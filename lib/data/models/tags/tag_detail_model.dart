import 'package:nhasixapp/domain/entities/tags/tag_detail_entity.dart';

/// Data model for tag detail from API v2
class TagDetailModel extends TagDetailEntity {
  const TagDetailModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.type,
    required super.count,
    super.url,
    super.description,
    super.aliases,
  });

  factory TagDetailModel.fromJson(Map<String, dynamic> json) {
    return TagDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String,
      count: json['count'] as int? ?? 0,
      url: json['url'] as String?,
      description: json['description'] as String?,
      aliases: (json['aliases'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  factory TagDetailModel.fromEntity(TagDetailEntity entity) {
    return TagDetailModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      type: entity.type,
      count: entity.count,
      url: entity.url,
      description: entity.description,
      aliases: entity.aliases,
    );
  }

  TagDetailEntity toEntity() {
    return TagDetailEntity(
      id: id,
      name: name,
      slug: slug,
      type: type,
      count: count,
      url: url,
      description: description,
      aliases: aliases,
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
      'description': description,
      'aliases': aliases,
    };
  }
}
