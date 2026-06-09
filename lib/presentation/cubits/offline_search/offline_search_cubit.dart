import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/config_models.dart';
import '../../../core/config/remote_config_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/download_storage_utils.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../domain/entities/download_status.dart';
import '../../../domain/entities/history.dart';
import '../../../domain/extensions/content_extensions.dart';
import '../../../domain/repositories/user_data_repository.dart';
import 'package:kuron_core/kuron_core.dart';

import '../base/base_cubit.dart';
import 'offline_library_models.dart';

part 'offline_search_state.dart';

/// Cubit for browsing offline/downloaded content.
class OfflineSearchCubit extends BaseCubit<OfflineSearchState> {
  OfflineSearchCubit({
    required OfflineContentManager offlineContentManager,
    required UserDataRepository userDataRepository,
    required SharedPreferences prefs,
    required super.logger,
  })  : _offlineContentManager = offlineContentManager,
        _userDataRepository = userDataRepository,
        _prefs = prefs,
        super(
          initialState: const OfflineSearchInitial(),
        );

  static const int _pageSize = 20;
  static const String _keySelectedSourceFilter =
      'offline_selected_source_filter';

  final OfflineContentManager _offlineContentManager;
  final UserDataRepository _userDataRepository;
  final SharedPreferences _prefs;

  /// Cached snapshot from the last full build.
  /// On load-more we extend the visible window from this cache instead of
  /// rebuilding all items from scratch (which was causing the slowdown).
  _OfflineLibrarySnapshot? _cachedSnapshot;

