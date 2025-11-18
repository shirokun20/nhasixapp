import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/models/image_metadata.dart';

void main() {
  group('ImageMetadata', () {
    const testImageUrl = 'https://i.nhentai.net/galleries/12345/1.webp';
    const testContentId = '12345';
    const testPageNumber = 1;

    test('should create ImageMetadata with online type', () {
      // Arrange & Act
      const metadata = ImageMetadata(
        imageUrl: testImageUrl,
        contentId: testContentId,
        pageNumber: testPageNumber,
        imageType: ImageType.online,
      );

      // Assert
      expect(metadata.imageUrl, testImageUrl);
      expect(metadata.contentId, testContentId);
      expect(metadata.pageNumber, testPageNumber);
      expect(metadata.imageType, ImageType.online);
    });

    test('should create ImageMetadata with cached type', () {
      // Arrange & Act
      const metadata = ImageMetadata(
        imageUrl: testImageUrl,
        contentId: testContentId,
        pageNumber: testPageNumber,
        imageType: ImageType.cached,
      );

      // Assert
      expect(metadata.imageUrl, testImageUrl);
      expect(metadata.contentId, testContentId);
      expect(metadata.pageNumber, testPageNumber);
      expect(metadata.imageType, ImageType.cached);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      const metadata = ImageMetadata(
        imageUrl: testImageUrl,
        contentId: testContentId,
        pageNumber: testPageNumber,
        imageType: ImageType.online,
      );

      // Act
      final json = metadata.toJson();

      // Assert
      expect(json['imageUrl'], testImageUrl);
      expect(json['contentId'], testContentId);
      expect(json['pageNumber'], testPageNumber);
      expect(json['imageType'], 'online');
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'imageUrl': testImageUrl,
        'contentId': testContentId,
        'pageNumber': testPageNumber,
        'imageType': 'online',
      };

      // Act
      final metadata = ImageMetadata.fromJson(json);

      // Assert
      expect(metadata.imageUrl, testImageUrl);
      expect(metadata.contentId, testContentId);
      expect(metadata.pageNumber, testPageNumber);
      expect(metadata.imageType, ImageType.online);
    });

    test('should handle cached type in JSON serialization', () {
      // Arrange
      const metadata = ImageMetadata(
        imageUrl: testImageUrl,
        contentId: testContentId,
        pageNumber: testPageNumber,
        imageType: ImageType.cached,
      );

      // Act
      final json = metadata.toJson();

      // Assert
      expect(json['imageType'], 'cached');

      // Test round-trip
      final deserialized = ImageMetadata.fromJson(json);
      expect(deserialized.imageType, ImageType.cached);
    });

    test('should support copyWith method', () {
      // Arrange
      const original = ImageMetadata(
        imageUrl: testImageUrl,
        contentId: testContentId,
        pageNumber: testPageNumber,
        imageType: ImageType.online,
      );

      // Act
      final copied = original.copyWith(
        pageNumber: 2,
        imageType: ImageType.cached,
      );

      // Assert
      expect(copied.imageUrl, testImageUrl); // unchanged
      expect(copied.contentId, testContentId); // unchanged
      expect(copied.pageNumber, 2); // changed
      expect(copied.imageType, ImageType.cached); // changed
    });

    test('should handle different page numbers', () {
      // Test various page numbers
      const pages = [1, 5, 10, 100, 999];

      for (final page in pages) {
        final metadata = ImageMetadata(
          imageUrl: '$testImageUrl$page.webp',
          contentId: testContentId,
          pageNumber: page,
          imageType: ImageType.online,
        );

        expect(metadata.pageNumber, page);

        // Test JSON round-trip
        final json = metadata.toJson();
        final deserialized = ImageMetadata.fromJson(json);
        expect(deserialized.pageNumber, page);
      }
    });

    test('should be immutable (no setters)', () {
      // Arrange
      const metadata = ImageMetadata(
        imageUrl: testImageUrl,
        contentId: testContentId,
        pageNumber: testPageNumber,
        imageType: ImageType.online,
      );

      // Assert that all properties are final (no setters available)
      // This is ensured by Freezed generating only getters
      expect(metadata.imageUrl, testImageUrl);
      expect(metadata.contentId, testContentId);
      expect(metadata.pageNumber, testPageNumber);
      expect(metadata.imageType, ImageType.online);
    });
  });
}
