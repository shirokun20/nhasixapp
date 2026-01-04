import 'package:kuron_core/kuron_core.dart';

/// Search capabilities for Crotpedia source.
final crotpediaSearchCapabilities = SearchCapabilities(
  supportsTagExclusion: false, // No tag exclusion for Crotpedia
  supportsAdvancedSyntax: true, // Advanced search available
  availableFilters: const [
    FilterType.tag, // Genres
    FilterType.category, // Type (Manga, Doujinshi, etc)
  ],
  availableSorts: const [
    SortOption.newest, // update
    SortOption.popular, // popular
  ],
  contentIdPattern: r'^[a-z0-9-]+$', // Slug format
  searchHelpText: 'Search by title, author, artist, or genre',
  maxResultsPerPage: 24,
);
