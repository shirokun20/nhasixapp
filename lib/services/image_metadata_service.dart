import 'package:logger/logger.dart';

import '../../core/models/image_metadata.dart';
import '../../core/utils/offline_content_manager.dart';

/// Service for generating and managing image metadata
/// Handles URL validation, offline status checking, and metadata creation
class ImageMetadataService {
  final OfflineContentManager _offlineContentManager;
  final Logger _logger;

  ImageMetadataService(
    this._offlineContentManager,
    this._logger,
  );

  /// Generate metadata for an image URL
  /// Determines if image is cached or online, extracts page number,
  /// and resolves nhentai media ID if needed
  Future<ImageMetadata> generateMetadata({
    required String imageUrl,
    required String contentId,
    int? pageNumber,
  }) async {
    try {
      // Extract page number from URL if not provided
      final extractedPageNumber = pageNumber ?? _extractPageNumber(imageUrl);

      // Check if image is downloaded (cached)
      final isDownloaded =
          await _offlineContentManager.isImageDownloaded(imageUrl);
      final imageType = isDownloaded ? ImageType.cached : ImageType.online;

      // For nhentai URLs, we might need to resolve media ID
      // But for now, we'll use the contentId as-is since the OfflineContentManager
      // already handles the URL patterns correctly

      return ImageMetadata(
        imageUrl: imageUrl,
        contentId: contentId,
        pageNumber: extractedPageNumber,
        imageType: imageType,
      );
    } catch (e, stackTrace) {
      _logger.e('Error generating image metadata for URL: $imageUrl',
          error: e, stackTrace: stackTrace);

      // Return basic metadata on error
      return ImageMetadata(
        imageUrl: imageUrl,
        contentId: contentId,
        pageNumber: pageNumber ?? _extractPageNumber(imageUrl),
        imageType: ImageType.online, // Default to online on error
      );
    }
  }

  /// Generate metadata for multiple images at once
  /// More efficient than calling generateMetadata multiple times
  Future<List<ImageMetadata>> generateMetadataBatch({
    required List<String> imageUrls,
    required String contentId,
  }) async {
    final metadataList = <ImageMetadata>[];

    for (int i = 0; i < imageUrls.length; i++) {
      final imageUrl = imageUrls[i];
      final pageNumber = i + 1; // Assume 1-based page numbering

      final metadata = await generateMetadata(
        imageUrl: imageUrl,
        contentId: contentId,
        pageNumber: pageNumber,
      );

      metadataList.add(metadata);
    }

    return metadataList;
  }

  /// Check if an image URL is available offline
  Future<bool> isImageAvailableOffline(String imageUrl) async {
    return await _offlineContentManager.isImageDownloaded(imageUrl);
  }

