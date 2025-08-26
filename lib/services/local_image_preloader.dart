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
  static final Logger _logger = Logger();

  /// Check if content is downloaded with metadata validation
  static Future<bool> isContentDownloaded(String contentId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final metadataPath = path.join(appDir.path, _baseLocalPath, contentId, 'metadata.json');
      final metadataFile = File(metadataPath);
      
      return await metadataFile.exists();
    } catch (e) {
      _logger.e('Error checking if content is downloaded for $contentId: $e');
      return false;
    }
  }

  /// Get local image path with priority: downloaded > cache > null
  static Future<String?> getLocalImagePath(String contentId, int pageNumber) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // Priority 1: Downloaded content
      final downloadedPath = path.join(
        appDir.path, 
        _baseLocalPath, 
        contentId, 
        'images', 
        'page_$pageNumber.jpg'
      );
      final downloadedFile = File(downloadedPath);
      if (await downloadedFile.exists()) {
        _logger.d('Found downloaded image: $downloadedPath');
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
        final altPath = path.join(appDir.path, _baseLocalPath, contentId, 'images', pattern);
        final altFile = File(altPath);
        if (await altFile.exists()) {
          _logger.d('Found downloaded image with alt pattern: $altPath');
          return altPath;
        }
      }

      // Priority 2: Check if file exists in images folder (scan directory)
      final imagesDir = Directory(path.join(appDir.path, _baseLocalPath, contentId, 'images'));
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
          _logger.d('Found image by directory scan: ${targetFile.path}');
          return targetFile.path;
        }
      }

      // Priority 3: Cache local (for content that hasn't been fully downloaded)
      final cachePath = await _getCachedImagePath(contentId, pageNumber);
      if (cachePath != null && await File(cachePath).exists()) {
        _logger.d('Found cached image: $cachePath');
        return cachePath;
      }

      return null; // Fallback to network
    } catch (e) {
      _logger.e('Error getting local image path for $contentId page $pageNumber: $e');
      return null;
    }
  }

  /// Get local thumbnail/cover path
  static Future<String?> getLocalThumbnailPath(String contentId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // Check downloaded cover first
      final downloadedCoverPatterns = [
        'cover.jpg',
        'thumbnail.jpg',
        'thumb.jpg',
        '1.jpg', // First page as cover
        'page_1.jpg',
      ];

      for (final pattern in downloadedCoverPatterns) {
        final coverPath = path.join(appDir.path, _baseLocalPath, contentId, pattern);
        if (await File(coverPath).exists()) {
          _logger.d('Found downloaded cover: $coverPath');
          return coverPath;
        }

        // Also check in images folder
        final coverInImagesPath = path.join(appDir.path, _baseLocalPath, contentId, 'images', pattern);
        if (await File(coverInImagesPath).exists()) {
          _logger.d('Found downloaded cover in images folder: $coverInImagesPath');
          return coverInImagesPath;
        }
      }

      // Check cached thumbnail
      final cachedCover = await _getCachedThumbnailPath(contentId);
      if (cachedCover != null && await File(cachedCover).exists()) {
        _logger.d('Found cached thumbnail: $cachedCover');
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
      final appDir = await getApplicationDocumentsDirectory();
      final metadataPath = path.join(appDir.path, _baseLocalPath, contentId, 'metadata.json');
      final file = File(metadataPath);
      
      if (!await file.exists()) {
        _logger.d('Metadata file not found: $metadataPath');
        return null;
      }
      
      final jsonString = await file.readAsString();
      final metadata = jsonDecode(jsonString) as Map<String, dynamic>;
      _logger.d('Successfully read metadata for $contentId');
      return metadata;
    } catch (e) {
      _logger.e('Error reading metadata for $contentId: $e');
      return null;
    }
  }

  /// Progressive loading: downloaded > cache > network
  static ImageProvider getProgressiveImageProvider(String networkUrl, String? localPath) {
    if (localPath != null && File(localPath).existsSync()) {
      _logger.d('Using local image provider: $localPath');
      return FileImage(File(localPath));
    }
    _logger.d('Using network image provider: $networkUrl');
    return CachedNetworkImageProvider(networkUrl);
  }

  /// Get all downloaded content IDs
  static Future<List<String>> getDownloadedContentIds() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final baseDir = Directory(path.join(appDir.path, _baseLocalPath));
      
      if (!await baseDir.exists()) {
        return [];
      }

      final contentIds = <String>[];
      await for (final entity in baseDir.list()) {
        if (entity is Directory) {
          final contentId = path.basename(entity.path);
          if (await isContentDownloaded(contentId)) {
            contentIds.add(contentId);
          }
        }
      }

      _logger.i('Found ${contentIds.length} downloaded contents');
      return contentIds;
    } catch (e) {
      _logger.e('Error getting downloaded content IDs: $e');
      return [];
    }
  }

  /// Get image count for downloaded content
  static Future<int> getDownloadedImageCount(String contentId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, _baseLocalPath, contentId, 'images'));
      
      if (!await imagesDir.exists()) {
        return 0;
      }

      final files = await imagesDir.list().toList();
      final imageFiles = files.where((file) => file is File && _isImageFile(file.path)).toList();
      
      return imageFiles.length;
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
