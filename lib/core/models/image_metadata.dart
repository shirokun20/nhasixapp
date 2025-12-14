import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_metadata.freezed.dart';
part 'image_metadata.g.dart';

/// Metadata for image handling in reader screen
/// Eliminates runtime URL validation by pre-computing image information
@freezed
abstract class ImageMetadata with _$ImageMetadata {
  const factory ImageMetadata({
    /// Final resolved URL for image loading
    required String imageUrl,

    /// nhentai Gallery ID (public identifier)
    required String contentId,

    /// 1-based page number
    required int pageNumber,

    /// Type of image source (online/cached)
    required ImageType imageType,
  }) = _ImageMetadata;

  /// JSON deserialization factory
  factory ImageMetadata.fromJson(Map<String, dynamic> json) =>
      _$ImageMetadataFromJson(json);
}

/// Enum for image source types
/// Used to determine caching strategy and URL resolution
enum ImageType {
  /// Image loaded from nhentai servers
  @JsonValue('online')
  online,

  /// Image loaded from local cache
  @JsonValue('cached')
  cached,
}
