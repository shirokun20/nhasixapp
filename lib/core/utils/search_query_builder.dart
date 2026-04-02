import 'package:nhasixapp/domain/entities/search_filter.dart';

/// Utility class for building search queries compatible with API v2
/// Supports advanced query syntax including page filters
class SearchQueryBuilder {
  /// Build query string from SearchFilter
  /// Supports: keywords, tag filters, numeric filters (pages, favorites), date filters
  static String buildQueryFromFilter(SearchFilter filter) {
    final parts = <String>[];

    // Add text query (keywords)
    if (filter.query != null && filter.query!.isNotEmpty) {
      // Check if query already starts with 'raw:' prefix
      if (filter.query!.startsWith('raw:')) {
        return filter.query!.substring(4).trim();
      }
      parts.add(filter.query!);
    }

    // Add language filter
    if (filter.language != null && filter.language!.isNotEmpty) {
      parts.add('language:${_escapeValue(filter.language!)}');
    }

    // Add category filter
    if (filter.category != null && filter.category!.isNotEmpty) {
      parts.add('category:${_escapeValue(filter.category!)}');
    }

    // Add tag filters (included and excluded)
    for (final tag in filter.tags) {
      final value = _escapeValue(tag.value);
      if (tag.isExcluded) {
        parts.add('-tag:$value');
      } else {
        parts.add('tag:$value');
      }
    }

    // Add artist filters
    for (final artist in filter.artists) {
      final value = _escapeValue(artist.value);
      if (artist.isExcluded) {
        parts.add('-artist:$value');
      } else {
        parts.add('artist:$value');
      }
    }

    // Add character filters
    for (final character in filter.characters) {
      final value = _escapeValue(character.value);
      if (character.isExcluded) {
        parts.add('-character:$value');
      } else {
        parts.add('character:$value');
      }
    }

    // Add parody filters
    for (final parody in filter.parodies) {
      final value = _escapeValue(parody.value);
      if (parody.isExcluded) {
        parts.add('-parody:$value');
      } else {
        parts.add('parody:$value');
      }
    }

    // Add group filters
    for (final group in filter.groups) {
      final value = _escapeValue(group.value);
      if (group.isExcluded) {
        parts.add('-group:$value');
      } else {
        parts.add('group:$value');
      }
    }

    // Add page count filters (pages:>10, pages:<=50)
    // Support NClientV3-style page:> and page:<= syntax
    if (filter.pageCountRange != null) {
      final range = filter.pageCountRange!;
      if (range.min != null) {
        parts.add('pages:>=${range.min}');
      }
      if (range.max != null) {
        parts.add('pages:<=${range.max}');
      }
    }

    return parts.join(' ');
  }

  /// Escape special characters in filter values
  /// Wraps multi-word values in quotes
  static String _escapeValue(String value) {
    // If value contains spaces or special characters, wrap in quotes
    if (value.contains(' ') ||
        value.contains(':') ||
        value.contains('"') ||
        value.contains('-')) {
      // Escape existing quotes
      final escaped = value.replaceAll('"', '\\"');
      return '"$escaped"';
    }
    return value;
  }

  /// Parse query string back to individual components
  /// Useful for analyzing existing queries
  static Map<String, dynamic> parseQueryString(String query) {
    final result = <String, dynamic>{
      'keywords': <String>[],
      'filters': <String, List<String>>{},
      'numericFilters': <String, Map<String, dynamic>>{},
    };

    // Split by spaces, but respect quoted strings
    final tokens = _tokenizeQuery(query);

    for (final token in tokens) {
      if (token.contains(':')) {
        // This is a filter
        final parts = token.split(':');
        if (parts.length >= 2) {
          var key = parts[0];
          final value = parts.sublist(1).join(':');

          // Check if it's a negation
          final isNegated = key.startsWith('-');
          if (isNegated) {
            key = key.substring(1);
          }

          // Check if it's a numeric filter (pages:>, favorites:>=)
          if (value.startsWith('>') ||
              value.startsWith('<') ||
              value.startsWith('>=') ||
              value.startsWith('<=')) {
            result['numericFilters'][key] = {
              'operator': value.substring(
                0,
                value.startsWith('>=') || value.startsWith('<=') ? 2 : 1,
              ),
              'value': value.substring(
                value.startsWith('>=') || value.startsWith('<=') ? 2 : 1,
              ),
            };
          } else {
            // Regular filter
            result['filters'][key] ??= <String>[];
            result['filters'][key].add(isNegated ? '-$value' : value);
          }
        }
      } else {
        // This is a keyword
        result['keywords'].add(token);
      }
    }

    return result;
  }

  /// Tokenize query string respecting quoted strings
  static List<String> _tokenizeQuery(String query) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;

    for (var i = 0; i < query.length; i++) {
      final char = query[i];

      if (char == '"' && (i == 0 || query[i - 1] != '\\')) {
        inQuote = !inQuote;
        buffer.write(char);
      } else if (char == ' ' && !inQuote) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString().trim());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString().trim());
    }

    return tokens;
  }
}
