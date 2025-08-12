import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/content/content_usecases.dart';
import '../../../domain/usecases/favorites/favorites_usecases.dart';
import '../../../domain/repositories/repositories.dart';

part 'content_event.dart';
part 'content_state.dart';

/// BLoC for managing content list with pagination, search, and infinite scrolling
class ContentBloc extends Bloc<ContentEvent, ContentState> {
  ContentBloc({
    required GetContentListUseCase getContentListUseCase,
    required SearchContentUseCase searchContentUseCase,
    required GetRandomContentUseCase getRandomContentUseCase,
    required ContentRepository contentRepository,
    required Logger logger,
    AddToFavoritesUseCase? addToFavoritesUseCase,
    RemoveFromFavoritesUseCase? removeFromFavoritesUseCase,
  })  : _getContentListUseCase = getContentListUseCase,
        _searchContentUseCase = searchContentUseCase,
        _getRandomContentUseCase = getRandomContentUseCase,
        _contentRepository = contentRepository,
        _addToFavoritesUseCase = addToFavoritesUseCase,
        _removeFromFavoritesUseCase = removeFromFavoritesUseCase,
        _logger = logger,
        super(const ContentInitial()) {
    // Register event handlers
    on<ContentLoadEvent>(_onContentLoad);
    on<ContentLoadMoreEvent>(_onContentLoadMore);
    on<ContentRefreshEvent>(_onContentRefresh);
    on<ContentSortChangedEvent>(_onContentSortChanged);
    on<ContentRetryEvent>(_onContentRetry);
    on<ContentClearEvent>(_onContentClear);
    on<ContentSearchEvent>(_onContentSearch);
    on<ContentLoadPopularEvent>(_onContentLoadPopular);
    on<ContentLoadRandomEvent>(_onContentLoadRandom);
    on<ContentLoadByTagEvent>(_onContentLoadByTag);
    on<ContentToggleFavoriteEvent>(
        _onContentToggleFavorite); // TODO: Implement later
    on<ContentUpdateEvent>(_onContentUpdate); // TODO: Implement later
    on<ContentRemoveEvent>(_onContentRemove); // TODO: Implement later
    on<ContentNextPageEvent>(_onContentNextPage);
    on<ContentPreviousPageEvent>(_onContentPreviousPage);
    on<ContentGoToPageEvent>(_onContentGoToPage);
  }

  final GetContentListUseCase _getContentListUseCase;
  final SearchContentUseCase _searchContentUseCase;
  final GetRandomContentUseCase _getRandomContentUseCase;
  final ContentRepository _contentRepository;
  final AddToFavoritesUseCase? _addToFavoritesUseCase; // TODO: Implement later
  final RemoveFromFavoritesUseCase?
      _removeFromFavoritesUseCase; // TODO: Implement later
  final Logger _logger;

  // Internal state tracking
  SortOption _currentSortBy = SortOption.newest;
  SearchFilter? _currentSearchFilter;
  Tag? _currentTag;
  PopularTimeframe? _currentTimeframe;
  Timer? _debounceTimer; // TODO: Implement later
  DateTime? _lastFetchTime; // Track when data was actually fetched from server

  // Configuration constants
  static const Duration _debounceDelay =
      Duration(milliseconds: 500); // TODO: Implement later
  static const int _defaultPageSize = 25; // TODO: Implement later
  static const int _maxRetryAttempts = 3; // TODO: Implement later

  /// Load initial content list
  Future<void> _onContentLoad(
    ContentLoadEvent event,
    Emitter<ContentState> emit,
  ) async {
    try {
      _logger.i('ContentBloc: Loading content with sort: ${event.sortBy}');

      // Clear previous state if force refresh or sort changed
      if (event.forceRefresh || _currentSortBy != event.sortBy) {
        _currentSortBy = event.sortBy;
        _currentSearchFilter = null;
        _currentTag = null;
        _currentTimeframe = null;
      }

      // Show loading state if no previous content
      if (state is! ContentLoaded || event.forceRefresh) {
        emit(const ContentLoading());
      }

      // Get content list
      final params = GetContentListParams(
        page: 1,
        sortBy: event.sortBy,
      );

      final result = await _getContentListUseCase(params);

      if (result.isEmpty) {
        emit(const ContentEmpty(
          message: 'No content available at the moment.',
        ));
        return;
      }

      // Update fetch time when we actually get data from server
      _lastFetchTime = DateTime.now();

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        sortBy: event.sortBy,
        lastUpdated: _lastFetchTime,
      ));

