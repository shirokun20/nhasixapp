
class GenreItem {
  final String name;
  final String slug;
  final String url;
  final int count;

  GenreItem({
    required this.name,
    required this.slug,
    required this.url,
    required this.count,
  });
}

class DoujinListItem {
  final String title;
  final String url;
  final String? id; // From 'rel' attribute

  DoujinListItem({
    required this.title,
    required this.url,
    this.id,
  });
}

class RequestItem {
  final String title;
  final String coverUrl;
  final String url;
  final int id; // ID for pagination/key
  final String? status; // Optional - not always available in HTML
  final Map<String, String> genres; // slug -> name

  RequestItem({
    required this.title,
    required this.coverUrl,
    required this.url,
    required this.id,
    this.status,
    this.genres = const {},
  });
}
