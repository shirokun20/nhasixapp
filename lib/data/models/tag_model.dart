import '../../domain/entities/tag.dart';

/// Data model for Tag entity with database serialization
class TagModel extends Tag {
  const TagModel({
    required super.name,
    required super.type,
    required super.count,
    required super.url,
    this.id,
  });

  final int? id; // Database ID

  /// Create TagModel from Tag entity
  factory TagModel.fromEntity(Tag tag) {
    return TagModel(
      name: tag.name,
      type: tag.type,
      count: tag.count,
      url: tag.url,
    );
  }

  /// Convert to Tag entity
  Tag toEntity() {
    return Tag(
      name: name,
      type: type,
      count: count,
      url: url,
    );
  }

  /// Create from database map
  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      count: map['count'] ?? 0,
      url: map['url'] ?? '',
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
      'count': count,
      'url': url,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Create copy with database ID
  TagModel copyWithId(int id) {
    return TagModel(
      id: id,
      name: name,
      type: type,
      count: count,
      url: url,
    );
  }

  @override
  List<Object> get props => [
        ...super.props,
        id ?? 0, // Use 0 as default for null id
      ];
}
