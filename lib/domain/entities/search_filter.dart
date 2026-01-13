import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_filter.freezed.dart';
part 'search_filter.g.dart';

/// Filter item for tagging and categorization
@freezed
abstract class FilterItem with _$FilterItem {
  const factory FilterItem({
    required String value,
    required bool isExcluded,
  }) = _FilterItem;

  /// Create an included filter item
  factory FilterItem.include(String value) =>
      FilterItem(value: value, isExcluded: false);

  /// Create an excluded filter item
  factory FilterItem.exclude(String value) =>
      FilterItem(value: value, isExcluded: true);

  factory FilterItem.fromJson(Map<String, dynamic> json) =>
      _$FilterItemFromJson(json);
}

/// Extension for FilterItem helper methods
extension FilterItemExtension on FilterItem {
  /// Get prefix for query string
  String get prefix => isExcluded ? '-' : '';
}

/// Search filter entity for advanced content filtering
@freezed
abstract class SearchFilter with _$SearchFilter {
  const factory SearchFilter({
    String? query,
    @Default([]) List<FilterItem> tags,
    @Default([]) List<FilterItem> artists,
    @Default([]) List<FilterItem> characters,
    @Default([]) List<FilterItem> parodies,
    @Default([]) List<FilterItem> groups,
    String? language, // Single select only
    String? category, // Single select only
    String? genre, // Single select only
    @Default(1) int page,
    @Default(SortOption.newest) SortOption sortBy,
    @Default(false) bool popular, // Popular filter
    IntRange? pageCountRange,
    @Default(SearchSource.unknown)
    SearchSource source, // Navigation source tracking
    @Default(false)
    bool highlightMode, // Enable blur effect for excluded content
    String?
        highlightQuery, // Specific query to highlight (can differ from main query)
  }) = _SearchFilter;

  factory SearchFilter.fromJson(Map<String, dynamic> json) =>
      _$SearchFilterFromJson(json);
}

/// Extension for SearchFilter helper methods
extension SearchFilterExtension on SearchFilter {
  /// Check if filter is empty (no criteria set)
  bool get isEmpty {
    return query == null &&
        tags.isEmpty &&
        artists.isEmpty &&
        characters.isEmpty &&
        parodies.isEmpty &&
        groups.isEmpty &&
        language == null &&
        category == null &&
        genre == null &&
        !popular &&
        pageCountRange == null &&
        !highlightMode &&
        highlightQuery == null;
  }

  /// Check if filter has any criteria
  bool get hasFilters => !isEmpty;

