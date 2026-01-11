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
  /// Supports:
  /// - Numeric IDs (nhentai): "123456"
  /// - Slug IDs (crotpedia): "my-manga-title", "the-hatsunetsu"
  bool get isValid {
    if (value.isEmpty) return false;

    // Accept numeric IDs (nhentai format)
    if (isNumeric) return true;

    // Accept slug IDs (crotpedia format)
    // Valid slug: lowercase, alphanumeric, hyphens, underscores
    // Must start with alphanumeric, no consecutive hyphens
    if (isSlug) return true;

    // Reject invalid formats
    return false;
  }

  /// Check if this is a numeric ID (nhentai-style)
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(value);

  /// Check if this is a slug ID (crotpedia-style)
  /// Valid patterns: "manga-title", "the-hatsunetsu", "series-name-2024"
  /// Also accepts URL-encoded characters: "secret-%e2%99%a5" (emoji support)
  bool get isSlug => RegExp(r'^[a-z0-9%]+(?:[-_][a-z0-9%]+)*$').hasMatch(value);

  /// Get content ID as integer (only for numeric IDs)
  int get asInt {
    if (!isValid) {
      throw FormatException('Invalid content ID: $value');
    }
    if (!isNumeric) {
      throw FormatException(
          'Cannot convert non-numeric content ID to int: $value. '
          'This ID appears to be a slug-based ID (e.g., from crotpedia). '
          'Use .value to get the string representation.');
    }
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
      throw FormatException('Invalid content ID format: $id. '
          'Expected either a numeric ID (e.g., "123456") or a slug ID (e.g., "manga-title").');
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
