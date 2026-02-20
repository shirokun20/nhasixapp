import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/utils/offline_content_manager.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../../domain/entities/download_status.dart';
import '../../../domain/repositories/user_data_repository.dart';

import '../base/base_cubit.dart';

part 'offline_search_state.dart';

/// Cubit for searching offline/downloaded content
class OfflineSearchCubit extends BaseCubit<OfflineSearchState> {
  OfflineSearchCubit({
    required OfflineContentManager offlineContentManager,
    required UserDataRepository userDataRepository,
    required super.logger,
  })  : _offlineContentManager = offlineContentManager,
        _userDataRepository = userDataRepository,
        super(
          initialState: const OfflineSearchInitial(),
        );

  final OfflineContentManager _offlineContentManager;
  final UserDataRepository _userDataRepository;

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
        // Get the directory path from the first image URL
        if (content.imageUrls.isNotEmpty) {
          final firstImagePath = content.imageUrls.first;
          final file = File(firstImagePath);
          final dirPath = file.parent.path;

          // Calculate directory size
          final sizeInBytes = await _getDirectorySize(Directory(dirPath));
          sizes[content.id] =
              OfflineContentManager.formatStorageSize(sizeInBytes);
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

    // Update state with new filter immediately
    var currentState = state;
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
      final offset = loadMore && state is OfflineSearchLoaded
          ? (state as OfflineSearchLoaded).results.length
          : 0;

      // Search from database with pagination
      final dbResults = await _userDataRepository.searchDownloads(
        query: query,
        state: DownloadState.completed,
        sourceId: effectiveSourceId,
        limit: pageSize,
        offset: offset,
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
      int newStorageUsage = 0;

      for (final row in dbResults) {
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
        newStorageUsage += fileSize;
      }

      if (isClosed) return;

      // Merge with existing results if loading more
      final List<Content> finalResults;
      final Map<String, String> finalSizes;
      final int finalStorageUsage;

      if (loadMore && state is OfflineSearchLoaded) {
        final currentState = state as OfflineSearchLoaded;
        finalResults = [...currentState.results, ...newContents];
        finalSizes = {...currentState.offlineSizes, ...newOfflineSizes};
        finalStorageUsage = currentState.storageUsage + newStorageUsage;
      } else {
        finalResults = newContents;
        finalSizes = newOfflineSizes;
        finalStorageUsage = newStorageUsage;
      }

      // Calculate pagination metadata
      final currentPage = (finalResults.length / pageSize).ceil();
      final totalPages = (totalCount / pageSize).ceil();
      final hasMore = finalResults.length < totalCount;

      if (finalResults.isEmpty && offset == 0) {
        // Keep sourceId in empty state if we want to show filtered empty state
        emit(OfflineSearchEmpty(query: query));
        return;
      }

      emit(OfflineSearchLoaded(
        query: query,
        results: finalResults,
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
      ));

      logInfo(
          'Search complete: ${finalResults.length}/$totalCount results for "$query" (source: $effectiveSourceId) '
          '(page $currentPage/$totalPages, hasMore: $hasMore)');
    } catch (e, stackTrace) {
      if (isClosed) return;
      handleError(e, stackTrace, 'search offline content');

      // If we were loading more, restore previous state
      if (loadMore && state is OfflineSearchLoaded) {
        emit((state as OfflineSearchLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(OfflineSearchError(
          message: 'Failed to search offline content: ${e.toString()}',
          query: query,
        ));
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
        effectiveSourceId = (state as OfflineSearchLoaded).selectedSourceId;
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
      final offset = loadMore && state is OfflineSearchLoaded
          ? (state as OfflineSearchLoaded).results.length
          : 0;

      // Load page from database
      final downloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        sourceId: effectiveSourceId,
        limit: pageSize,
        offset: offset,
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

        // Use DB size if available, otherwise calculate dynamically
        if (download.fileSize > 0) {
          newOfflineSizes[download.contentId] = download.formattedFileSize;
          newStorageUsage += download.fileSize;
        } else {
          // fileSize == 0: calculate from filesystem and update DB in background
          try {
            final imageFile = File(firstImagePath);
            final contentDir = imageFile.parent.parent; // images/ -> content/
            if (contentDir.existsSync()) {
              int calculatedSize = 0;
              await for (final entity in contentDir.list(recursive: true)) {
                if (entity is File) {
                  calculatedSize += await entity.length();
                }
              }
              if (calculatedSize > 0) {
                newOfflineSizes[download.contentId] =
                    OfflineContentManager.formatStorageSize(calculatedSize);
                newStorageUsage += calculatedSize;

                // Update DB in background so next load is instant
                _userDataRepository.saveDownloadStatus(
                  download.copyWith(fileSize: calculatedSize),
                );
              } else {
                newOfflineSizes[download.contentId] =
                    download.formattedFileSize;
              }
            } else {
              newOfflineSizes[download.contentId] = download.formattedFileSize;
            }
          } catch (e) {
            logInfo('Failed to calculate size for ${download.contentId}: $e');
            newOfflineSizes[download.contentId] = download.formattedFileSize;
          }
        }
      }

      if (isClosed) return;

      // Merge with existing results if loading more
      final List<Content> finalResults;
      final Map<String, String> finalSizes;
      final int finalStorageUsage;

      if (loadMore && state is OfflineSearchLoaded) {
        final currentState = state as OfflineSearchLoaded;
        finalResults = [...currentState.results, ...newContents];
        finalSizes = {...currentState.offlineSizes, ...newOfflineSizes};
        finalStorageUsage = currentState.storageUsage + newStorageUsage;
      } else {
        finalResults = newContents;
        finalSizes = newOfflineSizes;
        finalStorageUsage = newStorageUsage;
      }

      // Calculate pagination metadata
      final currentPage = (finalResults.length / pageSize).ceil();
      final totalPages = (totalCount / pageSize).ceil();
      final hasMore = finalResults.length < totalCount;

      if (finalResults.isEmpty) {
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
        ));
        return;
      }

      emit(OfflineSearchLoaded(
        query: '',
        results: finalResults,
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
      ));

      logInfo(
          'Loaded ${finalResults.length}/$totalCount offline content items (source: $effectiveSourceId) '
          '(page $currentPage/$totalPages, hasMore: $hasMore)');
    } catch (e, stackTrace) {
      if (isClosed) return;
      handleError(e, stackTrace, 'get all offline content');

      // If we were loading more, restore previous state
      if (loadMore && state is OfflineSearchLoaded) {
        emit((state as OfflineSearchLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(const OfflineSearchError(
          message: 'Failed to load offline content',
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

    emit(OfflineSearchLoaded(
      query: '',
      results: contents,
      totalResults: contents.length,
      offlineSizes: offlineSizes,
      storageUsage: totalStorageUsage,
      formattedStorageUsage:
          OfflineContentManager.formatStorageSize(totalStorageUsage),
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
        final offlineIds = await _offlineContentManager.getOfflineContentIds();
        totalCount = offlineIds.length;
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

      emit(OfflineSearchLoaded(
        query: '',
        results: backupContents,
        totalResults: backupContents.length,
        offlineSizes: offlineSizes,
        storageUsage: totalStorageUsage,
        formattedStorageUsage:
            OfflineContentManager.formatStorageSize(totalStorageUsage),
      ));

      logInfo('Found ${backupContents.length} backup content items');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'scan backup content');
      emit(OfflineSearchError(
        message: 'Failed to scan backup folder: ${e.toString()}',
        query: '',
      ));
    }
  }

  /// Delete offline content
  Future<void> deleteOfflineContent(String contentId) async {
    try {
      logInfo('Deleting offline content: $contentId');

      await _offlineContentManager.deleteOfflineContent(contentId);

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
      // We might want to emit error state? Or just log it.
      // Keeping current state but maybe showing a snackbar is handled by UI.
    }
  }
}