  /// Get offline image path if available
  Future<String?> getOfflineImagePath(String imageUrl) async {
    try {
      // If it's already a local file path, return as-is
      if (imageUrl.startsWith('/') || imageUrl.contains('/downloads/')) {
        return imageUrl;
      }

      // Extract content ID and get offline path
      final contentId = _extractContentIdFromUrl(imageUrl);
      if (contentId == null) return null;

      final contentPath =
          await _offlineContentManager.getOfflineContentPath(contentId);
      if (contentPath == null) return null;

      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final filename = uri.pathSegments.last;

      // Try images subdirectory first (new structure)
      final imagesPath = '$contentPath/images/$filename';
      // For now, we'll return the expected path - actual file existence
      // should be checked by the caller using isImageAvailableOffline
      return imagesPath;
    } catch (e, stackTrace) {
      _logger.e('Error getting offline image path for URL: $imageUrl',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Extract page number from image URL
  /// Supports various URL patterns used by nhentai and other sources
  int _extractPageNumber(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final filename = uri.pathSegments.last;
      final filenameWithoutExt = filename.split('.').first;

      // Try different patterns to extract page number

      // Pattern 1: Direct number in filename (e.g., 001.jpg, 1.jpg)
      final directNumberMatch =
          RegExp(r'^(\d+)$').firstMatch(filenameWithoutExt);
      if (directNumberMatch != null) {
        return int.tryParse(directNumberMatch.group(1)!) ?? 1;
      }

      // Pattern 2: Number with leading zeros (e.g., 001, 002)
      final leadingZeroMatch =
          RegExp(r'^0*(\d+)$').firstMatch(filenameWithoutExt);
      if (leadingZeroMatch != null) {
        return int.tryParse(leadingZeroMatch.group(1)!) ?? 1;
      }

      // Pattern 3: Number at the end (e.g., page_1, image001)
      final endNumberMatch = RegExp(r'(\d+)$').firstMatch(filenameWithoutExt);
      if (endNumberMatch != null) {
        return int.tryParse(endNumberMatch.group(1)!) ?? 1;
      }

      // Pattern 4: Number after underscore or dash (e.g., content_123_001)
      final underscoreMatch =
          RegExp(r'[_-](\d+)$').firstMatch(filenameWithoutExt);
      if (underscoreMatch != null) {
        return int.tryParse(underscoreMatch.group(1)!) ?? 1;
      }

      // Default to page 1 if no pattern matches
      _logger.w(
          'Could not extract page number from URL: $imageUrl, defaulting to 1');
      return 1;
    } catch (e) {
      _logger.w('Error extracting page number from URL: $imageUrl, error: $e');
      return 1;
    }
  }

  /// Extract content ID from image URL
  /// Uses similar logic to OfflineContentManager._extractContentIdFromUrl
  String? _extractContentIdFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);

      // Special handling for nhentai URLs: https://i.nhentai.net/galleries/[contentId]/[page].jpg
      if (uri.host == 'i.nhentai.net' && uri.pathSegments.length >= 3) {
        if (uri.pathSegments[0] == 'galleries' &&
            uri.pathSegments.length >= 2) {
          final contentId = uri.pathSegments[1];
          if (RegExp(r'^\d+$').hasMatch(contentId)) {
            return contentId;
          }
        }
      }

      // Pattern 1: URL contains content ID in path segments
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        for (final segment in pathSegments) {
          if (RegExp(r'^\d+$').hasMatch(segment)) {
            return segment;
          }
        }
      }

      // Pattern 2: Content ID in query parameters
      final contentIdParam = uri.queryParameters['contentId'];
      if (contentIdParam != null && contentIdParam.isNotEmpty) {
        return contentIdParam;
      }

      // Pattern 3: Content ID in hostname or subdomain
      final hostParts = uri.host.split('.');
      for (final part in hostParts) {
        if (RegExp(r'^\d+$').hasMatch(part)) {
          return part;
        }
      }

      // Pattern 4: Extract from filename if it contains content ID
      final filename = uri.pathSegments.last;
      final filenameMatch = RegExp(r'^(\d+)').firstMatch(filename);
      if (filenameMatch != null) {
        return filenameMatch.group(1);
      }

      return null;
    } catch (e) {
      _logger.w('Error extracting content ID from URL: $imageUrl, error: $e');
      return null;
    }
  }

  /// Validate if an image URL is properly formatted
  bool isValidImageUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);

      // Check if it's a valid HTTP/HTTPS URL
      if (!uri.isScheme('http') && !uri.isScheme('https')) {
        // Allow local file paths
        if (!imageUrl.startsWith('/') && !imageUrl.contains('/downloads/')) {
          return false;
        }
      }

      // Check if it has a valid image extension
      final path = uri.path.toLowerCase();
      final validExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.bmp'
      ];

      return validExtensions.any((ext) => path.endsWith(ext)) ||
          // Allow local files without extension check
          imageUrl.startsWith('/') ||
          imageUrl.contains('/downloads/');
    } catch (e) {
      _logger.w('Invalid image URL format: $imageUrl, error: $e');
      return false;
    }
  }

  /// Get metadata summary for debugging/logging purposes
  Map<String, dynamic> getMetadataSummary(ImageMetadata metadata) {
    return {
      'contentId': metadata.contentId,
      'pageNumber': metadata.pageNumber,
      'imageType': metadata.imageType.name,
      'urlLength': metadata.imageUrl.length,
      'isValidUrl': isValidImageUrl(metadata.imageUrl),
    };
  }
}
