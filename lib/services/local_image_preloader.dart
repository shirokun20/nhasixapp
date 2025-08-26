import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Enhanced Local Image Preloader Service
/// 
/// Provides progressive image loading with priority:
/// 1. Downloaded content (`nhasix/[id]/images/`)
/// 2. Local cache
/// 3. Network fallback
/// 
/// Supports metadata.json validation for downloaded content
class LocalImagePreloader {
  static const String _baseLocalPath = 'nhasix';
  static const String _cacheSubPath = 'cache';
  static const Duration _cacheExpiryDuration = Duration(hours: 6); // Cache expires in 6 hours
  static final Logger _logger = Logger();

  /// Get all possible base paths where images might be stored
  /// Priority: External Download -> Internal Cache (with expiry) -> Internal App Documents
  static Future<List<String>> _getPossibleBasePaths() async {
    final List<String> basePaths = [];
    
    try {
      // Priority 1: External storage Download folder (permanently downloaded files)
      final downloadPaths = await _getDownloadDirectories();
      for (final downloadPath in downloadPaths) {
        final downloadDir = Directory(path.join(downloadPath, _baseLocalPath));
        if (await downloadDir.exists()) {
          basePaths.add(path.join(downloadPath, _baseLocalPath));
          _logger.d('🐛 Found external storage: ${path.join(downloadPath, _baseLocalPath)}');
        }
      }
      
      // Priority 2: Internal cache directory (temporary files with expiry)
      final cacheDir = await _getInternalCacheDirectory();
      if (cacheDir != null) {
        basePaths.add(cacheDir);
        _logger.d('🐛 Added internal cache: $cacheDir');
        
        // Trigger cache cleanup in background
        _cleanupExpiredCache();
      }
      
      // Priority 3: Internal app documents directory (fallback storage)
      final appDir = await getApplicationDocumentsDirectory();
      final internalPath = path.join(appDir.path, _baseLocalPath);
      basePaths.add(internalPath);
      _logger.d('🐛 Added internal storage: $internalPath');
      
    } catch (e) {
      _logger.e('Error getting possible base paths: $e');
      // Fallback to internal storage only
      final appDir = await getApplicationDocumentsDirectory();
      basePaths.add(path.join(appDir.path, _baseLocalPath));
    }
    
    return basePaths;
  }

  /// Get Downloads directories using smart detection similar to download_service.dart
  /// Reference implementation from download_service.dart _getDownloadsDirectory()
  static Future<List<String>> _getDownloadDirectories() async {
    final List<String> downloadPaths = [];
    
    try {
      // Get external storage directory first
      Directory? externalDir;
      try {
        externalDir = await getExternalStorageDirectory();
      } catch (e) {
        _logger.w('Could not get external storage directory: $e');
      }

      if (externalDir != null) {
        // Try to find Downloads folder in external storage root
        final externalRoot = externalDir.path.split('/Android')[0];
        
        // Common Downloads folder names (same as download_service.dart)
        final downloadsFolderNames = [
          'Download',     // English (most common)
          'Downloads',    // English alternative
          'Unduhan',      // Indonesian
          'Descargas',    // Spanish
          'Téléchargements', // French
          'Downloads',    // German uses English
          'ダウンロード',     // Japanese
        ];

        // Try each possible Downloads folder
        for (final folderName in downloadsFolderNames) {
          final downloadsDir = Directory(path.join(externalRoot, folderName));
          if (await downloadsDir.exists()) {
            downloadPaths.add(downloadsDir.path);
            _logger.d('🐛 Found Downloads directory: ${downloadsDir.path}');
          }
        }
      }

      // Fallback: Try hardcoded common paths
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/emulated/0/Unduhan',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (final commonPath in commonPaths) {
        final dir = Directory(commonPath);
        if (await dir.exists() && !downloadPaths.contains(commonPath)) {
          downloadPaths.add(commonPath);
          _logger.d('🐛 Found Downloads directory at common path: $commonPath');
        }
      }
      
    } catch (e) {
      _logger.e('Error detecting Downloads directories: $e');
    }
    
