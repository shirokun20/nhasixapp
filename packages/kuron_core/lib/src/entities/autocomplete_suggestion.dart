import 'package:equatable/equatable.dart';

/// Autocomplete suggestion returned by [ContentSource.getAutocompleteSuggestions].
///
/// Represents a single suggestion item (e.g., a tag, artist, or character name)
/// that can be shown in search autocomplete dropdowns.
class AutocompleteSuggestion extends Equatable {
  const AutocompleteSuggestion({
    required this.id,
    required this.label,
    required this.type,
    this.count,
    this.url,
  });

  /// Suggestion unique ID (e.g., tag ID, artist ID)
  final String id;

  /// Display label (e.g., 'michiking', 'netorare')
  final String label;

  /// Category type (e.g., 'tag', 'artist', 'character', 'parody', 'group')
  final String type;

  /// How many items have this tag/attribute (optional)
  final int? count;

  /// URL for this suggestion (optional)
  final String? url;

  @override
  List<Object?> get props => [id, label, type, count, url];
}
