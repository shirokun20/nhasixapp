import 'dart:io';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import '../domain/entities/download_status.dart';
import '../domain/repositories/user_data_repository.dart';
import '../core/utils/offline_content_manager.dart';

/// Service for exporting and importing offline library
class ExportService {
  final UserDataRepository _userDataRepository;
  final Logger _logger;

  ExportService({
    required UserDataRepository userDataRepository,
    required OfflineContentManager offlineContentManager,
    required Logger logger,
  })  : _userDataRepository = userDataRepository,
        _logger = logger;

  /// Export library to a folder structure
  /// Returns the path to the export folder
  ///
  /// [onProgress] callback provides progress (0.0-1.0) and status message
  Future<String> exportLibrary({
    void Function(double progress, String message)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory('${tempDir.path}/nhasix_export_$timestamp');

    try {
      await exportDir.create(recursive: true);
      _logger.i('Created export directory: ${exportDir.path}');

      // Step 1: Export database to JSON (10%)
      onProgress?.call(0.05, 'Exporting database...');
      final dbExport = await _exportDatabaseToJson();
      final dbFile = File('${exportDir.path}/database.json');
      await dbFile.writeAsString(jsonEncode(dbExport));
      _logger.i('Exported database to JSON');

      // Step 2: Get all completed downloads
      onProgress?.call(0.1, 'Loading downloads...');
      final downloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        limit: 1000,
      );

      if (downloads.isEmpty) {
        onProgress?.call(1.0, 'No content to export');
        return exportDir.path;
      }

      // Step 3: Copy content folders (10% - 90%)
      final contentDir = Directory('${exportDir.path}/content');
      await contentDir.create(recursive: true);

      for (int i = 0; i < downloads.length; i++) {
        final download = downloads[i];
        final progress = 0.1 + (0.8 * (i / downloads.length));
        onProgress?.call(progress, 'Copying ${download.contentId}...');

        try {
          if (download.downloadPath != null) {
            final srcDir = Directory(download.downloadPath!);
            if (await srcDir.exists()) {
              final destDir =
                  Directory('${contentDir.path}/${download.contentId}');
              await _copyDirectory(srcDir, destDir);
              _logger.d('Copied content: ${download.contentId}');
            }
          }
        } catch (e) {
          _logger.w('Failed to copy ${download.contentId}: $e');
          // Continue with other content
        }
      }

      // Step 4: Create manifest
      onProgress?.call(0.95, 'Creating manifest...');
      final manifest = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalItems': downloads.length,
        'app': 'NhasixApp',
      };
      final manifestFile = File('${exportDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode(manifest));

      onProgress?.call(1.0, 'Export complete!');
      _logger
          .i('Export complete: ${downloads.length} items to ${exportDir.path}');

      return exportDir.path;
    } catch (e, stackTrace) {
      _logger.e('Export failed', error: e, stackTrace: stackTrace);
      // Cleanup on failure
      try {
        if (await exportDir.exists()) {
          await exportDir.delete(recursive: true);
        }
      } catch (_) {}
      rethrow;
    }
  }

  /// Share the exported library folder
  Future<void> shareExport(String exportPath) async {
    try {
      final exportDir = Directory(exportPath);
      if (!await exportDir.exists()) {
        throw Exception('Export folder not found');
      }

      // Collect all files to share
      final files = <XFile>[];
      await for (final entity in exportDir.list(recursive: true)) {
        if (entity is File) {
          files.add(XFile(entity.path));
        }
      }

      if (files.isEmpty) {
        throw Exception('No files to share');
      }

      // Share the database.json and manifest as a starting point
      // For full export, users should copy the entire folder
      final dbFile = File('$exportPath/database.json');
      final manifestFile = File('$exportPath/manifest.json');

      final filesToShare = <XFile>[];
      if (await dbFile.exists()) {
        filesToShare.add(XFile(dbFile.path));
      }
      if (await manifestFile.exists()) {
        filesToShare.add(XFile(manifestFile.path));
      }

      await Share.shareXFiles(
        filesToShare,
        text: 'Nhasix Library Export - ${filesToShare.length} files',
        subject: 'Nhasix Library Backup',
      );

      _logger.i('Shared export with ${filesToShare.length} files');
    } catch (e, stackTrace) {
      _logger.e('Failed to share export', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get total export size estimate
  Future<int> getExportSizeEstimate() async {
    int totalSize = 0;

    final downloads = await _userDataRepository.getAllDownloads(
      state: DownloadState.completed,
      limit: 1000,
    );

    for (final download in downloads) {
      totalSize += download.fileSize;
    }

    return totalSize;
  }

  /// Export database tables to JSON
  Future<Map<String, dynamic>> _exportDatabaseToJson() async {
    // Get downloads
    final downloads = await _userDataRepository.getAllDownloads(
      state: DownloadState.completed,
      limit: 1000,
    );

    // Get favorites
    final favorites = await _userDataRepository.getFavorites(limit: 1000);

    // Get history
    final history = await _userDataRepository.getHistory(limit: 1000);

    return {
      'downloads': downloads
          .map((d) => {
                'contentId': d.contentId,
                'state': d.state.name,
                'downloadedPages': d.downloadedPages,
                'totalPages': d.totalPages,
                'downloadPath': d.downloadPath,
                'fileSize': d.fileSize,
                'startTime': d.startTime?.toIso8601String(),
                'endTime': d.endTime?.toIso8601String(),
              })
          .toList(),
      'favorites': favorites,
      'history': history
          .map((h) => {
                'id': h.contentId,
                'title': h.title,
                'coverUrl': h.coverUrl,
                'lastPage': h.lastPage,
                'totalPages': h.totalPages,
                'lastReadAt': h.lastViewed.toIso8601String(),
              })
          .toList(),
    };
  }

  /// Copy directory recursively
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list()) {
      final newPath = path.join(destination.path, path.basename(entity.path));

      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  /// Cleanup old export folders
  Future<void> cleanupOldExports() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await for (final entity in tempDir.list()) {
        if (entity is Directory &&
            path.basename(entity.path).startsWith('nhasix_export_')) {
          // Delete exports older than 1 day
          final stat = await entity.stat();
          if (DateTime.now().difference(stat.modified).inDays > 1) {
            await entity.delete(recursive: true);
            _logger.d('Cleaned up old export: ${entity.path}');
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to cleanup old exports: $e');
    }
  }
}
