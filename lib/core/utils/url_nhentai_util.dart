import 'package:nhasixapp/domain/entities/entities.dart';

/// @deprecated Use SearchFilter.toQueryString() instead
/// This utility is kept for backward compatibility but SearchFilter
/// provides more comprehensive URL building capabilities.
///
/// SearchFilter already includes:
/// - Complete query building with toQueryString()
/// - Built-in validation with isEmpty property
/// - Proper encoding and parameter handling
/// - Support for all filter types (tags, artists, characters, etc.)
@Deprecated('Use SearchFilter.toQueryString() instead')
class UrlNhentaiUtil {
  final String baseUrl;
  String? language;
  List<String>? includeTags;
  List<String>? excludeTags;
  List<String>? artists;
  List<String>? characters;
  List<String>? parodies;
  List<String>? groups;
  String? category;
  String? textQuery;
  int page;

  UrlNhentaiUtil(
    this.baseUrl, {
    this.language,
    this.includeTags,
    this.excludeTags,
    this.artists,
    this.characters,
    this.parodies,
    this.groups,
    this.category,
    this.textQuery,
    this.page = 1,
  });

  /// Create UrlNhentaiUtil from SearchFilter
  factory UrlNhentaiUtil.fromSearchFilter(String baseUrl, SearchFilter filter) {
    return UrlNhentaiUtil(
      baseUrl,
      language: filter.language,
      includeTags:
          filter.tags.where((t) => !t.isExcluded).map((t) => t.value).toList(),
      excludeTags:
          filter.tags.where((t) => t.isExcluded).map((t) => t.value).toList(),
      artists: filter.artists
          .where((a) => !a.isExcluded)
          .map((a) => a.value)
          .toList(),
      characters: filter.characters
          .where((c) => !c.isExcluded)
          .map((c) => c.value)
          .toList(),
      parodies: filter.parodies
          .where((p) => !p.isExcluded)
          .map((p) => p.value)
          .toList(),
      groups: filter.groups
          .where((g) => !g.isExcluded)
          .map((g) => g.value)
          .toList(),
      category: filter.category,
      textQuery: filter.query,
      page: filter.page,
    );
  }

  String buildWithSearch() {
    // Mulai membangun query string
    String query = '';

    // Tambahkan text query jika ada
    if (textQuery != null && textQuery!.isNotEmpty) {
      query += textQuery!;
    }

    // Tambahkan parameter language jika tidak kosong
    if (language != null && language!.isNotEmpty) {
      if (query.isNotEmpty) query += ' ';
      query += 'language:"$language"';
    }

    // Tambahkan category jika tidak kosong
    if (category != null && category!.isNotEmpty) {
      if (query.isNotEmpty) query += ' ';
      query += 'category:"$category"';
    }

    // Tambahkan tag yang harus ada
    if (includeTags != null && includeTags!.isNotEmpty) {
      for (var tag in includeTags!) {
        if (query.isNotEmpty) query += ' ';
        query += 'tag:"$tag"';
      }
    }

    // Tambahkan tag yang harus dikecualikan
    if (excludeTags != null && excludeTags!.isNotEmpty) {
      for (var tag in excludeTags!) {
        if (query.isNotEmpty) query += ' ';
        query += '-tag:"$tag"';
      }
    }

    // Tambahkan artists yang harus ada
    if (artists != null && artists!.isNotEmpty) {
      for (var artist in artists!) {
        if (query.isNotEmpty) query += ' ';
        query += 'artist:"$artist"';
      }
    }

    // Tambahkan characters yang harus ada
    if (characters != null && characters!.isNotEmpty) {
      for (var character in characters!) {
        if (query.isNotEmpty) query += ' ';
        query += 'character:"$character"';
      }
    }

    // Tambahkan parodies yang harus ada
    if (parodies != null && parodies!.isNotEmpty) {
      for (var parody in parodies!) {
        if (query.isNotEmpty) query += ' ';
        query += 'parody:"$parody"';
      }
    }

    // Tambahkan groups yang harus ada
    if (groups != null && groups!.isNotEmpty) {
      for (var group in groups!) {
        if (query.isNotEmpty) query += ' ';
        query += 'group:"$group"';
      }
    }

    // Gabungkan dengan URL dasar dan parameter halaman
    if (query.isEmpty) {
      // If no search filters, use main page format
      final pageParam = page > 1 ? '?page=$page' : '';
      return '$baseUrl/$pageParam';
    } else {
      // Use search format with filters
      final url = '$baseUrl/search/?q=$query&page=$page';
      return url; // Encode URL agar valid
    }
  }

  String buildWithPageOnly() {
    return '$baseUrl/?page=$page';
  }
}

// Contoh penggunaan dengan SearchFilter
// final filter = SearchFilter(
//   query: 'some text',
//   tags: [FilterItem.include('tag1'), FilterItem.exclude('tag2')],
//   artists: [FilterItem.include('artist1')],
//   language: 'english',
//   page: 1
// );
// UrlNhentaiUtil urlUtil = UrlNhentaiUtil.fromSearchFilter('https://nhentai.net', filter);
// final builtUrl = urlUtil.buildWithSearch();
// print(builtUrl);

// Contoh penggunaan withSearch manual (backward compatibility)
// UrlNhentaiUtil urlUtil = UrlNhentaiUtil('https://nhentai.net',
//   language: 'english',
//   includeTags: ['tag1'],
//   excludeTags: ['tag2'],
//   artists: ['artist1'],
//   page: 1
// );
// final builtUrl = urlUtil.buildWithSearch();
// print(builtUrl);
// Output: https://nhentai.net/search/?q=+language:"english"+tag:"loli"+artist:"leonat"+-tag:"shota"&page=1

// Contoh penggunaan withPageOnly
// UrlUtil urlUtil = UrlUtil('https://nhentai.net', page: 2);
// final builtUrl = urlUtil.buildWithPageOnly();
// print(builtUrl);
// Output: https://nhentai.net/?page=2
