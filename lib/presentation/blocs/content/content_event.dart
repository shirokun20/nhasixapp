part of 'content_bloc.dart';

/// Base class for all content events
abstract class ContentEvent extends Equatable {
  const ContentEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial content list
class ContentLoadEvent extends ContentEvent {
  const ContentLoadEvent({
    this.sortBy = SortOption.newest,
    this.forceRefresh = false,
  });

  final SortOption sortBy;
  final bool forceRefresh;

  @override
  List<Object?> get props => [sortBy, forceRefresh];
}

/// Event to load more content (infinite scrolling)
class ContentLoadMoreEvent extends ContentEvent {
  const ContentLoadMoreEvent();
}

/// Event to refresh content (pull-to-refresh)
class ContentRefreshEvent extends ContentEvent {
  const ContentRefreshEvent({
    this.sortBy = SortOption.newest,
  });

  final SortOption sortBy;

  @override
  List<Object?> get props => [sortBy];
}

/// Event to change sort option
class ContentSortChangedEvent extends ContentEvent {
  const ContentSortChangedEvent(this.sortBy);

  final SortOption sortBy;

  @override
  List<Object?> get props => [sortBy];
}

/// Event to retry loading after error
class ContentRetryEvent extends ContentEvent {
  const ContentRetryEvent();
}

/// Event to clear content list
class ContentClearEvent extends ContentEvent {
  const ContentClearEvent();
}

/// Event to search content with filters
class ContentSearchEvent extends ContentEvent {
  const ContentSearchEvent(this.filter);

  final SearchFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Event to load popular content
class ContentLoadPopularEvent extends ContentEvent {
  const ContentLoadPopularEvent({
    this.timeframe = PopularTimeframe.allTime,
    this.forceRefresh = false,
  });

  final PopularTimeframe timeframe;
  final bool forceRefresh;

  @override
  List<Object?> get props => [timeframe, forceRefresh];
}

/// Event to load random content
class ContentLoadRandomEvent extends ContentEvent {
  const ContentLoadRandomEvent({
    this.count = 20,
  });

  final int count;

  @override
  List<Object?> get props => [count];
}

/// Event to load content by tag
class ContentLoadByTagEvent extends ContentEvent {
  const ContentLoadByTagEvent({
    required this.tag,
    this.sortBy = SortOption.newest,
    this.forceRefresh = false,
  });

  final Tag tag;
  final SortOption sortBy;
  final bool forceRefresh;

  @override
  List<Object?> get props => [tag, sortBy, forceRefresh];
}

/// Event to toggle favorite status of content
class ContentToggleFavoriteEvent extends ContentEvent {
  const ContentToggleFavoriteEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to update content in list (after external changes)
class ContentUpdateEvent extends ContentEvent {
  const ContentUpdateEvent(this.content);

  final Content content;

  @override
  List<Object?> get props => [content];
}

/// Event to remove content from list
class ContentRemoveEvent extends ContentEvent {
  const ContentRemoveEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to navigate to next page
class ContentNextPageEvent extends ContentEvent {
  const ContentNextPageEvent();
}

/// Event to navigate to previous page
class ContentPreviousPageEvent extends ContentEvent {
  const ContentPreviousPageEvent();
}

/// Event to navigate to specific page
class ContentGoToPageEvent extends ContentEvent {
  const ContentGoToPageEvent(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}
