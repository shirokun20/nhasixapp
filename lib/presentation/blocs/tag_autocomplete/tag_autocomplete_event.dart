part of 'tag_autocomplete_bloc.dart';

/// Events for TagAutocompleteBloc
abstract class TagAutocompleteEvent extends Equatable {
  const TagAutocompleteEvent();

  @override
  List<Object?> get props => [];
}

/// Event to search for autocomplete suggestions
class TagAutocompleteSearchEvent extends TagAutocompleteEvent {
  final String query;
  final String? tagType;

  const TagAutocompleteSearchEvent({
    required this.query,
    this.tagType,
  });

  @override
  List<Object?> get props => [query, tagType];
}

/// Event to clear autocomplete results
class TagAutocompleteClearEvent extends TagAutocompleteEvent {
  const TagAutocompleteClearEvent();
}
