import 'dart:convert';

/// Metadata schema version for download files.
///
/// v1.0 - Original format (nhentai-specific)
/// v2.0 - Multi-source support with source identifier
class MetadataVersion {
  static const String v1 = '1.0';
  static const String v2 = '2.0';
  static const String current = v2;
}

/// Content metadata for downloaded content.
///
/// This model represents the metadata.json file structure that is saved
/// alongside downloaded content files.
class ContentMetadata {
  const ContentMetadata({
    required this.schemaVersion,
    required this.source,
    required this.id,
    required this.title,
    this.englishTitle,
    this.japaneseTitle,
    required this.coverUrl,
    required this.pageCount,
    required this.imageUrls,
    this.tags = const [],
    this.artists = const [],
    this.characters = const [],
    this.parodies = const [],
    this.groups = const [],
    this.language = 'unknown',
    this.category = 'doujinshi',
    this.uploadDate,
    this.favorites = 0,
    this.mediaId,
    required this.downloadedAt,
    this.appVersion,
  });

  /// Schema version for migration support
  final String schemaVersion;

  /// Source identifier (e.g., 'nhentai', 'crotpedia')
  final String source;

  /// Content ID (source-specific format)
  final String id;

  /// Primary title
  final String title;

  /// English title (optional)
  final String? englishTitle;

  /// Japanese title (optional)
  final String? japaneseTitle;

  /// Cover image URL
  final String coverUrl;

  /// Number of pages
  final int pageCount;

  /// List of image URLs or local paths
  final List<String> imageUrls;

  /// Content tags
  final List<Map<String, dynamic>> tags;

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

  /// Content category
  final String category;

  /// Upload/publish date (ISO 8601)
  final String? uploadDate;

  /// Favorites count
  final int favorites;

  /// Media ID (used for image URL building)
  final String? mediaId;

  /// When content was downloaded (ISO 8601)
  final String downloadedAt;

  /// App version that created this metadata
  final String? appVersion;

  /// Create from JSON map
  factory ContentMetadata.fromJson(Map<String, dynamic> json) {
    // Handle v1.0 format (no schemaVersion field)
    final version = json['schemaVersion'] as String? ?? MetadataVersion.v1;

    // For v1.0, source is always 'nhentai'
    final source = json['source'] as String? ?? 'nhentai';

    return ContentMetadata(
      schemaVersion: version,
      source: source,
      id: (json['id'] ?? json['contentId'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      englishTitle: json['englishTitle'] as String?,
      japaneseTitle: json['japaneseTitle'] as String?,
      coverUrl: json['coverUrl'] as String? ?? '',
      pageCount: json['pageCount'] as int? ?? 0,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      parodies: (json['parodies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      language: json['language'] as String? ?? 'unknown',
      category: json['category'] as String? ?? 'doujinshi',
      uploadDate: json['uploadDate'] as String?,
      favorites: json['favorites'] as int? ?? 0,
      mediaId: json['mediaId']?.toString(),
      downloadedAt:
          json['downloadedAt'] as String? ?? DateTime.now().toIso8601String(),
      appVersion: json['appVersion'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'source': source,
      'id': id,
      'title': title,
      if (englishTitle != null) 'englishTitle': englishTitle,
      if (japaneseTitle != null) 'japaneseTitle': japaneseTitle,
      'coverUrl': coverUrl,
      'pageCount': pageCount,
      'imageUrls': imageUrls,
      'tags': tags,
      'artists': artists,
      'characters': characters,
      'parodies': parodies,
      'groups': groups,
      'language': language,
      'category': category,
      if (uploadDate != null) 'uploadDate': uploadDate,
      'favorites': favorites,
      if (mediaId != null) 'mediaId': mediaId,
      'downloadedAt': downloadedAt,
      if (appVersion != null) 'appVersion': appVersion,
    };
  }

  /// Convert to JSON string
  String toJsonString({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Create v2.0 metadata from v1.0 format
  factory ContentMetadata.migrateFromV1(Map<String, dynamic> v1Json) {
    // v1.0 format assumed to be nhentai-specific
    return ContentMetadata.fromJson({
      ...v1Json,
      'schemaVersion': MetadataVersion.v2,
      'source': 'nhentai',
    });
  }

  /// Check if this metadata needs migration
  bool get needsMigration => schemaVersion != MetadataVersion.current;

  /// Create a copy with updated fields
  ContentMetadata copyWith({
    String? schemaVersion,
    String? source,
    String? id,
    String? title,
    String? englishTitle,
    String? japaneseTitle,
    String? coverUrl,
    int? pageCount,
    List<String>? imageUrls,
    List<Map<String, dynamic>>? tags,
    List<String>? artists,
    List<String>? characters,
    List<String>? parodies,
    List<String>? groups,
    String? language,
    String? category,
    String? uploadDate,
    int? favorites,
    String? mediaId,
    String? downloadedAt,
    String? appVersion,
  }) {
    return ContentMetadata(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      source: source ?? this.source,
      id: id ?? this.id,
      title: title ?? this.title,
      englishTitle: englishTitle ?? this.englishTitle,
      japaneseTitle: japaneseTitle ?? this.japaneseTitle,
      coverUrl: coverUrl ?? this.coverUrl,
      pageCount: pageCount ?? this.pageCount,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      artists: artists ?? this.artists,
      characters: characters ?? this.characters,
      parodies: parodies ?? this.parodies,
      groups: groups ?? this.groups,
      language: language ?? this.language,
      category: category ?? this.category,
      uploadDate: uploadDate ?? this.uploadDate,
      favorites: favorites ?? this.favorites,
      mediaId: mediaId ?? this.mediaId,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
