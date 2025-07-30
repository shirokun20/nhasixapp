import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
import 'package:nhasixapp/domain/usecases/content/search_content_usecase.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/datasources/local/database_helper.dart';
import 'package:nhasixapp/data/models/tag_model.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';

// Simple mock implementations
class TestSearchContentUseCase extends SearchContentUseCase {
  TestSearchContentUseCase() : super(TestContentRepository());

  @override
  Future<ContentListResult> call(SearchFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (filter.query == 'test search') {
      return ContentListResult(
        contents: [
          Content(
            id: '1',
            title: 'Test Content',
            coverUrl: 'https://example.com/cover.jpg',
            tags: const [],
            artists: const [],
            characters: const [],
            parodies: const [],
            groups: const [],
            language: 'english',
            pageCount: 10,
            imageUrls: const [],
            uploadDate: DateTime.now(),
            favorites: 100,
          ),
        ],
        currentPage: 1,
        totalPages: 1,
        totalCount: 1,
        hasNext: false,
        hasPrevious: false,
      );
    } else if (filter.query == 'error') {
      throw Exception('Network error');
    }

    return ContentListResult.empty();
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

void main() {
  group('SearchBloc', () {
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

    test('initial state is SearchInitial', () {
      expect(searchBloc.state, equals(const SearchInitial()));
    });

    test('currentFilter returns default SearchFilter initially', () {
      expect(searchBloc.currentFilter, equals(const SearchFilter()));
    });

    test('isAdvancedMode returns false initially', () {
      expect(searchBloc.isAdvancedMode, equals(false));
    });

    test('searchHistory returns empty list initially', () {
      expect(searchBloc.searchHistory, equals([]));
    });

    test('searchPresets returns empty map initially', () {
      expect(searchBloc.searchPresets, equals({}));
    });

    group('SearchInitializeEvent', () {
      test('emits SearchHistory when initialization succeeds', () async {
        // Add some history first
        await testLocalDataSource.addSearchHistory('test query');
        await testLocalDataSource.addSearchHistory('another query');

        searchBloc.add(const SearchInitializeEvent());

        await expectLater(
          searchBloc.stream,
          emits(isA<SearchHistory>()
              .having((state) => state.history.length, 'history length', 2)
              .having((state) => state.history.first, 'first history item',
                  'another query')),
        );
      });
    });

    group('SearchQueryEvent', () {
      test('emits SearchLoading then SearchLoaded when search succeeds',
          () async {
        searchBloc.add(const SearchQueryEvent('test search'));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchLoaded>()
                .having((state) => state.results.length, 'results length', 1)
                .having(
                    (state) => state.results.first.id, 'first result id', '1')
                .having((state) => state.filter.query, 'filter query',
                    'test search'),
          ]),
        );
      });

      test('emits SearchEmpty when no results found', () async {
        searchBloc.add(const SearchQueryEvent('empty'));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchEmpty>()
                .having((state) => state.filter.query, 'filter query', 'empty')
                .having((state) => state.message, 'message',
                    'No results found for "empty"'),
          ]),
        );
      });

      test('emits SearchError when search fails', () async {
        searchBloc.add(const SearchQueryEvent('error'));

        await expectLater(
          searchBloc.stream,
          emitsInOrder([
            const SearchLoading(message: 'Searching...'),
            isA<SearchError>()
                .having((state) => state.errorType, 'error type',
                    SearchErrorType.network)
                .having((state) => state.canRetry, 'can retry', true),
          ]),
        );
      });

      test('clears search when empty query is provided', () async {
        searchBloc.add(const SearchQueryEvent(''));

        await expectLater(
          searchBloc.stream,
          emits(isA<SearchHistory>()),
        );
      });
    });

    group('SearchClearEvent', () {
      test('emits SearchHistory when search is cleared', () async {
        searchBloc.add(const SearchClearEvent());

        await expectLater(
          searchBloc.stream,
          emits(isA<SearchHistory>()),
        );
      });
    });

    group('SearchAddToHistoryEvent', () {
      test('adds query to search history', () async {
        searchBloc.add(const SearchAddToHistoryEvent('test query'));

        // Wait a bit for the async operation
        await Future.delayed(const Duration(milliseconds: 50));

        final history = await testLocalDataSource.getSearchHistory();
        expect(history, contains('test query'));
      });
    });

    group('SearchUpdateSortEvent', () {
      test('updates sort option in current filter', () async {
        searchBloc.add(const SearchUpdateSortEvent(SortOption.popular));

        // Wait a bit for the event to be processed
        await Future.delayed(const Duration(milliseconds: 50));

        expect(searchBloc.currentFilter.sortBy, equals(SortOption.popular));
      });
    });

    group('SearchToggleAdvancedModeEvent', () {
      test('toggles advanced mode', () async {
        expect(searchBloc.isAdvancedMode, equals(false));

        searchBloc.add(const SearchToggleAdvancedModeEvent());

        // Wait a bit for the event to be processed
        await Future.delayed(const Duration(milliseconds: 50));

        expect(searchBloc.isAdvancedMode, equals(true));

        searchBloc.add(const SearchToggleAdvancedModeEvent());

        // Wait a bit for the event to be processed
        await Future.delayed(const Duration(milliseconds: 50));

        expect(searchBloc.isAdvancedMode, equals(false));
      });
    });
  });
}
