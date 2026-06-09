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
        emit(currentState.copyWith(isLoadingMore: true));
      } else {
        emit(const OfflineSearchLoading());
      }

      final snapshot = await _buildOfflineLibrarySnapshot(
        query: query,
        selectedFilterId: requestedFilterId,
        sortMode: effectiveSortMode,
        backupPath: backupPath,
      );

      if (isClosed) return;

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

      final totalDisplayEntries = snapshot.displayOrder.length;
      final previousDisplayCount =
          loadMore && currentState is OfflineSearchLoaded
              ? currentState.displayOrder.length
              : 0;
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
        if (item == null) {
          continue;
        }
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
      filteredItems: sortedItems,
      availableFilters: availableFilters,
      normalizedFilterId: normalizedFilterId,
      displayOrder: displayModel.order,
      groupsByKey: displayModel.groupsByKey,
      storageUsage: storageUsage,
    );
  }

  Future<List<OfflineLibraryItemData>> _buildMergedLibraryItems({
    String? backupPath,
  }) async {
    final downloads = await _loadAllCompletedDownloadsFromDb();
    final scannedContents = await _loadScannedContents(backupPath: backupPath);
    final pendingScannedById = <String, Content>{};
    final pendingScannedByPath = <String, Content>{};

    for (final scannedContent in scannedContents) {
      pendingScannedById[scannedContent.id] = scannedContent;
      final pathKey = _normalizeOfflinePath(scannedContent.derivedContentPath);
      if (pathKey != null) {
        pendingScannedByPath[pathKey] = scannedContent;
      }
    }

    final sourceConfigs = {
      for (final config in _remoteConfigService.getAllSourceConfigs())
        config.source: config,
    };
    final items = <OfflineLibraryItemData>[];
    final indexByStableId = <String, int>{};
    final indexByResolvedPath = <String, int>{};

    for (final download in downloads) {
      final matchedScannedContent = await _matchScannedContentForDownload(
        download: download,
        pendingScannedById: pendingScannedById,
        pendingScannedByPath: pendingScannedByPath,
      );
      final item = await _buildItemFromDownload(
        download: download,
        scannedContent: matchedScannedContent.scannedContent,
        resolvedPathOverride: matchedScannedContent.resolvedPath,
        sourceConfigs: sourceConfigs,
      );
      if (item != null) {
        _storeMergedItem(
          items: items,
          indexByStableId: indexByStableId,
          indexByResolvedPath: indexByResolvedPath,
          item: item,
        );
      }
    }

    for (final scannedContent in pendingScannedById.values) {
      final item = await _buildItemFromScannedContent(
        scannedContent,
        sourceConfigs,
      );
      if (item != null) {
        _storeMergedItem(
          items: items,
          indexByStableId: indexByStableId,
          indexByResolvedPath: indexByResolvedPath,
          item: item,
        );
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
      if (page.isEmpty) {
        break;
      }
      downloads.addAll(page);
      if (page.length < batchSize) {
        break;
      }
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
  }) async {
    final resolvedPath = resolvedPathOverride ??
        await _offlineContentManager.resolveOfflineStoragePath(
          contentId: download.contentId,
          downloadPath: download.downloadPath,
          contentPath: scannedContent?.derivedContentPath,
          imageUrls: scannedContent?.imageUrls ?? const <String>[],
        );

    final rawMetadata = await _offlineContentManager.getRawOfflineMetadata(
      contentId: download.contentId,
      contentPath: resolvedPath ?? scannedContent?.derivedContentPath,
    );

    final rawSourceId = _resolveRawSourceId(
      metadata: rawMetadata,
      contentPath: resolvedPath ?? scannedContent?.derivedContentPath,
      fallbackSourceId: scannedContent?.sourceId ?? download.sourceId,
    );
    final bucketInfo = _resolveBucketInfo(rawSourceId, sourceConfigs);

    final firstImagePath = scannedContent?.coverUrl.isNotEmpty == true
        ? scannedContent!.coverUrl
        : await _offlineContentManager.getOfflineFirstImagePath(
            download.contentId,
            downloadPath: resolvedPath ?? download.downloadPath,
          );
    if (firstImagePath == null || firstImagePath.isEmpty) {
      return null;
    }

    final title = _resolveTitle(
      contentId: download.contentId,
      fallbackTitle: download.title,
      metadata: rawMetadata,
      scannedContent: scannedContent,
    );
    final imageCount = await _resolveImageCount(
      contentId: download.contentId,
      fallbackPageCount: scannedContent?.pageCount ?? download.totalPages,
      contentPath: resolvedPath ?? scannedContent?.derivedContentPath,
      metadata: rawMetadata,
    );
    final fileSizeBytes = download.fileSize > 0
        ? download.fileSize
        : await _resolveFileSize(
            resolvedPath ?? scannedContent?.derivedContentPath,
          );
    final sortDate = await _resolveSortDate(
      fallbackPath: resolvedPath ?? scannedContent?.derivedContentPath,
      download: download,
      metadata: rawMetadata,
    );
    final parentContext = await _resolveParentContext(
      contentId: download.contentId,
      displayTitle: title,
      metadata: rawMetadata,
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

  Future<_OfflineParentContext> _resolveParentContext({
    required String contentId,
    required String displayTitle,
    required Map<String, dynamic>? metadata,
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

    History? historyEntry;
    try {
      historyEntry = await _userDataRepository.getHistoryEntry(contentId);
    } catch (_) {
      historyEntry = null;
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
        try {
          final parentHistory =
              await _userDataRepository.getHistoryEntry(parentId);
          parentTitle = parentHistory?.title?.trim();
        } catch (_) {
          parentTitle = null;
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
    required this.filteredItems,
    required this.availableFilters,
    required this.normalizedFilterId,
    required this.displayOrder,
    required this.groupsByKey,
    required this.storageUsage,
  });

  final List<OfflineLibraryItemData> filteredItems;
  final List<OfflineSourceFilterOption> availableFilters;
  final String? normalizedFilterId;
  final List<String> displayOrder;
  final Map<String, OfflineLibraryGroupData> groupsByKey;
  final int storageUsage;

  Map<String, OfflineLibraryItemData> get itemById => {
        for (final item in filteredItems) item.stableId: item,
      };
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