  /// Get total number of active filters
  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (tags.isNotEmpty) count++;
    if (artists.isNotEmpty) count++;
    if (characters.isNotEmpty) count++;
    if (parodies.isNotEmpty) count++;
    if (groups.isNotEmpty) count++;
    if (language != null) count++;
    if (category != null) count++;
    if (genre != null) count++;
    if (popular) count++;
    if (pageCountRange != null) count++;
    if (highlightMode) count++;
    return count;
  }

  /// Clear all filters
  SearchFilter clear() {
    return const SearchFilter();
  }

  /// Reset to first page
  SearchFilter resetPage() {
    return copyWith(page: 1);
  }

  /// Go to next page
  SearchFilter nextPage() {
    return copyWith(page: page + 1);
  }

  /// Go to previous page
  SearchFilter previousPage() {
    return copyWith(page: page > 1 ? page - 1 : 1);
  }

  /// Validate filter according to Matrix Filter Support rules
  FilterValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate single select filters
    if (language != null && language!.isEmpty) {
      errors.add('Language cannot be empty');
    }

    if (category != null && category!.isEmpty) {
      errors.add('Category cannot be empty');
    }

    // Validate multiple select filters
    if (tags.any((item) => item.value.isEmpty)) {
      errors.add('Tag values cannot be empty');
    }

    if (artists.any((item) => item.value.isEmpty)) {
      errors.add('Artist values cannot be empty');
    }

    if (characters.any((item) => item.value.isEmpty)) {
      errors.add('Character values cannot be empty');
    }

    if (parodies.any((item) => item.value.isEmpty)) {
      errors.add('Parody values cannot be empty');
    }

    if (groups.any((item) => item.value.isEmpty)) {
      errors.add('Group values cannot be empty');
    }

    // Check for duplicate values in multiple select filters
    final tagValues = tags.map((item) => item.value).toList();
    if (tagValues.length != tagValues.toSet().length) {
      warnings.add('Duplicate tag values detected');
    }

    final artistValues = artists.map((item) => item.value).toList();
    if (artistValues.length != artistValues.toSet().length) {
      warnings.add('Duplicate artist values detected');
    }

    final characterValues = characters.map((item) => item.value).toList();
    if (characterValues.length != characterValues.toSet().length) {
      warnings.add('Duplicate character values detected');
    }

    final parodyValues = parodies.map((item) => item.value).toList();
    if (parodyValues.length != parodyValues.toSet().length) {
      warnings.add('Duplicate parody values detected');
    }

    final groupValues = groups.map((item) => item.value).toList();
    if (groupValues.length != groupValues.toSet().length) {
      warnings.add('Duplicate group values detected');
    }

    // Validate page range
    if (page < 1) {
      errors.add('Page number must be greater than 0');
    }

    // Validate page count range
    if (pageCountRange != null) {
      final range = pageCountRange!;
      if (range.min != null && range.min! < 1) {
        errors.add('Minimum page count must be greater than 0');
      }
      if (range.max != null && range.max! < 1) {
        errors.add('Maximum page count must be greater than 0');
      }
      if (range.min != null && range.max != null && range.min! > range.max!) {
        errors.add('Minimum page count cannot be greater than maximum');
      }
    }

    return FilterValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Check if filter type supports multiple values
  static bool isMultipleSelectFilter(String filterType) {
    switch (filterType.toLowerCase()) {
      case 'tag':
      case 'artist':
      case 'character':
      case 'parody':
      case 'group':
        return true;
      case 'language':
      case 'category':
        return false;
      default:
        return false;
    }
  }

  /// Check if filter type supports include/exclude
  static bool supportsIncludeExclude(String filterType) {
    switch (filterType.toLowerCase()) {
      case 'tag':
      case 'artist':
      case 'character':
      case 'parody':
      case 'group':
        return true;
      case 'language':
      case 'category':
        return false;
      default:
        return false;
    }
  }

  /// Convert to query string for URL (using SearchQueryBuilder)
  String toQueryString() {
    return _buildUrlQuery();
  }

  /// Build query string according to Matrix Filter Support rules
  /// Output format: "+-tag:"a1"+-artist:"b1"+language:"english""
  String buildQueryString() {
    return _buildQuery();
  }

  /// Build URL query string with all parameters
  String _buildUrlQuery() {
    final params = <String>[];

    // Build main query part using SearchQueryBuilder
    final queryString = _buildQuery();
    if (queryString.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(queryString)}');
    }

    // Add other parameters
    if (popular) {
      params.add('popular=true');
    }

    params.add('sort=${sortBy.apiValue}');
    params.add('page=$page');

    return params.join('&');
  }

  /// Build query string from SearchFilter according to Matrix Filter Support rules
  String _buildQuery() {
    final queryParts = <String>[];

    // Add text query if present (no prefix)
    if (query != null && query!.isNotEmpty) {
      queryParts.add(query!);
    }

    // Add tags with include/exclude (multiple allowed)
    for (final tag in tags) {
      queryParts.add('${tag.prefix}tag:"${tag.value}"');
    }

    // Add artists with include/exclude (multiple allowed)
    for (final artist in artists) {
      queryParts.add('${artist.prefix}artist:"${artist.value}"');
    }

    // Add characters with include/exclude (multiple allowed)
    for (final character in characters) {
      queryParts.add('${character.prefix}character:"${character.value}"');
    }

    // Add parodies with include/exclude (multiple allowed)
    for (final parody in parodies) {
      queryParts.add('${parody.prefix}parody:"${parody.value}"');
    }

    // Add groups with include/exclude (multiple allowed)
    for (final group in groups) {
      queryParts.add('${group.prefix}group:"${group.value}"');
    }

    // Add single select filters (no prefix, only one allowed)
    if (language != null) {
      queryParts.add('language:"$language"');
    }

    if (category != null) {
      queryParts.add('category:"$category"');
    }

    if (genre != null) {
      queryParts.add('genre:"$genre"');
    }

    return queryParts.join(' ');
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'tags': tags.map((item) => item.toJson()).toList(),
      'artists': artists.map((item) => item.toJson()).toList(),
      'characters': characters.map((item) => item.toJson()).toList(),
      'parodies': parodies.map((item) => item.toJson()).toList(),
      'groups': groups.map((item) => item.toJson()).toList(),
      'language': language,
      'category': category,
      'genre': genre,
      'page': page,
      'sortBy': sortBy.name,
      'popular': popular,
      'pageCountRange': pageCountRange?.toJson(),
      'source': source.apiValue,
      'highlightMode': highlightMode,
      'highlightQuery': highlightQuery,
    };
  }
}

