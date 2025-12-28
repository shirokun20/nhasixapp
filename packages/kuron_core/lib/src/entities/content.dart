import 'package:equatable/equatable.dart';
import 'tag.dart';

/// Core content entity representing a manga/doujinshi.
///
/// This entity is source-agnostic and can represent content from
/// any source (nhentai, crotpedia, etc.).
class Content extends Equatable {
  const Content({
    required this.id,
    required this.sourceId,
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
    this.mediaId,
    this.relatedContent = const [],
  });

  /// Content ID (format varies by source)
  final String id;

  /// Source identifier (e.g., 'nhentai', 'crotpedia')
  final String sourceId;

  /// Primary title
  final String title;

  /// Cover image URL
  final String coverUrl;

  /// Content tags
  final List<Tag> tags;

  /// Artist names
  final List<String> artists;

  /// Character names
  final List<String> characters;

  /// Parody/series names
  final List<String> parodies;

  /// Group/circle names
  final List<String> groups;

  /// Content language
  final String language;

  /// Number of pages
  final int pageCount;

  /// List of page image URLs
  final List<String> imageUrls;

  /// Upload/publish date
  final DateTime uploadDate;

  /// Favorites/popularity count
  final int favorites;

  /// English title (if available)
  final String? englishTitle;

  /// Japanese title (if available)
  final String? japaneseTitle;

  /// Media ID (used for image URL construction in some sources)
  final String? mediaId;

  /// Related content
  final List<Content> relatedContent;

  @override
  List<Object?> get props => [
        id,
        sourceId,
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
        mediaId,
        relatedContent,
      ];

  Content copyWith({
    String? id,
    String? sourceId,
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
    String? mediaId,
    List<Content>? relatedContent,
  }) {
    return Content(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
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
      mediaId: mediaId ?? this.mediaId,
      relatedContent: relatedContent ?? this.relatedContent,
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

  /// Get content category
  String get category {
    final categoryTags = getTagsByType('category');
    return categoryTags.isNotEmpty ? categoryTags.first.name : 'doujinshi';
  }
}
