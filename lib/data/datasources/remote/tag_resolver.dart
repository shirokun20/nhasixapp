import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'package:kuron_core/kuron_core.dart';

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
            id: tagData['id'] ?? 0,
            name: tagData['name'] ?? 'Unknown',
            type: _normalizeTagType(tagData['type']),
            count: tagData['count'] ?? 0,
            url: _generateTagUrl(tagData['slug'], tagData['type']),
            slug: tagData['slug'],
          ));
        } catch (e, stackTrace) {
          _logger.w('Failed to resolve tag ID $tagId: $e, and $stackTrace');
        }
      } else {
        // _logger.d('Tag ID $tagId not found in mapping');
      }
    }

    // _logger.d('Resolved ${tags.length} tags from ${tagIds.length} tag IDs');
    return tags;
  }

  /// Get tag by ID
  Future<Tag?> getTagById(String tagId) async {
    try {
      final tagMapping = await getTagMapping();
      final tagData = tagMapping[tagId];

      if (tagData == null) {
        _logger.d('Tag with ID $tagId not found');
        return null;
      }

      return Tag(
        id: tagData['id'] ?? 0,
        name: tagData['name'] ?? 'Unknown',
        type: _normalizeTagType(tagData['type']),
        count: tagData['count'] ?? 0,
        url: _generateTagUrl(tagData['slug'], tagData['type']),
        slug: tagData['slug'],
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get tag by ID $tagId',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get tag statistics by type
  Future<Map<String, int>> getTagTypeStats() async {
    try {
      final tagMapping = await getTagMapping();
      final stats = <String, int>{};

      _logger.d('Calculating tag type statistics');

      for (final entry in tagMapping.entries) {
        final tagData = entry.value;
        final tagType = _normalizeTagType(tagData['type']);

        stats[tagType] = (stats[tagType] ?? 0) + 1;
      }

      _logger.d('Tag type statistics: $stats');
      return stats;
    } catch (e, stackTrace) {
      _logger.e('Error calculating tag type statistics',
          error: e, stackTrace: stackTrace);
      return {};
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
            id: tagData['id'] ?? 0,
            name: tagData['name'] ?? 'Unknown',
            type: _normalizeTagType(tagData['type']),
            count: tagData['count'] ?? 0,
            url: _generateTagUrl(tagData['slug'], tagData['type']),
            slug: tagData['slug'],
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

  /// Search across all tag types simultaneously with type information
  Future<List<Tag>> searchAllTags(
    String query, {
    int limit = 50,
    bool caseSensitive = false,
    String? typeFilter,
  }) async {
    if (query.isEmpty) return [];

    try {
      final tagMapping = await getTagMapping();
      final results = <Tag>[];
      final queryToMatch = caseSensitive ? query : query.toLowerCase();

      _logger.d(
          'Searching all tags for query: "$query" (case sensitive: $caseSensitive, type filter: $typeFilter)');

      for (final entry in tagMapping.entries) {
        final tagData = entry.value;
        final tagName = tagData['name']?.toString() ?? '';
        final tagType = _normalizeTagType(tagData['type']);

        // Apply type filter if specified
        if (typeFilter != null && tagType != _normalizeTagType(typeFilter)) {
          continue;
        }

        final nameToMatch = caseSensitive ? tagName : tagName.toLowerCase();

        if (nameToMatch.contains(queryToMatch)) {
          try {
            final tag = Tag(
              id: tagData['id'] ?? 0,
              name: tagName,
              type: tagType,
              count: tagData['count'] ?? 0,
              url: _generateTagUrl(tagData['slug'], tagData['type']),
              slug: tagData['slug'],
            );

            results.add(tag);

            if (results.length >= limit) break;
          } catch (e, stackTrace) {
            _logger.w('Failed to create tag from search result: $e',
                stackTrace: stackTrace);
          }
        }
      }

      // Sort by relevance: exact matches first, then by popularity
      results.sort((a, b) {
        final aExact = caseSensitive
            ? a.name == query
            : a.name.toLowerCase() == queryToMatch;
        final bExact = caseSensitive
            ? b.name == query
            : b.name.toLowerCase() == queryToMatch;

        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        // If both exact or both not exact, sort by popularity
        return b.count.compareTo(a.count);
      });

      _logger
          .d('Found ${results.length} tags across all types matching "$query"');
      return results;
    } catch (e, stackTrace) {
      _logger.e('Error searching all tags for query "$query"',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all tags from all types with type information
  Future<List<Tag>> getAllTags({
    int offset = 0,
    int limit = 1000,
  }) async {
    try {
      final tagMapping = await getTagMapping();
      final results = <Tag>[];

      _logger.d('Getting all tags with offset: $offset, limit: $limit');

      final entries = tagMapping.entries.skip(offset).take(limit);

      for (final entry in entries) {
        final tagData = entry.value;

        try {
          final tag = Tag(
            id: tagData['id'] ?? 0,
            name: tagData['name'] ?? 'Unknown',
            type: _normalizeTagType(tagData['type']),
            count: tagData['count'] ?? 0,
            url: _generateTagUrl(tagData['slug'], tagData['type']),
            slug: tagData['slug'],
          );

          results.add(tag);
        } catch (e, stackTrace) {
          _logger.w('Failed to create tag from data: $e',
              stackTrace: stackTrace);
        }
      }

      // Sort by popularity descending
      results.sort((a, b) => b.count.compareTo(a.count));

      _logger.d('Retrieved ${results.length} tags from all types');
      return results;
    } catch (e, stackTrace) {
      _logger.e('Error getting all tags', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get tags by type with enhanced filtering and pagination
  /// Example usage: final tags = await tagResolver.getTagsByType('category');
  Future<List<Tag>> getTagsByType(
    String type, {
    int offset = 0,
    int limit = 100,
    String? searchQuery,
  }) async {
    try {
      final tagMapping = await getTagMapping();
      final results = <Tag>[];
      final normalizedType = _normalizeTagType(type);
      final queryLower = searchQuery?.toLowerCase();

      _logger.d(
          'Getting tags by type: "$type" (offset: $offset, limit: $limit, search: "$searchQuery")');

      int currentOffset = 0;
      for (final entry in tagMapping.entries) {
        final tagData = entry.value;
        final tagType = _normalizeTagType(tagData['type']);

        if (tagType == normalizedType) {
          // Apply search filter if provided
          if (queryLower != null) {
            final tagName = tagData['name']?.toString().toLowerCase() ?? '';
            if (!tagName.contains(queryLower)) {
              continue;
            }
          }

          // Apply offset
          if (currentOffset < offset) {
            currentOffset++;
            continue;
          }

          try {
            results.add(Tag(
              id: tagData['id'] ?? 0,
              name: tagData['name'] ?? 'Unknown',
              type: normalizedType,
              count: tagData['count'] ?? 0,
              url: _generateTagUrl(tagData['slug'], tagData['type']),
              slug: tagData['slug'],
            ));

            if (results.length >= limit) break;
          } catch (e, stackTrace) {
            _logger.w('Failed to create tag from type filter: $e',
                stackTrace: stackTrace);
          }
        }
      }

      // Sort by count (popularity) descending
      results.sort((a, b) => b.count.compareTo(a.count));

      _logger.d('Found ${results.length} tags of type "$type"');
      return results;
    } catch (e, stackTrace) {
      _logger.e('Error getting tags by type "$type"',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Clear memory cache
  void clearCache() {
    _tagMapping = null;
    _lastCacheUpdate = null;
    _logger.d('Cleared tag mapping memory cache');
  }

  /// Get cache statistics with detailed information
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final tagMapping = await getTagMapping();
      final typeStats = await getTagTypeStats();

      return {
        'total_tags': tagMapping.length,
        'in_memory_cache': _tagMapping != null,
        'last_update': _lastCacheUpdate?.toIso8601String(),
        'source': 'local_asset',
        'type_breakdown': typeStats,
        'cache_size_mb': _tagMapping != null
            ? (_tagMapping!.toString().length / (1024 * 1024))
                .toStringAsFixed(2)
            : '0',
      };
    } catch (e, stackTrace) {
      _logger.e('Error getting cache statistics',
          error: e, stackTrace: stackTrace);
      return {
        'total_tags': 0,
        'in_memory_cache': false,
        'error': e.toString(),
      };
    }
  }

  /// Load tag mapping from local asset with enhanced error handling
  Future<Map<String, Map<String, dynamic>>?> _loadFromLocalAsset() async {
    try {
      _logger.d('Loading tag mapping from local asset: $_localTagsAsset');

      final jsonString = await rootBundle.loadString(_localTagsAsset);
      final jsonData = jsonDecode(jsonString) as List<dynamic>;

      final mapping = <String, Map<String, dynamic>>{};
      int invalidEntries = 0;

      // Convert array format [id, name, slug, type] to mapping format
      for (int i = 0; i < jsonData.length; i++) {
        final item = jsonData[i];

        if (item is List && item.length >= 4) {
          try {
            final id = item[0].toString();
            final name = item[1].toString();
            final slug = item[2].toString();
            final typeCode = item[3] as int? ?? 3;

            // Validate required fields
            if (id.isEmpty || name.isEmpty) {
              invalidEntries++;
              continue;
            }

            // Convert type code to type name
            final type = _convertTypeCodeToName(typeCode);

            mapping[id] = {
              'id': int.tryParse(id) ?? 0,
              'name': name,
              'type': type,
              'slug': slug,
              'count': 0, // Default count, could be enhanced later
            };
          } catch (e) {
            _logger.w('Failed to process tag entry at index $i: $e');
            invalidEntries++;
          }
        } else {
          _logger.w(
              'Invalid tag entry format at index $i: expected List with 4+ elements');
          invalidEntries++;
        }
      }

      if (invalidEntries > 0) {
        _logger.w('Skipped $invalidEntries invalid tag entries during loading');
      }

      _logger.d(
          'Successfully loaded ${mapping.length} tag mappings from local asset');
      return mapping;
    } catch (e, stackTrace) {
      _logger.e('Failed to load tag mapping from local asset',
          error: e, stackTrace: stackTrace);
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
