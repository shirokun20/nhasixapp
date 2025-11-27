import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/webtoon_detector.dart';

void main() {
  group('WebtoonDetector', () {
    group('isWebtoon()', () {
      test('returns false for normal manga image (AR = 1.42)', () {
        // Actual normal manga dimensions from project
        final normalImage = Size(902, 1280);
        final result = WebtoonDetector.isWebtoon(normalImage);

        expect(result, false);
      });

      test('returns true for webtoon image (AR = 12.85)', () {
        // Actual webtoon dimensions from project
        final webtoonImage = Size(1275, 16383);
        final result = WebtoonDetector.isWebtoon(webtoonImage);

        expect(result, true);
      });

      test('returns false for square image (AR = 1.0)', () {
        final squareImage = Size(1000, 1000);
        final result = WebtoonDetector.isWebtoon(squareImage);

        expect(result, false);
      });

      test('returns false for landscape image (AR < 1.0)', () {
        final landscapeImage = Size(1920, 1080);
        final result = WebtoonDetector.isWebtoon(landscapeImage);

        expect(result, false);
      });

      test('returns false for image at threshold (AR = 2.5)', () {
        final thresholdImage = Size(1000, 2500);
        final result = WebtoonDetector.isWebtoon(thresholdImage);

        expect(result, false); // Should be false at exactly threshold
      });

      test('returns true for image just above threshold (AR = 2.51)', () {
        final justAboveThreshold = Size(1000, 2510);
        final result = WebtoonDetector.isWebtoon(justAboveThreshold);

        expect(result, true);
      });

      test('returns false for image just below threshold (AR = 2.49)', () {
        final justBelowThreshold = Size(1000, 2490);
        final result = WebtoonDetector.isWebtoon(justBelowThreshold);

        expect(result, false);
      });

      group('Edge Cases', () {
        test('returns false for zero width', () {
          final zeroWidth = Size(0, 1000);
          final result = WebtoonDetector.isWebtoon(zeroWidth);

          expect(result, false);
        });

        test('returns false for zero height', () {
          final zeroHeight = Size(1000, 0);
          final result = WebtoonDetector.isWebtoon(zeroHeight);

          expect(result, false);
        });

        test('returns false for both zero dimensions', () {
          final zeroSize = Size(0, 0);
          final result = WebtoonDetector.isWebtoon(zeroSize);

          expect(result, false);
        });

        test('returns false for negative width', () {
          final negativeWidth = Size(-100, 1000);
          final result = WebtoonDetector.isWebtoon(negativeWidth);

          expect(result, false);
        });

        test('returns false for negative height', () {
          final negativeHeight = Size(1000, -100);
          final result = WebtoonDetector.isWebtoon(negativeHeight);

          expect(result, false);
        });

        test('returns false for very small dimensions', () {
          final tinyImage = Size(1, 1);
          final result = WebtoonDetector.isWebtoon(tinyImage);

          expect(result, false);
        });

        test('handles very large webtoon dimensions', () {
          final hugeWebtoon = Size(2000, 50000);
          final result = WebtoonDetector.isWebtoon(hugeWebtoon);

          expect(result, true);
        });
      });
    });

    group('getImageType()', () {
      test('returns "Normal" for normal manga image', () {
        final normalImage = Size(902, 1280);
        final result = WebtoonDetector.getImageType(normalImage);

        expect(result, 'Normal');
      });

      test('returns "Webtoon" for webtoon image', () {
        final webtoonImage = Size(1275, 16383);
        final result = WebtoonDetector.getImageType(webtoonImage);

        expect(result, 'Webtoon');
      });

      test('returns "Invalid" for zero width', () {
        final invalidImage = Size(0, 1000);
        final result = WebtoonDetector.getImageType(invalidImage);

        expect(result, 'Invalid');
      });

      test('returns "Invalid" for zero height', () {
        final invalidImage = Size(1000, 0);
        final result = WebtoonDetector.getImageType(invalidImage);

        expect(result, 'Invalid');
      });
    });

    group('getAspectRatio()', () {
      test('returns correct aspect ratio for normal manga', () {
        final normalImage = Size(902, 1280);
        final aspectRatio = WebtoonDetector.getAspectRatio(normalImage);

        expect(aspectRatio, isNotNull);
        expect(aspectRatio, closeTo(1.42, 0.01));
      });

      test('returns correct aspect ratio for webtoon', () {
        final webtoonImage = Size(1275, 16383);
        final aspectRatio = WebtoonDetector.getAspectRatio(webtoonImage);

        expect(aspectRatio, isNotNull);
        expect(aspectRatio, closeTo(12.85, 0.01));
      });

      test('returns 1.0 for square image', () {
        final squareImage = Size(1000, 1000);
        final aspectRatio = WebtoonDetector.getAspectRatio(squareImage);

        expect(aspectRatio, 1.0);
      });

      test('returns null for zero width', () {
        final invalidImage = Size(0, 1000);
        final aspectRatio = WebtoonDetector.getAspectRatio(invalidImage);

        expect(aspectRatio, isNull);
      });

      test('returns null for zero height', () {
        final invalidImage = Size(1000, 0);
        final aspectRatio = WebtoonDetector.getAspectRatio(invalidImage);

        expect(aspectRatio, isNull);
      });
    });

    group('Threshold Constant', () {
      test('aspectRatioThreshold is 2.5', () {
        expect(WebtoonDetector.aspectRatioThreshold, 2.5);
      });
    });
  });
}
