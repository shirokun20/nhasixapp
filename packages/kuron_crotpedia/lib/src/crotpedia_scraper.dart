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
  /// Output: Tuple of (currentPage, hasNext)
  ({int currentPage, bool hasNext}) parsePagination(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    // Current page from .pagination .page-numbers.current
    final currentEl =
        document.querySelector('.pagination .page-numbers.current');
    final currentPage = int.tryParse(currentEl?.text.trim() ?? '1') ?? 1;

    // Check for "Next" link
    // Real HTML uses a.next.page-numbers
    final nextEl = document.querySelector('.pagination .next.page-numbers');
    final hasNext = nextEl != null;

    return (currentPage: currentPage, hasNext: hasNext);
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
    return regex.firstMatch(url)?.group(1) ?? '';
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

  List<String> _parseGenres(Document doc) {
    // Real HTML: <div class="series-genres"><a ...>Genre</a></div>
    return doc
        .querySelectorAll('.series-genres a')
        .map((e) => e.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
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
