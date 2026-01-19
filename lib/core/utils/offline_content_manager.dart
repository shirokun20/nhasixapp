import 'dart:io';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/domain/extensions/content_extensions.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/repositories/user_data_repository.dart';
import '../constants/app_constants.dart';
import 'download_storage_utils.dart';

/// Manager for offline content detection and operations
class OfflineContentManager {
  OfflineContentManager({
    required UserDataRepository userDataRepository,
    Logger? logger,
  })  : _userDataRepository = userDataRepository,
        _logger = logger ?? Logger();

  final UserDataRepository _userDataRepository;
  final Logger _logger;

  // Cache for offline content IDs with TTL
  List<String>? _cachedOfflineIds;
  DateTime? _offlineIdsCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cache for content metadata
  final Map<String, Map<String, dynamic>> _metadataCache = {};
  final Map<String, DateTime> _metadataCacheTime = {};
  static const Duration _metadataCacheDuration = Duration(minutes: 10);

  // Localization callback
  String Function(String key, {Map<String, dynamic>? args})? _localize;

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

      // First, try to get path from database
      if (downloadStatus?.downloadPath != null) {
        return downloadStatus!.downloadPath;
      }

      // Fallback: try to find the content in multiple possible locations
      final possiblePaths = await _getPossibleDownloadPaths(contentId);
      for (final contentPath in possiblePaths) {
        if (await Directory(contentPath).exists()) {
          _logger.i('Found offline content path for $contentId: $contentPath');
          return contentPath;
        }
      }

      // _logger.w('No offline content path found for $contentId');
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error getting offline content path for $contentId',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all possible download paths for a content ID
  /// Includes both new source-based paths and legacy paths for backward compatibility
  Future<List<String>> _getPossibleDownloadPaths(String contentId,
      {String? sourceId}) async {
    final paths = <String>[];
    final effectiveSourceId = sourceId ?? AppStorage.defaultSourceId;

    try {
      // Try the smart detection first
      final downloadsPath = await _getDownloadsDirectory();

      // NEW: Source-based paths (nhasix/{source}/{contentId}/)
      paths.add(
          path.join(downloadsPath, 'nhasix', effectiveSourceId, contentId));

      // LEGACY: Direct paths (nhasix/{contentId}/)
      paths.add(path.join(downloadsPath, 'nhasix', contentId));

      // Try app documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      paths.add(path.join(documentsDir.path, 'downloads', 'nhasix',
          effectiveSourceId, contentId));
      paths.add(path.join(documentsDir.path, 'downloads', 'nhasix', contentId));

