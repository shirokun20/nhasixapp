/// Simple model for series metadata from list pages
class KomiktapSeriesMetadata {
  final String id; // slug
  final String title;
  final String coverImageUrl;
  final String? subtitle; // additional title/info
  final DateTime? lastUpdate;
  final List<String> tags; // genre names

  const KomiktapSeriesMetadata({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    this.subtitle,
    this.lastUpdate,
    this.tags = const [],
  });
}

/// Detailed series information from series detail page
class KomiktapSeriesDetail {
  final String id; // slug
  final String title;
  final String? alternativeTitle;
  final String coverImageUrl;
  final String? author;
  final String? status;
  final String? type;
  final String? rating;
  final String? synopsis;
  final DateTime? lastUpdate;
  final List<String> tags; // genre names
  final List<KomiktapChapterInfo>? chapters;
  final int? favorites;

  const KomiktapSeriesDetail({
    required this.id,
    required this.title,
    this.alternativeTitle,
    required this.coverImageUrl,
    this.author,
    this.status,
    this.type,
    this.rating,
    this.synopsis,
    this.lastUpdate,
    this.tags = const [],
    this.chapters,
    this.favorites,
  });
}

/// Chapter information
class KomiktapChapterInfo {
  final String id; // chapter slug
  final String title;
  final DateTime? publishDate;

  const KomiktapChapterInfo({
    required this.id,
    required this.title,
    this.publishDate,
  });
}

/// Pagination information
class KomiktapPagination {
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const KomiktapPagination({
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });
}
