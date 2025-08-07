import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// Image optimization utility for compression and thumbnail generation
///
/// Features:
/// - Image compression with quality control
/// - Thumbnail generation with aspect ratio preservation
/// - Batch processing
/// - Memory-efficient operations
/// - Format conversion (JPEG, PNG, WebP)
class ImageOptimizer {
  static ImageOptimizer? _instance;
  static ImageOptimizer get instance => _instance ??= ImageOptimizer._();

  ImageOptimizer._();

  final Logger _logger = Logger();

  // Optimization settings
  static const int _defaultThumbnailWidth = 200;
  static const int _defaultThumbnailHeight = 300;
  static const int _defaultCompressionQuality = 85;
  static const int _maxImageDimension = 2048;

  /// Compress image with specified quality
  Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int quality = _defaultCompressionQuality,
    int? maxWidth,
    int? maxHeight,
    ImageFormat format = ImageFormat.jpeg,
  }) async {
    try {
      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      img.Image processedImage = originalImage;

      // Resize if dimensions are specified or image is too large
      if (maxWidth != null ||
          maxHeight != null ||
          originalImage.width > _maxImageDimension ||
          originalImage.height > _maxImageDimension) {
        final targetWidth = maxWidth ??
            (originalImage.width > _maxImageDimension
                ? _maxImageDimension
                : originalImage.width);
        final targetHeight = maxHeight ??
            (originalImage.height > _maxImageDimension
                ? _maxImageDimension
                : originalImage.height);

        // Calculate dimensions maintaining aspect ratio
        final aspectRatio = originalImage.width / originalImage.height;
        int newWidth = targetWidth;
        int newHeight = targetHeight;

        if (aspectRatio > (targetWidth / targetHeight)) {
          newHeight = (targetWidth / aspectRatio).round();
        } else {
          newWidth = (targetHeight * aspectRatio).round();
        }

        processedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
      }

      // Encode with specified format and quality
      switch (format) {
        case ImageFormat.jpeg:
          return Uint8List.fromList(
              img.encodeJpg(processedImage, quality: quality));
        case ImageFormat.png:
          return Uint8List.fromList(img.encodePng(processedImage));
        case ImageFormat.webp:
          // Note: WebP encoding might not be available in all environments
          try {
            return Uint8List.fromList(
                img.encodeJpg(processedImage, quality: quality));
          } catch (e) {
            // Fallback to JPEG if WebP is not supported
            return Uint8List.fromList(
                img.encodeJpg(processedImage, quality: quality));
          }
        case ImageFormat.unknown:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    } catch (e) {
      _logger.e('Failed to compress image', error: e);
      rethrow;
    }
  }

  /// Generate thumbnail from image bytes
  Future<Uint8List> generateThumbnail(
    Uint8List imageBytes, {
    int width = _defaultThumbnailWidth,
    int height = _defaultThumbnailHeight,
    int quality = 80,
    bool maintainAspectRatio = true,
    ImageFormat format = ImageFormat.jpeg,
  }) async {
    try {
      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      int thumbnailWidth = width;
      int thumbnailHeight = height;

      if (maintainAspectRatio) {
        // Calculate thumbnail dimensions maintaining aspect ratio
        final aspectRatio = originalImage.width / originalImage.height;

        if (aspectRatio > (width / height)) {
          thumbnailHeight = (width / aspectRatio).round();
        } else {
          thumbnailWidth = (height * aspectRatio).round();
        }
      }

      // Resize image
      final thumbnail = img.copyResize(
        originalImage,
        width: thumbnailWidth,
        height: thumbnailHeight,
        interpolation: img.Interpolation.cubic,
      );

      // Encode thumbnail
      switch (format) {
        case ImageFormat.jpeg:
          return Uint8List.fromList(img.encodeJpg(thumbnail, quality: quality));
        case ImageFormat.png:
          return Uint8List.fromList(img.encodePng(thumbnail));
        case ImageFormat.webp:
          try {
            return Uint8List.fromList(
                img.encodeJpg(thumbnail, quality: quality));
          } catch (e) {
            return Uint8List.fromList(
                img.encodeJpg(thumbnail, quality: quality));
          }
        case ImageFormat.unknown:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    } catch (e) {
      _logger.e('Failed to generate thumbnail', error: e);
      rethrow;
    }
  }

  /// Generate multiple thumbnail sizes
  Future<Map<ThumbnailSize, Uint8List>> generateMultipleThumbnails(
    Uint8List imageBytes, {
    List<ThumbnailSize> sizes = const [
      ThumbnailSize.small,
      ThumbnailSize.medium,
      ThumbnailSize.large,
    ],
    int quality = 80,
    ImageFormat format = ImageFormat.jpeg,
  }) async {
    final thumbnails = <ThumbnailSize, Uint8List>{};

    for (final size in sizes) {
      try {
        final thumbnail = await generateThumbnail(
          imageBytes,
          width: size.width,
          height: size.height,
          quality: quality,
          format: format,
        );
        thumbnails[size] = thumbnail;
      } catch (e) {
        _logger.w('Failed to generate ${size.name} thumbnail', error: e);
      }
    }

    return thumbnails;
  }

  /// Optimize image for storage
  Future<OptimizedImage> optimizeForStorage(
    Uint8List imageBytes, {
    StorageOptimization optimization = StorageOptimization.balanced,
  }) async {
    try {
      final originalSize = imageBytes.length;

      // Get optimization settings
      final settings = _getOptimizationSettings(optimization);

      // Compress image
      final compressedBytes = await compressImage(
        imageBytes,
        quality: settings.quality,
        maxWidth: settings.maxWidth,
        maxHeight: settings.maxHeight,
        format: settings.format,
      );

      // Generate thumbnail
      final thumbnailBytes = await generateThumbnail(
        imageBytes,
        width: settings.thumbnailWidth,
        height: settings.thumbnailHeight,
        quality: settings.thumbnailQuality,
        format: settings.format,
      );

      return OptimizedImage(
        originalSize: originalSize,
        compressedBytes: compressedBytes,
        thumbnailBytes: thumbnailBytes,
        compressionRatio: originalSize / compressedBytes.length,
        settings: settings,
      );
    } catch (e) {
      _logger.e('Failed to optimize image for storage', error: e);
      rethrow;
    }
  }

  /// Batch optimize images
  Future<List<OptimizedImage>> batchOptimize(
    List<Uint8List> imageBytesList, {
    StorageOptimization optimization = StorageOptimization.balanced,
    Function(int completed, int total)? onProgress,
  }) async {
    final results = <OptimizedImage>[];

    for (int i = 0; i < imageBytesList.length; i++) {
      try {
        final optimized = await optimizeForStorage(
          imageBytesList[i],
          optimization: optimization,
        );
        results.add(optimized);

        onProgress?.call(i + 1, imageBytesList.length);
      } catch (e) {
        _logger.w('Failed to optimize image ${i + 1}', error: e);
        // Add placeholder for failed optimization
        results.add(OptimizedImage.failed(imageBytesList[i].length));
      }
    }

    return results;
  }

  /// Get image information
  Future<ImageInfo> getImageInfo(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      return ImageInfo(
        width: image.width,
        height: image.height,
        format: _detectImageFormat(imageBytes),
        size: imageBytes.length,
        aspectRatio: image.width / image.height,
      );
    } catch (e) {
      _logger.e('Failed to get image info', error: e);
      rethrow;
    }
  }

  /// Detect image format from bytes
  ImageFormat _detectImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return ImageFormat.unknown;

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return ImageFormat.jpeg;
    }

    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return ImageFormat.png;
    }

    // WebP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return ImageFormat.webp;
    }

    return ImageFormat.unknown;
  }

  /// Get optimization settings based on optimization level
  OptimizationSettings _getOptimizationSettings(
      StorageOptimization optimization) {
    switch (optimization) {
      case StorageOptimization.maximum:
        return OptimizationSettings(
          quality: 60,
          maxWidth: 1024,
          maxHeight: 1536,
          thumbnailWidth: 150,
          thumbnailHeight: 225,
          thumbnailQuality: 70,
          format: ImageFormat.jpeg,
        );

      case StorageOptimization.balanced:
        return OptimizationSettings(
          quality: 80,
          maxWidth: 1536,
          maxHeight: 2048,
          thumbnailWidth: 200,
          thumbnailHeight: 300,
          thumbnailQuality: 75,
          format: ImageFormat.jpeg,
        );

      case StorageOptimization.quality:
        return OptimizationSettings(
          quality: 90,
          maxWidth: 2048,
          maxHeight: 3072,
          thumbnailWidth: 250,
          thumbnailHeight: 375,
          thumbnailQuality: 85,
          format: ImageFormat.jpeg,
        );
    }
  }

  /// Save optimized image to file
  Future<File> saveOptimizedImage(
    OptimizedImage optimizedImage,
    String fileName, {
    bool saveThumbnail = true,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/optimized_images');
      await imagesDir.create(recursive: true);

      // Save compressed image
      final imageFile = File('${imagesDir.path}/$fileName');
      await imageFile.writeAsBytes(optimizedImage.compressedBytes);

      // Save thumbnail if requested
      if (saveThumbnail && optimizedImage.thumbnailBytes != null) {
        final thumbnailFile = File('${imagesDir.path}/thumb_$fileName');
        await thumbnailFile.writeAsBytes(optimizedImage.thumbnailBytes!);
      }

      return imageFile;
    } catch (e) {
      _logger.e('Failed to save optimized image', error: e);
      rethrow;
    }
  }
}

