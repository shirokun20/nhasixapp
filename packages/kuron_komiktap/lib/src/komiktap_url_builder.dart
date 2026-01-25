/// URL construction utilities for KomikTap website.
class KomiktapUrlBuilder {
  static const String baseUrl = 'https://komiktap.info';

  /// Build homepage URL with pagination
  /// Page 1: https://komiktap.info/
  /// Page 2+: https://komiktap.info/page/2/
  static String buildHomeUrl({int page = 1, String baseUrl = baseUrl}) {
    if (page <= 1) {
      return baseUrl;
    }
    return '$baseUrl/page/$page/';
  }

  /// Build search URL
  /// Page 1: https://komiktap.info/?s=query
  /// Page 2+: https://komiktap.info/page/2/?s=query
  static String buildSearchUrl(String query, {int page = 1, String baseUrl = baseUrl}) {
    final encodedQuery = Uri.encodeComponent(query);
    if (page <= 1) {
      return '$baseUrl/?s=$encodedQuery';
    }
    return '$baseUrl/page/$page/?s=$encodedQuery';
  }

  /// Build series detail URL
  /// Format: https://komiktap.info/manga/{slug}/
  static String buildSeriesDetailUrl(String slug, {String baseUrl = baseUrl}) {
    return '$baseUrl/manga/$slug/';
  }

  /// Build chapter reader URL
  /// Format: https://komiktap.info/{slug}-chapter-{num}/
  static String buildChapterUrl(String slug, int chapterNum, {String baseUrl = baseUrl}) {
    return '$baseUrl/$slug-chapter-$chapterNum/';
  }

  /// Build chapter URL from full slug
  /// For cases where we already have the full chapter slug
  static String buildChapterUrlFromSlug(String chapterSlug, {String baseUrl = baseUrl}) {
    return '$baseUrl/$chapterSlug/';
  }

  /// Build genre/tag filtered URL
  /// Page 1: https://komiktap.info/genres/{slug}/
 /// Page 2+: https://komiktap.info/genres/{slug}/page/2/
  static String buildGenreUrl(String genreSlug, {int page = 1, String baseUrl = baseUrl}) {
    if (page <= 1) {
      return '$baseUrl/genres/$genreSlug/';
    }
    return '$baseUrl/genres/$genreSlug/page/$page/';
  }

  /// Extract slug from full URL
  /// https://komiktap.info/manga/adabana-boku-no-onee-chan/ -> adabana-boku-no-onee-chan
  static String? extractSlugFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Match /manga/{slug}/ or /{slug}-chapter-{num}/
    final mangaRegex = RegExp(r'/manga/([^/]+)');
    final chapterRegex = RegExp(r'/([^/]+)-chapter-\d+');
    
    var match = mangaRegex.firstMatch(url);
    if (match != null) {
      return match.group(1);
    }
    
    match = chapterRegex.firstMatch(url);
    if (match != null) {
      return match.group(1);
    }
    
    return null;
  }

  /// Parse chapter number from URL
  /// https://komiktap.info/manga-slug-chapter-12/ -> 12
  static int? extractChapterNumber(String? url) {
    if (url == null || url.isEmpty) return null;
    
    final regex = RegExp(r'-chapter-(\d+)');
    final match = regex.firstMatch(url);
    
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    
    return null;
  }
}
