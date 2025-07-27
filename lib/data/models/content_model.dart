import 'dart:convert';
import '../../domain/entities/content.dart';
import '../../domain/entities/tag.dart';

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
    super.favorites = 0,
    super.englishTitle,
    super.japaneseTitle,
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
      favorites: content.favorites,
      englishTitle: content.englishTitle,
      japaneseTitle: content.japaneseTitle,
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
      favorites: favorites,
      englishTitle: englishTitle,
      japaneseTitle: japaneseTitle,
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
      favorites: favorites,
      englishTitle: englishTitle,
      japaneseTitle: japaneseTitle,
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
