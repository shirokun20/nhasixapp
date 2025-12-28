import 'package:equatable/equatable.dart';

/// Tag entity representing content metadata tags.
///
/// Tags categorize content by artist, character, parody, etc.
class Tag extends Equatable {
  const Tag({
    required this.id,
    required this.name,
    required this.type,
    required this.count,
    this.url = '',
    this.slug,
  });

  /// Tag ID
  final int id;

  /// Tag name
  final String name;

  /// Tag type (tag, artist, character, parody, group, language, category)
  final String type;

  /// Usage/popularity count
  final int count;

  /// URL to tag page (source-specific)
  final String url;

  /// URL-safe slug
  final String? slug;

  @override
  List<Object?> get props => [id, name, type, count, url, slug];

  Tag copyWith({
    int? id,
    String? name,
    String? type,
    int? count,
    String? url,
    String? slug,
  }) {
    return Tag(
      id: id ?? this.id,
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

  /// Check if tag is popular (high count)
  bool get isPopular => count > 1000;
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