      _logger.i('ContentBloc: Loaded ${result.contents.length} contents');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error loading content',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(ContentError(
        message: e.toString(),
        canRetry: errorType.isRetryable,
        errorType: errorType,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Load more content for infinite scrolling
  Future<void> _onContentLoadMore(
    ContentLoadMoreEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded || !currentState.canLoadMore) {
      return;
    }

    try {
      _logger.i(
          'ContentBloc: Loading more content, page: ${currentState.currentPage + 1}');

      // Show loading more state
      emit(ContentLoadingMore(
        contents: currentState.contents,
        currentPage: currentState.currentPage,
        totalPages: currentState.totalPages,
        totalCount: currentState.totalCount,
        hasNext: currentState.hasNext,
        hasPrevious: currentState.hasPrevious,
        sortBy: currentState.sortBy,
        searchFilter: currentState.searchFilter,
        tag: currentState.tag,
        timeframe: currentState.timeframe,
        lastUpdated: currentState.lastUpdated,
      ));

      ContentListResult result;

      // Load more based on current context
      if (currentState.searchFilter != null) {
        // Load more search results
        final nextPageFilter = currentState.searchFilter!
            .copyWith(page: currentState.currentPage + 1);
        result = await _searchContentUseCase(nextPageFilter);
      } else if (currentState.tag != null) {
        // Load more content by tag
        result = await _contentRepository.getContentByTag(
          tag: currentState.tag!,
          page: currentState.currentPage + 1,
          sortBy: currentState.sortBy,
        );
      } else if (currentState.timeframe != null) {
        // Load more popular content
        result = await _contentRepository.getPopularContent(
          timeframe: currentState.timeframe!,
          page: currentState.currentPage + 1,
        );
      } else {
        // Load more regular content
        final params = GetContentListParams(
          page: currentState.currentPage + 1,
          sortBy: currentState.sortBy,
        );
        result = await _getContentListUseCase(params);
      }

      // Update fetch time when we get more data from server
      _lastFetchTime = DateTime.now();

      // Update state with more content
      emit(currentState.copyWith(
        contents: [...currentState.contents, ...result.contents],
        currentPage: result.currentPage,
        hasNext: result.hasNext,
        isLoadingMore: false,
        lastUpdated: _lastFetchTime,
      ));

      _logger.i('ContentBloc: Loaded ${result.contents.length} more contents');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error loading more content',
          error: e, stackTrace: stackTrace);

      // Return to previous state without loading more indicator
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh content (pull-to-refresh)
  Future<void> _onContentRefresh(
    ContentRefreshEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;

    try {
      _logger.i('ContentBloc: Refreshing content');

      // Show refreshing state if we have previous content
      if (currentState is ContentLoaded) {
        emit(ContentRefreshing(
          contents: currentState.contents,
          currentPage: currentState.currentPage,
          totalPages: currentState.totalPages,
          totalCount: currentState.totalCount,
          hasNext: currentState.hasNext,
          hasPrevious: currentState.hasPrevious,
          sortBy: currentState.sortBy,
          searchFilter: currentState.searchFilter,
          tag: currentState.tag,
          timeframe: currentState.timeframe,
          lastUpdated: currentState.lastUpdated,
        ));
      } else {
        emit(const ContentLoading(message: 'Refreshing content...'));
      }

      ContentListResult result;

      // Refresh always goes back to page 1 - that's the concept of "refresh"
      if (currentState is ContentLoaded) {
        if (currentState.searchFilter != null) {
          // Refresh search results from page 1
          final refreshFilter = currentState.searchFilter!.copyWith(page: 1);
          result = await _searchContentUseCase(refreshFilter);
        } else if (currentState.tag != null) {
          // Refresh content by tag from page 1
          result = await _contentRepository.getContentByTag(
            tag: currentState.tag!,
            page: 1,
            sortBy: currentState.sortBy,
          );
        } else if (currentState.timeframe != null) {
          // Refresh popular content from page 1
          result = await _contentRepository.getPopularContent(
            timeframe: currentState.timeframe!,
            page: 1,
          );
        } else {
          // Refresh regular content from page 1
          final params = GetContentListParams(
            page: 1,
            sortBy: event.sortBy,
          );
          result = await _getContentListUseCase(params);
        }
      } else {
        // Fresh load from page 1
        final params = GetContentListParams(
          page: 1,
          sortBy: event.sortBy,
        );
        result = await _getContentListUseCase(params);
      }

      if (result.isEmpty) {
        emit(const ContentEmpty(
          message: 'No content available at the moment.',
        ));
        return;
      }

      // Update current sort if changed
      _currentSortBy = event.sortBy;

      // Update fetch time when we refresh data from server
      _lastFetchTime = DateTime.now();

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        sortBy: event.sortBy,
        searchFilter:
            currentState is ContentLoaded ? currentState.searchFilter : null,
        tag: currentState is ContentLoaded ? currentState.tag : null,
        timeframe:
            currentState is ContentLoaded ? currentState.timeframe : null,
        lastUpdated: _lastFetchTime,
      ));

