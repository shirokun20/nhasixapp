import 'content.dart';

/// Result wrapper for paginated content lists.
class ContentListResult {
  const ContentListResult({
    required this.contents,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  /// List of content items
  final List<Content> contents;

  /// Current page number (1-indexed)
  final int currentPage;

  /// Total number of pages
  final int totalPages;

  /// Total number of items across all pages
  final int totalCount;

  /// Whether there is a next page
  final bool hasNext;

  /// Whether there is a previous page
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

  ContentListResult copyWith({
    List<Content>? contents,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    return ContentListResult(
      contents: contents ?? this.contents,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
    );
  }
}
