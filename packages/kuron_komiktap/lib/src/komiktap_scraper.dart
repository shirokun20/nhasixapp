import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'models/komiktap_models.dart';

/// HTML parsing logic for KomikTap website.
///
/// Parses HTML content into simple data models defined in komiktap_models.
/// The KomiktapSource converts these models to Content entities.
class KomiktapScraper {
  // Default CSS selectors (matching remote JSON structure)
  static const Map<String, String> _defaultSelectors = {
    // home (latest updates)
    'home_container': 'div.bsx',
    'home_link': 'a[href]',
    'home_cover': '.limit img',
    'home_title': '.tt',
    'home_chapter': '.epxs',

    // search results
    'search_container': 'div.bsx',
    'search_link': 'a[href]',
    'search_cover': '.limit img',
    'search_title': '.tt',
    'search_type': '.type',

    // pagination (dual pattern)
    'pagination_container': '.pagination',
    'pagination_current': '.pagination .current',
    'pagination_next': '.pagination .r',
    'pagination_links': '.pagination a:not(.r):not(.l)',
    // Alternative pagination
    'pagination_alt_container': '.hpage',
    'pagination_alt_current': '.hpage .r',
    'pagination_alt_next': '.hpage a:last-child',

    // series detail
    'detail_title': '.entry-title',
    'detail_cover': '.thumb img',
    'detail_status': '.imptdt:contains("Status") i',
    'detail_type': '.imptdt:contains("Type") a',
    'detail_infoList': '.fmed',
    'detail_genres': '.mgen a',
    'detail_synopsis': '[itemprop="description"]',
    
    // detail (chapters)
    'detail_chapterList': '#chapterlist li',
    'detail_chapterLink': '.chbox .eph-num a',
    'detail_chapterDate': '.chbox .chapterdate',
    'detail_chapterTitle': '.chbox .chapternum',

    // reader
    'reader_container': '#readerarea',
    'reader_images': '#readerarea img',
  };

  final Map<String, String> _selectors;

  /// Create scraper with optional custom selectors
  KomiktapScraper({Map<String, dynamic>? customSelectors})
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

  /// Parse homepage latest updates
  List<KomiktapSeriesMetadata> parseLatestSeries(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final items = document.querySelectorAll(_getSelector('home_container'));

    return items.map((item) {
      final link = item.querySelector(_getSelector('home_link'));
      final img = item.querySelector(_getSelector('home_cover'));
      final titleEl = item.querySelector(_getSelector('home_title'));
      final chapterEl = item.querySelector(_getSelector('home_chapter'));

      final url = link?.attributes['href'] ?? '';
      final slug = _extractSlugFromUrl(url);

      return KomiktapSeriesMetadata(
        id: slug,
        title: titleEl?.text.trim() ?? '',
        coverImageUrl: img?.attributes['src'] ?? '',
        subtitle: chapterEl?.text.trim(), // Latest chapter
      );
    }).toList();
  }

  /// Parse search results page
  List<KomiktapSeriesMetadata> parseSearchResults(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final items = document.querySelectorAll(_getSelector('search_container'));

    return items.map((item) {
      final link = item.querySelector(_getSelector('search_link'));
      final img = item.querySelector(_getSelector('search_cover'));
      final titleEl = item.querySelector(_getSelector('search_title'));
      final typeEl = item.querySelector(_getSelector('search_type'));

      final url = link?.attributes['href'] ?? '';
      final slug = _extractSlugFromUrl(url);
      final typeText = typeEl?.text.trim() ?? '';

      return KomiktapSeriesMetadata(
        id: slug,
        title: titleEl?.text.trim() ?? '',
        coverImageUrl: img?.attributes['src'] ?? '',
        subtitle: typeText, // Content type
        tags: typeText.isNotEmpty ? [typeText] : [],
      );
    }).toList();
  }