    return downloadPaths;
  }

  /// Get internal cache directory for temporary image storage
  /// Files here expire after _cacheExpiryDuration and can be auto-cleaned
  static Future<String?> _getInternalCacheDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(appDir.path, _cacheSubPath, _baseLocalPath));
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
        _logger.d('🐛 Created internal cache directory: ${cacheDir.path}');
      }
      
      return cacheDir.path;
    } catch (e) {
      _logger.e('Error getting internal cache directory: $e');
      return null;
    }
  }

  /// Clean up expired cache files in background
  static Future<void> _cleanupExpiredCache() async {
    try {
      final cacheDir = await _getInternalCacheDirectory();
      if (cacheDir == null) return;
      
      final baseCacheDir = Directory(cacheDir);
      if (!await baseCacheDir.exists()) return;

      final now = DateTime.now();
      int cleanedFiles = 0;
      int cleanedDirs = 0;

      // Process each content directory in cache
      await for (final entity in baseCacheDir.list()) {
        if (entity is Directory) {
          final contentId = path.basename(entity.path);
          final cacheMetadataFile = File(path.join(entity.path, 'cache_metadata.json'));
          
          bool shouldDelete = false;
          
          if (await cacheMetadataFile.exists()) {
            try {
              final metadataContent = await cacheMetadataFile.readAsString();
              final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;
              final cacheTime = DateTime.parse(metadata['cached_at'] as String);
              
              if (now.difference(cacheTime) > _cacheExpiryDuration) {
                shouldDelete = true;
                _logger.d('🐛 Cache expired for $contentId: ${now.difference(cacheTime)} > $_cacheExpiryDuration');
              }
            } catch (e) {
              // Invalid metadata, delete the cache
              shouldDelete = true;
              _logger.w('🐛 Invalid cache metadata for $contentId, marking for deletion: $e');
            }
          } else {
            // No metadata, check file modification time
            final imagesDir = Directory(path.join(entity.path, 'images'));
            if (await imagesDir.exists()) {
              final stat = await imagesDir.stat();
              if (now.difference(stat.modified) > _cacheExpiryDuration) {
                shouldDelete = true;
                _logger.d('🐛 Cache expired by file time for $contentId: ${now.difference(stat.modified)} > $_cacheExpiryDuration');
              }
            }
          }
          
          if (shouldDelete) {
            try {
              await entity.delete(recursive: true);
              cleanedDirs++;
              _logger.d('🐛 Cleaned expired cache directory: ${entity.path}');
            } catch (e) {
              _logger.w('🐛 Failed to delete expired cache directory ${entity.path}: $e');
            }
          }
        } else if (entity is File) {
          // Clean up loose files that might be expired
          final stat = await entity.stat();
          if (now.difference(stat.modified) > _cacheExpiryDuration) {
            try {
              await entity.delete();
              cleanedFiles++;
              _logger.d('🐛 Cleaned expired cache file: ${entity.path}');
            } catch (e) {
              _logger.w('🐛 Failed to delete expired cache file ${entity.path}: $e');
            }
          }
        }
      }
      
      if (cleanedFiles > 0 || cleanedDirs > 0) {
        _logger.i('🐛 Cache cleanup completed: $cleanedFiles files, $cleanedDirs directories removed');
      }
      
    } catch (e) {
      _logger.e('Error during cache cleanup: $e');
    }
  }

  /// Save image to internal cache with metadata
  static Future<String?> _saveToInternalCache(String contentId, int pageNumber, List<int> imageBytes) async {
    try {
      final cacheDir = await _getInternalCacheDirectory();
      if (cacheDir == null) return null;
      
      final contentCacheDir = Directory(path.join(cacheDir, contentId, 'images'));
      if (!await contentCacheDir.exists()) {
        await contentCacheDir.create(recursive: true);
      }
      
      final fileName = 'page_${pageNumber.toString().padLeft(3, '0')}.jpg';
      final filePath = path.join(contentCacheDir.path, fileName);
      final file = File(filePath);
      
      await file.writeAsBytes(imageBytes);
      
      // Save cache metadata
      final metadataFile = File(path.join(contentCacheDir.parent.path, 'cache_metadata.json'));
      final metadata = {
        'content_id': contentId,
        'cached_at': DateTime.now().toIso8601String(),
        'expiry_hours': _cacheExpiryDuration.inHours,
      };
      await metadataFile.writeAsString(jsonEncode(metadata));
      
      _logger.d('🐛 Saved image to cache: $filePath');
      return filePath;
      
    } catch (e) {
      _logger.e('Error saving image to cache: $e');
      return null;
    }
  }

  /// Check if content is downloaded with metadata validation
  static Future<bool> isContentDownloaded(String contentId) async {
    try {
      final basePaths = await _getPossibleBasePaths();
      
      for (final basePath in basePaths) {
        final metadataPath = path.join(basePath, contentId, 'metadata.json');
        final metadataFile = File(metadataPath);
        
        if (await metadataFile.exists()) {
          _logger.d('Found metadata at: $metadataPath');
          return true;
        }
        
        // Also check if images directory exists (even without metadata)
        final imagesDir = Directory(path.join(basePath, contentId, 'images'));
        if (await imagesDir.exists()) {
          final files = await imagesDir.list().toList();
          final imageFiles = files.where((file) => file is File && _isImageFile(file.path)).toList();
          if (imageFiles.isNotEmpty) {
            _logger.d('Found images directory at: ${imagesDir.path} with ${imageFiles.length} images');
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      _logger.e('Error checking if content is downloaded for $contentId: $e');
      return false;
    }
  }

  /// Get local image path with priority: downloaded > internal cache > network cache > null
  static Future<String?> getLocalImagePath(String contentId, int pageNumber) async {
    try {
      final basePaths = await _getPossibleBasePaths();
      
      // Check all possible base paths for downloaded content
      for (final basePath in basePaths) {
        // Priority 1: Downloaded content with standard naming
        final downloadedPath = path.join(
          basePath, 
          contentId, 
          'images', 
          'page_$pageNumber.jpg'
        );
        final downloadedFile = File(downloadedPath);
        if (await downloadedFile.exists()) {
          _logger.d('🐛 Found downloaded image: $downloadedPath');
          return downloadedPath;
        }

        // Alternative naming patterns for downloaded content
        final altPatterns = [
          'page_${pageNumber.toString().padLeft(3, '0')}.jpg',
          '${pageNumber.toString().padLeft(3, '0')}.jpg',
          '$pageNumber.jpg',
          'image_$pageNumber.jpg',
        ];

        for (final pattern in altPatterns) {
          final altPath = path.join(basePath, contentId, 'images', pattern);
          final altFile = File(altPath);
          if (await altFile.exists()) {
            _logger.d('🐛 Found downloaded image with alt pattern: $altPath');
            return altPath;
          }
        }

        // Priority 2: Check if file exists in images folder (scan directory)
        final imagesDir = Directory(path.join(basePath, contentId, 'images'));
        if (await imagesDir.exists()) {
          final files = await imagesDir.list().toList();
          final imageFiles = files
              .where((file) => file is File && _isImageFile(file.path))
              .cast<File>()
              .toList();

          // Sort by filename to maintain page order
          imageFiles.sort((a, b) => _extractPageNumber(a.path).compareTo(_extractPageNumber(b.path)));

          // Return the image for the requested page number (1-indexed)
          if (pageNumber > 0 && pageNumber <= imageFiles.length) {
            final targetFile = imageFiles[pageNumber - 1];
            _logger.d('🐛 Found image by directory scan: ${targetFile.path}');
            return targetFile.path;
          }
        }
      }

      // Priority 3: Check CachedNetworkImage cache (legacy cache system)
      final cachePath = await _getCachedImagePath(contentId, pageNumber);
      if (cachePath != null && await File(cachePath).exists()) {
        _logger.d('🐛 Found legacy cached image: $cachePath');
        return cachePath;
      }

      return null; // Fallback to network
    } catch (e) {
      _logger.e('Error getting local image path for $contentId page $pageNumber: $e');
      return null;
    }
  }

  /// Get local thumbnail/cover path with priority: downloads > internal cache > legacy cache
  static Future<String?> getLocalThumbnailPath(String contentId) async {
    try {
      final basePaths = await _getPossibleBasePaths();
      
      // Check downloaded cover patterns in all base paths
      final downloadedCoverPatterns = [
        'cover.jpg',
        'thumbnail.jpg',
        'thumb.jpg',
        '1.jpg', // First page as cover
        'page_1.jpg',
        'page_001.jpg',
      ];

      for (final basePath in basePaths) {
        for (final pattern in downloadedCoverPatterns) {
          final coverPath = path.join(basePath, contentId, pattern);
          if (await File(coverPath).exists()) {
            _logger.d('🐛 Found downloaded cover: $coverPath');
            return coverPath;
          }

          // Also check in images folder
          final coverInImagesPath = path.join(basePath, contentId, 'images', pattern);
          if (await File(coverInImagesPath).exists()) {
            _logger.d('🐛 Found downloaded cover in images folder: $coverInImagesPath');
            return coverInImagesPath;
          }
        }
      }

      // Check legacy cached thumbnail
      final cachedCover = await _getCachedThumbnailPath(contentId);
      if (cachedCover != null && await File(cachedCover).exists()) {
        _logger.d('🐛 Found legacy cached thumbnail: $cachedCover');
        return cachedCover;
      }

      return null;
    } catch (e) {
      _logger.e('Error getting local thumbnail path for $contentId: $e');
      return null;
    }
  }

  /// Read metadata for validation
  static Future<Map<String, dynamic>?> getDownloadedMetadata(String contentId) async {
    try {
      final basePaths = await _getPossibleBasePaths();
      
      for (final basePath in basePaths) {
        final metadataPath = path.join(basePath, contentId, 'metadata.json');
        final file = File(metadataPath);
        
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final metadata = jsonDecode(jsonString) as Map<String, dynamic>;
          _logger.d('Successfully read metadata for $contentId from $metadataPath');
          return metadata;
        }
      }
      
      _logger.d('Metadata file not found for $contentId in any base path');
      return null;
    } catch (e) {
      _logger.e('Error reading metadata for $contentId: $e');
      return null;
    }
  }

  /// Progressive loading: downloaded > internal cache > network
  /// Also saves network images to internal cache for future use
  static ImageProvider getProgressiveImageProvider(String networkUrl, String? localPath) {
    if (localPath != null && File(localPath).existsSync()) {
      _logger.d('🐛 Using local image provider: $localPath');
      return FileImage(File(localPath));
    }
    
    _logger.d('🐛 Using network image provider with cache fallback: $networkUrl');
    return CachedNetworkImageProvider(networkUrl);
  }

  /// Download and cache image from network to internal cache
  /// This method can be called when loading network images to cache them locally
  static Future<String?> downloadAndCacheImage(String networkUrl, String contentId, int pageNumber) async {
    try {
      // First check if already exists in cache to avoid duplicate downloads
      final existingPath = await getLocalImagePath(contentId, pageNumber);
      if (existingPath != null) {
        _logger.d('🐛 Image already exists locally: $existingPath');
        return existingPath;
      }

      // Download from network (this is a simplified version - in real app use proper HTTP client)
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(networkUrl));
      request.headers.set('User-Agent', 'AppleWebKit/537.36');
      request.headers.set('Referer', 'https://nhentai.net/');
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (var chunk in response) {
          bytes.addAll(chunk);
        }
        
        // Save to internal cache
        final cachedPath = await _saveToInternalCache(contentId, pageNumber, bytes);
        httpClient.close();
        
        return cachedPath;
      } else {
        httpClient.close();
        _logger.w('🐛 Failed to download image: HTTP ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      _logger.e('🐛 Error downloading and caching image: $e');
      return null;
    }
  }

  /// Get all downloaded content IDs
  static Future<List<String>> getDownloadedContentIds() async {
    try {
      final basePaths = await _getPossibleBasePaths();
      final contentIds = <String>{};  // Use Set to avoid duplicates
      
      for (final basePath in basePaths) {
        final baseDir = Directory(basePath);
        
        if (!await baseDir.exists()) {
          continue;
        }

        await for (final entity in baseDir.list()) {
          if (entity is Directory) {
            final contentId = path.basename(entity.path);
            if (await isContentDownloaded(contentId)) {
              contentIds.add(contentId);
            }
          }
        }
      }

      final resultList = contentIds.toList();
      _logger.i('Found ${resultList.length} downloaded contents across all storage locations');
      return resultList;
    } catch (e) {
      _logger.e('Error getting downloaded content IDs: $e');
      return [];
    }
  }

  /// Get image count for downloaded content
  static Future<int> getDownloadedImageCount(String contentId) async {
    try {
      final basePaths = await _getPossibleBasePaths();
      
      for (final basePath in basePaths) {
        final imagesDir = Directory(path.join(basePath, contentId, 'images'));
        
        if (await imagesDir.exists()) {
          final files = await imagesDir.list().toList();
          final imageFiles = files.where((file) => file is File && _isImageFile(file.path)).toList();
          
          if (imageFiles.isNotEmpty) {
            _logger.d('Found ${imageFiles.length} images for $contentId in $basePath');
            return imageFiles.length;
          }
        }
      }
      
      return 0;
    } catch (e) {
      _logger.e('Error getting downloaded image count for $contentId: $e');
      return 0;
    }
  }

  /// Validate downloaded content integrity
  static Future<bool> validateDownloadedContent(String contentId) async {
    try {
      final metadata = await getDownloadedMetadata(contentId);
      if (metadata == null) return false;

      final expectedPageCount = metadata['pageCount'] as int?;
      if (expectedPageCount == null) return false;

      final actualImageCount = await getDownloadedImageCount(contentId);
      
      final isValid = actualImageCount >= expectedPageCount;
      _logger.d('Content $contentId validation: $actualImageCount/$expectedPageCount images - ${isValid ? 'VALID' : 'INVALID'}');
      
      return isValid;
    } catch (e) {
      _logger.e('Error validating downloaded content $contentId: $e');
      return false;
    }
  }

  // Private helper methods

  /// Get cached image path (simulate cache directory)
  static Future<String?> _getCachedImagePath(String contentId, int pageNumber) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cachePath = path.join(appDir.path, 'cache', 'images', contentId, 'page_$pageNumber.jpg');
      
      // Check if cached version exists
      if (await File(cachePath).exists()) {
        return cachePath;
      }

      // Check CachedNetworkImage cache directory if available
      // This is a simplified approach - actual implementation might need CachedNetworkImage's cache manager
      return null;
    } catch (e) {
      _logger.e('Error getting cached image path: $e');
      return null;
    }
  }

  /// Get cached thumbnail path
  static Future<String?> _getCachedThumbnailPath(String contentId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cachePath = path.join(appDir.path, 'cache', 'thumbnails', '$contentId.jpg');
      
      if (await File(cachePath).exists()) {
        return cachePath;
      }

      return null;
    } catch (e) {
      _logger.e('Error getting cached thumbnail path: $e');
      return null;
    }
  }

  /// Helper method to check if file is an image
  static bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(extension);
  }

  /// Helper method to extract page number from filename
  static int _extractPageNumber(String filePath) {
    final filename = path.basenameWithoutExtension(filePath);
    final match = RegExp(r'(\d+)').firstMatch(filename);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  /// Get base local path for content
  static Future<String> getBaseLocalPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _baseLocalPath);
  }

  /// Get content folder path
  static Future<String> getContentFolderPath(String contentId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _baseLocalPath, contentId);
  }

  /// Get images folder path
  static Future<String> getImagesFolderPath(String contentId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _baseLocalPath, contentId, 'images');
  }
}
