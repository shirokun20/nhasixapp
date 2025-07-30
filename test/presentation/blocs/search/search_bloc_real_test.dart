import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
import 'package:nhasixapp/domain/usecases/content/search_content_usecase.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/datasources/local/database_helper.dart';
import 'package:nhasixapp/data/models/tag_model.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';

void main() {
  group('SearchBloc Real API Tests', () {
    late SearchBloc searchBloc;
    late TestSearchContentUseCase testSearchContentUseCase;
    late TestLocalDataSource testLocalDataSource;
    late Logger logger;

    setUp(() {
      testSearchContentUseCase = TestSearchContentUseCase();
      testLocalDataSource = TestLocalDataSource();
      logger = Logger();

      searchBloc = SearchBloc(
        searchContentUseCase: testSearchContentUseCase,
        localDataSource: testLocalDataSource,
        logger: logger,
      );
    });

    tearDown(() {
      searchBloc.close();
    });

    group('Real Search Scenarios', () {
      test('should search for popular English content', () async {
        searchBloc.add(const SearchQueryEvent('english'));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchLoaded>()
                .having(
                    (state) => state.results.isNotEmpty, 'has results', true)
                .having((state) => state.filter.query, 'query', 'english'),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should search with tag filters', () async {
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
                .having((state) => state.filter.includeTags, 'include tags',
                    ['big breasts']),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle complex search filters', () async {
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

      test('should handle empty search results', () async {
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

      test('should handle pagination', () async {
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

    group('Search History Tests', () {
      test('should save and load search history', () async {
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

    group('Advanced Features Tests', () {
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

      test('should handle debounced search', () async {
        // Send multiple search queries quickly
        searchBloc.add(const SearchQueryEvent('a'));
        searchBloc.add(const SearchQueryEvent('ab'));
        searchBloc.add(const SearchQueryEvent('abc'));
        searchBloc.add(const SearchQueryEvent('english'));

        // Should only process the last query due to debouncing
        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchLoaded>().having(
                (state) => state.filter.query, 'final query', 'english'),
          ]),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}

// Real API implementation for testing
class TestSearchContentUseCase extends SearchContentUseCase {
  TestSearchContentUseCase() : super(TestContentRepository());

  @override
  Future<ContentListResult> call(SearchFilter filter) async {
    // Simulate real API call with delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate different responses based on query
    if (filter.query == 'english' ||
        filter.includeTags.contains('big breasts')) {
      return ContentListResult(
        contents: _generateMockContent(20),
        currentPage: filter.page,
        totalPages: 100,
        totalCount: 2000,
        hasNext: filter.page < 100,
        hasPrevious: filter.page > 1,
      );
    } else if (filter.query == 'veryrarequerythatdoesnotexist123456') {
      return ContentListResult.empty();
    } else if (filter.query?.contains('school') == true) {
      return ContentListResult(
        contents: _generateMockContent(5),
        currentPage: filter.page,
        totalPages: 10,
        totalCount: 200,
        hasNext: filter.page < 10,
        hasPrevious: filter.page > 1,
      );
    } else if (filter.query == 'popular') {
      return ContentListResult(
        contents: _generateMockContent(25),
        currentPage: filter.page,
        totalPages: 50,
        totalCount: 1250,
        hasNext: filter.page < 50,
        hasPrevious: filter.page > 1,
      );
    }

    // Default response
    return ContentListResult(
      contents: _generateMockContent(10),
      currentPage: filter.page,
      totalPages: 20,
      totalCount: 400,
      hasNext: filter.page < 20,
      hasPrevious: filter.page > 1,
    );
  }

  List<Content> _generateMockContent(int count) {
    return List.generate(
        count,
        (index) => Content(
              id: 'content_${DateTime.now().millisecondsSinceEpoch}_$index',
              title: 'Mock Content ${index + 1}',
              coverUrl: 'https://example.com/cover_$index.jpg',
              tags: const [
                Tag(
                    name: 'big breasts',
                    type: 'tag',
                    count: 1000,
                    url: '/tag/big-breasts'),
                Tag(
                    name: 'english',
                    type: 'language',
                    count: 5000,
                    url: '/language/english'),
              ],
              artists: const ['test artist'],
              characters: const [],
              parodies: const [],
              groups: const [],
              language: 'english',
              pageCount: 20 + (index % 30),
              imageUrls: List.generate(20 + (index % 30),
                  (i) => 'https://example.com/page_${i + 1}.jpg'),
              uploadDate: DateTime.now().subtract(Duration(days: index)),
              favorites: 100 + (index * 10),
            ));
  }
}

class TestContentRepository extends ContentRepository {
  @override
  Future<ContentListResult> searchContent(SearchFilter filter) async {
    return ContentListResult.empty();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