/// Sort options for content
enum SortOption {
  newest,
  popular,
  popularWeek,
  popularToday,
}

/// Navigation source for search filter
enum SearchSource {
  searchScreen,
  detailScreen,
  homeScreen,
  unknown,
}

/// Extension for SearchSource display names
extension SearchSourceExtension on SearchSource {
  String get displayName {
    switch (this) {
      case SearchSource.searchScreen:
        return 'Search Screen';
      case SearchSource.detailScreen:
        return 'Detail Screen';
      case SearchSource.homeScreen:
        return 'Home Screen';
      case SearchSource.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case SearchSource.searchScreen:
        return 'search';
      case SearchSource.detailScreen:
        return 'detail';
      case SearchSource.homeScreen:
        return 'home';
      case SearchSource.unknown:
        return 'unknown';
    }
  }
}

/// Extension for SortOption display names
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.newest:
        return 'Newest';
      case SortOption.popular:
        return 'Popular';
      case SortOption.popularWeek:
        return 'Popular This Week';
      case SortOption.popularToday:
        return 'Popular Today';
    }
  }

  String get apiValue {
    switch (this) {
      case SortOption.newest:
        return ''; // Recent is default, no sort parameter needed
      case SortOption.popular:
        return 'popular';
      case SortOption.popularWeek:
        return 'popular-week';
      case SortOption.popularToday:
        return 'popular-today';
    }
  }
}

/// Integer range for filtering
@freezed
abstract class IntRange with _$IntRange {
  const factory IntRange({
    int? min,
    int? max,
  }) = _IntRange;

  factory IntRange.fromJson(Map<String, dynamic> json) =>
      _$IntRangeFromJson(json);
}

/// Extension for IntRange helper methods
extension IntRangeExtension on IntRange {
  /// Check if value is within range
  bool contains(int value) {
    if (min != null && value < min!) return false;
    if (max != null && value > max!) return false;
    return true;
  }

  /// Check if range is valid
  bool get isValid {
    if (min == null && max == null) return false;
    if (min != null && max != null && min! > max!) return false;
    return true;
  }

  /// Get display string
  String get displayString {
    if (min != null && max != null) {
      return '$min - $max pages';
    } else if (min != null) {
      return '$min+ pages';
    } else if (max != null) {
      return 'Up to $max pages';
    }
    return '';
  }
}

/// Result of filter validation
@freezed
abstract class FilterValidationResult with _$FilterValidationResult {
  const factory FilterValidationResult({
    required bool isValid,
    required List<String> errors,
    required List<String> warnings,
  }) = _FilterValidationResult;

  factory FilterValidationResult.fromJson(Map<String, dynamic> json) =>
      _$FilterValidationResultFromJson(json);
}

/// Extension for FilterValidationResult helper methods
extension FilterValidationResultExtension on FilterValidationResult {
  /// Check if has any issues
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;

  /// Get all issues as formatted string
  String get issuesText {
    final issues = <String>[];

    if (errors.isNotEmpty) {
      issues.add('Errors: ${errors.join(', ')}');
    }

    if (warnings.isNotEmpty) {
      issues.add('Warnings: ${warnings.join(', ')}');
    }

    return issues.join('\n');
  }
}
