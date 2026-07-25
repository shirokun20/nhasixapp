library;

import 'nhentai_api_models.dart';

class NhentaiImageUrlBuilder {
  static const String thumbnailBaseUrl = 'https://t.nhentai.net/galleries';

  static const String imageBaseUrl = 'https://i.nhentai.net/galleries';

  static const List<String> imageServers = [
    'https://i.nhentai.net/galleries',
    'https://i2.nhentai.net/galleries',
    'https://i3.nhentai.net/galleries',
    'https://i5.nhentai.net/galleries',
    'https://i7.nhentai.net/galleries',
  ];

  static String buildCoverUrl(String mediaId, String type) {
    final ext = getImageExtension(type);
    return '$thumbnailBaseUrl/$mediaId/cover.$ext';
  }

  static String buildThumbnailUrl(String mediaId, String type) {
    final ext = getImageExtension(type);
    return '$thumbnailBaseUrl/$mediaId/thumb.$ext';
  }

  static String buildPageThumbnailUrl(
      String mediaId, int pageNumber, String type) {
    final ext = getImageExtension(type);
    return '$thumbnailBaseUrl/$mediaId/${pageNumber}t.$ext';
  }

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

  static Map<String, int> getPageDimensions(NhentaiImageInfo pageInfo) {
    return {
      'width': pageInfo.width ?? 0,
      'height': pageInfo.height ?? 0,
    };
  }

  static double calculateAspectRatio(NhentaiImageInfo pageInfo) {
    final width = pageInfo.width ?? 0;
    final height = pageInfo.height ?? 0;

    if (width <= 0 || height <= 0) {
      return 1.414; // Default A4 aspect ratio
    }

    return height / width;
  }

  static String? tryNextServer(String currentUrl) {
    for (int i = 0; i < imageServers.length - 1; i++) {
      if (currentUrl.startsWith(imageServers[i])) {
        return currentUrl.replaceFirst(imageServers[i], imageServers[i + 1]);
      }
    }
    return null; // All servers exhausted
  }
}
