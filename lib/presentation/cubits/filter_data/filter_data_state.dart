part of 'filter_data_cubit.dart';

/// Base state for filter data screen
class FilterDataState extends Equatable {
  const FilterDataState({
    this.filterType,
    this.searchResults,
    this.selectedFilters,
    this.searchQuery,
    this.isSearching,
    this.lastUpdated,
    this.message,
  });

  final String? filterType;
  final List<Tag>? searchResults;
  final List<FilterItem>? selectedFilters;
  final String? searchQuery;
  final bool? isSearching;
  final DateTime? lastUpdated;
  final String? message;

  @override
  List<Object?> get props => [
        filterType,
        searchResults,
        selectedFilters,
        searchQuery,
        isSearching,
      ];

  static const _undefined = Object();

  FilterDataState copyWith({
    Object? filterType = _undefined,
    List<Tag>? searchResults,
    List<FilterItem>? selectedFilters,
    Object? searchQuery = _undefined,
    bool? isSearching,
    DateTime? lastUpdated,
    Object? message = _undefined,
  }) {
    return FilterDataState(
      filterType:
          filterType == _undefined ? this.filterType : filterType as String?,
      searchResults: searchResults ?? this.searchResults,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      searchQuery:
          searchQuery == _undefined ? this.searchQuery : searchQuery as String?,
      isSearching: isSearching ?? this.isSearching,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      message: message == _undefined ? this.message : message as String?,
    );
  }

  /// Check if tag is selected
  FilterItem? getSelectedFilterItem(String tagName) {
    try {
      return selectedFilters?.firstWhere((item) => item.value == tagName);
    } catch (e) {
      return null;
    }
  }

  /// Check if tag is selected as include
  bool isIncluded(String tagName) {
    final item = getSelectedFilterItem(tagName);
    return item != null && !item.isExcluded;
  }

  /// Check if tag is selected as exclude
  bool isExcluded(String tagName) {
    final item = getSelectedFilterItem(tagName);
    return item != null && item.isExcluded;
  }

  /// Check if tag is selected (either include or exclude)
  bool isSelected(String tagName) {
    return getSelectedFilterItem(tagName) != null;
  }

  /// Get selected filters count
  int get selectedCount => selectedFilters?.length ?? 0;

  /// Check if has selected filters
  bool get hasSelectedFilters => selectedFilters != null && selectedCount > 0;

  /// Get selected filters by type
  List<FilterItem> get includeFilters =>
      (selectedFilters ?? []).where((item) => !item.isExcluded).toList();

  List<FilterItem> get excludeFilters =>
      (selectedFilters ?? []).where((item) => item.isExcluded).toList();
}

/// Initial state
class FilterDataInitial extends FilterDataState {
  const FilterDataInitial();
}

/// Loading state
class FilterDataLoading extends FilterDataState {
  FilterDataLoading(FilterDataState prevState)
      : super(
          filterType: prevState.filterType,
          searchResults: prevState.searchResults,
          selectedFilters: prevState.selectedFilters,
          searchQuery: prevState.searchQuery,
          isSearching: prevState.isSearching,
          lastUpdated: prevState.lastUpdated,
          message: prevState.message,
        );
}

/// Loaded state with filter data
class FilterDataLoaded extends FilterDataState {
  FilterDataLoaded(FilterDataState prevState)
      : super(
          filterType: prevState.filterType,
          searchResults: prevState.searchResults,
          selectedFilters: prevState.selectedFilters,
          searchQuery: prevState.searchQuery,
          isSearching: prevState.isSearching,
          lastUpdated: prevState.lastUpdated,
        );
}

/// Error state
class FilterDataError extends FilterDataState {
  FilterDataError(FilterDataState prevState)
      : super(
          filterType: prevState.filterType,
          message: prevState.message,
          selectedFilters: prevState.selectedFilters,
        );
}
