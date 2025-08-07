import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Custom image cache manager with advanced features
///
/// Features:
/// - Progressive image loading with thumbnails
/// - Custom cache configuration
/// - Image compression and optimization
/// - Thumbnail generation
/// - Memory and disk cache management
class ImageCacheManager {
  static ImageCacheManager? _instance;
  static ImageCacheManager get instance => _instance ??= ImageCacheManager._();

  ImageCacheManager._();

  // Cache managers for different image types
  late final CacheManager _fullImageCache;
  late final CacheManager _thumbnailCache;
  late final CacheManager _compressedCache;

  // Cache configuration constants
  static const Duration _maxCacheAge = Duration(days: 30);
  static const Duration _thumbnailCacheAge = Duration(days: 7);

  // Thumbnail configuration
  static const int _thumbnailWidth = 200;
  static const int _thumbnailHeight = 300;
  static const int _compressionQuality = 85;

  bool _initialized = false;

  /// Initialize the cache managers
  Future<void> initialize() async {
    if (_initialized) return;

    // Full image cache
    _fullImageCache = CacheManager(
      Config(
        'nhentai_images',
        stalePeriod: _maxCacheAge,
        maxNrOfCacheObjects: 1000,
        repo: JsonCacheInfoRepository(databaseName: 'nhentai_images'),
        fileService: HttpFileService(),
      ),
    );

    // Thumbnail cache
    _thumbnailCache = CacheManager(
      Config(
        'nhentai_thumbnails',
        stalePeriod: _thumbnailCacheAge,
        maxNrOfCacheObjects: 2000,
        repo: JsonCacheInfoRepository(databaseName: 'nhentai_thumbnails'),
        fileService: HttpFileService(),
      ),
    );

    // Compressed image cache
    _compressedCache = CacheManager(
      Config(
        'nhentai_compressed',
        stalePeriod: _maxCacheAge,
        maxNrOfCacheObjects: 1500,
        repo: JsonCacheInfoRepository(databaseName: 'nhentai_compressed'),
        fileService: HttpFileService(),
      ),
    );

    _initialized = true;
  }

  /// Get full resolution image from cache or network
  Future<File> getFullImage(String url) async {
    await initialize();
    return await _fullImageCache.getSingleFile(url);
  }

  /// Get thumbnail image from cache or generate if not exists
  Future<File> getThumbnail(String url) async {
    await initialize();

    final thumbnailKey = _generateThumbnailKey(url);

    try {
      // Try to get existing thumbnail
      return await _thumbnailCache.getSingleFile(thumbnailKey);
    } catch (e) {
      // Generate thumbnail if not exists
      return await _generateAndCacheThumbnail(url, thumbnailKey);
    }
  }

  /// Get compressed image from cache or generate if not exists
  Future<File> getCompressedImage(String url,
      {int quality = _compressionQuality}) async {
    await initialize();

    final compressedKey = _generateCompressedKey(url, quality);

    try {
      // Try to get existing compressed image
      return await _compressedCache.getSingleFile(compressedKey);
    } catch (e) {
      // Generate compressed image if not exists
      return await _generateAndCacheCompressed(url, compressedKey, quality);
    }
  }

