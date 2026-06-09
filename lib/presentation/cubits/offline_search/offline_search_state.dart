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
    required this.items,
    required this.totalResults,
    this.offlineSizes = const {},
    this.storageUsage = 0,
    this.formattedStorageUsage = '0 B',
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.selectedSourceId,
    this.orderBy = 'created_at',
    this.descending = true,
  });

  final String query;
  final List<OfflineLibraryItemData> items;
  final int totalResults;
  final Map<String, String> offlineSizes;
  final int storageUsage;
  final String formattedStorageUsage;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;
  final String? selectedFilterId;
  final OfflineLibrarySortMode sortMode;
  final List<OfflineSourceFilterOption> availableFilters;
  final List<String> displayOrder;
  final Map<String, OfflineLibraryGroupData> groupsByKey;

  List<Content> get results =>
      items.map((item) => item.content).toList(growable: false);

  // NEW: Sorting fields
  final String orderBy;
  final bool descending;

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

  bool get isSearchResult => query.isNotEmpty;

  int get visibleGroupCount => displayOrder.length;

  OfflineSourceFilterOption? get selectedFilterOption {
    if (selectedFilterId == null) {
      return null;
    }
    for (final filter in availableFilters) {
      if (filter.id == selectedFilterId) {
        return filter;
      }
    }
    return null;
  }

  String get displayTitle {
    if (isSearchResult) {
      return 'Search Results for "$query"';
    }
    return 'Offline Content';
  }

  String get resultsSummary {
    if (totalResults == 0) {
      return 'No content found';
    }
    if (visibleGroupCount > 0 && visibleGroupCount != totalResults) {
      return '$visibleGroupCount groups • $totalResults items';
    }
    if (totalResults == 1) {
      return '1 item found';
    }
    return '$totalResults items found';
  }

  OfflineSearchLoaded copyWith({
    String? query,
    List<OfflineLibraryItemData>? items,
    int? totalResults,
    Map<String, String>? offlineSizes,
    int? storageUsage,
    String? formattedStorageUsage,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
    String? selectedSourceId,
    String? orderBy,
    bool? descending,
    bool clearSourceId = false,
  }) {
    return OfflineSearchLoaded(
      query: query ?? this.query,
      items: items ?? this.items,
      totalResults: totalResults ?? this.totalResults,
      offlineSizes: offlineSizes ?? this.offlineSizes,
      storageUsage: storageUsage ?? this.storageUsage,
      formattedStorageUsage:
          formattedStorageUsage ?? this.formattedStorageUsage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedSourceId:
          clearSourceId ? null : (selectedSourceId ?? this.selectedSourceId),
      orderBy: orderBy ?? this.orderBy,
      descending: descending ?? this.descending,
    );
  }

  @override
  List<Object?> get props => [
        query,
        items,
        totalResults,
        offlineSizes,
        storageUsage,
        formattedStorageUsage,
        currentPage,
        totalPages,
        hasMore,
        isLoadingMore,
        selectedFilterId,
        sortMode,
        availableFilters,
        displayOrder,
        groupsByKey,
      ];
}

/// State when no offline content found
class OfflineSearchEmpty extends OfflineSearchState {
  const OfflineSearchEmpty({
    required this.query,
  });

  final String query;

  @override
  List<Object?> get props => [query];

  String get emptyMessage {
    if (query.isEmpty) {
      return 'No offline content available.\nDownload some content to read offline.';
    }
    return 'No offline content found for "$query".\nTry a different search term.';
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