      _logger
          .i('ContentBloc: Refreshed with ${result.contents.length} contents');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error refreshing content',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      final previousContents =
          currentState is ContentLoaded ? currentState.contents : null;

      emit(ContentError(
        message: e.toString(),
        canRetry: errorType.isRetryable,
        previousContents: previousContents,
        errorType: errorType,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Handle sort option change
  Future<void> _onContentSortChanged(
    ContentSortChangedEvent event,
    Emitter<ContentState> emit,
  ) async {
    if (_currentSortBy == event.sortBy) return;

    _logger.i('ContentBloc: Sort changed to: ${event.sortBy}');
    _currentSortBy = event.sortBy;

    final currentState = state;
    if (currentState is ContentLoaded) {
      // Apply sorting based on current context
      if (currentState.searchFilter != null) {
        // Apply sorting to search results
        final updatedFilter = currentState.searchFilter!.copyWith(
          sortBy: event.sortBy,
          page: 1, // Reset to first page when sorting changes
        );
        add(ContentSearchEvent(updatedFilter));
      } else if (currentState.tag != null) {
        // Apply sorting to tag-based content
        add(ContentLoadByTagEvent(
          tag: currentState.tag!,
          sortBy: event.sortBy,
          forceRefresh: true,
        ));
      } else if (currentState.timeframe != null) {
        // Popular content doesn't support custom sorting, reload with popular
        add(ContentLoadPopularEvent(
          timeframe: currentState.timeframe!,
          forceRefresh: true,
        ));
      } else {
        // Apply sorting to normal content
        add(ContentLoadEvent(sortBy: event.sortBy, forceRefresh: true));
      }
    } else {
      // Load content with new sort option
      add(ContentLoadEvent(sortBy: event.sortBy, forceRefresh: true));
    }
  }

  /// Retry loading content after error
  Future<void> _onContentRetry(
    ContentRetryEvent event,
    Emitter<ContentState> emit,
  ) async {
    _logger.i('ContentBloc: Retrying content load');

    final currentState = state;
    if (currentState is ContentLoaded) {
      // Retry with current context
      if (currentState.searchFilter != null) {
        add(ContentSearchEvent(currentState.searchFilter!));
      } else if (currentState.tag != null) {
        add(ContentLoadByTagEvent(tag: currentState.tag!));
      } else if (currentState.timeframe != null) {
        add(ContentLoadPopularEvent(timeframe: currentState.timeframe!));
      } else {
        add(ContentLoadEvent(sortBy: currentState.sortBy));
      }
    } else {
      // Default retry
      add(ContentLoadEvent(sortBy: _currentSortBy));
    }
  }

  /// Clear content list
  Future<void> _onContentClear(
    ContentClearEvent event,
    Emitter<ContentState> emit,
  ) async {
    _logger.i('ContentBloc: Clearing content');

    _currentSearchFilter = null;
    _currentTag = null;
    _currentTimeframe = null;

    emit(const ContentInitial());
  }

  /// Search content with filters
  Future<void> _onContentSearch(
    ContentSearchEvent event,
    Emitter<ContentState> emit,
  ) async {
    try {
      _logger.i(
          'ContentBloc: Searching content with filter: ${event.filter.toQueryString()}');

      _currentSearchFilter = event.filter;
      _currentTag = null;
      _currentTimeframe = null;

      // Show loading state
      emit(const ContentLoading(message: 'Searching content...'));

      final result = await _searchContentUseCase(event.filter);

      if (result.isEmpty) {
        emit(ContentEmpty(
          message: 'No content found matching your search criteria.',
          searchFilter: event.filter,
        ));
        return;
      }

      // Update fetch time when we search from server
      _lastFetchTime = DateTime.now();

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        sortBy: event.filter.sortBy,
        searchFilter: event.filter,
        lastUpdated: _lastFetchTime,
      ));

      _logger.i('ContentBloc: Found ${result.contents.length} search results');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error searching content',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(ContentError(
        message: e.toString(),
        canRetry: errorType.isRetryable,
        errorType: errorType,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Load popular content
  Future<void> _onContentLoadPopular(
    ContentLoadPopularEvent event,
    Emitter<ContentState> emit,
  ) async {
    try {
      _logger.i('ContentBloc: Loading popular content: ${event.timeframe}');

      _currentTimeframe = event.timeframe;
      _currentSearchFilter = null;
      _currentTag = null;

      // Show loading state if no previous content or force refresh
      if (state is! ContentLoaded || event.forceRefresh) {
        emit(const ContentLoading(message: 'Loading popular content...'));
      }

      final result = await _contentRepository.getPopularContent(
        timeframe: event.timeframe,
        page: 1,
      );

      if (result.isEmpty) {
        emit(const ContentEmpty(
          message: 'No popular content available at the moment.',
        ));
        return;
      }

      // Update fetch time when we load popular content from server
      _lastFetchTime = DateTime.now();

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        sortBy: SortOption.popular,
        timeframe: event.timeframe,
        lastUpdated: _lastFetchTime,
      ));

      _logger
          .i('ContentBloc: Loaded ${result.contents.length} popular contents');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error loading popular content',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(ContentError(
        message: e.toString(),
        canRetry: errorType.isRetryable,
        errorType: errorType,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Load random content
  Future<void> _onContentLoadRandom(
    ContentLoadRandomEvent event,
    Emitter<ContentState> emit,
  ) async {
    try {
      _logger.i('ContentBloc: Loading ${event.count} random contents');

      _currentSearchFilter = null;
      _currentTag = null;
      _currentTimeframe = null;

      emit(const ContentLoading(message: 'Loading random content...'));

      final contents = await _getRandomContentUseCase(event.count);

      if (contents.isEmpty) {
        emit(const ContentEmpty(
          message: 'No random content available at the moment.',
        ));
        return;
      }

      // Update fetch time when we load random content from server
      _lastFetchTime = DateTime.now();

      // Create a single page result for random content
      emit(ContentLoaded(
        contents: contents,
        currentPage: 1,
        totalPages: 1,
        totalCount: contents.length,
        hasNext: false,
        hasPrevious: false,
        sortBy: SortOption.random,
        lastUpdated: _lastFetchTime,
      ));

      _logger.i('ContentBloc: Loaded ${contents.length} random contents');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error loading random content',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(ContentError(
        message: e.toString(),
        canRetry: errorType.isRetryable,
        errorType: errorType,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Load content by tag
  Future<void> _onContentLoadByTag(
    ContentLoadByTagEvent event,
    Emitter<ContentState> emit,
  ) async {
    try {
      _logger.i('ContentBloc: Loading content by tag: ${event.tag.name}');

      _currentTag = event.tag;
      _currentSearchFilter = null;
      _currentTimeframe = null;

      // Show loading state if no previous content or force refresh
      if (state is! ContentLoaded || event.forceRefresh) {
        emit(const ContentLoading(message: 'Loading content by tag...'));
      }

      final result = await _contentRepository.getContentByTag(
        tag: event.tag,
        page: 1,
        sortBy: event.sortBy,
      );

      if (result.isEmpty) {
        emit(ContentEmpty(
          message: 'No content found for this tag.',
          tag: event.tag,
        ));
        return;
      }

      // Update fetch time when we load content by tag from server
      _lastFetchTime = DateTime.now();

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        sortBy: event.sortBy,
        tag: event.tag,
        lastUpdated: _lastFetchTime,
      ));

      _logger
          .i('ContentBloc: Loaded ${result.contents.length} contents for tag');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error loading content by tag',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(ContentError(
        message: e.toString(),
        canRetry: errorType.isRetryable,
        errorType: errorType,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Toggle favorite status of content
  // TODO: Implement later - requires favorite use cases implementation
  Future<void> _onContentToggleFavorite(
    ContentToggleFavoriteEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded) return;

    try {
      _logger
          .i('ContentBloc: Toggling favorite for content: ${event.contentId}');

      // Find the content in current list
      final contentIndex = currentState.contents
          .indexWhere((content) => content.id == event.contentId);

      if (contentIndex == -1) return;

      final content = currentState.contents[contentIndex];

      // TODO: Implement favorite status check and toggle
      // This would require additional use cases or repository methods
      // For now, we'll just log the action

      _logger.i('ContentBloc: Favorite toggled for: ${content.title}');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error toggling favorite',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Update content in list
  // TODO: Implement later - currently not triggered from UI
  Future<void> _onContentUpdate(
    ContentUpdateEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded) return;

    _logger.i('ContentBloc: Updating content: ${event.content.id}');

    emit(currentState.copyWithUpdatedContent(event.content));
  }

  /// Remove content from list
  // TODO: Implement later - currently not triggered from UI
  Future<void> _onContentRemove(
    ContentRemoveEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded) return;

    _logger.i('ContentBloc: Removing content: ${event.contentId}');

    emit(currentState.copyWithRemovedContent(event.contentId));
  }

  /// Determine error type from exception
  ContentErrorType _determineErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return ContentErrorType.network;
    } else if (errorString.contains('server') || errorString.contains('5')) {
      return ContentErrorType.server;
    } else if (errorString.contains('cloudflare') ||
        errorString.contains('protection')) {
      return ContentErrorType.cloudflare;
    } else if (errorString.contains('rate') ||
        errorString.contains('limit') ||
        errorString.contains('429')) {
      return ContentErrorType.rateLimit;
    } else if (errorString.contains('parse') ||
        errorString.contains('format')) {
      return ContentErrorType.parsing;
    } else {
      return ContentErrorType.unknown;
    }
  }

  /// Navigate to next page
  Future<void> _onContentNextPage(
    ContentNextPageEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    _logger.i(
        'on ContentLoaded is ${currentState is ContentLoaded} and hasNext ${currentState is ContentLoaded && currentState.hasNext}');
    if (currentState is! ContentLoaded || !currentState.hasNext) {
      return;
    }

    final nextPage = currentState.currentPage + 1;
    _logger.i('ContentBloc: Navigating to next page: $nextPage');

    await _loadSpecificPage(nextPage, currentState, emit);
  }

  /// Navigate to previous page
  Future<void> _onContentPreviousPage(
    ContentPreviousPageEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded || !currentState.hasPrevious) {
      return;
    }

    final previousPage = currentState.currentPage - 1;
    _logger.i('ContentBloc: Navigating to previous page: $previousPage');

    await _loadSpecificPage(previousPage, currentState, emit);
  }

