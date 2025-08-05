import 'package:equatable/equatable.dart';

/// Tag entity representing content metadata tags
class Tag extends Equatable {
  const Tag({
    required this.name,
    required this.type,
    required this.count,
    required this.url,
    this.slug,
  });

  final String name;
  final String
      type; // tag, artist, character, parody, group, language, category
  final int count; // Popularity count
  final String url;
  final String? slug;

  @override
  List<Object> get props => [name, type, count, url];

  Tag copyWith({
    String? name,
    String? type,
    int? count,
    String? url,
    String? slug,
  }) {
    return Tag(
      name: name ?? this.name,
      type: type ?? this.type,
      count: count ?? this.count,
      url: url ?? this.url,
      slug: slug ?? this.slug,
    );
  }

  /// Get display name with count
  String get displayName => '$name ($count)';

  /// Check if tag is of specific type
  bool isType(String tagType) => type.toLowerCase() == tagType.toLowerCase();

  /// Check if tag is artist
  bool get isArtist => isType('artist');

  /// Check if tag is character
  bool get isCharacter => isType('character');

  /// Check if tag is parody
  bool get isParody => isType('parody');

  /// Check if tag is group
  bool get isGroup => isType('group');

  /// Check if tag is language
  bool get isLanguage => isType('language');

  /// Check if tag is category
  bool get isCategory => isType('category');

  /// Check if tag is regular tag
  bool get isRegularTag => isType('tag');

  /// Get tag color based on type
  String get colorHex {
    switch (type.toLowerCase()) {
      case 'artist':
        return '#FF6B6B'; // Red
      case 'character':
        return '#4ECDC4'; // Teal
      case 'parody':
        return '#45B7D1'; // Blue
      case 'group':
        return '#96CEB4'; // Green
      case 'language':
        return '#FFEAA7'; // Yellow
      case 'category':
        return '#DDA0DD'; // Plum
      default:
        return '#74B9FF'; // Default blue
    }
  }

  /// Check if tag is popular (high count)
  bool get isPopular => count > 1000;

  /// Get popularity level
  TagPopularity get popularity {
    if (count > 10000) return TagPopularity.veryHigh;
    if (count > 5000) return TagPopularity.high;
    if (count > 1000) return TagPopularity.medium;
    if (count > 100) return TagPopularity.low;
    return TagPopularity.veryLow;
  }
}

/// Tag popularity levels
enum TagPopularity {
  veryLow,
  low,
  medium,
  high,
  veryHigh,
}

/// Tag type constants
class TagType {
  static const String tag = 'tag';
  static const String artist = 'artist';
  static const String character = 'character';
  static const String parody = 'parody';
  static const String group = 'group';
  static const String language = 'language';
  static const String category = 'category';

  static const List<String> all = [
    tag,
    artist,
    character,
    parody,
    group,
    language,
    category,
  ];

  static String getDisplayName(String type) {
    switch (type.toLowerCase()) {
      case tag:
        return 'Tag';
      case artist:
        return 'Artist';
      case character:
        return 'Character';
      case parody:
        return 'Parody';
      case group:
        return 'Group';
      case language:
        return 'Language';
      case category:
        return 'Category';
      default:
        return type;
    }
  }
}
