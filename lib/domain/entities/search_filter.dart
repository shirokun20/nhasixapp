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

  /// Convert to query string for URL (new format with FilterItem)
  String toQueryString() {
    final queryParts = <String>[];

    // Add text query if present
    if (query != null && query!.isNotEmpty) {
      queryParts.add(query!);
    }

    // Add tags with include/exclude
    for (final tag in tags) {
      queryParts.add('${tag.prefix}tag:"${tag.value}"');
    }

    // Add artists with include/exclude
    for (final artist in artists) {
      queryParts.add('${artist.prefix}artist:"${artist.value}"');
    }

    // Add characters with include/exclude
    for (final character in characters) {
      queryParts.add('${character.prefix}character:"${character.value}"');
    }

    // Add parodies with include/exclude
    for (final parody in parodies) {
      queryParts.add('${parody.prefix}parody:"${parody.value}"');
    }

    // Add groups with include/exclude
    for (final group in groups) {
      queryParts.add('${group.prefix}group:"${group.value}"');
    }

    // Add single select filters
    if (language != null) {
      queryParts.add('language:"$language"');
    }

    if (category != null) {
      queryParts.add('category:"$category"');
    }

    final params = <String>[];

    // Combine all query parts
    if (queryParts.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(queryParts.join(' '))}');
    }

    if (popular) {
      params.add('popular=true');
    }

    params.add('sort=${sortBy.name}');
    params.add('page=$page');

    return params.join('&');
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
