import 'package:equatable/equatable.dart';
import 'tag.dart';

/// Core content entity representing a manga/doujinshi
class Content extends Equatable {
  const Content({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.tags,
    required this.artists,
    required this.characters,
    required this.parodies,
    required this.groups,
    required this.language,
    required this.pageCount,
    required this.imageUrls,
    required this.uploadDate,
    this.favorites = 0,
    this.englishTitle,
    this.japaneseTitle,
  });

  final String id;
  final String title;
  final String coverUrl;
  final List<Tag> tags;
  final List<String> artists;
  final List<String> characters;
  final List<String> parodies;
  final List<String> groups;
  final String language;
  final int pageCount;
  final List<String> imageUrls;
  final DateTime uploadDate;
  final int favorites; // Popularity count
  final String? englishTitle;
  final String? japaneseTitle;

  @override
  List<Object?> get props => [
        id,
        title,
        coverUrl,
        tags,
        artists,
        characters,
        parodies,
        groups,
        language,
        pageCount,
        imageUrls,
        uploadDate,
        favorites,
        englishTitle,
        japaneseTitle,
      ];

  Content copyWith({
    String? id,
    String? title,
    String? coverUrl,
    List<Tag>? tags,
    List<String>? artists,
    List<String>? characters,
    List<String>? parodies,
    List<String>? groups,
    String? language,
    int? pageCount,
    List<String>? imageUrls,
    DateTime? uploadDate,
    int? favorites,
    String? englishTitle,
    String? japaneseTitle,
  }) {
    return Content(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      tags: tags ?? this.tags,
      artists: artists ?? this.artists,
      characters: characters ?? this.characters,
      parodies: parodies ?? this.parodies,
      groups: groups ?? this.groups,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      imageUrls: imageUrls ?? this.imageUrls,
      uploadDate: uploadDate ?? this.uploadDate,
      favorites: favorites ?? this.favorites,
      englishTitle: englishTitle ?? this.englishTitle,
      japaneseTitle: japaneseTitle ?? this.japaneseTitle,
    );
  }

  /// Get display title based on preference
  String getDisplayTitle({bool preferEnglish = true}) {
    if (preferEnglish && englishTitle != null && englishTitle!.isNotEmpty) {
      return englishTitle!;
    }
    if (japaneseTitle != null && japaneseTitle!.isNotEmpty) {
      return japaneseTitle!;
    }
    return title;
  }

  /// Check if content has specific tag
  bool hasTag(String tagName) {
    return tags.any((tag) => tag.name.toLowerCase() == tagName.toLowerCase());
  }

  /// Check if content has specific artist
  bool hasArtist(String artistName) {
    return artists
        .any((artist) => artist.toLowerCase() == artistName.toLowerCase());
  }

  /// Get tags by type
  List<Tag> getTagsByType(String type) {
    return tags.where((tag) => tag.type == type).toList();
  }

  /// Check if content is NSFW based on tags
  bool get isNsfw {
    const nsfwTags = [
      'lolicon',
      'shotacon',
      'rape',
      'netorare',
      'ugly bastard'
    ];
    return tags.any((tag) => nsfwTags.contains(tag.name.toLowerCase()));
  }

  /// Get content category
  String get category {
    final categoryTags = getTagsByType('category');
    return categoryTags.isNotEmpty ? categoryTags.first.name : 'doujinshi';
  }
}
