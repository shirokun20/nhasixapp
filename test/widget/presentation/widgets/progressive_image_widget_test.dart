import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/presentation/widgets/progressive_image_widget.dart';

void main() {
  group('ProgressiveImageWidget.shouldSuppressOfflineThumbnailForTesting', () {
    test('returns true for animated fallback page image', () {
      expect(
        ProgressiveImageWidget.shouldSuppressOfflineThumbnailForTesting(
          localPath: '/storage/emulated/0/nhasix/ehentai/123/images/14.webp',
          fileBytes: 128 * 1024,
          isAnimated: true,
        ),
        isTrue,
      );
    });

    test('returns false for dedicated heavy cover asset', () {
      expect(
        ProgressiveImageWidget.shouldSuppressOfflineThumbnailForTesting(
          localPath: '/storage/emulated/0/nhasix/ehentai/123/images/cover.jpg',
          fileBytes: ProgressiveImageWidget
                  .heavyAnimatedThumbnailThresholdBytesForTesting +
              1,
          isAnimated: false,
        ),
        isFalse,
      );
    });

    test('returns true for heavy non-animated fallback thumbnail', () {
      expect(
        ProgressiveImageWidget.shouldSuppressOfflineThumbnailForTesting(
          localPath: '/storage/emulated/0/nhasix/ehentai/123/images/14.jpg',
          fileBytes: ProgressiveImageWidget
                  .heavyAnimatedThumbnailThresholdBytesForTesting +
              1,
          isAnimated: false,
        ),
        isTrue,
      );
    });

    test('returns false for lightweight static fallback thumbnail', () {
      expect(
        ProgressiveImageWidget.shouldSuppressOfflineThumbnailForTesting(
          localPath: '/storage/emulated/0/nhasix/ehentai/123/images/14.jpg',
          fileBytes: ProgressiveImageWidget
                  .heavyAnimatedThumbnailThresholdBytesForTesting -
              1,
          isAnimated: false,
        ),
        isFalse,
      );
    });
  });
}
