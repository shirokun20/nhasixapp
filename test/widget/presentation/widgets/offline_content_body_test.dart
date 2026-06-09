import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/services/language_service.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/domain/entities/user_preferences.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_library_models.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';
import 'package:nhasixapp/presentation/cubits/settings/settings_cubit.dart';
import 'package:nhasixapp/presentation/widgets/offline_content_body.dart';
import 'package:nhasixapp/services/tag_blacklist_service.dart';

class MockOfflineSearchCubit extends MockCubit<OfflineSearchState>
    implements OfflineSearchCubit {}

class MockDownloadBloc extends MockBloc<DownloadEvent, DownloadBlocState>
    implements DownloadBloc {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class MockOfflineContentManager extends Mock implements OfflineContentManager {}

class MockTagBlacklistService extends Mock implements TagBlacklistService {}

class MockContentSource extends Mock implements ContentSource {}

final _fallbackContent = Content(
  id: 'fallback',
  title: 'Fallback',
  coverUrl: '',
  sourceId: 'nhentai',
  tags: [],
  artists: [],
  characters: [],
  parodies: [],
  groups: [],
  language: 'en',
  pageCount: 1,
  imageUrls: [],
  uploadDate: DateTime.fromMillisecondsSinceEpoch(0),
  favorites: 0,
);

void main() {
  late MockOfflineSearchCubit mockOfflineSearchCubit;
  late MockDownloadBloc mockDownloadBloc;
  late MockSettingsCubit mockSettingsCubit;
  late MockRemoteConfigService mockRemoteConfigService;
  late MockOfflineContentManager mockOfflineContentManager;
  late MockTagBlacklistService mockTagBlacklistService;
  late MockContentSource mockContentSource;

  setUpAll(() {
    registerFallbackValue(_fallbackContent);
    registerFallbackValue(OfflineLibrarySortMode.date);
  });

  setUp(() {
    mockOfflineSearchCubit = MockOfflineSearchCubit();
    mockDownloadBloc = MockDownloadBloc();
    mockSettingsCubit = MockSettingsCubit();
    mockRemoteConfigService = MockRemoteConfigService();
    mockOfflineContentManager = MockOfflineContentManager();
    mockTagBlacklistService = MockTagBlacklistService();
    mockContentSource = MockContentSource();

    final getIt = GetIt.instance;
    getIt.reset();
    final registry = ContentSourceRegistry();
    final languageService = LanguageService(logger: Logger());

    when(() => mockContentSource.id).thenReturn('nhentai');
    when(
      () => mockContentSource.getImageDownloadHeaders(
        imageUrl: any(named: 'imageUrl'),
        cookies: null,
      ),
    ).thenReturn(const <String, String>{});
    registry.register(mockContentSource);

    getIt.registerSingleton<OfflineSearchCubit>(mockOfflineSearchCubit);
    getIt.registerSingleton<ContentSourceRegistry>(registry);
    getIt.registerSingleton<LanguageService>(languageService);
    getIt.registerSingleton<RemoteConfigService>(mockRemoteConfigService);
    getIt.registerSingleton<OfflineContentManager>(mockOfflineContentManager);
    getIt.registerSingleton<TagBlacklistService>(mockTagBlacklistService);

    when(() => mockRemoteConfigService.getAllSourceConfigs()).thenReturn([]);
    when(() => mockTagBlacklistService.syncAllAvailableSources())
        .thenAnswer((_) async {});
    when(() => mockTagBlacklistService.addListener(any())).thenReturn(null);
    when(() => mockTagBlacklistService.removeListener(any())).thenReturn(null);
    when(
      () => mockTagBlacklistService.isContentBlacklisted(
        any(),
        localEntries: any(named: 'localEntries'),
      ),
    ).thenReturn(false);

    when(() => mockSettingsCubit.state).thenReturn(
      SettingsLoaded(
        preferences: const UserPreferences(
          blurThumbnails: false,
          blacklistedTags: [],
        ),
        lastUpdated: DateTime(2026, 1, 1),
      ),
    );
    when(() => mockSettingsCubit.getColumnsForOrientation(any())).thenReturn(2);
    when(() => mockDownloadBloc.state).thenReturn(const DownloadInitial());

    when(() => mockOfflineSearchCubit.getAllOfflineContent())
        .thenAnswer((_) async {});
    when(() => mockOfflineSearchCubit.searchOfflineContent(any()))
        .thenAnswer((_) async {});
    when(() => mockOfflineSearchCubit.loadMoreContent())
        .thenAnswer((_) async {});
    when(() => mockOfflineSearchCubit.setSortMode(any()))
        .thenAnswer((_) async {});
    when(() => mockOfflineSearchCubit.filterBySource(any()))
        .thenAnswer((_) async {});

    when(() => mockOfflineContentManager.getOfflineImageUrls(any()))
        .thenAnswer((_) async => const <String>[]);
    when(
      () => mockOfflineContentManager.resolveOfflineStoragePath(
        contentId: any(named: 'contentId'),
        downloadPath: any(named: 'downloadPath'),
        contentPath: any(named: 'contentPath'),
        imageUrls: any(named: 'imageUrls'),
      ),
    ).thenAnswer((_) async => null);
    when(() => mockOfflineContentManager.getOfflineFirstImagePath(
          any(),
          downloadPath: any(named: 'downloadPath'),
        )).thenAnswer((_) async => null);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('sort controls trigger cubit sort changes', (
    WidgetTester tester,
  ) async {
    when(() => mockOfflineSearchCubit.state).thenReturn(
        _loadedState(items: [_buildItem(id: 'id-1', title: 'One')]));

    await tester.pumpWidget(_createWidgetUnderTest(
      mockDownloadBloc: mockDownloadBloc,
      mockSettingsCubit: mockSettingsCubit,
      mockOfflineSearchCubit: mockOfflineSearchCubit,
    ));
    await tester.pump();

    await tester
        .tap(find.byKey(const ValueKey('offline-library-options-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('offline-sort-option-title')));
    await tester.pump();

    verify(
      () => mockOfflineSearchCubit.setSortMode(OfflineLibrarySortMode.title),
    ).called(1);
  });

  testWidgets('source filter controls use offline inventory buckets', (
    WidgetTester tester,
  ) async {
    when(() => mockOfflineSearchCubit.state).thenReturn(
      _loadedState(
        items: [
          _buildItem(id: 'id-1', title: 'Installed', rawSourceId: 'nhentai'),
          _buildItem(id: 'id-2', title: 'Manual Item', rawSourceId: 'local'),
        ],
        availableFilters: const [
          OfflineSourceFilterOption(
            id: OfflineSourceFilterOption.allId,
            kind: OfflineSourceBucketKind.all,
          ),
          OfflineSourceFilterOption(
            id: 'nhentai',
            kind: OfflineSourceBucketKind.installed,
            sourceId: 'nhentai',
            displayName: 'NHentai',
          ),
          OfflineSourceFilterOption(
            id: OfflineSourceFilterOption.localId,
            kind: OfflineSourceBucketKind.local,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_createWidgetUnderTest(
      mockDownloadBloc: mockDownloadBloc,
      mockSettingsCubit: mockSettingsCubit,
      mockOfflineSearchCubit: mockOfflineSearchCubit,
    ));
    await tester.pump();

    await tester
        .tap(find.byKey(const ValueKey('offline-library-options-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('offline-library-options-section-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey(
          'offline-filter-option-${OfflineSourceFilterOption.localId}',
        ),
      ),
    );
    await tester.pump();

    verify(
      () => mockOfflineSearchCubit.filterBySource(
        OfflineSourceFilterOption.localId,
      ),
    ).called(1);
  });

  testWidgets('library controls stay visible while the grid scrolls', (
    WidgetTester tester,
  ) async {
    when(() => mockOfflineSearchCubit.state).thenReturn(
      _loadedState(
        items: List.generate(
          60,
          (index) => _buildItem(id: 'id-$index', title: 'Item $index'),
        ),
      ),
    );

    await tester.pumpWidget(_createWidgetUnderTest(
      mockDownloadBloc: mockDownloadBloc,
      mockSettingsCubit: mockSettingsCubit,
      mockOfflineSearchCubit: mockOfflineSearchCubit,
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('offline-library-options-button')),
      findsOneWidget,
    );

    final grid = find.byType(GridView);
    final gesture = await tester.startGesture(tester.getCenter(grid));
    await gesture.moveBy(const Offset(0, -320));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -320));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('offline-library-options-button')),
      findsOneWidget,
    );
  });

  testWidgets('long press shows resolved storage path', (
    WidgetTester tester,
  ) async {
    final item = _buildItem(
      id: 'id-1',
      title: 'Offline One',
      rawSourceId: 'local',
      resolvedPath: '/backup/nhasix/local/id-1',
    );

    when(() => mockOfflineSearchCubit.state)
        .thenReturn(_loadedState(items: [item]));
    when(() => mockOfflineContentManager.resolveOfflineStoragePath(
          contentId: 'id-1',
          downloadPath: any(named: 'downloadPath'),
          contentPath: any(named: 'contentPath'),
          imageUrls: any(named: 'imageUrls'),
        )).thenAnswer((_) async => '/backup/nhasix/local/id-1');

    await tester.pumpWidget(_createWidgetUnderTest(
      mockDownloadBloc: mockDownloadBloc,
      mockSettingsCubit: mockSettingsCubit,
      mockOfflineSearchCubit: mockOfflineSearchCubit,
    ));
    await tester.pump();
    await tester.ensureVisible(find.text('Offline One'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Offline One'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Path'), findsOneWidget);
    expect(find.text('/backup/nhasix/local/id-1'), findsOneWidget);
  });

  testWidgets('grouped parent opens downloaded child list', (
    WidgetTester tester,
  ) async {
    final childOne = _buildItem(
      id: 'series-1',
      title: 'Series - Chapter 1',
      rawSourceId: 'mangafire',
      parentId: 'series-parent',
      parentTitle: 'Series Title',
      chapterTitle: 'Chapter 1',
      chapterIndex: 1,
    );
    final childTwo = _buildItem(
      id: 'series-2',
      title: 'Series - Chapter 2',
      rawSourceId: 'mangafire',
      parentId: 'series-parent',
      parentTitle: 'Series Title',
      chapterTitle: 'Chapter 2',
      chapterIndex: 2,
    );
    const groupKey = 'mangafire::series-parent';

    when(() => mockOfflineSearchCubit.state).thenReturn(
      _loadedState(
        items: [childOne, childTwo],
        displayOrder: const [groupKey],
        groupsByKey: {
          groupKey: OfflineLibraryGroupData(
            groupKey: groupKey,
            parentId: 'series-parent',
            parentTitle: 'Series Title',
            rawSourceId: 'mangafire',
            sourceBucketKind: OfflineSourceBucketKind.other,
            sourceDisplayName: 'mangafire',
            sourceFilterId: OfflineSourceFilterOption.otherId,
            sortDate: DateTime(2026, 1, 2),
            children: [childOne, childTwo],
          ),
        },
      ),
    );

    await tester.pumpWidget(_createWidgetUnderTest(
      mockDownloadBloc: mockDownloadBloc,
      mockSettingsCubit: mockSettingsCubit,
      mockOfflineSearchCubit: mockOfflineSearchCubit,
    ));
    await tester.pump();
    await tester.ensureVisible(find.text('Series Title'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Series Title'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.text('Chapter 2'), findsOneWidget);
  });

  testWidgets('infinite scroll still triggers loadMoreContent', (
    WidgetTester tester,
  ) async {
    final items = List.generate(
      20,
      (index) => _buildItem(id: 'id_$index', title: 'Title $index'),
    );

    when(() => mockOfflineSearchCubit.state).thenReturn(
      _loadedState(
        items: items,
        totalResults: 100,
        currentPage: 1,
        totalPages: 5,
        hasMore: true,
      ),
    );

    await tester.pumpWidget(_createWidgetUnderTest(
      mockDownloadBloc: mockDownloadBloc,
      mockSettingsCubit: mockSettingsCubit,
      mockOfflineSearchCubit: mockOfflineSearchCubit,
    ));
    await tester.pump();

    expect(find.text('Title 0'), findsOneWidget);

    final gridFinder = find.byType(GridView);
    expect(gridFinder, findsOneWidget);

    await tester.drag(gridFinder, const Offset(0, -5000));
    await tester.pump();

    verify(() => mockOfflineSearchCubit.loadMoreContent())
        .called(greaterThan(0));
  });
}

Widget _createWidgetUnderTest({
  required MockDownloadBloc mockDownloadBloc,
  required MockSettingsCubit mockSettingsCubit,
  required MockOfflineSearchCubit mockOfflineSearchCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<DownloadBloc>.value(value: mockDownloadBloc),
      BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
      BlocProvider<OfflineSearchCubit>.value(value: mockOfflineSearchCubit),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: Scaffold(
        body: OfflineContentBody(),
      ),
    ),
  );
}

OfflineSearchLoaded _loadedState({
  required List<OfflineLibraryItemData> items,
  List<OfflineSourceFilterOption>? availableFilters,
  List<String>? displayOrder,
  Map<String, OfflineLibraryGroupData>? groupsByKey,
  int? totalResults,
  int currentPage = 1,
  int totalPages = 1,
  bool hasMore = false,
  bool isLoadingMore = false,
  OfflineLibrarySortMode sortMode = OfflineLibrarySortMode.date,
  String? selectedFilterId,
}) {
  return OfflineSearchLoaded(
    query: '',
    items: items,
    totalResults: totalResults ?? items.length,
    currentPage: currentPage,
    totalPages: totalPages,
    hasMore: hasMore,
    isLoadingMore: isLoadingMore,
    sortMode: sortMode,
    selectedFilterId: selectedFilterId,
    availableFilters: availableFilters ??
        const [
          OfflineSourceFilterOption(
            id: OfflineSourceFilterOption.allId,
            kind: OfflineSourceBucketKind.all,
          ),
        ],
    displayOrder: displayOrder ??
        items.map((item) => item.stableId).toList(growable: false),
    groupsByKey: groupsByKey ?? const {},
  );
}

OfflineLibraryItemData _buildItem({
  required String id,
  required String title,
  String rawSourceId = 'nhentai',
  String? resolvedPath,
  String? parentId,
  String? parentTitle,
  String? chapterTitle,
  int? chapterIndex,
}) {
  final bucketKind = rawSourceId == 'local'
      ? OfflineSourceBucketKind.local
      : rawSourceId == 'nhentai'
          ? OfflineSourceBucketKind.installed
          : OfflineSourceBucketKind.other;
  final sourceFilterId = switch (bucketKind) {
    OfflineSourceBucketKind.local => OfflineSourceFilterOption.localId,
    OfflineSourceBucketKind.other => OfflineSourceFilterOption.otherId,
    OfflineSourceBucketKind.installed => rawSourceId,
    OfflineSourceBucketKind.all => OfflineSourceFilterOption.allId,
  };
  final sourceDisplayName = switch (bucketKind) {
    OfflineSourceBucketKind.local => 'local',
    OfflineSourceBucketKind.other => rawSourceId,
    OfflineSourceBucketKind.installed => 'NHentai',
    OfflineSourceBucketKind.all => 'All',
  };

  return OfflineLibraryItemData(
    content: Content(
      id: id,
      title: title,
      coverUrl: '',
      sourceId: rawSourceId,
      tags: const [],
      artists: const [],
      characters: const [],
      parodies: const [],
      groups: const [],
      language: 'en',
      pageCount: 12,
      imageUrls: const [],
      uploadDate: DateTime(2026, 1, 1),
      favorites: 0,
    ),
    rawSourceId: rawSourceId,
    sourceBucketKind: bucketKind,
    sourceDisplayName: sourceDisplayName,
    sourceFilterId: sourceFilterId,
    imageCount: 12,
    fileSizeBytes: 2048,
    sortDate: DateTime(2026, 1, 1),
    resolvedPath: resolvedPath,
    parentId: parentId,
    parentTitle: parentTitle,
    chapterTitle: chapterTitle,
    chapterIndex: chapterIndex,
  );
}
