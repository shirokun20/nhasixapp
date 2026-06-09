import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/domain/entities/history.dart';
import 'package:nhasixapp/domain/entities/download_status.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_library_models.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';

class MockOfflineContentManager extends Mock implements OfflineContentManager {}

class MockUserDataRepository extends Mock implements UserDataRepository {}

class MockLogger extends Mock implements Logger {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class _OfflineFixture {
  const _OfflineFixture({
    required this.content,
    required this.resolvedPath,
    required this.metadata,
  });

  final Content content;
  final String resolvedPath;
  final Map<String, dynamic> metadata;
}

_OfflineFixture _buildFixture({
  required String id,
  required String title,
  required String rawSourceId,
  required DateTime downloadedAt,
  required int imageCount,
  String? resolvedPathOverride,
  Map<String, dynamic>? metadata,
}) {
  final resolvedPath =
      resolvedPathOverride ?? '/virtual/nhasix/$rawSourceId/$id';
  final content = Content(
    id: id,
    sourceId: rawSourceId,
    title: title,
    coverUrl: '$resolvedPath/images/page_001.jpg',
    tags: const [],
    artists: const [],
    characters: const [],
    parodies: const [],
    groups: const [],
    language: 'en',
    pageCount: imageCount,
    imageUrls: ['$resolvedPath/images/page_001.jpg'],
    uploadDate: downloadedAt,
    favorites: 0,
  );

  return _OfflineFixture(
    content: content,
    resolvedPath: resolvedPath,
    metadata: {
      'id': id,
      'title': title,
      'rawSourceId': rawSourceId,
      'downloadedAt': downloadedAt.toIso8601String(),
      'resolvedImageCount': imageCount,
      ...?metadata,
    },
  );
}

void _stubOfflineScan({
  required MockOfflineContentManager offlineContentManager,
  required List<_OfflineFixture> fixtures,
}) {
  final fixturesById = {
    for (final fixture in fixtures) fixture.content.id: fixture,
  };
  final fixturesByPath = {
    for (final fixture in fixtures) fixture.resolvedPath: fixture,
  };

  when(() => offlineContentManager.scanBackupFolder(any())).thenAnswer(
    (_) async => fixtures.map((fixture) => fixture.content).toList(),
  );

  when(
    () => offlineContentManager.getRawOfflineMetadata(
      contentId: any(named: 'contentId'),
      contentPath: any(named: 'contentPath'),
    ),
  ).thenAnswer((invocation) async {
    final contentId = invocation.namedArguments[#contentId] as String?;
    final contentPath = invocation.namedArguments[#contentPath] as String?;
    if (contentPath != null) {
      return fixturesByPath[contentPath]?.metadata;
    }
    if (contentId != null) {
      return fixturesById[contentId]?.metadata;
    }
    return null;
  });

  when(
    () => offlineContentManager.resolveStoredSourceId(
      metadata: any(named: 'metadata'),
      contentPath: any(named: 'contentPath'),
    ),
  ).thenAnswer((invocation) {
    final metadata =
        invocation.namedArguments[#metadata] as Map<String, dynamic>?;
    return metadata?['rawSourceId']?.toString() ?? 'local';
  });

  when(
    () => offlineContentManager.resolveOfflineStoragePath(
      contentId: any(named: 'contentId'),
      downloadPath: any(named: 'downloadPath'),
      contentPath: any(named: 'contentPath'),
      imageUrls: any(named: 'imageUrls'),
    ),
  ).thenAnswer((invocation) async {
    final contentId = invocation.namedArguments[#contentId] as String?;
    final downloadPath = invocation.namedArguments[#downloadPath] as String?;
    final contentPath = invocation.namedArguments[#contentPath] as String?;
    if (contentId != null && fixturesById.containsKey(contentId)) {
      return fixturesById[contentId]!.resolvedPath;
    }
    if (downloadPath != null && downloadPath.isNotEmpty) {
      return downloadPath;
    }
    return contentPath;
  });

  when(
    () => offlineContentManager.resolveOfflineImageCount(
      contentId: any(named: 'contentId'),
      contentPath: any(named: 'contentPath'),
      metadata: any(named: 'metadata'),
    ),
  ).thenAnswer((invocation) async {
    final metadata =
        invocation.namedArguments[#metadata] as Map<String, dynamic>?;
    return metadata?['resolvedImageCount'] as int? ?? 0;
  });
}

void main() {
  late OfflineSearchCubit cubit;
  late MockOfflineContentManager mockOfflineContentManager;
  late MockUserDataRepository mockUserDataRepository;
  late MockLogger mockLogger;
  late MockRemoteConfigService mockRemoteConfigService;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    mockOfflineContentManager = MockOfflineContentManager();
    mockUserDataRepository = MockUserDataRepository();
    mockLogger = MockLogger();
    mockRemoteConfigService = MockRemoteConfigService();

    await getIt.reset();
    getIt.registerSingleton<RemoteConfigService>(mockRemoteConfigService);

    when(() => mockRemoteConfigService.getAllSourceConfigs()).thenReturn([
      SourceConfig(
        source: 'nhentai',
        version: '1.0.0',
        ui: UiConfig(
          displayName: 'NHentai',
          iconPath: 'icons/nhentai.svg',
        ),
      ),
    ]);

    when(
      () => mockUserDataRepository.getAllDownloads(
        state: any(named: 'state'),
        sourceId: any(named: 'sourceId'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        orderBy: any(named: 'orderBy'),
        descending: any(named: 'descending'),
      ),
    ).thenAnswer((_) async => const <DownloadStatus>[]);

    when(() => mockUserDataRepository.getHistoryEntry(any()))
        .thenAnswer((_) async => null);
    when(() => mockOfflineContentManager.getBackupRootPath())
        .thenAnswer((_) async => '/virtual/nhasix');

    cubit = OfflineSearchCubit(
      offlineContentManager: mockOfflineContentManager,
      userDataRepository: mockUserDataRepository,
      logger: mockLogger,
      prefs: prefs,
    );
  });

  tearDown(() async {
    await cubit.close();
    await getIt.reset();
  });

  group('OfflineSearchCubit offline library', () {
    test('uses date sort by default', () async {
      final fixtures = [
        _buildFixture(
          id: 'gallery-a',
          title: 'Alpha',
          rawSourceId: 'nhentai',
          downloadedAt: DateTime(2026, 1, 2),
          imageCount: 12,
        ),
        _buildFixture(
          id: 'gallery-b',
          title: 'Beta',
          rawSourceId: 'nhentai',
          downloadedAt: DateTime(2026, 1, 3),
          imageCount: 8,
        ),
        _buildFixture(
          id: 'gallery-c',
          title: 'Gamma',
          rawSourceId: 'local',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: 4,
        ),
      ];
      _stubOfflineScan(
        offlineContentManager: mockOfflineContentManager,
        fixtures: fixtures,
      );

      await cubit.getAllOfflineContent();

      final state = cubit.state as OfflineSearchLoaded;
      expect(
        state.results.map((content) => content.title).toList(),
        ['Beta', 'Alpha', 'Gamma'],
      );
      expect(state.sortMode, OfflineLibrarySortMode.date);
      expect(state.hasMore, isFalse);
    });

    test('image-count sort remains active during load more', () async {
      final fixtures = List.generate(
        25,
        (index) => _buildFixture(
          id: 'gallery-$index',
          title: 'Title ${String.fromCharCode(90 - index)}',
          rawSourceId: 'nhentai',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: index + 1,
        ),
      );
      _stubOfflineScan(
        offlineContentManager: mockOfflineContentManager,
        fixtures: fixtures,
      );

      await cubit.setSortMode(OfflineLibrarySortMode.imageCount);

      var state = cubit.state as OfflineSearchLoaded;
      expect(state.sortMode, OfflineLibrarySortMode.imageCount);
      expect(state.results.length, 20);
      expect(state.results.first.title, 'Title B');
      expect(state.items.first.imageCount, 25);
      expect(state.items.last.imageCount, 6);
      expect(state.hasMore, isTrue);

      await cubit.loadMoreContent();

      state = cubit.state as OfflineSearchLoaded;
      expect(state.sortMode, OfflineLibrarySortMode.imageCount);
      expect(state.results.length, 25);
      expect(state.items.first.imageCount, 25);
      expect(state.items.last.imageCount, 1);
      expect(state.hasMore, isFalse);
    });

    test('filter change keeps chosen sort mode and bucket selection', () async {
      final fixtures = [
        _buildFixture(
          id: 'installed-item',
          title: 'Zeta',
          rawSourceId: 'nhentai',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: 20,
        ),
        _buildFixture(
          id: 'local-item',
          title: 'Alpha',
          rawSourceId: 'local',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: 5,
        ),
        _buildFixture(
          id: 'other-item',
          title: 'Beta',
          rawSourceId: 'mangafire',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: 8,
        ),
      ];
      _stubOfflineScan(
        offlineContentManager: mockOfflineContentManager,
        fixtures: fixtures,
      );

      await cubit.setSortMode(OfflineLibrarySortMode.title);
      await cubit.filterBySource(OfflineSourceFilterOption.localId);

      final state = cubit.state as OfflineSearchLoaded;
      expect(state.sortMode, OfflineLibrarySortMode.title);
      expect(state.selectedFilterId, OfflineSourceFilterOption.localId);
      expect(state.results.map((content) => content.title).toList(), ['Alpha']);
      expect(
        state.availableFilters.map((filter) => filter.id).toList(),
        containsAll([
          OfflineSourceFilterOption.allId,
          'nhentai',
          OfflineSourceFilterOption.localId,
          OfflineSourceFilterOption.otherId,
        ]),
      );
    });

    test('switching from local bucket back to all clears the active filter',
        () async {
      final fixtures = [
        _buildFixture(
          id: 'installed-item',
          title: 'Zeta',
          rawSourceId: 'nhentai',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: 20,
        ),
        _buildFixture(
          id: 'local-item',
          title: 'Alpha',
          rawSourceId: 'local',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: 5,
        ),
      ];
      _stubOfflineScan(
        offlineContentManager: mockOfflineContentManager,
        fixtures: fixtures,
      );

      await cubit.filterBySource(OfflineSourceFilterOption.localId);
      var state = cubit.state as OfflineSearchLoaded;
      expect(state.selectedFilterId, OfflineSourceFilterOption.localId);
      expect(state.results.map((content) => content.title).toList(), ['Alpha']);

      await cubit.filterBySource(null);

      state = cubit.state as OfflineSearchLoaded;
      expect(state.selectedFilterId, isNull);
      expect(
        state.results.map((content) => content.title).toList(),
        ['Alpha', 'Zeta'],
      );
    });

    test('derives parent grouping and keeps child paths', () async {
      final fixtures = [
        _buildFixture(
          id: 'series/chapter-2',
          title: 'Series - Chapter 2',
          rawSourceId: 'mangafire',
          downloadedAt: DateTime(2026, 1, 2),
          imageCount: 10,
          metadata: {
            'parentId': 'series-parent',
            'chapterIndex': 2,
            'chapterTitle': 'Chapter 2',
          },
        ),
        _buildFixture(
          id: 'series/chapter-1',
          title: 'Series - Chapter 1',
          rawSourceId: 'mangafire',
          downloadedAt: DateTime(2026, 1, 1),
          imageCount: 9,
          metadata: {
            'parentId': 'series-parent',
            'chapterIndex': 1,
            'chapterTitle': 'Chapter 1',
          },
        ),
      ];
      _stubOfflineScan(
        offlineContentManager: mockOfflineContentManager,
        fixtures: fixtures,
      );
      when(() => mockUserDataRepository.getHistoryEntry('series-parent'))
          .thenAnswer(
        (_) async => History(
          contentId: 'series-parent',
          sourceId: 'mangafire',
          lastViewed: DateTime(2026, 1, 5),
          title: 'Series Title',
        ),
      );

      await cubit.getAllOfflineContent();

      final state = cubit.state as OfflineSearchLoaded;
      expect(state.displayOrder.length, 1);
      expect(state.groupsByKey.length, 1);

      final group = state.groupsByKey.values.first;
      expect(group.parentTitle, 'Series Title');
      expect(group.children.map((item) => item.childLabel).toList(), [
        'Chapter 1',
        'Chapter 2',
      ]);
      expect(group.children.first.resolvedPath, fixtures[1].resolvedPath);
      expect(group.children.last.resolvedPath, fixtures[0].resolvedPath);
    });

    test('deduplicates scanned content when db entry still uses safe folder id',
        () async {
      final fixture = _buildFixture(
        id: 'chapter-72-original-id',
        title: 'Chapter 72',
        rawSourceId: 'komiku',
        downloadedAt: DateTime(2026, 1, 2),
        imageCount: 18,
        resolvedPathOverride: '/virtual/nhasix/komiku/2qbiiejj4x',
      );
      _stubOfflineScan(
        offlineContentManager: mockOfflineContentManager,
        fixtures: [fixture],
      );

      when(
        () => mockUserDataRepository.getAllDownloads(
          state: any(named: 'state'),
          sourceId: any(named: 'sourceId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          orderBy: any(named: 'orderBy'),
          descending: any(named: 'descending'),
        ),
      ).thenAnswer(
        (_) async => [
          DownloadStatus(
            contentId: '2qbiiejj4x',
            state: DownloadState.completed,
            downloadedPages: 18,
            totalPages: 18,
            downloadPath: fixture.resolvedPath,
            fileSize: 6200,
            title: 'Chapter 72',
            sourceId: 'komiku',
          ),
        ],
      );

      await cubit.getAllOfflineContent();

      final state = cubit.state as OfflineSearchLoaded;
      expect(state.results, hasLength(1));
      expect(state.items.single.content.id, fixture.content.id);
      expect(state.items.single.resolvedPath, fixture.resolvedPath);
    });

    test('chapter-mode items keep two children instead of doubling to four',
        () async {
      final fixtures = [
        _buildFixture(
          id: 'chapter-72-original-id',
          title: 'Series - Chapter 72',
          rawSourceId: 'komiku',
          downloadedAt: DateTime(2026, 1, 2),
          imageCount: 18,
          resolvedPathOverride: '/virtual/nhasix/komiku/2qbiiejj4x',
          metadata: {
            'parentId': 'series-parent',
            'chapterIndex': 72,
            'chapterTitle': 'Chapter 72',
          },
        ),
        _buildFixture(
          id: 'chapter-73-original-id',
          title: 'Series - Chapter 73',
          rawSourceId: 'komiku',
          downloadedAt: DateTime(2026, 1, 3),
          imageCount: 21,
          resolvedPathOverride: '/virtual/nhasix/komiku/9orw3pvat',
          metadata: {
            'parentId': 'series-parent',
            'chapterIndex': 73,
            'chapterTitle': 'Chapter 73',
          },
        ),
      ];
      _stubOfflineScan(
        offlineContentManager: mockOfflineContentManager,
        fixtures: fixtures,
      );
      when(() => mockUserDataRepository.getHistoryEntry('series-parent'))
          .thenAnswer(
        (_) async => History(
          contentId: 'series-parent',
          sourceId: 'komiku',
          lastViewed: DateTime(2026, 1, 5),
          title: 'Series Title',
        ),
      );
      when(
        () => mockUserDataRepository.getAllDownloads(
          state: any(named: 'state'),
          sourceId: any(named: 'sourceId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          orderBy: any(named: 'orderBy'),
          descending: any(named: 'descending'),
        ),
      ).thenAnswer(
        (_) async => [
          DownloadStatus(
            contentId: '2qbiiejj4x',
            state: DownloadState.completed,
            downloadedPages: 18,
            totalPages: 18,
            downloadPath: fixtures[0].resolvedPath,
            fileSize: 6200,
            title: 'Series - Chapter 72',
            sourceId: 'komiku',
          ),
          DownloadStatus(
            contentId: '9orw3pvat',
            state: DownloadState.completed,
            downloadedPages: 21,
            totalPages: 21,
            downloadPath: fixtures[1].resolvedPath,
            fileSize: 7100,
            title: 'Series - Chapter 73',
            sourceId: 'komiku',
          ),
        ],
      );

      await cubit.getAllOfflineContent();

      final state = cubit.state as OfflineSearchLoaded;
      expect(state.displayOrder, hasLength(1));
      expect(state.groupsByKey, hasLength(1));

      final group = state.groupsByKey.values.single;
      expect(group.parentTitle, 'Series Title');
      expect(group.children, hasLength(2));
      expect(
        group.children.map((item) => item.childLabel).toList(),
        ['Chapter 72', 'Chapter 73'],
      );
    });

    test('deduplicates duplicate db rows that point to the same folder',
        () async {
      when(() => mockOfflineContentManager.scanBackupFolder(any()))
          .thenAnswer((_) async => const <Content>[]);
      when(
        () => mockOfflineContentManager.getRawOfflineMetadata(
          contentId: any(named: 'contentId'),
          contentPath: any(named: 'contentPath'),
        ),
      ).thenAnswer((invocation) async {
        final contentId = invocation.namedArguments[#contentId] as String?;
        if (contentId == 'chapter-73-original-id') {
          return {
            'id': 'chapter-73-original-id',
            'title': 'Chapter 73',
            'rawSourceId': 'komiku',
            'resolvedImageCount': 21,
          };
        }
        return null;
      });
      when(
        () => mockOfflineContentManager.resolveStoredSourceId(
          metadata: any(named: 'metadata'),
          contentPath: any(named: 'contentPath'),
        ),
      ).thenReturn('komiku');
      when(
        () => mockOfflineContentManager.resolveOfflineStoragePath(
          contentId: any(named: 'contentId'),
          downloadPath: any(named: 'downloadPath'),
          contentPath: any(named: 'contentPath'),
          imageUrls: any(named: 'imageUrls'),
        ),
      ).thenAnswer((invocation) async {
        final downloadPath =
            invocation.namedArguments[#downloadPath] as String?;
        return downloadPath ?? '/virtual/nhasix/komiku/9orw3pvat';
      });
      when(
        () => mockOfflineContentManager.getOfflineFirstImagePath(
          any(),
          downloadPath: any(named: 'downloadPath'),
        ),
      ).thenAnswer((invocation) async {
        final downloadPath =
            invocation.namedArguments[#downloadPath] as String?;
        return '$downloadPath/images/page_001.webp';
      });
      when(
        () => mockOfflineContentManager.resolveOfflineImageCount(
          contentId: any(named: 'contentId'),
          contentPath: any(named: 'contentPath'),
          metadata: any(named: 'metadata'),
        ),
      ).thenAnswer((_) async => 21);

      const sharedPath = '/virtual/nhasix/komiku/9orw3pvat';
      when(
        () => mockUserDataRepository.getAllDownloads(
          state: any(named: 'state'),
          sourceId: any(named: 'sourceId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          orderBy: any(named: 'orderBy'),
          descending: any(named: 'descending'),
        ),
      ).thenAnswer(
        (_) async => const [
          DownloadStatus(
            contentId: '9orw3pvat',
            state: DownloadState.completed,
            downloadedPages: 21,
            totalPages: 21,
            downloadPath: sharedPath,
            fileSize: 7100,
            title: 'Chapter 73',
            sourceId: 'komiku',
          ),
          DownloadStatus(
            contentId: 'chapter-73-original-id',
            state: DownloadState.completed,
            downloadedPages: 21,
            totalPages: 21,
            downloadPath: sharedPath,
            fileSize: 7100,
            title: 'Chapter 73',
            sourceId: 'komiku',
          ),
        ],
      );

      await cubit.getAllOfflineContent();

      final state = cubit.state as OfflineSearchLoaded;
      expect(state.results, hasLength(1));
      expect(state.items.single.resolvedPath, sharedPath);
    });
  });
}
