import '../../../domain/entities/search_filter.dart';

/// Builder class for constructing search queries with Matrix Filter Support
/// Handles include/exclude filters and validates single vs multiple select filters
class SearchQueryBuilder {
  /// Build query string from SearchFilter according to Matrix Filter Support rules
  ///
  /// Output format: "+-tag:"a1"+-artist:"b1"+language:"english""
  ///
  /// Matrix Filter Support:
  /// - Tag: Multiple, can include/exclude
  /// - Artist: Multiple, can include/exclude
  /// - Character: Multiple, can include/exclude
  /// - Parody: Multiple, can include/exclude
  /// - Group: Multiple, can include/exclude
  /// - Language: Single select only
  /// - Category: Single select only
  static String buildQuery(SearchFilter filter) {
    final queryParts = <String>[];

    // Add text query if present (no prefix)
    if (filter.query != null && filter.query!.isNotEmpty) {
      queryParts.add(filter.query!);
    }

    // Add tags with include/exclude (multiple allowed)
    for (final tag in filter.tags) {
      queryParts.add('${tag.prefix}tag:"${tag.value}"');
    }

    // Add artists with include/exclude (multiple allowed)
    for (final artist in filter.artists) {
      queryParts.add('${artist.prefix}artist:"${artist.value}"');
    }

    // Add characters with include/exclude (multiple allowed)
    for (final character in filter.characters) {
      queryParts.add('${character.prefix}character:"${character.value}"');
    }

    // Add parodies with include/exclude (multiple allowed)
    for (final parody in filter.parodies) {
      queryParts.add('${parody.prefix}parody:"${parody.value}"');
    }

    // Add groups with include/exclude (multiple allowed)
    for (final group in filter.groups) {
      queryParts.add('${group.prefix}group:"${group.value}"');
    }

    // Add single select filters (no prefix, only one allowed)
    if (filter.language != null) {
      queryParts.add('language:"${filter.language}"');
    }

    if (filter.category != null) {
      queryParts.add('category:"${filter.category}"');
    }

    return queryParts.join(' ');
  }

  /// Build full URL query string with all parameters
  static String buildUrlQuery(SearchFilter filter) {
    final params = <String>[];

    // Build main query part
    final queryString = buildQuery(filter);
    if (queryString.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(queryString)}');
    }

    // Add other parameters
    if (filter.popular) {
      params.add('popular=true');
    }

    params.add('sort=${filter.sortBy.apiValue}');
    params.add('page=${filter.page}');

