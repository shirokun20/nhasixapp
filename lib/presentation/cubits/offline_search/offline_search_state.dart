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
    this.storageUsage = 0,
    this.formattedStorageUsage = '0 B',
    // NEW: Pagination fields
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedSourceId,
  });

  final String query;
  final List<Content> results;
  final int totalResults;
  final Map<String, String> offlineSizes;
  final int storageUsage;
  final String formattedStorageUsage;
  
  // NEW: Pagination fields
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;

  // NEW: Filter field
  final String? selectedSourceId;

  @override
  List<Object?> get props => [
        query,
        results,
        totalResults,
        offlineSizes,
        storageUsage,
        formattedStorageUsage,
        currentPage,
        totalPages,
        hasMore,
        isLoadingMore,
        selectedSourceId,
      ];

  /// Check if this is a search result or all content
  bool get isSearchResult => query.isNotEmpty;

  /// Get display title for the results
  String get displayTitle {
    if (isSearchResult) {
      if (selectedSourceId != null) {
        return 'Results for "$query" in $selectedSourceId';
      }
      return 'Search Results for "$query"';
    } else {
      if (selectedSourceId != null) {
        return 'Offline Content ($selectedSourceId)';
      }
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
  
  /// Create a copy with updated fields
  OfflineSearchLoaded copyWith({
    String? query,
    List<Content>? results,
    int? totalResults,
    Map<String, String>? offlineSizes,
    int? storageUsage,
    String? formattedStorageUsage,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
    String? selectedSourceId,
    bool clearSourceId = false,
  }) {
    return OfflineSearchLoaded(
      query: query ?? this.query,
      results: results ?? this.results,
      totalResults: totalResults ?? this.totalResults,
      offlineSizes: offlineSizes ?? this.offlineSizes,
      storageUsage: storageUsage ?? this.storageUsage,
      formattedStorageUsage: formattedStorageUsage ?? this.formattedStorageUsage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedSourceId: clearSourceId 
          ? null 
          : (selectedSourceId ?? this.selectedSourceId),
    );
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