      // Try external storage directory directly
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final externalRoot = externalDir.path.split('/Android')[0];
          // Try common download folder names
          final folderNames = ['Download', 'Downloads', 'Unduhan', 'Descargas'];
          for (final folderName in folderNames) {
            // NEW: Source-based paths
            paths.add(path.join(externalRoot, folderName, 'nhasix',
                effectiveSourceId, contentId));
            // LEGACY: Direct paths
            paths.add(path.join(externalRoot, folderName, 'nhasix', contentId));
          }
        }
      } catch (e) {
        _logger.w('Failed to get external storage paths: $e');
      }

      // Try hardcoded paths
      final hardcodedPaths = [
        // NEW: Source-based paths
        '/storage/emulated/0/Download/nhasix/$effectiveSourceId/$contentId',
        '/storage/emulated/0/Downloads/nhasix/$effectiveSourceId/$contentId',
        '/storage/emulated/0/Unduhan/nhasix/$effectiveSourceId/$contentId',
        '/sdcard/Download/nhasix/$effectiveSourceId/$contentId',
        '/sdcard/Downloads/nhasix/$effectiveSourceId/$contentId',
        // LEGACY: Direct paths
        '/storage/emulated/0/Download/nhasix/$contentId',
        '/storage/emulated/0/Downloads/nhasix/$contentId',
        '/storage/emulated/0/Unduhan/nhasix/$contentId',
        '/sdcard/Download/nhasix/$contentId',
        '/sdcard/Downloads/nhasix/$contentId',
      ];
      paths.addAll(hardcodedPaths);
    } catch (e) {
      _logger.w('Error getting possible download paths: $e');
    }

    return paths;
  }

  /// Find content directory in filesystem by scanning possible backup paths
  /// Used as fallback when DB record doesn't exist
  Future<String?> _findContentInFilesystem(String contentId) async {
    try {
      final possiblePaths = await _getPossibleDownloadPaths(contentId);

      for (final contentPath in possiblePaths) {
        final dir = Directory(contentPath);
        if (await dir.exists()) {
          _logger.i('Found content in filesystem: $contentPath');
          return contentPath;
        }
      }

      _logger
          .w('Content $contentId not found in any known filesystem location');
      return null;
    } catch (e) {
      _logger.e('Error scanning filesystem for $contentId: $e');
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

      // First, try to find images in the 'images' subdirectory (new structure)
      final imagesDir = Directory(path.join(contentPath, 'images'));
      List<File> imageFiles = [];

      if (await imagesDir.exists()) {
        // New structure: images are in images/ subdirectory
        final files = await imagesDir.list().toList();
        imageFiles = files
            .where((file) => file is File && _isImageFile(file.path))
            .cast<File>()
            .toList();
      }

      // Fallback: if no images found in images/ directory, check content directory directly
      if (imageFiles.isEmpty) {
        final files = await contentDir.list().toList();
        imageFiles = files
            .where((file) =>
                file is File &&
                _isImageFile(file.path) &&
                path.basename(file.path) != 'metadata.json')
            .cast<File>()
            .toList();
      }

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

  /// Get offline first image path (fast, for cover display)
  /// 
  /// This method constructs the path to the first image without scanning
  /// the entire directory, making it much faster for grid/list displays.
  /// 
  /// Tries common patterns: 001.jpg, 001.png, 001.webp, 1.jpg
  Future<String?> getOfflineFirstImagePath(String contentId, {String? downloadPath}) async {
    try {
      final contentPath = downloadPath ?? await getOfflineContentPath(contentId);
      if (contentPath == null) return null;

      // Try images subdirectory first (new structure)
      final imagesDir = path.join(contentPath, 'images');
      
      // Common first page patterns
      final patterns = [
        '001.jpg', '001.png', '001.webp', '001.jpeg',
        '1.jpg', '1.png', '1.webp', '1.jpeg',
        '0001.jpg', '0001.png', '0001.webp',
      ];

      // Try new structure first
      for (final pattern in patterns) {
        final imagePath = path.join(imagesDir, pattern);
        if (await File(imagePath).exists()) {
          return imagePath;
        }
      }

      // Fallback: try old structure (images directly in content folder)
      for (final pattern in patterns) {
        final imagePath = path.join(contentPath, pattern);
        if (await File(imagePath).exists()) {
          return imagePath;
        }
      }

      // Last resort: scan directory (but only return first)
      final imageUrls = await getOfflineImageUrls(contentId);
      return imageUrls.isNotEmpty ? imageUrls.first : null;
    } catch (e) {
      _logger.e('Error getting first offline image for $contentId: $e');
      return null;
    }
  }

  /// Check if specific image is downloaded
  Future<bool> isImageDownloaded(String imageUrl) async {
    try {
      // If it's already a local file path, check directly
      if (imageUrl.startsWith('/') || imageUrl.contains('/downloads/')) {
        final file = File(imageUrl);
        return await file.exists() && await file.length() > 0;
      }

      // For online URLs, we need to find the corresponding offline path
      // Extract content ID from URL pattern (assuming URL contains content ID)
      final contentId = _extractContentIdFromUrl(imageUrl);
      if (contentId == null) return false;

      final contentPath = await getOfflineContentPath(contentId);
      if (contentPath == null) return false;

      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final filename = path.basename(uri.path);

      // First, try to find the file in the 'images' subdirectory (new structure)
      final imagesDirPath = path.join(contentPath, 'images');
      final imagesDir = Directory(imagesDirPath);

      if (await imagesDir.exists()) {
        final offlineImagePath = path.join(imagesDirPath, filename);
        final file = File(offlineImagePath);
        if (await file.exists() && await file.length() > 0) {
          return true;
        }
      }

      // Fallback: check directly in content directory (old structure)
      final offlineImagePath = path.join(contentPath, filename);
      final file = File(offlineImagePath);
      return await file.exists() && await file.length() > 0;
    } catch (e, stackTrace) {
      _logger.e('Error checking if image is downloaded: $imageUrl',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get all offline content IDs
  Future<List<String>> getOfflineContentIds() async {
    try {
      // Check cache first
      if (_cachedOfflineIds != null &&
          _offlineIdsCacheTime != null &&
          DateTime.now().difference(_offlineIdsCacheTime!) < _cacheDuration) {
        _logger.d('Using cached offline content IDs');
        return _cachedOfflineIds!;
      }

      final downloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        limit: AppLimits.maxBatchSize, // Get all completed downloads
      );

      final offlineIds = <String>[];

      for (final download in downloads) {
        if (await isContentAvailableOffline(download.contentId)) {
          offlineIds.add(download.contentId);
        }
      }

      // Update cache
      _cachedOfflineIds = offlineIds;
      _offlineIdsCacheTime = DateTime.now();

      return offlineIds;
    } catch (e, stackTrace) {
      _logger.e('Error getting offline content IDs',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Extract sourceId from folder path.
  /// Path pattern: .../nhasix/{sourceId}/{contentId}/...
  /// Returns extracted sourceId or defaultSourceId as fallback.
  String _extractSourceIdFromPath(String contentPath) {
    try {
      final segments = contentPath.split(path.separator);
      final nhasixIndex = segments.indexOf('nhasix');
      if (nhasixIndex != -1 && nhasixIndex + 1 < segments.length) {
        final potentialSource = segments[nhasixIndex + 1];
        // Only return if it's a known source (not a content ID)
        if (AppStorage.knownSources.contains(potentialSource)) {
          return potentialSource;
        }
      }
    } catch (e) {
      _logger.w('Error extracting sourceId from path: $e');
    }
    return AppStorage.defaultSourceId;
  }

  /// Extract sourceId from metadata or fall back to path extraction.
  String _extractSourceIdFromMetadataOrPath(
    Map<String, dynamic>? metadata,
    String contentPath,
  ) {
    // Try metadata first (v2 format has 'source' field)
    if (metadata != null && metadata['source'] != null) {
      return metadata['source'] as String;
    }
    // Fallback to path extraction
    return _extractSourceIdFromPath(contentPath);
  }

  /// Search in offline content
  Future<List<String>> searchOfflineContent(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final offlineIds = await getOfflineContentIds();
      final matchingIds = <String>[];

      // Get favorites and history for additional metadata
      final favorites =
          await _userDataRepository.getFavorites(limit: AppLimits.maxBatchSize);
      final history =
          await _userDataRepository.getHistory(limit: AppLimits.maxBatchSize);

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
      // Check cache first
      if (_metadataCache.containsKey(contentId) &&
          _metadataCacheTime.containsKey(contentId) &&
          DateTime.now().difference(_metadataCacheTime[contentId]!) <
              _metadataCacheDuration) {
        _logger.d('Using cached metadata for $contentId');
        return _metadataCache[contentId];
      }

      // Try to get from favorites first
      final favorites =
          await _userDataRepository.getFavorites(limit: AppLimits.maxBatchSize);
      final favorite =
          favorites.where((fav) => fav['id'] == contentId).firstOrNull;
      _logger.i(_getLocalized('offlineContentMetadata',
          args: {'contentId': contentId, 'source': 'favorites'},
          fallback: "apakah data dari favorite? ${favorite != null}"));
      if (favorite != null) {
        final metadata = {
          'id': contentId,
          'title': favorite['title'] ?? 'Unknown Title',
          'coverUrl': favorite['cover_url'] ?? '',
          'source': 'favorites',
        };
        // Cache the result
        _metadataCache[contentId] = metadata;
        _metadataCacheTime[contentId] = DateTime.now();
        return metadata;
      }

      // Try to get from history
      final historyEntry = await _userDataRepository.getHistoryEntry(contentId);
      _logger.i(_getLocalized('offlineContentMetadata',
          args: {'contentId': contentId, 'source': 'history'},
          fallback: "apakah data dari history? ${historyEntry != null}"));
      _logger.i("isi file history nya: $historyEntry");
      if (historyEntry != null) {
        final metadata = {
          'id': contentId,
          'title': historyEntry.title ?? 'Unknown Title',
          'coverUrl': historyEntry.coverUrl ?? '',
          'source': 'history',
        };
        // Cache the result
        _metadataCache[contentId] = metadata;
        _metadataCacheTime[contentId] = DateTime.now();
        return metadata;
      }

      // Fallback: Try reading from metadata.json file
      final contentPath = await getOfflineContentPath(contentId);
      if (contentPath != null) {
        final metadataFile = File(path.join(contentPath, 'metadata.json'));
        if (await metadataFile.exists()) {
          try {
            final metadataContent = await metadataFile.readAsString();
            final fileMetadata =
                json.decode(metadataContent) as Map<String, dynamic>;
            final metadata = {
              'id': contentId,
              'title': fileMetadata['title'] ?? contentId,
              'coverUrl':
                  fileMetadata['coverUrl'] ?? fileMetadata['cover_url'] ?? '',
              'source': 'metadata_file',
              'sourceId': fileMetadata['sourceId'] ??
                  fileMetadata['source_id'] ??
                  SourceType.nhentai.id,
            };
            // Cache the result
            _metadataCache[contentId] = metadata;
            _metadataCacheTime[contentId] = DateTime.now();
            _logger.d('Got metadata from file for $contentId');
            return metadata;
          } catch (e) {
            _logger.w('Error reading metadata.json for $contentId: $e');
          }
        }
      }

      // Final fallback to basic info
      final metadata = {
        'id': contentId,
        'title': contentId,
        'coverUrl': '',
        'source': 'offline',
      };
      // Cache the result
      _metadataCache[contentId] = metadata;
      _metadataCacheTime[contentId] = DateTime.now();
      return metadata;
    } catch (e, stackTrace) {
      _logger.e('Error getting offline content metadata for $contentId',
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

  /// Get all offline content from file system (used by offline search)
  Future<List<Content>> getAllOfflineContentFromFileSystem(
      String loadPath) async {
    return await scanBackupFolder(loadPath);
  }

  /// Clean up orphaned offline files
  Future<void> cleanupOrphanedFiles() async {
    try {
      _logger.i(_getLocalized('cleanupOrphanedFilesStarted',
          fallback: 'Starting cleanup of orphaned offline files'));

      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(path.join(appDir.path, 'downloads'));

      if (!await downloadsDir.exists()) return;

      final validDownloads = await _userDataRepository.getAllDownloads(
        state: DownloadState.completed,
        limit: AppLimits.maxBatchSize,
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

      _logger.i(_getLocalized('cleanupOrphanedFilesCompleted',
          fallback: 'Cleanup of orphaned offline files completed'));
    } catch (e, stackTrace) {
      _logger.e('Error during cleanup of orphaned files',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Create Content object from offline data for a specific content ID
  Future<Content?> createOfflineContent(String contentId) async {
    try {
      final contentPath = await getOfflineContentPath(contentId);
      if (contentPath == null) return null;

      final contentDir = Directory(contentPath);
      if (!await contentDir.exists()) return null;

      // Try to read metadata.json first
      String title = contentId;
      Map<String, dynamic>? metadata;
      try {
        final metadataFile = File(path.join(contentPath, 'metadata.json'));
        if (await metadataFile.exists()) {
          final metadataContent = await metadataFile.readAsString();
          metadata = json.decode(metadataContent) as Map<String, dynamic>;
          title = metadata['title'] ?? contentId;
        }
      } catch (e) {
        _logger.w('Error reading metadata for $contentId: $e');
      }

      // Extract sourceId from metadata or path
      final sourceId =
          _extractSourceIdFromMetadataOrPath(metadata, contentPath);

      // Get image files
      final imageUrls = await getOfflineImageUrls(contentId);
      if (imageUrls.isEmpty) return null;

      // Create cover URL from first image
      String coverUrl = '';
      if (imageUrls.isNotEmpty) {
        final firstImageFile = File(imageUrls.first);
        if (await firstImageFile.exists() &&
            await firstImageFile.length() > 0) {
          coverUrl = imageUrls.first;
        } else if (imageUrls.length > 1) {
          final secondImageFile = File(imageUrls[1]);
          if (await secondImageFile.exists() &&
              await secondImageFile.length() > 0) {
            coverUrl = imageUrls[1];
          }
        }
      }

      return Content(
        sourceId: sourceId,
        id: contentId,
        title: title,
        coverUrl: coverUrl,
        tags: [],
        artists: [],
        characters: [],
        parodies: [],
        groups: [],
        language: '',
        pageCount: imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: DateTime.now(),
        favorites: 0,
        englishTitle: null,
        japaneseTitle: null,
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating offline content for $contentId',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Search offline content from metadata.json files without database
  /// Supports both:
  /// - NEW: Source-based folders (nhasix/nhentai/{contentId}/, nhasix/crotpedia/{contentId}/)
  /// - LEGACY: Direct folders (nhasix/{contentId}/)
  Future<List<Content>> searchOfflineContentFromFileSystem(
      String backupPath, String query) async {
    try {
      final backupDir = Directory(backupPath);

      if (!await backupDir.exists()) {
        _logger.w('Backup folder does not exist: $backupPath');
        return [];
      }

      final matchingWithTimes = <MapEntry<Content, DateTime>>[];
      final queryLower = query.toLowerCase();

      // Known source identifiers to check for nested structure
      final knownSources = [SourceType.nhentai.id, SourceType.crotpedia.id];

      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final folderName = path.basename(entity.path);

          // Check if this is a source folder (e.g., nhentai/, crotpedia/)
          if (knownSources.contains(folderName)) {
            // Search inside source folder
            _logger.d('Searching in source folder: $folderName');
            final sourceResults =
                await _searchInFolder(entity.path, queryLower);
            matchingWithTimes.addAll(sourceResults);
          } else {
            // Legacy: Could be a content folder directly
            final result =
                await _searchContentFolder(entity, folderName, queryLower);
            if (result != null) {
              matchingWithTimes.add(result);
            }
          }
        }
      }

      // Sort by modification time descending (newest first)
      matchingWithTimes.sort((a, b) => b.value.compareTo(a.value));
      final matchingContents = matchingWithTimes.map((e) => e.key).toList();

      _logger.i(
          'Found ${matchingContents.length} matching content items for query: $query');
      return matchingContents;
    } catch (e, stackTrace) {
      _logger.e('Error searching offline content from file system',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Helper to search within a source folder (e.g., nhentai/)
  Future<List<MapEntry<Content, DateTime>>> _searchInFolder(
      String folderPath, String queryLower) async {
    final results = <MapEntry<Content, DateTime>>[];
    final folderDir = Directory(folderPath);

    if (!await folderDir.exists()) return results;

    await for (final entity in folderDir.list()) {
      if (entity is Directory) {
        final contentId = path.basename(entity.path);
        final result =
            await _searchContentFolder(entity, contentId, queryLower);
        if (result != null) {
          results.add(result);
        }
      }
    }

    return results;
  }

  /// Helper to search a single content folder and return if it matches query
  Future<MapEntry<Content, DateTime>?> _searchContentFolder(
      FileSystemEntity entity, String contentId, String queryLower) async {
    try {
      // Search in content ID
      final contentIdMatch = contentId.toLowerCase().contains(queryLower);

      // Try to read title from metadata.json
      String title = contentId;
      bool titleMatch = false;
      String sourceId = 'offline'; // Default sourceId

      try {
        final metadataFile = File(path.join(entity.path, 'metadata.json'));
        Map<String, dynamic>? metadata;
        if (await metadataFile.exists()) {
          final metadataContent = await metadataFile.readAsString();
          metadata = json.decode(metadataContent) as Map<String, dynamic>;
          title = metadata['title'] ?? contentId;
          titleMatch = title.toLowerCase().contains(queryLower);
        }
        // Store metadata for later use
        sourceId = _extractSourceIdFromMetadataOrPath(metadata, entity.path);
      } catch (e) {
        _logger.w('Error reading metadata for search in $contentId: $e');
      }

      // If matches, load full content data
      if (!contentIdMatch && !titleMatch) {
        return null;
      }

      final imagesDir = Directory(path.join(entity.path, 'images'));
      List<File> imageFiles = [];

      if (await imagesDir.exists()) {
        imageFiles = await imagesDir
            .list(recursive: true)
            .where((f) => f is File && _isImageFile(f.path))
            .cast<File>()
            .toList();
      }

      // Fallback: check contentId directory directly
      if (imageFiles.isEmpty) {
        final contentEntities = await Directory(entity.path).list().toList();
        final directImageFiles = contentEntities
            .where((f) =>
                f is File &&
                _isImageFile(f.path) &&
                path.basename(f.path) != 'metadata.json')
            .cast<File>()
            .toList();
        if (directImageFiles.isNotEmpty) {
          imageFiles.addAll(directImageFiles);
        }
      }

      if (imageFiles.isEmpty) return null;

      // Sort images by page number
      imageFiles.sort((a, b) =>
          _extractPageNumber(a.path).compareTo(_extractPageNumber(b.path)));

      final imageUrls = imageFiles.map((f) => f.path).toList();

      // Create Content object
      String coverUrl = '';
      if (imageUrls.isNotEmpty) {
        final firstImageFile = File(imageUrls.first);
        if (await firstImageFile.exists() &&
            await firstImageFile.length() > 0) {
          coverUrl = imageUrls.first;
        } else if (imageUrls.length > 1) {
          final secondImageFile = File(imageUrls[1]);
          if (await secondImageFile.exists() &&
              await secondImageFile.length() > 0) {
            coverUrl = imageUrls[1];
          }
        }
      }

      final content = Content(
        sourceId: sourceId,
        id: contentId,
        title: title,
        coverUrl: coverUrl,
        tags: [],
        artists: [],
        characters: [],
        parodies: [],
        groups: [],
        language: '',
        pageCount: imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: DateTime.now(),
        favorites: 0,
        englishTitle: null,
        japaneseTitle: null,
      );

      // Get folder modification time
      final folderStat = await entity.stat();
      final modifiedTime = folderStat.modified;

      _logger.d(
          'Found matching content: $contentId - $title (${imageUrls.length} pages)');

      return MapEntry(content, modifiedTime);
    } catch (e) {
      return null;
    }
  }

  /// Scan backup folder for offline content without database dependency
  /// Supports both:
  /// - NEW: Source-based folders (nhasix/nhentai/{contentId}/, nhasix/crotpedia/{contentId}/)
  /// - LEGACY: Direct folders (nhasix/{contentId}/)
  Future<List<Content>> scanBackupFolder(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);

      if (!await backupDir.exists()) {
        _logger.w('Backup folder does not exist: $backupPath');
        return [];
      }

      final contents = <Content>[];
      final contentWithTimes = <MapEntry<Content, DateTime>>[];

      // Known source identifiers to check for nested structure
      const knownSources = ['nhentai', 'crotpedia'];

      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final folderName = path.basename(entity.path);

          // Check if this is a source folder (e.g., nhentai/, crotpedia/)
          if (knownSources.contains(folderName)) {
            // Scan content inside source folder
            _logger.d('Scanning source folder: $folderName');
            final sourceContents = await _scanContentFolder(entity.path);
            contentWithTimes.addAll(sourceContents);
          } else {
            // Could be legacy content folder, try to scan it directly
            final contentResult =
                await _tryParseContentFolder(entity, folderName);
            if (contentResult != null) {
              contentWithTimes.add(contentResult);
            }
          }
        }
      }

      // Sort by modification time descending (newest first)
      contentWithTimes.sort((a, b) => b.value.compareTo(a.value));
      contents.addAll(contentWithTimes.map((e) => e.key));

      _logger.i('Found ${contents.length} backup content items');
      return contents;
    } catch (e, stackTrace) {
      _logger.e('Error scanning backup folder: $backupPath',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Helper to scan a specific source folder (e.g. nhentai/) for content
  Future<List<MapEntry<Content, DateTime>>> _scanContentFolder(
      String folderPath) async {
    final folderDir = Directory(folderPath);
    final results = <MapEntry<Content, DateTime>>[];

    if (!await folderDir.exists()) return results;

    await for (final entity in folderDir.list()) {
      if (entity is Directory) {
        final contentId = path.basename(entity.path);

        // Check for v1 metadata in v2 structure and fix it
        try {
          final metadataFile = File(path.join(entity.path, 'metadata.json'));
          if (await metadataFile.exists()) {
            final content = await metadataFile.readAsString();
            if (!content.contains('schemaVersion')) {
              // Found v1 metadata in source folder - UPGRADE IT
              final jsonMap = jsonDecode(content) as Map<String, dynamic>;
              final sourceName = path.basename(folderPath); // e.g., 'nhentai'

              // Use proper migration constructor from ContentMetadata
              // Note: We need a temporary import or just manual map manipulation here
              // Since we can't easily import ContentMetadata here without circular deps if not already imported
              // We'll do manual map manipulation for safety

              final newMetadata = Map<String, dynamic>.from(jsonMap);
              newMetadata['schemaVersion'] = '2.0';
              newMetadata['source'] = sourceName;

              // Handle tags string to map conversion if needed
              if (newMetadata['tags'] is List &&
                  newMetadata['tags'].isNotEmpty &&
                  newMetadata['tags'][0] is String) {
                newMetadata['tags'] = (newMetadata['tags'] as List)
                    .map((t) => {
                          'name': t.toString(),
                          'type': 'tag',
                          'count': 0,
                          'url': ''
                        })
                    .toList();
              }

              await metadataFile.writeAsString(jsonEncode(newMetadata));
              _logger.i(
                  'Auto-upgraded metadata for $contentId to v2 in $sourceName folder');
            }
          }
        } catch (e) {
          _logger.w('Failed to check/upgrade metadata for $contentId: $e');
        }

        final contentResult = await _tryParseContentFolder(entity, contentId);
        if (contentResult != null) {
          results.add(contentResult);
        }
      }
    }
    return results;
  }

  /// Helper to try parse a directory as a content folder
  Future<MapEntry<Content, DateTime>?> _tryParseContentFolder(
      FileSystemEntity entity, String contentId) async {
    try {
      final imagesDir = Directory(path.join(entity.path, 'images'));
      List<File> imageFiles = [];

      if (await imagesDir.exists()) {
        try {
          final files = await imagesDir.list(recursive: true).toList();
          imageFiles = files
              .where((f) => f is File && _isImageFile(f.path))
              .cast<File>()
              .toList();
        } catch (e) {
          // ignore
        }
      }

      // Fallback: check contentId directory directly
      if (imageFiles.isEmpty) {
        try {
          final contentDir = Directory(entity.path);
          final contentEntities = await contentDir.list().toList();
          final directImageFiles = contentEntities
              .where((f) =>
                  f is File &&
                  _isImageFile(f.path) &&
                  path.basename(f.path) != 'metadata.json')
              .cast<File>()
              .toList();

          if (directImageFiles.isNotEmpty) {
            imageFiles.addAll(directImageFiles);
          }
        } catch (e) {
          // ignore
        }
      }

      if (imageFiles.isEmpty) return null;

      // Sort images by page number
      imageFiles.sort((a, b) =>
          _extractPageNumber(a.path).compareTo(_extractPageNumber(b.path)));

      final imageUrls = imageFiles.map((f) => f.path).toList();

      // Try to read title from metadata.json
      String title = contentId;
      Map<String, dynamic>? metadata;
      try {
        final metadataFile = File(path.join(entity.path, 'metadata.json'));
        if (await metadataFile.exists()) {
          final metadataContent = await metadataFile.readAsString();
          metadata = json.decode(metadataContent) as Map<String, dynamic>;
          title = metadata['title'] ?? contentId;
        }
      } catch (e) {
        _logger.w('Error reading metadata for $contentId: $e');
      }

      // Extract sourceId from metadata or path
      final sourceId =
          _extractSourceIdFromMetadataOrPath(metadata, entity.path);

      // Create Content object
      String coverUrl = '';
      if (imageUrls.isNotEmpty) {
        coverUrl = imageUrls.first;
      }

      final content = Content(
        sourceId: sourceId,
        id: contentId,
        title: title,
        coverUrl: coverUrl,
        tags: [],
        artists: [],
        characters: [],
        parodies: [],
        groups: [],
        language: '',
        pageCount: imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: DateTime.now(),
        favorites: 0,
        englishTitle: null,
        japaneseTitle: null,
      );

      // Get folder modification time
      final folderStat = await entity.stat();
      final modifiedTime = folderStat.modified;

      return MapEntry(content, modifiedTime);
    } catch (e) {
      return null;
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

  /// Helper method to extract content ID from image URL
  String? _extractContentIdFromUrl(String imageUrl) {
    try {
      // Try different URL patterns to extract content ID
      final uri = Uri.parse(imageUrl);

      // Special handling for nhentai URLs: https://i.nhentai.net/galleries/[contentId]/[page].jpg
      if (uri.host == 'i.nhentai.net' && uri.pathSegments.length >= 3) {
        if (uri.pathSegments[0] == 'galleries' &&
            uri.pathSegments.length >= 2) {
          final contentId = uri.pathSegments[1];
          if (RegExp(r'^\d+$').hasMatch(contentId)) {
            return contentId;
          }
        }
      }

      // Pattern 1: URL contains content ID in path segments
      // e.g., https://example.com/content/12345/page/1.jpg
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        // Look for numeric content ID
        for (final segment in pathSegments) {
          if (RegExp(r'^\d+$').hasMatch(segment)) {
            return segment;
          }
        }
      }

      // Pattern 2: Content ID in query parameters
      // e.g., https://example.com/image.jpg?contentId=12345
      final contentIdParam = uri.queryParameters['contentId'];
      if (contentIdParam != null && contentIdParam.isNotEmpty) {
        return contentIdParam;
      }

      // Pattern 3: Content ID in hostname or subdomain
      // e.g., https://12345.example.com/image.jpg
      final hostParts = uri.host.split('.');
      for (final part in hostParts) {
        if (RegExp(r'^\d+$').hasMatch(part)) {
          return part;
        }
      }

      // Pattern 4: Extract from filename if it contains content ID
      // e.g., https://example.com/12345_001.jpg
      final filename = path.basenameWithoutExtension(uri.path);
      final filenameMatch = RegExp(r'^(\d+)').firstMatch(filename);
      if (filenameMatch != null) {
        return filenameMatch.group(1);
      }

      return null;
    } catch (e) {
      _logger.w('Error extracting content ID from URL: $imageUrl, error: $e');
      return null;
    }
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

  /// Clear all caches
  void clearCache() {
    _cachedOfflineIds = null;
    _offlineIdsCacheTime = null;
    _metadataCache.clear();
    _metadataCacheTime.clear();
    _logger.d('Offline content cache cleared');
  }

  /// Clear cache for specific content ID
  void clearContentCache(String contentId) {
    _metadataCache.remove(contentId);
    _metadataCacheTime.remove(contentId);
    _logger.d('Cache cleared for content: $contentId');
  }

  /// Smart Downloads directory detection
  /// Tries multiple possible Downloads folder names and locations
  Future<String> _getDownloadsDirectory() async {
    try {
      // First, try to get external storage directory
      Directory? externalDir;
      try {
        externalDir = await getExternalStorageDirectory();
      } catch (e) {
        _logger.w('Could not get external storage directory: $e');
      }

      if (externalDir != null) {
        // Try to find Downloads folder in external storage root
        final externalRoot = externalDir.path.split('/Android')[0];

        // Common Downloads folder names (English, Indonesian, Spanish, etc.)
        final downloadsFolderNames = [
          'Download', // English (most common)
          'Downloads', // English alternative
          'Unduhan', // Indonesian
          'Descargas', // Spanish
          'Téléchargements', // French
          'Downloads', // German uses English
          'ダウンロード', // Japanese
        ];

        // Try each possible Downloads folder
        for (final folderName in downloadsFolderNames) {
          final downloadsDir = Directory(path.join(externalRoot, folderName));
          if (await downloadsDir.exists()) {
            // _logger.i('Found Downloads directory: ${downloadsDir.path}');
            return downloadsDir.path;
          }
        }

        // If no Downloads folder found, create one in external storage root
        final defaultDownloadsDir =
            Directory(path.join(externalRoot, 'Download'));
        try {
          if (!await defaultDownloadsDir.exists()) {
            await defaultDownloadsDir.create(recursive: true);
            _logger
                .i('Created Downloads directory: ${defaultDownloadsDir.path}');
          }
          return defaultDownloadsDir.path;
        } catch (e) {
          _logger.w(
              'Could not create Downloads directory in external storage: $e');
        }
      }

      // Fallback 1: Try hardcoded common paths
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/emulated/0/Unduhan',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (final commonPath in commonPaths) {
        final dir = Directory(commonPath);
        if (await dir.exists()) {
          _logger.i('Found Downloads directory at common path: $commonPath');
          return commonPath;
        }
      }

      // Fallback 2: Use app-specific external storage
      if (externalDir != null) {
        final appDownloadsDir =
            Directory(path.join(externalDir.path, 'downloads'));
        if (!await appDownloadsDir.exists()) {
          await appDownloadsDir.create(recursive: true);
        }
        _logger.i(
            'Using app-specific downloads directory: ${appDownloadsDir.path}');
        return appDownloadsDir.path;
      }

      // Fallback 3: Use application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsDownloadsDir =
          Directory(path.join(documentsDir.path, 'downloads'));
      if (!await documentsDownloadsDir.exists()) {
        await documentsDownloadsDir.create(recursive: true);
      }
      _logger.i(
          'Using app documents downloads directory: ${documentsDownloadsDir.path}');
      return documentsDownloadsDir.path;
    } catch (e) {
      _logger.e('Error detecting Downloads directory: $e');

      // Emergency fallback: use app documents
      final documentsDir = await getApplicationDocumentsDirectory();
      final emergencyDir = Directory(path.join(documentsDir.path, 'downloads'));
      if (!await emergencyDir.exists()) {
        await emergencyDir.create(recursive: true);
      }
      _logger.w('Using emergency fallback directory: ${emergencyDir.path}');
      return emergencyDir.path;
    }
  }

  /// Sync backup folder content to database
  /// Returns map with 'synced' (new items) and 'updated' (fixed paths) counts
  Future<Map<String, int>> syncBackupToDatabase(String backupPath) async {
    // NEW: Auto-migrate legacy content before scanning
    try {
      final backupDir = Directory(backupPath);
      if (await backupDir.exists()) {
        await for (final entity in backupDir.list()) {
          if (entity is Directory) {
            final folderName = path.basename(entity.path);
            if (!AppStorage.knownSources.contains(folderName)) {
              // Potential legacy content - attempt migration
              // This moves nhasix/{id} -> nhasix/nhentai/{id}
              final migrated = await DownloadStorageUtils.migrateToSourceFolder(
                folderName,
                sourceId:
                    AppStorage.defaultSourceId, // Default for legacy content
              );
              if (migrated) {
                _logger.i(
                    'Auto-migrated legacy content $folderName to nhentai source');
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.w('Auto-migration check failed: $e');
    }

    final contents = await scanBackupFolder(backupPath);
    int syncedCount = 0;
    int updatedCount = 0;

    for (final content in contents) {
      final existing = await _userDataRepository.getDownloadStatus(content.id);

      // Use derived content path from entity (replaces duplicated logic)
      final contentDir = content.derivedContentPath;
      int fileSize = 0;
      if (content.imageUrls.isNotEmpty) {
        for (final imgPath in content.imageUrls) {
          final file = File(imgPath);
          if (await file.exists()) fileSize += await file.length();
        }
      }

      if (existing == null) {
        // NEW: ID not in database - create entry
        final status = DownloadStatus.completed(
          content.id,
          content.pageCount,
          contentDir ?? '',
          fileSize,
          title: content.title,
          sourceId: content.sourceId,
          coverUrl: content.coverUrl,
        );
        await _userDataRepository.saveDownloadStatus(status);
        syncedCount++;
        _logger.i('Synced new content: ${content.id}');
      } else if (existing.downloadPath != null) {
        // DUPLICATE/EXISTING: Check for updates or path fixes
        final existingDir = Directory(existing.downloadPath!);
        bool needsUpdate = false;
        var updatedStatus = existing;

        // Check 1: Path broken?
        if (!await existingDir.exists() && contentDir != null) {
          updatedStatus = updatedStatus.copyWith(downloadPath: contentDir);
          needsUpdate = true;
          _logger.i('Updated broken path for: ${content.id}');
        }

        // Check 2: Missing Metadata? (Title/SourceId/CoverUrl)
        if ((existing.title == null || existing.title!.isEmpty) &&
            content.title.isNotEmpty) {
          updatedStatus = updatedStatus.copyWith(title: content.title);
          needsUpdate = true;
        }

        if ((existing.sourceId == null ||
                existing.sourceId!.isEmpty ||
                existing.sourceId == 'nhentai') &&
            content.sourceId.isNotEmpty &&
            content.sourceId != 'nhentai') {
          updatedStatus = updatedStatus.copyWith(sourceId: content.sourceId);
          needsUpdate = true;
        }

        if ((existing.coverUrl == null || existing.coverUrl!.isEmpty) &&
            content.coverUrl.isNotEmpty) {
          updatedStatus = updatedStatus.copyWith(coverUrl: content.coverUrl);
          needsUpdate = true;
        }

        if (needsUpdate) {
          await _userDataRepository.saveDownloadStatus(updatedStatus);
          updatedCount++;
          _logger.i('Updated existing entry metadata/path for: ${content.id}');
        }
      }
    }

    _logger.i('Sync complete: $syncedCount new, $updatedCount updated');
    return {'synced': syncedCount, 'updated': updatedCount};
  }

  /// Delete offline content and free up storage
  /// [contentPath] - optional direct path to content directory (for backup items)
  /// Returns true if deletion was successful (idempotent - returns true if either DB or filesystem deleted)
  Future<bool> deleteOfflineContent(String contentId,
      {String? contentPath}) async {
    try {
      _logger.i('Deleting offline content: $contentId');

      // Use provided path or try to find it
      String? pathToDelete = contentPath;
      pathToDelete ??= await getOfflineContentPath(contentId);

      // NEW: If path still not found, try filesystem scan as fallback
      if (pathToDelete == null) {
        _logger.i('Path not in DB, scanning filesystem for $contentId');
        pathToDelete = await _findContentInFilesystem(contentId);
      }

      bool filesystemDeleted = false;
      bool dbDeleted = false;

      // Delete filesystem if path found
      if (pathToDelete != null) {
        final contentDir = Directory(pathToDelete);
        if (await contentDir.exists()) {
          await contentDir.delete(recursive: true);
          _logger.i('Deleted content directory: $pathToDelete');
          filesystemDeleted = true;
        } else {
          _logger.w('Content directory does not exist: $pathToDelete');
        }
      }

      // Remove from metadata cache
      _metadataCache.remove(contentId);
      _metadataCacheTime.remove(contentId);

      // Clear offline IDs cache to force refresh
      _cachedOfflineIds = null;
      _offlineIdsCacheTime = null;

      // Delete from database - this is critical for sync
      try {
        await _userDataRepository.deleteDownloadStatus(contentId);
        _logger.i('Removed download status from DB for $contentId');
        dbDeleted = true;
      } catch (e) {
        _logger.e('CRITICAL: Failed to remove download status from DB: $e');
        // Even if filesystem was deleted, we need DB to be cleaned too
        // Log but continue - at least filesystem is cleaned
      }

      // Return true if at least one operation succeeded (idempotent behavior)
      final success = filesystemDeleted || dbDeleted;
      if (!success) {
        _logger.w(
            'Delete failed: content $contentId not found in filesystem or DB');
      }
      return success;
    } catch (e, stackTrace) {
      _logger.e('Error deleting offline content for $contentId',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get localized string with fallback
  String _getLocalized(String key,
      {Map<String, dynamic>? args, String? fallback}) {
    try {
      return _localize?.call(key, args: args) ?? fallback ?? key;
    } catch (e) {
      _logger.w('Failed to get localized string for key: $key, error: $e');
      return fallback ?? key;
    }
  }
}
