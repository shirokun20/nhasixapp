part of 'filter_data_cubit.dart';

/// Base state for filter data screen
abstract class FilterDataState extends Equatable {
  const FilterDataState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FilterDataInitial extends FilterDataState {
  const FilterDataInitial();
}

/// Loading state
class FilterDataLoading extends FilterDataState {
  const FilterDataLoading();
}

/// Loaded state with filter data
class FilterDataLoaded extends FilterDataState {
  const FilterDataLoaded({
    required this.filterType,
    required this.searchResults,
    required this.selectedFilters,
    required this.searchQuery,
    required this.isSearching,
  });

  final String filterType;
  final List<Tag> searchResults;
  final List<FilterItem> selectedFilters;
  final String searchQuery;
  final bool isSearching;

  @override
  List<Object?> get props => [
        filterType,
        searchResults,
        selectedFilters
            .length, // Use length instead of list for better comparison
        selectedFilters
            .map((e) => '${e.value}_${e.isExcluded}')
            .join(','), // Create unique string
        searchQuery,
        isSearching,
      ];

  FilterDataLoaded copyWith({
    String? filterType,
    List<Tag>? searchResults,
    List<FilterItem>? selectedFilters,
    String? searchQuery,
    bool? isSearching,
  }) {
    return FilterDataLoaded(
      filterType: filterType ?? this.filterType,
      searchResults: searchResults ?? this.searchResults,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  /// Check if tag is selected
  FilterItem? getSelectedFilterItem(String tagName) {
    try {
      return selectedFilters.firstWhere((item) => item.value == tagName);
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
  int get selectedCount => selectedFilters.length;

  /// Check if has selected filters
  bool get hasSelectedFilters => selectedFilters.isNotEmpty;

  /// Get selected filters by type
  List<FilterItem> get includeFilters =>
      selectedFilters.where((item) => !item.isExcluded).toList();

  List<FilterItem> get excludeFilters =>
      selectedFilters.where((item) => item.isExcluded).toList();
}

/// Error state
class FilterDataError extends FilterDataState {
  const FilterDataError({
    required this.message,
    required this.filterType,
    required this.selectedFilters,
  });

  final String message;
  final String filterType;
  final List<FilterItem> selectedFilters;

  @override
  List<Object?> get props => [message, filterType, selectedFilters];
}
