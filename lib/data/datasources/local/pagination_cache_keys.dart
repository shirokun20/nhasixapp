import 'package:nhasixapp/domain/repositories/repositories.dart';

import '../../../domain/entities/entities.dart';

/// Utility class for generating unique pagination cache keys
class PaginationCacheKeys {
  /// Generate cache key for content list
  static String contentList(int page, SortOption sortBy) {
    return 'content_list_${sortBy.name}_page_$page';
  }

  /// Generate cache key for search results
  static String search(SearchFilter filter) {
    final queryHash = filter.toQueryString().hashCode.abs();
    return 'search_${queryHash}_page_${filter.page}';
  }

  /// Generate cache key for popular content
  static String popular(PopularTimeframe timeframe, int page) {
    return 'popular_${timeframe.name}_page_$page';
  }

  /// Generate cache key for content by tag
  static String byTag(String tagName, int page, SortOption sortBy) {
    final tagHash = tagName.hashCode.abs();
    return 'tag_${tagHash}_${sortBy.name}_page_$page';
  }

  /// Generate cache key for homepage content
  static String homepage() {
    return 'homepage_content';
  }

  /// Generate cache key for random content
  static String random(int count) {
    return 'random_content_$count';
  }

  /// Check if cache key is valid format
  static bool isValidKey(String key) {
    return key.isNotEmpty &&
        key.length <= 255 && // Database constraint
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(key);
  }

  /// Extract page number from cache key
  static int? extractPageFromKey(String key) {
    final match = RegExp(r'_page_(\d+)$').firstMatch(key);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Extract context type from cache key
  static String? extractContextFromKey(String key) {
    if (key.startsWith('content_list_')) return 'content_list';
    if (key.startsWith('search_')) return 'search';
    if (key.startsWith('popular_')) return 'popular';
    if (key.startsWith('tag_')) return 'tag';
    if (key.startsWith('homepage_')) return 'homepage';
    if (key.startsWith('random_')) return 'random';
    return null;
  }

  /// Generate cache key for content list with custom parameters
  static String contentListCustom({
    required int page,
    required SortOption sortBy,
    String? language,
    String? category,
  }) {
    final buffer = StringBuffer('content_list_${sortBy.name}');

    if (language != null && language.isNotEmpty) {
      buffer.write('_lang_${language.hashCode.abs()}');
    }

    if (category != null && category.isNotEmpty) {
      buffer.write('_cat_${category.hashCode.abs()}');
    }

    buffer.write('_page_$page');

    return buffer.toString();
  }

  /// Generate cache key for search with specific filters
  static String searchWithFilters({
    required SearchFilter filter,
    bool includeSort = true,
    bool includeLanguage = true,
  }) {
    final buffer = StringBuffer('search');

    // Add query hash
    if (filter.query != null && filter.query!.isNotEmpty) {
      buffer.write('_q_${filter.query!.hashCode.abs()}');
    }

    // Add include tags
    if (filter.includeTags.isNotEmpty) {
      final tagsHash = filter.includeTags.join(',').hashCode.abs();
      buffer.write('_inc_$tagsHash');
    }

    // Add exclude tags
    if (filter.excludeTags.isNotEmpty) {
      final tagsHash = filter.excludeTags.join(',').hashCode.abs();
      buffer.write('_exc_$tagsHash');
    }

    // Add language
    if (includeLanguage &&
        filter.language != null &&
        filter.language!.isNotEmpty) {
      buffer.write('_lang_${filter.language!.hashCode.abs()}');
    }

    // Add sort option
    if (includeSort) {
      buffer.write('_sort_${filter.sortBy.name}');
    }

    // Add page
    buffer.write('_page_${filter.page}');

    return buffer.toString();
  }

  /// Get all possible cache keys for a content list context
  static List<String> getAllContentListKeys(SortOption sortBy,
      {int maxPages = 100}) {
    return List.generate(
      maxPages,
      (index) => contentList(index + 1, sortBy),
    );
  }

  /// Get cache key pattern for cleanup operations
  static String getPatternForContext(String context) {
    switch (context) {
      case 'content_list':
        return 'content_list_%';
      case 'search':
        return 'search_%';
      case 'popular':
        return 'popular_%';
      case 'tag':
        return 'tag_%';
      case 'homepage':
        return 'homepage_%';
      case 'random':
        return 'random_%';
      default:
        return '%';
    }
  }
}
