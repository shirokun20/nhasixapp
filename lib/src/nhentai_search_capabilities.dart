import 'package:kuron_core/kuron_core.dart';

/// nhentai-specific search capabilities
const nhentaiSearchCapabilities = SearchCapabilities(
  supportsTagExclusion: true,
  supportsAdvancedSyntax: true,
  availableFilters: [
    FilterType.tag,
    FilterType.artist,
    FilterType.group,
    FilterType.parody,
    FilterType.character,
    FilterType.language,
    FilterType.category,
  ],
  availableSorts: [
    SortOption.newest,
    SortOption.popular,
    SortOption.popularToday,
    SortOption.popularWeek,
  ],
  contentIdPattern: r'^\d+$', // Numeric only
  searchHelpText: '''
Search syntax:
• tag:"tag name" - Search by tag
• artist:"name" - Search by artist  
• group:"name" - Search by group
• parody:"name" - Search by parody
• character:"name" - Search by character
• language:english - Filter by language
• category:doujinshi - Filter by category
• -tag:"name" - Exclude tag
• pages:>20 - Filter by page count
''',
  maxResultsPerPage: 25,
);
