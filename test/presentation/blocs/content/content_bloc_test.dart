import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:logger/logger.dart';

import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/repositories.dart';
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/domain/usecases/favorites/favorites_usecases.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';

import 'content_bloc_test.mocks.dart';

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
  group('ContentBloc', () {
    late ContentBloc contentBloc;
    late MockContentRepository mockContentRepository;
    late MockGetContentListUseCase mockGetContentListUseCase;
    late MockSearchContentUseCase mockSearchContentUseCase;
    late MockGetRandomContentUseCase mockGetRandomContentUseCase;
    late MockAddToFavoritesUseCase mockAddToFavoritesUseCase;
    late MockRemoveFromFavoritesUseCase mockRemoveFromFavoritesUseCase;
    late MockLogger mockLogger;

    setUp(() {
      mockContentRepository = MockContentRepository();
      mockGetContentListUseCase = MockGetContentListUseCase();
      mockSearchContentUseCase = MockSearchContentUseCase();
      mockGetRandomContentUseCase = MockGetRandomContentUseCase();
      mockAddToFavoritesUseCase = MockAddToFavoritesUseCase();
      mockRemoveFromFavoritesUseCase = MockRemoveFromFavoritesUseCase();
      mockLogger = MockLogger();

      contentBloc = ContentBloc(
        getContentListUseCase: mockGetContentListUseCase,
        searchContentUseCase: mockSearchContentUseCase,
        getRandomContentUseCase: mockGetRandomContentUseCase,
        contentRepository: mockContentRepository,
        logger: mockLogger,
        addToFavoritesUseCase: mockAddToFavoritesUseCase,
        removeFromFavoritesUseCase: mockRemoveFromFavoritesUseCase,
      );
    });

    tearDown(() {
      contentBloc.close();
    });

    test('initial state is ContentInitial', () {
      expect(contentBloc.state, equals(const ContentInitial()));
    });

    group('ContentLoadEvent', () {
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
          uploadDate: DateTime.now(),
        ),
        Content(
          id: '2',
          title: 'Test Content 2',
          coverUrl: 'https://example.com/cover2.jpg',
          tags: const [],
          artists: const ['Artist 2'],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: 'japanese',
          pageCount: 15,
          imageUrls: const [],
          uploadDate: DateTime.now(),
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
        'emits [ContentLoading, ContentLoaded] when content is loaded successfully',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenAnswer((_) async => mockResult);
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadEvent()),
        expect: () => [
          const ContentLoading(),
          isA<ContentLoaded>()
              .having((state) => state.contents, 'contents', mockContentList)
              .having((state) => state.currentPage, 'currentPage', 1)
              .having((state) => state.totalPages, 'totalPages', 5)
              .having((state) => state.totalCount, 'totalCount', 100)
              .having((state) => state.hasNext, 'hasNext', true)
              .having((state) => state.hasPrevious, 'hasPrevious', false)
              .having((state) => state.sortBy, 'sortBy', SortOption.newest),
        ],
        verify: (_) {
          verify(mockGetContentListUseCase(any)).called(1);
        },
      );

      blocTest<ContentBloc, ContentState>(
        'emits [ContentLoading, ContentEmpty] when no content is available',
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
        'emits [ContentLoading, ContentError] when loading fails',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenThrow(Exception('Network error'));
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadEvent()),
        expect: () => [
          const ContentLoading(),
          isA<ContentError>()
              .having((state) => state.message, 'message',
                  'Exception: Network error')
              .having((state) => state.canRetry, 'canRetry', true)
              .having((state) => state.errorType, 'errorType',
                  ContentErrorType.network),
        ],
      );
    });

    group('ContentRefreshEvent', () {
      final mockContentList = [
        Content(
          id: '1',
          title: 'Refreshed Content',
          coverUrl: 'https://example.com/cover1.jpg',
          tags: const [],
          artists: const ['Artist 1'],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: 'english',
          pageCount: 20,
          imageUrls: const [],
          uploadDate: DateTime.now(),
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
        'emits [ContentLoading, ContentLoaded] when refresh is successful',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenAnswer((_) async => mockResult);
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentRefreshEvent()),
        expect: () => [
          const ContentLoading(message: 'Refreshing content...'),
          isA<ContentLoaded>()
              .having((state) => state.contents, 'contents', mockContentList)
              .having((state) => state.currentPage, 'currentPage', 1)
              .having((state) => state.totalPages, 'totalPages', 1)
              .having((state) => state.totalCount, 'totalCount', 1)
              .having((state) => state.hasNext, 'hasNext', false)
              .having((state) => state.hasPrevious, 'hasPrevious', false)
              .having((state) => state.sortBy, 'sortBy', SortOption.newest),
        ],
      );
    });

    group('ContentSearchEvent', () {
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
          uploadDate: DateTime.now(),
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
        'emits [ContentLoading, ContentLoaded] when search is successful',
        build: () {
          when(mockSearchContentUseCase(any))
              .thenAnswer((_) async => mockResult);
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentSearchEvent(searchFilter)),
        expect: () => [
          const ContentLoading(message: 'Searching content...'),
          isA<ContentLoaded>()
              .having((state) => state.contents, 'contents', mockSearchResults)
              .having((state) => state.currentPage, 'currentPage', 1)
              .having((state) => state.totalPages, 'totalPages', 1)
              .having((state) => state.totalCount, 'totalCount', 1)
              .having((state) => state.hasNext, 'hasNext', false)
              .having((state) => state.hasPrevious, 'hasPrevious', false)
              .having((state) => state.sortBy, 'sortBy', SortOption.newest)
              .having(
                  (state) => state.searchFilter, 'searchFilter', searchFilter),
        ],
      );

      blocTest<ContentBloc, ContentState>(
        'emits [ContentLoading, ContentEmpty] when no search results found',
        build: () {
          when(mockSearchContentUseCase(any))
              .thenAnswer((_) async => ContentListResult.empty());
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentSearchEvent(searchFilter)),
        expect: () => [
          const ContentLoading(message: 'Searching content...'),
          const ContentEmpty(
            message: 'No content found matching your search criteria.',
            searchFilter: searchFilter,
          ),
        ],
      );
    });

    group('ContentLoadRandomEvent', () {
      final mockRandomContent = [
        Content(
          id: '1',
          title: 'Random Content 1',
          coverUrl: 'https://example.com/cover1.jpg',
          tags: const [],
          artists: const ['Artist 1'],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: 'english',
          pageCount: 20,
          imageUrls: const [],
          uploadDate: DateTime.now(),
        ),
        Content(
          id: '2',
          title: 'Random Content 2',
          coverUrl: 'https://example.com/cover2.jpg',
          tags: const [],
          artists: const ['Artist 2'],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: 'japanese',
          pageCount: 15,
          imageUrls: const [],
          uploadDate: DateTime.now(),
        ),
      ];

      blocTest<ContentBloc, ContentState>(
        'emits [ContentLoading, ContentLoaded] when random content is loaded',
        build: () {
          when(mockGetRandomContentUseCase(any))
              .thenAnswer((_) async => mockRandomContent);
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadRandomEvent(count: 2)),
        expect: () => [
          const ContentLoading(message: 'Loading random content...'),
          isA<ContentLoaded>()
              .having((state) => state.contents, 'contents', mockRandomContent)
              .having((state) => state.currentPage, 'currentPage', 1)
              .having((state) => state.totalPages, 'totalPages', 1)
              .having((state) => state.totalCount, 'totalCount', 2)
              .having((state) => state.hasNext, 'hasNext', false)
              .having((state) => state.hasPrevious, 'hasPrevious', false)
              .having((state) => state.sortBy, 'sortBy', SortOption.random),
        ],
      );
    });

    group('ContentSortChangedEvent', () {
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
          uploadDate: DateTime.now(),
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
        'triggers content load with new sort option',
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
              .having((state) => state.contents, 'contents', mockContentList)
              .having((state) => state.currentPage, 'currentPage', 1)
              .having((state) => state.totalPages, 'totalPages', 1)
              .having((state) => state.totalCount, 'totalCount', 1)
              .having((state) => state.hasNext, 'hasNext', false)
              .having((state) => state.hasPrevious, 'hasPrevious', false)
              .having((state) => state.sortBy, 'sortBy', SortOption.popular),
        ],
      );
    });

    group('ContentClearEvent', () {
      blocTest<ContentBloc, ContentState>(
        'emits ContentInitial when content is cleared',
        build: () => contentBloc,
        act: (bloc) => bloc.add(const ContentClearEvent()),
        expect: () => [const ContentInitial()],
      );
    });
  });
}
