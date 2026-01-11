/// Internal model for Crotpedia series data.
///
/// This model is used before mapping to [Content] entity.
class CrotpediaSeries {
  final String slug;
  final String title;
  final String coverUrl;
  final String? status;
  final String? author;
  final String? artist;
  final int? year;
  final Map<String, String> genres; // slug -> name
  final String? synopsis;

  const CrotpediaSeries({
    required this.slug,
    required this.title,
    required this.coverUrl,
    this.status,
    this.author,
    this.artist,
    this.year,
    this.genres = const {},
    this.synopsis,
  });

  @override
  String toString() {
    return 'CrotpediaSeries(slug: $slug, title: $title, status: $status)';
  }
}

/// Detailed series information including chapter list.
class CrotpediaSeriesDetail extends CrotpediaSeries {
  final List<CrotpediaChapter> chapters;

  const CrotpediaSeriesDetail({
    required super.slug,
    required super.title,
    required super.coverUrl,
    super.status,
    super.author,
    super.artist,
    super.year,
    super.genres,
    super.synopsis,
    required this.chapters,
  });

  @override
  String toString() {
    return 'CrotpediaSeriesDetail(slug: $slug, title: $title, chapters: ${chapters.length})';
  }
}

/// Chapter model referenced by series detail.
class CrotpediaChapter {
  final String slug;
  final String title;
  final int? chapterNumber;
  final DateTime? publishedDate;
  final String seriesSlug;

  const CrotpediaChapter({
    required this.slug,
    required this.title,
    this.chapterNumber,
    this.publishedDate,
    required this.seriesSlug,
  });

  @override
  String toString() {
    return 'CrotpediaChapter(slug: $slug, title: $title, chapter: $chapterNumber)';
  }
}
