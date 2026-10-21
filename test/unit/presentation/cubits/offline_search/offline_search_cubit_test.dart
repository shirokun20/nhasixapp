import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/domain/entities/download_status.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';
import 'package:nhasixapp/presentation/models/content_group.dart';

class MockOfflineContentManager extends Mock implements OfflineContentManager {}

class MockUserDataRepository extends Mock implements UserDataRepository {}

class MockLogger extends Mock implements Logger {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late OfflineSearchCubit cubit;
  late MockOfflineContentManager mockOfflineContentManager;
  late MockUserDataRepository mockUserDataRepository;
  late MockLogger mockLogger;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockOfflineContentManager = MockOfflineContentManager();
    mockUserDataRepository = MockUserDataRepository();
    mockLogger = MockLogger();
    mockPrefs = MockSharedPreferences();

    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

    when(() => mockUserDataRepository.getDownloadCountsBySource())
        .thenAnswer((_) async => const <String, int>{});

    cubit = OfflineSearchCubit(
      offlineContentManager: mockOfflineContentManager,
      userDataRepository: mockUserDataRepository,
      logger: mockLogger,
      prefs: mockPrefs,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('ContentGroup dedupes duplicate offline entries with same path/title',
      () {
    Content content(String id) => Content(
          id: id,
          title: '(GIF)First Meeting on Aocang[Ai generated] - Part 1',
          coverUrl: '/downloads/ehentai/aocang-part-1/images/page_001.webp',
          sourceId: 'ehentai',
          tags: const [],
          artists: const [],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: '',
          pageCount: 12,
          imageUrls: const [],
          uploadDate: DateTime.fromMillisecondsSinceEpoch(0),
          favorites: 0,
        );

    final group = ContentGroup(
      baseTitle: '(GIF)First Meeting on Aocang[Ai generated]',
      items: [content('old-id'), content('new-id')],
      totalSize: 1,
    );

    expect(group.items, hasLength(1));
    expect(group.chapterCount, 1);
    expect(ContentGroup.dedupeItems([content('old-id'), content('new-id')]),
        hasLength(1));
  });

  group('OfflineSearchCubit Pagination', () {
    const tContentId = '123';
    const tDownloadStatus = DownloadStatus(
      contentId: tContentId,
      state: DownloadState.completed,
      title: 'Test Title',
      totalPages: 10,
      downloadPath: '/path/to/download',
      fileSize: 1024,
    );
    final tDownloadList = [tDownloadStatus];

    test('initial state is OfflineSearchInitial', () {
      expect(cubit.state, isA<OfflineSearchInitial>());
    });

    blocTest<OfflineSearchCubit, OfflineSearchState>(
      'getAllOfflineContent should load first page correctly',
      build: () {
        // Group-level pagination fetches all filtered rows at once.
        when(() => mockUserDataRepository.getAllDownloads(
              state: DownloadState.completed,
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => tDownloadList);

        when(() => mockUserDataRepository.getDownloadsCount(
              state: DownloadState.completed,
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => 1);

        when(() => mockOfflineContentManager.getOfflineFirstImagePath(
              any(),
              downloadPath: any(named: 'downloadPath'),
            )).thenAnswer((_) async => '/path/to/image.jpg');

        when(() => mockUserDataRepository.getHistoryEntry(any()))
            .thenAnswer((_) async => null);

        return cubit;
      },
      act: (cubit) => cubit.getAllOfflineContent(),
      expect: () => [
        isA<OfflineSearchLoading>(),
        isA<OfflineSearchLoaded>()
            .having((s) => s.results.length, 'results length', 1)
            .having((s) => s.totalResults, 'totalResults', 1)
            .having((s) => s.currentPage, 'currentPage', 1)
            .having((s) => s.hasMore, 'hasMore', false)
            .having(
                (s) => s.availableSourceIds, 'availableSourceIds', ['nhentai']),
      ],
    );

    blocTest<OfflineSearchCubit, OfflineSearchState>(
      'filterBySource keeps source counts instead of dropping to bare loading',
      build: () {
        when(() => mockUserDataRepository.getAllDownloads(
              state: DownloadState.completed,
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => tDownloadList);

        when(() => mockUserDataRepository.getDownloadCountsBySource())
            .thenAnswer((_) async => const {'nhentai': 3});

        when(() => mockOfflineContentManager.getOfflineFirstImagePath(
              any(),
              downloadPath: any(named: 'downloadPath'),
            )).thenAnswer((_) async => '/path/to/image.jpg');

        when(() => mockUserDataRepository.getHistoryEntry(any()))
            .thenAnswer((_) async => null);

        return cubit;
      },
      seed: () => const OfflineSearchLoaded(
        query: '',
        results: [],
        totalResults: 0,
        availableSourceIds: ['nhentai'],
        sourceCounts: {'nhentai': 3},
      ),
      act: (cubit) => cubit.filterBySource('nhentai'),
      expect: () => [
        // No bare OfflineSearchLoading in between: the reload keeps the
        // payload and only flips isRefreshing.
        isA<OfflineSearchLoaded>()
            .having((s) => s.selectedSourceId, 'selectedSourceId', 'nhentai'),
        isA<OfflineSearchLoaded>()
            .having((s) => s.isRefreshing, 'isRefreshing', true)
            .having((s) => s.sourceCounts, 'sourceCounts', {'nhentai': 3})
            .having((s) => s.availableSourceIds, 'buckets', ['nhentai']),
        isA<OfflineSearchLoaded>()
            .having((s) => s.isRefreshing, 'isRefreshing', false)
            .having((s) => s.sourceCounts, 'sourceCounts', {'nhentai': 3}),
      ],
    );

    blocTest<OfflineSearchCubit, OfflineSearchState>(
      'loadMoreContent should append items when hasMore is true',
      build: () {
        // Mock initial state as loaded
        final initialContentGroup = ContentGroup(
          baseTitle: 'Initial',
          items: [
            Content(
              id: 'initial',
              title: 'Initial',
              coverUrl: '',
              sourceId: 'nhentai',
              tags: [],
              artists: [],
              characters: [],
              parodies: [],
              groups: [],
              language: '',
              pageCount: 0,
              imageUrls: [],
              uploadDate: DateTime.now(),
              favorites: 0,
            ),
          ],
          totalSize: 0,
          readProgress: 0.0,
          isRead: false,
          isReading: false,
        );

        // Group pagination re-fetches the whole filtered set on loadMore,
        // so the mock returns the full dataset (initial + new row).
        const initialDownload = DownloadStatus(
          contentId: 'initial',
          state: DownloadState.completed,
          title: 'Initial',
          totalPages: 5,
          downloadPath: '/path/to/initial',
          fileSize: 512,
        );

        // Setup mocks for loadMore call
        when(() => mockUserDataRepository.getAllDownloads(
              state: DownloadState.completed,
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              sourceId: any(named: 'sourceId'),
              orderBy: any(named: 'orderBy'),
              descending: any(named: 'descending'),
            )).thenAnswer((_) async => [initialDownload, ...tDownloadList]);

        when(() => mockUserDataRepository.getDownloadsCount(
              state: DownloadState.completed,
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => 2); // Total 2 items

        when(() => mockOfflineContentManager.getOfflineFirstImagePath(
              any(),
              downloadPath: any(named: 'downloadPath'),
            )).thenAnswer((_) async => '/path/to/image.jpg');

        when(() => mockUserDataRepository.getHistoryEntry(any()))
            .thenAnswer((_) async => null);

        cubit.emit(OfflineSearchLoaded(
          query: '',
          results: [initialContentGroup],
          totalResults: 2,
          currentPage: 1,
          hasMore: true,
          isLoadingMore: false,
        ));

        return cubit;
      },
      act: (cubit) => cubit.loadMoreContent(),
      expect: () => [
        isA<OfflineSearchLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<OfflineSearchLoaded>()
            .having((s) => s.results.length, 'results length', 2)
            .having((s) => s.currentPage, 'currentPage', 1)
            .having((s) => s.hasMore, 'hasMore', false)
            .having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );
  });

  group('OfflineSearchCubit Group Pagination (offline-ai-polish-pack)', () {
    DownloadStatus dl(String id, String title, {String? sourceId}) =>
        DownloadStatus(
          contentId: id,
          state: DownloadState.completed,
          title: title,
          totalPages: 10,
          downloadPath: '/dl/$id',
          fileSize: 100,
          sourceId: sourceId,
        );

    void stubCovers() {
      when(() => mockOfflineContentManager.getOfflineFirstImagePath(
                any(),
                downloadPath: any(named: 'downloadPath'),
              ))
          .thenAnswer((inv) =>
              Future.value('/img/${inv.positionalArguments.first}.jpg'));
    }

    void stubGetAll(List<DownloadStatus> rows) {
      when(() => mockUserDataRepository.getAllDownloads(
            state: DownloadState.completed,
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            sourceId: any(named: 'sourceId'),
            orderBy: any(named: 'orderBy'),
            descending: any(named: 'descending'),
          )).thenAnswer((inv) async {
        final sid = inv.namedArguments[#sourceId] as String?;
        final offset = inv.namedArguments[#offset] as int? ?? 0;
        final limit = inv.namedArguments[#limit] as int? ?? 100;
        final filtered = sid == null
            ? rows
            : rows.where((r) => (r.sourceId ?? 'nhentai') == sid).toList();
        if (offset >= filtered.length) return [];
        return filtered.skip(offset).take(limit).toList();
      });
    }

    List<String> distinctWords(int count) {
      const words = [
        'Alpha',
        'Beta',
        'Gamma',
        'Delta',
        'Epsilon',
        'Zeta',
        'Eta',
        'Theta',
        'Iota',
        'Kappa',
        'Lambda',
        'Mu',
        'Nu',
        'Xi',
        'Omicron',
        'Pi',
        'Rho',
        'Sigma',
        'Tau',
        'Upsilon',
        'Phi',
        'Chi',
        'Psi',
        'Omega',
        'Prime',
        'Nova',
        'Vega',
        'Lyra',
        'Orion',
        'Draco',
      ];
      return words.take(count).toList();
    }

    test('25 distinct series paginate 20 + 5 with group counts', () async {
      final rows = [
        for (var i = 0; i < 25; i++)
          dl('c$i', 'Series ${distinctWords(25)[i]}'),
      ];
      stubCovers();
      stubGetAll(rows);

      await cubit.getAllOfflineContent();
      var loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 20);
      expect(loaded.totalResults, 25);
      expect(loaded.currentPage, 1);
      expect(loaded.totalPages, 2);
      expect(loaded.hasMore, true);

      await cubit.loadMoreContent();
      loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 25);
      expect(loaded.totalResults, 25);
      expect(loaded.currentPage, 2);
      expect(loaded.hasMore, false);
    });

    test('single series with 20 chapters yields 1 group, hasMore false',
        () async {
      final rows = [
        for (var i = 1; i <= 20; i++) dl('ch$i', 'Epic Series Chapter $i'),
      ];
      stubCovers();
      stubGetAll(rows);

      await cubit.getAllOfflineContent();
      final loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 1);
      expect(loaded.results.first.chapterCount, 20);
      expect(loaded.totalResults, 1);
      expect(loaded.hasMore, false);
    });

    test('search results group first, then slice per page', () async {
      final words = distinctWords(30);
      final rows = [
        for (var i = 0; i < 30; i++)
          {
            'id': 's$i',
            'source_id': 'nhentai',
            'title': 'Hit ${words[i]}',
            'file_size': 50,
            'total_pages': 8,
            'download_path': '/dl/s$i',
          },
      ];
      stubCovers();
      when(() => mockUserDataRepository.searchDownloads(
            query: any(named: 'query'),
            state: DownloadState.completed,
            sourceId: any(named: 'sourceId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            orderBy: any(named: 'orderBy'),
            descending: any(named: 'descending'),
          )).thenAnswer((inv) async {
        final offset = inv.namedArguments[#offset] as int? ?? 0;
        final limit = inv.namedArguments[#limit] as int? ?? 100;
        if (offset >= rows.length) return [];
        return rows.skip(offset).take(limit).toList();
      });

      await cubit.searchOfflineContent('hit');
      var loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 20);
      expect(loaded.totalResults, 30);
      expect(loaded.hasMore, true);

      await cubit.searchOfflineContent('hit', loadMore: true);
      loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 30);
      expect(loaded.totalResults, 30);
      expect(loaded.hasMore, false);
    });

    test('source buckets listed, filter persists and keeps buckets', () async {
      final rows = [
        dl('h1', 'Hitomi One', sourceId: 'hitomi'),
        dl('h2', 'Hitomi Two', sourceId: 'hitomi'),
        dl('n1', 'Nhentai One', sourceId: 'nhentai'),
        dl('l1', 'Local One', sourceId: 'local'),
      ];
      stubCovers();
      stubGetAll(rows);

      await cubit.getAllOfflineContent();
      var loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.availableSourceIds, ['hitomi', 'local', 'nhentai']);

      await cubit.filterBySource('hitomi');
      loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.selectedSourceId, 'hitomi');
      expect(loaded.totalResults, 2);
      expect(
          loaded.results
              .every((g) => g.representativeContent.sourceId == 'hitomi'),
          true);
      // Buckets survive filtering.
      expect(loaded.availableSourceIds, ['hitomi', 'local', 'nhentai']);
      verify(() =>
              mockPrefs.setString('offline_selected_source_filter', 'hitomi'))
          .called(1);
    });

    test('changing sort resets pagination to page 1', () async {
      final rows = [
        for (var i = 0; i < 25; i++)
          dl('c$i', 'Series ${distinctWords(25)[i]}'),
      ];
      stubCovers();
      stubGetAll(rows);

      await cubit.getAllOfflineContent();
      await cubit.loadMoreContent();
      var loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 25);

      await cubit.changeSorting(orderBy: 'title', descending: false);
      loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 20);
      expect(loaded.currentPage, 1);
      expect(loaded.hasMore, true);
    });

    test('loadMore fetches next window with cursor offset and caps results', () async {
      final rows = [
        for (var i = 0; i < 120; i++)
          dl('item_$i', 'DistinctSeries$i Chapter 1'),
      ];
      stubCovers();
      stubGetAll(rows);

      await cubit.getAllOfflineContent();
      var loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 20);

      // Verify first fetch was offset 0, limit 100
      verify(() => mockUserDataRepository.getAllDownloads(
            state: DownloadState.completed,
            limit: 100,
            offset: 0,
            sourceId: any(named: 'sourceId'),
            orderBy: any(named: 'orderBy'),
            descending: any(named: 'descending'),
          )).called(1);

      // Consume groups until batch 1 runs out (5 pages of 20 = 100 groups)
      for (var p = 0; p < 4; p++) {
        await cubit.loadMoreContent();
      }
      loaded = cubit.state as OfflineSearchLoaded;
      expect(loaded.results.length, 100);

      // Now load 6th page: triggers cursor fetch at offset 100
      await cubit.loadMoreContent();
      verify(() => mockUserDataRepository.getAllDownloads(
            state: DownloadState.completed,
            limit: 100,
            offset: 100,
            sourceId: any(named: 'sourceId'),
            orderBy: any(named: 'orderBy'),
            descending: any(named: 'descending'),
          )).called(1);
    });
  });
}
