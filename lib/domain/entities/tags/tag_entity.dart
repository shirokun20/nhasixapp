import 'package:equatable/equatable.dart';

/// Domain entity for tag data from API v2
class TagEntity extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String type;
  final int count;
  final String? url;

  const TagEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.count,
    this.url,
  });

  @override
  List<Object?> get props => [id, name, slug, type, count, url];
}
