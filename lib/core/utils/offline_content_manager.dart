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
      // _logger.i(_getLocalized('offlineContentPath',
      //   args: {'contentId': contentId, 'path': downloadStatus?.downloadPath ?? 'null'},
      //   fallback: "Location: path: ${downloadStatus?.downloadPath}"));
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

  /// Create offline content object from metadata
  Future<Content?> createOfflineContent(String contentId) async {
    try {
      final metadata = await getOfflineContentMetadata(contentId);
      if (metadata == null) return null;

      final imageUrls = await getOfflineImageUrls(contentId);
      _logger.i(_getLocalized('offlineImageUrlsFound',
          args: {'contentId': contentId, 'count': imageUrls.length},
          fallback: "apakah ada gambarnya? ${imageUrls.isEmpty}"));
      if (imageUrls.isEmpty) return null;

      // Ensure first page image exists and is valid
      String coverUrl = '';
      if (imageUrls.isNotEmpty) {
        final firstImagePath = imageUrls.first;
        final firstImageFile = File(firstImagePath);
        if (await firstImageFile.exists() &&
            await firstImageFile.length() > 0) {
          coverUrl = firstImagePath;
        } else {
          // Try second image if first is invalid
          if (imageUrls.length > 1) {
            final secondImagePath = imageUrls[1];
            final secondImageFile = File(secondImagePath);
            if (await secondImageFile.exists() &&
                await secondImageFile.length() > 0) {
              coverUrl = secondImagePath;
            }
          }
        }
      }

      return Content(
        id: contentId,
        title: metadata['title'] as String,
        coverUrl: coverUrl,
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

  /// Get all offline content from file system without database
  Future<List<Content>> getAllOfflineContentFromFileSystem(
      String backupPath) async {
    return await scanBackupFolder(backupPath);
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

                matchingContents.add(content);
                _logger.d(
                    'Found matching content: $contentId - $title (${imageUrls.length} pages)');
              }
            }
          }
        }
      }

      // Sort by content ID
      matchingContents.sort((a, b) => a.id.compareTo(b.id));

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

              contents.add(content);
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

      // Sort by content ID (assuming it's numeric)
      contents.sort((a, b) => a.id.compareTo(b.id));

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
