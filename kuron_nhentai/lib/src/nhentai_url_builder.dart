/// URL builder utilities for nhentai.
class NhentaiUrlBuilder {
  static const String baseUrl = 'https://nhentai.net';
  static const String apiBaseUrl = 'https://nhentai.net/api';
  static const String imageHost = 'i.nhentai.net';
  static const String thumbnailHost = 't.nhentai.net';

  /// Build full-size image URL
  static String buildImageUrl({
    required String mediaId,
    required int page,
    required String extension,
  }) {
    return 'https://$imageHost/galleries/$mediaId/$page.$extension';
  }

  /// Build thumbnail URL
  static String buildThumbnailUrl({
    required String mediaId,
    String extension = 'jpg',
  }) {
    return 'https://$thumbnailHost/galleries/$mediaId/thumb.$extension';
  }

  /// Build cover URL
  static String buildCoverUrl({
    required String mediaId,
    String extension = 'jpg',
  }) {
    return 'https://$thumbnailHost/galleries/$mediaId/cover.$extension';
  }

  /// Build page thumbnail URL
  static String buildPageThumbnailUrl({
    required String mediaId,
    required int page,
    required String extension,
  }) {
    return 'https://$thumbnailHost/galleries/$mediaId/${page}t.$extension';
  }

  /// Build content detail URL
  static String buildContentUrl(String contentId) {
    return '$baseUrl/g/$contentId/';
  }

  /// Build API gallery URL
  static String buildApiGalleryUrl(String contentId) {
    return '$apiBaseUrl/gallery/$contentId';
  }

  /// Build search URL
  static String buildSearchUrl({
    required String query,
    int page = 1,
    String? sort,
  }) {
    final params = <String, String>{
      'q': query,
      'page': page.toString(),
    };
    if (sort != null) {
      params['sort'] = sort;
    }
    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$baseUrl/search/?$queryString';
  }

  /// Build tag URL
  static String buildTagUrl({
    required String tagName,
    int page = 1,
    String? sort,
  }) {
    final sortSuffix = sort ?? '';
    return '$baseUrl/tag/$tagName/$sortSuffix?page=$page';
  }

  /// Build popular URL
  static String buildPopularUrl({
    String timeframe = 'all',
    int page = 1,
  }) {
    final timeframePath = timeframe == 'all' ? '' : '-$timeframe';
    return '$baseUrl/popular$timeframePath?page=$page';
  }

  /// Parse content ID from URL
  static String? parseContentIdFromUrl(String url) {
    // Match patterns like /g/123456/ or nhentai.net/g/123456
    final regex = RegExp(r'/g/(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Validate content ID (must be numeric)
  static bool isValidContentId(String id) {
    return RegExp(r'^\d+$').hasMatch(id);
  }

  /// Get referer header
  static String get refererHeader => baseUrl;
}
