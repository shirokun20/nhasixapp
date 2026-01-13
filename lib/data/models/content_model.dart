import 'dart:convert';
import 'package:kuron_core/kuron_core.dart';
import '../datasources/remote/api/nhentai_api_models.dart';
import '../datasources/remote/api/nhentai_image_url_builder.dart';

/// Data model for Content entity with database serialization
class ContentModel extends Content {
  const ContentModel({
    required super.id,
    required super.title,
    required super.coverUrl,
    required super.tags,
    required super.artists,
    required super.characters,
    required super.parodies,
    required super.groups,
    required super.language,
    required super.pageCount,
    required super.imageUrls,
    required super.uploadDate,
    super.sourceId = 'nhentai',
    super.favorites = 0,
    super.englishTitle,
    super.japaneseTitle,
    super.relatedContent = const [],
    this.cachedAt,
  });

  final DateTime? cachedAt;

  /// Create ContentModel from Content entity
  factory ContentModel.fromEntity(Content content) {
    return ContentModel(
      id: content.id,
      title: content.title,
      coverUrl: content.coverUrl,
      tags: content.tags,
      artists: content.artists,
      characters: content.characters,
      parodies: content.parodies,
      groups: content.groups,
      language: content.language,
      pageCount: content.pageCount,
      imageUrls: content.imageUrls,
      uploadDate: content.uploadDate,
      sourceId: content.sourceId,
      favorites: content.favorites,
      englishTitle: content.englishTitle,
      japaneseTitle: content.japaneseTitle,
      relatedContent: content.relatedContent,
      cachedAt: DateTime.now(),
    );
  }

  /// Create ContentModel from nhentai API response
  ///
  /// This factory provides direct mapping from API response,
  /// without needing TagResolver since tags are already resolved in API.
  factory ContentModel.fromNhentaiApi(NhentaiGalleryResponse response) {
    // Extract tags by type
    final allTags = response.tags
        .map((t) => Tag(
              id: t.id,
              name: t.name,
              type: t.type,
              count: t.count ?? 0,
              url: t.url ?? '/tag/${t.name.replaceAll(' ', '-')}/',
            ))
        .toList();

    final artists = response.tags
        .where((t) => t.type == 'artist')
        .map((t) => t.name)
        .toList();

    final characters = response.tags
        .where((t) => t.type == 'character')
        .map((t) => t.name)
        .toList();

    final parodies = response.tags
        .where((t) => t.type == 'parody')
        .map((t) => t.name)
        .toList();

    final groups = response.tags
        .where((t) => t.type == 'group')
        .map((t) => t.name)
        .toList();

    // Extract language from tags
    final languageTag = response.tags.firstWhere(
      (t) => t.type == 'language',
      orElse: () =>
          const NhentaiTagInfo(id: 0, type: 'language', name: 'unknown'),
    );

    // Build cover URL (Using Page 1 Thumbnail for reliability)
    final coverUrl = response.images.pages.isNotEmpty
        ? NhentaiImageUrlBuilder.buildPageThumbnailUrl(
            response.mediaId,
            1, // Page 1
            response.images.pages.first.type,
          )
        : NhentaiImageUrlBuilder.buildCoverUrl(
            response.mediaId,
            response.images.cover.type,
          );

    // Build all page URLs
    final imageUrls = NhentaiImageUrlBuilder.buildAllPageUrls(
      response.mediaId,
      response.images.pages,
    );

    // Determine best title
    final title = response.title.pretty ??
        response.title.english ??
        response.title.japanese ??
        'Unknown Title';

    return ContentModel(
      id: response.id.toString(),
      title: title,
      englishTitle: response.title.english,
      japaneseTitle: response.title.japanese,
      coverUrl: coverUrl,
      tags: allTags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: languageTag.name,
      pageCount: response.numPages ?? response.images.pages.length,
      imageUrls: imageUrls,
      uploadDate: response.uploadDate != null
          ? DateTime.fromMillisecondsSinceEpoch(response.uploadDate! * 1000)
          : DateTime.now(),
      sourceId: 'nhentai',
      favorites: response.numFavorites ?? 0,
      cachedAt: DateTime.now(),
    );
  }

