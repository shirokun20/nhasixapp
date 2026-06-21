import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/offline_content_manager.dart';
import '../../../core/utils/download_storage_utils.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../../domain/entities/download_status.dart';
import '../../../domain/repositories/user_data_repository.dart';
import '../../../domain/repositories/reader_repository.dart';
import '../../../core/di/service_locator.dart';

import '../base/base_cubit.dart';
import '../../models/content_group.dart';
import '../../../core/utils/title_parser_utils.dart';

part 'offline_search_state.dart';

/// Cubit for searching offline/downloaded content
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

  final OfflineContentManager _offlineContentManager;
  final UserDataRepository _userDataRepository;
  final SharedPreferences _prefs;
  final Map<String, int> _sizeBytesByContentId = {};
  int _dbOffset = 0; // ponytail: raw DB offset, immune to skip-on-null-image
  int _searchDbOffset = 0;
  static const String _keySelectedSourceFilter =
      'offline_selected_source_filter';
  static const String _keyIsListMode = 'offline_is_list_mode';

  /// Helper to calculate directory size recursively
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

  /// Calculate sizes for all content directories
  Future<Map<String, String>> _calculateContentSizes(
      List<Content> contents) async {
    final sizes = <String, String>{};

    for (final content in contents) {
      try {
        // Use the centralized directory lookup which handles Elegant IDs
        final dirPath = await DownloadStorageUtils.getContentDirectory(
            content.id,
            sourceId: content.sourceId);

        final dir = Directory(dirPath);
        if (await dir.exists()) {
          final sizeInBytes = await _getDirectorySize(dir);
          sizes[content.id] =
              OfflineContentManager.formatStorageSize(sizeInBytes);
        } else {
          // Fallback: Try to get directory from first image path if available
          if (content.imageUrls.isNotEmpty) {
            final firstImagePath = content.imageUrls.first;
            final file = File(firstImagePath);
            final parentDir = file.parent;
            if (await parentDir.exists()) {
              final sizeInBytes = await _getDirectorySize(parentDir);
              sizes[content.id] =
                  OfflineContentManager.formatStorageSize(sizeInBytes);
            }
          }
        }
      } catch (e) {
        // Skip if unable to calculate size
        logInfo('Unable to calculate size for content ${content.id}: $e');
      }
    }

    return sizes;
  }

  /// Apply source filter
  Future<void> filterBySource(String? sourceId) async {
    logInfo('Filtering offline content by source: $sourceId');

    // Save selected source filter to preferences
    if (sourceId != null) {
      await _prefs.setString(_keySelectedSourceFilter, sourceId);
    } else {
      await _prefs.remove(_keySelectedSourceFilter);
    }

    // Update state with new filter immediately
    final currentState = state;
    String currentQuery = '';

    if (currentState is OfflineSearchLoaded) {
      currentQuery = currentState.query;
      emit(currentState.copyWith(
        selectedSourceId: sourceId,
        clearSourceId: sourceId == null,
        // Reset pagination when filter changes
        results: [],
        totalResults: 0,
        offlineSizes: {},
        storageUsage: 0,
        formattedStorageUsage: '0 B',
        currentPage: 1,
        totalPages: 1,
        hasMore: false,
      ));
    } else if (currentState is OfflineSearchEmpty) {
      currentQuery = currentState.query;
    } else if (currentState is OfflineSearchError) {
      currentQuery = currentState.query;
    }

    // Refresh content with new filter
    if (currentQuery.isNotEmpty) {
      await searchOfflineContent(currentQuery, sourceId: sourceId);
    } else {
      await getAllOfflineContent(sourceId: sourceId);
    }
  }

  /// Change sorting method
  Future<void> changeSorting(
      {required String orderBy, required bool descending}) async {
    final currentState = state;
    if (currentState is! OfflineSearchLoaded) return;

    // Emit updated state with new sorting
    emit(currentState.copyWith(
      orderBy: orderBy,
      descending: descending,
      // Clear results to trigger a fresh load
      results: [],
    ));

    // Reload content
    if (currentState.query.isNotEmpty) {
      await searchOfflineContent(currentState.query);
    } else {
      await getAllOfflineContent();
    }
  }

  /// Toggle List/Grid View Mode
  Future<void> toggleViewMode() async {
    final currentState = state;
    if (currentState is OfflineSearchLoaded) {
      final newMode = !currentState.isListMode;
      await _prefs.setBool(_keyIsListMode, newMode);
      emit(currentState.copyWith(isListMode: newMode));
    }
  }

  /// Search in offline content - DATABASE ONLY (optimized)
  ///
  /// [query] - Search query string
  /// [loadMore] - If true, appends to existing search results (pagination)
  /// [sourceId] - Optional source filter override (if null, uses state)
  Future<void> searchOfflineContent(
    String query, {
    bool loadMore = false,
    String? sourceId,
  }) async {
    try {
      if (query.trim().isEmpty) {
        // preserve filter if any
        if (state is OfflineSearchLoaded) {
          await getAllOfflineContent(
              sourceId: (state as OfflineSearchLoaded).selectedSourceId);
        } else {
          emit(const OfflineSearchInitial());
        }
        return;
      }

      const pageSize = 20;

      // Determine effective source ID
      String? effectiveSourceId = sourceId;
      if (effectiveSourceId == null && state is OfflineSearchLoaded) {
        effectiveSourceId = (state as OfflineSearchLoaded).selectedSourceId;
      }

      // Determine sorting BEFORE state changes to loading
      String currentOrderBy = 'created_at';
      bool currentDescending = true;
      if (state is OfflineSearchLoaded) {
        currentOrderBy = (state as OfflineSearchLoaded).orderBy;
        currentDescending = (state as OfflineSearchLoaded).descending;
      }

      // If loading more, check current state
      if (loadMore) {
        final currentState = state;
        if (currentState is! OfflineSearchLoaded) {
          logInfo('Cannot load more: not in loaded state');
          return;
        }
        if (!currentState.hasMore) {
          logInfo('No more search results to load');
          return;
        }
        if (currentState.isLoadingMore) {
          logInfo('Already loading more search results');
          return;
        }

        // Verify we're still searching the same query
        if (currentState.query != query) {
          logInfo('Query changed, ignoring load more');
          return;
        }

        // Show loading indicator
        emit(currentState.copyWith(isLoadingMore: true));
      } else {
        // Initial search
        logInfo(
            'Searching offline content for: $query (source: $effectiveSourceId)');
        emit(const OfflineSearchLoading());
      }

      // Calculate offset based on current page
      final offset = loadMore ? _searchDbOffset : 0;
      if (!loadMore) _searchDbOffset = 0;

      // Load page from database
      final searchResults = await _userDataRepository.searchDownloads(
        query: query,
        state: DownloadState.completed,
        sourceId: effectiveSourceId,
        limit: pageSize,
        offset: offset,
        orderBy: currentOrderBy,
        descending: currentDescending,
      );

      if (isClosed) return;

      // Get total count for pagination
      final totalCount = await _userDataRepository.getSearchCount(
        query: query,
        state: DownloadState.completed,
        sourceId: effectiveSourceId,
      );

      // Convert database results to Content objects
      final newContents = <Content>[];
      final newOfflineSizes = <String, String>{};
      final newSizeBytes = <String, int>{};
      int newStorageUsage = 0;

      for (final row in searchResults) {
        if (isClosed) return;

        final contentId = row['id'] as String;
        final sourceId = row['source_id'] as String? ?? 'nhentai';
        final title = row['title'] as String? ?? contentId;
        // coverUrl from DB not used - we use local first image instead
        final fileSize = row['file_size'] as int? ?? 0;
        final totalPages = row['total_pages'] as int? ?? 0;
        final downloadPath = row['download_path'] as String?;

        // OPTIMIZED: Get only first image for cover (fast pattern matching)
        // Full image URLs will be loaded on-demand when entering reader
        final firstImagePath =
            await _offlineContentManager.getOfflineFirstImagePath(
          contentId,
          downloadPath: downloadPath,
        );

        if (firstImagePath == null) continue; // Skip if no images found

        newContents.add(Content(
          sourceId: sourceId,
          id: contentId,
          title: title,
          coverUrl: firstImagePath, // Use local first image as cover
          tags: [],
          artists: [],
          characters: [],
          parodies: [],
          groups: [],
          language: '',
          pageCount: totalPages,
          imageUrls: [], // Empty - loaded on-demand in reader
          uploadDate: DateTime.now(),
          favorites: 0,
          englishTitle: null,
          japaneseTitle: null,
        ));

        newOfflineSizes[contentId] =
            OfflineContentManager.formatStorageSize(fileSize);
        newSizeBytes[contentId] = fileSize;
        newStorageUsage += fileSize;
      }

      if (isClosed) return;

      // Merge with existing results if loading more
      final List<Content> finalResultsFlat;
      final Map<String, String> finalSizes;
      final int finalStorageUsage;

      if (loadMore && state is OfflineSearchLoaded) {
        final currentState = state as OfflineSearchLoaded;
        final flatItems = currentState.results.expand((g) => g.items).toList();
        finalResultsFlat = [...flatItems, ...newContents];
        finalSizes = {...currentState.offlineSizes, ...newOfflineSizes};
        finalStorageUsage = currentState.storageUsage + newStorageUsage;
      } else {
        finalResultsFlat = newContents;
        finalSizes = newOfflineSizes;
        finalStorageUsage = newStorageUsage;
      }

      if (!loadMore) {
        _sizeBytesByContentId.clear();
        _searchDbOffset = 0;
      }
      _sizeBytesByContentId.addAll(newSizeBytes);
      _searchDbOffset += searchResults.length; // track raw fetched count

      final List<ContentGroup> groupedResults = await _groupContent(
        finalResultsFlat,
        itemSizes: _sizeBytesByContentId,
      );

      // Calculate pagination metadata
      final currentPage = (finalResultsFlat.length / pageSize).ceil();
      final totalPages = (totalCount / pageSize).ceil();
      final hasMore = finalResultsFlat.length < totalCount;

      if (groupedResults.isEmpty && offset == 0) {
        // Keep sourceId in empty state if we want to show filtered empty state
        emit(OfflineSearchEmpty(query: query));
        return;
      }

      emit(OfflineSearchLoaded(
        query: query,
        results: groupedResults,
        totalResults: totalCount,
        offlineSizes: finalSizes,
        storageUsage: finalStorageUsage,
        formattedStorageUsage:
            OfflineContentManager.formatStorageSize(finalStorageUsage),
        currentPage: currentPage,
        totalPages: totalPages,
        hasMore: hasMore,
        isLoadingMore: false,
        selectedSourceId: effectiveSourceId,
        orderBy: currentOrderBy,
        descending: currentDescending,
        isListMode: _prefs.getBool(_keyIsListMode) ?? false,
      ));

      logInfo(
          'Search complete: ${groupedResults.length} groups / ${finalResultsFlat.length} items for "$query" (source: $effectiveSourceId) '
          '(page $currentPage/$totalPages, hasMore: $hasMore)');
    } catch (e, stackTrace) {
      if (isClosed) return;
      handleError(e, stackTrace, 'search offline content');

      // If we were loading more, restore previous state
      if (loadMore && state is OfflineSearchLoaded) {
        emit((state as OfflineSearchLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(OfflineSearchError(
          message: 'failedSearchOffline',
          query: query,
        ));
      }
    }

    // Save to search history if query is not empty and we didn't error out
    if (query.isNotEmpty && !loadMore) {
      try {
        await _userDataRepository.addSearchHistory(query);
      } catch (e) {
        logInfo('Error saving search history: $e');
      }
    }
  }

  /// Helper to find nhasix backup folder
  Future<String?> findNhasixBackupFolder() async {
    try {
      final downloadsDir = await getApplicationDocumentsDirectory();
      // Try external storage path first
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final externalRoot = externalDir.path.split('/Android')[0];
        final nhasixPath = '$externalRoot/Download/nhasix';
        final nhasixDir = Directory(nhasixPath);
        if (await nhasixDir.exists()) {
          return nhasixPath;
        }
      }
      // Fallback to app documents
      final appNhasixPath = '${downloadsDir.path}/downloads/nhasix';
      final appNhasixDir = Directory(appNhasixPath);
      if (await appNhasixDir.exists()) {
        return appNhasixPath;
      }
      return null;
    } catch (e) {
      logInfo('Error finding nhasix backup folder: $e');
      return null;
    }
  }

  /// Load more search results (pagination)
  ///
  /// This is a convenience method for infinite scroll in search
  Future<void> loadMoreSearchResults() async {
    final currentState = state;
    if (currentState is OfflineSearchLoaded && currentState.query.isNotEmpty) {
      await searchOfflineContent(currentState.query, loadMore: true);
    }
  }

  /// Get all offline content from DATABASE (primary source)
  /// Falls back to file scan only if no database entries exist
  ///
  /// [loadMore] - If true, appends to existing results (pagination)
  /// [backupPath] - Optional custom backup path
  /// [sourceId] - Optional source filter override (if null, uses state)
  Future<void> getAllOfflineContent({
    String? backupPath,
    bool loadMore = false,
    String? sourceId,
  }) async {
    try {
      // Page size constant (20 items per page)
      const pageSize = 20;

      // Determine effective source ID
      String? effectiveSourceId = sourceId;
      if (effectiveSourceId == null && state is OfflineSearchLoaded) {
        // If in loaded state, preserve current filter
        effectiveSourceId = (state as OfflineSearchLoaded).selectedSourceId;
      } else {
        effectiveSourceId ??= _prefs.getString(_keySelectedSourceFilter);
      }

      // Determine sorting BEFORE state changes to loading
      String currentOrderBy = 'created_at';
      bool currentDescending = true;
      if (state is OfflineSearchLoaded) {
        currentOrderBy = (state as OfflineSearchLoaded).orderBy;
        currentDescending = (state as OfflineSearchLoaded).descending;
      }

      // If loading more, check current state
      if (loadMore) {
        final currentState = state;
        if (currentState is! OfflineSearchLoaded) {
          logInfo('Cannot load more: not in loaded state');
          return;
        }
        if (!currentState.hasMore) {
          logInfo('No more content to load');
          return;
        }
        if (currentState.isLoadingMore) {
          logInfo('Already loading more content');
          return;
        }

        // Show loading indicator
        emit(currentState.copyWith(isLoadingMore: true));
      } else {
        // Initial load
        logInfo(
            'Loading all offline content from database (page 1) source: $effectiveSourceId');
        emit(const OfflineSearchLoading());
      }

      // Calculate offset based on current page
      final offset = loadMore ? _dbOffset : 0;
      if (!loadMore) _dbOffset = 0;

      // Load page from database
      final downloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        sourceId: effectiveSourceId,
        limit: pageSize,
        offset: offset,
        orderBy: currentOrderBy,
        descending: currentDescending,
      );

      if (isClosed) return;

      // Get total count for pagination
      final totalCount = await _userDataRepository.getDownloadsCount(
        state: DownloadState.completed,
        sourceId: effectiveSourceId,
      );

      if (downloads.isEmpty && offset == 0) {
        // Only trigger empty if NO source filter is applied.
        // If filter is applied, just show empty (filtered) state, don't fallback to FS
        if (effectiveSourceId == null) {
          // Enforce DB First: Do NOT auto-scan filesystem.
          // If DB is empty, user must explicitly trigger "Sync" or "Import".
          logInfo('No downloads in database. Waiting for user to sync/import.');
          emit(const OfflineSearchEmpty(query: ''));
          return;
        }
      }

      // Convert DownloadStatus to Content objects
      final newContents = <Content>[];
      final newOfflineSizes = <String, String>{};
      final newSizeBytes = <String, int>{};
      int newStorageUsage = 0;

      for (final download in downloads) {
        if (isClosed) return;

        // OPTIMIZED: Get only first image for cover (fast pattern matching)
        // Full image URLs will be loaded on-demand when entering reader
        final firstImagePath =
            await _offlineContentManager.getOfflineFirstImagePath(
          download.contentId,
          downloadPath: download.downloadPath,
        );

        if (firstImagePath == null) continue; // Skip if no images found

        newContents.add(Content(
          sourceId: download.sourceId ?? 'nhentai', // Fallback to nhentai
          id: download.contentId,
          title: download.title ?? download.contentId,
          coverUrl: firstImagePath, // Use local first image as cover
          tags: [],
          artists: [],
          characters: [],
          parodies: [],
          groups: [],
          language: '',
          pageCount: download.totalPages,
          imageUrls: [], // Empty - loaded on-demand in reader
          uploadDate: DateTime.now(),
          favorites: 0,
          englishTitle: download.title, // Store original title
          japaneseTitle: null,
        ));

        // Use DB size (already available)
        newOfflineSizes[download.contentId] = download.formattedFileSize;
        newSizeBytes[download.contentId] = download.fileSize;
        newStorageUsage += download.fileSize;
      }

      if (isClosed) return;

      // Merge with existing results if loading more
      final List<Content> finalResultsFlat;
      final Map<String, String> finalSizes;
      final int finalStorageUsage;

      if (loadMore && state is OfflineSearchLoaded) {
        final currentState = state as OfflineSearchLoaded;
        final flatItems = currentState.results.expand((g) => g.items).toList();
        finalResultsFlat = [...flatItems, ...newContents];
        finalSizes = {...currentState.offlineSizes, ...newOfflineSizes};
        finalStorageUsage = currentState.storageUsage + newStorageUsage;
      } else {
        finalResultsFlat = newContents;
        finalSizes = newOfflineSizes;
        finalStorageUsage = newStorageUsage;
      }

      if (!loadMore) {
        _sizeBytesByContentId.clear();
        _dbOffset = 0;
      }
      _sizeBytesByContentId.addAll(newSizeBytes);
      _dbOffset += downloads.length; // track raw fetched count

      final List<ContentGroup> groupedResults = await _groupContent(
        finalResultsFlat,
        itemSizes: _sizeBytesByContentId,
      );

      // Calculate pagination metadata
      final currentPage = (finalResultsFlat.length / pageSize).ceil();
      final totalPages = (totalCount / pageSize).ceil();
      final hasMore = finalResultsFlat.length < totalCount;

      if (groupedResults.isEmpty) {
        // If filtered and empty, we should still show the filtered state, not generic empty
        emit(OfflineSearchLoaded(
          query: '',
          results: [],
          totalResults: 0,
          offlineSizes: {},
          storageUsage: 0,
          formattedStorageUsage: '0 B',
          currentPage: 1,
          totalPages: 1,
          hasMore: false,
          isLoadingMore: false,
          selectedSourceId: effectiveSourceId,
          isListMode: _prefs.getBool(_keyIsListMode) ?? false,
        ));
        return;
      }

      emit(OfflineSearchLoaded(
        query: '',
        results: groupedResults,
        totalResults: totalCount,
        offlineSizes: finalSizes,
        storageUsage: finalStorageUsage,
        formattedStorageUsage:
            OfflineContentManager.formatStorageSize(finalStorageUsage),
        currentPage: currentPage,
        totalPages: totalPages,
        hasMore: hasMore,
        isLoadingMore: false,
        selectedSourceId: effectiveSourceId,
        orderBy: currentOrderBy,
        descending: currentDescending,
        isListMode: _prefs.getBool(_keyIsListMode) ?? false,
      ));

      logInfo(
          'Loaded ${groupedResults.length} groups / ${finalResultsFlat.length} offline items (source: $effectiveSourceId) '
          '(page $currentPage/$totalPages, hasMore: $hasMore)');
    } catch (e, stackTrace) {
      if (isClosed) return;
      handleError(e, stackTrace, 'get all offline content');

      // If we were loading more, restore previous state
      if (loadMore && state is OfflineSearchLoaded) {
        emit((state as OfflineSearchLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(const OfflineSearchError(
          message: 'failedLoadOfflineContent',
          query: '',
        ));
      }
    }
  }

  /// Manual Import/Sync: Load from file system and populate database
  /// This is now EXPLICITLY triggered by the user (not automatic)
  Future<void> importFromBackup([String? backupPath]) async {
    String? loadPath = backupPath;
    if (loadPath == null) {
      final nhasixPath = await findNhasixBackupFolder();
      if (nhasixPath == null) {
        emit(const OfflineSearchEmpty(query: ''));
        return;
      }
      loadPath = nhasixPath;
    }

    final contents = await _offlineContentManager
        .getAllOfflineContentFromFileSystem(loadPath);

    if (contents.isEmpty) {
      emit(const OfflineSearchEmpty(query: ''));
      return;
    }

    final offlineSizes = await _calculateContentSizes(contents);

    // Calculate total storage usage
    int totalStorageUsage = 0;
    for (final content in contents) {
      if (content.imageUrls.isNotEmpty) {
        try {
          final file = File(content.imageUrls.first);
          final dirPath = file.parent.path;
          totalStorageUsage += await _getDirectorySize(Directory(dirPath));
        } catch (_) {}
      }
    }

    final List<ContentGroup> groupedResults = await _groupContent(contents);

    emit(OfflineSearchLoaded(
      query: '',
      results: groupedResults,
      totalResults: contents.length,
      offlineSizes: offlineSizes,
      storageUsage: totalStorageUsage,
      formattedStorageUsage:
          OfflineContentManager.formatStorageSize(totalStorageUsage),
      isListMode: _prefs.getBool(_keyIsListMode) ?? false,
    ));

    logInfo(
        'Loaded ${contents.length} offline content items from file system (fallback)');

    // NEW: Auto-sync filesystem content to database for persistence
    // This ensures DB is rebuilt after clear app data
    try {
      logInfo(
          'Auto-syncing ${contents.length} items from filesystem to database...');
      final syncResult =
          await _offlineContentManager.syncBackupToDatabase(loadPath);
      final synced = syncResult['synced'] ?? 0;
      final updated = syncResult['updated'] ?? 0;
      logInfo('Auto-sync complete: $synced new, $updated updated');
    } catch (e) {
      logInfo('Auto-sync failed (non-blocking): $e');
      // Don't throw - content is already displayed, sync is best-effort
    }
  }

  /// Load more offline content (pagination)
  ///
  /// This smart method calls either searchOfflineContent or getAllOfflineContent
  /// depending on whether a search query is active.
  Future<void> loadMoreContent() async {
    final currentState = state;
    if (currentState is OfflineSearchLoaded && currentState.query.isNotEmpty) {
      // If active search, load more search results
      await searchOfflineContent(currentState.query, loadMore: true);
    } else {
      // If no active search, load more general content
      await getAllOfflineContent(loadMore: true);
    }
  }

  /// Force reload content from database
  /// Call this after sync operations to ensure UI is up to date
  Future<void> forceRefresh({String? backupPath}) async {
    try {
      logInfo('Force refreshing offline content from database');

      // Clear any cached data in the manager
      _offlineContentManager.clearCache();

      // Reload from database
      await getAllOfflineContent(backupPath: backupPath);
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'force refresh');
    }
  }

  /// Clear search results
  void clearSearch() {
    emit(const OfflineSearchInitial());
  }

  /// Set loading state (for external triggers like import operations)
  void setLoadingState() {
    emit(const OfflineSearchLoading());
  }

  /// Get offline storage statistics
  ///
  /// Returns stats based on current state:
  /// - When OfflineSearchLoaded (any query): calculate from loaded results
  /// - When Initial/Loading/Empty/Error: get from database
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      // If we have content loaded (whether filtered by search or all content),
      // calculate stats from the loaded results for consistency
      int storageUsage = 0;
      int totalCount = 0;
      bool isSearchResult = false;

      if (state is OfflineSearchLoaded) {
        final loadedState = state as OfflineSearchLoaded;
        if (loadedState.query.isNotEmpty) {
          isSearchResult = true;
          totalCount = loadedState.totalResults;

          // Use optimized DB query for search result size
          storageUsage = await _userDataRepository.getSearchDownloadSize(
            query: loadedState.query,
            state: DownloadState.completed,
          );
        }
      }

      // If not a search result (or empty query), get total library stats
      if (!isSearchResult) {
        storageUsage = await _offlineContentManager.getOfflineStorageUsage();
        totalCount = await _userDataRepository.getDownloadsCount(
          state: DownloadState.completed,
        );
      }

      return {
        'totalContent': totalCount,
        'storageUsage': storageUsage,
        'formattedSize': OfflineContentManager.formatStorageSize(storageUsage),
        'isSearchResult': isSearchResult,
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

  /// Cleanup orphaned offline files
  Future<void> cleanupOfflineFiles() async {
    try {
      logInfo('Starting cleanup of orphaned offline files');
      await _offlineContentManager.cleanupOrphanedFiles();
      // Clear cache after cleanup
      _offlineContentManager.clearCache();
      logInfo('Cleanup completed successfully');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'cleanup offline files');
      rethrow;
    }
  }

  /// Scan backup folder for offline content
  Future<void> scanBackupContent(String backupPath) async {
    try {
      logInfo('Scanning backup folder: $backupPath');
      emit(const OfflineSearchLoading());

      final backupContents =
          await _offlineContentManager.scanBackupFolder(backupPath);

      if (backupContents.isEmpty) {
        emit(const OfflineSearchEmpty(query: ''));
        return;
      }

      // Calculate sizes for all content
      final offlineSizes = await _calculateContentSizes(backupContents);

      // Calculate total storage usage
      int totalStorageUsage = 0;
      for (final content in backupContents) {
        if (content.imageUrls.isNotEmpty) {
          try {
            final file = File(content.imageUrls.first);
            final dirPath = file.parent.path;
            totalStorageUsage += await _getDirectorySize(Directory(dirPath));
          } catch (_) {}
        }
      }

      final List<ContentGroup> groupedResults =
          await _groupContent(backupContents);

      emit(OfflineSearchLoaded(
        query: '',
        results: groupedResults,
        totalResults: backupContents.length,
        offlineSizes: offlineSizes,
        storageUsage: totalStorageUsage,
        formattedStorageUsage:
            OfflineContentManager.formatStorageSize(totalStorageUsage),
        isListMode: _prefs.getBool(_keyIsListMode) ?? false,
      ));

      logInfo('Found ${backupContents.length} backup content items');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'scan backup content');
      emit(const OfflineSearchError(
        message: 'failedScanBackup',
        query: '',
      ));
    }
  }

  /// Get search history
  Future<List<String>> getSearchHistory() async {
    try {
      return await _userDataRepository.getSearchHistory(limit: 10);
    } catch (e) {
      logInfo('Error getting search history: $e');
      return [];
    }
  }

  /// Delete a search history entry
  Future<void> deleteSearchHistory(String query) async {
    try {
      await _userDataRepository.deleteSearchHistory(query);
    } catch (e) {
      logInfo('Error deleting search history: $e');
    }
  }

  /// Delete offline content
  Future<void> deleteOfflineContent(String contentId) async {
    try {
      logInfo('Deleting offline content: $contentId');

      final deleted =
          await _offlineContentManager.deleteOfflineContent(contentId);
      if (!deleted) {
        throw StateError('Offline content not found: $contentId');
      }
      _sizeBytesByContentId.remove(contentId);

      // Refresh the list
      // If we are searching, we might want to re-search?
      // Or just refresh global list if query is empty
      if (state is OfflineSearchLoaded) {
        final query = (state as OfflineSearchLoaded).query;
        if (query.isNotEmpty) {
          await searchOfflineContent(query);
        } else {
          await getAllOfflineContent();
        }
      } else {
        await getAllOfflineContent();
      }

      logInfo('Deleted content $contentId');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'delete offline content');
      rethrow;
    }
  }

  /// Groups a flat list of Content into ContentGroup based on sourceId + baseTitle
  Future<List<ContentGroup>> _groupContent(
    List<Content> flatItems, {
    Map<String, int> itemSizes = const {},
  }) async {
    final Map<String, List<Content>> groupedMap = {};
    for (final item in flatItems) {
      final baseTitle = TitleParserUtils.getBaseTitle(item.title);
      final groupKey = '${item.sourceId}:::$baseTitle';
      groupedMap.putIfAbsent(groupKey, () => []).add(item);
    }

    // Try to get ReaderPositionRepository if registered
    dynamic readerPosRepo;
    try {
      readerPosRepo = getIt<ReaderRepository>();
    } catch (_) {
      // Ignore if not found
    }

    final List<ContentGroup> groups = [];
    for (final entry in groupedMap.entries) {
      final items = ContentGroup.dedupeItems(entry.value);
      if (items.isEmpty) continue;

      final baseTitle = TitleParserUtils.getBaseTitle(items.first.title);
      final totalSize = items.fold<int>(
        0,
        (sum, item) => sum + (itemSizes[item.id] ?? 0),
      );
      final groupItemSizes = {
        for (final item in items) item.id: itemSizes[item.id] ?? 0,
      };
      double maxProgress = 0.0;
      bool isRead = false;
      bool isReading = false;

      // Check progress for all items in the group and take the highest
      for (final item in items) {
        try {
          if (readerPosRepo != null) {
            final position = await readerPosRepo.getReaderPosition(item.id);
            if (position != null && position.totalPages > 0) {
              final double progress =
                  position.currentPage / position.totalPages;
              if (progress > maxProgress) maxProgress = progress;
              if (position.currentPage >= position.totalPages - 1) {
                isRead = true;
              } else if (position.currentPage > 1) {
                isReading = true;
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      }

      groups.add(ContentGroup(
        baseTitle: baseTitle,
        items: items,
        totalSize: totalSize,
        itemSizes: groupItemSizes,
        readProgress: maxProgress > 1.0 ? 1.0 : maxProgress,
        isRead: isRead,
        isReading: isReading,
      ));
    }
    return groups;
  }
}
