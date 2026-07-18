/// nhentai Comment Model
class NhentaiComment {
  final int id;
  final int galleryId;
  final NhentaiUser poster;
  final String body;
  final int postDate;

  const NhentaiComment({
    required this.id,
    required this.galleryId,
    required this.poster,
    required this.body,
    required this.postDate,
  });

  factory NhentaiComment.fromJson(Map<String, dynamic> json) {
    return NhentaiComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      galleryId: (json['gallery_id'] as num?)?.toInt() ?? 0,
      poster: json['poster'] is Map<String, dynamic>
          ? NhentaiUser.fromJson(json['poster'] as Map<String, dynamic>)
          : NhentaiUser.fromJson({}),
      body: json['body'] as String? ?? '',
      postDate: (json['post_date'] as num?)?.toInt() ?? 0,
    );
  }
}

/// nhentai User Model
class NhentaiUser {
  final int id;
  final String username;
  final String slug;
  final String avatarUrl;
  final bool isSuperuser;
  final bool isStaff;

  const NhentaiUser({
    required this.id,
    required this.username,
    required this.slug,
    required this.avatarUrl,
    required this.isSuperuser,
    required this.isStaff,
  });

  factory NhentaiUser.fromJson(Map<String, dynamic> json) {
    return NhentaiUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      isSuperuser: json['is_superuser'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
    );
  }
}
