import 'package:equatable/equatable.dart';

/// Value object for Content ID to ensure type safety
class ContentId extends Equatable {
  const ContentId(this.value);

  final String value;

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;

  /// Validate content ID format
  bool get isValid {
    // Content ID should be numeric for nhentai
    return RegExp(r'^\d+$').hasMatch(value);
  }

  /// Get content ID as integer
  int get asInt {
    if (!isValid) throw FormatException('Invalid content ID: $value');
    return int.parse(value);
  }

  /// Create from integer
  factory ContentId.fromInt(int id) {
    return ContentId(id.toString());
  }

  /// Create from string with validation
  factory ContentId.fromString(String id) {
    final contentId = ContentId(id);
    if (!contentId.isValid) {
      throw FormatException('Invalid content ID format: $id');
    }
    return contentId;
  }

  /// Try to create from string, return null if invalid
  static ContentId? tryParse(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return ContentId.fromString(id);
    } catch (e) {
      return null;
    }
  }

  /// Generate URL for content
  String get contentUrl => 'https://nhentai.net/g/$value/';

  /// Generate API URL for content
  String get apiUrl => 'https://nhentai.net/api/gallery/$value';

  /// Generate thumbnail URL
  String getThumbnailUrl(String mediaId) {
    return 'https://t.nhentai.net/galleries/$mediaId/thumb.jpg';
  }

  /// Generate page URL
  String getPageUrl(String mediaId, int page, {String extension = 'jpg'}) {
    return 'https://i.nhentai.net/galleries/$mediaId/$page.$extension';
  }
}

/// Extension for String to convert to ContentId
extension StringToContentId on String {
  ContentId get asContentId => ContentId.fromString(this);
  ContentId? get asContentIdOrNull => ContentId.tryParse(this);
}

/// Extension for int to convert to ContentId
extension IntToContentId on int {
  ContentId get asContentId => ContentId.fromInt(this);
}
