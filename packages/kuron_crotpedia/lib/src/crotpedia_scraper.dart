import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'models/crotpedia_series.dart';

/// HTML parsing logic for Crotpedia website.
class CrotpediaScraper {
  // ============ Series List Parsing ============

  /// Parse homepage "Update Terbaru" section
  /// Input: HTML string from homepage
  /// Output: List of series with basic info
  List<CrotpediaSeries> parseLatestSeries(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    // Real HTML uses .flexbox4-item for latest updates
    final items = document.querySelectorAll('.flexbox4-item');

    return items.map((item) {
      // Series URL from first <a> tag
      final link = item.querySelector('a');
      // Cover image from .flexbox4-thumb img
      final img = item.querySelector('.flexbox4-thumb img');
      // Title from .flexbox4-side .title a
      final title = item.querySelector('.flexbox4-side .title a')?.text ?? '';

      return CrotpediaSeries(
        slug: _extractSlug(link?.attributes['href']),
        title: title.trim(),
        coverUrl: img?.attributes['src'] ?? '',
      );
    }).toList();
  }

  /// Parse search results page
  List<CrotpediaSeries> parseSearchResults(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    // Real HTML uses .flexbox2-item for search results
    final items = document.querySelectorAll('.flexbox2-item');

    return items.map((item) {
      // Series URL from first <a> tag
      final link = item.querySelector('a');
      // Cover image from .flexbox2-thumb img
      final img = item.querySelector('.flexbox2-thumb img');
      // Title from .flexbox2-title span:first-child
      final titleElement = item.querySelector('.flexbox2-title span');
      final title = titleElement?.text ?? '';

      return CrotpediaSeries(
        slug: _extractSlug(link?.attributes['href']),
        title: title.trim(),
        coverUrl: img?.attributes['src'] ?? '',
      );
    }).toList();
  }

  /// Parse doujin list page (alphabetical)
  List<CrotpediaSeries> parseDoujinList(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final items = document.querySelectorAll('a.series');

    return items.map((item) {
      return CrotpediaSeries(
        slug: _extractSlug(item.attributes['href']),
        title: item.text.trim(),
        coverUrl: '', // No cover in list view
      );
    }).toList();
  }

  /// Parse pagination info from any page list
  /// Output: Tuple of (currentPage, totalPages, hasNext, hasPrevious)
  ({int currentPage, int totalPages, bool hasNext, bool hasPrevious})
      parsePagination(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    // Current page from .pagination .page-numbers.current
    final currentEl =
        document.querySelector('.pagination .page-numbers.current');
    final currentPage = int.tryParse(currentEl?.text.trim() ?? '1') ?? 1;

    // Check for "Next" and "Previous" links
    // Real HTML uses a.next.page-numbers and a.prev.page-numbers
    final nextEl = document.querySelector('.pagination .next.page-numbers');
    final hasNext = nextEl != null;

    final prevEl = document.querySelector('.pagination .prev.page-numbers');
    final hasPrevious = prevEl != null;

    // Extract total pages from the last numbered page link
    // HTML structure: <a class="page-numbers" href=".../page/136/">136</a>
    // Get all numbered page links (excluding current, dots, and next/prev)
    final pageLinks = document
        .querySelectorAll('.pagination a.page-numbers:not(.next):not(.prev)');

    int totalPages = 0;
    if (pageLinks.isNotEmpty) {
      // Find the highest page number from all page links
      for (final link in pageLinks) {
        final pageText = link.text.trim();
        final pageNum = int.tryParse(pageText);
        if (pageNum != null && pageNum > totalPages) {
          totalPages = pageNum;
        }
      }
    }

    // Ensure totalPages takes into account the current page
    // This handles the case where the current page (last page) is not an 'a' link but a 'span'
    if (currentPage > totalPages) {
      totalPages = currentPage;
    }

    return (
      currentPage: currentPage,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrevious: hasPrevious
    );
  }

  // ============ Series Detail Parsing ============

  /// Parse series detail page
  /// Input: HTML from /baca/series/{slug}/
  /// Output: Full series info with chapter list
  CrotpediaSeriesDetail parseSeriesDetail(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    return CrotpediaSeriesDetail(
      slug: '', // Will be provided externally
      title: _parseTitle(document),
      coverUrl: _parseCover(document),
      status: _parseStatus(document),
      author: _parseAuthor(document),
      artist: _parseArtist(document),
      year: _parseYear(document),
      genres: _parseGenres(document),
      synopsis: _parseSynopsis(document),
      chapters: _parseChapterList(document),
    );
  }

