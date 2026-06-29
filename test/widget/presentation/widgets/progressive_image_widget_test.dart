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

  group(
    'ProgressiveImageWidget.shouldUseStaticNetworkDecodeFallbackForTesting',
    () {
      test('returns true for webp URL', () {
        expect(
          ProgressiveImageWidget.shouldUseStaticNetworkDecodeFallbackForTesting(
            'https://cdn.manga18.club/manga/title/cover/cover_thumb_2.webp',
            isThumbnail: true,
          ),
          isTrue,
        );
      });

      test('returns true for avif URL with query string', () {
        expect(
          ProgressiveImageWidget.shouldUseStaticNetworkDecodeFallbackForTesting(
            'https://example.com/image.avif?token=123',
            isThumbnail: true,
          ),
          isTrue,
        );
      });

      test('returns false for jpeg URL', () {
        expect(
          ProgressiveImageWidget.shouldUseStaticNetworkDecodeFallbackForTesting(
            'https://example.com/image.jpg',
            isThumbnail: true,
          ),
          isFalse,
        );
      });

      test('returns false for reader-like page image surface', () {
        expect(
          ProgressiveImageWidget.shouldUseStaticNetworkDecodeFallbackForTesting(
            'https://images.hentainexus.com/v2/foo/001.webp',
            pageNumber: 1,
            isThumbnail: false,
          ),
          isFalse,
        );
      });

      test('returns false for malformed URL', () {
        expect(
          ProgressiveImageWidget.shouldUseStaticNetworkDecodeFallbackForTesting(
            'not a valid url',
            isThumbnail: true,
          ),
          isFalse,
        );
      });
    },
  );
}
