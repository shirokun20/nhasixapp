part of 'search_bloc.dart';

/// Base class for all search states
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial search state
class SearchInitial extends SearchState {
  const SearchInitial();
}

/// Search loading state
class SearchLoading extends SearchState {
  const SearchLoading({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Search results loaded state
class SearchLoaded extends SearchState {
  const SearchLoaded({
    required this.results,
    required this.filter,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNext,
    required this.hasPrevious,
    required this.lastUpdated,
    this.isLoadingMore = false,
    this.suggestions = const [],
    this.tagSuggestions = const [],
  });

  final List<Content> results;
  final SearchFilter filter;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;
  final DateTime lastUpdated;
  final bool isLoadingMore;
  final List<String> suggestions;
  final List<Tag> tagSuggestions;

  @override
  List<Object?> get props => [
        results,
        filter,
        currentPage,
        totalPages,
        totalCount,
        hasNext,
        hasPrevious,
        lastUpdated,
        isLoadingMore,
        suggestions,
        tagSuggestions,
      ];

  /// Check if can load more results
  bool get canLoadMore => hasNext && !isLoadingMore;

  /// Check if has results
  bool get hasResults => results.isNotEmpty;

  /// Get result count text
  String get resultCountText {
    if (totalCount == 0) return 'No results';
    if (totalCount == 1) return '1 result';
    return '$totalCount results';
  }

  /// Get page info text
  String get pageInfoText {
    if (totalPages <= 1) return '';
    return 'Page $currentPage of $totalPages';
  }

  /// Copy with updated properties
  SearchLoaded copyWith({
    List<Content>? results,
    SearchFilter? filter,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? hasNext,
    bool? hasPrevious,
    DateTime? lastUpdated,
    bool? isLoadingMore,
    List<String>? suggestions,
    List<Tag>? tagSuggestions,
  }) {
    return SearchLoaded(
      results: results ?? this.results,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      suggestions: suggestions ?? this.suggestions,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
    );
  }

  /// Copy with more results (for pagination)
  SearchLoaded copyWithMoreResults(List<Content> moreResults) {
    return copyWith(
      results: [...results, ...moreResults],
      isLoadingMore: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// Copy with updated filter and reset results
  SearchLoaded copyWithNewFilter(SearchFilter newFilter) {
    return SearchLoaded(
      results: const [],
      filter: newFilter,
      currentPage: 1,
      totalPages: 0,
      totalCount: 0,
      hasNext: false,
      hasPrevious: false,
      lastUpdated: DateTime.now(),
      isLoadingMore: false,
      suggestions: suggestions,
      tagSuggestions: tagSuggestions,
    );
  }
}

/// Search loading more results state
class SearchLoadingMore extends SearchLoaded {
  const SearchLoadingMore({
    required super.results,
    required super.filter,
    required super.currentPage,
    required super.totalPages,
    required super.totalCount,
    required super.hasNext,
    required super.hasPrevious,
    required super.lastUpdated,
    super.suggestions = const [],
    super.tagSuggestions = const [],
  }) : super(isLoadingMore: true);
}

/// Search refreshing state
class SearchRefreshing extends SearchLoaded {
  const SearchRefreshing({
    required super.results,
    required super.filter,
    required super.currentPage,
    required super.totalPages,
    required super.totalCount,
    required super.hasNext,
    required super.hasPrevious,
    required super.lastUpdated,
    super.suggestions = const [],
    super.tagSuggestions = const [],
  });
}

/// Search empty state (no results found)
class SearchEmpty extends SearchState {
  const SearchEmpty({
    required this.filter,
    this.message = 'No results found',
    this.suggestions = const [],
  });

  final SearchFilter filter;
  final String message;
  final List<String> suggestions;

  @override
  List<Object?> get props => [filter, message, suggestions];

  /// Get helpful message based on filter
  String get helpfulMessage {
    if (filter.hasFilters) {
      return 'Try adjusting your search filters or search terms.';
    } else {
      return 'Try searching with different keywords.';
    }
  }

  /// Get filter summary
  String get filterSummary {
    final parts = <String>[];

    if (filter.query != null && filter.query!.isNotEmpty) {
      parts.add('Query: "${filter.query}"');
    }

    if (filter.tags.isNotEmpty) {
      final includeTags = filter.tags
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeTags = filter.tags
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeTags.isNotEmpty) {
        parts.add('Tags: ${includeTags.join(', ')}');
      }
      if (excludeTags.isNotEmpty) {
        parts.add('Exclude Tags: ${excludeTags.join(', ')}');
      }
    }

    if (filter.groups.isNotEmpty) {
      final includeGroups = filter.groups
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeGroups = filter.groups
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeGroups.isNotEmpty) {
        parts.add('Groups: ${includeGroups.join(', ')}');
      }
      if (excludeGroups.isNotEmpty) {
        parts.add('Exclude Groups: ${excludeGroups.join(', ')}');
      }
    }

    if (filter.characters.isNotEmpty) {
      final includeCharacters = filter.characters
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeCharacters = filter.characters
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeCharacters.isNotEmpty) {
        parts.add('Characters: ${includeCharacters.join(', ')}');
      }
      if (excludeCharacters.isNotEmpty) {
        parts.add('Exclude Characters: ${excludeCharacters.join(', ')}');
      }
    }

    if (filter.parodies.isNotEmpty) {
      final includeParodies = filter.parodies
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeParodies = filter.parodies
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeParodies.isNotEmpty) {
        parts.add('Parodies: ${includeParodies.join(', ')}');
      }
      if (excludeParodies.isNotEmpty) {
        parts.add('Exclude Parodies: ${excludeParodies.join(', ')}');
      }
    }

    if (filter.artists.isNotEmpty) {
      final includeArtists = filter.artists
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeArtists = filter.artists
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeArtists.isNotEmpty) {
        parts.add('Artists: ${includeArtists.join(', ')}');
      }
      if (excludeArtists.isNotEmpty) {
        parts.add('Exclude Artists: ${excludeArtists.join(', ')}');
      }
    }

    if (filter.language != null) {
      parts.add('Language: ${filter.language}');
    }

    if (filter.category != null) {
      parts.add('Category: ${filter.category}');
    }

    return parts.join(' • ');
  }
}

