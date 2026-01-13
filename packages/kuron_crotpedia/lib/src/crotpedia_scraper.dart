import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'models/crotpedia_series.dart';

/// HTML parsing logic for Crotpedia website.
class CrotpediaScraper {
  // Default CSS selectors (can be overridden via constructor)
  static const Map<String, String> _defaultSelectors = {
    // List pages
    'latest_item': '.flexbox4-item',
    'latest_link': 'a',
    'latest_thumb': '.flexbox4-thumb img',
    'latest_title': '.flexbox4-side .title a',

    'search_item': '.flexbox2-item',
    'search_link': 'a',
    'search_thumb': '.flexbox2-thumb img',
    'search_title': '.flexbox2-title span',

    'doujin_item': 'a.series',

    // Pagination
    'pagination_current': '.pagination .page-numbers.current',
    'pagination_next': '.pagination .next.page-numbers',
    'pagination_prev': '.pagination .prev.page-numbers',
    'pagination_links': '.pagination a.page-numbers:not(.next):not(.prev)',

    // Series detail
    'detail_title': '.series-titlex h2',
    'detail_cover': '.series-thumb img',
    'detail_status': '.series-infoz .status',
    'detail_infolist': '.series-infolist li',
    'detail_genres': '.series-genres a',
    'detail_synopsis': '.series-synops p',

    // Chapters
    'chapter_list': '.series-chapterlist li',
    'chapter_link': '.flexch-infoz a',
    'chapter_date': '.flexch-infoz .date',
    'chapter_title': '.flexch-infoz a span',

    // Reader
    'reader_container': '.reader-area',
    'reader_images': 'p img',
  };

  final Map<String, String> _selectors;

  /// Create scraper with optional custom selectors
  CrotpediaScraper({Map<String, dynamic>? customSelectors})
      : _selectors = {
          ..._defaultSelectors,
          ...?customSelectors?.map((k, v) => MapEntry(k, v.toString())),
        };

  /// Get selector by key, fallback to default if not found
  String _getSelector(String key) => _selectors[key] ?? _defaultSelectors[key]!;

  // ============ Series List Parsing ============

  /// Parse homepage "Update Terbaru" section
  /// Input: HTML string from homepage
  /// Output: List of series with basic info
  List<CrotpediaSeries> parseLatestSeries(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    // Get items using configured selector
    final items = document.querySelectorAll(_getSelector('latest_item'));

    return items.map((item) {
      // Series URL from link
      final link = item.querySelector(_getSelector('latest_link'));
      // Cover image
      final img = item.querySelector(_getSelector('latest_thumb'));
      // Title
      final title =
          item.querySelector(_getSelector('latest_title'))?.text ?? '';

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
    // Get items using configured selector
    final items = document.querySelectorAll(_getSelector('search_item'));

    return items.map((item) {
      // Series URL from link
      final link = item.querySelector(_getSelector('search_link'));
      // Cover image
      final img = item.querySelector(_getSelector('search_thumb'));
      // Title
      final titleElement = item.querySelector(_getSelector('search_title'));
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
    final items = document.querySelectorAll(_getSelector('doujin_item'));

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

    // Current page from pagination
    final currentEl =
        document.querySelector(_getSelector('pagination_current'));
    final currentPage = int.tryParse(currentEl?.text.trim() ?? '1') ?? 1;

    // Check for "Next" and "Previous" links
    final nextEl = document.querySelector(_getSelector('pagination_next'));
    final hasNext = nextEl != null;

    final prevEl = document.querySelector(_getSelector('pagination_prev'));
    final hasPrevious = prevEl != null;

    // Extract total pages from the last numbered page link
    // Get all numbered page links (excluding current, dots, and next/prev)
    final pageLinks =
        document.querySelectorAll(_getSelector('pagination_links'));

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
    // Get chapter list items using configured selector
    final items = document.querySelectorAll(_getSelector('chapter_list'));

    return items.map((item) {
      // Chapter link
      final link = item.querySelector(_getSelector('chapter_link'));
      // Chapter date
      final date = item.querySelector(_getSelector('chapter_date'))?.text;
      // Chapter title
      final titleSpan = item.querySelector(_getSelector('chapter_title'));
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

    // Get reader container using configured selector
    final container = document.querySelector(_getSelector('reader_container'));

    if (container == null) return [];

    // Images within container
    final images = container.querySelectorAll(_getSelector('reader_images'));

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
    return doc.querySelector(_getSelector('detail_title'))?.text.trim() ?? '';
  }

  String _parseCover(Document doc) {
    final img = doc.querySelector(_getSelector('detail_cover'));
    return img?.attributes['src'] ?? '';
  }

  String? _parseStatus(Document doc) {
    return doc.querySelector(_getSelector('detail_status'))?.text.trim();
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
    // Get genre links using configured selector
    final genreLinks = doc.querySelectorAll(_getSelector('detail_genres'));
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
    final items = doc.querySelectorAll(_getSelector('detail_infolist'));
    for (var item in items) {
      final bKey = item.querySelector('b')?.text.trim();
      if (bKey != null && bKey.contains(label)) {
        return item.querySelector('span')?.text.trim();
      }
    }
    return null;
  }

  String? _parseSynopsis(Document doc) {
    // Get synopsis using configured selector
    final synopsisElement = doc.querySelector(_getSelector('detail_synopsis'));
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
