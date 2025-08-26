import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/content.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/repositories/user_data_repository.dart';

/// Manager for offline content detection and operations
class OfflineContentManager {
  OfflineContentManager({
    required UserDataRepository userDataRepository,
    Logger? logger,
  })  : _userDataRepository = userDataRepository,
        _logger = logger ?? Logger();

  final UserDataRepository _userDataRepository;
  final Logger _logger;

  /// Check if content is available offline
  Future<bool> isContentAvailableOffline(String contentId) async {
    try {
      // Check if content is downloaded and completed
      final downloadStatus =
          await _userDataRepository.getDownloadStatus(contentId);

      if (downloadStatus?.state != DownloadState.completed) {
        return false;
      }

      // Verify files exist on disk
      final contentPath = await getOfflineContentPath(contentId);
      if (contentPath == null) return false;

      final contentDir = Directory(contentPath);
      if (!await contentDir.exists()) return false;

      // Check if at least one image file exists
      final files = await contentDir.list().toList();
      final imageFiles = files
          .where((file) => file is File && _isImageFile(file.path))
          .toList();

      return imageFiles.isNotEmpty;
    } catch (e, stackTrace) {
      _logger.e('Error checking offline availability for $contentId',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get offline content path for a specific content ID
  Future<String?> getOfflineContentPath(String contentId) async {
    try {
      final downloadStatus =
          await _userDataRepository.getDownloadStatus(contentId);
      // _logger.i("Location: path: ${downloadStatus?.downloadPath}");
      return downloadStatus?.downloadPath;
    } catch (e, stackTrace) {
      _logger.e('Error getting offline content path for $contentId',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get offline image URLs for content
  Future<List<String>> getOfflineImageUrls(String contentId) async {
    try {
      final contentPath = await getOfflineContentPath(contentId);
      if (contentPath == null) return [];

      final contentDir = Directory(contentPath);
      if (!await contentDir.exists()) return [];

      final files = await contentDir.list().toList();
      final imageFiles = files
          .where((file) => file is File && _isImageFile(file.path))
          .cast<File>()
          .toList();

      // Sort by filename to maintain page order
      imageFiles.sort((a, b) =>
          _extractPageNumber(a.path).compareTo(_extractPageNumber(b.path)));

      return imageFiles.map((file) => file.path).toList();
    } catch (e, stackTrace) {
      _logger.e('Error getting offline image URLs for $contentId',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all offline content IDs
  Future<List<String>> getOfflineContentIds() async {
    try {
      final downloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        limit: 1000, // Get all completed downloads
      );

      final offlineIds = <String>[];

      for (final download in downloads) {
        if (await isContentAvailableOffline(download.contentId)) {
          // _logger.i("isi file nya: $download");
          offlineIds.add(download.contentId);
        }
      }

      return offlineIds;
    } catch (e, stackTrace) {
      _logger.e('Error getting offline content IDs',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Search in offline content
  Future<List<String>> searchOfflineContent(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final offlineIds = await getOfflineContentIds();
      final matchingIds = <String>[];

      // Get favorites and history for additional metadata
      final favorites = await _userDataRepository.getFavorites(limit: 1000);
      final history = await _userDataRepository.getHistory(limit: 1000);

      final favoriteMap = {for (var fav in favorites) fav['id']: fav};
      final historyMap = {for (var hist in history) hist.contentId: hist};

      for (final contentId in offlineIds) {
        // Search in content ID
        if (contentId.toLowerCase().contains(query.toLowerCase())) {
          matchingIds.add(contentId);
          continue;
        }

        // Search in favorite title if available
        final favorite = favoriteMap[contentId];
        if (favorite != null) {
          final title = favorite['title'] as String?;
          if (title != null &&
              title.toLowerCase().contains(query.toLowerCase())) {
            matchingIds.add(contentId);
            continue;
          }
        }

        // Search in history title if available
        final historyEntry = historyMap[contentId];
        if (historyEntry != null) {
          final title = historyEntry.title;
          if (title != null &&
              title.toLowerCase().contains(query.toLowerCase())) {
            matchingIds.add(contentId);
            continue;
          }
        }
      }

      return matchingIds;
    } catch (e, stackTrace) {
      _logger.e('Error searching offline content',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get offline content metadata
  Future<Map<String, dynamic>?> getOfflineContentMetadata(
      String contentId) async {
    try {
      // Try to get from favorites first
      final favorites = await _userDataRepository.getFavorites(limit: 1000);
      final favorite =
          favorites.where((fav) => fav['id'] == contentId).firstOrNull;
      _logger.i("apakah data dari favorite? ${favorite != null}");
      if (favorite != null) {
        return {
          'id': contentId,
          'title': favorite['title'] ?? 'Unknown Title',
          'coverUrl': favorite['cover_url'] ?? '',
          'source': 'favorites',
        };
      }

      // Try to get from history
      final historyEntry = await _userDataRepository.getHistoryEntry(contentId);
      _logger.i("apakah data dari history? ${historyEntry != null}");
      _logger.i("isi file history nya: $historyEntry");
      if (historyEntry != null) {
        return {
          'id': contentId,
          'title': historyEntry.title ?? 'Unknown Title',
          'coverUrl': historyEntry.coverUrl ?? '',
          'source': 'history',
        };
      }

      // Fallback to basic info
      return {
        'id': contentId,
        'title': 'Offline Content $contentId',
        'coverUrl': '',
        'source': 'offline',
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting offline content metadata for $contentId',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Create offline content object from metadata
  Future<Content?> createOfflineContent(String contentId) async {
    try {
      final metadata = await getOfflineContentMetadata(contentId);
      if (metadata == null) return null;

      final imageUrls = await getOfflineImageUrls(contentId);
      _logger.i("apakah ada gambarnya? ${imageUrls.isEmpty}");
      if (imageUrls.isEmpty) return null;

      return Content(
        id: contentId,
        title: metadata['title'] as String,
        coverUrl: metadata['coverUrl'] as String,
        tags: [], // No tags available offline
        artists: [], // No artists available offline
        characters: [], // No characters available offline
        parodies: [], // No parodies available offline
        groups: [], // No groups available offline
        language: '', // No language info offline
        pageCount: imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: DateTime.now(), // Fallback date
        favorites: 0, // No favorites count offline
        englishTitle: null,
        japaneseTitle: null,
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating offline content for $contentId',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get offline storage usage
  Future<int> getOfflineStorageUsage() async {
    try {
      final offlineIds = await getOfflineContentIds();
      int totalSize = 0;

      for (final contentId in offlineIds) {
        final contentPath = await getOfflineContentPath(contentId);
        if (contentPath != null) {
          final contentDir = Directory(contentPath);
          if (await contentDir.exists()) {
            await for (final file in contentDir.list(recursive: true)) {
              if (file is File) {
                final stat = await file.stat();
                totalSize += stat.size;
              }
            }
          }
        }
      }

      return totalSize;
    } catch (e, stackTrace) {
      _logger.e('Error calculating offline storage usage',
          error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Clean up orphaned offline files
  Future<void> cleanupOrphanedFiles() async {
    try {
      _logger.i('Starting cleanup of orphaned offline files');

      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(path.join(appDir.path, 'downloads'));

      if (!await downloadsDir.exists()) return;

      final validDownloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        limit: 1000,
      );

      final validPaths = validDownloads
          .map((d) => d.downloadPath)
          .where((p) => p != null)
          .cast<String>()
          .toSet();

      await for (final entity in downloadsDir.list()) {
        if (entity is Directory) {
          if (!validPaths.contains(entity.path)) {
            _logger.d('Removing orphaned directory: ${entity.path}');
            await entity.delete(recursive: true);
          }
        }
      }

      _logger.i('Cleanup of orphaned offline files completed');
    } catch (e, stackTrace) {
      _logger.e('Error during cleanup of orphaned files',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Helper method to check if file is an image
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
        .contains(extension);
  }

  /// Helper method to extract page number from filename
  int _extractPageNumber(String filePath) {
    final filename = path.basenameWithoutExtension(filePath);
    final match = RegExp(r'(\d+)').firstMatch(filename);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  /// Format storage size for display
  static String formatStorageSize(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }
}
