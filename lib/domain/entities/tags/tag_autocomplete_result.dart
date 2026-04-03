import 'package:equatable/equatable.dart';
import 'package:nhasixapp/domain/entities/tags/tag_entity.dart';

/// Domain entity for autocomplete search results from API v2
class TagAutocompleteResult extends Equatable {
  final List<TagEntity> suggestions;
  final String query;
  final int totalResults;

  const TagAutocompleteResult({
    required this.suggestions,
    required this.query,
    required this.totalResults,
  });

  @override
  List<Object?> get props => [suggestions, query, totalResults];
}
