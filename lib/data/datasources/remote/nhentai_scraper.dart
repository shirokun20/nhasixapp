import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:logger/logger.dart';

import '../../models/content_model.dart';
import '../../models/tag_model.dart';
import '../../../domain/entities/tag.dart';

/// HTML scraper for nhentai.net with CSS selectors
class NhentaiScraper {
  NhentaiScraper({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  // CSS Selectors for content list
  static const String contentListSelector = 'div.gallery';
  static const String contentLinkSelector = 'a';
  static const String contentCoverSelector = '.cover img';
  static const String contentTitleSelector = '.caption';

  // CSS Selectors for content detail
  static const String detailTitleSelector = '#info h1';
  static const String detailSubtitleSelector = '#info h2';
  static const String detailTagsSelector = '.tag-container .tag';
  static const String detailPagesSelector =
      '#thumbnail-container .thumb-container img';
  static const String detailInfoSelector = '#info';
  static const String detailCoverSelector = '#cover img';

  // CSS Selectors for tags page
  static const String tagItemSelector = '.tag';
  static const String tagNameSelector = '.name';
  static const String tagCountSelector = '.count';

  // URL patterns
  static const String contentUrlPattern = r'/g/(\d+)/';
  static const String imageUrlPattern =
      r'https://t\.nhentai\.net/galleries/(\d+)/(\d+)t\.(jpg|png|gif)';

  /// Parse content list from HTML
  List<ContentModel> parseContentList(String html) {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');
      final contentElements = document.querySelectorAll(contentListSelector);

      final contents = <ContentModel>[];


      for (final element in contentElements) {
        try {
          final content = _parseContentCard(element);
          if (content != null) {
            contents.add(content);
          }
        } catch (e) {
          _logger.w('Failed to parse content card: $e');
          continue;
        }
      }

      _logger.d('Parsed ${contents.length} content items from list');
      return contents;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse content list',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Parse content detail from HTML
  ContentModel parseContentDetail(String html, String contentId) {
    try {
      final document = html_parser.parse(html);

      // Extract title
      final titleElement = document.querySelector(detailTitleSelector);
      final subtitleElement = document.querySelector(detailSubtitleSelector);

      final title = (titleElement?.text)?.trim() ?? 'Unknown Title';
      final subtitle = (subtitleElement?.text)?.trim();

      // Extract cover URL
      final coverElement = document.querySelector(detailCoverSelector);
      final coverUrl = _extractImageUrl(coverElement?.attributes['data-src'] ??
          coverElement?.attributes['src'] ??
          '');

      // Extract tags
      final tags = _parseTagsFromDetail(document);

      // Extract metadata
      final metadata = _parseMetadata(document);

      // Extract image URLs
      final imageUrls = _parseImageUrls(document, contentId);

      // Determine language
      final language = _extractLanguage(tags);

      // Extract artists, characters, etc.
      final artists = _extractTagsByType(tags, 'artist');
      final characters = _extractTagsByType(tags, 'character');
      final parodies = _extractTagsByType(tags, 'parody');
      final groups = _extractTagsByType(tags, 'group');

      return ContentModel(
        id: contentId,
        title: title,
        englishTitle: _isEnglish(title) ? title : null,
        japaneseTitle: _isJapanese(title) ? title : subtitle,
        coverUrl: coverUrl,
        tags: tags,
        artists: artists,
        characters: characters,
        parodies: parodies,
        groups: groups,
        language: language,
        pageCount: imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: _parseUploadDate(metadata),
        favorites: _parseFavorites(metadata),
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to parse content detail for ID: $contentId',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Parse search results from HTML
  List<ContentModel> parseSearchResults(String html) {
    // Search results use the same structure as content list
    return parseContentList(html);
  }

  /// Parse tags page from HTML
  List<TagModel> parseTagsPage(String html, {String? type}) {
    try {
      final document = html_parser.parse(html);
      final tagElements = document.querySelectorAll(tagItemSelector);

      final tags = <TagModel>[];

      for (final element in tagElements) {
        try {
          final tag = _parseTagElement(element, type);
          if (tag != null) {
            tags.add(tag);
          }
        } catch (e) {
          _logger.w('Failed to parse tag element: $e');
          continue;
        }
      }

      _logger.d('Parsed ${tags.length} tags from page');
      return tags;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse tags page', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Extract content ID from page (for random content)
  String? extractContentIdFromPage(String html) {
    try {
      final document = html_parser.parse(html);

      // Try to extract from URL in canonical link
      final canonicalElement = document.querySelector('link[rel="canonical"]');
      if (canonicalElement != null) {
        final href = canonicalElement.attributes['href'];
        if (href != null) {
          final match = RegExp(contentUrlPattern).firstMatch(href);
          if (match != null) {
            return match.group(1);
          }
        }
      }

      // Try to extract from current URL in JavaScript
      final scriptElements = document.querySelectorAll('script');
      for (final script in scriptElements) {
        final content = script.text;
        if (content.contains('gallery_id')) {
          final match =
              RegExp(r'gallery_id["\s]*:["\s]*(\d+)').firstMatch(content);
          if (match != null) {
            return match.group(1);
          }
        }
      }

      return null;
    } catch (e) {
      _logger.w('Failed to extract content ID from page: $e');
      return null;
    }
  }

  /// Parse individual content card
  ContentModel? _parseContentCard(html_dom.Element element) {
    try {
      // Extract content ID from link
      final linkElement = element.querySelector(contentLinkSelector);
      final href = linkElement?.attributes['href'];
      if (href == null) return null;

      final match = RegExp(contentUrlPattern).firstMatch(href);
      if (match == null) return null;

      final contentId = match.group(1)!;

      // Extract title
      final titleElement = element.querySelector(contentTitleSelector);
      final title = (titleElement?.text)?.trim() ?? 'Unknown Title';

      // Extract cover URL
      final coverElement = element.querySelector(contentCoverSelector);
      final coverUrl = _extractImageUrl(coverElement?.attributes['data-src'] ??
          coverElement?.attributes['src'] ??
          '');

      // Create minimal content model (will be enriched when detail is fetched)
      return ContentModel(
        id: contentId,
        title: title,
        coverUrl: coverUrl,
        tags: const [], // Will be populated from detail
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'unknown',
        pageCount: 0, // Will be populated from detail
        imageUrls: const [],
        uploadDate: DateTime.now(), // Will be populated from detail
        favorites: 0,
      );
    } catch (e) {
      _logger.w('Failed to parse content card: $e');
      return null;
    }
  }

  /// Parse tags from detail page
  List<Tag> _parseTagsFromDetail(html_dom.Document document) {
    final tags = <Tag>[];

    try {
      final tagElements = document.querySelectorAll(detailTagsSelector);

      for (final element in tagElements) {
        final tag = _parseTagFromElement(element);
        if (tag != null) {
          tags.add(tag);
        }
      }
    } catch (e) {
      _logger.w('Failed to parse tags from detail: $e');
    }

    return tags;
  }

  /// Parse tag from element
  Tag? _parseTagFromElement(html_dom.Element element) {
    try {
      final nameElement = element.querySelector('.name');
      final countElement = element.querySelector('.count');

      final name = (nameElement?.text)?.trim();
      final countText = (countElement?.text)?.trim();
      final href = element.attributes['href'];

      if (name == null || href == null) return null;

      // Parse count
      int count = 0;
      if (countText != null) {
        final countMatch = RegExp(r'(\d+)').firstMatch(countText);
        if (countMatch != null) {
          count = int.tryParse(countMatch.group(1)!) ?? 0;
        }
      }

      // Determine tag type from URL
      String type = 'tag';
      if (href.contains('/artist/')) {
        type = 'artist';
      } else if (href.contains('/character/')) {
        type = 'character';
      } else if (href.contains('/parody/')) {
        type = 'parody';
      } else if (href.contains('/group/')) {
        type = 'group';
      } else if (href.contains('/language/')) {
        type = 'language';
      } else if (href.contains('/category/')) {
        type = 'category';
      }

      return Tag(
        name: name,
        type: type,
        count: count,
        url: href,
      );
    } catch (e) {
      _logger.w('Failed to parse tag from element: $e');
      return null;
    }
  }

  /// Parse tag element from tags page
  TagModel? _parseTagElement(html_dom.Element element, String? type) {
    try {
      final nameElement = element.querySelector(tagNameSelector);
      final countElement = element.querySelector(tagCountSelector);

      final name = (nameElement?.text)?.trim();
      final countText = (countElement?.text)?.trim();
      final href = element.attributes['href'];

      if (name == null || href == null) return null;

      // Parse count
      int count = 0;
      if (countText != null) {
        final countMatch = RegExp(r'(\d+)').firstMatch(countText);
        if (countMatch != null) {
          count = int.tryParse(countMatch.group(1)!) ?? 0;
        }
      }

      return TagModel(
        name: name,
        type: type ?? 'tag',
        count: count,
        url: href,
      );
    } catch (e) {
      _logger.w('Failed to parse tag element: $e');
      return null;
    }
  }

  /// Parse metadata from detail page
  Map<String, String> _parseMetadata(html_dom.Document document) {
    final metadata = <String, String>{};

    try {
      final infoElement = document.querySelector(detailInfoSelector);
      if (infoElement != null) {
        // Extract various metadata fields
        final text = infoElement.text;

        // Extract favorites count
        final favoritesMatch = RegExp(r'Favorites:\s*(\d+)').firstMatch(text);
        if (favoritesMatch != null) {
          metadata['favorites'] = favoritesMatch.group(1)!;
        }

        // Extract upload date
        final uploadMatch =
            RegExp(r'Uploaded:\s*(.+?)(?:\n|$)').firstMatch(text);
        if (uploadMatch != null) {
          metadata['uploaded'] = uploadMatch.group(1)!.trim();
        }
      }
    } catch (e) {
      _logger.w('Failed to parse metadata: $e');
    }

    return metadata;
  }

  /// Parse image URLs from detail page
  List<String> _parseImageUrls(html_dom.Document document, String contentId) {
    final imageUrls = <String>[];

    try {
      final thumbElements = document.querySelectorAll(detailPagesSelector);

      for (int i = 0; i < thumbElements.length; i++) {
        final element = thumbElements[i];
        final thumbUrl =
            element.attributes['data-src'] ?? element.attributes['src'];

        if (thumbUrl != null) {
          // Convert thumbnail URL to full image URL
          final fullImageUrl =
              _convertThumbnailToFullImage(thumbUrl, contentId, i + 1);
          if (fullImageUrl != null) {
            imageUrls.add(fullImageUrl);
          }
        }
      }

      // Fallback: generate URLs based on page count if no thumbnails found
      if (imageUrls.isEmpty) {
        final pageCount = thumbElements.length;
        for (int i = 1; i <= pageCount; i++) {
          imageUrls.add(_generateImageUrl(contentId, i));
        }
      }
    } catch (e) {
      _logger.w('Failed to parse image URLs: $e');
    }

    return imageUrls;
  }

  /// Convert thumbnail URL to full image URL
  String? _convertThumbnailToFullImage(
      String thumbUrl, String contentId, int page) {
    try {
      // nhentai thumbnail pattern: https://t.nhentai.net/galleries/{id}/{page}t.{ext}
      // Full image pattern: https://i.nhentai.net/galleries/{id}/{page}.{ext}

      final match = RegExp(
              r'https://t\.nhentai\.net/galleries/(\d+)/(\d+)t\.(jpg|png|gif)')
          .firstMatch(thumbUrl);

      if (match != null) {
        final galleryId = match.group(1)!;
        final pageNum = match.group(2)!;
        final extension = match.group(3)!;

        return 'https://i.nhentai.net/galleries/$galleryId/$pageNum.$extension';
      }

      // Fallback to generated URL
      return _generateImageUrl(contentId, page);
    } catch (e) {
      _logger.w('Failed to convert thumbnail URL: $e');
      return null;
    }
  }

  /// Generate image URL based on content ID and page number
  String _generateImageUrl(String contentId, int page) {
    // Default to JPG extension
    return 'https://i.nhentai.net/galleries/$contentId/$page.jpg';
  }

  /// Extract image URL from various formats
  String _extractImageUrl(String url) {
    if (url.isEmpty) return '';

    // Handle data-src lazy loading
    if (url.startsWith('data:')) {
      return '';
    }

    // Ensure absolute URL
    if (url.startsWith('//')) {
      return 'https:$url';
    } else if (url.startsWith('/')) {
      return 'https://nhentai.net$url';
    }

    return url;
  }

  /// Extract language from tags
  String _extractLanguage(List<Tag> tags) {
    final languageTags = tags.where((tag) => tag.type == 'language').toList();
    if (languageTags.isNotEmpty) {
      return languageTags.first.name;
    }
    return 'japanese'; // Default language
  }

  /// Extract tags by type
  List<String> _extractTagsByType(List<Tag> tags, String type) {
    return tags
        .where((tag) => tag.type == type)
        .map((tag) => tag.name)
        .toList();
  }

  /// Parse upload date from metadata
  DateTime _parseUploadDate(Map<String, String> metadata) {
    final uploadedText = metadata['uploaded'];
    if (uploadedText != null) {
      try {
        // Try to parse various date formats
        // This is a simplified parser - you might need to handle more formats
        return DateTime.tryParse(uploadedText) ?? DateTime.now();
      } catch (e) {
        _logger.w('Failed to parse upload date: $uploadedText');
      }
    }
    return DateTime.now();
  }

  /// Parse favorites count from metadata
  int _parseFavorites(Map<String, String> metadata) {
    final favoritesText = metadata['favorites'];
    if (favoritesText != null) {
      return int.tryParse(favoritesText) ?? 0;
    }
    return 0;
  }

  /// Check if text is English
  bool _isEnglish(String text) {
    // Simple heuristic - check for ASCII characters
    return RegExp(r'^[\x00-\x7F]+$').hasMatch(text);
  }

  /// Check if text is Japanese
  bool _isJapanese(String text) {
    // Check for Japanese characters (Hiragana, Katakana, Kanji)
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
  }
}
