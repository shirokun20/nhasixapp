import 'dart:io';
import 'dart:convert';
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

      _logger.w('No offline content path found for $contentId');
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error getting offline content path for $contentId',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all possible download paths for a content ID
  Future<List<String>> _getPossibleDownloadPaths(String contentId) async {
    final paths = <String>[];

    try {
      // Try the smart detection first
      final downloadsPath = await _getDownloadsDirectory();
      paths.add(path.join(downloadsPath, 'nhasix', contentId));

      // Try app documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      paths.add(path.join(documentsDir.path, 'downloads', 'nhasix', contentId));

      // Try external storage directory directly
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final externalRoot = externalDir.path.split('/Android')[0];
          // Try common download folder names
          final folderNames = ['Download', 'Downloads', 'Unduhan', 'Descargas'];
          for (final folderName in folderNames) {
            paths.add(path.join(externalRoot, folderName, 'nhasix', contentId));
          }
        }
      } catch (e) {
        _logger.w('Failed to get external storage paths: $e');
      }

      // Try hardcoded paths
      final hardcodedPaths = [
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
        limit: 1000, // Get all completed downloads
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
      // Check cache first
      if (_metadataCache.containsKey(contentId) &&
          _metadataCacheTime.containsKey(contentId) &&
          DateTime.now().difference(_metadataCacheTime[contentId]!) <
              _metadataCacheDuration) {
        _logger.d('Using cached metadata for $contentId');
        return _metadataCache[contentId];
      }

      // Try to get from favorites first
      final favorites = await _userDataRepository.getFavorites(limit: 1000);
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

      // Fallback to basic info
      final metadata = {
        'id': contentId,
        'title': 'Offline Content $contentId',
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
      try {
        final metadataFile = File(path.join(contentPath, 'metadata.json'));
        if (await metadataFile.exists()) {
          final metadataContent = await metadataFile.readAsString();
          final metadata = json.decode(metadataContent) as Map<String, dynamic>;
          title = metadata['title'] ?? contentId;
        }
      } catch (e) {
        _logger.w('Error reading metadata for $contentId: $e');
      }

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
  Future<List<Content>> searchOfflineContentFromFileSystem(
      String backupPath, String query) async {
    try {
      final backupDir = Directory(backupPath);

      if (!await backupDir.exists()) {
        _logger.w('Backup folder does not exist: $backupPath');
        return [];
      }

      final matchingContents = <Content>[];
      final matchingWithTimes = <MapEntry<Content, DateTime>>[];
      final queryLower = query.toLowerCase();

      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final contentId = path.basename(entity.path);

          // Search in content ID
          final contentIdMatch = contentId.toLowerCase().contains(queryLower);

          // Try to read title from metadata.json
          String title = contentId;
          bool titleMatch = false;

          try {
            final metadataFile = File(path.join(entity.path, 'metadata.json'));
            if (await metadataFile.exists()) {
              final metadataContent = await metadataFile.readAsString();
              final metadata =
                  json.decode(metadataContent) as Map<String, dynamic>;
              title = metadata['title'] ?? contentId;
              titleMatch = title.toLowerCase().contains(queryLower);
            }
          } catch (e) {
            _logger.w('Error reading metadata for search in $contentId: $e');
          }

          // If matches, load full content data
          if (contentIdMatch || titleMatch) {
            final imagesDir = Directory(path.join(entity.path, 'images'));

            if (await imagesDir.exists()) {
              final imageFiles = await imagesDir
                  .list(recursive: true)
                  .where((f) => f is File && _isImageFile(f.path))
                  .cast<File>()
                  .toList();

              // Fallback: check contentId directory directly
              if (imageFiles.isEmpty) {
                final contentEntities = await entity.list().toList();
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

              if (imageFiles.isNotEmpty) {
                // Sort images by page number
                imageFiles.sort((a, b) => _extractPageNumber(a.path)
                    .compareTo(_extractPageNumber(b.path)));

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

                matchingWithTimes.add(MapEntry(content, modifiedTime));

                _logger.d(
                    'Found matching content: $contentId - $title (${imageUrls.length} pages)');
              }
            }
          }
        }
      }

      // Sort by modification time descending (newest first)
      matchingWithTimes.sort((a, b) => b.value.compareTo(a.value));
      matchingContents.addAll(matchingWithTimes.map((e) => e.key));

      _logger.i(
          'Found ${matchingContents.length} matching content items for query: $query');
      return matchingContents;
    } catch (e, stackTrace) {
      _logger.e('Error searching offline content from file system',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Scan backup folder for offline content without database dependency
  Future<List<Content>> scanBackupFolder(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);

      if (!await backupDir.exists()) {
        _logger.w('Backup folder does not exist: $backupPath');
        return [];
      }

      final contents = <Content>[];
      final contentWithTimes = <MapEntry<Content, DateTime>>[];

      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final contentId = path.basename(entity.path);

          final imagesDir = Directory(path.join(entity.path, 'images'));
          // debugPrint(
          //     'OFFLINE_MANAGER: Looking for images dir: ${imagesDir.path}');

          if (await imagesDir.exists()) {
            // debugPrint(
            //     'OFFLINE_MANAGER: Images directory exists for $contentId');

            // Log all entities in images directory for debugging
            try {
              await imagesDir.list().toList();
            } catch (e) {
              // debugPrint(
              //     'OFFLINE_MANAGER: Error listing entities in images dir for $contentId: $e');
            }

            final imageFiles = await imagesDir
                .list(recursive: true)
                .where((f) => f is File && _isImageFile(f.path))
                .cast<File>()
                .toList();

            // debugPrint(
            //     'OFFLINE_MANAGER: Found ${imageFiles.length} image files in $contentId');

            // Fallback: if no images found in images/ directory, check contentId directory directly
            if (imageFiles.isEmpty) {
              // debugPrint(
              //     'OFFLINE_MANAGER: No images in images/ subdirectory, checking contentId directory directly for $contentId');
              try {
                final contentEntities = await entity.list().toList();
                final directImageFiles = contentEntities
                    .where((f) =>
                        f is File &&
                        _isImageFile(f.path) &&
                        path.basename(f.path) != 'metadata.json')
                    .cast<File>()
                    .toList();
                if (directImageFiles.isNotEmpty) {
                  // debugPrint(
                  //     'OFFLINE_MANAGER: Found ${directImageFiles.length} image files directly in contentId for $contentId');
                  imageFiles.addAll(directImageFiles);
                } else {
                  // debugPrint(
                  //     'OFFLINE_MANAGER: No image files found directly in contentId for $contentId');
                }
              } catch (e) {
                // debugPrint(
                //     'OFFLINE_MANAGER: Error listing contentId directory for $contentId: $e');
              }
            }

            if (imageFiles.isNotEmpty) {
              // Sort images by page number
              imageFiles.sort((a, b) => _extractPageNumber(a.path)
                  .compareTo(_extractPageNumber(b.path)));

              final imageUrls = imageFiles.map((f) => f.path).toList();
              // debugPrint(
              //     'OFFLINE_MANAGER: Image URLs for $contentId: $imageUrls');

              // Try to read title from metadata.json
              String title = contentId; // fallback to folder name
              try {
                final metadataFile =
                    File(path.join(entity.path, 'metadata.json'));
                // debugPrint(
                //     'OFFLINE_MANAGER: Looking for metadata file: ${metadataFile.path}');
                if (await metadataFile.exists()) {
                  final metadataContent = await metadataFile.readAsString();
                  final metadata =
                      json.decode(metadataContent) as Map<String, dynamic>;
                  title = metadata['title'] ?? contentId;
                  // debugPrint(
                  //     'OFFLINE_MANAGER: Found title from metadata for $contentId: $title');
                  _logger.d('Found title from metadata for $contentId: $title');
                } else {
                  // debugPrint(
                  //     'OFFLINE_MANAGER: No metadata.json found for $contentId, using folder name as title');
                  _logger.d(
                      'No metadata.json found for $contentId, using folder name as title');
                }
              } catch (e) {
                // debugPrint(
                //     'OFFLINE_MANAGER: Error reading metadata for $contentId: $e');
                _logger.w(
                    'Error reading metadata for $contentId: $e, using folder name');
              }

              // Create Content object
              String coverUrl = '';
              if (imageUrls.isNotEmpty) {
                final firstImageFile = File(imageUrls.first);
                if (await firstImageFile.exists() &&
                    await firstImageFile.length() > 0) {
                  coverUrl = imageUrls.first;
                  // debugPrint(
                  //     'OFFLINE_MANAGER: Using first image as cover for $contentId: $coverUrl');
                } else if (imageUrls.length > 1) {
                  final secondImageFile = File(imageUrls[1]);
                  if (await secondImageFile.exists() &&
                      await secondImageFile.length() > 0) {
                    coverUrl = imageUrls[1];
                    // debugPrint(
                    //         'OFFLINE_MANAGER: Using second image as cover for $contentId: $coverUrl');
                  }
                }
              }

              final content = Content(
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

              contentWithTimes.add(MapEntry(content, modifiedTime));

              // debugPrint(
              //     'OFFLINE_MANAGER: Added backup content: $contentId - $title (${imageUrls.length} pages)');
              _logger.d(
                  'Added backup content: $contentId - $title (${imageUrls.length} pages)');
            } else {
              // debugPrint(
              //     'OFFLINE_MANAGER: No image files found in images directory for $contentId');
            }
          } else {
            // debugPrint(
            //     'OFFLINE_MANAGER: Images directory does not exist for $contentId');
          }
        } else {
          // debugPrint(
          //     'OFFLINE_MANAGER: Entity is not a directory: ${entity.path}');
        }
      }

      // Sort by modification time descending (newest first)
      contentWithTimes.sort((a, b) => b.value.compareTo(a.value));
      contents.addAll(contentWithTimes.map((e) => e.key));

      // debugPrint(
      //     'OFFLINE_MANAGER: Found ${contents.length} backup content items total');
      _logger.i('Found ${contents.length} backup content items');
      return contents;
    } catch (e, stackTrace) {
      // debugPrint(
      //     'OFFLINE_MANAGER: Error scanning backup folder: $backupPath - $e');
      _logger.e('Error scanning backup folder: $backupPath',
          error: e, stackTrace: stackTrace);
      return [];
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
            _logger.i('Found Downloads directory: ${downloadsDir.path}');
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
    final contents = await scanBackupFolder(backupPath);
    int syncedCount = 0;
    int updatedCount = 0;

    for (final content in contents) {
      final existing = await _userDataRepository.getDownloadStatus(content.id);

      // Extract content directory from image URLs
      String? contentDir;
      int fileSize = 0;
      if (content.imageUrls.isNotEmpty) {
        final imagePath = content.imageUrls.first;
        var parentDir = File(imagePath).parent;
        contentDir = path.basename(parentDir.path) == 'images'
            ? parentDir.parent.path
            : parentDir.path;
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
        );
        await _userDataRepository.saveDownloadStatus(status);
        syncedCount++;
        _logger.i('Synced new content: ${content.id}');
      } else if (existing.downloadPath != null) {
        // DUPLICATE: Check if existing path still valid
        final existingDir = Directory(existing.downloadPath!);
        if (!await existingDir.exists() && contentDir != null) {
          // Path broken - update with backup path
          await _userDataRepository.saveDownloadStatus(
            existing.copyWith(downloadPath: contentDir),
          );
          updatedCount++;
          _logger.i('Updated broken path for: ${content.id}');
        }
        // else: valid existing entry - skip
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

      // Update download status to removed
      try {
        await _userDataRepository.deleteDownloadStatus(contentId);
        _logger.i('Removed download status for $contentId');
        dbDeleted = true;
      } catch (e) {
        _logger.w('Failed to remove download status: $e');
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
