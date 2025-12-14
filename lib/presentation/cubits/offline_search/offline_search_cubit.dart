import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/utils/offline_content_manager.dart';
import '../../../domain/entities/content.dart';
import '../../../domain/entities/download_status.dart';
import '../../../domain/repositories/user_data_repository.dart';
import '../../../core/constants/app_constants.dart';
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

  /// Search in offline content from metadata.json files
  Future<void> searchOfflineContent(String query, {String? backupPath}) async {
    try {
      if (query.trim().isEmpty) {
        emit(const OfflineSearchInitial());
        return;
      }

      logInfo('Searching offline content for: $query');
      emit(const OfflineSearchLoading());

      // Get backup path from DirectoryUtils if not provided
      String? searchPath = backupPath;
      if (searchPath == null) {
        // Import DirectoryUtils at the top if not already imported
        final nhasixPath =
            await findNhasixBackupFolder(); // You'll need to import this
        if (nhasixPath == null) {
          emit(const OfflineSearchEmpty(query: ''));
          return;
        }
        searchPath = nhasixPath;
      }

      final contents = await _offlineContentManager
          .searchOfflineContentFromFileSystem(searchPath, query);

      if (contents.isEmpty) {
        emit(const OfflineSearchEmpty(query: ''));
        return;
      }

      // Calculate sizes for all content
      final offlineSizes = await _calculateContentSizes(contents);

      emit(OfflineSearchLoaded(
        query: query,
        results: contents,
        totalResults: contents.length,
        offlineSizes: offlineSizes,
      ));

      logInfo('Found ${contents.length} offline content matches for: $query');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'search offline content');
      emit(OfflineSearchError(
        message: 'Failed to search offline content: ${e.toString()}',
        query: query,
      ));
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

  /// Get all offline content from DATABASE (primary source)
  /// Falls back to file scan only if no database entries exist
  Future<void> getAllOfflineContent({String? backupPath}) async {
    try {
      logInfo('Loading all offline content from database');
      emit(const OfflineSearchLoading());

      // Load completed downloads from database
      final downloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        limit: AppLimits.maxBatchSize,
      );

      if (downloads.isEmpty) {
        // Fallback to file scan if database is empty (first-time setup)
        logInfo('No downloads in database, falling back to file scan');
        await _loadFromFileSystem(backupPath);
        return;
      }

      // Convert DownloadStatus to Content objects
      final contents = <Content>[];
      final offlineSizes = <String, String>{};

      for (final download in downloads) {
        final content = await _offlineContentManager
            .createOfflineContent(download.contentId);
        if (content != null) {
          contents.add(content);
          offlineSizes[download.contentId] = download.formattedFileSize;
        }
      }

      if (contents.isEmpty) {
        emit(const OfflineSearchEmpty(query: ''));
        return;
      }

      emit(OfflineSearchLoaded(
        query: '',
        results: contents,
        totalResults: contents.length,
        offlineSizes: offlineSizes,
      ));

      logInfo('Loaded ${contents.length} offline content items from database');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get all offline content');
      emit(const OfflineSearchError(
        message: 'Failed to load offline content',
        query: '',
      ));
    }
  }

  /// Fallback: Load from file system (used for initial setup/import)
  Future<void> _loadFromFileSystem(String? backupPath) async {
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

    emit(OfflineSearchLoaded(
      query: '',
      results: contents,
      totalResults: contents.length,
      offlineSizes: offlineSizes,
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

  /// Get offline storage statistics
  ///
  /// Returns stats based on current state:
  /// - When OfflineSearchLoaded (any query): calculate from loaded results
  /// - When Initial/Loading/Empty/Error: get from database
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      // If we have content loaded (whether filtered by search or all content),
      // calculate stats from the loaded results for consistency
      if (state is OfflineSearchLoaded) {
        final loadedState = state as OfflineSearchLoaded;
        final totalContent = loadedState.totalResults;

        // Calculate storage usage from loaded content files
        int totalSize = 0;
        for (final content in loadedState.results) {
          for (final imageUrl in content.imageUrls) {
            try {
              final file = File(imageUrl);
              if (await file.exists()) {
                totalSize += await file.length();
              }
            } catch (e) {
              // Skip files that can't be accessed
            }
          }
        }

        return {
          'totalContent': totalContent,
          'storageUsage': totalSize,
          'formattedSize': OfflineContentManager.formatStorageSize(totalSize),
          'isSearchResult': loadedState.query.isNotEmpty,
        };
      }

      // Default: get stats from database (when no content is loaded yet)
      final offlineIds = await _offlineContentManager.getOfflineContentIds();
      final storageUsage =
          await _offlineContentManager.getOfflineStorageUsage();

      return {
        'totalContent': offlineIds.length,
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

      emit(OfflineSearchLoaded(
        query: '',
        results: backupContents,
        totalResults: backupContents.length,
        offlineSizes: offlineSizes,
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
}
