/// nhentai API Response Models
///
/// JSON models for parsing nhentai API responses.
/// These models provide type-safe access to API data.
library;

/// Image type extension mapping from API response
/// Handles:
/// - Single letter codes: 'j' = jpg, 'p' = png, 'g' = gif, 'w' = webp
/// - Full extensions: 'jpg', 'jpeg', 'png', 'gif', 'webp'
/// - Mixed cases: 'JPG', 'Webp', etc.
String getImageExtension(String type) {
  // Normalize to lowercase and trim
  final normalized = type.toLowerCase().trim();

  return switch (normalized) {
    // Single letter codes (official nhentai API format)
    'j' => 'jpg',
    'p' => 'png',
    'g' => 'gif',
    'w' => 'webp',
    // Full extensions (sometimes returned by API)
    'jpg' || 'jpeg' => 'jpg',
    'png' => 'png',
    'gif' => 'gif',
    'webp' => 'webp',
    // Default fallback
    _ => 'jpg',
  };
}

/// Helper to safely parse int from dynamic (handles String or int)
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// nhentai Gallery Title
class NhentaiTitle {
  final String? english;
  final String? japanese;
  final String? pretty;

  const NhentaiTitle({
    this.english,
    this.japanese,
    this.pretty,
  });

  factory NhentaiTitle.fromJson(Map<String, dynamic> json) {
    return NhentaiTitle(
      english: json['english'] as String?,
      japanese: json['japanese'] as String?,
      pretty: json['pretty'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'english': english,
        'japanese': japanese,
        'pretty': pretty,
      };
}

/// nhentai Image Info (for pages, cover, thumbnail)
class NhentaiImageInfo {
  /// Image type: 'j'=jpg, 'p'=png, 'g'=gif, 'w'=webp
  final String type;

  /// Width in pixels
  final int? width;

  /// Height in pixels
  final int? height;

  const NhentaiImageInfo({
    required this.type,
    this.width,
    this.height,
  });

  factory NhentaiImageInfo.fromJson(Map<String, dynamic> json) {
    return NhentaiImageInfo(
      type: json['t'] as String? ?? 'j',
      width: _parseInt(json['w']),
      height: _parseInt(json['h']),
    );
  }

  Map<String, dynamic> toJson() => {
        't': type,
        'w': width,
        'h': height,
      };
}

/// nhentai Images Container
class NhentaiImages {
  final List<NhentaiImageInfo> pages;
  final NhentaiImageInfo cover;
  final NhentaiImageInfo? thumbnail;

  const NhentaiImages({
    required this.pages,
    required this.cover,
    this.thumbnail,
  });

  factory NhentaiImages.fromJson(Map<String, dynamic> json) {
    return NhentaiImages(
      pages: (json['pages'] as List<dynamic>?)
              ?.map((e) => NhentaiImageInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cover: NhentaiImageInfo.fromJson(json['cover'] as Map<String, dynamic>),
      thumbnail: json['thumbnail'] != null
          ? NhentaiImageInfo.fromJson(json['thumbnail'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'pages': pages.map((e) => e.toJson()).toList(),
        'cover': cover.toJson(),
        'thumbnail': thumbnail?.toJson(),
      };
}

/// nhentai Tag Info
class NhentaiTagInfo {
  final int id;
  final String type;
  final String name;
  final String? url;
  final int? count;

  const NhentaiTagInfo({
    required this.id,
    required this.type,
    required this.name,
    this.url,
    this.count,
  });

  factory NhentaiTagInfo.fromJson(Map<String, dynamic> json) {
    return NhentaiTagInfo(
      id: _parseInt(json['id']) ?? 0,
      type: json['type'] as String? ?? 'tag',
      name: json['name'] as String? ?? '',
      url: json['url'] as String?,
      count: _parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'url': url,
        'count': count,
      };
}

/// nhentai Gallery Response (single gallery detail)
class NhentaiGalleryResponse {
  final int id;
  final String mediaId;
  final NhentaiTitle title;
  final NhentaiImages images;
  final String? scanlator;
  final int? uploadDate;
  final List<NhentaiTagInfo> tags;
  final int? numPages;
  final int? numFavorites;

  const NhentaiGalleryResponse({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.images,
    this.scanlator,
    this.uploadDate,
    this.tags = const [],
    this.numPages,
    this.numFavorites,
  });

  factory NhentaiGalleryResponse.fromJson(Map<String, dynamic> json) {
    return NhentaiGalleryResponse(
      id: _parseInt(json['id']) ?? 0,
      mediaId: json['media_id'] as String? ?? '',
      title:
          NhentaiTitle.fromJson(json['title'] as Map<String, dynamic>? ?? {}),
      images:
          NhentaiImages.fromJson(json['images'] as Map<String, dynamic>? ?? {}),
      scanlator: json['scanlator'] as String?,
      uploadDate: _parseInt(json['upload_date']),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => NhentaiTagInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      numPages: _parseInt(json['num_pages']),
      numFavorites: _parseInt(json['num_favorites']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'media_id': mediaId,
        'title': title.toJson(),
        'images': images.toJson(),
        'scanlator': scanlator,
        'upload_date': uploadDate,
        'tags': tags.map((e) => e.toJson()).toList(),
        'num_pages': numPages,
        'num_favorites': numFavorites,
      };
}

/// nhentai List Response (for search, homepage, popular)
class NhentaiListResponse {
  final List<NhentaiGalleryResponse> result;
  final int? numPages;
  final int? perPage;

  const NhentaiListResponse({
    required this.result,
    this.numPages,
    this.perPage,
  });

  factory NhentaiListResponse.fromJson(Map<String, dynamic> json) {
    return NhentaiListResponse(
      result: (json['result'] as List<dynamic>?)
              ?.map((e) =>
                  NhentaiGalleryResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      numPages: _parseInt(json['num_pages']),
      perPage: _parseInt(json['per_page']),
    );
  }

  Map<String, dynamic> toJson() => {
        'result': result.map((e) => e.toJson()).toList(),
        'num_pages': numPages,
        'per_page': perPage,
      };
}

/// nhentai Related Response
class NhentaiRelatedResponse {
  final List<NhentaiGalleryResponse> result;

  const NhentaiRelatedResponse({
    required this.result,
  });

  factory NhentaiRelatedResponse.fromJson(Map<String, dynamic> json) {
    return NhentaiRelatedResponse(
      result: (json['result'] as List<dynamic>?)
              ?.map((e) =>
                  NhentaiGalleryResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'result': result.map((e) => e.toJson()).toList(),
      };
}
