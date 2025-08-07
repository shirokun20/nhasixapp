import 'package:equatable/equatable.dart';

/// Search filter entity for advanced content filtering
class SearchFilter extends Equatable {
  const SearchFilter({
    this.query,
    this.includeTags = const [],
    this.excludeTags = const [],
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
  final List<String> includeTags;
  final List<String> excludeTags;
  final List<String> artists;
  final List<String> characters;
  final List<String> parodies;
  final List<String> groups;
  final String? language;
  final String? category;
  final int page;
  final SortOption sortBy;
  final bool popular; // Popular filter
  final IntRange? pageCountRange;

  @override
  List<Object?> get props => [
        query,
        includeTags,
        excludeTags,
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

  SearchFilter copyWith({
    String? query,
    List<String>? includeTags,
    List<String>? excludeTags,
    List<String>? artists,
    List<String>? characters,
    List<String>? parodies,
    List<String>? groups,
    String? language,
    String? category,
    int? page,
    SortOption? sortBy,
    bool? popular,
    IntRange? pageCountRange,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      includeTags: includeTags ?? this.includeTags,
      excludeTags: excludeTags ?? this.excludeTags,
      artists: artists ?? this.artists,
      characters: characters ?? this.characters,
      parodies: parodies ?? this.parodies,
      groups: groups ?? this.groups,
      language: language ?? this.language,
      category: category ?? this.category,
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
      popular: popular ?? this.popular,
      pageCountRange: pageCountRange ?? this.pageCountRange,
    );
  }

  /// Check if filter is empty (no criteria set)
  bool get isEmpty {
    return query == null &&
        includeTags.isEmpty &&
        excludeTags.isEmpty &&
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
    if (includeTags.isNotEmpty) count++;
    if (excludeTags.isNotEmpty) count++;
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

  /// Convert to query string for URL
  String toQueryString() {
    final params = <String>[];

    if (query != null && query!.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(query!)}');
    }

    if (includeTags.isNotEmpty) {
      params.add('tags=${Uri.encodeComponent(includeTags.join(','))}');
    }

    if (excludeTags.isNotEmpty) {
      params.add('exclude=${Uri.encodeComponent(excludeTags.join(','))}');
    }

    if (artists.isNotEmpty) {
      params.add('artists=${Uri.encodeComponent(artists.join(','))}');
    }

    if (language != null) {
      params.add('language=${Uri.encodeComponent(language!)}');
    }

    if (category != null) {
      params.add('category=${Uri.encodeComponent(category!)}');
    }

    if (popular) {
      params.add('popular=true');
    }

    params.add('sort=${sortBy.name}');
    params.add('page=$page');

    return params.join('&');
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
}
