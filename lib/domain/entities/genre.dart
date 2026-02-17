import 'package:equatable/equatable.dart';

/// Genre entity representing a content genre/category
class Genre extends Equatable {
  final String slug;
  final String name;
  final int count;
  final String url;

  const Genre({
    required this.slug,
    required this.name,
    required this.count,
    required this.url,
  });

  @override
  List<Object?> get props => [slug, name, count, url];

  Genre copyWith({
    String? slug,
    String? name,
    int? count,
    String? url,
  }) {
    return Genre(
      slug: slug ?? this.slug,
      name: name ?? this.name,
      count: count ?? this.count,
      url: url ?? this.url,
    );
  }
}
