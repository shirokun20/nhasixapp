import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:kuron_core/kuron_core.dart';
import 'models/crotpedia_series.dart';
import 'models/crotpedia_genre.dart';

/// HTML parsing logic for Crotpedia website.
class CrotpediaScraper {
  // Default CSS selectors (matching remote JSON structure)
  static const Map<String, String> _defaultSelectors = {
    // latest
    'latest_container': '.flexbox4-item',
    'latest_link': 'a',
    'latest_cover': '.flexbox4-thumb img',
    'latest_title': '.flexbox4-side .title a',

    // search
    'search_container': '.flexbox2-item',
    'search_link': 'a',
    'search_cover': '.flexbox2-thumb img',
    'search_title': '.flexbox2-title span',

    // doujinList
    'doujinList_container': '.mangalist-blc',
    'doujinList_link': 'a.series',

    // genreList
    'genreList_container': 'ul.achlist',
    'genreList_item': 'li',
    'genreList_link': 'a',
    'genreList_count': 'span',

    // requestList
    'requestList_container': '.flexbox2',
    'requestList_item': '.flexbox2-item',
    'requestList_link': 'a',
    'requestList_cover': 'img',
    'requestList_title': '.flexbox2-title span',
    'requestList_status': '.flexbox2-footer',

    // pagination
    'pagination_current': '.pagination .page-numbers.current',
    'pagination_next': '.pagination .next.page-numbers',
    'pagination_prev': '.pagination .prev.page-numbers',
    'pagination_links': '.pagination a.page-numbers:not(.next):not(.prev)',

    // detail
    'detail_title': '.series-titlex h2',
    'detail_cover': '.series-thumb img',
    'detail_status': '.series-infoz .status',
    'detail_favorites': '.series-infoz.score span', // NEW
    'detail_infoList': '.series-infolist li', // used for alt title, author etc
    'detail_genres': '.series-genres a',
    'detail_synopsis': '.series-synops p',
    // detail (chapters)
    'detail_chapterList': '.series-chapterlist li',
    'detail_chapterLink': '.flexch-infoz a',
    'detail_chapterDate': '.flexch-infoz .date',
    'detail_chapterTitle': '.flexch-infoz a span',

    // reader
    'reader_container': '.reader-area',
    'reader_images': 'p img',
    'reader_next':
        '.nextprev a.next, .nav-links a.next, a.next_page, .navigation .rightnav a',
    'reader_prev':
        '.nextprev a.prev, .nav-links a.prev, a.prev_page, .navigation .leftnav a',
  };

  final Map<String, String> _selectors;

  /// Create scraper with optional custom selectors
  /// [customSelectors] can be a nested Map matching the JSON config structure
  CrotpediaScraper({Map<String, dynamic>? customSelectors})
      : _selectors = {
          ..._defaultSelectors,
          ...?_flattenSelectors(customSelectors),
        };

  /// Helper to flatten nested JSON selector map into Key_Value format
  static Map<String, String>? _flattenSelectors(Map<String, dynamic>? json) {
    if (json == null) return null;
    final result = <String, String>{};

    void flatten(String prefix, Map<String, dynamic> map) {
      map.forEach((key, value) {
        final newKey = prefix.isEmpty ? key : '${prefix}_$key';
        if (value is Map) {
          flatten(newKey, Map<String, dynamic>.from(value));
        } else if (value is String) {
          result[newKey] = value;
        }
      });
    }

    flatten('', json);
    return result;
  }

  /// Get selector by key, fallback to default if not found
  String _getSelector(String key) => _selectors[key] ?? _defaultSelectors[key]!;

  // ============ Series List Parsing ============

