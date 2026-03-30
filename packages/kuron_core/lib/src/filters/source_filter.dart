/// Filter system for content sources, adapted from TachiyomiSY's Filter hierarchy.
///
/// This sealed class hierarchy represents all possible filter types that a
/// content source can expose. Filters are defined in source config (JSON) and
/// rendered as generic UI components.
///
/// ## Usage
/// Sources declare their available filters via [ContentSource.filterList]:
/// ```dart
/// @override
/// List<SourceFilter> get filterList => [
///   SortSourceFilter('Sort By', ['Newest', 'Popular']),
///   SelectSourceFilter('Language', ['All', 'English', 'Japanese']),
/// ];
/// ```
library;

/// Base sealed class for all filter types.
///
/// Generic type [T] is the state type:
/// - [TextSourceFilter] → [String]
/// - [CheckBoxSourceFilter] → [bool]
/// - [TriStateSourceFilter] → [TriStateValue]
/// - [SelectSourceFilter] → [int] (selected index)
/// - [SortSourceFilter] → [SortSelection?]
/// - [GroupSourceFilter] → [List<SourceFilter>]
sealed class SourceFilter<T> {
  const SourceFilter({
    required this.name,
    required this.state,
  });

  /// Display name shown in filter UI
  final String name;

  /// Current filter state (value)
  final T state;

  /// Create a copy with updated state
  SourceFilter<T> withState(T newState);
}

// ==================== Primitive Filters ====================

/// Non-interactive section header separator in filter UI.
final class HeaderSourceFilter extends SourceFilter<Object?> {
  const HeaderSourceFilter(String name) : super(name: name, state: null);

  @override
  HeaderSourceFilter withState(Object? newState) => this;
}

/// Visual separator line between filter groups.
final class SeparatorSourceFilter extends SourceFilter<Object?> {
  const SeparatorSourceFilter([String name = ''])
      : super(name: name, state: null);

  @override
  SeparatorSourceFilter withState(Object? newState) => this;
}

/// Free-text input filter.
///
/// Example: "Tag Search" input field.
final class TextSourceFilter extends SourceFilter<String> {
  const TextSourceFilter(String name, [String defaultValue = ''])
      : super(name: name, state: defaultValue);

  /// Placeholder text shown when field is empty
  final String placeholder = '';

  @override
  TextSourceFilter withState(String newState) =>
      TextSourceFilter(name, newState);
}

/// Single boolean checkbox filter.
///
/// Example: "Show NSFW content" toggle.
final class CheckBoxSourceFilter extends SourceFilter<bool> {
  const CheckBoxSourceFilter(String name, [bool defaultValue = false])
      : super(name: name, state: defaultValue);

  @override
  CheckBoxSourceFilter withState(bool newState) =>
      CheckBoxSourceFilter(name, newState);
}

/// Three-state filter: ignore / include / exclude.
///
/// This is the key filter type for tag-based search systems (nhentai, e-hentai).
///
/// - [TriStateValue.ignore] → Tag is not filtered
/// - [TriStateValue.include] → Tag MUST be present in results
/// - [TriStateValue.exclude] → Tag MUST NOT be present in results
///
/// Maps directly to nhentai search syntax:
/// - include → `tag:name`
/// - exclude → `-tag:name`
final class TriStateSourceFilter extends SourceFilter<TriStateValue> {
  const TriStateSourceFilter(String name,
      [TriStateValue defaultValue = TriStateValue.ignore])
      : super(name: name, state: defaultValue);

  @override
  TriStateSourceFilter withState(TriStateValue newState) =>
      TriStateSourceFilter(name, newState);
}

/// Dropdown selection filter.
///
/// Example: "Language" dropdown with ['All', 'English', 'Japanese'].
final class SelectSourceFilter extends SourceFilter<int> {
  const SelectSourceFilter(
    String name,
    this.options, [
    int defaultIndex = 0,
  ]) : super(name: name, state: defaultIndex);

  /// List of option display labels
  final List<String> options;

  /// Currently selected option label
  String get selectedOption => options[state];

  @override
  SelectSourceFilter withState(int newState) =>
      SelectSourceFilter(name, options, newState);
}

/// Sort filter with direction (ascending/descending).
///
/// Example: "Sort By" with options ['Newest', 'Popular', 'Popular Today'].
final class SortSourceFilter extends SourceFilter<SortSelection?> {
  const SortSourceFilter(
    String name,
    this.options, [
    SortSelection? defaultSelection,
  ]) : super(name: name, state: defaultSelection);

  /// List of sort option display labels
  final List<String> options;

  @override
  SortSourceFilter withState(SortSelection? newState) =>
      SortSourceFilter(name, options, newState);
}

/// Group of filters displayed as a collapsible section.
///
/// Commonly used for tag groups (e.g., all "Category" tristate filters together).
final class GroupSourceFilter extends SourceFilter<List<SourceFilter>> {
  const GroupSourceFilter(String name, List<SourceFilter> children)
      : super(name: name, state: children);

  @override
  GroupSourceFilter withState(List<SourceFilter> newState) =>
      GroupSourceFilter(name, newState);
}

// ==================== Supporting Types ====================

/// The three possible states for a [TriStateSourceFilter].
enum TriStateValue {
  /// Tag is not applied to the filter (default)
  ignore,

  /// Tag must be present in search results
  include,

  /// Tag must not be present in search results
  exclude,
}

/// Sort selection state containing both the sort index and direction.
class SortSelection {
  const SortSelection(this.index, {this.ascending = false});

  /// Index into [SortSourceFilter.options]
  final int index;

  /// Sort direction (true = ascending, false = descending)
  final bool ascending;

  SortSelection copyWith({int? index, bool? ascending}) =>
      SortSelection(index ?? this.index,
          ascending: ascending ?? this.ascending);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortSelection &&
          other.index == index &&
          other.ascending == ascending;

  @override
  int get hashCode => Object.hash(index, ascending);
}

/// Type alias for a list of filters — the complete filter definition for a source.
typedef FilterList = List<SourceFilter>;
