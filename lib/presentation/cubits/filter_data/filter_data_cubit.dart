import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities.dart';
import '../../../core/utils/tag_data_manager.dart';

part 'filter_data_state.dart';

/// Cubit for managing filter data screen state
class FilterDataCubit extends Cubit<FilterDataState> {
  FilterDataCubit({
    required TagDataManager tagDataManager,
    required Logger logger,
  })  : _tagDataManager = tagDataManager,
        _logger = logger,
        super(const FilterDataInitial());

  final TagDataManager _tagDataManager;
  final Logger _logger;

  // Internal state
  String _currentFilterType = 'tag';
  List<FilterItem> _selectedFilters = [];
  List<Tag> _filteredTags = [];
  String _searchQuery = '';

  /// Initialize filter data screen
  Future<void> initialize({
    required String filterType,
    required List<FilterItem> selectedFilters,
  }) async {
    try {
      _logger.i('FilterDataCubit: Initializing with type: $filterType');

      _currentFilterType = filterType;
      _selectedFilters = List<FilterItem>.from(selectedFilters);
      emit(FilterDataLoading(state));
      // Ensure tag data is cached
      await _tagDataManager.cacheTagData();
      // Get tags by type
      _filteredTags =
          await _tagDataManager.getTagsByType(filterType, limit: 100);
      emit(
        state.copyWith(
          filterType: _currentFilterType,
          searchResults: _filteredTags,
          selectedFilters: _selectedFilters,
          searchQuery: _searchQuery,
          isSearching: false,
          lastUpdated: DateTime.now(),
          message: null,
        ),
      );

      emit(FilterDataLoaded(state));
      _logger.i(
          'FilterDataCubit: Loaded ${_filteredTags.length} tags for type: $filterType');
    } catch (e, stackTrace) {
      _logger.e('FilterDataCubit: Error initializing',
          error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        message: 'Failed to initialize filter data: $e',
        filterType: _currentFilterType,
        selectedFilters: _selectedFilters,
      ));
      emit(FilterDataError(state));
    }
  }

  /// Search filter data by query
  Future<void> searchFilterData(String query) async {
    try {
      _searchQuery = query.trim();

      if (_searchQuery.isEmpty) {
        // Show all tags for current type
        _filteredTags =
            await _tagDataManager.getTagsByType(_currentFilterType, limit: 100);
      } else {
        // Search tags by query and filter by type
        _filteredTags = await _tagDataManager.searchTags(
          _searchQuery,
          type: _currentFilterType,
          limit: 50,
        );
      }

      emit(state.copyWith(
        filterType: _currentFilterType,
        searchResults: _filteredTags,
        selectedFilters: _selectedFilters,
        searchQuery: _searchQuery,
        isSearching: false,
        lastUpdated: DateTime.now(),
      ));

      emit(FilterDataLoaded(state));

      _logger.d(
          'FilterDataCubit: Search results: ${_filteredTags.length} tags for query: "$_searchQuery"');
    } catch (e) {
      _logger.e('FilterDataCubit: Error searching filter data', error: e);
      // Don't emit error for search, just continue with current state
    }
  }

  /// Switch filter type (tag, artist, character, etc.)
  Future<void> switchFilterType(String filterType) async {
    try {
      _logger.i('FilterDataCubit: Switching to filter type: $filterType');

      _currentFilterType = filterType;
      _searchQuery = '';

      emit(FilterDataLoading(state));

      // Get tags by new type
      _filteredTags =
          await _tagDataManager.getTagsByType(filterType, limit: 100);

      emit(state.copyWith(
        filterType: _currentFilterType,
        searchResults: _filteredTags,
        selectedFilters: _selectedFilters,
        searchQuery: _searchQuery,
        isSearching: false,
        lastUpdated: DateTime.now(),
        message: null,
      ));

      emit(FilterDataLoaded(state));

      _logger.i(
          'FilterDataCubit: Switched to ${_filteredTags.length} tags for type: $filterType');
    } catch (e, stackTrace) {
      _logger.e('FilterDataCubit: Error switching filter type',
          error: e, stackTrace: stackTrace);
      emit(state.copyWith(
        message: 'Failed to switch filter type: $e',
        filterType: _currentFilterType,
        selectedFilters: _selectedFilters,
      ));
      emit(FilterDataError(state));
    }
  }

  /// Toggle filter item selection
  void toggleFilterItem(Tag tag, {bool? forceExclude}) {
    try {
      final existingIndex =
          _selectedFilters.indexWhere((item) => item.value == tag.name);

      if (existingIndex >= 0) {
        final existingItem = _selectedFilters[existingIndex];

        if (existingItem.isExcluded) {
          // Currently excluded, remove it
          _selectedFilters.removeAt(existingIndex);
          _logger.d('FilterDataCubit: Removed filter item: ${tag.name}');
        } else {
          // Currently included, switch to excluded
          _selectedFilters[existingIndex] = FilterItem.exclude(tag.name);
          _logger.d('FilterDataCubit: Switched to exclude: ${tag.name}');
        }
      } else {
        // Not selected, add as include or exclude based on forceExclude
        final newItem = forceExclude == true
            ? FilterItem.exclude(tag.name)
            : FilterItem.include(tag.name);
        _selectedFilters.add(newItem);
        _logger.d(
            'FilterDataCubit: Added filter item: ${tag.name} (${newItem.isExcluded ? 'exclude' : 'include'})');
      }

      // Force emit new state by creating completely new instance
      final currentState = state;
      // if (currentState is FilterDataLoaded) {
      // Create completely new state instance
      _logger.d(
          'FilterDataCubit: Force emitting new state with ${_selectedFilters.length} selected filters');
      emit(state.copyWith(
        filterType: currentState.filterType,
        searchResults: currentState.searchResults,
        selectedFilters: List<FilterItem>.from(_selectedFilters),
        searchQuery: currentState.searchQuery,
        isSearching: currentState.isSearching,
        lastUpdated: DateTime.now(),
      ));

      emit(FilterDataLoaded(state));
      // }
    } catch (e) {
      _logger.e('FilterDataCubit: Error toggling filter item', error: e);
    }
  }

  /// Add filter item as include
  void addIncludeFilter(Tag tag) {
    toggleFilterItem(tag, forceExclude: false);
  }

  /// Add filter item as exclude
  void addExcludeFilter(Tag tag) {
    toggleFilterItem(tag, forceExclude: true);
  }

  /// Remove filter item
  void removeFilterItem(String value) {
    try {
      final removedCount = _selectedFilters.length;
      _selectedFilters.removeWhere((item) => item.value == value);
      final newCount = _selectedFilters.length;

      if (removedCount != newCount) {
        // Force emit new state by creating completely new instance
        final currentState = state;
        // if (currentState is FilterDataLoaded) {
        _logger.d(
            'FilterDataCubit: Force emitting new state after removing $value, ${_selectedFilters.length} filters remaining');
        emit(state.copyWith(
          filterType: currentState.filterType,
          searchResults: currentState.searchResults,
          selectedFilters: List<FilterItem>.from(_selectedFilters),
          searchQuery: currentState.searchQuery,
          isSearching: currentState.isSearching,
          lastUpdated: DateTime.now(),
        ));

        emit(FilterDataLoaded(state));
        // }
        _logger.d('FilterDataCubit: Removed filter item: $value');
      }
    } catch (e) {
      _logger.e('FilterDataCubit: Error removing filter item', error: e);
    }
  }

  /// Clear all selected filters
  void clearAllFilters() {
    try {
      final hadFilters = _selectedFilters.isNotEmpty;
      _selectedFilters.clear();

      if (hadFilters) {
        // Force emit new state by creating completely new instance
        final currentState = state;
        // if (currentState is FilterDataLoaded) {
        _logger.d(
            'FilterDataCubit: Force emitting new state after clearing all filters');
        emit(
          state.copyWith(
            filterType: currentState.filterType,
            searchResults: currentState.searchResults,
            selectedFilters: <FilterItem>[],
            searchQuery: currentState.searchQuery,
            isSearching: currentState.isSearching,
            lastUpdated: DateTime.now(),
          ),
        );
        emit(FilterDataLoaded(state));
        // }
        _logger.i('FilterDataCubit: Cleared all filter items');
      }
    } catch (e) {
      _logger.e('FilterDataCubit: Error clearing filters', error: e);
    }
  }

  /// Get selected filters
  List<FilterItem> getSelectedFilters() {
    return List<FilterItem>.from(_selectedFilters);
  }

  /// Check if tag is selected
  FilterItem? getSelectedFilterItem(String tagName) {
    try {
      return _selectedFilters.firstWhere((item) => item.value == tagName);
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

  /// Get current filter type
  String get currentFilterType => _currentFilterType;

  /// Get search query
  String get searchQuery => _searchQuery;
}
