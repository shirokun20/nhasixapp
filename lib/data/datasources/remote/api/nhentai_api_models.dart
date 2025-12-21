/// nhentai API Response Models
///
/// JSON models for parsing nhentai API responses.
/// These models provide type-safe access to API data.
library;

/// Image type extension mapping from API response
/// 'j' = jpg, 'p' = png, 'g' = gif, 'w' = webp
String getImageExtension(String type) {
  return switch (type) {
    'j' => 'jpg',
    'p' => 'png',
    'g' => 'gif',
    'w' => 'webp',
    _ => 'jpg', // Default fallback
  };
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
      width: json['w'] as int?,
      height: json['h'] as int?,
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
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'tag',
      name: json['name'] as String? ?? '',
      url: json['url'] as String?,
      count: json['count'] as int?,
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
      id: json['id'] as int? ?? 0,
      mediaId: json['media_id'] as String? ?? '',
      title:
          NhentaiTitle.fromJson(json['title'] as Map<String, dynamic>? ?? {}),
      images:
          NhentaiImages.fromJson(json['images'] as Map<String, dynamic>? ?? {}),
      scanlator: json['scanlator'] as String?,
      uploadDate: json['upload_date'] as int?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => NhentaiTagInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      numPages: json['num_pages'] as int?,
      numFavorites: json['num_favorites'] as int?,
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
      numPages: json['num_pages'] as int?,
      perPage: json['per_page'] as int?,
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