  /// Navigate to specific page
  Future<void> _onContentGoToPage(
    ContentGoToPageEvent event,
    Emitter<ContentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentLoaded) {
      return;
    }

    // Validate page number
    if (event.page < 1 || event.page > currentState.totalPages) {
      _logger.w('ContentBloc: Invalid page number: ${event.page}');
      return;
    }

    // Don't reload if already on the same page
    if (event.page == currentState.currentPage) {
      return;
    }

    _logger.i('ContentBloc: Navigating to page: ${event.page}');

    await _loadSpecificPage(event.page, currentState, emit);
  }

  /// Load specific page based on current context
  Future<void> _loadSpecificPage(
    int page,
    ContentLoaded currentState,
    Emitter<ContentState> emit,
  ) async {
    try {
      // Show minimal loading state for pagination
      emit(ContentLoading(
        message: 'Loading page $page...',
        previousContents: currentState.contents,
      ));

      ContentListResult result;

      // Load page based on current context
      if (currentState.searchFilter != null) {
        // Load search results page
        final pageFilter = currentState.searchFilter!.copyWith(page: page);
        result = await _searchContentUseCase(pageFilter);
      } else if (currentState.tag != null) {
        // Load content by tag page
        result = await _contentRepository.getContentByTag(
          tag: currentState.tag!,
          page: page,
          sortBy: currentState.sortBy,
        );
      } else if (currentState.timeframe != null) {
        // Load popular content page
        result = await _contentRepository.getPopularContent(
          timeframe: currentState.timeframe!,
          page: page,
        );
      } else {
        // Load regular content page
        final params = GetContentListParams(
          page: page,
          sortBy: currentState.sortBy,
        );
        result = await _getContentListUseCase(params);
      }

      if (result.isEmpty) {
        emit(const ContentEmpty(
          message: 'No content found on this page.',
        ));
        return;
      }

      // Update fetch time when we load a specific page from server
      _lastFetchTime = DateTime.now();

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        totalCount: result.totalCount,
        hasNext: result.hasNext,
        hasPrevious: result.hasPrevious,
        sortBy: currentState.sortBy,
        searchFilter: currentState.searchFilter,
        tag: currentState.tag,
        timeframe: currentState.timeframe,
        lastUpdated: _lastFetchTime,
      ));

      _logger.i(
          'ContentBloc: Loaded page $page with ${result.contents.length} contents');
    } catch (e, stackTrace) {
      _logger.e('ContentBloc: Error loading page $page',
          error: e, stackTrace: stackTrace);

      final errorType = _determineErrorType(e);
      emit(ContentError(
        message: e.toString(),
        canRetry: errorType.isRetryable,
        previousContents: currentState.contents,
        errorType: errorType,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