  /// Parse pagination info (supports dual pattern)
  KomiktapPagination parsePagination(String htmlContent) {
    final document = html_parser.parse(htmlContent);

    // Try primary pagination pattern first
    var container = document.querySelector(_getSelector('pagination_container'));
    
    if (container != null) {
      return _parsePrimaryPagination(document);
    }

    // Fallback to alternative pattern
    container = document.querySelector(_getSelector('pagination_alt_container'));
    if (container != null) {
      return _parseAlternativePagination(document);
    }

    // No pagination found
    return const KomiktapPagination(
      currentPage: 1,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    );
  }

  /// Primary pagination pattern (.pagination)
  KomiktapPagination _parsePrimaryPagination(Document document) {
    final currentEl = document.querySelector(_getSelector('pagination_current'));
    final currentPage = int.tryParse(currentEl?.text.trim() ?? '1') ?? 1;

    final nextEl = document.querySelector(_getSelector('pagination_next'));
    final hasNext = nextEl != null;

    final pageLinks = document.querySelectorAll(_getSelector('pagination_links'));
    
    int totalPages = currentPage;
    for (final link in pageLinks) {
      final pageNum = int.tryParse(link.text.trim());
      if (pageNum != null && pageNum > totalPages) {
        totalPages = pageNum;
      }
    }

    return KomiktapPagination(
      currentPage: currentPage,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrevious: currentPage > 1,
    );
  }

  /// Alternative pagination pattern (.hpage)
  KomiktapPagination _parseAlternativePagination(Document document) {
    final currentEl = document.querySelector(_getSelector('pagination_alt_current'));
    final currentText = currentEl?.text.trim() ?? '1';
    
    // Extract "Page X of Y" format
    final match = RegExp(r'Page (\d+) of (\d+)').firstMatch(currentText);
    
    if (match != null) {
      final current = int.tryParse(match.group(1)!) ?? 1;
      final total = int.tryParse(match.group(2)!) ?? 1;
      
      return KomiktapPagination(
        currentPage: current,
        totalPages: total,
        hasNext: current < total,
        hasPrevious: current > 1,
      );
    }

    return const KomiktapPagination(
      currentPage: 1,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    );
  }

  // ============ Series Detail Parsing ============

  /// Parse series detail page
  KomiktapSeriesDetail parseSeriesDetail(String htmlContent, String slug) {
    final document = html_parser.parse(htmlContent);

    // Parse basic info
    final title = _parseTitle(document);
    final coverUrl = _parseCover(document);
    final synopsis = _parseSynopsis(document);
    final status = _parseStatus(document);
    final contentType = _parseType(document);
    final genres = _parseGenres(document);
    final metadata = _parseMetadata(document);

    // Parse chapters
    final chapters = _parseChapterList(document);

    return KomiktapSeriesDetail(
      id: slug,
      title: title,
      coverImageUrl: coverUrl,
      synopsis: synopsis,
      status: status,
      type: contentType,
      tags: genres,
      author: metadata['author'] as String?,
      chapters: chapters,
    );
  }

  List<KomiktapChapterInfo> _parseChapterList(Document document) {
    final items = document.querySelectorAll(_getSelector('detail_chapterList'));

    return items.map((item) {
      final link = item.querySelector(_getSelector('detail_chapterLink'));
      final dateEl = item.querySelector(_getSelector('detail_chapterDate'));
      final titleEl = item.querySelector(_getSelector('detail_chapterTitle'));

      final url = link?.attributes['href'] ?? '';
      final chapterSlug = _extractSlugFromUrl(url);
      
      // Extract chapter number from URL or title
      final chapterNum = _extractChapterNumber(url) ?? 
                        _extractChapterNumber(titleEl?.text ?? '');

      return KomiktapChapterInfo(
        id: chapterSlug,
        title: titleEl?.text.trim() ?? 'Chapter $chapterNum',
        publishDate: _parseDate(dateEl?.text.trim()),
      );
    }).toList();
  }

  // ============ Chapter/Reader Parsing ============