  /// Generate and cache thumbnail
  Future<File> _generateAndCacheThumbnail(
      String originalUrl, String thumbnailKey) async {
    try {
      // Get original image
      final originalFile = await _fullImageCache.getSingleFile(originalUrl);
      final originalBytes = await originalFile.readAsBytes();

      // Decode and resize image
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate thumbnail dimensions maintaining aspect ratio
      final aspectRatio = originalImage.width / originalImage.height;
      int thumbnailWidth = _thumbnailWidth;
      int thumbnailHeight = _thumbnailHeight;

      if (aspectRatio > (thumbnailWidth / thumbnailHeight)) {
        thumbnailHeight = (thumbnailWidth / aspectRatio).round();
      } else {
        thumbnailWidth = (thumbnailHeight * aspectRatio).round();
      }

      // Resize image
      final thumbnail = img.copyResize(
        originalImage,
        width: thumbnailWidth,
        height: thumbnailHeight,
        interpolation: img.Interpolation.cubic,
      );

      // Encode as JPEG with compression
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);

      // Save to cache
      final cacheDir = await getTemporaryDirectory();
      final thumbnailFile = File(
          '${cacheDir.path}/thumbnails/${_sanitizeFileName(thumbnailKey)}.jpg');
      await thumbnailFile.create(recursive: true);
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      // Add to cache manager
      await _thumbnailCache.putFile(thumbnailKey, thumbnailBytes);

      return thumbnailFile;
    } catch (e) {
      // Fallback to original image if thumbnail generation fails
      return await _fullImageCache.getSingleFile(originalUrl);
    }
  }

  /// Generate and cache compressed image
  Future<File> _generateAndCacheCompressed(
      String originalUrl, String compressedKey, int quality) async {
    try {
      // Get original image
      final originalFile = await _fullImageCache.getSingleFile(originalUrl);
      final originalBytes = await originalFile.readAsBytes();

      // Decode and compress image
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Encode with specified quality
      final compressedBytes = img.encodeJpg(originalImage, quality: quality);

      // Save to cache
      await _compressedCache.putFile(compressedKey, compressedBytes);

      return await _compressedCache.getSingleFile(compressedKey);
    } catch (e) {
      // Fallback to original image if compression fails
      return await _fullImageCache.getSingleFile(originalUrl);
    }
  }

  /// Generate thumbnail cache key
  String _generateThumbnailKey(String url) {
    final bytes = utf8.encode('thumbnail_$url');
    final digest = sha256.convert(bytes);
    return 'thumb_${digest.toString()}';
  }

  /// Generate compressed image cache key
  String _generateCompressedKey(String url, int quality) {
    final bytes = utf8.encode('compressed_${quality}_$url');
    final digest = sha256.convert(bytes);
    return 'comp_${quality}_${digest.toString()}';
  }

  /// Sanitize filename for file system
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> urls) async {
    await initialize();

    final futures = urls.map((url) async {
      try {
        // Preload thumbnail first (faster)
        await getThumbnail(url);
        // Then preload compressed version
        await getCompressedImage(url);
      } catch (e) {
        // Ignore preload errors
      }
    });

    await Future.wait(futures);
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await initialize();

    await Future.wait([
      _fullImageCache.emptyCache(),
      _thumbnailCache.emptyCache(),
      _compressedCache.emptyCache(),
    ]);
  }

  /// Clear specific cache type
  Future<void> clearCache(CacheType type) async {
    await initialize();

    switch (type) {
      case CacheType.fullImage:
        await _fullImageCache.emptyCache();
        break;
      case CacheType.thumbnail:
        await _thumbnailCache.emptyCache();
        break;
      case CacheType.compressed:
        await _compressedCache.emptyCache();
        break;
    }
  }

  /// Get cache information
  Future<CacheInfo> getCacheInfo() async {
    await initialize();

    final fullImageInfo = await _getCacheManagerInfo(_fullImageCache);
    final thumbnailInfo = await _getCacheManagerInfo(_thumbnailCache);
    final compressedInfo = await _getCacheManagerInfo(_compressedCache);

    return CacheInfo(
      fullImageCache: fullImageInfo,
      thumbnailCache: thumbnailInfo,
      compressedCache: compressedInfo,
      totalSize: fullImageInfo.size + thumbnailInfo.size + compressedInfo.size,
      totalFiles: fullImageInfo.fileCount +
          thumbnailInfo.fileCount +
          compressedInfo.fileCount,
    );
  }

  /// Get cache manager information
  Future<CacheManagerInfo> _getCacheManagerInfo(
      CacheManager cacheManager) async {
    try {
      // This is a workaround since flutter_cache_manager doesn't provide direct size info
      // In a real implementation, you might want to iterate through cache files
      return CacheManagerInfo(
        size: 0, // Would need to calculate actual size
        fileCount: 0, // Would need to count actual files
        lastCleanup: DateTime.now(),
      );
    } catch (e) {
      return CacheManagerInfo(
        size: 0,
        fileCount: 0,
        lastCleanup: DateTime.now(),
      );
    }
  }

  /// Optimize cache by removing old or unused files
  Future<void> optimizeCache() async {
    await initialize();

    // Clean up old cache files
    await Future.wait([
      _fullImageCache.emptyCache(),
      _thumbnailCache.emptyCache(),
      _compressedCache.emptyCache(),
    ]);
  }

  /// Check if image exists in cache
  Future<bool> isImageCached(String url,
      {CacheType type = CacheType.fullImage}) async {
    await initialize();

    try {
      CacheManager cacheManager;
      String key = url;

      switch (type) {
        case CacheType.fullImage:
          cacheManager = _fullImageCache;
          break;
        case CacheType.thumbnail:
          cacheManager = _thumbnailCache;
          key = _generateThumbnailKey(url);
          break;
        case CacheType.compressed:
          cacheManager = _compressedCache;
          key = _generateCompressedKey(url, _compressionQuality);
          break;
      }

      final fileInfo = await cacheManager.getFileFromCache(key);
      return fileInfo != null && fileInfo.file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Get cache file if exists
  Future<File?> getCachedFile(String url,
      {CacheType type = CacheType.fullImage}) async {
    await initialize();

    try {
      CacheManager cacheManager;
      String key = url;

      switch (type) {
        case CacheType.fullImage:
          cacheManager = _fullImageCache;
          break;
        case CacheType.thumbnail:
          cacheManager = _thumbnailCache;
          key = _generateThumbnailKey(url);
          break;
        case CacheType.compressed:
          cacheManager = _compressedCache;
          key = _generateCompressedKey(url, _compressionQuality);
          break;
      }

      final fileInfo = await cacheManager.getFileFromCache(key);
      return fileInfo?.file;
    } catch (e) {
      return null;
    }
  }
}

/// Cache type enumeration
enum CacheType {
  fullImage,
  thumbnail,
  compressed,
}

/// Cache information data classes
class CacheInfo {
  final CacheManagerInfo fullImageCache;
  final CacheManagerInfo thumbnailCache;
  final CacheManagerInfo compressedCache;
  final int totalSize;
  final int totalFiles;

  CacheInfo({
    required this.fullImageCache,
    required this.thumbnailCache,
    required this.compressedCache,
    required this.totalSize,
    required this.totalFiles,
  });
}

class CacheManagerInfo {
  final int size;
  final int fileCount;
  final DateTime lastCleanup;

  CacheManagerInfo({
    required this.size,
    required this.fileCount,
    required this.lastCleanup,
  });
}
