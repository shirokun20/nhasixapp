import 'package:equatable/equatable.dart';

/// Filter item with include/exclude functionality
class FilterItem extends Equatable {
  const FilterItem({
    required this.value,
    this.isExcluded = false,
  });

  final String value;
  final bool isExcluded; // true = exclude, false = include

  @override
  List<Object?> get props => [value, isExcluded];

  FilterItem copyWith({
    String? value,
    bool? isExcluded,
  }) {
    return FilterItem(
      value: value ?? this.value,
      isExcluded: isExcluded ?? this.isExcluded,
    );
  }

  /// Create include filter item
  factory FilterItem.include(String value) {
    return FilterItem(value: value, isExcluded: false);
  }

  /// Create exclude filter item
  factory FilterItem.exclude(String value) {
    return FilterItem(value: value, isExcluded: true);
  }

  /// Get prefix for query string
  String get prefix => isExcluded ? '-' : '';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isExcluded': isExcluded,
    };
  }

  /// Create from JSON
  factory FilterItem.fromJson(Map<String, dynamic> json) {
    return FilterItem(
      value: json['value'] as String,
      isExcluded: json['isExcluded'] as bool? ?? false,
    );
  }
}

/// Search filter entity for advanced content filtering
class SearchFilter extends Equatable {
  const SearchFilter({
    this.query,
    this.tags = const [],
    this.artists = const [],
    this.characters = const [],
    this.parodies = const [],
    this.groups = const [],
    this.language,
    this.category,
    this.page = 1,
    this.sortBy = SortOption.newest,
    this.popular = false,
    this.pageCountRange,
  });

  final String? query;
  final List<FilterItem> tags;
  final List<FilterItem> artists;
  final List<FilterItem> characters;
  final List<FilterItem> parodies;
  final List<FilterItem> groups;
  final String? language; // Single select only
  final String? category; // Single select only
  final int page;
  final SortOption sortBy;
  final bool popular; // Popular filter
  final IntRange? pageCountRange;

  @override
  List<Object?> get props => [
        query,
        tags,
        artists,
        characters,
        parodies,
        groups,
        language,
        category,
        page,
        sortBy,
        popular,
        pageCountRange,
      ];

  static const _undefined = Object();

  SearchFilter copyWith({
    String? query,
    List<FilterItem>? tags,
    List<FilterItem>? artists,
    List<FilterItem>? characters,
    List<FilterItem>? parodies,
    List<FilterItem>? groups,
    Object? language = _undefined,
    Object? category = _undefined,
    int? page,
    SortOption? sortBy,
    bool? popular,
    IntRange? pageCountRange,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      tags: tags ?? this.tags,
      artists: artists ?? this.artists,
      characters: characters ?? this.characters,
      parodies: parodies ?? this.parodies,
      groups: groups ?? this.groups,
      language: language == _undefined ? this.language : language as String?,
      category: category == _undefined ? this.category : category as String?,
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
      popular: popular ?? this.popular,
      pageCountRange: pageCountRange ?? this.pageCountRange,
    );
  }

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
        !popular &&
        pageCountRange == null;
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
    if (popular) count++;
    if (pageCountRange != null) count++;
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
      'page': page,
      'sortBy': sortBy.name,
      'popular': popular,
      'pageCountRange': pageCountRange?.toJson(),
    };
  }

  /// Create from JSON for persistence
  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      query: json['query'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((item) => FilterItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      artists: (json['artists'] as List<dynamic>?)
              ?.map((item) => FilterItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((item) => FilterItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      parodies: (json['parodies'] as List<dynamic>?)
              ?.map((item) => FilterItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      groups: (json['groups'] as List<dynamic>?)
              ?.map((item) => FilterItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      language: json['language'] as String?,
      category: json['category'] as String?,
      page: json['page'] as int? ?? 1,
      sortBy: SortOption.values.firstWhere(
        (e) => e.name == json['sortBy'],
        orElse: () => SortOption.newest,
      ),
      popular: json['popular'] as bool? ?? false,
      pageCountRange: json['pageCountRange'] != null
          ? IntRange.fromJson(json['pageCountRange'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Sort options for content
enum SortOption {
  newest,
  popular,
  popularWeek,
  popularToday,
  random,
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
      case SortOption.random:
        return 'Random';
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
      case SortOption.random:
        return 'random';
    }
  }
}

/// Integer range for filtering
class IntRange extends Equatable {
  const IntRange({this.min, this.max});

  final int? min;
  final int? max;

  @override
  List<Object?> get props => [min, max];

  IntRange copyWith({
    int? min,
    int? max,
  }) {
    return IntRange(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

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

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }

  /// Create from JSON
  factory IntRange.fromJson(Map<String, dynamic> json) {
    return IntRange(
      min: json['min'] as int?,
      max: json['max'] as int?,
    );
  }
}

/// Result of filter validation
class FilterValidationResult extends Equatable {
  const FilterValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  @override
  List<Object> get props => [isValid, errors, warnings];

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
