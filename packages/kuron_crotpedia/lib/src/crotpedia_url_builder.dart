/// Centralized URL construction for Crotpedia website.
class CrotpediaUrlBuilder {
  static const String baseUrl = 'https://crotpedia.net';

  // ============ Browse URLs ============

  /// Homepage
  static String home() => baseUrl;

  /// Pagination
  static String page(int pageNum) => '$baseUrl/page/$pageNum/';

  /// Doujin list (alphabetical)
  static String doujinList() => '$baseUrl/doujin-list/';

  /// Series detail
  static String seriesDetail(String slug) => '$baseUrl/baca/series/$slug/';

  /// Chapter reader
  static String chapterReader(String slug) => '$baseUrl/baca/$slug/';

  /// Genre page
  static String genre(String genreSlug) => '$baseUrl/baca/genre/$genreSlug/';

  // ============ Search URLs ============

  /// Simple search
  static String simpleSearch(String query) {
    return '$baseUrl/?s=${Uri.encodeComponent(query)}';
  }

  /// Advanced search - ALL params required (even if empty)
  static String advancedSearch({
    String title = '',
    String author = '',
    String artist = '',
    String year = '',
    String status = '', // ongoing, completed, or empty
    String type = '', // Manga, Doujinshi, etc
    String order = 'update',
    List<String> genres = const [],
  }) {
    final params = [
      'title=${Uri.encodeComponent(title)}',
      'author=${Uri.encodeComponent(author)}',
      'artist=${Uri.encodeComponent(artist)}',
      'yearx=${Uri.encodeComponent(year)}',
      'status=${Uri.encodeComponent(status)}',
      'type=${Uri.encodeComponent(type)}',
      'order=${Uri.encodeComponent(order)}',
    ];

    for (final genre in genres) {
      params.add('genre[]=${Uri.encodeComponent(genre)}');
    }

    return '$baseUrl/advanced-search/?${params.join('&')}';
  }

  // ============ Auth URLs ============

  static String login() => '$baseUrl/login/';
  static String register() => '$baseUrl/register/';
  static String bookmark() => '$baseUrl/bookmark/';

  // ============ REST API URLs ============

  static String apiPosts({int page = 1, int perPage = 10}) {
    return '$baseUrl/wp-json/wp/v2/posts?page=$page&per_page=$perPage';
  }

  static String apiPost(int id) => '$baseUrl/wp-json/wp/v2/posts/$id';
}
