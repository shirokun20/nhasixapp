import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/tag.dart';

/// Simple tag resolver that uses local assets only
/// Loads tag mapping from assets/json/tags.json
class TagResolver {
  TagResolver({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  // Local asset path for tag mapping
  static const String _localTagsAsset = 'assets/json/tags.json';

  // In-memory cache
  Map<String, Map<String, dynamic>>? _tagMapping;
  DateTime? _lastCacheUpdate;

  /// Get tag mapping (from memory or local asset)
  Future<Map<String, Map<String, dynamic>>> getTagMapping() async {
    // Return from memory if available
    if (_tagMapping != null) {
      _logger.d('Using in-memory tag mapping cache');
      return _tagMapping!;
    }

    try {
      // Load from local asset
      final localMapping = await _loadFromLocalAsset();
      if (localMapping != null) {
        _tagMapping = localMapping;
        _lastCacheUpdate = DateTime.now();
        _logger.d('Loaded tag mapping from local asset');
        return _tagMapping!;
      }

      // Fallback to empty mapping if loading fails
      _logger.w(
          'Failed to load tag mapping from local asset, using empty mapping');
      return {};
    } catch (e, stackTrace) {
      _logger.e('Error getting tag mapping', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Resolve tag IDs to Tag objects
  Future<List<Tag>> resolveTagIds(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    final tagMapping = await getTagMapping();
    final tags = <Tag>[];

    for (final tagId in tagIds) {
      final tagData = tagMapping[tagId];
      if (tagData != null) {
        try {
          tags.add(Tag(
            name: tagData['name'] ?? 'Unknown',
            type: _normalizeTagType(tagData['type']),
            count: tagData['count'] ?? 0,
            url: _generateTagUrl(tagData['name'], tagData['type']),
          ));
        } catch (e) {
          _logger.w('Failed to resolve tag ID $tagId: $e');
        }
      } else {
        _logger.d('Tag ID $tagId not found in mapping');
      }
    }

    _logger.d('Resolved ${tags.length} tags from ${tagIds.length} tag IDs');
    return tags;
  }

  /// Get tag by ID
  Future<Tag?> getTagById(String tagId) async {
    final tagMapping = await getTagMapping();
    final tagData = tagMapping[tagId];

    if (tagData == null) return null;

    try {
      return Tag(
        name: tagData['name'] ?? 'Unknown',
        type: _normalizeTagType(tagData['type']),
        count: tagData['count'] ?? 0,
        url: _generateTagUrl(tagData['name'], tagData['type']),
      );
    } catch (e) {
      _logger.w('Failed to create tag from ID $tagId: $e');
      return null;
    }
  }

  /// Search tags by name (fuzzy search)
  Future<List<Tag>> searchTags(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    final tagMapping = await getTagMapping();
    final results = <Tag>[];
    final queryLower = query.toLowerCase();

    for (final entry in tagMapping.entries) {
      final tagData = entry.value;
      final tagName = tagData['name']?.toString().toLowerCase() ?? '';

      if (tagName.contains(queryLower)) {
        try {
          results.add(Tag(
            name: tagData['name'] ?? 'Unknown',
            type: _normalizeTagType(tagData['type']),
            count: tagData['count'] ?? 0,
            url: _generateTagUrl(tagData['name'], tagData['type']),
          ));

          if (results.length >= limit) break;
        } catch (e) {
          _logger.w('Failed to create tag from search result: $e');
        }
      }
    }

    // Sort by count (popularity) descending
    results.sort((a, b) => b.count.compareTo(a.count));

    _logger.d('Found ${results.length} tags matching "$query"');
    return results;
  }

  /// Get tags by type
  Future<List<Tag>> getTagsByType(String type, {int limit = 100}) async {
    final tagMapping = await getTagMapping();
    final results = <Tag>[];
    final normalizedType = _normalizeTagType(type);

    for (final entry in tagMapping.entries) {
      final tagData = entry.value;
      final tagType = _normalizeTagType(tagData['type']);

      if (tagType == normalizedType) {
        try {
          results.add(Tag(
            name: tagData['name'] ?? 'Unknown',
            type: normalizedType,
            count: tagData['count'] ?? 0,
            url: _generateTagUrl(tagData['name'], tagData['type']),
          ));

          if (results.length >= limit) break;
        } catch (e) {
          _logger.w('Failed to create tag from type filter: $e');
        }
      }
    }

    // Sort by count (popularity) descending
    results.sort((a, b) => b.count.compareTo(a.count));

    _logger.d('Found ${results.length} tags of type "$type"');
    return results;
  }

  /// Clear memory cache
  void clearCache() {
    _tagMapping = null;
    _lastCacheUpdate = null;
    _logger.d('Cleared tag mapping memory cache');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final tagMapping = await getTagMapping();

    return {
      'total_tags': tagMapping.length,
      'in_memory_cache': _tagMapping != null,
      'last_update': _lastCacheUpdate?.toIso8601String(),
      'source': 'local_asset',
    };
  }

  /// Load tag mapping from local asset
  Future<Map<String, Map<String, dynamic>>?> _loadFromLocalAsset() async {
    try {
      _logger.d('Loading tag mapping from local asset: $_localTagsAsset');

      final jsonString = await rootBundle.loadString(_localTagsAsset);
      final jsonData = jsonDecode(jsonString) as List<dynamic>;

      final mapping = <String, Map<String, dynamic>>{};

      // Convert array format [id, name, count, type] to mapping format
      for (final item in jsonData) {
        if (item is List && item.length >= 4) {
          final id = item[0].toString();
          final name = item[1].toString();
          final count = item[2] as int? ?? 0;
          final typeCode = item[3] as int? ?? 3;

          // Convert type code to type name
          final type = _convertTypeCodeToName(typeCode);

          mapping[id] = {
            'name': name,
            'type': type,
            'count': count,
          };
        }
      }

      _logger.d('Loaded ${mapping.length} tag mappings from local asset');
      return mapping;
    } catch (e) {
      _logger.w('Failed to load from local asset: $e');
      return null;
    }
  }

  /// Convert type code from local asset to type name
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

  /// Normalize tag type
  String _normalizeTagType(dynamic type) {
    if (type == null) return 'tag';

    final typeStr = type.toString().toLowerCase();

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
      default:
        return typeStr;
    }
  }

  /// Generate tag URL
  String _generateTagUrl(dynamic name, dynamic type) {
    if (name == null) return '/';

    final tagName = name.toString().replaceAll(' ', '-').toLowerCase();
    final tagType = _normalizeTagType(type);

    switch (tagType) {
      case 'artist':
        return '/artist/$tagName/';
      case 'character':
        return '/character/$tagName/';
      case 'parody':
        return '/parody/$tagName/';
      case 'group':
        return '/group/$tagName/';
      case 'language':
        return '/language/$tagName/';
      case 'category':
        return '/category/$tagName/';
      default:
        return '/tag/$tagName/';
    }
  }
}
