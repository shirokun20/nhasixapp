class CrotpediaGenre {
  final String name;
  final String slug;
  final String url;
  final int count;

  const CrotpediaGenre({
    required this.name,
    required this.slug,
    required this.url,
    required this.count,
  });

  @override
  String toString() {
    return 'CrotpediaGenre(name: $name, slug: $slug, count: $count)';
  }
}