/// Search error state
class SearchError extends SearchState {
  const SearchError({
    required this.message,
    required this.errorType,
    this.canRetry = true,
    this.previousResults,
    this.filter,
    this.stackTrace,
  });

  final String message;
  final SearchErrorType errorType;
  final bool canRetry;
  final List<Content>? previousResults;
  final SearchFilter? filter;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [
        message,
        errorType,
        canRetry,
        previousResults,
        filter,
        stackTrace,
      ];

  /// Check if has previous results to show
  bool get hasPreviousResults =>
      previousResults != null && previousResults!.isNotEmpty;

  /// Get user-friendly error message
  String get userMessage {
    switch (errorType) {
      case SearchErrorType.network:
        return 'Network error. Please check your connection and try again.';
      case SearchErrorType.server:
        return 'Server error. Please try again later.';
      case SearchErrorType.cloudflare:
        return 'Access blocked. Trying to bypass protection...';
      case SearchErrorType.rateLimit:
        return 'Too many requests. Please wait a moment and try again.';
      case SearchErrorType.parsing:
        return 'Error processing search results. Please try again.';
      case SearchErrorType.validation:
        return 'Invalid search parameters. Please check your input.';
      case SearchErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get retry button text
  String get retryButtonText {
    switch (errorType) {
      case SearchErrorType.cloudflare:
        return 'Retry Bypass';
      case SearchErrorType.network:
        return 'Retry Connection';
      case SearchErrorType.server:
      case SearchErrorType.rateLimit:
      case SearchErrorType.parsing:
      case SearchErrorType.validation:
      case SearchErrorType.unknown:
        return 'Retry Search';
    }
  }
}

/// Search suggestions state
class SearchSuggestions extends SearchState {
  const SearchSuggestions({
    required this.query,
    required this.suggestions,
    required this.tagSuggestions,
    required this.history,
  });

  final String query;
  final List<String> suggestions;
  final List<Tag> tagSuggestions;
  final List<String> history;

  @override
  List<Object> get props => [query, suggestions, tagSuggestions, history];

  /// Check if has any suggestions
  bool get hasSuggestions =>
      suggestions.isNotEmpty || tagSuggestions.isNotEmpty || history.isNotEmpty;

  /// Get filtered history based on query
  List<String> get filteredHistory {
    if (query.isEmpty) return history;
    return history
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Get filtered tag suggestions based on query
  List<Tag> get filteredTagSuggestions {
    if (query.isEmpty) return tagSuggestions.take(10).toList();
    return tagSuggestions
        .where((tag) => tag.name.toLowerCase().contains(query.toLowerCase()))
        .take(10)
        .toList();
  }

  /// Copy with updated properties
  SearchSuggestions copyWith({
    String? query,
    List<String>? suggestions,
    List<Tag>? tagSuggestions,
    List<String>? history,
  }) {
    return SearchSuggestions(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
      history: history ?? this.history,
    );
  }
}

/// Search history state
class SearchHistory extends SearchState {
  const SearchHistory({
    required this.history,
    required this.popularSearches,
    this.timestamp,
  });

  final List<String> history;
  final List<String> popularSearches;
  final DateTime? timestamp;

  @override
  List<Object?> get props => [history, popularSearches, timestamp];

  /// Check if has history
  bool get hasHistory => history.isNotEmpty;

  /// Check if has popular searches
  bool get hasPopularSearches => popularSearches.isNotEmpty;

  /// Check if has any content
  bool get hasContent => hasHistory || hasPopularSearches;
}

/// Search presets state
class SearchPresets extends SearchState {
  const SearchPresets({
    required this.presets,
  });

  final Map<String, SearchFilter> presets;

  @override
  List<Object> get props => [presets];

  /// Check if has presets
  bool get hasPresets => presets.isNotEmpty;

  /// Get preset names
  List<String> get presetNames => presets.keys.toList()..sort();
}

/// Search filter updated state (new flow - filter updated but no API call yet)
class SearchFilterUpdated extends SearchState {
  const SearchFilterUpdated({
    required this.filter,
    required this.timestamp,
  });

  final SearchFilter filter;
  final DateTime timestamp;

  @override
  List<Object> get props => [filter, timestamp];

  /// Check if filter has any criteria
  bool get hasFilters => filter.hasFilters;

  /// Get filter summary for display
  String get filterSummary {
    final parts = <String>[];

    if (filter.query != null && filter.query!.isNotEmpty) {
      parts.add('Query: "${filter.query}"');
    }

    if (filter.tags.isNotEmpty) {
      final includeTags = filter.tags
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeTags = filter.tags
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeTags.isNotEmpty) {
        parts.add('Tags: ${includeTags.join(', ')}');
      }
      if (excludeTags.isNotEmpty) {
        parts.add('Exclude Tags: ${excludeTags.join(', ')}');
      }
    }

    if (filter.groups.isNotEmpty) {
      final includeGroups = filter.groups
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeGroups = filter.groups
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeGroups.isNotEmpty) {
        parts.add('Groups: ${includeGroups.join(', ')}');
      }
      if (excludeGroups.isNotEmpty) {
        parts.add('Exclude Groups: ${excludeGroups.join(', ')}');
      }
    }

    if (filter.characters.isNotEmpty) {
      final includeCharacters = filter.characters
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeCharacters = filter.characters
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeCharacters.isNotEmpty) {
        parts.add('Characters: ${includeCharacters.join(', ')}');
      }
      if (excludeCharacters.isNotEmpty) {
        parts.add('Exclude Characters: ${excludeCharacters.join(', ')}');
      }
    }

    if (filter.parodies.isNotEmpty) {
      final includeParodies = filter.parodies
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeParodies = filter.parodies
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeParodies.isNotEmpty) {
        parts.add('Parodies: ${includeParodies.join(', ')}');
      }
      if (excludeParodies.isNotEmpty) {
        parts.add('Exclude Parodies: ${excludeParodies.join(', ')}');
      }
    }