    return params.join('&');
  }

  /// Validate filter according to Matrix Filter Support rules
  static FilterValidationResult validateFilter(SearchFilter filter) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate single select filters
    if (filter.language != null && filter.language!.isEmpty) {
      errors.add('Language cannot be empty');
    }

    if (filter.category != null && filter.category!.isEmpty) {
      errors.add('Category cannot be empty');
    }

    // Validate multiple select filters
    if (filter.tags.any((item) => item.value.isEmpty)) {
      errors.add('Tag values cannot be empty');
    }

    if (filter.artists.any((item) => item.value.isEmpty)) {
      errors.add('Artist values cannot be empty');
    }

    if (filter.characters.any((item) => item.value.isEmpty)) {
      errors.add('Character values cannot be empty');
    }

    if (filter.parodies.any((item) => item.value.isEmpty)) {
      errors.add('Parody values cannot be empty');
    }

    if (filter.groups.any((item) => item.value.isEmpty)) {
      errors.add('Group values cannot be empty');
    }

    // Check for duplicate values in multiple select filters
    final tagValues = filter.tags.map((item) => item.value).toList();
    if (tagValues.length != tagValues.toSet().length) {
      warnings.add('Duplicate tag values detected');
    }

    final artistValues = filter.artists.map((item) => item.value).toList();
    if (artistValues.length != artistValues.toSet().length) {
      warnings.add('Duplicate artist values detected');
    }

    final characterValues =
        filter.characters.map((item) => item.value).toList();
    if (characterValues.length != characterValues.toSet().length) {
      warnings.add('Duplicate character values detected');
    }

    final parodyValues = filter.parodies.map((item) => item.value).toList();
    if (parodyValues.length != parodyValues.toSet().length) {
      warnings.add('Duplicate parody values detected');
    }

    final groupValues = filter.groups.map((item) => item.value).toList();
    if (groupValues.length != groupValues.toSet().length) {
      warnings.add('Duplicate group values detected');
    }

    // Validate page range
    if (filter.page < 1) {
      errors.add('Page number must be greater than 0');
    }

    // Validate page count range
    if (filter.pageCountRange != null) {
      final range = filter.pageCountRange!;
      if (range.min != null && range.min! < 1) {
        errors.add('Minimum page count must be greater than 0');
      }
      if (range.max != null && range.max! < 1) {
        errors.add('Maximum page count must be greater than 0');
      }
      if (range.min != null && range.max != null && range.min! > range.max!) {
        errors.add('Minimum page count cannot be greater than maximum');
      }
    }

    return FilterValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Check if filter type supports multiple values
  static bool isMultipleSelectFilter(String filterType) {
    switch (filterType.toLowerCase()) {
      case 'tag':
      case 'artist':
      case 'character':
      case 'parody':
      case 'group':
        return true;
      case 'language':
      case 'category':
        return false;
      default:
        return false;
    }
  }

  /// Check if filter type supports include/exclude
  static bool supportsIncludeExclude(String filterType) {
    switch (filterType.toLowerCase()) {
      case 'tag':
      case 'artist':
      case 'character':
      case 'parody':
      case 'group':
        return true;
      case 'language':
      case 'category':
        return false;
      default:
        return false;
    }
  }

  /// Get filter type display name
  static String getFilterTypeDisplayName(String filterType) {
    switch (filterType.toLowerCase()) {
      case 'tag':
        return 'Tags';
      case 'artist':
        return 'Artists';
      case 'character':
        return 'Characters';
      case 'parody':
        return 'Parodies';
      case 'group':
        return 'Groups';
      case 'language':
        return 'Language';
      case 'category':
        return 'Category';
      default:
        return filterType;
    }
  }

  /// Parse query string back to SearchFilter (for URL parsing)
  static SearchFilter parseQuery(String queryString) {
    const filter = SearchFilter();

    if (queryString.isEmpty) {
      return filter;
    }

    // Split by spaces but preserve quoted strings
    final parts = _parseQueryParts(queryString);

    final tags = <FilterItem>[];
    final artists = <FilterItem>[];
    final characters = <FilterItem>[];
    final parodies = <FilterItem>[];
    final groups = <FilterItem>[];
    String? language;
    String? category;
    String? textQuery;

    for (final part in parts) {
      if (part.startsWith('tag:"') && part.endsWith('"')) {
        final value = part.substring(5, part.length - 1);
        tags.add(FilterItem.include(value));
      } else if (part.startsWith('-tag:"') && part.endsWith('"')) {
        final value = part.substring(6, part.length - 1);
        tags.add(FilterItem.exclude(value));
      } else if (part.startsWith('artist:"') && part.endsWith('"')) {
        final value = part.substring(8, part.length - 1);
        artists.add(FilterItem.include(value));
      } else if (part.startsWith('-artist:"') && part.endsWith('"')) {
        final value = part.substring(9, part.length - 1);
        artists.add(FilterItem.exclude(value));
      } else if (part.startsWith('character:"') && part.endsWith('"')) {
        final value = part.substring(11, part.length - 1);
        characters.add(FilterItem.include(value));
      } else if (part.startsWith('-character:"') && part.endsWith('"')) {
        final value = part.substring(12, part.length - 1);
        characters.add(FilterItem.exclude(value));
      } else if (part.startsWith('parody:"') && part.endsWith('"')) {
        final value = part.substring(8, part.length - 1);
        parodies.add(FilterItem.include(value));
      } else if (part.startsWith('-parody:"') && part.endsWith('"')) {
        final value = part.substring(9, part.length - 1);
        parodies.add(FilterItem.exclude(value));
      } else if (part.startsWith('group:"') && part.endsWith('"')) {
        final value = part.substring(7, part.length - 1);
        groups.add(FilterItem.include(value));
      } else if (part.startsWith('-group:"') && part.endsWith('"')) {
        final value = part.substring(8, part.length - 1);
        groups.add(FilterItem.exclude(value));
      } else if (part.startsWith('language:"') && part.endsWith('"')) {
        language = part.substring(10, part.length - 1);
      } else if (part.startsWith('category:"') && part.endsWith('"')) {
        category = part.substring(10, part.length - 1);
      } else if (!part.contains(':')) {
        // Plain text query
        textQuery = part;
      }
    }

    return filter.copyWith(
      query: textQuery,
      tags: tags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: language,
      category: category,
    );
  }

  /// Parse query string into parts, preserving quoted strings
  static List<String> _parseQueryParts(String queryString) {
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < queryString.length; i++) {
      final char = queryString[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (char == ' ' && !inQuotes) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString().trim());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().trim());
    }

    return parts.where((part) => part.isNotEmpty).toList();
  }
}

/// Result of filter validation
class FilterValidationResult {
  const FilterValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  /// Check if has any issues
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;

  /// Get all issues as formatted string
  String get issuesText {
    final issues = <String>[];

    if (errors.isNotEmpty) {
      issues.add('Errors: ${errors.join(', ')}');
    }

    if (warnings.isNotEmpty) {
      issues.add('Warnings: ${warnings.join(', ')}');
    }

    return issues.join('\n');
  }
}
