import 'dart:ui';

/// Utility class for detecting webtoon-style images based on aspect ratio.
///
/// Webtoons are typically characterized by their extremely tall vertical format,
/// designed for continuous scrolling on mobile devices. This detector uses
/// aspect ratio analysis to differentiate between normal manga pages and webtoons.
///
/// **Aspect Ratio Analysis (from project images):**
/// - Normal manga: 902×1280px → AR = 1.42
/// - Webtoon image: 1275×16383px → AR = 12.85
/// - Threshold: 2.5 (provides clear separation)
///
/// **Usage:**
/// ```dart
/// final size = Size(1275, 16383);
/// if (WebtoonDetector.isWebtoon(size)) {
///   // Apply webtoon-specific rendering (e.g., BoxFit.fitWidth)
/// }
/// ```
class WebtoonDetector {
  /// Private constructor to prevent instantiation.
  /// This is a utility class with only static methods.
  WebtoonDetector._();

  /// Aspect ratio threshold to classify images as webtoon.
  ///
  /// Images with aspect ratio (height/width) greater than this threshold
  /// are considered webtoons. This value was chosen based on analysis of
  /// actual project images:
  /// - Normal manga pages typically have AR between 1.0 and 2.0
  /// - Webtoon images typically have AR > 5.0
  /// - Threshold of 2.5 provides clear separation between the two
  static const double aspectRatioThreshold = 2.5;

  /// Detects if an image is a webtoon based on its dimensions.
  ///
  /// Returns `true` if the image's aspect ratio (height/width) exceeds
  /// [aspectRatioThreshold], indicating a webtoon-style vertical image.
  ///
  /// **Parameters:**
  /// - [imageSize]: The size of the image to check
  ///
  /// **Returns:**
  /// - `true` if aspect ratio > 2.5 (webtoon)
  /// - `false` if aspect ratio ≤ 2.5 (normal image) or invalid dimensions
  ///
  /// **Edge Cases:**
  /// - Returns `false` if width ≤ 0 (invalid)
  /// - Returns `false` if height ≤ 0 (invalid)
  /// - Returns `false` for extremely small images (< 1px)
  ///
  /// **Examples:**
  /// ```dart
  /// // Normal manga page
  /// WebtoonDetector.isWebtoon(Size(902, 1280))  // false (AR = 1.42)
  ///
  /// // Webtoon image
  /// WebtoonDetector.isWebtoon(Size(1275, 16383)) // true (AR = 12.85)
  ///
  /// // Edge cases
  /// WebtoonDetector.isWebtoon(Size(0, 1000))    // false (invalid width)
  /// WebtoonDetector.isWebtoon(Size(1000, 0))    // false (invalid height)
  /// ```
  static bool isWebtoon(Size imageSize) {
    // Validate dimensions
    if (imageSize.width <= 0) return false;
    if (imageSize.height <= 0) return false;

    // Calculate aspect ratio (height / width)
    final aspectRatio = imageSize.height / imageSize.width;

    // Compare with threshold
    return aspectRatio > aspectRatioThreshold;
  }

  /// Gets a human-readable description of the image type.
  ///
  /// Useful for debugging and logging purposes.
  ///
  /// **Returns:**
  /// - "Webtoon" if aspect ratio > 2.5
  /// - "Normal" if aspect ratio ≤ 2.5
  /// - "Invalid" if dimensions are invalid
  static String getImageType(Size imageSize) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return 'Invalid';
    }

    return isWebtoon(imageSize) ? 'Webtoon' : 'Normal';
  }

  /// Gets the aspect ratio of an image.
  ///
  /// Returns `null` if dimensions are invalid.
  ///
  /// **Formula:** height / width
  static double? getAspectRatio(Size imageSize) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return null;
    }

    return imageSize.height / imageSize.width;
  }
}