/// Thumbnail size presets
enum ThumbnailSize {
  small(width: 100, height: 150),
  medium(width: 200, height: 300),
  large(width: 300, height: 450),
  xlarge(width: 400, height: 600);

  const ThumbnailSize({required this.width, required this.height});

  final int width;
  final int height;
}

/// Storage optimization levels
enum StorageOptimization {
  maximum, // Smallest file size, lower quality
  balanced, // Balance between size and quality
  quality, // Higher quality, larger file size
}

/// Image formats
enum ImageFormat {
  jpeg,
  png,
  webp,
  unknown,
}

/// Optimization settings
class OptimizationSettings {
  final int quality;
  final int maxWidth;
  final int maxHeight;
  final int thumbnailWidth;
  final int thumbnailHeight;
  final int thumbnailQuality;
  final ImageFormat format;

  OptimizationSettings({
    required this.quality,
    required this.maxWidth,
    required this.maxHeight,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
    required this.thumbnailQuality,
    required this.format,
  });
}

/// Optimized image result
class OptimizedImage {
  final int originalSize;
  final Uint8List compressedBytes;
  final Uint8List? thumbnailBytes;
  final double compressionRatio;
  final OptimizationSettings? settings;
  final bool isOptimized;

  OptimizedImage({
    required this.originalSize,
    required this.compressedBytes,
    this.thumbnailBytes,
    required this.compressionRatio,
    this.settings,
    this.isOptimized = true,
  });

  OptimizedImage.failed(this.originalSize)
      : compressedBytes = Uint8List(0),
        thumbnailBytes = null,
        compressionRatio = 1.0,
        settings = null,
        isOptimized = false;

  int get compressedSize => compressedBytes.length;
  int get thumbnailSize => thumbnailBytes?.length ?? 0;
  int get totalSize => compressedSize + thumbnailSize;
  double get spaceSaved => 1.0 - (compressedSize / originalSize);
}

/// Image information
class ImageInfo {
  final int width;
  final int height;
  final ImageFormat format;
  final int size;
  final double aspectRatio;

  ImageInfo({
    required this.width,
    required this.height,
    required this.format,
    required this.size,
    required this.aspectRatio,
  });

  bool get isLandscape => aspectRatio > 1.0;
  bool get isPortrait => aspectRatio < 1.0;
  bool get isSquare => aspectRatio == 1.0;
}
