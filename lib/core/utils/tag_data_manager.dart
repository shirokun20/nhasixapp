import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/tag.dart';

/// Comprehensive tag data manager for assets integration
/// Provides advanced tag management with caching, validation, and Matrix Filter Support
class TagDataManager {
  TagDataManager({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  // Asset path
  static const String _tagsAssetPath = 'assets/json/tags.json';

  // In-memory cache
  List<Tag>? _cachedTags;
  Map<String, List<Tag>>? _tagsByType;
  DateTime? _lastCacheUpdate;

  // Matrix Filter Support validation rules
  static const Map<String, bool> _multipleSelectSupport = {
    'tag': true,
    'artist': true,
    'character': true,
    'parody': true,
    'group': true,
    'language': false, // Single select only
    'category': false, // Single select only
  };

  /// Load and cache tag data from assets
  Future<void> cacheTagData() async {
    try {
      _logger.i('TagDataManager: Starting tag data caching from assets');

      final String jsonString = await rootBundle.loadString(_tagsAssetPath);
      final List<dynamic> jsonData = jsonDecode(jsonString);

      final List<Tag> tags = [];
      int invalidEntries = 0;

      // Process each tag entry
      for (int i = 0; i < jsonData.length; i++) {
        final item = jsonData[i];

        if (item is List && item.length >= 4) {
          try {
            final id = item[0] as int;
            final name = item[1] as String;
            final slug = item[2] as String;
            final typeCode = item[3] as int;

            // Validate required fields
            if (name.isEmpty) {
              invalidEntries++;
              continue;
            }

            // Convert type code to type name
            final type = _convertTypeCodeToName(typeCode);

            // Create Tag entity
            final tag = Tag(
              id: id,
              name: name,
              type: type,
              count: 0, // Default count, could be enhanced with popularity data
              url: _generateTagUrl(slug, type),
              slug: slug,
            );

            tags.add(tag);
          } catch (e) {
            _logger.w(
                'TagDataManager: Failed to process tag entry at index $i: $e');
            invalidEntries++;
          }
        } else {
          _logger.w('TagDataManager: Invalid tag entry format at index $i');
          invalidEntries++;
        }
      }

      // Cache the processed tags
      _cachedTags = tags;
      _lastCacheUpdate = DateTime.now();

      // Build type-based cache
      _buildTypeCache();

      if (invalidEntries > 0) {
        _logger.w(
            'TagDataManager: Skipped $invalidEntries invalid entries during caching');
      }

      _logger.i('TagDataManager: Successfully cached ${tags.length} tags');
    } catch (e, stackTrace) {
      _logger.e('TagDataManager: Error caching tag data',
          error: e, stackTrace: stackTrace);
      throw Exception('Failed to cache tag data: $e');
    }
  }

  /// Search tags by query with type filtering
  Future<List<Tag>> searchTags(
    String query, {
    String? type,
    int limit = 20,
    bool caseSensitive = false,
  }) async {
    if (query.isEmpty) return [];

    // Ensure data is cached
    await _ensureDataCached();

    final queryToMatch = caseSensitive ? query : query.toLowerCase();
    final results = <Tag>[];

    final tagsToSearch =
        type != null ? (_tagsByType?[type] ?? []) : (_cachedTags ?? []);

    for (final tag in tagsToSearch) {
      final nameToMatch = caseSensitive ? tag.name : tag.name.toLowerCase();

      if (nameToMatch.contains(queryToMatch)) {
        results.add(tag);
        if (results.length >= limit) break;
      }
    }

    // Sort by relevance: exact matches first, then starts with, then by popularity
    results.sort((a, b) {
      final aName = caseSensitive ? a.name : a.name.toLowerCase();
      final bName = caseSensitive ? b.name : b.name.toLowerCase();

      // Exact match priority
      if (aName == queryToMatch && bName != queryToMatch) return -1;
      if (bName == queryToMatch && aName != queryToMatch) return 1;

      // Starts with priority
      if (aName.startsWith(queryToMatch) && !bName.startsWith(queryToMatch)) {
        return -1;
      }
      if (bName.startsWith(queryToMatch) && !aName.startsWith(queryToMatch)) {
        return 1;
      }

      // Sort by popularity (count)
      return b.count.compareTo(a.count);
    });

    _logger.d(
        'TagDataManager: Found ${results.length} tags for query "$query"${type != null ? ' (type: $type)' : ''}');
    return results;
  }

  /// Get tags by type with pagination and search
  Future<List<Tag>> getTagsByType(
    String type, {
    int offset = 0,
    int limit = 100,
    String? searchQuery,
  }) async {
    // Ensure data is cached
    await _ensureDataCached();

    final normalizedType = _normalizeTagType(type);
    List<Tag> tags = _tagsByType?[normalizedType] ?? [];

    // Apply search filter if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      tags = tags
          .where((tag) => tag.name.toLowerCase().contains(queryLower))
          .toList();
    }

    // Apply pagination
    final paginatedTags = tags.skip(offset).take(limit).toList();

    _logger.d(
        'TagDataManager: Retrieved ${paginatedTags.length} tags of type "$type"'
        '${searchQuery != null ? ' with search "$searchQuery"' : ''}');

    return paginatedTags;
  }

  /// Get popular tags with type filtering
  Future<List<Tag>> getPopularTags({
    String? type,
    int limit = 20,
    int minCount = 0,
  }) async {
    // Ensure data is cached
    await _ensureDataCached();

    List<Tag> tags = type != null
        ? (_tagsByType?[_normalizeTagType(type)] ?? [])
        : (_cachedTags ?? []);

    // Filter by minimum count and sort by popularity
    final popularTags = tags.where((tag) => tag.count >= minCount).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final result = popularTags.take(limit).toList();

    _logger.d('TagDataManager: Retrieved ${result.length} popular tags'
        '${type != null ? ' of type "$type"' : ''}');

    return result;
  }

  /// Validate Matrix Filter Support rules
  bool validateMatrixFilterSupport(String type, List<String> selectedValues) {
    final normalizedType = _normalizeTagType(type);
    final supportsMultiple = _multipleSelectSupport[normalizedType] ?? true;

    if (!supportsMultiple && selectedValues.length > 1) {
      _logger.w('TagDataManager: Matrix Filter validation failed - '
          'Type "$type" only supports single selection but got ${selectedValues.length} values');
      return false;
    }

    _logger
        .d('TagDataManager: Matrix Filter validation passed for type "$type" '
            'with ${selectedValues.length} values');
    return true;
  }

  /// Check if type supports multiple selection
  bool supportsMultipleSelection(String type) {
    final normalizedType = _normalizeTagType(type);
    return _multipleSelectSupport[normalizedType] ?? true;
  }

  /// Get all available tag types
  List<String> getAvailableTypes() {
    return _multipleSelectSupport.keys.toList();
  }

  /// Get tag statistics
  Future<Map<String, dynamic>> getTagStatistics() async {
    await _ensureDataCached();

    final stats = <String, dynamic>{
      'total_tags': _cachedTags?.length ?? 0,
      'last_cache_update': _lastCacheUpdate?.toIso8601String(),
      'cache_size_mb': _getCacheSizeMB(),
      'types': <String, int>{},
    };

    // Calculate type statistics
    if (_tagsByType != null) {
      for (final entry in _tagsByType!.entries) {
        stats['types'][entry.key] = entry.value.length;
      }
    }

    return stats;
  }

  /// Clear all cached data
  void clearCache() {
    _cachedTags = null;
    _tagsByType = null;
    _lastCacheUpdate = null;
    _logger.i('TagDataManager: Cleared all cached data');
  }

  /// Check if data is cached and valid
  bool get isCached => _cachedTags != null && _tagsByType != null;

  /// Get cache age in minutes
  int? get cacheAgeMinutes {
    if (_lastCacheUpdate == null) return null;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes;
  }

  /// Ensure data is cached, load if necessary
  Future<void> _ensureDataCached() async {
    if (!isCached) {
      await cacheTagData();
    }
  }

  /// Build type-based cache for faster lookups
  void _buildTypeCache() {
    if (_cachedTags == null) return;

    _tagsByType = <String, List<Tag>>{};

    for (final tag in _cachedTags!) {
      final type = tag.type;
      _tagsByType![type] = (_tagsByType![type] ?? [])..add(tag);
    }

    // Sort each type by popularity
    for (final entry in _tagsByType!.entries) {
      entry.value.sort((a, b) => b.count.compareTo(a.count));
    }

    _logger.d(
        'TagDataManager: Built type cache with ${_tagsByType!.length} types');
  }

  /// Convert type code from assets to type name
  String _convertTypeCodeToName(int typeCode) {
    switch (typeCode) {
      case 0:
        return 'category';
      case 1:
        return 'artist';
      case 2:
        return 'parody';
      case 3:
        return 'tag';
      case 4:
        return 'character';
      case 5:
        return 'group';
      case 6:
        return 'language';
      case 7:
        return 'category';
      default:
        return 'tag';
    }
  }

  /// Normalize tag type for consistency
  String _normalizeTagType(String type) {
    final typeStr = type.toLowerCase().trim();

    // Map common variations
    switch (typeStr) {
      case 'artists':
        return 'artist';
      case 'characters':
        return 'character';
      case 'parodies':
        return 'parody';
      case 'groups':
        return 'group';
      case 'languages':
        return 'language';
      case 'categories':
        return 'category';
      case 'tags':
        return 'tag';
      default:
        return typeStr;
    }
  }

  /// Generate tag URL based on type and slug
  String _generateTagUrl(String slug, String type) {
    if (slug.isEmpty) return '/';

    final normalizedType = _normalizeTagType(type);

    switch (normalizedType) {
      case 'artist':
        return '/artist/$slug/';
      case 'character':
        return '/character/$slug/';
      case 'parody':
        return '/parody/$slug/';
      case 'group':
        return '/group/$slug/';
      case 'language':
        return '/language/$slug/';
      case 'category':
        return '/category/$slug/';
      default:
        return '/tag/$slug/';
    }
  }

  /// Calculate cache size in MB
  double _getCacheSizeMB() {
    if (_cachedTags == null) return 0.0;

    // Rough estimation based on tag data
    final totalChars = _cachedTags!.fold<int>(
        0,
        (sum, tag) =>
            sum +
            tag.name.length +
            tag.type.length +
            tag.url.length +
            (tag.slug?.length ?? 0));

    return (totalChars * 2) / (1024 * 1024); // Rough estimation in MB
  }
}
