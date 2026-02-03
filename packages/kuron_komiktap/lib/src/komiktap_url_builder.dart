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
  /// Example: 67 -> ...-chapter-67/
  /// Example: 67.5 -> ...-chapter-67-5/
  static String buildChapterUrl(String slug, dynamic chapterNum, {String baseUrl = baseUrl}) {
    String numStr = chapterNum.toString();
    // Replace dot with hyphen for decimals in URL
    if (numStr.contains('.')) {
       numStr = numStr.replaceAll('.', '-');
    }
    return '$baseUrl/$slug-chapter-$numStr/';
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
  /// https://komiktap.info/wireless-onahole-chapter-67-5/ -> wireless-onahole-chapter-67-5
  static String? extractSlugFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      
      if (pathSegments.isNotEmpty) {
        // If it's a manga URL: /manga/slug/
        final mangaIndex = pathSegments.indexOf('manga');
        if (mangaIndex != -1 && mangaIndex + 1 < pathSegments.length) {
          return pathSegments[mangaIndex + 1];
        }
        
        // Return latest segment as fallback for chapter or other resources
        return pathSegments.last;
      }
    } catch (_) {}
    
    // Legacy Regex Fallback
    final mangaRegex = RegExp(r'/manga/([^/]+)');
    final chapterRegex = RegExp(r'/([^/]+?-chapter-[\d.-]+)');
    
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
  /// https://komiktap.info/manga-slug-chapter-67-5/ -> 67.5
  static double? extractChapterNumber(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Match number that might contain dots or hyphens
    final regex = RegExp(r'-chapter-([\d.-]+)');
    final match = regex.firstMatch(url);
    
    if (match != null) {
      String numStr = match.group(1)!;
      // Convert hyphenated decimal back to dot syntax
      if (numStr.contains('-')) {
        numStr = numStr.replaceAll('-', '.');
      }
      return double.tryParse(numStr);
    }
    
    return null;
  }
}
