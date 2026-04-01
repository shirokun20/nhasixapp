import 'package:equatable/equatable.dart';

/// Domain entity for detailed tag information from API v2
class TagDetailEntity extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String type;
  final int count;
  final String? url;
  final String? description;
  final List<String>? aliases;

  const TagDetailEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.count,
    this.url,
    this.description,
    this.aliases,
  });

  @override
  List<Object?> get props =>
      [id, name, slug, type, count, url, description, aliases];
}
