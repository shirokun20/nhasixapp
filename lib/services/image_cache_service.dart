import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Internal class for memory cache data
class _CachedImageData {
  final File file;
  final DateTime cachedAt;
  final int size;

  _CachedImageData({
    required this.file,
    required this.cachedAt,
    required this.size,
  });
}

/// Service for caching images to improve loading performance and reduce network usage
/// Provides memory and disk caching with TTL (Time To Live) support
class ImageCacheService {
  static const String _cacheMetadataKey = 'image_cache_metadata';
  static const String _cacheVersion = '1.0.0';
  static const Duration _defaultCacheDuration = Duration(hours: 24); // 24 hours
  static const int _maxCacheSizeMB = 100; // 100MB max cache size

  final Logger _logger = Logger();

  // In-memory cache for fast access
  final Map<String, _CachedImageData> _memoryCache = {};

  /// Get cached image data by URL
  Future<File?> getCachedImage(String imageUrl) async {
    try {
      final cacheKey = _generateCacheKey(imageUrl);

      // Check memory cache first
      final memoryData = _memoryCache[cacheKey];
      if (memoryData != null && !_isExpired(memoryData.cachedAt)) {
        _logger.d('Image cache hit (memory): $imageUrl');
        return memoryData.file;
      }

      // Check disk cache
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$cacheKey');

      if (await cacheFile.exists()) {
        // Check if cache is expired
        final metadata = await _getCacheMetadata();
        final cacheEntry = metadata[cacheKey];

        if (cacheEntry != null && !_isExpired(cacheEntry['cachedAt'])) {
          // Load into memory cache for faster future access
          _memoryCache[cacheKey] = _CachedImageData(
            file: cacheFile,
            cachedAt: DateTime.parse(cacheEntry['cachedAt']),
            size: await cacheFile.length(),
          );

          _logger.d('Image cache hit (disk): $imageUrl');
          return cacheFile;
        } else {
          // Remove expired cache
          await cacheFile.delete();
          await _removeFromMetadata(cacheKey);
          _logger.d('Removed expired image cache: $imageUrl');
        }
      }

      _logger.d('Image cache miss: $imageUrl');
      return null;
    } catch (e) {
      _logger.w('Error getting cached image for $imageUrl: $e');
      return null;
    }
  }

  /// Cache image data
  Future<void> cacheImage(String imageUrl, List<int> imageData) async {
    try {
      final cacheKey = _generateCacheKey(imageUrl);
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$cacheKey');

      // Write image data to file
      await cacheFile.writeAsBytes(imageData);

      final cachedAt = DateTime.now();
      final fileSize = imageData.length;

      // Add to memory cache
      _memoryCache[cacheKey] = _CachedImageData(
        file: cacheFile,
        cachedAt: cachedAt,
        size: fileSize,
      );

      // Update metadata
      await _addToMetadata(cacheKey, cachedAt, fileSize);

      // Clean up old entries if cache size exceeds limit
      await _cleanupIfNeeded();

      _logger.d('Cached image: $imageUrl (${_formatBytes(fileSize)})');
    } catch (e) {
      _logger.w('Error caching image for $imageUrl: $e');
    }
  }

  /// Check if image is cached
  Future<bool> isImageCached(String imageUrl) async {
    final cachedFile = await getCachedImage(imageUrl);
    return cachedFile != null;
  }

  /// Clear cache for specific content ID
  Future<void> clearContentCache(String contentId) async {
    try {
      final metadata = await _getCacheMetadata();
      final keysToRemove = <String>[];

      // Find all cache entries for this content
      metadata.forEach((key, value) {
        final url = value['url'] as String?;
        if (url != null && url.contains('/galleries/$contentId/')) {
          keysToRemove.add(key);
        }
      });

      // Remove files and metadata
      final cacheDir = await _getCacheDirectory();
      for (final key in keysToRemove) {
        final cacheFile = File('${cacheDir.path}/$key');
        if (await cacheFile.exists()) {
          await cacheFile.delete();
        }
        await _removeFromMetadata(key);
        _memoryCache.remove(key);
      }

      _logger.i(
          'Cleared image cache for content: $contentId (${keysToRemove.length} files)');
    } catch (e) {
      _logger.w('Error clearing content cache for $contentId: $e');
    }
  }

