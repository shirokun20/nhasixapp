import 'package:nhasixapp/domain/entities/search_filter.dart';

class SearchFilterPresenter {
  const SearchFilterPresenter._();

  /// Get helpful message based on filter
  static String buildHelpfulMessage(SearchFilter filter) {
    if (filter.hasFilters) {
      return 'Try adjusting your search filters or search terms.';
    } else {
      return 'Try searching with different keywords.';
    }
  }

  /// Get filter summary for display
  static String buildFilterSummary(SearchFilter filter) {
    final parts = <String>[];

    if (filter.query != null && filter.query!.isNotEmpty) {
      parts.add('Query: "${filter.query}"');
    }

    if (filter.tags.isNotEmpty) {
      final includeTags = filter.tags
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeTags = filter.tags
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeTags.isNotEmpty) {
        parts.add('Tags: ${includeTags.join(', ')}');
      }
      if (excludeTags.isNotEmpty) {
        parts.add('Exclude Tags: ${excludeTags.join(', ')}');
      }
    }

    if (filter.groups.isNotEmpty) {
      final includeGroups = filter.groups
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeGroups = filter.groups
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeGroups.isNotEmpty) {
        parts.add('Groups: ${includeGroups.join(', ')}');
      }
      if (excludeGroups.isNotEmpty) {
        parts.add('Exclude Groups: ${excludeGroups.join(', ')}');
      }
    }

    if (filter.characters.isNotEmpty) {
      final includeCharacters = filter.characters
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeCharacters = filter.characters
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeCharacters.isNotEmpty) {
        parts.add('Characters: ${includeCharacters.join(', ')}');
      }
      if (excludeCharacters.isNotEmpty) {
        parts.add('Exclude Characters: ${excludeCharacters.join(', ')}');
      }
    }

    if (filter.parodies.isNotEmpty) {
      final includeParodies = filter.parodies
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeParodies = filter.parodies
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeParodies.isNotEmpty) {
        parts.add('Parodies: ${includeParodies.join(', ')}');
      }
      if (excludeParodies.isNotEmpty) {
        parts.add('Exclude Parodies: ${excludeParodies.join(', ')}');
      }
    }

    if (filter.artists.isNotEmpty) {
      final includeArtists = filter.artists
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeArtists = filter.artists
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeArtists.isNotEmpty) {
        parts.add('Artists: ${includeArtists.join(', ')}');
      }
      if (excludeArtists.isNotEmpty) {
        parts.add('Exclude Artists: ${excludeArtists.join(', ')}');
      }
    }

    if (filter.language != null) {
      parts.add('Language: ${filter.language}');
    }

    if (filter.category != null) {
      parts.add('Category: ${filter.category}');
    }

    return parts.join(' • ');
  }
}
