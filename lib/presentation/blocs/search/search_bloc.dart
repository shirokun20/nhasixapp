import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/content/content_usecases.dart';

import '../../../data/datasources/local/local_data_source.dart';

part 'search_event.dart';
part 'search_state.dart';

/// BLoC for managing search functionality with advanced filters,
/// search history, debounced search, and tag suggestions
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required SearchContentUseCase searchContentUseCase,
    required LocalDataSource localDataSource,
    required Logger logger,
  })  : _searchContentUseCase = searchContentUseCase,
        _localDataSource = localDataSource,
        _logger = logger,
        super(const SearchInitial()) {
    // Register event handlers
    on<SearchInitializeEvent>(_onSearchInitialize);
    on<SearchQueryEvent>(_onSearchQuery, transformer: _debounceTransformer());
    on<SearchWithFiltersEvent>(_onSearchWithFilters);
    on<SearchUpdateFilterEvent>(_onSearchUpdateFilter);
    on<SearchClearEvent>(_onSearchClear);
    on<SearchLoadMoreEvent>(_onSearchLoadMore);
    on<SearchRefreshEvent>(_onSearchRefresh);
    on<SearchRetryEvent>(_onSearchRetry);
    on<SearchGetSuggestionsEvent>(_onSearchGetSuggestions,
        transformer: _debounceTransformer());
    on<SearchGetTagSuggestionsEvent>(_onSearchGetTagSuggestions,
        transformer: _debounceTransformer());
    on<SearchAddToHistoryEvent>(_onSearchAddToHistory);
    on<SearchLoadHistoryEvent>(_onSearchLoadHistory);
    on<SearchClearHistoryEvent>(_onSearchClearHistory);
    on<SearchRemoveFromHistoryEvent>(_onSearchRemoveFromHistory);
    on<SearchApplyQuickFilterEvent>(_onSearchApplyQuickFilter);
    on<SearchToggleAdvancedModeEvent>(_onSearchToggleAdvancedMode);
    on<SearchSavePresetEvent>(_onSearchSavePreset);
    on<SearchLoadPresetEvent>(_onSearchLoadPreset);
    on<SearchDeletePresetEvent>(_onSearchDeletePreset);
    on<SearchGetPopularEvent>(_onSearchGetPopular);
    on<SearchUpdateSortEvent>(_onSearchUpdateSort);
  }

  final SearchContentUseCase _searchContentUseCase;
  final LocalDataSource _localDataSource;
  final Logger _logger;

  // Internal state tracking
  SearchFilter _currentFilter = const SearchFilter();
  bool _isAdvancedMode = false;
  Map<String, SearchFilter> _searchPresets = {};
  List<String> _searchHistory = [];
  List<String> _popularSearches = [];
  Timer? _debounceTimer;

  // Configuration constants
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const int _maxHistoryItems = 50;
  static const int _maxSuggestions = 10;

  /// Debounce transformer for search events
  EventTransformer<T> _debounceTransformer<T>() {
    return (events, mapper) {
      return events.debounceTime(_debounceDelay).asyncExpand(mapper);
    };
  }

  /// Initialize search with history and presets
  Future<void> _onSearchInitialize(
    SearchInitializeEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _logger.i('SearchBloc: Initializing search');

      // Load search history
      _searchHistory = await _localDataSource.getSearchHistory();

      // Load popular searches (mock data for now)
      _popularSearches = [
        'english',
        'big breasts',
        'sole female',
        'sole male',
        'full color',
      ];

      // Load search presets (from preferences)
      await _loadSearchPresets();

      emit(SearchHistory(
        history: _searchHistory,
        popularSearches: _popularSearches,
      ));

      _logger.i(
          'SearchBloc: Initialized with ${_searchHistory.length} history items');
    } catch (e, stackTrace) {
      _logger.e('SearchBloc: Error initializing search',
          error: e, stackTrace: stackTrace);

      emit(SearchError(
        message: 'Failed to initialize search',
        errorType: SearchErrorType.unknown,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Handle search query with debouncing
  Future<void> _onSearchQuery(
    SearchQueryEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      add(const SearchClearEvent());
      return;
    }

    try {
      _logger.i('SearchBloc: Searching with query: "${event.query}"');

      // Update current filter with query
      _currentFilter = _currentFilter.copyWith(
        query: event.query.trim(),
        page: 1,
      );

      // Show loading state
      emit(const SearchLoading(message: 'Searching...'));

      // Perform search
      final result = await _searchContentUseCase(_currentFilter);

      // Add to search history
      add(SearchAddToHistoryEvent(event.query.trim()));

      if (result.isEmpty) {
        emit(SearchEmpty(
          filter: _currentFilter,
          message: 'No results found for "${event.query}"',
          suggestions: await _generateSearchSuggestions(event.query),
        ));
        return;
      }

      emit(SearchLoaded(
        results: result.contents,
        filter: _currentFilter,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('SearchBloc: Found ${result.contents.length} results');
    } catch (e, stackTrace) {
      _logger.e('SearchBloc: Error searching with query',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(SearchError(
        message: e.toString(),
        errorType: errorType,
        canRetry: errorType.isRetryable,
        filter: _currentFilter,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Handle search with filters
  Future<void> _onSearchWithFilters(
    SearchWithFiltersEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _logger.i(
          'SearchBloc: Searching with filters: ${event.filter.toQueryString()}');

      _currentFilter = event.filter.copyWith(page: 1);

      // Show loading state
      emit(const SearchLoading(message: 'Searching with filters...'));

      // Perform search
      final result = await _searchContentUseCase(_currentFilter);

      // Add query to history if present
      if (_currentFilter.query != null && _currentFilter.query!.isNotEmpty) {
        add(SearchAddToHistoryEvent(_currentFilter.query!));
      }

      if (result.isEmpty) {
        emit(SearchEmpty(
          filter: _currentFilter,
          message: 'No results found with current filters',
        ));
        return;
      }

      emit(SearchLoaded(
        results: result.contents,
        filter: _currentFilter,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('SearchBloc: Found ${result.contents.length} filtered results');
    } catch (e, stackTrace) {
      _logger.e('SearchBloc: Error searching with filters',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(SearchError(
        message: e.toString(),
        errorType: errorType,
        canRetry: errorType.isRetryable,
        filter: _currentFilter,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Update search filter without performing search
  Future<void> _onSearchUpdateFilter(
    SearchUpdateFilterEvent event,
    Emitter<SearchState> emit,
  ) async {
    _logger.i('SearchBloc: Updating filter');

    _currentFilter = event.filter;

    final currentState = state;
    if (currentState is SearchLoaded) {
      emit(currentState.copyWithNewFilter(_currentFilter));
    }
  }

  /// Clear search results and filters
  Future<void> _onSearchClear(
    SearchClearEvent event,
    Emitter<SearchState> emit,
  ) async {
    _logger.i('SearchBloc: Clearing search');

    _currentFilter = const SearchFilter();

    emit(SearchHistory(
      history: _searchHistory,
      popularSearches: _popularSearches,
    ));
  }

  /// Load more search results
  Future<void> _onSearchLoadMore(
    SearchLoadMoreEvent event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded || !currentState.canLoadMore) {
      return;
    }

    try {
      _logger.i(
          'SearchBloc: Loading more results, page: ${currentState.currentPage + 1}');

      // Show loading more state
      emit(SearchLoadingMore(
        results: currentState.results,
        filter: currentState.filter,
        currentPage: currentState.currentPage,
        totalPages: currentState.totalPages,
        totalCount: currentState.totalCount,
        hasNext: currentState.hasNext,
        hasPrevious: currentState.hasPrevious,
        lastUpdated: currentState.lastUpdated,
        suggestions: currentState.suggestions,
        tagSuggestions: currentState.tagSuggestions,
      ));

      // Load next page
      final nextPageFilter = _currentFilter.copyWith(
        page: currentState.currentPage + 1,
      );

      final result = await _searchContentUseCase(nextPageFilter);

      // Update current filter
      _currentFilter = nextPageFilter;

      // Update state with more results
      emit(currentState.copyWith(
        results: [...currentState.results, ...result.contents],
        currentPage: result.currentPage,
        hasNext: result.hasNext,
        isLoadingMore: false,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('SearchBloc: Loaded ${result.contents.length} more results');
    } catch (e, stackTrace) {
      _logger.e('SearchBloc: Error loading more results',
          error: e, stackTrace: stackTrace);

      // Return to previous state without loading more indicator
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh search results
  Future<void> _onSearchRefresh(
    SearchRefreshEvent event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded) return;

    try {
      _logger.i('SearchBloc: Refreshing search results');

      // Show refreshing state
      emit(SearchRefreshing(
        results: currentState.results,
        filter: currentState.filter,
        currentPage: currentState.currentPage,
        totalPages: currentState.totalPages,
        totalCount: currentState.totalCount,
        hasNext: currentState.hasNext,
        hasPrevious: currentState.hasPrevious,
        lastUpdated: currentState.lastUpdated,
        suggestions: currentState.suggestions,
        tagSuggestions: currentState.tagSuggestions,
      ));

      // Refresh with first page
      final refreshFilter = _currentFilter.copyWith(page: 1);
      final result = await _searchContentUseCase(refreshFilter);

      _currentFilter = refreshFilter;

      if (result.isEmpty) {
        emit(SearchEmpty(
          filter: _currentFilter,
          message: 'No results found',
        ));
        return;
      }

      emit(SearchLoaded(
        results: result.contents,
        filter: _currentFilter,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('SearchBloc: Refreshed with ${result.contents.length} results');
    } catch (e, stackTrace) {
      _logger.e('SearchBloc: Error refreshing search',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(SearchError(
        message: e.toString(),
        errorType: errorType,
        canRetry: errorType.isRetryable,
        previousResults: currentState.results,
        filter: _currentFilter,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Retry search after error
  Future<void> _onSearchRetry(
    SearchRetryEvent event,
    Emitter<SearchState> emit,
  ) async {
    _logger.i('SearchBloc: Retrying search');

    if (_currentFilter.hasFilters) {
      add(SearchWithFiltersEvent(_currentFilter));
    } else {
      emit(SearchHistory(
        history: _searchHistory,
        popularSearches: _popularSearches,
      ));
    }
  }

  /// Get search suggestions
  Future<void> _onSearchGetSuggestions(
    SearchGetSuggestionsEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _logger.d('SearchBloc: Getting suggestions for: "${event.query}"');

      final suggestions = await _generateSearchSuggestions(event.query);
      final tagSuggestions = await _generateTagSuggestions(event.query);

      emit(SearchSuggestions(
        query: event.query,
        suggestions: suggestions,
        tagSuggestions: tagSuggestions,
        history: _searchHistory,
      ));
    } catch (e) {
      _logger.e('SearchBloc: Error getting suggestions', error: e);
      // Don't emit error for suggestions, just continue
    }
  }

  /// Get tag suggestions
  Future<void> _onSearchGetTagSuggestions(
    SearchGetTagSuggestionsEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _logger.d('SearchBloc: Getting tag suggestions for: "${event.query}"');

      final tagSuggestions = await _generateTagSuggestions(event.query);

      final currentState = state;
      if (currentState is SearchSuggestions) {
        emit(currentState.copyWith(tagSuggestions: tagSuggestions));
      } else if (currentState is SearchLoaded) {
        emit(currentState.copyWith(tagSuggestions: tagSuggestions));
      }
    } catch (e) {
      _logger.e('SearchBloc: Error getting tag suggestions', error: e);
    }
  }

  /// Add query to search history
  Future<void> _onSearchAddToHistory(
    SearchAddToHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _localDataSource.addSearchHistory(event.query);

      // Update local history
      _searchHistory.remove(event.query); // Remove if exists
      _searchHistory.insert(0, event.query); // Add to beginning

      // Keep only max items
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
      }

      _logger.d('SearchBloc: Added to search history: "${event.query}"');
    } catch (e) {
      _logger.e('SearchBloc: Error adding to search history', error: e);
    }
  }

  /// Load search history
  Future<void> _onSearchLoadHistory(
    SearchLoadHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _searchHistory = await _localDataSource.getSearchHistory();

      emit(SearchHistory(
        history: _searchHistory,
        popularSearches: _popularSearches,
      ));

      _logger.d('SearchBloc: Loaded ${_searchHistory.length} history items');
    } catch (e) {
      _logger.e('SearchBloc: Error loading search history', error: e);

      emit(SearchHistory(
        history: _searchHistory,
        popularSearches: _popularSearches,
      ));
    }
  }

  /// Clear search history
  Future<void> _onSearchClearHistory(
    SearchClearHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _localDataSource.clearSearchHistory();
      _searchHistory.clear();

      emit(SearchHistory(
        history: _searchHistory,
        popularSearches: _popularSearches,
      ));

      _logger.d('SearchBloc: Cleared search history');
    } catch (e) {
      _logger.e('SearchBloc: Error clearing search history', error: e);
    }
  }

  /// Remove item from search history
  Future<void> _onSearchRemoveFromHistory(
    SearchRemoveFromHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _searchHistory.remove(event.query);

      // Update database (reload to sync)
      await _localDataSource.clearSearchHistory();
      for (final query in _searchHistory) {
        await _localDataSource.addSearchHistory(query);
      }

      emit(SearchHistory(
        history: _searchHistory,
        popularSearches: _popularSearches,
      ));

      _logger.d('SearchBloc: Removed from history: "${event.query}"');
    } catch (e) {
      _logger.e('SearchBloc: Error removing from history', error: e);
    }
  }

  /// Apply quick filter
  Future<void> _onSearchApplyQuickFilter(
    SearchApplyQuickFilterEvent event,
    Emitter<SearchState> emit,
  ) async {
    _logger.i('SearchBloc: Applying quick filter');

    SearchFilter newFilter = _currentFilter;

    if (event.tag != null) {
      final tags = List<String>.from(newFilter.includeTags);
      if (!tags.contains(event.tag!)) {
        tags.add(event.tag!);
      }
      newFilter = newFilter.copyWith(includeTags: tags);
    }

    if (event.artist != null) {
      final artists = List<String>.from(newFilter.artists);
      if (!artists.contains(event.artist!)) {
        artists.add(event.artist!);
      }
      newFilter = newFilter.copyWith(artists: artists);
    }

    if (event.language != null) {
      newFilter = newFilter.copyWith(language: event.language);
    }

    if (event.category != null) {
      newFilter = newFilter.copyWith(category: event.category);
    }

    add(SearchWithFiltersEvent(newFilter));
  }

  /// Toggle advanced search mode
  Future<void> _onSearchToggleAdvancedMode(
    SearchToggleAdvancedModeEvent event,
    Emitter<SearchState> emit,
  ) async {
    _isAdvancedMode = !_isAdvancedMode;
    _logger.i('SearchBloc: Advanced mode: $_isAdvancedMode');

    // Update current state to reflect mode change
    final currentState = state;
    if (currentState is SearchLoaded) {
      emit(currentState.copyWith(lastUpdated: DateTime.now()));
    }
  }

  /// Save search filter as preset
  Future<void> _onSearchSavePreset(
    SearchSavePresetEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _searchPresets[event.name] = event.filter;
      await _saveSearchPresets();

      _logger.i('SearchBloc: Saved search preset: "${event.name}"');
    } catch (e) {
      _logger.e('SearchBloc: Error saving search preset', error: e);
    }
  }

  /// Load search preset
  Future<void> _onSearchLoadPreset(
    SearchLoadPresetEvent event,
    Emitter<SearchState> emit,
  ) async {
    final preset = _searchPresets[event.presetName];
    if (preset != null) {
      _logger.i('SearchBloc: Loading search preset: "${event.presetName}"');
      add(SearchWithFiltersEvent(preset));
    }
  }

  /// Delete search preset
  Future<void> _onSearchDeletePreset(
    SearchDeletePresetEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _searchPresets.remove(event.presetName);
      await _saveSearchPresets();

      _logger.i('SearchBloc: Deleted search preset: "${event.presetName}"');
    } catch (e) {
      _logger.e('SearchBloc: Error deleting search preset', error: e);
    }
  }

  /// Get popular searches
  Future<void> _onSearchGetPopular(
    SearchGetPopularEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchHistory(
      history: _searchHistory,
      popularSearches: _popularSearches,
    ));
  }

  /// Update search sort option
  Future<void> _onSearchUpdateSort(
    SearchUpdateSortEvent event,
    Emitter<SearchState> emit,
  ) async {
    _logger.i('SearchBloc: Updating sort to: ${event.sortBy}');

    _currentFilter = _currentFilter.copyWith(
      sortBy: event.sortBy,
      page: 1,
    );

    // Re-search with new sort if we have active search
    final currentState = state;
    if (currentState is SearchLoaded) {
      add(SearchWithFiltersEvent(_currentFilter));
    }
  }

  /// Generate search suggestions based on query
  Future<List<String>> _generateSearchSuggestions(String query) async {
    try {
      final suggestions = <String>[];

      // Add from search history
      final historyMatches = _searchHistory
          .where((item) =>
              item.toLowerCase().contains(query.toLowerCase()) && item != query)
          .take(5)
          .toList();
      suggestions.addAll(historyMatches);

      // Add from popular searches
      final popularMatches = _popularSearches
          .where((item) =>
              item.toLowerCase().contains(query.toLowerCase()) &&
              item != query &&
              !suggestions.contains(item))
          .take(5)
          .toList();
      suggestions.addAll(popularMatches);

      return suggestions.take(_maxSuggestions).toList();
    } catch (e) {
      _logger.e('SearchBloc: Error generating search suggestions', error: e);
      return [];
    }
  }

  /// Generate tag suggestions based on query
  Future<List<Tag>> _generateTagSuggestions(String query) async {
    try {
      if (query.length < 2) return [];

      final tags =
          await _localDataSource.searchTags(query, limit: _maxSuggestions);
      return tags.map((tagModel) => tagModel.toEntity()).toList();
    } catch (e) {
      _logger.e('SearchBloc: Error generating tag suggestions', error: e);
      return [];
    }
  }

  /// Load search presets from storage
  Future<void> _loadSearchPresets() async {
    try {
      // TODO: Implement loading presets from preferences
      // For now, use empty map
      _searchPresets = {};
    } catch (e) {
      _logger.e('SearchBloc: Error loading search presets', error: e);
      _searchPresets = {};
    }
  }

  /// Save search presets to storage
  Future<void> _saveSearchPresets() async {
    try {
      // TODO: Implement saving presets to preferences
      _logger.d('SearchBloc: Saved ${_searchPresets.length} search presets');
    } catch (e) {
      _logger.e('SearchBloc: Error saving search presets', error: e);
    }
  }

  /// Determine error type from exception
  SearchErrorType _determineErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('validation')) {
      return SearchErrorType.validation;
    } else if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return SearchErrorType.network;
    } else if (errorString.contains('server') || errorString.contains('5')) {
      return SearchErrorType.server;
    } else if (errorString.contains('cloudflare') ||
        errorString.contains('protection')) {
      return SearchErrorType.cloudflare;
    } else if (errorString.contains('rate') ||
        errorString.contains('limit') ||
        errorString.contains('429')) {
      return SearchErrorType.rateLimit;
    } else if (errorString.contains('parse') ||
        errorString.contains('format')) {
      return SearchErrorType.parsing;
    } else {
      return SearchErrorType.unknown;
    }
  }

  /// Get current filter
  SearchFilter get currentFilter => _currentFilter;

  /// Check if in advanced mode
  bool get isAdvancedMode => _isAdvancedMode;

  /// Get search presets
  Map<String, SearchFilter> get searchPresets =>
      Map.unmodifiable(_searchPresets);

  /// Get search history
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

/// Extension to add debounce functionality to streams
extension StreamDebounce<T> on Stream<T> {
  Stream<T> debounceTime(Duration duration) {
    Timer? debounceTimer;
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          (T data) {
            debounceTimer?.cancel();
            debounceTimer = Timer(duration, () {
              controller.add(data);
            });
          },
          onError: controller.addError,
          onDone: () {
            debounceTimer?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        debounceTimer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
