import 'package:kuron_core/kuron_core.dart';

/// Search capabilities for KomikTap source
const komiktapSearchCapabilities = SearchCapabilities(
  // KomikTap doesn't support tag exclusion
  supportsTagExclusion: false,

  // KomikTap doesn't support advanced syntax
  supportsAdvancedSyntax: false,

  // KomikTap only supports basic tag filtering via genres
  availableFilters: [FilterType.tag],

  // KomikTap supports simple latest/newest sorting
  availableSorts: [SortOption.newest],

  // KomikTap uses slug-based IDs (lowercase alphanumeric with hyphens)
  contentIdPattern: r'^[a-z0-9-]+$',

  // Help text for KomikTap search
  searchHelpText: 'Enter series title to search...',

  // Results per page
  maxResultsPerPage: 24,
);
