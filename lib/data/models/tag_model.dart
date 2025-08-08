import '../../domain/entities/tag.dart';

/// Data model for Tag entity with database serialization
class TagModel extends Tag {
  const TagModel({
    required int id,
    required super.name,
    required super.type,
    required super.count,
    required super.url,
    super.slug,
  }) : super(id: id);

  /// Create TagModel from Tag entity
  factory TagModel.fromEntity(Tag tag) {
    return TagModel(
      id: tag.id,
      name: tag.name,
      type: tag.type,
      count: tag.count,
      url: tag.url,
      slug: tag.slug,
    );
  }

  /// Convert to Tag entity
  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      type: type,
      count: count,
      url: url,
      slug: slug,
    );
  }

  /// Create from database map
  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      type: map['type'] ?? 'tag',
      count: map['count'] ?? 0,
      url: map['url'] ?? '',
      slug: map['slug'],
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type,
      'count': count,
      'url': url,
      'slug': slug,
    };
  }

  /// Create copy with new values
  TagModel copyWith({
    int? id,
    String? name,
    String? type,
    int? count,
    String? url,
    String? slug,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      count: count ?? this.count,
      url: url ?? this.url,
      slug: slug ?? this.slug,
    );
  }
}
