import 'dart:convert';

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
    // home (latest updates) - using .utao structure from "Latest Update" section ONLY
    'home_container': '.utao',
    'home_link': 'a.series',
    'home_cover': 'img.ts-post-image',
    'home_title': '.luf > a > h4', // Direct child to avoid chapter text
    'home_chapter': '.eggchap',

    // search results
    'search_container': 'div.bsx',
    'search_link': 'a[href]',
    'search_cover': '.limit img',
    'search_title': '.tt',
    'search_type': '.type',

    // pagination (dual pattern)
    'pagination_container': '.pagination',
    'pagination_current': '.pagination .current',
    'pagination_next': '.pagination .next.page-numbers',
    'pagination_links': '.pagination a.page-numbers:not(.next):not(.prev)',
    // Alternative pagination (.hpage for home)
    'pagination_alt_container': '.hpage',
    'pagination_alt_next': '.hpage a.r',
    'pagination_alt_prev': '.hpage a.l',

    // series detail
    'detail_title': '.entry-title',
    'detail_cover': '.thumb img',
    'detail_status': '.infotable tr',
    'detail_type': '.infotable tr',
    'detail_infoList': '.infotable tr',
    'detail_genres': '.seriestugenre a',
    'detail_synopsis': '[itemprop="description"]',

    // detail (chapters)
    'detail_chapterList': '#chapterlist li',
    'detail_chapterLink': '.chbox .eph-num a',
    'detail_chapterDate': '.chbox .chapterdate',
    'detail_chapterTitle': '.chbox .chapternum',

    // reader
    'reader_container': '#readerarea',
    'reader_images': 'img',
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
      final title = titleEl?.text.trim() ?? '';

      return KomiktapSeriesMetadata(
        id: slug,
        title: title,
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
    var container =
        document.querySelector(_getSelector('pagination_container'));

    if (container != null) {
      return _parsePrimaryPagination(document);
    }

    // Fallback to alternative pattern
    container =
        document.querySelector(_getSelector('pagination_alt_container'));
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
    final currentEl =
        document.querySelector(_getSelector('pagination_current'));
    final currentPage = int.tryParse(currentEl?.text.trim() ?? '1') ?? 1;

    final nextEl = document.querySelector(_getSelector('pagination_next'));
    final hasNext = nextEl != null;

    final pageLinks =
        document.querySelectorAll(_getSelector('pagination_links'));

    int totalPages = currentPage;
    for (final link in pageLinks) {
      final pageNum = int.tryParse(link.text.trim());
      if (pageNum != null && pageNum > totalPages) {
        totalPages = pageNum;
      }
    }

    // If dots exist, we don't know exact total, but it's more than what we see
    // Set to a large number to allow navigation, rely on hasNext for actual navigation
    return KomiktapPagination(
      currentPage: currentPage,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrevious: currentPage > 1,
    );
  }

  /// Alternative pagination pattern (.hpage)
  KomiktapPagination _parseAlternativePagination(Document document) {
    final nextEl = document.querySelector(_getSelector('pagination_alt_next'));
    final prevEl = document.querySelector(_getSelector('pagination_alt_prev'));

    final hasNext = nextEl != null;
    final hasPrevious = prevEl != null;

    // Try to extract current page from URL if possible
    int currentPage = 1;

    // Check prev link for page number
    if (prevEl != null) {
      final href = prevEl.attributes['href'] ?? '';
      final match = RegExp(r'/page/(\d+)').firstMatch(href);
      if (match != null) {
        final prevPage = int.tryParse(match.group(1)!) ?? 0;
        currentPage = prevPage + 1;
      }
    }

    // If no prev, check next link
    if (currentPage == 1 && nextEl != null) {
      final href = nextEl.attributes['href'] ?? '';
      if (href.contains('/page/2')) {
        currentPage = 1; // We're on page 1
      }
    }

    return KomiktapPagination(
      currentPage: currentPage,
      totalPages: hasNext ? currentPage + 1 : currentPage, // Unknown total
      hasNext: hasNext,
      hasPrevious: hasPrevious,
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
    
    // Parse favorites
    final favorites = _parseFavorites(document);

    return KomiktapSeriesDetail(
      id: slug,
      title: title,
      coverImageUrl: coverUrl,
      synopsis: synopsis,
      status: status,
      type: contentType,
      tags: genres,
      author: (metadata['author'] ?? metadata['artist'] ?? metadata['posted_by']) as String?,
      lastUpdate: (metadata['updated_on'] ?? metadata['posted_on']) as DateTime?,
      chapters: chapters,
      favorites: favorites,
    );
  }

  // ... (keep existing methods)

  Map<String, dynamic> _parseMetadata(Document doc) {
    final metadata = <String, dynamic>{};

    // Parse all .infotable rows
    final infoRows = doc.querySelectorAll(_getSelector('detail_infoList'));

    for (final row in infoRows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;

      final label = cells[0].text.trim().toLowerCase();
      final value = cells[1].text.trim();

      if (label.contains('author')) {
        metadata['author'] = value;
      } else if (label.contains('artist')) {
        metadata['artist'] = value;
      } else if (label.contains('serialization')) {
        metadata['serialization'] = value;
      } else if (label.contains('posted by')) {
        metadata['posted_by'] = value;
      } else if (label.contains('updated on') || label.contains('posted on')) {
        // Extract date from time tag or text
        DateTime? date;
        final timeEl = cells[1].querySelector('time');
        if (timeEl != null) {
          final datetime = timeEl.attributes['datetime'];
          if (datetime != null) {
            date = DateTime.tryParse(datetime);
          }
        }
        
        // Fallback to text parsing
        date ??= _parseDate(value);

        if (date != null) {
          if (label.contains('updated')) {
            metadata['updated_on'] = date;
          } else {
            metadata['posted_on'] = date;
          }
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
      final relativePattern = RegExp(r'(\d+)\s+(hour|day|week|month)s?\s+ago',
          caseSensitive: false);
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
        url: url, // Preserve original URL from HTML
        publishDate: _parseDate(dateEl?.text.trim()),
      );
    }).toList();
  }

  // ============ Chapter/Reader Parsing ============

  /// Parse chapter page to extract image URLs
  List<String> parseChapterImages(String htmlContent) {
    try {
      // Try to extract from ts_reader.run() JavaScript
      final tsReaderRegex = RegExp(
        r'ts_reader\.run\((.*?)\);',
        dotAll: true,
      );

      final match = tsReaderRegex.firstMatch(htmlContent);

      if (match != null) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          // Clean escaped characters
          final cleanJson =
              jsonStr.replaceAll(r'\/', '/').replaceAll(r'\"', '"');

          try {
            final data = json.decode(cleanJson) as Map<String, dynamic>;
            final sources = data['sources'] as List<dynamic>?;

            if (sources != null && sources.isNotEmpty) {
              final firstSource = sources[0] as Map<String, dynamic>;
              final images = firstSource['images'] as List<dynamic>?;

              if (images != null) {
                final imageUrls = images
                    .map((img) => img.toString())
                    .where((url) => url.isNotEmpty)
                    .toList();

                return imageUrls;
              }
            }
          } catch (e) {
            // JSON parsing failed, fallback to DOM parsing
          }
        }
      }
    } catch (e) {
      // Regex extraction failed, fallback to DOM parsing
    }

    // Fallback: Try DOM parsing
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

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (pathSegments.isNotEmpty) {
        // If it's a manga URL: /manga/slug/
        final mangaIndex = pathSegments.indexOf('manga');
        if (mangaIndex != -1 && mangaIndex + 1 < pathSegments.length) {
          return pathSegments[mangaIndex + 1];
        }

        // Otherwise assume it's a chapter URL or other resource where the ID is the last segment
        // e.g. /slug-chapter-1/ or /slug-chaper-1/ (typo)
        return pathSegments.last;
      }
    } catch (_) {
      // Ignore parsing errors and fall through to regex fallback
    }

    // Fallback: Legacy regex matching
    final mangaRegex = RegExp(r'/manga/([^/]+)');
    // Match any segment that looks like a chapter slug (ends with digit)
    // or simply the last segment if we can't be precise
    final chapterRegex = RegExp(r'/([^/]+?-chapter-[\d.-]+)');

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

  double? _extractChapterNumber(String? text) {
    if (text == null || text.isEmpty) return null;

    // Try patterns: "Chapter 123", "chapter-123", "Ch. 123", "Chapter 67.5", "Chapter 67-5"
    final patterns = [
      RegExp(r'chapter[- ]([\d.-]+)', caseSensitive: false),
      RegExp(r'ch\.?\s*([\d.-]+)', caseSensitive: false),
      RegExp(r'#([\d.-]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String numStr = match.group(1)!;
        // Fix common OCR/formatting issues or hyphenated decimals
        if (numStr.contains('-')) {
             // Only replace hyphen if it likely acts as a decimal separator (not a range)
             // For single chapter context, we assume it's substitution
             numStr = numStr.replaceAll('-', '.');
        }
        return double.tryParse(numStr);
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
    try {
      final rows = doc.querySelectorAll(_getSelector('detail_status'));

      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length < 2) continue;

        if (cells[0].text.contains('Status')) {
          return cells[1].text.trim();
        }
      }

      // Fallback: Check for specific status keywords if structure is unknown
      final allText = doc.body?.text ?? '';
      if (allText.contains('Ongoing')) return 'Ongoing';
      if (allText.contains('Completed')) return 'Completed';
    } catch (_) {}
    return null;
  }

  String? _parseType(Document doc) {
    try {
      final rows = doc.querySelectorAll(_getSelector('detail_type'));

      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length < 2) continue;

        if (cells[0].text.contains('Type')) {
          return cells[1].text.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  List<String> _parseGenres(Document doc) {
    final genreLinks = doc.querySelectorAll(_getSelector('detail_genres'));
    return genreLinks
        .map((link) => link.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  int? _parseFavorites(Document doc) {
    try {
      // <div class="bmc">Followed by 21 people</div>
      final bmcEl = doc.querySelector('.bmc');
      if (bmcEl != null) {
        final text = bmcEl.text.trim();
        // Extract number from "Followed by 21 people"
        final match = RegExp(r'(\d+)').firstMatch(text);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
      }
    } catch (_) {}
    return null;
  }
}
