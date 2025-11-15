import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/content.dart';
import '../../domain/entities/tag.dart';
import '../../data/models/content_model.dart';

/// Service for caching content detail data to improve performance
/// Reduces loading times from ~3-4 seconds to target <1.5 seconds
class DetailCacheService {
  static const String _cacheKeyPrefix = 'detail_cache_';
  static const String _metadataKey = 'detail_cache_metadata';
  static const Duration _defaultCacheDuration =
      Duration(hours: 24); // 24 hours cache
  static const int _maxCacheEntries = 50; // Limit cache size

  final Logger _logger = Logger();

  /// Get cached content detail by ID
  Future<Content?> getCachedDetail(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(contentId);

      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) {
        return null;
      }

      final cachedData = json.decode(cachedJson) as Map<String, dynamic>;

      // Check if cache is expired
      final cachedAt = DateTime.parse(cachedData['cachedAt'] as String);
      final isExpired =
          DateTime.now().difference(cachedAt) > _defaultCacheDuration;

      if (isExpired) {
        _logger.d('Detail cache expired for content: $contentId');
        await _removeFromCache(contentId);
        return null;
      }

      // Parse content from cache using ContentModel
      final contentMap = cachedData['content'] as Map<String, dynamic>;
      final tags =
          _parseTagsFromCache(contentMap['tags'] as List<dynamic>? ?? []);
      final contentModel = ContentModel.fromMap(contentMap, tags);

      _logger.d('Retrieved cached detail for content: $contentId');
      return contentModel.toEntity();
    } catch (e) {
      _logger.w('Error retrieving cached detail for $contentId: $e');
      return null;
    }
  }

  /// Cache content detail
  Future<void> cacheDetail(Content content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(content.id);

      // Convert to ContentModel for serialization
      final contentModel = ContentModel.fromEntity(content);
      final contentMap = contentModel.toMap();

      // Add tags to the map for caching
      contentMap['tags'] = _tagsToCacheFormat(content.tags);

      final cacheData = {
        'content': contentMap,
        'cachedAt': DateTime.now().toIso8601String(),
        'contentId': content.id,
      };

      final jsonData = json.encode(cacheData);
      await prefs.setString(cacheKey, jsonData);

      // Update metadata
      await _updateCacheMetadata(content.id);

      // Clean up old entries if needed
      await _cleanupOldEntries();

      _logger.d('Cached detail for content: ${content.id}');
    } catch (e) {
      _logger.w('Error caching detail for ${content.id}: $e');
    }
  }

  /// Parse tags from cached data
  List<Tag> _parseTagsFromCache(List<dynamic> tagsData) {
    return tagsData.map((tagData) {
      final map = tagData as Map<String, dynamic>;
      return Tag(
        id: map['id'] as int,
        name: map['name'] as String,
        type: map['type'] as String,
        count: map['count'] as int,
        url: map['url'] as String,
        slug: map['slug'] as String?,
      );
    }).toList();
  }

  /// Convert tags to cache format
  List<Map<String, dynamic>> _tagsToCacheFormat(List<Tag> tags) {
    return tags
        .map((tag) => {
              'id': tag.id,
              'name': tag.name,
              'type': tag.type,
              'count': tag.count,
              'url': tag.url,
              'slug': tag.slug,
            })
        .toList();
  }

  /// Get cache key for content ID
  String _getCacheKey(String contentId) => '$_cacheKeyPrefix$contentId';

  /// Update cache metadata
  Future<void> _updateCacheMetadata(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getString(_metadataKey);
    final metadataList = metadata != null
        ? (json.decode(metadata) as List<dynamic>).cast<String>()
        : <String>[];

    // Remove if already exists, then add to front (most recent)
    metadataList.remove(contentId);
    metadataList.insert(0, contentId);

    await prefs.setString(_metadataKey, json.encode(metadataList));
  }

  /// Clean up old cache entries to maintain size limit
  Future<void> _cleanupOldEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getString(_metadataKey);

    if (metadata == null) return;

    final metadataList =
        (json.decode(metadata) as List<dynamic>).cast<String>();

    // Remove entries beyond the limit
    if (metadataList.length > _maxCacheEntries) {
      final entriesToRemove = metadataList.sublist(_maxCacheEntries);

      for (final contentId in entriesToRemove) {
        await _removeFromCache(contentId);
      }

      // Update metadata
      final updatedList = metadataList.sublist(0, _maxCacheEntries);
      await prefs.setString(_metadataKey, json.encode(updatedList));
    }
  }

  /// Remove content from cache
  Future<void> _removeFromCache(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _getCacheKey(contentId);
    await prefs.remove(cacheKey);

    // Update metadata
    final metadata = prefs.getString(_metadataKey);
    if (metadata != null) {
      final metadataList =
          (json.decode(metadata) as List<dynamic>).cast<String>();
      metadataList.remove(contentId);
      await prefs.setString(_metadataKey, json.encode(metadataList));
    }
  }

  /// Clear all cached details
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getString(_metadataKey);

    if (metadata != null) {
      final metadataList =
          (json.decode(metadata) as List<dynamic>).cast<String>();
      for (final contentId in metadataList) {
        final cacheKey = _getCacheKey(contentId);
        await prefs.remove(cacheKey);
      }
    }

    await prefs.remove(_metadataKey);
    _logger.d('Cleared all detail cache');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getString(_metadataKey);

    if (metadata == null) {
      return {'totalEntries': 0, 'cacheSize': 0};
    }

    final metadataList =
        (json.decode(metadata) as List<dynamic>).cast<String>();
    int totalSize = 0;

    for (final contentId in metadataList) {
      final cacheKey = _getCacheKey(contentId);
      final data = prefs.getString(cacheKey);
      if (data != null) {
        totalSize += data.length;
      }
    }

    return {
      'totalEntries': metadataList.length,
      'cacheSize': totalSize,
      'cacheSizeKB': (totalSize / 1024).round(),
    };
  }
}
