import 'package:equatable/equatable.dart';

/// Value object for Image URL with validation and utilities
class ImageUrl extends Equatable {
  const ImageUrl(this.value);

  final String value;

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;

  /// Validate URL format
  bool get isValid {
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// Check if URL is from nhentai domain
  bool get isNhentaiUrl {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.host.contains('nhentai.net');
  }

  /// Check if URL is a thumbnail
  bool get isThumbnail {
    return value.contains('/thumb.') || value.contains('t.nhentai.net');
  }

  /// Check if URL is a full-size image
  bool get isFullSize {
    return value.contains('i.nhentai.net') && !isThumbnail;
  }

  /// Get file extension
  String get extension {
    final uri = Uri.tryParse(value);
    if (uri == null) return '';
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot + 1).toLowerCase();
  }

  /// Check if image is JPEG
  bool get isJpeg => extension == 'jpg' || extension == 'jpeg';

  /// Check if image is PNG
  bool get isPng => extension == 'png';

  /// Check if image is WebP
  bool get isWebp => extension == 'webp';

  /// Check if image is GIF
  bool get isGif => extension == 'gif';

  /// Get image format
  ImageFormat get format {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return ImageFormat.jpeg;
      case 'png':
        return ImageFormat.png;
      case 'webp':
        return ImageFormat.webp;
      case 'gif':
        return ImageFormat.gif;
      default:
        return ImageFormat.unknown;
    }
  }

  /// Create with validation
  factory ImageUrl.fromString(String url) {
    final imageUrl = ImageUrl(url);
    if (!imageUrl.isValid) {
      throw FormatException('Invalid image URL: $url');
    }
    return imageUrl;
  }

  /// Try to create from string, return null if invalid
  static ImageUrl? tryParse(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      return ImageUrl.fromString(url);
    } catch (e) {
      return null;
    }
  }

  /// Convert to thumbnail URL if possible
  ImageUrl? toThumbnail() {
    if (!isNhentaiUrl || isThumbnail) return this;

    // Convert i.nhentai.net to t.nhentai.net and add thumb
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (uri.host == 'i.nhentai.net') {
      final path = uri.path;
      final lastSlash = path.lastIndexOf('/');
      final lastDot = path.lastIndexOf('.');

      if (lastSlash != -1 && lastDot != -1) {
        final directory = path.substring(0, lastSlash);
        final extension = path.substring(lastDot);
        final thumbnailPath = '$directory/thumb$extension';

        final thumbnailUri = uri.replace(
          host: 't.nhentai.net',
          path: thumbnailPath,
        );

        return ImageUrl(thumbnailUri.toString());
      }
    }

    return null;
  }

  /// Convert to full-size URL if possible
  ImageUrl? toFullSize() {
    if (!isNhentaiUrl || isFullSize) return this;

    // Convert t.nhentai.net to i.nhentai.net and remove thumb
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (uri.host == 't.nhentai.net' && isThumbnail) {
      final path = uri.path;
      final fullSizePath = path.replaceAll('/thumb.', '/1.');

      final fullSizeUri = uri.replace(
        host: 'i.nhentai.net',
        path: fullSizePath,
      );

      return ImageUrl(fullSizeUri.toString());
    }

    return null;
  }

  /// Get optimized URL based on quality preference
  ImageUrl getOptimized(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.thumbnail:
        return toThumbnail() ?? this;
      case ImageQuality.low:
        // For low quality, prefer WebP if available
        return _convertToWebP() ?? this;
      case ImageQuality.medium:
        return this;
      case ImageQuality.high:
      case ImageQuality.original:
        return toFullSize() ?? this;
    }
  }

  /// Convert to WebP format if possible
  ImageUrl? _convertToWebP() {
    if (isWebp) return this;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return null;

    final webpPath = '${path.substring(0, lastDot)}.webp';
    final webpUri = uri.replace(path: webpPath);

    return ImageUrl(webpUri.toString());
  }

  /// Get cache key for the image
  String get cacheKey {
    return value.hashCode.toString();
  }

  /// Get filename from URL
  String get filename {
    final uri = Uri.tryParse(value);
    if (uri == null) return '';
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  }
}

/// Image format enumeration
enum ImageFormat {
  jpeg,
  png,
  webp,
  gif,
  unknown,
}

/// Image quality levels
enum ImageQuality {
  thumbnail,
  low,
  medium,
  high,
  original,
}

/// Extension for ImageFormat
extension ImageFormatExtension on ImageFormat {
  String get extension {
    switch (this) {
      case ImageFormat.jpeg:
        return 'jpg';
      case ImageFormat.png:
        return 'png';
      case ImageFormat.webp:
        return 'webp';
      case ImageFormat.gif:
        return 'gif';
      case ImageFormat.unknown:
        return '';
    }
  }

  String get mimeType {
    switch (this) {
      case ImageFormat.jpeg:
        return 'image/jpeg';
      case ImageFormat.png:
        return 'image/png';
      case ImageFormat.webp:
        return 'image/webp';
      case ImageFormat.gif:
        return 'image/gif';
      case ImageFormat.unknown:
        return 'application/octet-stream';
    }
  }

  bool get supportsTransparency {
    return this == ImageFormat.png ||
        this == ImageFormat.webp ||
        this == ImageFormat.gif;
  }

  bool get supportsAnimation {
    return this == ImageFormat.gif || this == ImageFormat.webp;
  }
}

/// Extension for String to convert to ImageUrl
extension StringToImageUrl on String {
  ImageUrl get asImageUrl => ImageUrl.fromString(this);
  ImageUrl? get asImageUrlOrNull => ImageUrl.tryParse(this);
}