  List<CrotpediaChapter> _parseChapterList(Document document) {
    // Real HTML uses .series-chapterlist li
    final items = document.querySelectorAll('.series-chapterlist li');

    return items.map((item) {
      // Chapter link from .flexch-infoz a
      final link = item.querySelector('.flexch-infoz a');
      // Chapter date from .flexch-infoz .date
      final date = item.querySelector('.flexch-infoz .date')?.text;
      // Chapter title from .flexch-infoz a span:first-child
      final titleSpan = item.querySelector('.flexch-infoz a span');
      final title = titleSpan?.text ?? '';

      return CrotpediaChapter(
        slug: _extractSlug(link?.attributes['href']),
        title: title.trim(),
        publishedDate: _parseDate(date),
        seriesSlug: '', // Will be filled by caller
      );
    }).toList();
  }

  // ============ Chapter/Reader Parsing ============

  /// Parse chapter page to extract image URLs
  /// Input: HTML from /baca/{chapterSlug}/
  /// Output: List of image URLs in order
  List<String> parseChapterImages(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    // Real HTML uses .reader-area for chapter images
    final container = document.querySelector('.reader-area');

    if (container == null) return [];

    // Images are within <p> tags: .reader-area p img
    final images = container.querySelectorAll('p img');

    return images
        .map((img) => img.attributes['src'] ?? '')
        .where((src) => src.isNotEmpty)
        .toList();
  }

  // ============ Helper Methods ============

  String _extractSlug(String? url) {
    if (url == null) return '';
    // Extract slug from URL like /baca/series/slug-name/ or /baca/slug-name/
    final regex = RegExp(r'/baca/(?:series/)?([^/]+)/?$');
    final slug = regex.firstMatch(url)?.group(1) ?? '';

    // HTML parser decodes URL-encoded characters (e.g., %e2%99%a5 → ❤️)
    // We need to re-encode them for ContentId validation
    // Use Uri.encodeComponent but preserve existing hyphens and underscores
    if (slug.isEmpty) return '';

    // Check if slug contains non-ASCII characters (emoji, special chars)
    if (slug.codeUnits.any((unit) => unit > 127)) {
      // URL-encode the entire slug
      return Uri.encodeComponent(slug);
    }

    return slug;
  }

  String _parseTitle(Document doc) {
    return doc.querySelector('.series-titlex h2')?.text.trim() ?? '';
  }

  String _parseCover(Document doc) {
    final img = doc.querySelector('.series-thumb img');
    return img?.attributes['src'] ?? '';
  }

  String? _parseStatus(Document doc) {
    // Real HTML: <div class="series-infoz block"><span class="status Completed">Completed</span></div>
    return doc.querySelector('.series-infoz .status')?.text.trim();
  }

  String? _parseAuthor(Document doc) {
    // Real HTML: <ul class="series-infolist"><li><b>Author</b><span>Peniken</span></li></ul>
    return _parseInfoFromList(doc, 'Author');
  }

  String? _parseArtist(Document doc) {
    // Artist might be same as Author or separate, using list parsing
    return _parseInfoFromList(doc, 'Artist');
  }

  int? _parseYear(Document doc) {
    // Real HTML: <li><b>Published</b><span>2025</span></li>
    final yearText = _parseInfoFromList(doc, 'Published') ??
        _parseInfoFromList(doc, 'Released');
    if (yearText == null) return null;
    return int.tryParse(yearText);
  }

  Map<String, String> _parseGenres(Document doc) {
    // Real HTML: <div class="series-genres"><a href="https://crotpedia.net/baca/genre/comedy/">Comedy</a></div>
    final genreLinks = doc.querySelectorAll('.series-genres a');
    final Map<String, String> genres = {};

    for (final link in genreLinks) {
      final name = link.text.trim();
      final href = link.attributes['href'];
      if (name.isNotEmpty && href != null) {
        // Extract slug from /baca/genre/slug/
        // Assuming href is typical: https://crotpedia.net/baca/genre/comedy/
        // or just /baca/genre/comedy/
        final uri = Uri.tryParse(href);
        if (uri != null) {
          final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
          // Segments might be ['baca', 'genre', 'comedy']
          if (segments.length >= 3 && segments[1] == 'genre') {
            genres[segments[2]] = name;
          } else {
            // Fallback if structure is weird, use name as slug
            genres[name.toLowerCase().replaceAll(' ', '-')] = name;
          }
        }
      }
    }
    return genres;
  }

  /// Helper to extract value from info list based on label
  String? _parseInfoFromList(Document doc, String label) {
    final items = doc.querySelectorAll('.series-infolist li');
    for (var item in items) {
      final bKey = item.querySelector('b')?.text.trim();
      if (bKey != null && bKey.contains(label)) {
        return item.querySelector('span')?.text.trim();
      }
    }
    return null;
  }

  String? _parseSynopsis(Document doc) {
    // Real HTML: <div class="series-synops"> <p>...</p> </div>
    final synopsisElement = doc.querySelector('.series-synops p');
    return synopsisElement?.text.trim();
  }

  DateTime? _parseDate(String? dateText) {
    if (dateText == null || dateText.isEmpty) return null;
    try {
      // Try to parse common date formats
      // This is a simplified version, adjust based on actual format
      return DateTime.tryParse(dateText);
    } catch (_) {
      return null;
    }
  }
}
