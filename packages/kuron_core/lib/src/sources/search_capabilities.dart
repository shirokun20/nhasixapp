import '../value_objects/sort_option.dart';

/// Defines the search capabilities supported by a content source.
///
/// Each source may have different search features. This class allows UI
/// to dynamically adapt based on what the current source supports.
class SearchCapabilities {
  /// Whether this source supports tag exclusion (e.g., -tag:name)
  final bool supportsTagExclusion;

  /// Whether this source supports advanced search syntax
  final bool supportsAdvancedSyntax;

  /// Available filter types for this source
  final List<FilterType> availableFilters;

  /// Available sort options for this source
  final List<SortOption> availableSorts;

  /// Regex pattern for validating content IDs
  final String contentIdPattern;

  /// Help text explaining search syntax
  final String searchHelpText;

  /// Maximum results per page
  final int maxResultsPerPage;

  const SearchCapabilities({
    required this.supportsTagExclusion,
    required this.supportsAdvancedSyntax,
    required this.availableFilters,
    required this.availableSorts,
    required this.contentIdPattern,
    required this.searchHelpText,
    this.maxResultsPerPage = 25,
  });

  /// Default capabilities for unknown sources
  static const SearchCapabilities defaultCapabilities = SearchCapabilities(
    supportsTagExclusion: false,
    supportsAdvancedSyntax: false,
    availableFilters: [FilterType.tag],
    availableSorts: [SortOption.newest, SortOption.popular],
    contentIdPattern: r'.*',
    searchHelpText: 'Enter keywords to search...',
  );
}

/// Types of filters available for search
enum FilterType {
  tag('Tags'),
  artist('Artists'),
  group('Groups'),
  parody('Parodies'),
  character('Characters'),
  language('Languages'),
  category('Categories');

  final String displayName;
  const FilterType(this.displayName);
}