  /// Clear all cached images
  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _getCacheDirectory();

      // Delete all cache files
      final files = cacheDir.listSync();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }

      // Clear metadata and memory cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheMetadataKey);
      _memoryCache.clear();

      _logger.i('Cleared all image cache');
    } catch (e) {
      _logger.w('Error clearing all image cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final metadata = await _getCacheMetadata();
      int totalSize = 0;
      final int totalFiles = metadata.length;

      for (final entry in metadata.values) {
        totalSize += entry['size'] as int? ?? 0;
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).round(),
        'memoryCacheSize': _memoryCache.length,
        'cacheVersion': _cacheVersion,
      };
    } catch (e) {
      _logger.w('Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Generate cache key from URL
  String _generateCacheKey(String url) {
    // Use SHA-256 hash of URL as cache key
    final bytes = utf8.encode(url);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Get cache directory
  Future<Directory> _getCacheDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    final imageCacheDir = Directory('${cacheDir.path}/images');

    if (!await imageCacheDir.exists()) {
      await imageCacheDir.create(recursive: true);
    }

    return imageCacheDir;
  }

  /// Check if cache entry is expired
  bool _isExpired(dynamic cachedAt) {
    if (cachedAt is String) {
      final date = DateTime.parse(cachedAt);
      return DateTime.now().difference(date) > _defaultCacheDuration;
    } else if (cachedAt is DateTime) {
      return DateTime.now().difference(cachedAt) > _defaultCacheDuration;
    }
    return true; // Consider expired if format is unknown
  }

  /// Get cache metadata from SharedPreferences
  Future<Map<String, dynamic>> _getCacheMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString(_cacheMetadataKey);

    if (metadataJson == null) return {};

    try {
      return Map<String, dynamic>.from(json.decode(metadataJson));
    } catch (e) {
      _logger.w('Error parsing cache metadata: $e');
      return {};
    }
  }

  /// Add entry to metadata
  Future<void> _addToMetadata(
      String cacheKey, DateTime cachedAt, int size) async {
    final metadata = await _getCacheMetadata();
    metadata[cacheKey] = {
      'cachedAt': cachedAt.toIso8601String(),
      'size': size,
      'url': '', // Could be stored for debugging but increases metadata size
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheMetadataKey, json.encode(metadata));
  }

  /// Remove entry from metadata
  Future<void> _removeFromMetadata(String cacheKey) async {
    final metadata = await _getCacheMetadata();
    metadata.remove(cacheKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheMetadataKey, json.encode(metadata));
  }

  /// Clean up old entries if cache size exceeds limit
  Future<void> _cleanupIfNeeded() async {
    try {
      final metadata = await _getCacheMetadata();
      int totalSize = 0;

      // Calculate total cache size
      for (final entry in metadata.values) {
        totalSize += entry['size'] as int? ?? 0;
      }

      const maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      if (totalSize > maxSizeBytes) {
        _logger.i(
            'Cache size exceeded limit (${_formatBytes(totalSize)}), cleaning up...');

        // Sort by cached date (oldest first)
        final sortedEntries = metadata.entries.toList()
          ..sort((a, b) {
            final dateA = DateTime.parse(a.value['cachedAt']);
            final dateB = DateTime.parse(b.value['cachedAt']);
            return dateA.compareTo(dateB);
          });

        // Remove oldest entries until we're under the limit
        final cacheDir = await _getCacheDirectory();
        int removedSize = 0;

        for (final entry in sortedEntries) {
          if (totalSize - removedSize <= maxSizeBytes * 0.8) {
            break; // Keep 80% of limit
          }

          final cacheKey = entry.key;
          final cacheFile = File('${cacheDir.path}/$cacheKey');

          if (await cacheFile.exists()) {
            await cacheFile.delete();
            removedSize += entry.value['size'] as int? ?? 0;
          }

          await _removeFromMetadata(cacheKey);
          _memoryCache.remove(cacheKey);
        }

        _logger.i('Cleaned up ${_formatBytes(removedSize)} from image cache');
      }
    } catch (e) {
      _logger.w('Error during cache cleanup: $e');
    }
  }

  /// Format bytes to human readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
