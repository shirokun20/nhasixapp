import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/workers/download_lifecycle_mixin.dart';

void main() {
  group('ActiveDownloadInfo', () {
    test('can be created with required properties', () {
      const info = ActiveDownloadInfo(
        contentId: 'test-123',
        downloadUrl: 'https://example.com/download',
        savePath: '/path/to/save',
        title: 'Test Download',
        totalImages: 100,
        currentProgress: 50,
        isInProgress: true,
      );

      expect(info.contentId, equals('test-123'));
      expect(info.downloadUrl, equals('https://example.com/download'));
      expect(info.savePath, equals('/path/to/save'));
      expect(info.title, equals('Test Download'));
      expect(info.totalImages, equals(100));
      expect(info.currentProgress, equals(50));
      expect(info.isInProgress, isTrue);
    });

    test('can represent paused download', () {
      const info = ActiveDownloadInfo(
        contentId: 'paused-123',
        downloadUrl: 'https://example.com/download',
        savePath: '/path/to/save',
        title: 'Paused Download',
        totalImages: 50,
        currentProgress: 25,
        isInProgress: false,
      );

      expect(info.isInProgress, isFalse);
      expect(info.currentProgress, equals(25));
    });

    test('can represent completed download', () {
      const info = ActiveDownloadInfo(
        contentId: 'complete-123',
        downloadUrl: 'https://example.com/download',
        savePath: '/path/to/save',
        title: 'Complete Download',
        totalImages: 30,
        currentProgress: 100,
        isInProgress: false,
      );

      expect(info.currentProgress, equals(100));
      expect(info.isInProgress, isFalse);
    });
  });
}
