/// nhentai Image URL Builder
///
/// Utility class to construct image URLs from nhentai API response data.
/// Handles different image types and server selection.
library;

import 'nhentai_api_models.dart';

/// Builder class for constructing nhentai image URLs
class NhentaiImageUrlBuilder {
  /// Base URL for thumbnail/cover images
  static const String thumbnailBaseUrl = 'https://t.nhentai.net/galleries';

  /// Base URL for full-size page images
  static const String imageBaseUrl = 'https://i.nhentai.net/galleries';

  /// Alternative image servers (for fallback/load balancing)
  static const List<String> imageServers = [
    'https://i.nhentai.net/galleries',
    'https://i2.nhentai.net/galleries',
    'https://i3.nhentai.net/galleries',
    'https://i5.nhentai.net/galleries',
    'https://i7.nhentai.net/galleries',
  ];

  /// Build cover image URL
  ///
  /// [mediaId] - The media ID from API response
  /// [type] - Image type ('j', 'p', 'g', 'w')
  static String buildCoverUrl(String mediaId, String type) {
    final ext = getImageExtension(type);
    return '$thumbnailBaseUrl/$mediaId/cover.$ext';
  }

  /// Build thumbnail image URL
  ///
  /// [mediaId] - The media ID from API response
  /// [type] - Image type ('j', 'p', 'g', 'w')
  static String buildThumbnailUrl(String mediaId, String type) {
    final ext = getImageExtension(type);
    return '$thumbnailBaseUrl/$mediaId/thumb.$ext';
  }

  /// Build page thumbnail URL (for gallery view)
  ///
  /// [mediaId] - The media ID from API response
  /// [pageNumber] - 1-indexed page number
  /// [type] - Image type ('j', 'p', 'g', 'w')
  static String buildPageThumbnailUrl(
      String mediaId, int pageNumber, String type) {
    final ext = getImageExtension(type);
    return '$thumbnailBaseUrl/$mediaId/${pageNumber}t.$ext';
  }

  /// Build full-size page image URL
  ///
  /// [mediaId] - The media ID from API response
  /// [pageNumber] - 1-indexed page number
  /// [type] - Image type ('j', 'p', 'g', 'w')
  /// [serverIndex] - Optional server index (0-4) for load balancing
  static String buildPageUrl(
    String mediaId,
    int pageNumber,
    String type, {
    int serverIndex = 0,
  }) {
    final ext = getImageExtension(type);
    final baseUrl = imageServers[serverIndex.clamp(0, imageServers.length - 1)];
    return '$baseUrl/$mediaId/$pageNumber.$ext';
  }

  /// Build all page URLs from API images data
  ///
  /// [mediaId] - The media ID from API response
  /// [pages] - List of page image info from API
  /// [serverIndex] - Optional server index for load balancing
  static List<String> buildAllPageUrls(
    String mediaId,
    List<NhentaiImageInfo> pages, {
    int serverIndex = 0,
  }) {
    return pages.asMap().entries.map((entry) {
      final pageNumber = entry.key + 1; // 1-indexed
      final pageInfo = entry.value;
      return buildPageUrl(mediaId, pageNumber, pageInfo.type,
          serverIndex: serverIndex);
    }).toList();
  }

  /// Build all page thumbnail URLs from API images data
  ///
  /// [mediaId] - The media ID from API response
  /// [pages] - List of page image info from API
  static List<String> buildAllPageThumbnailUrls(
    String mediaId,
    List<NhentaiImageInfo> pages,
  ) {
    return pages.asMap().entries.map((entry) {
      final pageNumber = entry.key + 1; // 1-indexed
      final pageInfo = entry.value;
      return buildPageThumbnailUrl(mediaId, pageNumber, pageInfo.type);
    }).toList();
  }

  /// Get image dimensions from page info
  ///
  /// Returns a map with 'width' and 'height' keys
  static Map<String, int> getPageDimensions(NhentaiImageInfo pageInfo) {
    return {
      'width': pageInfo.width ?? 0,
      'height': pageInfo.height ?? 0,
    };
  }

  /// Calculate aspect ratio from page info
  ///
  /// Returns height/width ratio, defaults to 1.414 (A4) if dimensions unavailable
  static double calculateAspectRatio(NhentaiImageInfo pageInfo) {
    final width = pageInfo.width ?? 0;
    final height = pageInfo.height ?? 0;

    if (width <= 0 || height <= 0) {
      return 1.414; // Default A4 aspect ratio
    }

    return height / width;
  }

  /// Try alternative server if primary fails
  ///
  /// [currentUrl] - The current failing URL
  /// Returns URL with next server, or null if all servers exhausted
  static String? tryNextServer(String currentUrl) {
    for (int i = 0; i < imageServers.length - 1; i++) {
      if (currentUrl.startsWith(imageServers[i])) {
        return currentUrl.replaceFirst(imageServers[i], imageServers[i + 1]);
      }
    }
    return null; // All servers exhausted
  }
}
