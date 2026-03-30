part of 'search_bloc.dart';

/// Base class for all search events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize search
class SearchInitializeEvent extends SearchEvent {
  const SearchInitializeEvent({required this.sourceId});

  final String sourceId;

  @override
  List<Object> get props => [sourceId];
}

/// Event to perform search with query
class SearchQueryEvent extends SearchEvent {
  const SearchQueryEvent(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

/// Event to perform search with filters
class SearchWithFiltersEvent extends SearchEvent {
  const SearchWithFiltersEvent(this.filter);

  final SearchFilter filter;

  @override
  List<Object> get props => [filter];
}

/// Event to update search filter without triggering API call
class SearchUpdateFilterEvent extends SearchEvent {
  const SearchUpdateFilterEvent(this.filter);

  final SearchFilter filter;

  @override
  List<Object> get props => [filter];
}

/// Event to submit search with current filter (triggers API call)
class SearchSubmittedEvent extends SearchEvent {
  const SearchSubmittedEvent();
}

/// Event to clear search
class SearchClearEvent extends SearchEvent {
  const SearchClearEvent();
}

/// Event to load more search results
class SearchLoadMoreEvent extends SearchEvent {
  const SearchLoadMoreEvent();
}

/// Event to refresh search results
class SearchRefreshEvent extends SearchEvent {
  const SearchRefreshEvent();
}

/// Event to retry search after error
class SearchRetryEvent extends SearchEvent {
  const SearchRetryEvent();
}

/// Event to get search suggestions
class SearchGetSuggestionsEvent extends SearchEvent {
  const SearchGetSuggestionsEvent(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

/// Event to get tag suggestions
class SearchGetTagSuggestionsEvent extends SearchEvent {
  const SearchGetTagSuggestionsEvent(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

/// Event to add query to search history
class SearchAddToHistoryEvent extends SearchEvent {
  const SearchAddToHistoryEvent(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

/// Event to load search history
class SearchLoadHistoryEvent extends SearchEvent {
  const SearchLoadHistoryEvent();
}

/// Event to clear search history
class SearchClearHistoryEvent extends SearchEvent {
  const SearchClearHistoryEvent();
}

/// Event to remove item from search history
class SearchRemoveFromHistoryEvent extends SearchEvent {
  const SearchRemoveFromHistoryEvent(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

/// Event to apply quick filter
class SearchApplyQuickFilterEvent extends SearchEvent {
  const SearchApplyQuickFilterEvent({
    this.tag,
    this.artist,
    this.language,
    this.category,
  });

  final String? tag;
  final String? artist;
  final String? language;
  final String? category;

  @override
  List<Object?> get props => [tag, artist, language, category];
}

/// Event to toggle advanced search mode
class SearchToggleAdvancedModeEvent extends SearchEvent {
  const SearchToggleAdvancedModeEvent();
}

/// Event to save search filter as preset
class SearchSavePresetEvent extends SearchEvent {
  const SearchSavePresetEvent({
    required this.name,
    required this.filter,
  });

  final String name;
  final SearchFilter filter;

  @override
  List<Object> get props => [name, filter];
}

/// Event to load search preset
class SearchLoadPresetEvent extends SearchEvent {
  const SearchLoadPresetEvent(this.presetName);

  final String presetName;

  @override
  List<Object> get props => [presetName];
}

/// Event to delete search preset
class SearchDeletePresetEvent extends SearchEvent {
  const SearchDeletePresetEvent(this.presetName);

  final String presetName;

  @override
  List<Object> get props => [presetName];
}

/// Event to get popular searches
class SearchGetPopularEvent extends SearchEvent {
  const SearchGetPopularEvent();
}

/// Event to update search sort option
class SearchUpdateSortEvent extends SearchEvent {
  const SearchUpdateSortEvent(this.sortBy);

  final SortOption sortBy;

  @override
  List<Object> get props => [sortBy];
}
