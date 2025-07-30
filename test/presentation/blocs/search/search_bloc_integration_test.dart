import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
import 'package:nhasixapp/domain/usecases/content/search_content_usecase.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/datasources/local/database_helper.dart';
import 'package:nhasixapp/data/models/tag_model.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/nhentai_scraper.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass.dart';
import 'package:nhasixapp/data/datasources/remote/anti_detection.dart';
import 'package:nhasixapp/data/repositories/content_repository_impl.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';

void main() {
  group('SearchBloc Integration Tests (Real API)', () {
    late SearchBloc searchBloc;
    late SearchContentUseCase searchContentUseCase;
    late ContentRepository contentRepository;
    late RemoteDataSource remoteDataSource;
    late LocalDataSource localDataSource;
    late Logger logger;
    late Dio dio;

    setUpAll(() async {
      // Setup real dependencies
      dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      logger = Logger();

      // Setup scraper components
      final scraper = NhentaiScraper();
      final cloudflareBypass =
          CloudflareBypass(httpClient: dio, logger: logger);
      final antiDetection = AntiDetection(logger: logger);

      // Setup remote data source with real API
      remoteDataSource = RemoteDataSource(
        httpClient: dio,
        scraper: scraper,
        cloudflareBypass: cloudflareBypass,
        antiDetection: antiDetection,
        logger: logger,
      );

      // Initialize remote data source
      try {
        await remoteDataSource.initialize();
      } catch (e) {
        logger.w('Failed to initialize remote data source: $e');
      }

      // Setup local data source (mock for testing)
      localDataSource = TestLocalDataSource();

      // Setup repository
      contentRepository = ContentRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        logger: logger,
      );

      // Setup use case
      searchContentUseCase = SearchContentUseCase(contentRepository);
    });

    setUp(() {
      searchBloc = SearchBloc(
        searchContentUseCase: searchContentUseCase,
        localDataSource: localDataSource,
        logger: logger,
      );
    });

    tearDown(() {
      searchBloc.close();
    });

    group('Real API Search Tests', () {
      test('should search for popular content successfully', () async {
        // Test searching for popular content
        searchBloc.add(const SearchQueryEvent('english'));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchLoaded>()
                .having(
                    (state) => state.results.isNotEmpty, 'has results', true)
                .having(
                    (state) => state.totalCount, 'total count', greaterThan(0))
                .having((state) => state.filter.query, 'query', 'english'),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should search with specific tag successfully', () async {
        // Test searching with specific tag
        final filter = SearchFilter(
          includeTags: const ['big breasts'],
          sortBy: SortOption.popular,
        );

        searchBloc.add(SearchWithFiltersEvent(filter));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching with filters...'),
            isA<SearchLoaded>()
                .having(
                    (state) => state.results.isNotEmpty, 'has results', true)
                .having((state) => state.filter.includeTags, 'include tags', [
              'big breasts'
            ]).having((state) => state.filter.sortBy, 'sort by',
                    SortOption.popular),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle search with multiple filters', () async {
        // Test complex search with multiple filters
        final filter = SearchFilter(
          query: 'school',
          includeTags: const ['schoolgirl uniform'],
          language: 'english',
          sortBy: SortOption.newest,
        );

        searchBloc.add(SearchWithFiltersEvent(filter));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching with filters...'),
            isA<SearchState>(), // Either SearchLoaded or SearchEmpty
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle empty search results gracefully', () async {
        // Test search that should return no results
        searchBloc
            .add(const SearchQueryEvent('veryrarequerythatdoesnotexist123456'));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchEmpty>().having((state) => state.filter.query, 'query',
                'veryrarequerythatdoesnotexist123456'),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle network errors gracefully', () async {
        // Create a SearchBloc with invalid base URL to simulate network error
        final errorDio = Dio();
        errorDio.options.baseUrl =
            'https://invalid-url-that-does-not-exist.com';
        errorDio.options.connectTimeout = const Duration(seconds: 5);

        final errorScraper = NhentaiScraper();
        final errorCloudflareBypass =
            CloudflareBypass(httpClient: errorDio, logger: logger);
        final errorAntiDetection = AntiDetection(logger: logger);

        final errorRemoteDataSource = RemoteDataSource(
          httpClient: errorDio,
          scraper: errorScraper,
          cloudflareBypass: errorCloudflareBypass,
          antiDetection: errorAntiDetection,
          logger: logger,
        );
        final errorRepository = ContentRepositoryImpl(
          remoteDataSource: errorRemoteDataSource,
          localDataSource: localDataSource,
          logger: logger,
        );
        final errorUseCase = SearchContentUseCase(errorRepository);

        final errorSearchBloc = SearchBloc(
          searchContentUseCase: errorUseCase,
          localDataSource: localDataSource,
          logger: logger,
        );

        errorSearchBloc.add(const SearchQueryEvent('test'));

        await expectLater(
          errorSearchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchError>()
                .having((state) => state.canRetry, 'can retry', true),
          ]),
        );

        await errorSearchBloc.close();
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('should load more results when available', () async {
        // Test pagination
        searchBloc.add(const SearchQueryEvent('english'));

        // Wait for initial results
        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchLoaded>().having(
                (state) => state.results.isNotEmpty, 'has results', true),
          ]),
        );

        // Test load more if available
        final currentState = searchBloc.state;
        if (currentState is SearchLoaded && currentState.hasNext) {
          searchBloc.add(const SearchLoadMoreEvent());

          await expectLater(
            searchBloc.stream,
            emitsInOrder([
              isA<SearchLoadingMore>(),
              isA<SearchLoaded>().having((state) => state.results.length,
                  'more results', greaterThan(currentState.results.length)),
            ]),
          );
        }
      }, timeout: const Timeout(Duration(seconds: 45)));

      test('should refresh search results', () async {
        // Test refresh functionality
        searchBloc.add(const SearchQueryEvent('popular'));

        // Wait for initial results
        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchLoaded>(),
          ]),
        );

        // Test refresh
        searchBloc.add(const SearchRefreshEvent());

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            isA<SearchRefreshing>(),
            isA<SearchLoaded>().having((state) => state.results.isNotEmpty,
                'has results after refresh', true),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 45)));

      test('should handle sort option changes', () async {
        // Test sort functionality
        searchBloc.add(const SearchQueryEvent('english'));

        // Wait for initial results
        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchLoaded>().having((state) => state.filter.sortBy,
                'initial sort', SortOption.newest),
          ]),
        );

        // Change sort option
        searchBloc.add(const SearchUpdateSortEvent(SortOption.popular));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching with filters...'),
            isA<SearchLoaded>().having((state) => state.filter.sortBy,
                'updated sort', SortOption.popular),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 45)));
    });

    group('Search History Integration', () {
      test('should save and load search history', () async {
        // Test search history functionality
        const query1 = 'test query 1';
        const query2 = 'test query 2';

        // Add queries to history
        searchBloc.add(const SearchAddToHistoryEvent(query1));
        searchBloc.add(const SearchAddToHistoryEvent(query2));

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Load history
        searchBloc.add(const SearchLoadHistoryEvent());

        await expectLater(
          searchBloc.stream,
          emits(isA<SearchHistory>()
              .having((state) => state.history, 'history', contains(query1))
              .having((state) => state.history, 'history', contains(query2))),
        );
      });

      test('should clear search history', () async {
        // Add some history first
        searchBloc.add(const SearchAddToHistoryEvent('test query'));
        await Future.delayed(const Duration(milliseconds: 50));

        // Clear history
        searchBloc.add(const SearchClearHistoryEvent());

        await expectLater(
          searchBloc.stream,
          emits(isA<SearchHistory>().having(
              (state) => state.history.isEmpty, 'history is empty', true)),
        );
      });
    });

    group('Advanced Search Features', () {
      test('should toggle advanced mode', () async {
        expect(searchBloc.isAdvancedMode, false);

        searchBloc.add(const SearchToggleAdvancedModeEvent());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(searchBloc.isAdvancedMode, true);
      });

      test('should apply quick filters', () async {
        searchBloc.add(const SearchApplyQuickFilterEvent(tag: 'big breasts'));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching with filters...'),
            isA<SearchState>(), // Either SearchLoaded or SearchEmpty
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}

// Mock LocalDataSource for testing
class TestLocalDataSource extends LocalDataSource {
  List<String> _searchHistory = [];

  TestLocalDataSource() : super(DatabaseHelper.instance);

  @override
  Future<void> addSearchHistory(String query) async {
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 50) {
      _searchHistory = _searchHistory.take(50).toList();
    }
  }

  @override
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    return _searchHistory.take(limit).toList();
  }

  @override
  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
  }

  @override
  Future<List<TagModel>> searchTags(String query, {int limit = 50}) async {
    return [];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
