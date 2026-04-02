part of 'tag_autocomplete_bloc.dart';

/// States for TagAutocompleteBloc
abstract class TagAutocompleteState extends Equatable {
  const TagAutocompleteState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TagAutocompleteInitial extends TagAutocompleteState {
  const TagAutocompleteInitial();
}

/// Loading state
class TagAutocompleteLoading extends TagAutocompleteState {
  const TagAutocompleteLoading();
}

/// Loaded state with suggestions
class TagAutocompleteLoaded extends TagAutocompleteState {
  final List<TagEntity> suggestions;
  final String query;
  final int totalResults;

  const TagAutocompleteLoaded({
    required this.suggestions,
    required this.query,
    required this.totalResults,
  });

  @override
  List<Object?> get props => [suggestions, query, totalResults];
}

/// Error state
class TagAutocompleteError extends TagAutocompleteState {
  final String message;

  const TagAutocompleteError({required this.message});

  @override
  List<Object?> get props => [message];
}