  RemoteConfigService get _remoteConfigService => getIt<RemoteConfigService>();

  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      logInfo('Error calculating directory size: $e');
    }
    return size;
  }

  Future<void> filterBySource(String? filterId) async {
    logInfo('Filtering offline content by source bucket: $filterId');

    if (filterId != null && filterId.isNotEmpty) {
      await _prefs.setString(_keySelectedSourceFilter, filterId);
    } else {
      await _prefs.remove(_keySelectedSourceFilter);
    }

    await _reloadCurrentContext(
      filterId: filterId,
      hasExplicitFilterOverride: true,
    );
  }

  Future<void> setSortMode(OfflineLibrarySortMode sortMode) async {
    final currentState = state;
    if (currentState is OfflineSearchLoaded &&
        currentState.sortMode == sortMode) {
      return;
    }

    await _reloadCurrentContext(sortMode: sortMode);
  }

  Future<void> searchOfflineContent(
    String query, {
    bool loadMore = false,
    String? sourceId,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await getAllOfflineContent(loadMore: loadMore, sourceId: sourceId);
      return;
    }

    await _loadOfflineLibrary(
      query: trimmedQuery,
      loadMore: loadMore,
      filterId: sourceId,
      sortMode: _currentSortMode,
    );
  }

  Future<String?> findNhasixBackupFolder() async {
    return _offlineContentManager.getBackupRootPath();
  }

  Future<void> loadMoreSearchResults() async {
    final currentState = state;
    if (currentState is OfflineSearchLoaded && currentState.query.isNotEmpty) {
      await searchOfflineContent(currentState.query, loadMore: true);
    }
  }

  Future<void> getAllOfflineContent({
    String? backupPath,
    bool loadMore = false,
    String? sourceId,
  }) async {
    await _loadOfflineLibrary(
      query: '',
      loadMore: loadMore,
      filterId: sourceId,
      sortMode: _currentSortMode,
      backupPath: backupPath,
    );
  }

  Future<void> importFromBackup([String? backupPath]) async {
    String? loadPath = backupPath;
    loadPath ??= await findNhasixBackupFolder();
    if (loadPath == null) {
      emit(const OfflineSearchEmpty(query: ''));
      return;
    }

    await _loadOfflineLibrary(
      query: '',
      filterId: _currentFilterId,
      sortMode: _currentSortMode,
      backupPath: loadPath,
    );

    try {
      logInfo('Syncing filesystem content to database from $loadPath');
      final syncResult =
          await _offlineContentManager.syncBackupToDatabase(loadPath);
      logInfo(
        'Auto-sync complete: ${syncResult['synced'] ?? 0} new, '
        '${syncResult['updated'] ?? 0} updated',
      );
    } catch (e) {
      logInfo('Auto-sync failed (non-blocking): $e');
    }
  }

  Future<void> loadMoreContent() async {
    final currentState = state;
    if (currentState is OfflineSearchLoaded && currentState.query.isNotEmpty) {
      await searchOfflineContent(currentState.query, loadMore: true);
      return;
    }
    await getAllOfflineContent(loadMore: true);
  }

  Future<void> forceRefresh({String? backupPath}) async {
    try {
      logInfo('Force refreshing offline content');
      _offlineContentManager.clearCache();
      _cachedSnapshot = null; // bust snapshot so next load rebuilds fresh
      await _reloadCurrentContext(backupPath: backupPath);
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'force refresh');
    }
  }

  void clearSearch() {
    if (state is OfflineSearchLoaded) {
      unawaited(
        getAllOfflineContent(
            sourceId: (state as OfflineSearchLoaded).selectedFilterId),
      );
      return;
    }
    emit(const OfflineSearchInitial());
  }

  void setLoadingState() {
    emit(const OfflineSearchLoading());
  }

  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      if (state is OfflineSearchLoaded) {
        final loadedState = state as OfflineSearchLoaded;
        return {
          'totalContent': loadedState.totalResults,
          'storageUsage': loadedState.storageUsage,
          'formattedSize': loadedState.formattedStorageUsage,
          'isSearchResult': loadedState.isSearchResult,
        };
      }

      final totalCount = await _userDataRepository.getDownloadsCount(
        state: DownloadState.completed,
      );
      final storageUsage =
          await _offlineContentManager.getOfflineStorageUsage();
      return {
        'totalContent': totalCount,
        'storageUsage': storageUsage,
        'formattedSize': OfflineContentManager.formatStorageSize(storageUsage),
        'isSearchResult': false,
      };
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get offline stats');
      return {
        'totalContent': 0,
        'storageUsage': 0,
        'formattedSize': '0 B',
        'isSearchResult': false,
      };
    }
  }

  Future<void> cleanupOfflineFiles() async {
    try {
      logInfo('Starting cleanup of orphaned offline files');
      await _offlineContentManager.cleanupOrphanedFiles();
      _offlineContentManager.clearCache();
      logInfo('Cleanup completed successfully');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'cleanup offline files');
      rethrow;
    }
  }

  Future<void> scanBackupContent(String backupPath) async {
    await _loadOfflineLibrary(
      query: '',
      filterId: _currentFilterId,
      sortMode: _currentSortMode,
      backupPath: backupPath,
    );
  }

  Future<void> deleteOfflineContent(
    String contentId, {
    String? contentPath,
  }) async {
    try {
      logInfo('Deleting offline content: $contentId');
      await _offlineContentManager.deleteOfflineContent(
        contentId,
        contentPath: contentPath,
      );
      await _reloadCurrentContext();
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'delete offline content');
    }
  }

  Future<void> _reloadCurrentContext({
    String? filterId,
    bool hasExplicitFilterOverride = false,
    OfflineLibrarySortMode? sortMode,
    String? backupPath,
  }) async {
    final currentState = state;
    final currentQuery =
        currentState is OfflineSearchLoaded ? currentState.query : '';

    await _loadOfflineLibrary(
      query: currentQuery,
      filterId: filterId,
      hasExplicitFilterOverride: hasExplicitFilterOverride,
      sortMode: sortMode ?? _currentSortMode,
      backupPath: backupPath,
    );
  }

  String? get _currentFilterId {
    final currentState = state;
    if (currentState is OfflineSearchLoaded) {
      return currentState.selectedFilterId;
    }
    return _prefs.getString(_keySelectedSourceFilter);
  }

  OfflineLibrarySortMode get _currentSortMode {
    final currentState = state;
    if (currentState is OfflineSearchLoaded) {
      return currentState.sortMode;
    }
    return OfflineLibrarySortMode.date;
  }

  Future<void> _loadOfflineLibrary({
    required String query,
    bool loadMore = false,
    String? filterId,
    bool hasExplicitFilterOverride = false,
    OfflineLibrarySortMode? sortMode,
    String? backupPath,
  }) async {
    try {
      final effectiveSortMode = sortMode ?? _currentSortMode;
      final requestedFilterId =
          hasExplicitFilterOverride ? filterId : (filterId ?? _currentFilterId);
      final currentState = state;

      if (loadMore) {
        if (currentState is! OfflineSearchLoaded ||
            !currentState.hasMore ||
            currentState.isLoadingMore) {
          return;
        }

        // ⚡ FAST PATH: extend visible window from cached snapshot.
        // Do NOT rebuild all items — that was causing load-more to be as slow
        // as the initial load for large libraries (2237+ items).
        final cached = _cachedSnapshot;
        if (cached != null &&
            cached.isValidFor(
              query: query,
              filterId: requestedFilterId,
            )) {
          emit(currentState.copyWith(isLoadingMore: true));
          // Yield to let the spinner render
          await Future<void>.delayed(Duration.zero);
          _emitFromSnapshot(
            snapshot: cached,
            query: query,
            loadMore: true,
            prevState: currentState,
            effectiveSortMode: effectiveSortMode,
          );
          return;
        }

        emit(currentState.copyWith(isLoadingMore: true));
      } else {
        // A full (re)load: clear any cached snapshot so we build fresh.
        _cachedSnapshot = null;
        emit(const OfflineSearchLoading());
      }

      final snapshot = await _buildOfflineLibrarySnapshot(
        query: query,
        selectedFilterId: requestedFilterId,
        sortMode: effectiveSortMode,
        backupPath: backupPath,
      );

      if (isClosed) return;

      // Cache the freshly built snapshot for subsequent load-more calls.
      _cachedSnapshot = snapshot;

      if (snapshot.filteredItems.isEmpty) {
        if (query.isNotEmpty ||
            snapshot.availableFilters.isNotEmpty ||
            snapshot.normalizedFilterId != null) {
          emit(OfflineSearchLoaded(
            query: query,
            items: const [],
            totalResults: 0,
            offlineSizes: const {},
            storageUsage: 0,
            formattedStorageUsage: '0 B',
            currentPage: 1,
            totalPages: 1,
            hasMore: false,
            isLoadingMore: false,
            selectedFilterId: snapshot.normalizedFilterId,
            sortMode: effectiveSortMode,
            availableFilters: snapshot.availableFilters,
            displayOrder: const [],
            groupsByKey: const {},
          ));
        } else {
          emit(OfflineSearchEmpty(query: query));
        }
        return;
      }

      _emitFromSnapshot(
        snapshot: snapshot,
        query: query,
        loadMore: false,
        prevState: currentState is OfflineSearchLoaded ? currentState : null,
        effectiveSortMode: effectiveSortMode,
      );
    } catch (e, stackTrace) {
      if (isClosed) return;
      handleError(e, stackTrace, 'load offline library');

      final currentState = state;
      if (loadMore && currentState is OfflineSearchLoaded) {
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      emit(OfflineSearchError(
        message:
            query.isEmpty ? 'failedLoadOfflineContent' : 'failedSearchOffline',
        query: query,
      ));
    }
  }

  /// Build the new emitted state from a snapshot, handling both initial load
  /// and load-more (extending the visible window).
  void _emitFromSnapshot({
    required _OfflineLibrarySnapshot snapshot,
    required String query,
    required bool loadMore,
    required OfflineLibrarySortMode effectiveSortMode,
    OfflineSearchLoaded? prevState,
  }) {
    final totalDisplayEntries = snapshot.displayOrder.length;
    final previousDisplayCount =
        loadMore && prevState != null ? prevState.displayOrder.length : 0;
    final visibleDisplayCount = loadMore
        ? (previousDisplayCount + _pageSize)
            .clamp(0, totalDisplayEntries)
            .toInt()
        : _pageSize.clamp(0, totalDisplayEntries).toInt();
    final visibleOrder = snapshot.displayOrder
        .take(visibleDisplayCount)
        .toList(growable: false);
    final visibleGroups = <String, OfflineLibraryGroupData>{};
    final visibleItems = <OfflineLibraryItemData>[];
    final visibleSizes = <String, String>{};

    for (final entryKey in visibleOrder) {
      final group = snapshot.groupsByKey[entryKey];
      if (group != null) {
        visibleGroups[entryKey] = group;
        for (final child in group.children) {
          visibleItems.add(child);
          visibleSizes[child.stableId] =
              OfflineContentManager.formatStorageSize(child.fileSizeBytes);
        }
        continue;
      }

      final item = snapshot.itemById[entryKey];
      if (item == null) continue;
      visibleItems.add(item);
      visibleSizes[item.stableId] =
          OfflineContentManager.formatStorageSize(item.fileSizeBytes);
    }

    final totalPages = totalDisplayEntries == 0
        ? 1
        : (totalDisplayEntries / _pageSize).ceil();
    final currentPage = visibleDisplayCount == 0
        ? 1
        : (visibleDisplayCount / _pageSize).ceil();

    emit(OfflineSearchLoaded(
      query: query,
      items: visibleItems,
      totalResults: snapshot.filteredItems.length,
      offlineSizes: visibleSizes,
      storageUsage: snapshot.storageUsage,
      formattedStorageUsage:
          OfflineContentManager.formatStorageSize(snapshot.storageUsage),
      currentPage: currentPage,
      totalPages: totalPages,
      hasMore: visibleDisplayCount < totalDisplayEntries,
      isLoadingMore: false,
      selectedFilterId: snapshot.normalizedFilterId,
      sortMode: effectiveSortMode,
      availableFilters: snapshot.availableFilters,
      displayOrder: visibleOrder,
      groupsByKey: visibleGroups,
    ));
  }

  Future<_OfflineLibrarySnapshot> _buildOfflineLibrarySnapshot({
    required String query,
    required String? selectedFilterId,
    required OfflineLibrarySortMode sortMode,
    String? backupPath,
  }) async {
    final mergedItems = await _buildMergedLibraryItems(backupPath: backupPath);
    final availableFilters = _buildAvailableFilters(mergedItems);

    String? normalizedFilterId = selectedFilterId;
    if (normalizedFilterId != null &&
        availableFilters.every((filter) => filter.id != normalizedFilterId)) {
      normalizedFilterId = null;
    }

    final normalizedQuery = query.trim().toLowerCase();
    final filteredItems = mergedItems.where((item) {
      if (!_matchesFilter(item, normalizedFilterId)) {
        return false;
      }
      return _matchesQuery(item, normalizedQuery);
    }).toList(growable: false);

    final sortedItems = List<OfflineLibraryItemData>.from(filteredItems);
    _sortItems(sortedItems, sortMode);

    final displayModel = _buildDisplayModel(sortedItems);
    final storageUsage = sortedItems.fold<int>(
      0,
      (sum, item) => sum + item.fileSizeBytes,
    );

    return _OfflineLibrarySnapshot(
      query: query,
      filterId: selectedFilterId,
      filteredItems: sortedItems,
      availableFilters: availableFilters,
      normalizedFilterId: normalizedFilterId,
      displayOrder: displayModel.order,
      groupsByKey: displayModel.groupsByKey,
      storageUsage: storageUsage,
    );
  }

  /// Build merged library items with performance optimisations:
  /// 1. Preload all history in a single batch DB query.
  /// 2. Only scan the backup folder for items NOT already covered by a DB
  ///    record with a valid download path (avoids scanning 2237 folders on
  ///    every load — only orphan / uninstalled-source items are scanned).
  /// 3. Process items in parallel chunks (size 10) instead of sequentially.
  Future<List<OfflineLibraryItemData>> _buildMergedLibraryItems({
    String? backupPath,
  }) async {
    // ── Step 1: Load all completed downloads from DB (one paginated query) ──
    final downloads = await _loadAllCompletedDownloadsFromDb();

    // ── Step 2: Preload ALL history in one batch SQL query ──
    final contentIds = downloads.map((d) => d.contentId).toList();
    final historyMap =
        await _userDataRepository.getHistoryBatch(contentIds);

    // ── Step 3: Identify which DB items already have a valid path ──
    // For those we skip the full backup scan; scan is only for true orphans.
    final knownPathsFromDb = <String>{};
    for (final d in downloads) {
      final p = _normalizeOfflinePath(d.downloadPath);
      if (p != null) knownPathsFromDb.add(p);
    }

    // ── Step 4: Scan backup folder (discover uninstalled-source orphans) ──
    final scannedContents =
        await _loadScannedContents(backupPath: backupPath);
    final pendingScannedById = <String, Content>{};
    final pendingScannedByPath = <String, Content>{};
    for (final sc in scannedContents) {
      final pathKey = _normalizeOfflinePath(sc.derivedContentPath);
      // Skip items whose path is already tracked by a DB download record
      if (pathKey != null && knownPathsFromDb.contains(pathKey)) continue;
      pendingScannedById[sc.id] = sc;
      if (pathKey != null) pendingScannedByPath[pathKey] = sc;
    }

    final sourceConfigs = {
      for (final config in _remoteConfigService.getAllSourceConfigs())
        config.source: config,
    };
    final items = <OfflineLibraryItemData>[];
    final indexByStableId = <String, int>{};
    final indexByResolvedPath = <String, int>{};

    // ── Step 5: Process DB downloads in parallel chunks ──
    const chunkSize = 10;
    for (var i = 0; i < downloads.length; i += chunkSize) {
      final chunk = downloads.skip(i).take(chunkSize).toList();
      final chunkResults = await Future.wait(
        chunk.map((download) async {
          final matched = await _matchScannedContentForDownload(
            download: download,
            pendingScannedById: pendingScannedById,
            pendingScannedByPath: pendingScannedByPath,
          );
          return _buildItemFromDownload(
            download: download,
            scannedContent: matched.scannedContent,
            resolvedPathOverride: matched.resolvedPath,
            sourceConfigs: sourceConfigs,
            preloadedHistory: historyMap,
          );
        }),
      );
      for (final item in chunkResults) {
        if (item != null) {
          _storeMergedItem(
            items: items,
            indexByStableId: indexByStableId,
            indexByResolvedPath: indexByResolvedPath,
            item: item,
          );
        }
      }
    }

    // ── Step 6: Process orphan scanned items in parallel chunks ──
    final orphanList = pendingScannedById.values.toList();
    for (var i = 0; i < orphanList.length; i += chunkSize) {
      final chunk = orphanList.skip(i).take(chunkSize).toList();
      final chunkResults = await Future.wait(
        chunk.map((sc) => _buildItemFromScannedContent(sc, sourceConfigs)),
      );
      for (final item in chunkResults) {
        if (item != null) {
          _storeMergedItem(
            items: items,
            indexByStableId: indexByStableId,
            indexByResolvedPath: indexByResolvedPath,
            item: item,
          );
        }
      }
    }



    return items;
  }


  Future<List<DownloadStatus>> _loadAllCompletedDownloadsFromDb() async {
    const batchSize = 500;
    final downloads = <DownloadStatus>[];
    int offset = 0;

    while (true) {
      final page = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        limit: batchSize,
        offset: offset,
      );
      if (page.isEmpty) break;
      downloads.addAll(page);
      if (page.length < batchSize) break;
      offset += batchSize;
    }

    return downloads;
  }

  Future<List<Content>> _loadScannedContents({String? backupPath}) async {
    final resolvedBackupPath =
        backupPath ?? await _offlineContentManager.getBackupRootPath();
    if (resolvedBackupPath == null || resolvedBackupPath.trim().isEmpty) {
      return const <Content>[];
    }
    return _offlineContentManager.scanBackupFolder(resolvedBackupPath);
  }

  Future<OfflineLibraryItemData?> _buildItemFromDownload({
    required DownloadStatus download,
    required Content? scannedContent,
    String? resolvedPathOverride,
    required Map<String, SourceConfig> sourceConfigs,
    Map<String, History> preloadedHistory = const {},
  }) async {
    final resolvedPath = resolvedPathOverride ??
        await _offlineContentManager.resolveOfflineStoragePath(
          contentId: download.contentId,
          downloadPath: download.downloadPath,
          contentPath: scannedContent?.derivedContentPath,
          imageUrls: scannedContent?.imageUrls ?? const <String>[],
        );

    late final Map<String, dynamic>? rawMetadata;
    late final String title;
    late final int imageCount;
    late final DateTime sortDate;
    late final String firstImagePath;
    late final String rawSourceId;

    if (scannedContent == null) {
      // 🚀 FAST PATH FOR DB ITEMS: 0 Disk I/O!
      // We rely completely on the SQLite database values.
      rawMetadata = null;
      title = download.title ?? 'Unknown';
      imageCount = download.totalPages;
      sortDate = download.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      firstImagePath = download.coverUrl ?? '';
      rawSourceId = download.sourceId ?? 'nhentai';
    } else {
      // 🐢 SLOW PATH FOR ORPHAN ITEMS: Read metadata.json from disk
      rawMetadata = await _offlineContentManager.getRawOfflineMetadata(
        contentId: download.contentId,
        contentPath: resolvedPath ?? scannedContent.derivedContentPath,
      );
      title = _resolveTitle(
        contentId: download.contentId,
        fallbackTitle: download.title,
        metadata: rawMetadata,
        scannedContent: scannedContent,
      );
      imageCount = await _resolveImageCount(
        contentId: download.contentId,
        fallbackPageCount: scannedContent.pageCount,
        contentPath: resolvedPath ?? scannedContent.derivedContentPath,
        metadata: rawMetadata,
      );
      sortDate = await _resolveSortDate(
        fallbackPath: resolvedPath ?? scannedContent.derivedContentPath,
        download: download,
        metadata: rawMetadata,
      );

      // Find first image by falling back to directory scan if needed
      firstImagePath = scannedContent.coverUrl.isNotEmpty == true
          ? scannedContent.coverUrl
          : (await _offlineContentManager.getOfflineFirstImagePath(
                download.contentId,
                downloadPath: resolvedPath ?? download.downloadPath,
              ) ?? '');
      
      rawSourceId = _resolveRawSourceId(
        metadata: rawMetadata,
        contentPath: resolvedPath ?? scannedContent.derivedContentPath,
        fallbackSourceId: scannedContent.sourceId,
      );
    }

    final bucketInfo = _resolveBucketInfo(rawSourceId, sourceConfigs);

    if (firstImagePath.isEmpty) {
      return null;
    }

    // Fix 5: Use DB fileSize directly — skip expensive directory traversal
    // Only fall back to filesystem scan when the DB value is genuinely absent.
    final fileSizeBytes = download.fileSize > 0
        ? download.fileSize
        : await _resolveFileSize(
            resolvedPath ?? scannedContent?.derivedContentPath,
          );

    // Fix 1: use preloaded history map instead of individual DB query
    final parentContext = await _resolveParentContext(
      contentId: download.contentId,
      displayTitle: title,
      metadata: rawMetadata,
      preloadedHistory: preloadedHistory,
    );

    final content = (scannedContent ??
            _buildFallbackContent(
              sourceId: rawSourceId,
              contentId: download.contentId,
              title: title,
              coverUrl: firstImagePath,
              pageCount: imageCount,
              uploadDate: sortDate,
            ))
        .copyWith(
      sourceId: rawSourceId,
      title: title,
      coverUrl: firstImagePath,
      pageCount: imageCount,
      uploadDate: sortDate,
    );

    return OfflineLibraryItemData(
      content: content,
      rawSourceId: rawSourceId,
      sourceBucketKind: bucketInfo.kind,
      sourceDisplayName: bucketInfo.displayName,
      sourceFilterId: bucketInfo.filterId,
      imageCount: imageCount,
      fileSizeBytes: fileSizeBytes,
      sortDate: sortDate,
      resolvedPath: resolvedPath,
      parentId: parentContext.parentId,
      parentTitle: parentContext.parentTitle,
      chapterTitle: parentContext.chapterTitle,
      chapterIndex: parentContext.chapterIndex,
    );
  }

  Future<_MatchedScannedContent> _matchScannedContentForDownload({
    required DownloadStatus download,
    required Map<String, Content> pendingScannedById,
    required Map<String, Content> pendingScannedByPath,
  }) async {
    final idMatch = pendingScannedById[download.contentId];
    if (idMatch != null) {
      _consumeScannedContent(
        content: idMatch,
        pendingScannedById: pendingScannedById,
        pendingScannedByPath: pendingScannedByPath,
      );
      return _MatchedScannedContent(
        scannedContent: idMatch,
        resolvedPath: idMatch.derivedContentPath,
      );
    }

    final resolvedPath = await _offlineContentManager.resolveOfflineStoragePath(
      contentId: download.contentId,
      downloadPath: download.downloadPath,
    );
    final normalizedPath = _normalizeOfflinePath(
      resolvedPath ?? download.downloadPath,
    );
    if (normalizedPath != null) {
      final pathMatch = pendingScannedByPath[normalizedPath];
      if (pathMatch != null) {
        _consumeScannedContent(
          content: pathMatch,
          pendingScannedById: pendingScannedById,
          pendingScannedByPath: pendingScannedByPath,
        );
        return _MatchedScannedContent(
          scannedContent: pathMatch,
          resolvedPath: resolvedPath ?? pathMatch.derivedContentPath,
        );
      }
    }

    return _MatchedScannedContent(
      resolvedPath: resolvedPath ?? download.downloadPath,
    );
  }

  void _consumeScannedContent({
    required Content content,
    required Map<String, Content> pendingScannedById,
    required Map<String, Content> pendingScannedByPath,
  }) {
    pendingScannedById.remove(content.id);
    final normalizedPath = _normalizeOfflinePath(content.derivedContentPath);
    if (normalizedPath != null) {
      pendingScannedByPath.remove(normalizedPath);
    }
  }

  void _storeMergedItem({
    required List<OfflineLibraryItemData> items,
    required Map<String, int> indexByStableId,
    required Map<String, int> indexByResolvedPath,
    required OfflineLibraryItemData item,
  }) {
    final resolvedPathKey = _normalizeOfflinePath(item.resolvedPath);
    final existingIndex = resolvedPathKey != null
        ? indexByResolvedPath[resolvedPathKey] ?? indexByStableId[item.stableId]
        : indexByStableId[item.stableId];

    if (existingIndex == null) {
      final newIndex = items.length;
      items.add(item);
      indexByStableId[item.stableId] = newIndex;
      if (resolvedPathKey != null) {
        indexByResolvedPath[resolvedPathKey] = newIndex;
      }
      return;
    }

    final existingItem = items[existingIndex];
    final mergedItem = _preferOfflineItem(existingItem, item);
    items[existingIndex] = mergedItem;

    indexByStableId
      ..remove(existingItem.stableId)
      ..[mergedItem.stableId] = existingIndex;

    final existingResolvedPathKey =
        _normalizeOfflinePath(existingItem.resolvedPath);
    if (existingResolvedPathKey != null) {
      indexByResolvedPath.remove(existingResolvedPathKey);
    }

    final mergedResolvedPathKey =
        _normalizeOfflinePath(mergedItem.resolvedPath);
    if (mergedResolvedPathKey != null) {
      indexByResolvedPath[mergedResolvedPathKey] = existingIndex;
    }
  }

  OfflineLibraryItemData _preferOfflineItem(
    OfflineLibraryItemData current,
    OfflineLibraryItemData candidate,
  ) {
    final currentHasPath = _normalizeOfflinePath(current.resolvedPath) != null;
    final candidateHasPath =
        _normalizeOfflinePath(candidate.resolvedPath) != null;
    if (candidateHasPath && !currentHasPath) {
      return candidate;
    }
    if (currentHasPath && !candidateHasPath) {
      return current;
    }

    final currentScore = _offlineItemScore(current);
    final candidateScore = _offlineItemScore(candidate);
    if (candidateScore > currentScore) {
      return candidate;
    }
    return current;
  }

  int _offlineItemScore(OfflineLibraryItemData item) {
    var score = 0;
    if (_normalizeOfflinePath(item.resolvedPath) != null) {
      score += 4;
    }
    if (item.imageCount > 0) {
      score += 2;
    }
    if (item.fileSizeBytes > 0) {
      score += 2;
    }
    if (item.hasParentContext) {
      score += 1;
    }
    if (item.sourceDisplayName.trim().isNotEmpty) {
      score += 1;
    }
    return score;
  }

  String? _normalizeOfflinePath(String? rawPath) {
    final trimmedPath = rawPath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }
    return p.normalize(trimmedPath);
  }

  Future<OfflineLibraryItemData?> _buildItemFromScannedContent(
    Content scannedContent,
    Map<String, SourceConfig> sourceConfigs,
  ) async {
    final resolvedPath = await _offlineContentManager.resolveOfflineStoragePath(
      contentId: scannedContent.id,
      contentPath: scannedContent.derivedContentPath,
      imageUrls: scannedContent.imageUrls,
    );
    if (resolvedPath == null || resolvedPath.isEmpty) {
      return null;
    }

    final rawMetadata = await _offlineContentManager.getRawOfflineMetadata(
      contentPath: resolvedPath,
    );
    final rawSourceId = _resolveRawSourceId(
      metadata: rawMetadata,
      contentPath: resolvedPath,
      fallbackSourceId: scannedContent.sourceId,
    );
    final bucketInfo = _resolveBucketInfo(rawSourceId, sourceConfigs);

    final firstImagePath = scannedContent.coverUrl.isNotEmpty
        ? scannedContent.coverUrl
        : await _offlineContentManager.getOfflineFirstImagePath(
            scannedContent.id,
            downloadPath: resolvedPath,
          );
    if (firstImagePath == null || firstImagePath.isEmpty) {
      return null;
    }

    final title = _resolveTitle(
      contentId: scannedContent.id,
      fallbackTitle: scannedContent.title,
      metadata: rawMetadata,
      scannedContent: scannedContent,
    );
    final imageCount = await _resolveImageCount(
      contentId: scannedContent.id,
      fallbackPageCount: scannedContent.pageCount,
      contentPath: resolvedPath,
      metadata: rawMetadata,
    );
    final fileSizeBytes = await _resolveFileSize(resolvedPath);
    final sortDate = await _resolveSortDate(
      fallbackPath: resolvedPath,
      metadata: rawMetadata,
    );
    final parentContext = await _resolveParentContext(
      contentId: scannedContent.id,
      displayTitle: title,
      metadata: rawMetadata,
    );

    final content = scannedContent.copyWith(
      sourceId: rawSourceId,
      title: title,
      coverUrl: firstImagePath,
      pageCount: imageCount,
      uploadDate: sortDate,
    );

    return OfflineLibraryItemData(
      content: content,
      rawSourceId: rawSourceId,
      sourceBucketKind: bucketInfo.kind,
      sourceDisplayName: bucketInfo.displayName,
      sourceFilterId: bucketInfo.filterId,
      imageCount: imageCount,
      fileSizeBytes: fileSizeBytes,
      sortDate: sortDate,
      resolvedPath: resolvedPath,
      parentId: parentContext.parentId,
      parentTitle: parentContext.parentTitle,
      chapterTitle: parentContext.chapterTitle,
      chapterIndex: parentContext.chapterIndex,
    );
  }

  Content _buildFallbackContent({
    required String sourceId,
    required String contentId,
    required String title,
    required String coverUrl,
    required int pageCount,
    required DateTime uploadDate,
  }) {
    return Content(
      sourceId: sourceId,
      id: contentId,
      title: title,
      coverUrl: coverUrl,
      tags: const [],
      artists: const [],
      characters: const [],
      parodies: const [],
      groups: const [],
      language: '',
      pageCount: pageCount,
      imageUrls: const [],
      uploadDate: uploadDate,
      favorites: 0,
      englishTitle: null,
      japaneseTitle: null,
    );
  }

  String _resolveRawSourceId({
    required Map<String, dynamic>? metadata,
    required String? contentPath,
    required String? fallbackSourceId,
  }) {
    if (contentPath != null && contentPath.isNotEmpty) {
      final resolved = _offlineContentManager.resolveStoredSourceId(
        metadata: metadata,
        contentPath: contentPath,
      );
      if (resolved.trim().isNotEmpty) {
        return resolved.trim();
      }
    }

    final normalizedFallback = fallbackSourceId?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return 'local';
  }

  String _resolveTitle({
    required String contentId,
    required String? fallbackTitle,
    required Map<String, dynamic>? metadata,
    required Content? scannedContent,
  }) {
    final metadataTitle = DownloadStorageUtils.getSafeTitleFromMetadata(
      metadata,
      contentId,
    ).trim();
    if (metadataTitle.isNotEmpty) {
      return metadataTitle;
    }

    final scannedTitle = scannedContent?.title.trim();
    if (scannedTitle != null && scannedTitle.isNotEmpty) {
      return scannedTitle;
    }

    final normalizedFallback = fallbackTitle?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return contentId;
  }

  Future<int> _resolveImageCount({
    required String contentId,
    required int fallbackPageCount,
    required String? contentPath,
    required Map<String, dynamic>? metadata,
  }) async {
    final resolvedCount = await _offlineContentManager.resolveOfflineImageCount(
      contentId: contentId,
      contentPath: contentPath,
      metadata: metadata,
    );
    if (resolvedCount > 0) {
      return resolvedCount;
    }
    return fallbackPageCount;
  }

  Future<int> _resolveFileSize(String? contentPath) async {
    if (contentPath == null || contentPath.isEmpty) {
      return 0;
    }
    final directory = Directory(contentPath);
    if (!await directory.exists()) {
      return 0;
    }
    return _getDirectorySize(directory);
  }

  Future<DateTime> _resolveSortDate({
    DownloadStatus? download,
    Map<String, dynamic>? metadata,
    String? fallbackPath,
  }) async {
    final metadataDateKeys = <dynamic>[
      metadata?['downloadedAt'],
      metadata?['download_date'],
      metadata?['downloaded_at'],
      metadata?['importedAt'],
      metadata?['imported_at'],
    ];
    for (final rawValue in metadataDateKeys) {
      final parsed = DateTime.tryParse(rawValue?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }

    final statusDate = download?.endTime ?? download?.startTime;
    if (statusDate != null) {
      return statusDate;
    }

    if (fallbackPath != null && fallbackPath.isNotEmpty) {
      final directory = Directory(fallbackPath);
      if (await directory.exists()) {
        final stat = await directory.stat();
        return stat.modified;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Resolve parent/chapter context for an item.
  ///
  /// [preloadedHistory] – pass the batch-preloaded history map so this method
  /// does NOT make any additional DB calls during the hot loop.
  Future<_OfflineParentContext> _resolveParentContext({
    required String contentId,
    required String displayTitle,
    required Map<String, dynamic>? metadata,
    Map<String, History> preloadedHistory = const {},
  }) async {
    String? parentId = _readString(
      metadata,
      ['parentId', 'parent_id', 'seriesId', 'series_id'],
    );
    String? parentTitle = _readString(
      metadata,
      ['parentTitle', 'parent_title', 'seriesTitle', 'series_title'],
    );
    String? chapterTitle = _readString(
      metadata,
      ['chapterTitle', 'chapter_title', 'chapterName', 'chapter_name'],
    );
    int? chapterIndex = _readInt(
      metadata,
      ['chapterIndex', 'chapter_index', 'chapterNumber', 'chapter_number'],
    );

    // Use preloaded map (no extra DB hit); fall back to individual query only
    // when called outside the hot loop (e.g. orphan scanned content).
    History? historyEntry = preloadedHistory[contentId];
    if (historyEntry == null && preloadedHistory.isEmpty) {
      try {
        historyEntry = await _userDataRepository.getHistoryEntry(contentId);
      } catch (_) {
        historyEntry = null;
      }
    }

    parentId ??= historyEntry?.parentId?.trim();
    chapterTitle ??= historyEntry?.chapterTitle?.trim();
    chapterIndex ??= historyEntry?.chapterIndex;

    if ((parentId == null || parentId.isEmpty) && contentId.contains('/')) {
      final slashIndex = contentId.lastIndexOf('/');
      if (slashIndex > 0 && slashIndex < contentId.length - 1) {
        parentId = contentId.substring(0, slashIndex).trim();
        chapterIndex ??= int.tryParse(contentId.substring(slashIndex + 1));
      }
    }

    if (chapterTitle == null || chapterTitle.isEmpty) {
      final titleParts = displayTitle.split(' - ');
      if (titleParts.length > 1) {
        chapterTitle = titleParts.last.trim();
      } else if (parentId != null && parentId.isNotEmpty) {
        chapterTitle = displayTitle.trim();
      }
    }

    if (parentId != null && parentId.isNotEmpty) {
      if (parentTitle == null || parentTitle.isEmpty) {
        // Check preloaded map first before hitting DB
        final parentHistory = preloadedHistory[parentId];
        parentTitle = parentHistory?.title?.trim();

        if ((parentTitle == null || parentTitle.isEmpty) &&
            preloadedHistory.isEmpty) {
          try {
            final fetched =
                await _userDataRepository.getHistoryEntry(parentId);
            parentTitle = fetched?.title?.trim();
          } catch (_) {
            parentTitle = null;
          }
        }
      }

      if (parentTitle == null || parentTitle.isEmpty) {
        parentTitle = DownloadStorageUtils.getSafeTitleFromMetadata(
          null,
          parentId,
        );
      }
    }

    return _OfflineParentContext(
      parentId: parentId?.trim().isEmpty == true ? null : parentId?.trim(),
      parentTitle:
          parentTitle?.trim().isEmpty == true ? null : parentTitle?.trim(),
      chapterTitle:
          chapterTitle?.trim().isEmpty == true ? null : chapterTitle?.trim(),
      chapterIndex: chapterIndex,
    );
  }

  String? _readString(Map<String, dynamic>? metadata, List<String> keys) {
    if (metadata == null) {
      return null;
    }
    for (final key in keys) {
      final value = metadata[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _readInt(Map<String, dynamic>? metadata, List<String> keys) {
    if (metadata == null) {
      return null;
    }
    for (final key in keys) {
      final value = metadata[key];
      final parsed =
          value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  _OfflineBucketInfo _resolveBucketInfo(
    String rawSourceId,
    Map<String, SourceConfig> sourceConfigs,
  ) {
    final normalizedSourceId = rawSourceId.trim();
    if (normalizedSourceId.isEmpty || normalizedSourceId == 'local') {
      return const _OfflineBucketInfo(
        kind: OfflineSourceBucketKind.local,
        displayName: 'local',
        filterId: OfflineSourceFilterOption.localId,
      );
    }

    final sourceConfig = sourceConfigs[normalizedSourceId];
    if (sourceConfig != null) {
      return _OfflineBucketInfo(
        kind: OfflineSourceBucketKind.installed,
        displayName: sourceConfig.ui?.displayName ?? normalizedSourceId,
        filterId: normalizedSourceId,
      );
    }

    return _OfflineBucketInfo(
      kind: OfflineSourceBucketKind.other,
      displayName: normalizedSourceId,
      filterId: OfflineSourceFilterOption.otherId,
    );
  }

  List<OfflineSourceFilterOption> _buildAvailableFilters(
    List<OfflineLibraryItemData> items,
  ) {
    final filters = <OfflineSourceFilterOption>[
      const OfflineSourceFilterOption(
        id: OfflineSourceFilterOption.allId,
        kind: OfflineSourceBucketKind.all,
      ),
    ];
    final installed = <String, OfflineSourceFilterOption>{};
    bool hasLocal = false;
    bool hasOther = false;

    for (final item in items) {
      switch (item.sourceBucketKind) {
        case OfflineSourceBucketKind.installed:
          installed[item.rawSourceId] = OfflineSourceFilterOption(
            id: item.rawSourceId,
            kind: OfflineSourceBucketKind.installed,
            sourceId: item.rawSourceId,
            displayName: item.sourceDisplayName,
          );
        case OfflineSourceBucketKind.local:
          hasLocal = true;
        case OfflineSourceBucketKind.other:
          hasOther = true;
        case OfflineSourceBucketKind.all:
          break;
      }
    }

    final installedOptions = installed.values.toList()
      ..sort((left, right) => (left.displayName ?? left.sourceId ?? left.id)
          .toLowerCase()
          .compareTo(
            (right.displayName ?? right.sourceId ?? right.id).toLowerCase(),
          ));
    filters.addAll(installedOptions);

    if (hasLocal) {
      filters.add(
        const OfflineSourceFilterOption(
          id: OfflineSourceFilterOption.localId,
          kind: OfflineSourceBucketKind.local,
        ),
      );
    }
    if (hasOther) {
      filters.add(
        const OfflineSourceFilterOption(
          id: OfflineSourceFilterOption.otherId,
          kind: OfflineSourceBucketKind.other,
        ),
      );
    }

    return filters;
  }

  bool _matchesFilter(
    OfflineLibraryItemData item,
    String? selectedFilterId,
  ) {
    if (selectedFilterId == null ||
        selectedFilterId == OfflineSourceFilterOption.allId) {
      return true;
    }
    switch (selectedFilterId) {
      case OfflineSourceFilterOption.localId:
        return item.sourceBucketKind == OfflineSourceBucketKind.local;
      case OfflineSourceFilterOption.otherId:
        return item.sourceBucketKind == OfflineSourceBucketKind.other;
      default:
        return item.rawSourceId == selectedFilterId &&
            item.sourceBucketKind == OfflineSourceBucketKind.installed;
    }
  }

  bool _matchesQuery(
    OfflineLibraryItemData item,
    String normalizedQuery,
  ) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final haystacks = <String>[
      item.content.title,
      item.content.id,
      item.rawSourceId,
      item.sourceDisplayName,
      item.parentTitle ?? '',
      item.chapterTitle ?? '',
    ];

    for (final haystack in haystacks) {
      if (haystack.toLowerCase().contains(normalizedQuery)) {
        return true;
      }
    }

    return false;
  }

  void _sortItems(
    List<OfflineLibraryItemData> items,
    OfflineLibrarySortMode sortMode,
  ) {
    items.sort((left, right) {
      switch (sortMode) {
        case OfflineLibrarySortMode.title:
          final titleCompare = left.content.title
              .toLowerCase()
              .compareTo(right.content.title.toLowerCase());
          if (titleCompare != 0) {
            return titleCompare;
          }
          final dateCompare = right.sortDate.compareTo(left.sortDate);
          if (dateCompare != 0) {
            return dateCompare;
          }
          return left.content.id.compareTo(right.content.id);
        case OfflineLibrarySortMode.imageCount:
          final imageCountCompare = right.imageCount.compareTo(left.imageCount);
          if (imageCountCompare != 0) {
            return imageCountCompare;
          }
          final titleCompare = left.content.title
              .toLowerCase()
              .compareTo(right.content.title.toLowerCase());
          if (titleCompare != 0) {
            return titleCompare;
          }
          final dateCompare = right.sortDate.compareTo(left.sortDate);
          if (dateCompare != 0) {
            return dateCompare;
          }
          return left.content.id.compareTo(right.content.id);
        case OfflineLibrarySortMode.date:
          final dateCompare = right.sortDate.compareTo(left.sortDate);
          if (dateCompare != 0) {
            return dateCompare;
          }
          final titleCompare = left.content.title
              .toLowerCase()
              .compareTo(right.content.title.toLowerCase());
          if (titleCompare != 0) {
            return titleCompare;
          }
          return left.content.id.compareTo(right.content.id);
      }
    });
  }

  _OfflineDisplayModel _buildDisplayModel(List<OfflineLibraryItemData> items) {
    final order = <String>[];
    final groupsByKey = <String, OfflineLibraryGroupData>{};

    for (final item in items) {
      if (!item.hasParentContext) {
        order.add(item.stableId);
        continue;
      }

      final groupKey = '${item.rawSourceId}::${item.parentId}';
      final existing = groupsByKey[groupKey];
      if (existing == null) {
        groupsByKey[groupKey] = OfflineLibraryGroupData(
          groupKey: groupKey,
          parentId: item.parentId!,
          parentTitle: item.parentTitle!,
          rawSourceId: item.rawSourceId,
          sourceBucketKind: item.sourceBucketKind,
          sourceDisplayName: item.sourceDisplayName,
          sourceFilterId: item.sourceFilterId,
          sortDate: item.sortDate,
          resolvedPath: item.resolvedPath,
          children: _sortGroupChildren([item]),
        );
        order.add(groupKey);
        continue;
      }

      final mergedChildren = _sortGroupChildren([...existing.children, item]);
      final resolvedGroupPath = existing.resolvedPath ??
          item.resolvedPath ??
          existing.children.first.resolvedPath;
      final updatedSortDate = item.sortDate.isAfter(existing.sortDate)
          ? item.sortDate
          : existing.sortDate;
      groupsByKey[groupKey] = existing.copyWith(
        children: mergedChildren,
        resolvedPath: resolvedGroupPath,
        sortDate: updatedSortDate,
      );
    }

    return _OfflineDisplayModel(order: order, groupsByKey: groupsByKey);
  }

  List<OfflineLibraryItemData> _sortGroupChildren(
    List<OfflineLibraryItemData> children,
  ) {
    final sortedChildren = List<OfflineLibraryItemData>.from(children);
    sortedChildren.sort((left, right) {
      if (left.chapterIndex != null && right.chapterIndex != null) {
        final indexCompare = left.chapterIndex!.compareTo(right.chapterIndex!);
        if (indexCompare != 0) {
          return indexCompare;
        }
      }
      if (left.chapterIndex != null) {
        return -1;
      }
      if (right.chapterIndex != null) {
        return 1;
      }
      return left.childLabel
          .toLowerCase()
          .compareTo(right.childLabel.toLowerCase());
    });
    return sortedChildren;
  }
}

class _OfflineLibrarySnapshot {
  const _OfflineLibrarySnapshot({
    required this.query,
    required this.filterId,
    required this.filteredItems,
    required this.availableFilters,
    required this.normalizedFilterId,
    required this.displayOrder,
    required this.groupsByKey,
    required this.storageUsage,
  });

  /// The query and filterId used to build this snapshot.
  /// Used to validate cache freshness before serving load-more from cache.
  final String query;
  final String? filterId;
  final List<OfflineLibraryItemData> filteredItems;
  final List<OfflineSourceFilterOption> availableFilters;
  final String? normalizedFilterId;
  final List<String> displayOrder;
  final Map<String, OfflineLibraryGroupData> groupsByKey;
  final int storageUsage;

  Map<String, OfflineLibraryItemData> get itemById => {
        for (final item in filteredItems) item.stableId: item,
      };

  /// Returns true when this snapshot can be reused for a load-more call
  /// with the given [query] and [filterId].
  bool isValidFor({required String query, required String? filterId}) =>
      this.query == query && this.filterId == filterId;
}

class _OfflineDisplayModel {
  const _OfflineDisplayModel({
    required this.order,
    required this.groupsByKey,
  });

  final List<String> order;
  final Map<String, OfflineLibraryGroupData> groupsByKey;
}

class _OfflineParentContext {
  const _OfflineParentContext({
    this.parentId,
    this.parentTitle,
    this.chapterTitle,
    this.chapterIndex,
  });

  final String? parentId;
  final String? parentTitle;
  final String? chapterTitle;
  final int? chapterIndex;
}

class _OfflineBucketInfo {
  const _OfflineBucketInfo({
    required this.kind,
    required this.displayName,
    required this.filterId,
  });

  final OfflineSourceBucketKind kind;
  final String displayName;
  final String filterId;
}

class _MatchedScannedContent {
  const _MatchedScannedContent({
    this.scannedContent,
    this.resolvedPath,
  });

  final Content? scannedContent;
  final String? resolvedPath;
}
