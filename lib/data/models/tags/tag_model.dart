import 'package:nhasixapp/domain/entities/tags/tag_entity.dart';

/// Data model for tag from API v2
class TagModel extends TagEntity {
  const TagModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.type,
    required super.count,
    super.url,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String,
      count: json['count'] as int? ?? 0,
      url: json['url'] as String?,
    );
  }

  factory TagModel.fromEntity(TagEntity entity) {
    return TagModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      type: entity.type,
      count: entity.count,
      url: entity.url,
    );
  }

  TagEntity toEntity() {
    return TagEntity(
      id: id,
      name: name,
      slug: slug,
      type: type,
      count: count,
      url: url,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'count': count,
      'url': url,
    };
  }
}
