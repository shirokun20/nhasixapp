import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:logger/logger.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_crotpedia/src/crotpedia_source.dart';
import 'package:kuron_crotpedia/src/crotpedia_scraper.dart';
import 'package:kuron_crotpedia/src/auth/crotpedia_auth_manager.dart';
import 'package:kuron_crotpedia/src/models/crotpedia_series.dart';

// Generate mocks using build_runner: flutter pub run build_runner build
@GenerateNiceMocks([
  MockSpec<CrotpediaScraper>(),
  MockSpec<CrotpediaAuthManager>(),
  MockSpec<Dio>(),
  MockSpec<Logger>(),
])
import 'crotpedia_source_test.mocks.dart';

void main() {
  late CrotpediaSource source;
  late MockCrotpediaScraper mockScraper;
  late MockCrotpediaAuthManager mockAuthManager;
  late MockDio mockDio;
  late MockLogger mockLogger;

  setUp(() {
    mockScraper = MockCrotpediaScraper();
    mockAuthManager = MockCrotpediaAuthManager();
    mockDio = MockDio();
    mockLogger = MockLogger();

    source = CrotpediaSource(
      scraper: mockScraper,
      authManager: mockAuthManager,
      dio: mockDio,
      logger: mockLogger,
    );

    // Default behavior for parsePagination
    when(mockScraper.parsePagination(any)).thenReturn((
      currentPage: 1,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    ));
  });

  group('CrotpediaSource Metadata', () {
    test('has correct id', () {
      expect(source.id, equals(SourceType.crotpedia.id));
    });

    test('has correct displayName', () {
      expect(source.displayName, equals('Crotpedia'));
    });

    test('has correct baseUrl', () {
      expect(source.baseUrl, equals('https://crotpedia.net'));
    });

    test('has correct iconPath', () {
      expect(source.iconPath, equals('assets/icons/crotpedia.png'));
    });

    test('does not require bypass', () {
      expect(source.requiresBypass, isFalse);
    });

    test('has correct refererHeader', () {
      expect(source.refererHeader, equals('https://crotpedia.net'));
    });

    test('has searchCapabilities', () {
      expect(source.searchCapabilities, isNotNull);
    });
  });

  group('getList', () {
    test('returns content list from home page for page 1', () async {
      final mockSeriesList = [
        CrotpediaSeries(
          title: 'Test Series 1',
          slug: 'test-series-1',
          coverUrl: 'https://example.com/cover1.jpg',
          genres: {'action': 'Action', 'drama': 'Drama'},
          artist: 'Artist 1',
        ),
        CrotpediaSeries(
          title: 'Test Series 2',
          slug: 'test-series-2',
          coverUrl: 'https://example.com/cover2.jpg',
          genres: {'comedy': 'Comedy'},
        ),
      ];

      final response = Response(
        requestOptions: RequestOptions(path: '/'),
        data: '<html>mock html</html>',
        statusCode: 200,
      );

      when(mockDio.get(any)).thenAnswer((_) async => response);
      when(mockScraper.parseLatestSeries(any)).thenReturn(mockSeriesList);
      when(mockScraper.parsePagination(any)).thenReturn((
        currentPage: 1,
        totalPages: 10,
        hasNext: true,
        hasPrevious: false,
      ));

      final result = await source.getList(page: 1);

      expect(result.contents.length, equals(2));
      expect(result.contents[0].id, equals('test-series-1'));
      expect(result.contents[0].title, equals('Test Series 1'));
      expect(result.contents[0].artists, equals(['Artist 1']));
      expect(result.currentPage, equals(1));
      expect(result.hasNext, isTrue);

      verify(mockDio.get(argThat(contains('crotpedia.net')))).called(1);
      verify(mockScraper.parseLatestSeries(any)).called(1);
    });

    test('returns content list from paginated page', () async {
      final mockSeriesList = [
        CrotpediaSeries(
          title: 'Test Series 3',
          slug: 'test-series-3',
          coverUrl: 'https://example.com/cover3.jpg',
          genres: {'action': 'Action'},
        ),
      ];

      final response = Response(
        requestOptions: RequestOptions(path: '/page/2/'),
        data: '<html>mock html</html>',
        statusCode: 200,
      );

      when(mockDio.get(any)).thenAnswer((_) async => response);
      when(mockScraper.parseLatestSeries(any)).thenReturn(mockSeriesList);
      when(mockScraper.parsePagination(any)).thenReturn((
        currentPage: 2,
        totalPages: 5,
        hasNext: false,
        hasPrevious: true,
      ));

      final result = await source.getList(page: 2);

      expect(result.contents.length, equals(1));
      expect(result.currentPage, equals(2));
      verify(mockDio.get(argThat(contains('/page/2/')))).called(1);
    });

    test('returns empty list on error', () async {
      when(mockDio.get(any)).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/'),
        error: 'Network error',
      ));

      final result = await source.getList(page: 1);

      expect(result.contents, isEmpty);
      expect(result.totalCount, equals(0));
      expect(result.hasNext, isFalse);
      verify(mockLogger.e(any)).called(1);
    });
  });

  group('getPopular', () {
    test('returns popular series', () async {
      final mockSeriesList = [
        CrotpediaSeries(
          title: 'Popular Series',
          slug: 'popular-series',
          coverUrl: 'https://example.com/popular.jpg',
          genres: {'romance': 'Romance'},
        ),
      ];

      final response = Response(
        requestOptions: RequestOptions(path: '/search'),
        data: '<html>mock html</html>',
        statusCode: 200,
      );

      when(mockDio.get(any)).thenAnswer((_) async => response);
      when(mockScraper.parseSearchResults(any)).thenReturn(mockSeriesList);

      final result = await source.getPopular(page: 1);

      expect(result.contents.length, equals(1));
      expect(result.contents[0].title, equals('Popular Series'));
      verify(mockDio.get(argThat(contains('order=popular')))).called(1);
    });

    test('returns empty list on error', () async {
      when(mockDio.get(any)).thenThrow(Exception('Error'));

      final result = await source.getPopular();

      expect(result.contents, isEmpty);
      verify(mockLogger.e(any)).called(1);
    });
  });

  group('search', () {
    test('performs simple search with query only', () async {
      final mockSeriesList = [
        CrotpediaSeries(
          title: 'Search Result',
          slug: 'search-result',
          coverUrl: 'https://example.com/search.jpg',
          genres: {'action': 'Action'},
        ),
      ];

      final response = Response(
        requestOptions: RequestOptions(path: '/search'),
        data: '<html>mock html</html>',
        statusCode: 200,
      );

      final filter = SearchFilter(
        query: 'test query',
        page: 1,
      );

      when(mockDio.get(any)).thenAnswer((_) async => response);
      when(mockScraper.parseSearchResults(any)).thenReturn(mockSeriesList);

      final result = await source.search(filter);

      expect(result.contents.length, equals(1));
      expect(result.contents[0].title, equals('Search Result'));
      verify(mockDio.get(argThat(contains('?s=')))).called(1);
    });

    test('performs advanced search with tags', () async {
      final mockSeriesList = [
        CrotpediaSeries(
          title: 'Advanced Search Result',
          slug: 'advanced-search',
          coverUrl: 'https://example.com/advanced.jpg',
          genres: {'drama': 'Drama', 'romance': 'Romance'},
        ),
      ];

      final response = Response(
        requestOptions: RequestOptions(path: '/search'),
        data: '<html>mock html</html>',
        statusCode: 200,
      );

      final filter = SearchFilter(
        query: 'test',
        page: 1,
        includeTags: [
          FilterItem(id: 1, name: 'Drama', type: 'genre'),
        ],
      );

      when(mockDio.get(any)).thenAnswer((_) async => response);
      when(mockScraper.parseSearchResults(any)).thenReturn(mockSeriesList);

      final result = await source.search(filter);

      expect(result.contents.length, equals(1));
      verify(mockDio.get(argThat(contains('genre')))).called(1);
    });

    test('returns empty list on search error', () async {
      when(mockDio.get(any)).thenThrow(Exception('Search error'));

      final filter = SearchFilter(query: 'test', page: 1);
      final result = await source.search(filter);

      expect(result.contents, isEmpty);
      verify(mockLogger.e(any)).called(1);
    });
  });

  group('getDetail', () {
    test('fetches series detail and returns chapter list without images',
        () async {
      final mockSeriesDetail = CrotpediaSeriesDetail(
        slug: 'test-slug',
        title: 'Detailed Series',
        coverUrl: 'https://example.com/detail.jpg',
        genres: {'action': 'Action', 'adventure': 'Adventure'},
        artist: 'Artist',
        status: 'Ongoing',
        synopsis: 'Description',
        chapters: [
          CrotpediaChapter(
            title: 'Chapter 1',
            slug: 'chapter-1',
            seriesSlug: 'test-slug',
            publishedDate: DateTime(2024, 1, 1),
          ),
          CrotpediaChapter(
            title: 'Chapter 2',
            slug: 'chapter-2',
            seriesSlug: 'test-slug',
            publishedDate: DateTime(2024, 1, 2),
          ),
        ],
      );

      final detailResponse = Response(
        requestOptions: RequestOptions(path: '/baca/series/test-slug/'),
        data: '<html>detail html</html>',
        statusCode: 200,
      );

      when(mockDio.get(argThat(contains('/baca/series/'))))
          .thenAnswer((_) async => detailResponse);
      when(mockScraper.parseSeriesDetail(any)).thenReturn(mockSeriesDetail);

      final result = await source.getDetail('test-slug');

      expect(result.id, equals('test-slug'));
      expect(result.title, equals('Detailed Series'));
      // New implementation: pageCount and imageUrls are 0/empty
      // Images are loaded per-chapter separately via getChapterImages()
      expect(result.pageCount, equals(0));
      expect(result.imageUrls.length, equals(0));
      expect(result.chapters!.length, equals(2));
      expect(result.chapters![0].id, equals('chapter-1'));
      expect(result.chapters![1].id, equals('chapter-2'));
      expect(result.tags.length, equals(2));
      expect(result.artists, equals(['Artist']));

      verify(mockScraper.parseSeriesDetail(any)).called(1);
      // parseChapterImages is NOT called during getDetail anymore
      verifyNever(mockScraper.parseChapterImages(any));
    });

    test('throws on detail fetch error', () async {
      when(mockDio.get(any)).thenThrow(Exception('Detail error'));

      expect(
        () => source.getDetail('test-slug'),
        throwsException,
      );
      verify(mockLogger.e(any)).called(1);
    });
  });

  group('getRandom', () {
    test('returns empty list (not implemented)', () async {
      final result = await source.getRandom(count: 5);
      expect(result, isEmpty);
    });
  });

  group('getRelated', () {
    test('returns related content based on tags', () async {
      // Mock getDetail
      final mockSeriesDetail = CrotpediaSeriesDetail(
        slug: 'original',
        title: 'Original Series',
        coverUrl: 'https://example.com/original.jpg',
        genres: {'action': 'Action', 'drama': 'Drama'},
        chapters: [],
      );

      final detailResponse = Response(
        requestOptions: RequestOptions(path: '/baca/series/original/'),
        data: '<html>detail html</html>',
        statusCode: 200,
      );

      // Mock search results
      final mockSearchResults = [
        CrotpediaSeries(
          title: 'Related Series 1',
          slug: 'related-1',
          coverUrl: 'https://example.com/related1.jpg',
          genres: {'action': 'Action'},
        ),
        CrotpediaSeries(
          title: 'Related Series 2',
          slug: 'related-2',
          coverUrl: 'https://example.com/related2.jpg',
          genres: {'action': 'Action'},
        ),
        CrotpediaSeries(
          title: 'Original Series',
          slug: 'original',
          coverUrl: 'https://example.com/original.jpg',
          genres: {'action': 'Action'},
        ),
      ];

      final searchResponse = Response(
        requestOptions: RequestOptions(path: '/search'),
        data: '<html>search html</html>',
        statusCode: 200,
      );

      // More specific matchers to avoid conflicts
      when(mockDio.get(argThat(contains('/baca/series/original/'))))
          .thenAnswer((_) async => detailResponse);
      when(mockDio.get(argThat(contains('?s='))))
          .thenAnswer((_) async => searchResponse);
      when(mockScraper.parseSeriesDetail(any)).thenReturn(mockSeriesDetail);
      when(mockScraper.parseSearchResults(any)).thenReturn(mockSearchResults);
      when(mockScraper.parseChapterImages(any))
          .thenReturn(const ChapterData(images: []));

      final result = await source.getRelated('original');

      // Should filter out the original series
      expect(result.length, equals(2));
      expect(result.any((c) => c.id == 'original'), isFalse);
    });

    test('returns empty list when no tags available', () async {
      final mockSeriesDetail = CrotpediaSeriesDetail(
        slug: 'notags',
        title: 'Series without tags',
        coverUrl: 'https://example.com/notags.jpg',
        genres: {},
        chapters: [],
      );

      final detailResponse = Response(
        requestOptions: RequestOptions(path: '/baca/series/notags/'),
        data: '<html>detail html</html>',
        statusCode: 200,
      );

      when(mockDio.get(argThat(contains('/baca/series/'))))
          .thenAnswer((_) async => detailResponse);
      when(mockScraper.parseSeriesDetail(any)).thenReturn(mockSeriesDetail);

      final result = await source.getRelated('notags');

      expect(result, isEmpty);
    });

    test('returns empty list on error', () async {
      when(mockDio.get(any)).thenThrow(Exception('Related error'));

      final result = await source.getRelated('test-slug');

      expect(result, isEmpty);
      // getDetail throws, triggering one log, then outer catch logs again
      verify(mockLogger.e(any)).called(2);
    });
  });

  group('parseContentIdFromUrl', () {
    test('extracts slug from valid URL', () {
      final url = 'https://crotpedia.net/baca/series/my-series-slug/';
      final id = source.parseContentIdFromUrl(url);
      expect(id, equals('my-series-slug'));
    });

    test('returns null for invalid URL', () {
      final url = 'https://crotpedia.net/other-page/';
      final id = source.parseContentIdFromUrl(url);
      expect(id, isNull);
    });
  });

  group('isValidContentId', () {
    test('returns true for valid slug', () {
      expect(source.isValidContentId('valid-slug'), isTrue);
      expect(source.isValidContentId('another-valid-slug-123'), isTrue);
    });

    test('returns false for invalid slug', () {
      expect(source.isValidContentId(''), isFalse);
      expect(source.isValidContentId('invalid/slug'), isFalse);
    });
  });

  group('getChapterImages', () {
    test('fetches and parses chapter images', () async {
      final mockChapterData = ChapterData(
        images: [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
          'https://example.com/img3.jpg',
        ],
        prevChapterId: 'chapter-0',
        nextChapterId: 'chapter-2',
      );

      final response = Response(
        requestOptions: RequestOptions(path: '/baca/chapter-slug/'),
        data: '<html>chapter html</html>',
        statusCode: 200,
      );

      when(mockDio.get(any)).thenAnswer((_) async => response);
      when(mockScraper.parseChapterImages(any)).thenReturn(mockChapterData);

      final result = await source.getChapterImages('chapter-slug');

      expect(result.images.length, equals(3));
      expect(result.images, equals(mockChapterData.images));
      expect(result.prevChapterId, equals('chapter-0'));
      expect(result.nextChapterId, equals('chapter-2'));
      verify(mockDio.get(argThat(contains('chapter-slug')))).called(1);
    });

    test('returns empty ChapterData on error', () async {
      when(mockDio.get(any)).thenThrow(Exception('Chapter error'));

      final result = await source.getChapterImages('chapter-slug');

      expect(result.images, isEmpty);
      expect(result, isA<ChapterData>());
      verify(mockLogger.e(any)).called(1);
    });
  });

  group('toggleBookmark', () {
    test('toggles bookmark when logged in', () async {
      when(mockAuthManager.isLoggedIn).thenReturn(true);
      when(mockAuthManager.toggleBookmark(any, any))
          .thenAnswer((_) async => true);

      final result = await source.toggleBookmark('test-id', false);

      expect(result, isTrue);
      verify(mockAuthManager.toggleBookmark('test-id', true)).called(1);
    });

    test('throws when not logged in', () async {
      when(mockAuthManager.isLoggedIn).thenReturn(false);

      expect(
        () => source.toggleBookmark('test-id', true),
        throwsA(isA<Exception>()),
      );

      verifyNever(mockAuthManager.toggleBookmark(any, any));
    });
  });

  group('Auth delegation', () {
    test('login delegates to auth manager', () async {
      final mockResult = CrotpediaAuthResult.success('testuser');
      when(mockAuthManager.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
        rememberMe: anyNamed('rememberMe'),
      )).thenAnswer((_) async => mockResult);

      final result = await source.login(
        email: 'test@example.com',
        password: 'pass123',
        rememberMe: true,
      );

      expect(result.success, isTrue);
      expect(result.username, equals('testuser'));
      verify(mockAuthManager.login(
        email: 'test@example.com',
        password: 'pass123',
        rememberMe: true,
      )).called(1);
    });

    test('tryAutoLogin delegates to auth manager', () async {
      when(mockAuthManager.tryAutoLogin()).thenAnswer((_) async => true);

      final result = await source.tryAutoLogin();

      expect(result, isTrue);
      verify(mockAuthManager.tryAutoLogin()).called(1);
    });

    test('isLoggedIn delegates to auth manager', () {
      when(mockAuthManager.isLoggedIn).thenReturn(true);

      expect(source.isLoggedIn, isTrue);
      verify(mockAuthManager.isLoggedIn).called(1);
    });

    test('authState delegates to auth manager', () {
      when(mockAuthManager.state).thenReturn(CrotpediaAuthState.loggedIn);

      expect(source.authState, equals(CrotpediaAuthState.loggedIn));
      verify(mockAuthManager.state).called(1);
    });

    test('username delegates to auth manager', () {
      when(mockAuthManager.username).thenReturn('testuser');

      expect(source.username, equals('testuser'));
      verify(mockAuthManager.username).called(1);
    });

    test('hasStoredCredentials delegates to auth manager', () async {
      when(mockAuthManager.hasStoredCredentials())
          .thenAnswer((_) async => true);

      final result = await source.hasStoredCredentials();

      expect(result, isTrue);
      verify(mockAuthManager.hasStoredCredentials()).called(1);
    });

    test('logout delegates to auth manager', () async {
      when(mockAuthManager.logout()).thenAnswer((_) async {});

      await source.logout();

      verify(mockAuthManager.logout()).called(1);
    });

    test('registerUrl delegates to auth manager', () {
      when(mockAuthManager.registerUrl)
          .thenReturn('https://crotpedia.net/register/');

      expect(source.registerUrl, equals('https://crotpedia.net/register/'));
      verify(mockAuthManager.registerUrl).called(1);
    });
  });
}
