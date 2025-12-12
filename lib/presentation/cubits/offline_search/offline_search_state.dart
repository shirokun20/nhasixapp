part of 'offline_search_cubit.dart';

/// Base state for offline search
abstract class OfflineSearchState extends BaseCubitState {
  const OfflineSearchState();
}

/// Initial state before any search
class OfflineSearchInitial extends OfflineSearchState {
  const OfflineSearchInitial();

  @override
  List<Object?> get props => [];
}

/// State when searching offline content
class OfflineSearchLoading extends OfflineSearchState {
  const OfflineSearchLoading();

  @override
  List<Object?> get props => [];
}

/// State when offline search results are loaded
class OfflineSearchLoaded extends OfflineSearchState {
  const OfflineSearchLoaded({
    required this.query,
    required this.results,
    required this.totalResults,
    this.offlineSizes = const {},
  });

  final String query;
  final List<Content> results;
  final int totalResults;
  final Map<String, String> offlineSizes;

  @override
  List<Object?> get props => [query, results, totalResults, offlineSizes];

  /// Check if this is a search result or all content
  bool get isSearchResult => query.isNotEmpty;

  /// Get display title for the results
  String get displayTitle {
    if (isSearchResult) {
      return 'Search Results for "$query"';
    } else {
      return 'Offline Content';
    }
  }

  /// Get results summary
  String get resultsSummary {
    if (totalResults == 0) {
      return 'No content found';
    } else if (totalResults == 1) {
      return '1 item found';
    } else {
      return '$totalResults items found';
    }
  }
}

/// State when no offline content found
class OfflineSearchEmpty extends OfflineSearchState {
  const OfflineSearchEmpty({
    required this.query,
  });

  final String query;

  @override
  List<Object?> get props => [query];

  /// Get empty message based on query
  String get emptyMessage {
    if (query.isEmpty) {
      return 'No offline content available.\nDownload some content to read offline.';
    } else {
      return 'No offline content found for "$query".\nTry a different search term.';
    }
  }
}

/// State when there's an error with offline search
class OfflineSearchError extends OfflineSearchState {
  const OfflineSearchError({
    required this.message,
    required this.query,
  });

  final String message;
  final String query;

  @override
  List<Object?> get props => [message, query];
}