  /// Parse homepage "Update Terbaru" section
  /// Input: HTML string from homepage
  /// Output: List of series with basic info
  List<CrotpediaSeries> parseLatestSeries(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    // Get items using configured selector
    final items = document.querySelectorAll(_getSelector('latest_container'));

    return items.map((item) {
      // Series URL from link
      final link = item.querySelector(_getSelector('latest_link'));
      // Cover image
      final img = item.querySelector(_getSelector('latest_cover'));
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
    final items = document.querySelectorAll(_getSelector('search_container'));

    return items.map((item) {
      // Series URL from link
      final link = item.querySelector(_getSelector('search_link'));
      // Cover image
      final img = item.querySelector(_getSelector('search_cover'));
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

    // Get ALL alphabet section containers (-, #, A, B, C, etc.)
    final containers = document.querySelectorAll('.mangalist-blc');
    final allItems = <CrotpediaSeries>[];

    // Iterate through each alphabet section
    for (final container in containers) {
      // Get all series links in this section
      final items = container.querySelectorAll('a.series');

      for (final item in items) {
        allItems.add(CrotpediaSeries(
          slug: _extractSlug(item.attributes['href']),
          title: item.text.trim(),
          coverUrl: '', // No cover in list view
          url: item.attributes['href'],
          id: item.attributes['rel'], // Extract ID from rel attribute
          // Optional: add section header for grouping
        ));
      }
    }

    return allItems;
  }

  /// Parse genre list page
  List<CrotpediaGenre> parseGenreList(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    final container =
        document.querySelector(_getSelector('genreList_container'));
    if (container == null) return [];

    final items = container.querySelectorAll(_getSelector('genreList_item'));
    final results = <CrotpediaGenre>[];

    for (final item in items) {
      final link = item.querySelector(_getSelector('genreList_link'));
      if (link == null) continue;

      final url = link.attributes['href'] ?? '';

      // Extract count and clean name
      final countEl = item.querySelector(_getSelector('genreList_count'));
      final countText = countEl?.text ?? '0';
      final count = int.tryParse(countText) ?? 0;

      String name = link.text;
      if (countEl != null) {
        name = name.replaceAll(countEl.text, '').trim();
      }

      // Slug
      final uri = Uri.parse(url);
      final slug = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.where((s) => s.isNotEmpty).last
          : name.toLowerCase().replaceAll(' ', '-');

      results.add(CrotpediaGenre(
        name: name,
        slug: slug,
        url: url,
        count: count,
      ));
    }
    return results;
  }

  /// Parse request list page
  List<CrotpediaSeries> parseRequestList(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final container =
        document.querySelector(_getSelector('requestList_container'));

    if (container == null) return [];

    final items = container.querySelectorAll(_getSelector('requestList_item'));

    return items.map((item) {
      final link = item.querySelector(_getSelector('requestList_link'));
      final img = item.querySelector(_getSelector('requestList_cover'));
      final titleEl = item.querySelector(_getSelector('requestList_title'));
      final statusEl = item.querySelector(_getSelector('requestList_status'));

      final title = titleEl?.text.trim() ?? 'Unknown';
      final url = link?.attributes['href'] ?? '';

      // Parse genres from the .genres div
      final genresContainer = item.querySelector('.flexbox2-side .genres span');
      final genres = <String, String>{};
      if (genresContainer != null) {
        final genreLinks = genresContainer.querySelectorAll('a');
        for (final genreLink in genreLinks) {
          final genreName = genreLink.text.trim();
          final genreUrl = genreLink.attributes['href'] ?? '';
          if (genreName.isNotEmpty && genreUrl.isNotEmpty) {
            // Extract slug from URL (e.g., /baca/genre/ahegao/ -> ahegao)
            final slug = _extractSlug(genreUrl);
            genres[slug] = genreName;
          }
        }
      }

      // Generate ID or extract if possible (hashcode as fallback)
      final id = title.hashCode.toString();

      return CrotpediaSeries(
        slug: _extractSlug(url),
        title: title,
        coverUrl: img?.attributes['src'] ?? '',
        url: url,
        status: statusEl?.text.trim(),
        id: id,
        genres: genres,
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
      favorites: _parseFavorites(document),
      alternativeTitle: _parseAlternativeTitle(document),
      chapters: _parseChapterList(document),
    );
  }

  List<CrotpediaChapter> _parseChapterList(Document document) {
    // Get chapter list items using configured selector
    final items = document.querySelectorAll(_getSelector('detail_chapterList'));

    return items.map((item) {
      // Chapter link
      final link = item.querySelector(_getSelector('detail_chapterLink'));
      // Chapter date
      final date = item.querySelector(_getSelector('detail_chapterDate'))?.text;
      // Chapter title
      final titleSpan = item.querySelector(_getSelector('detail_chapterTitle'));
      final title = titleSpan?.text ?? '';

      return CrotpediaChapter(
        slug: _extractSlug(link?.attributes['href']),
        title: title.trim(),
        publishedDate: _parseDate(date),
        seriesSlug: '', // Will be filled by caller
        url: link?.attributes['href'],
      );
    }).toList();
  }

  // ============ Chapter/Reader Parsing ============

  /// Parse chapter page to extract image URLs
  /// Input: HTML from /baca/{chapterSlug}/
  /// Output: List of image URLs in order
  /// Parse chapter page to extract image URLs and navigation
  /// Input: HTML from /baca/{chapterSlug}/
  /// Output: ChapterData with images and next/prev links
  ChapterData parseChapterImages(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    // Get reader container using configured selector
    final container = document.querySelector(_getSelector('reader_container'));

    // Images
    final List<String> images;
    if (container != null) {
      final imgElements =
          container.querySelectorAll(_getSelector('reader_images'));
      images = imgElements
          .map((img) => img.attributes['src'] ?? '')
          .where((src) => src.isNotEmpty)
          .toList();
    } else {
      images = [];
    }

    // Navigation
    String? nextId;
    String? prevId;
    String? nextTitle;
    String? prevTitle;

    // Try to find next/prev links
    // Note: Selectors might return multiple buttons (top and bottom), just take first valid
    final nextEl = document.querySelector(_getSelector('reader_next'));
    if (nextEl != null) {
      final href = nextEl.attributes['href'];
      nextId = _extractSlug(href);
      nextTitle = nextEl.text.trim(); // Often just "Next"
    }

    final prevEl = document.querySelector(_getSelector('reader_prev'));
    if (prevEl != null) {
      final href = prevEl.attributes['href'];
      prevId = _extractSlug(href);
      prevTitle = prevEl.text.trim(); // Often just "Prev"
    }

    return ChapterData(
      images: images,
      nextChapterId: nextId != null && nextId.isNotEmpty ? nextId : null,
      prevChapterId: prevId != null && prevId.isNotEmpty ? prevId : null,
      nextChapterTitle: nextTitle,
      prevChapterTitle: prevTitle,
    );
  }

  // ============ Helper Methods ============

  String _extractSlug(String? url) {
    if (url == null || url.isEmpty || url.startsWith('#')) return '';

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (pathSegments.isNotEmpty) {
        // If it's a series URL: /baca/series/slug/
        final seriesIndex = pathSegments.indexOf('series');
        if (seriesIndex != -1 && seriesIndex + 1 < pathSegments.length) {
          return _finalizeSlug(pathSegments[seriesIndex + 1]);
        }

        // Check for /baca/genre/slug/ pattern
        final genreIndex = pathSegments.indexOf('genre');
        if (genreIndex != -1 && genreIndex + 1 < pathSegments.length) {
          return _finalizeSlug(pathSegments[genreIndex + 1]);
        }

        // Also check for /baca/slug/ (older/alternate structure)
        final bacaIndex = pathSegments.indexOf('baca');
        if (bacaIndex != -1 &&
            bacaIndex + 1 < pathSegments.length &&
            pathSegments[bacaIndex + 1] != 'series' &&
            pathSegments[bacaIndex + 1] != 'genre') {
          return _finalizeSlug(pathSegments[bacaIndex + 1]);
        }

        // Otherwise assume it's a chapter URL or other resource where the ID is the last segment
        return _finalizeSlug(pathSegments.last);
      }
    } catch (_) {
      // Ignore parsing errors and fall through to regex fallback
    }

    // Fallback: Legacy regex matching
    final regex = RegExp(r'/baca/(?:series/)?([^/]+)/?$');
    final slug = regex.firstMatch(url)?.group(1) ?? '';

    return _finalizeSlug(slug);
  }

  String _finalizeSlug(String slug) {
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
    final items = doc.querySelectorAll(_getSelector('detail_infoList'));
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

  int? _parseFavorites(Document doc) {
    final scoreEl = doc.querySelector(_getSelector('detail_favorites'));
    if (scoreEl != null) {
      return int.tryParse(scoreEl.text.trim());
    }
    return null;
  }

  String? _parseAlternativeTitle(Document doc) {
    return _parseInfoFromList(doc, 'Alternative');
  }

  /// Detects if the page requires login/authentication
  ///
  /// Checks for multiple indicators:
  /// 1. Login form presence (#koi_login_form)
  /// 2. Canonical URL containing /login/
  /// 3. Title containing "Login"
  bool isLoginRequired(Document document) {
    // Check for login form
    final loginForm = document.querySelector('#koi_login_form');
    if (loginForm != null) return true;

    // Check canonical URL
    final canonical = document.querySelector('link[rel="canonical"]');
    if (canonical != null) {
      final href = canonical.attributes['href'] ?? '';
      if (href.contains('/login/')) return true;
    }

    // Check page title
    final title = document.querySelector('title');
    if (title != null && title.text.toLowerCase().contains('login')) {
      return true;
    }

    return false;
  }
}
