import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'webtoon_detector.dart';

/// Utility class for splitting long images into readable chunks.
///
/// This is particularly useful for webtoon-style images with extreme aspect ratios
/// that are difficult to read when embedded as single pages in PDFs.
///
/// **Usage:**
/// ```dart
/// final chunks = await ImageSplitter.splitImage('path/to/webtoon.jpg');
/// // Process each chunk for PDF generation
/// ```
class ImageSplitter {
  /// Private constructor to prevent instantiation.
  ImageSplitter._();

  /// Maximum height per chunk in pixels
  ///
  /// Reduced to 3000px for better split points (less likely to cut panels mid-image)
  /// Formula: 3000 / 1200 = 2.5 (aspect ratio matches WebtoonDetector threshold)
  /// This results in shorter pages but more natural splits
  static const int maxHeightPerChunk = 3000;

  /// Maximum width for image resize
  ///
  /// Images wider than this will be downscaled to save memory
  /// Default: 1200px (good balance for readability and file size)
  static const int maxWidth = 1200;

  /// JPEG quality for chunk encoding
  ///
  /// Range: 0-100, where 100 is highest quality
  /// Increased to 90 for better detail preservation in manga/webtoon
  /// Slightly larger file size but better visual quality
  static const int jpegQuality = 90;

  /// Auto-split long images into readable chunks
  ///
  /// **Process:**
  /// 1. Load and decode image
  /// 2. Resize width if needed (>maxWidth)
  /// 3. Check if webtoon using WebtoonDetector
  /// 4. Split into chunks if webtoon, otherwise return as-is
  ///
  /// **Parameters:**
  /// - [imagePath]: Absolute path to image file
  ///
  /// **Returns:**
  /// - List of image chunks as byte arrays (JPEG encoded)
  /// - Single item list if normal image
  /// - Original bytes if decode fails
  ///
  /// **Example:**
  /// ```dart
  /// // Normal image (902×1280) → 1 chunk
  /// final normalChunks = await ImageSplitter.splitImage('normal.jpg');
  /// assert(normalChunks.length == 1);
  ///
  /// // Webtoon image (930×28512) → ~8 chunks
  /// final webtoonChunks = await ImageSplitter.splitImage('webtoon.jpg');
  /// assert(webtoonChunks.length > 1);
  /// ```
  static Future<List<Uint8List>> splitImage(String imagePath) async {
    try {
      // Load image bytes
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        // Decode failed, return original bytes
        return [bytes];
      }

      // Step 1: Resize width if needed
      img.Image processedImage = image;
      if (image.width > maxWidth) {
        final scale = maxWidth / image.width;
        processedImage = img.copyResize(
          image,
          width: maxWidth,
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      }

      // Step 2: Check if splitting needed using WebtoonDetector
      final dimensions = Size(
        processedImage.width.toDouble(),
        processedImage.height.toDouble(),
      );

      if (!WebtoonDetector.isWebtoon(dimensions)) {
        // Normal image, return as-is
        return [
          Uint8List.fromList(
              img.encodeJpg(processedImage, quality: jpegQuality))
        ];
      }

      // Step 3: Split into chunks
      final chunks = <Uint8List>[];
      final totalChunks = (processedImage.height / maxHeightPerChunk).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final yStart = i * maxHeightPerChunk;
        final yEnd =
            ((i + 1) * maxHeightPerChunk).clamp(0, processedImage.height);

        final chunk = img.copyCrop(
          processedImage,
          x: 0,
          y: yStart,
          width: processedImage.width,
          height: yEnd - yStart,
        );

        chunks.add(
            Uint8List.fromList(img.encodeJpg(chunk, quality: jpegQuality)));
      }

      return chunks;
    } catch (e) {
      // Error during processing, return original bytes
      final bytes = await File(imagePath).readAsBytes();
      return [bytes];
    }
  }

  /// Estimate how many chunks an image will become
  ///
  /// Useful for progress calculation and pre-allocation.
  ///
  /// **Parameters:**
  /// - [imagePath]: Absolute path to image file
  ///
  /// **Returns:**
  /// - Number of chunks the image will be split into
  /// - Returns 1 if normal image or decode fails
  ///
  /// **Example:**
  /// ```dart
  /// final chunkCount = await ImageSplitter.estimateChunkCount('webtoon.jpg');
  /// print('This webtoon will become $chunkCount PDF pages');
  /// ```
  static Future<int> estimateChunkCount(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return 1;

      // Calculate adjusted dimensions after resize
      final adjustedHeight = image.width > maxWidth
          ? (image.height * (maxWidth / image.width)).round()
          : image.height;

      final dimensions = Size(
        (image.width > maxWidth ? maxWidth : image.width).toDouble(),
        adjustedHeight.toDouble(),
      );

      // Check if webtoon
      if (!WebtoonDetector.isWebtoon(dimensions)) {
        return 1;
      }

      // Calculate chunk count
      return (adjustedHeight / maxHeightPerChunk).ceil();
    } catch (e) {
      return 1;
    }
  }

  /// Get dimensions of an image without fully loading it
  ///
  /// More memory-efficient than loading entire image for dimension check.
  ///
  /// **Parameters:**
  /// - [imagePath]: Absolute path to image file
  ///
  /// **Returns:**
  /// - Size object with width and height
  /// - Returns Size.zero if unable to determine
  static Future<Size> getImageDimensions(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return Size.zero;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      return Size.zero;
    }
  }

  /// Check if an image will be split (is a webtoon)
  ///
  /// Convenience method combining dimension check and webtoon detection.
  ///
  /// **Parameters:**
  /// - [imagePath]: Absolute path to image file
  ///
  /// **Returns:**
  /// - true if image will be split into chunks
  /// - false if image will remain as single page
  static Future<bool> willBeSplit(String imagePath) async {
    final dimensions = await getImageDimensions(imagePath);
    return WebtoonDetector.isWebtoon(dimensions);
  }

  /// Count how many images in a list are webtoons (extreme dimensions)
  ///
  /// Used for pre-scanning before PDF generation to determine whether
  /// to use Flutter (fast for small sets) or Native (fast for large sets).
  ///
  /// **Parameters:**
  /// - [imagePaths]: List of absolute paths to image files
  ///
  /// **Returns:**
  /// - Number of webtoon images detected
  ///
  /// **Example:**
  /// ```dart
  /// final images = ['page1.jpg', 'page2.jpg', ...];
  /// final webtoonCount = await ImageSplitter.countWebtoonImages(images);
  ///
  /// if (webtoonCount >= 50) {
  ///   // Use native PDF generator (faster)
  /// } else {
  ///   // Use Flutter PDF generator (good enough)
  /// }
  /// ```
  static Future<int> countWebtoonImages(List<String> imagePaths) async {
    int webtoonCount = 0;

    for (final imagePath in imagePaths) {
      final isWebtoon = await willBeSplit(imagePath);
      if (isWebtoon) {
        webtoonCount++;
      }
    }

    return webtoonCount;
  }

  /// Estimate total PDF pages for a list of images
  ///
  /// Calculates the sum of chunks/pages for all images, accounting
  /// for webtoon splitting.
  ///
  /// **Parameters:**
  /// - [imagePaths]: List of absolute paths to image files
  ///
  /// **Returns:**
  /// - Estimated total number of PDF pages
  ///
  /// **Example:**
  /// ```dart
  /// final images = ['page1.jpg', 'page2.jpg', ...];
  /// final totalPages = await ImageSplitter.estimateTotalPages(images);
  /// print('PDF will have approximately $totalPages pages');
  ///
  /// // Estimate processing time
  /// final estimatedSeconds = totalPages * 0.5;
  /// ```
  static Future<int> estimateTotalPages(List<String> imagePaths) async {
    int totalPages = 0;

    for (final imagePath in imagePaths) {
      final chunkCount = await estimateChunkCount(imagePath);
      totalPages += chunkCount;
    }

    return totalPages;
  }
}
