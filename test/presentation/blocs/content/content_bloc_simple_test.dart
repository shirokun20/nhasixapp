import 'package:test/test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:logger/logger.dart';

import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/repositories.dart';
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/domain/usecases/favorites/favorites_usecases.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';

import 'content_bloc_simple_test.mocks.dart';

@GenerateMocks([
  ContentRepository,
  GetContentListUseCase,
  SearchContentUseCase,
  GetRandomContentUseCase,
  AddToFavoritesUseCase,
  RemoveFromFavoritesUseCase,
  Logger,
])
void main() {
  group('ContentBloc Simple Tests', () {
    late ContentBloc contentBloc;
    late MockContentRepository mockContentRepository;
    late MockGetContentListUseCase mockGetContentListUseCase;
    late MockSearchContentUseCase mockSearchContentUseCase;
    late MockGetRandomContentUseCase mockGetRandomContentUseCase;
    late MockLogger mockLogger;

    setUp(() {
      mockContentRepository = MockContentRepository();
      mockGetContentListUseCase = MockGetContentListUseCase();
      mockSearchContentUseCase = MockSearchContentUseCase();
      mockGetRandomContentUseCase = MockGetRandomContentUseCase();
      mockLogger = MockLogger();

      contentBloc = ContentBloc(
        getContentListUseCase: mockGetContentListUseCase,
        searchContentUseCase: mockSearchContentUseCase,
        getRandomContentUseCase: mockGetRandomContentUseCase,
        contentRepository: mockContentRepository,
        logger: mockLogger,
      );
    });

    tearDown(() {
      contentBloc.close();
    });

    test('initial state should be ContentInitial', () {
      expect(contentBloc.state, equals(const ContentInitial()));
    });

    group('ContentLoadEvent Tests', () {
      final mockContentList = [
        Content(
          id: '1',
          title: 'Test Content 1',
          coverUrl: 'https://example.com/cover1.jpg',
          tags: const [],
          artists: const ['Artist 1'],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: 'english',
          pageCount: 20,
          imageUrls: const [],
          uploadDate: DateTime(2024, 1, 1),
        ),
      ];

      final mockResult = ContentListResult(
        contents: mockContentList,
        currentPage: 1,
        totalPages: 5,
        totalCount: 100,
        hasNext: true,
        hasPrevious: false,
      );

      blocTest<ContentBloc, ContentState>(
        'should emit [ContentLoading, ContentLoaded] when content loads successfully',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenAnswer((_) async => mockResult);
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadEvent()),
        expect: () => [
          const ContentLoading(),
          isA<ContentLoaded>()
              .having((state) => state.contents.length, 'content count', 1)
              .having((state) => state.currentPage, 'current page', 1)
              .having((state) => state.hasNext, 'has next', true),
        ],
        verify: (_) {
          verify(mockGetContentListUseCase(any)).called(1);
        },
      );

      blocTest<ContentBloc, ContentState>(
        'should emit [ContentLoading, ContentEmpty] when no content available',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenAnswer((_) async => ContentListResult.empty());
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadEvent()),
        expect: () => [
          const ContentLoading(),
          const ContentEmpty(
            message: 'No content available at the moment.',
          ),
        ],
      );

      blocTest<ContentBloc, ContentState>(
        'should emit [ContentLoading, ContentError] when loading fails',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenThrow(Exception('Network error'));
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadEvent()),
        expect: () => [
          const ContentLoading(),
          isA<ContentError>()
              .having((state) => state.canRetry, 'can retry', true)
              .having((state) => state.errorType, 'error type',
                  ContentErrorType.network),
        ],
      );
    });

    group('ContentSearchEvent Tests', () {
      const searchFilter = SearchFilter(
        query: 'test query',
        page: 1,
        sortBy: SortOption.newest,
      );

      final mockSearchResults = [
        Content(
          id: '1',
          title: 'Search Result 1',
          coverUrl: 'https://example.com/cover1.jpg',
          tags: const [],
          artists: const ['Artist 1'],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: 'english',
          pageCount: 20,
          imageUrls: const [],
          uploadDate: DateTime(2024, 1, 1),
        ),
      ];

      final mockResult = ContentListResult(
        contents: mockSearchResults,
        currentPage: 1,
        totalPages: 1,
        totalCount: 1,
        hasNext: false,
        hasPrevious: false,
      );

      blocTest<ContentBloc, ContentState>(
        'should emit [ContentLoading, ContentLoaded] when search succeeds',
        build: () {
          when(mockSearchContentUseCase(any))
              .thenAnswer((_) async => mockResult);
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentSearchEvent(searchFilter)),
        expect: () => [
          const ContentLoading(message: 'Searching content...'),
          isA<ContentLoaded>()
              .having((state) => state.contents.length, 'results count', 1)
              .having(
                  (state) => state.searchFilter, 'search filter', searchFilter),
        ],
      );
    });

    group('ContentClearEvent Tests', () {
      blocTest<ContentBloc, ContentState>(
        'should emit ContentInitial when content is cleared',
        build: () => contentBloc,
        act: (bloc) => bloc.add(const ContentClearEvent()),
        expect: () => [const ContentInitial()],
      );
    });

    group('ContentSortChangedEvent Tests', () {
      final mockContentList = [
        Content(
          id: '1',
          title: 'Popular Content',
          coverUrl: 'https://example.com/cover1.jpg',
          tags: const [],
          artists: const ['Artist 1'],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: 'english',
          pageCount: 20,
          imageUrls: const [],
          uploadDate: DateTime(2024, 1, 1),
        ),
      ];

      final mockResult = ContentListResult(
        contents: mockContentList,
        currentPage: 1,
        totalPages: 1,
        totalCount: 1,
        hasNext: false,
        hasPrevious: false,
      );

      blocTest<ContentBloc, ContentState>(
        'should trigger content load with new sort option',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenAnswer((_) async => mockResult);
          return contentBloc;
        },
        act: (bloc) =>
            bloc.add(const ContentSortChangedEvent(SortOption.popular)),
        expect: () => [
          const ContentLoading(),
          isA<ContentLoaded>()
              .having((state) => state.sortBy, 'sort by', SortOption.popular),
        ],
      );
    });

    group('State Properties Tests', () {
      test('ContentLoaded should have correct properties', () {
        final contents = [
          Content(
            id: '1',
            title: 'Test Content',
            coverUrl: 'https://example.com/cover.jpg',
            tags: const [],
            artists: const ['Artist'],
            characters: const [],
            parodies: const [],
            groups: const [],
            language: 'english',
            pageCount: 20,
            imageUrls: const [],
            uploadDate: DateTime(2024, 1, 1),
          ),
        ];

        final state = ContentLoaded(
          contents: contents,
          currentPage: 1,
          totalPages: 5,
          totalCount: 100,
          hasNext: true,
          hasPrevious: false,
          sortBy: SortOption.newest,
        );

        expect(state.isEmpty, false);
        expect(state.isNotEmpty, true);
        expect(state.count, 1);
        expect(state.canLoadMore, true);
        expect(state.contentTypeDescription, 'Latest Content');
      });

      test('ContentError should have correct properties', () {
        const error = ContentError(
          message: 'Network error',
          canRetry: true,
          errorType: ContentErrorType.network,
        );

        expect(error.userFriendlyMessage,
            'No internet connection. Please check your network and try again.');
        expect(error.errorIcon, '🌐');
        expect(error.hasPreviousContent, false);
      });

      test('ContentEmpty should have correct suggestions', () {
        const empty = ContentEmpty(
          message: 'No content found',
          searchFilter: SearchFilter(query: 'test'),
        );

        expect(empty.contextualMessage,
            'No content found matching your search criteria. Try adjusting your filters.');
        expect(empty.suggestions, isNotEmpty);
        expect(empty.suggestions.first, 'Try removing some filters');
      });
    });
  });
}