    if (filter.artists.isNotEmpty) {
      final includeArtists = filter.artists
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeArtists = filter.artists
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeArtists.isNotEmpty) {
        parts.add('Artists: ${includeArtists.join(', ')}');
      }
      if (excludeArtists.isNotEmpty) {
        parts.add('Exclude Artists: ${excludeArtists.join(', ')}');
      }
    }

    if (filter.language != null) {
      parts.add('Language: ${filter.language}');
    }

    if (filter.category != null) {
      parts.add('Category: ${filter.category}');
    }

    return parts.join(' • ');
  }
}

/// Search error types
enum SearchErrorType {
  network,
  server,
  cloudflare,
  rateLimit,
  parsing,
  validation,
  unknown,
}

/// Extension for SearchErrorType
extension SearchErrorTypeExtension on SearchErrorType {
  /// Check if error is retryable
  bool get isRetryable {
    switch (this) {
      case SearchErrorType.network:
      case SearchErrorType.server:
      case SearchErrorType.cloudflare:
      case SearchErrorType.rateLimit:
      case SearchErrorType.unknown:
        return true;
      case SearchErrorType.parsing:
      case SearchErrorType.validation:
        return false;
    }
  }

  /// Get error icon
  String get icon {
    switch (this) {
      case SearchErrorType.network:
        return '📡';
      case SearchErrorType.server:
        return '🔧';
      case SearchErrorType.cloudflare:
        return '🛡️';
      case SearchErrorType.rateLimit:
        return '⏱️';
      case SearchErrorType.parsing:
        return '📄';
      case SearchErrorType.validation:
        return '⚠️';
      case SearchErrorType.unknown:
        return '❓';
    }
  }
}
