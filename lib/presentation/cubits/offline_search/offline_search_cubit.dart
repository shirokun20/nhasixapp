import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/utils/offline_content_manager.dart';
import '../../../domain/entities/content.dart';
import '../base/base_cubit.dart';

part 'offline_search_state.dart';

/// Cubit for searching offline/downloaded content
class OfflineSearchCubit extends BaseCubit<OfflineSearchState> {
  OfflineSearchCubit({
    required OfflineContentManager offlineContentManager,
    required super.logger,
  })  : _offlineContentManager = offlineContentManager,
        super(
          initialState: const OfflineSearchInitial(),
        );

  final OfflineContentManager _offlineContentManager;

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

      emit(OfflineSearchLoaded(
        query: query,
        results: contents,
        totalResults: contents.length,
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

  /// Get all offline content from file system
  Future<void> getAllOfflineContent({String? backupPath}) async {
    try {
      logInfo('Loading all offline content from file system');
      emit(const OfflineSearchLoading());

      // Get backup path from DirectoryUtils if not provided
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

      // Sort by content ID (descending for newest first)
      contents.sort((a, b) => b.id.compareTo(a.id));

      emit(OfflineSearchLoaded(
        query: '',
        results: contents,
        totalResults: contents.length,
      ));

      logInfo(
          'Loaded ${contents.length} offline content items from file system');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get all offline content');
      emit(const OfflineSearchError(
        message: 'Failed to load offline content',
        query: '',
      ));
    }
  }

  /// Clear search results
  void clearSearch() {
    emit(const OfflineSearchInitial());
  }

  /// Get offline storage statistics
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      // If we have backup content loaded (OfflineSearchLoaded with empty query),
      // calculate stats from the loaded results instead of database
      if (state is OfflineSearchLoaded &&
          (state as OfflineSearchLoaded).query.isEmpty) {
        final loadedState = state as OfflineSearchLoaded;
        final totalContent = loadedState.totalResults;

        // Calculate storage usage from backup content files
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
        };
      }

      // Default: get stats from database
      final offlineIds = await _offlineContentManager.getOfflineContentIds();
      final storageUsage =
          await _offlineContentManager.getOfflineStorageUsage();

      return {
        'totalContent': offlineIds.length,
        'storageUsage': storageUsage,
        'formattedSize': OfflineContentManager.formatStorageSize(storageUsage),
      };
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get offline stats');
      return {
        'totalContent': 0,
        'storageUsage': 0,
        'formattedSize': '0 B',
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

      emit(OfflineSearchLoaded(
        query: '',
        results: backupContents,
        totalResults: backupContents.length,
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
