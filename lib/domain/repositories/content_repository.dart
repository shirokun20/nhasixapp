import '../entities/entities.dart';
import '../value_objects/value_objects.dart';

/// Repository interface for content-related operations
abstract class ContentRepository {
  /// Get paginated list of content
  ///
  /// [page] - Page number (1-based)
  /// [sortBy] - Sort option for content ordering
  /// Returns list of content with pagination info
  Future<ContentListResult> getContentList({
    int page = 1,
    SortOption sortBy = SortOption.newest,
  });

  /// Get content detail by ID
  ///
  /// [contentId] - Unique content identifier
  /// Returns detailed content information
  Future<Content> getContentDetail(ContentId contentId, {String? sourceId});

  /// Search content with advanced filters
  ///
  /// [filter] - Search filter with criteria
  /// Returns filtered content list with pagination
  Future<ContentListResult> searchContent(SearchFilter filter);

  /// Get random content
  ///
  /// [count] - Number of random content to fetch (default: 1)
  /// Returns list of random content
  Future<List<Content>> getRandomContent({int count = 1});

  /// Get popular content
  ///
  /// [timeframe] - Popularity timeframe (all-time, week, today)
  /// [page] - Page number for pagination
  /// Returns popular content list
  Future<ContentListResult> getPopularContent({
    PopularTimeframe timeframe = PopularTimeframe.allTime,
    int page = 1,
  });

  /// Get content by specific tag
  ///
  /// [tag] - Tag to filter by
  /// [page] - Page number for pagination
  /// [sortBy] - Sort option
  /// Returns content list filtered by tag
  Future<ContentListResult> getContentByTag({
    required Tag tag,
    int page = 1,
    SortOption sortBy = SortOption.newest,
  });

  /// Get related content based on tags and artists
  ///
  /// [contentId] - Reference content ID
  /// [limit] - Maximum number of related content (default: 10)
  /// Returns list of related content
  Future<List<Content>> getRelatedContent({
    required ContentId contentId,
    int limit = 10,
  });

  /// Get all available tags with counts
  ///
  /// [type] - Filter by tag type (optional)
  /// [sortBy] - Sort tags by count or name
  /// Returns list of tags with popularity counts
  Future<List<Tag>> getAllTags({
    String? type,
    TagSortOption sortBy = TagSortOption.count,
  });

  /// Check if content exists and is accessible
  ///
  /// [contentId] - Content ID to verify
  /// Returns true if content exists and accessible
  Future<bool> verifyContentExists(ContentId contentId);

  /// Get chapter images
  ///
  /// [chapterId] - Chapter ID
  /// [sourceId] - Optional source ID
  /// Returns list of image URLs for the chapter
  Future<List<String>> getChapterImages(ContentId chapterId,
      {String? sourceId});
}

/// Result wrapper for paginated content lists
class ContentListResult {
  const ContentListResult({
    required this.contents,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final List<Content> contents;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;

  /// Check if result is empty
  bool get isEmpty => contents.isEmpty;

  /// Check if result has content
  bool get isNotEmpty => contents.isNotEmpty;

  /// Get content count in current page
  int get count => contents.length;

  /// Create empty result
  factory ContentListResult.empty() {
    return const ContentListResult(
      contents: [],
      currentPage: 1,
      totalPages: 0,
      totalCount: 0,
    );
  }

  /// Create single page result
  factory ContentListResult.single(List<Content> contents) {
    return ContentListResult(
      contents: contents,
      currentPage: 1,
      totalPages: 1,
      totalCount: contents.length,
    );
  }
}

/// Popular content timeframe options
enum PopularTimeframe {
  allTime,
  week,
  today,
}

/// Tag sorting options
enum TagSortOption {
  count,
  name,
  recent,
}

/// Content statistics
class ContentStatistics {
  const ContentStatistics({
    required this.totalContent,
    required this.totalTags,
    required this.totalArtists,
    required this.averagePages,
    required this.mostPopularTags,
    required this.mostPopularArtists,
    required this.languageDistribution,
    required this.categoryDistribution,
    this.lastUpdated,
  });

  final int totalContent;
  final int totalTags;
  final int totalArtists;
  final double averagePages;
  final List<Tag> mostPopularTags;
  final List<String> mostPopularArtists;
  final Map<String, int> languageDistribution;
  final Map<String, int> categoryDistribution;
  final DateTime? lastUpdated;

  /// Get total pages across all content
  int get totalPages => (totalContent * averagePages).round();

  /// Get most popular language
  String? get mostPopularLanguage {
    if (languageDistribution.isEmpty) return null;
    return languageDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most popular category
  String? get mostPopularCategory {
    if (categoryDistribution.isEmpty) return null;
    return categoryDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Extensions for PopularTimeframe
extension PopularTimeframeExtension on PopularTimeframe {
  String get displayName {
    switch (this) {
      case PopularTimeframe.allTime:
        return 'All Time';
      case PopularTimeframe.week:
        return 'This Week';
      case PopularTimeframe.today:
        return 'Today';
    }
  }

  String get apiValue {
    switch (this) {
      case PopularTimeframe.allTime:
        return 'all';
      case PopularTimeframe.week:
        return 'week';
      case PopularTimeframe.today:
        return 'today';
    }
  }
}

/// Extensions for TagSortOption
extension TagSortOptionExtension on TagSortOption {
  String get displayName {
    switch (this) {
      case TagSortOption.count:
        return 'By Popularity';
      case TagSortOption.name:
        return 'By Name';
      case TagSortOption.recent:
        return 'Recently Used';
    }
  }
}