  /// Parse chapter page to extract image URLs
  List<String> parseChapterImages(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final container = document.querySelector(_getSelector('reader_container'));

    if (container == null) return [];

    final images = container.querySelectorAll(_getSelector('reader_images'));

    return images
        .map((img) => img.attributes['src'] ?? '')
        .where((src) => src.isNotEmpty)
        .toList();
  }

  // ============ Helper Methods ============

  String _extractSlugFromUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Match /manga/{slug}/ or /{slug}-chapter-{num}/
    final mangaRegex = RegExp(r'/manga/([^/]+)');
    final chapterRegex = RegExp(r'/([^/]+)-chapter-\d+');
    
    var match = mangaRegex.firstMatch(url);
    if (match != null) {
      return match.group(1) ?? '';
    }
    
    match = chapterRegex.firstMatch(url);
    if (match != null) {
      return match.group(1) ?? '';
    }
    
    return '';
  }

  int? _extractChapterNumber(String? text) {
    if (text == null || text.isEmpty) return null;
    
    // Try patterns: "Chapter 123", "chapter-123", "Ch. 123"
    final patterns = [
      RegExp(r'chapter[- ](\d+)', caseSensitive: false),
      RegExp(r'ch\.?\s*(\d+)', caseSensitive: false),
      RegExp(r'#(\d+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    
    return null;
  }

  String _parseTitle(Document doc) {
    return doc.querySelector(_getSelector('detail_title'))?.text.trim() ?? '';
  }

  String _parseCover(Document doc) {
    final img = doc.querySelector(_getSelector('detail_cover'));
    return img?.attributes['src'] ?? '';
  }

  String? _parseSynopsis(Document doc) {
    final el = doc.querySelector(_getSelector('detail_synopsis'));
    return el?.text.trim();
  }

  String? _parseStatus(Document doc) {
    // Find "Status" row in .imptdt
    final statusEl = doc.querySelector(_getSelector('detail_status'));
    return statusEl?.text.trim();
  }

  String? _parseType(Document doc) {
    final typeEl = doc.querySelector(_getSelector('detail_type'));
    return typeEl?.text.trim();
  }

  List<String> _parseGenres(Document doc) {
    final genreLinks = doc.querySelectorAll(_getSelector('detail_genres'));
    return genreLinks
        .map((link) => link.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _parseMetadata(Document doc) {
    final metadata = <String, dynamic>{};
    
    // Parse all .fmed rows (Author, Artist, etc.)
    final infoRows = doc.querySelectorAll(_getSelector('detail_infoList'));
    
    for (final row in infoRows) {
      final label = row.querySelector('b')?.text.trim().toLowerCase();
      final value = row.querySelector('span')?.text.trim();
      
      if (label != null && value != null) {
        if (label.contains('author')) {
          metadata['author'] = value;
        } else if (label.contains('artist')) {
          metadata['artist'] = value;
        } else if (label.contains('serialization')) {
          metadata['serialization'] = value;
        } else if (label.contains('posted')) {
          metadata['posted_by'] = value;
        }
      }
    }
    
    return metadata;
  }

  DateTime? _parseDate(String? dateText) {
    if (dateText == null || dateText.isEmpty) return null;
    
    try {
      // Try direct ISO parse first
      final parsed = DateTime.tryParse(dateText);
      if (parsed != null) return parsed;
      
      // Handle relative dates like "2 hours ago", "3 days ago"
      final relativePattern = RegExp(r'(\d+)\s+(hour|day|week|month)s?\s+ago', caseSensitive: false);
      final match = relativePattern.firstMatch(dateText);
      
      if (match != null) {
        final amount = int.tryParse(match.group(1)!) ?? 0;
        final unit = match.group(2)!.toLowerCase();
        
        final now = DateTime.now();
        switch (unit) {
          case 'hour':
            return now.subtract(Duration(hours: amount));
          case 'day':
            return now.subtract(Duration(days: amount));
          case 'week':
            return now.subtract(Duration(days: amount * 7));
          case 'month':
            return DateTime(now.year, now.month - amount, now.day);
        }
      }
      
      return null;
    } catch (_) {
      return null;
    }
  }
}