  /// Create ContentModel from nhentai API response (list version)
  ///
  /// Simplified version for list/search results where full page URLs
  /// are not needed yet (will be fetched on detail view).
  factory ContentModel.fromNhentaiApiPreview(NhentaiGalleryResponse response) {
    // Extract tags by type
    final allTags = response.tags
        .map((t) => Tag(
              id: t.id,
              name: t.name,
              type: t.type,
              count: t.count ?? 0,
              url: t.url ?? '/tag/${t.name.replaceAll(' ', '-')}/',
            ))
        .toList();

    final artists = response.tags
        .where((t) => t.type == 'artist')
        .map((t) => t.name)
        .toList();

    final characters = response.tags
        .where((t) => t.type == 'character')
        .map((t) => t.name)
        .toList();

    final parodies = response.tags
        .where((t) => t.type == 'parody')
        .map((t) => t.name)
        .toList();

    final groups = response.tags
        .where((t) => t.type == 'group')
        .map((t) => t.name)
        .toList();

    // Extract language from tags
    final languageTag = response.tags.firstWhere(
      (t) => t.type == 'language',
      orElse: () =>
          const NhentaiTagInfo(id: 0, type: 'language', name: 'unknown'),
    );

    // Build cover URL (Using Page 1 Thumbnail for reliability)
    final coverUrl = response.images.pages.isNotEmpty
        ? NhentaiImageUrlBuilder.buildPageThumbnailUrl(
            response.mediaId,
            1, // Page 1
            response.images.pages.first.type,
          )
        : NhentaiImageUrlBuilder.buildCoverUrl(
            response.mediaId,
            response.images.cover.type,
          );

    // Determine best title
    final title = response.title.pretty ??
        response.title.english ??
        response.title.japanese ??
        'Unknown Title';

    return ContentModel(
      id: response.id.toString(),
      title: title,
      englishTitle: response.title.english,
      japaneseTitle: response.title.japanese,
      coverUrl: coverUrl,
      tags: allTags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: languageTag.name,
      pageCount: response.numPages ?? response.images.pages.length,
      imageUrls: NhentaiImageUrlBuilder.buildAllPageUrls(
        response.mediaId,
        response.images.pages,
      ),
      uploadDate: response.uploadDate != null
          ? DateTime.fromMillisecondsSinceEpoch(response.uploadDate! * 1000)
          : DateTime.now(),
      sourceId: 'nhentai',
      favorites: response.numFavorites ?? 0,
      cachedAt: DateTime.now(),
    );
  }

  /// Convert to Content entity
  Content toEntity() {
    return Content(
      id: id,
      title: title,
      coverUrl: coverUrl,
      tags: tags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: language,
      pageCount: pageCount,
      imageUrls: imageUrls,
      uploadDate: uploadDate,
      sourceId: sourceId,
      favorites: favorites,
      englishTitle: englishTitle,
      japaneseTitle: japaneseTitle,
      relatedContent: relatedContent,
    );
  }

  /// Create from database map
  factory ContentModel.fromMap(Map<String, dynamic> map, List<Tag> tags) {
    return ContentModel(
      id: map['id'],
      title: map['title'],
      englishTitle: map['english_title'],
      japaneseTitle: map['japanese_title'],
      coverUrl: map['cover_url'],
      artists: _decodeStringList(map['artists']),
      characters: _decodeStringList(map['characters']),
      parodies: _decodeStringList(map['parodies']),
      groups: _decodeStringList(map['groups']),
      language: map['language'],
      pageCount: map['page_count'],
      imageUrls: _decodeStringList(map['image_urls']),
      uploadDate: DateTime.fromMillisecondsSinceEpoch(map['upload_date']),
      sourceId: map['source_id'] ?? 'nhentai',
      favorites: map['favorites'] ?? 0,
      tags: tags,
      cachedAt: map['cached_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['cached_at'])
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'english_title': englishTitle,
      'japanese_title': japaneseTitle,
      'cover_url': coverUrl,
      'artists': _encodeStringList(artists),
      'characters': _encodeStringList(characters),
      'parodies': _encodeStringList(parodies),
      'groups': _encodeStringList(groups),
      'language': language,
      'page_count': pageCount,
      'image_urls': _encodeStringList(imageUrls),
      'upload_date': uploadDate.millisecondsSinceEpoch,
      'source_id': sourceId,
      'favorites': favorites,
      'cached_at': cachedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Create copy with updated cache time
  ContentModel copyWithCacheTime() {
    return ContentModel(
      id: id,
      title: title,
      coverUrl: coverUrl,
      tags: tags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: language,
      pageCount: pageCount,
      imageUrls: imageUrls,
      uploadDate: uploadDate,
      sourceId: sourceId,
      favorites: favorites,
      englishTitle: englishTitle,
      japaneseTitle: japaneseTitle,
      relatedContent: relatedContent,
      cachedAt: DateTime.now(),
    );
  }

  /// Check if cache is expired
  bool isCacheExpired({Duration maxAge = const Duration(hours: 24)}) {
    if (cachedAt == null) return true;
    return DateTime.now().difference(cachedAt!) > maxAge;
  }

  /// Encode string list to JSON
  static String _encodeStringList(List<String> list) {
    return jsonEncode(list);
  }

  /// Decode string list from JSON
  static List<String> _decodeStringList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  List<Object?> get props => [
        ...super.props,
        cachedAt,
      ];
}
