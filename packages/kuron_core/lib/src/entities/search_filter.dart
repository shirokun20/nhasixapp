import 'package:equatable/equatable.dart';
import '../value_objects/sort_option.dart';
import 'filter_item.dart';

/// Search filter for content queries.
class SearchFilter extends Equatable {
  const SearchFilter({
    this.query = '',
    this.page = 1,
    this.sort = SortOption.newest,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.language,
    this.category,
  });

  /// Search query string
  final String query;

  /// Page number (1-indexed)
  final int page;

  /// Sort option
  final SortOption sort;

  /// Tags to include in search
  final List<FilterItem> includeTags;

  /// Tags to exclude from search
  final List<FilterItem> excludeTags;

  /// Language filter
  final String? language;

  /// Category filter
  final String? category;

  @override
  List<Object?> get props => [
        query,
        page,
        sort,
        includeTags,
        excludeTags,
        language,
        category,
      ];

  SearchFilter copyWith({
    String? query,
    int? page,
    SortOption? sort,
    List<FilterItem>? includeTags,
    List<FilterItem>? excludeTags,
    String? language,
    String? category,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      page: page ?? this.page,
      sort: sort ?? this.sort,
      includeTags: includeTags ?? this.includeTags,
      excludeTags: excludeTags ?? this.excludeTags,
      language: language ?? this.language,
      category: category ?? this.category,
    );
  }

  /// Check if filter has any active filters
  bool get hasFilters =>
      query.isNotEmpty ||
      includeTags.isNotEmpty ||
      excludeTags.isNotEmpty ||
      language != null ||
      category != null;

  /// Create filter for next page
  SearchFilter nextPage() => copyWith(page: page + 1);

  /// Create filter for previous page
  SearchFilter previousPage() => copyWith(page: page > 1 ? page - 1 : 1);

  /// Reset to first page
  SearchFilter resetPage() => copyWith(page: 1);
}
