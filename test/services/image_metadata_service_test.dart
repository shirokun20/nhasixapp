import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/models/image_metadata.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/services/image_metadata_service.dart';

/// Mock implementation of OfflineContentManager for testing
class MockOfflineContentManager implements OfflineContentManager {
  final Map<String, bool> _mockDownloadedStatus;

  MockOfflineContentManager(this._mockDownloadedStatus);

  @override
  Future<bool> isImageDownloaded(String imageUrl) async {
    return _mockDownloadedStatus[imageUrl] ?? false;
  }

  // Stub implementations for other methods (not used in tests)
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late ImageMetadataService service;
  late MockOfflineContentManager mockOfflineManager;
  late Logger logger;

  setUp(() {
    logger = Logger();
    mockOfflineManager = MockOfflineContentManager({
      'https://i.nhentai.net/galleries/12345/1.webp': true, // cached
      'https://i.nhentai.net/galleries/12345/2.webp': false, // online
      '/downloads/12345/images/1.webp': true, // local cached
    });

    service = ImageMetadataService(
      mockOfflineManager,
      logger,
    );
  });

  group('ImageMetadataService', () {
    const testContentId = '12345';

    test('should generate metadata for cached image', () async {
      // Arrange
      const cachedUrl = 'https://i.nhentai.net/galleries/12345/1.webp';

      // Act
      final metadata = await service.generateMetadata(
        imageUrl: cachedUrl,
        contentId: testContentId,
        pageNumber: 1,
      );

      // Assert
      expect(metadata.imageUrl, cachedUrl);
      expect(metadata.contentId, testContentId);
      expect(metadata.pageNumber, 1);
      expect(metadata.imageType, ImageType.cached);
    });

    test('should generate metadata for online image', () async {
      // Arrange
      const onlineUrl = 'https://i.nhentai.net/galleries/12345/2.webp';

      // Act
      final metadata = await service.generateMetadata(
        imageUrl: onlineUrl,
        contentId: testContentId,
        pageNumber: 2,
      );

      // Assert
      expect(metadata.imageUrl, onlineUrl);
      expect(metadata.contentId, testContentId);
      expect(metadata.pageNumber, 2);
      expect(metadata.imageType, ImageType.online);
    });

    test('should extract page number from URL when not provided', () async {
      // Arrange
      const urlWithPage = 'https://i.nhentai.net/galleries/12345/5.webp';

      // Act
      final metadata = await service.generateMetadata(
        imageUrl: urlWithPage,
        contentId: testContentId,
        // pageNumber not provided
      );

      // Assert
      expect(metadata.pageNumber, 5);
    });

    test('should handle local file paths', () async {
      // Arrange
      const localPath = '/downloads/12345/images/1.webp';

      // Act
      final metadata = await service.generateMetadata(
        imageUrl: localPath,
        contentId: testContentId,
        pageNumber: 1,
      );

      // Assert
      expect(metadata.imageUrl, localPath);
      expect(metadata.imageType, ImageType.cached); // local paths are cached
    });

    test('should generate metadata batch correctly', () async {
      // Arrange
      final imageUrls = [
        'https://i.nhentai.net/galleries/12345/1.webp',
        'https://i.nhentai.net/galleries/12345/2.webp',
        'https://i.nhentai.net/galleries/12345/3.webp',
      ];

      // Act
      final metadataList = await service.generateMetadataBatch(
        imageUrls: imageUrls,
        contentId: testContentId,
      );

      // Assert
      expect(metadataList.length, 3);
      for (int i = 0; i < metadataList.length; i++) {
        final metadata = metadataList[i];
        expect(metadata.contentId, testContentId);
        expect(metadata.pageNumber, i + 1);
        expect(metadata.imageUrl, imageUrls[i]);
      }
    });

    test('should check if image is available offline', () async {
      // Arrange
      const cachedUrl = 'https://i.nhentai.net/galleries/12345/1.webp';
      const onlineUrl = 'https://i.nhentai.net/galleries/12345/2.webp';

      // Act & Assert
      expect(await service.isImageAvailableOffline(cachedUrl), true);
      expect(await service.isImageAvailableOffline(onlineUrl), false);
    });

    test('should validate image URLs correctly', () {
      // Valid URLs
      expect(
          service
              .isValidImageUrl('https://i.nhentai.net/galleries/12345/1.webp'),
          true);
      expect(service.isValidImageUrl('https://example.com/image.jpg'), true);
      expect(service.isValidImageUrl('/downloads/12345/images/1.webp'), true);

      // Invalid URLs
      expect(service.isValidImageUrl('not-a-url'), false);
      expect(service.isValidImageUrl('ftp://example.com/image.jpg'), false);
      expect(service.isValidImageUrl(''), false);
    });

    test('should return metadata summary for debugging', () async {
      // Arrange
      const testUrl = 'https://i.nhentai.net/galleries/12345/1.webp';
      final metadata = await service.generateMetadata(
        imageUrl: testUrl,
        contentId: testContentId,
        pageNumber: 1,
      );

      // Act
      final summary = service.getMetadataSummary(metadata);

      // Assert
      expect(summary['contentId'], testContentId);
      expect(summary['pageNumber'], 1);
      expect(summary['imageType'], 'cached');
      expect(summary['urlLength'], testUrl.length);
      expect(summary['isValidUrl'], true);
    });

    test('should handle errors gracefully', () async {
      // Arrange - invalid URL that might cause parsing errors
      const invalidUrl = 'invalid-url';

      // Act
      final metadata = await service.generateMetadata(
        imageUrl: invalidUrl,
        contentId: testContentId,
        pageNumber: 1,
      );

      // Assert - should return basic metadata with defaults
      expect(metadata.imageUrl, invalidUrl);
      expect(metadata.contentId, testContentId);
      expect(metadata.pageNumber, 1);
      expect(metadata.imageType, ImageType.online); // default on error
    });
  });
}
