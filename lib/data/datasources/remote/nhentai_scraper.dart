import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:logger/logger.dart';
import 'package:nhasixapp/domain/entities/entities.dart';

import '../../models/content_model.dart';
import '../../models/tag_model.dart';
import '../../../domain/entities/tag.dart';
import 'tag_resolver.dart';

/// HTML scraper for nhentai.net with CSS selectors
class NhentaiScraper {
  NhentaiScraper({Logger? logger, TagResolver? tagResolver})
      : _logger = logger ?? Logger(),
        _tagResolver = tagResolver ?? TagResolver(logger: logger);

  final Logger _logger;
  final TagResolver _tagResolver;

  // CSS Selectors for content list
  static const String contentListSelector = 'div.gallery';
  static const String contentLinkSelector = 'a.cover';
  static const String contentCoverSelector = 'img';
  static const String contentTitleSelector = '.caption';

  // CSS Selectors for homepage sections
  static const String popularSectionSelector =
      '.container.index-container.index-popular';
  static const String newUploadsSectionSelector =
      '.container.index-container:not(.index-popular)';
  static const String indexContainerSelector = '.container.index-container';

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

  /// Parse content list from HTML (async version with tag resolution)
  Future<List<ContentModel>> parseContentList(String html) async {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');
      final contentElements = document.querySelectorAll(contentListSelector);

      final contents = <ContentModel>[];

      for (final element in contentElements) {
        try {
          final content = await _parseContentCard(element);
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

  /// Parse content list from HTML (sync version without tag resolution)
  /// Use this when you don't need tag resolution for better performance
  List<ContentModel> parseContentListSync(String html) {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');
      final contentElements = document.querySelectorAll(contentListSelector);

      final contents = <ContentModel>[];

      for (final element in contentElements) {
        try {
          final content = _parseContentCardSync(element);
          if (content != null) {
            contents.add(content);
          }
        } catch (e) {
          _logger.w('Failed to parse content card: $e');
          continue;
        }
      }

      _logger.d('Parsed ${contents.length} content items from list (sync)');
      return contents;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse content list (sync)',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Parse content detail from HTML
  ContentModel parseContentDetail(String html, String contentId) {
    try {
      final document = html_parser.parse(html);

      // Extract titles
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

      // Extract upload date from time element
      final uploadDate = _parseUploadDateFromTime(document);

      // Extract favorites from button
      final favorites = _parseFavoritesFromButton(document);

      // Extract image URLs
      final imageUrls = _parseImageUrls(document, contentId);

      // Parse page count from dedicated section (not from tags)
      final pageCount = _parsePageCount(document);

      // Parse related content
      final relatedContent = _parseRelatedContent(document);

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
        pageCount: pageCount > 0 ? pageCount : imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: uploadDate,
        favorites: favorites,
        relatedContent: relatedContent,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to parse content detail for ID: $contentId',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Parse homepage content from HTML (async version with tag resolution)
  Future<Map<String, List<ContentModel>>> parseHomepage(String html) async {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');

      final result = <String, List<ContentModel>>{
        'popular': [],
        'new_uploads': [],
      };

      // Parse Popular Now section
      final popularSection = document.querySelector(popularSectionSelector);
      if (popularSection != null) {
        final popularGalleries =
            popularSection.querySelectorAll(contentListSelector);
        for (final gallery in popularGalleries) {
          final content = await _parseContentCard(gallery);
          if (content != null) {
            result['popular']!.add(content);
          }
        }
      }

      // Parse New Uploads section
      final containers = document.querySelectorAll(indexContainerSelector);
      for (final container in containers) {
        // Skip the popular section (already processed)
        if (container.classes.contains('index-popular')) continue;

        final newGalleries = container.querySelectorAll(contentListSelector);
        for (final gallery in newGalleries) {
          final content = await _parseContentCard(gallery);
          if (content != null) {
            result['new_uploads']!.add(content);
          }
        }
      }

      _logger.d(
          'Parsed homepage: ${result['popular']!.length} popular, ${result['new_uploads']!.length} new uploads');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse homepage', error: e, stackTrace: stackTrace);
      return {'popular': [], 'new_uploads': []};
    }
  }

  /// Parse homepage content from HTML (sync version without tag resolution)
  /// Use this when you don't need tag resolution for better performance
  Map<String, List<ContentModel>> parseHomepageSync(String html) {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');

      final result = <String, List<ContentModel>>{
        'popular': [],
        'new_uploads': [],
      };

      // Parse Popular Now section
      final popularSection = document.querySelector(popularSectionSelector);
      if (popularSection != null) {
        final popularGalleries =
            popularSection.querySelectorAll(contentListSelector);
        for (final gallery in popularGalleries) {
          final content = _parseContentCardSync(gallery);
          if (content != null) {
            result['popular']!.add(content);
          }
        }
      }

      // Parse New Uploads section
      final containers = document.querySelectorAll(indexContainerSelector);
      for (final container in containers) {
        // Skip the popular section (already processed)
        if (container.classes.contains('index-popular')) continue;

        final newGalleries = container.querySelectorAll(contentListSelector);
        for (final gallery in newGalleries) {
          final content = _parseContentCardSync(gallery);
          if (content != null) {
            result['new_uploads']!.add(content);
          }
        }
      }

      _logger.d(
          'Parsed homepage (sync): ${result['popular']!.length} popular, ${result['new_uploads']!.length} new uploads');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse homepage (sync)',
          error: e, stackTrace: stackTrace);
      return {'popular': [], 'new_uploads': []};
    }
  }

  /// Parse only from index containers (async version with tag resolution)
  Future<List<ContentModel>> parseFromIndexContainers(String html) async {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');
      final containers = document.querySelectorAll(newUploadsSectionSelector);

      final contents = <ContentModel>[];

      for (final container in containers) {
        final galleries = container.querySelectorAll(contentListSelector);
        for (final gallery in galleries) {
          final content = await _parseContentCard(gallery);
          if (content != null) {
            contents.add(content);
          }
        }
      }

      _logger
          .d('Parsed ${contents.length} content items from index containers');
      return contents;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse from index containers',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Parse only from index containers (sync version without tag resolution)
  /// Use this when you don't need tag resolution for better performance
  List<ContentModel> parseFromIndexContainersSync(String html) {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');
      final containers = document.querySelectorAll(indexContainerSelector);

      final contents = <ContentModel>[];

      for (final container in containers) {
        final galleries = container.querySelectorAll(contentListSelector);
        for (final gallery in galleries) {
          final content = _parseContentCardSync(gallery);
          if (content != null) {
            contents.add(content);
          }
        }
      }

      _logger.d(
          'Parsed ${contents.length} content items from index containers (sync)');
      return contents;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse from index containers (sync)',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Parse search results from HTML (async version with tag resolution)
  Future<List<ContentModel>> parseSearchResults(String html) async {
    // Search results use the same structure as content list
    return await parseContentList(html);
  }

  Future<int> parseTotalData(String html) async {
    try {
      final document = html_parser.parse(html, encoding: 'utf-8');
      final h1Text = document.querySelector('h1')?.text ?? '';

      // Gunakan regex untuk ambil angka
      final match = RegExp(r'[\d,]+').firstMatch(h1Text);
      final rawNumber = match?.group(0)?.replaceAll(',', '') ?? '0';

      // Konversi ke integer
      final resultCount = int.tryParse(rawNumber) ?? 0;

      return resultCount;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse content list',
          error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Parse search results from HTML (sync version without tag resolution)
  /// Use this when you don't need tag resolution for better performance
  List<ContentModel> parseSearchResultsSync(String html) {
    // Search results use the same structure as content list
    return parseContentListSync(html);
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

  /// Parse pagination information from HTML
  Map<String, dynamic> parsePaginationInfo(String html) {
    try {
      final document = html_parser.parse(html);
      final paginationSection = document.querySelector('section.pagination');

      if (paginationSection == null) {
        _logger.w('No pagination section found');
        return {
          'currentPage': 1,
          'totalPages': 1,
          'hasNext': false,
          'hasPrevious': false,
          'nextPage': null,
          'previousPage': null,
        };
      }

      // Extract current page
      int currentPage = 1;
      final currentPageElement =
          paginationSection.querySelector('a.page.current');
      if (currentPageElement != null) {
        currentPage = int.tryParse(currentPageElement.text.trim()) ?? 1;
      }

      // Extract total pages from "last" link
      int totalPages = 1;
      final lastPageElement = paginationSection.querySelector('a.last');
      if (lastPageElement != null) {
        final href = lastPageElement.attributes['href'];
        if (href != null) {
          final match = RegExp(r'page=(\d+)').firstMatch(href);
          if (match != null) {
            totalPages = int.tryParse(match.group(1)!) ?? 1;
          }
        }
      } else {
        final currentPageElement =
            paginationSection.querySelector('a.page.current');
        if (currentPageElement != null) {
          totalPages = int.tryParse(currentPageElement.text.trim()) ?? 1;
        }
      }

      // Extract next page
      int? nextPage;
      final nextPageElement = paginationSection.querySelector('a.next');
      if (nextPageElement != null) {
        final href = nextPageElement.attributes['href'];
        if (href != null) {
          final match = RegExp(r'page=(\d+)').firstMatch(href);
          if (match != null) {
            nextPage = int.tryParse(match.group(1)!);
          }
        }
      }

      // Extract previous page
      int? previousPage;
      final previousPageElement = paginationSection.querySelector('a.previous');
      if (previousPageElement != null) {
        final href = previousPageElement.attributes['href'];
        if (href != null) {
          final match = RegExp(r'page=(\d+)').firstMatch(href);
          if (match != null) {
            previousPage = int.tryParse(match.group(1)!);
          }
        }
      }

      // Calculate previous page if not found in DOM
      if (previousPage == null && currentPage > 1) {
        previousPage = currentPage - 1;
      }

      // Calculate next page if not found in DOM
      if (nextPage == null && currentPage < totalPages) {
        nextPage = currentPage + 1;
      }

      final paginationInfo = {
        'currentPage': currentPage,
        'totalPages': totalPages,
        'hasNext': currentPage < totalPages,
        'hasPrevious': currentPage > 1,
        'nextPage': nextPage,
        'previousPage': previousPage,
      };

      _logger.d('Parsed pagination info: $paginationInfo');
      return paginationInfo;
    } catch (e, stackTrace) {
      _logger.e('Failed to parse pagination info',
          error: e, stackTrace: stackTrace);
      return {
        'currentPage': 1,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
        'nextPage': null,
        'previousPage': null,
      };
    }
  }

  /// Extract visible page numbers from pagination
  List<int> extractVisiblePages(String html) {
    try {
      final document = html_parser.parse(html);
      final paginationSection = document.querySelector('section.pagination');

      if (paginationSection == null) return [1];

      final pageElements = paginationSection.querySelectorAll('a.page');
      final visiblePages = <int>[];

      for (final element in pageElements) {
        final pageText = element.text.trim();
        final pageNumber = int.tryParse(pageText);
        if (pageNumber != null) {
          visiblePages.add(pageNumber);
        }
      }

      visiblePages.sort();
      _logger.d('Extracted visible pages: $visiblePages');
      return visiblePages;
    } catch (e) {
      _logger.w('Failed to extract visible pages: $e');
      return [1];
    }
  }

  /// Parse individual content card (async version with tag resolution)
  Future<ContentModel?> _parseContentCard(html_dom.Element element) async {
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
      final coverElement = linkElement?.querySelector(contentCoverSelector);
      final coverUrl = _extractImageUrl(coverElement?.attributes['data-src'] ??
          coverElement?.attributes['src'] ??
          '');

      // Extract tag IDs from data-tags attribute (if available)
      final tagIds = _parseTagIds(element.attributes['data-tags']);

      // Resolve tag IDs to Tag objects using TagResolver
      final resolvedTags = await _tagResolver.resolveTagIds(tagIds);

      // Extract tags by type for better categorization
      final artists = resolvedTags
          .where((tag) => tag.type == 'artist')
          .map((tag) => tag.name)
          .toList();
      final characters = resolvedTags
          .where((tag) => tag.type == 'character')
          .map((tag) => tag.name)
          .toList();
      final parodies = resolvedTags
          .where((tag) => tag.type == 'parody')
          .map((tag) => tag.name)
          .toList();
      final groups = resolvedTags
          .where((tag) => tag.type == 'group')
          .map((tag) => tag.name)
          .toList();

      // Determine language from resolved tags
      final languageTags =
          resolvedTags.where((tag) => tag.type == 'language').toList();
      final language =
          languageTags.isNotEmpty ? languageTags.first.name : 'japanese';

      // Log extracted data for debugging
      // _logger.d(
      //     'Parsed content card - ID: $contentId, TagIDs: $tagIds, Tags: ${resolvedTags.length}, Dimensions: ${width}x$height, AspectRatio: $aspectRatio');

      // Create content model with resolved tags
      return ContentModel(
        id: contentId,
        title: title,
        coverUrl: coverUrl,
        tags: resolvedTags,
        artists: artists,
        characters: characters,
        parodies: parodies,
        groups: groups,
        language: language,
        pageCount: 0, // Will be populated from detail
        imageUrls: const [],
        uploadDate: DateTime.now(), // Will be populated from detail
        favorites: 0,
        relatedContent: const [],
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.w('Failed to parse content card: $e');
      return null;
    }
  }

  /// Parse individual content card (sync version without tag resolution)
  /// Use this when you don't need tag resolution for better performance
  ContentModel? _parseContentCardSync(html_dom.Element element) {
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
      final coverElement = linkElement?.querySelector(contentCoverSelector);
      final coverUrl = _extractImageUrl(coverElement?.attributes['data-src'] ??
          coverElement?.attributes['src'] ??
          '');

      // Extract tag IDs from data-tags attribute (if available)
      final tagIds = _parseTagIds(element.attributes['data-tags']);

      // Extract dimensions from cover element attributes
      final width =
          int.tryParse(coverElement?.attributes['width'] ?? '0') ?? 250;
      final height =
          int.tryParse(coverElement?.attributes['height'] ?? '0') ?? 350;

      // Extract aspect ratio from cover link style
      final aspectRatio = _extractAspectRatio(linkElement);

      // Log extracted data for debugging
      _logger.d(
          'Parsed content card (sync) - ID: $contentId, TagIDs: $tagIds, Dimensions: ${width}x$height, AspectRatio: $aspectRatio');

      // Create minimal content model (will be enriched when detail is fetched)
      return ContentModel(
        id: contentId,
        title: title,
        coverUrl: coverUrl,
        tags: const [], // Will be populated from detail or tag IDs
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'unknown',
        pageCount: 0, // Will be populated from detail
        imageUrls: const [],
        uploadDate: DateTime.now(), // Will be populated from detail
        favorites: 0,
        relatedContent: const [],
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.w('Failed to parse content card (sync): $e');
      return null;
    }
  }

  /// Parse tag IDs from data-tags attribute
  List<String> _parseTagIds(String? dataTags) {
    if (dataTags == null || dataTags.isEmpty) return [];

    try {
      return dataTags.split(' ').where((id) => id.isNotEmpty).toList();
    } catch (e) {
      _logger.w('Failed to parse tag IDs: $e');
      return [];
    }
  }

  /// Extract aspect ratio from cover element style
  double? _extractAspectRatio(html_dom.Element? linkElement) {
    try {
      final style = linkElement?.attributes['style'];
      if (style == null) return null;

      // Extract padding percentage from style like "padding:0 0 141.2% 0"
      final paddingMatch =
          RegExp(r'padding:\s*0\s+0\s+([\d.]+)%\s+0').firstMatch(style);
      if (paddingMatch != null) {
        final paddingPercent = double.tryParse(paddingMatch.group(1)!);
        if (paddingPercent != null) {
          // Convert padding percentage to aspect ratio (height/width)
          return paddingPercent / 100.0;
        }
      }
    } catch (e) {
      _logger.w('Failed to extract aspect ratio: $e');
    }
    return null;
  }

  /// Get tag IDs from content card for potential tag resolution
  List<String> getTagIdsFromCard(html_dom.Element element) {
    return _parseTagIds(element.attributes['data-tags']);
  }

  /// Get dimensions from content card
  Map<String, int> getDimensionsFromCard(html_dom.Element element) {
    final linkElement = element.querySelector(contentLinkSelector);
    final coverElement = linkElement?.querySelector(contentCoverSelector);

    final width = int.tryParse(coverElement?.attributes['width'] ?? '0') ?? 250;
    final height =
        int.tryParse(coverElement?.attributes['height'] ?? '0') ?? 350;

    return {'width': width, 'height': height};
  }

  /// Parse tags from detail page
  List<Tag> _parseTagsFromDetail(html_dom.Document document) {
    final tags = <Tag>[];

    try {
      // Parse tags from specific sections, excluding Pages and Uploaded
      final tagContainers = document.querySelectorAll('#tags .tag-container');

      for (final container in tagContainers) {
        // Skip Pages and Uploaded sections
        final fieldName = container.text.trim();
        if (fieldName.startsWith('Pages:') ||
            fieldName.startsWith('Uploaded:')) {
          continue;
        }

        final tagElements = container.querySelectorAll('.tag');
        for (final element in tagElements) {
          final tag = _parseTagFromElement(element);
          if (tag != null) {
            // Filter out "translated" from languages - only keep actual languages
            if (tag.type == 'language' && tag.name == 'translated') {
              continue;
            }
            tags.add(tag);
          }
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

      // Parse count with K/M suffix support
      int count = _parseCountWithSuffix(countText);

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
        id: 0, // Default ID for scraped tags
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

  /// Parse count with K/M suffix support (e.g., "93K" -> 93000)
  int _parseCountWithSuffix(String? countText) {
    if (countText == null || countText.isEmpty) return 0;

    try {
      // Remove any parentheses and trim
      final cleanText = countText.replaceAll(RegExp(r'[()]'), '').trim();

      if (cleanText.isEmpty) return 0;

      // Check for K suffix (thousands)
      if (cleanText.endsWith('K')) {
        final numberPart = cleanText.substring(0, cleanText.length - 1);
        final number = double.tryParse(numberPart);
        if (number != null) {
          return (number * 1000).round();
        }
      }

      // Check for M suffix (millions)
      if (cleanText.endsWith('M')) {
        final numberPart = cleanText.substring(0, cleanText.length - 1);
        final number = double.tryParse(numberPart);
        if (number != null) {
          return (number * 1000000).round();
        }
      }

      // Try to parse as regular number
      return int.tryParse(cleanText) ?? 0;
    } catch (e) {
      _logger.w('Failed to parse count with suffix: $countText');
      return 0;
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

      // Parse count with K/M suffix support
      int count = _parseCountWithSuffix(countText);

      return TagModel(
        id: 0, // Default ID for scraped tags
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
          // _logger.i("url sebelum: ${thumbUrl}");
          final fullImageUrl = _convertThumbnailToFull(thumbUrl);
          imageUrls.add(fullImageUrl);
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

  /// Parse image URLs using media ID for accurate URL generation
  String _convertThumbnailToFull(String thumbUrl) {
    // Pastikan url mulai dari https
    String url = thumbUrl.replaceFirst('//', 'https://');

    // Ganti domain tX -> iX
    url = url.replaceFirstMapped(RegExp(r'//t(\d)\.nhentai\.net'), (match) {
      return '//i${match.group(1)}.nhentai.net';
    });

    // Hilangkan huruf 't' sebelum ekstensi gambar
    url = url.replaceFirstMapped(
      RegExp(r'(\d+)t\.(webp|jpg|png|gif|jpeg)'),
      (match) => '${match.group(1)}.${match.group(2)}',
    );

    // Hapus ekstensi ganda (misal .webp.webp -> .webp)
    url = url.replaceAllMapped(
      RegExp(r'\.(webp|jpg|png|gif|jpeg)\.(webp|jpg|png|gif|jpeg)$'),
      (match) => '.${match.group(1)}',
    );

    // _logger.i(url);
    return url;
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

  /// Parse upload date from time element with datetime attribute
  DateTime _parseUploadDateFromTime(html_dom.Document document) {
    try {
      final timeElement = document.querySelector('time[datetime]');
      if (timeElement != null) {
        final datetimeAttr = timeElement.attributes['datetime'];
        if (datetimeAttr != null) {
          return DateTime.parse(datetimeAttr);
        }
      }
    } catch (e) {
      _logger.w('Failed to parse upload date from time element: $e');
    }
    return DateTime.now();
  }

  /// Parse favorites count from button text
  int _parseFavoritesFromButton(html_dom.Document document) {
    try {
      final favoriteButton = document.querySelector('.btn .nobold');
      if (favoriteButton != null) {
        final text = favoriteButton.text.trim();
        // Extract number from text like "(296)"
        final match = RegExp(r'\((\d+)\)').firstMatch(text);
        if (match != null) {
          return int.tryParse(match.group(1)!) ?? 0;
        }
      }
    } catch (e) {
      _logger.w('Failed to parse favorites from button: $e');
    }
    return 0;
  }

  /// Parse related content from "More Like This" section
  List<ContentModel> _parseRelatedContent(html_dom.Document document) {
    final relatedContent = <ContentModel>[];

    try {
      final relatedContainer = document.querySelector('#related-container');
      if (relatedContainer != null) {
        final galleries = relatedContainer.querySelectorAll('.gallery');

        for (final gallery in galleries) {
          try {
            final linkElement = gallery.querySelector('a.cover');
            final href = linkElement?.attributes['href'];
            if (href == null) continue;

            final match = RegExp(contentUrlPattern).firstMatch(href);
            if (match == null) continue;

            final contentId = match.group(1)!;

            // Extract title
            final titleElement = gallery.querySelector('.caption');
            final title = (titleElement?.text)?.trim() ?? 'Unknown Title';

            // Extract cover URL
            final coverElement = linkElement?.querySelector('img');
            final coverUrl = _extractImageUrl(
                coverElement?.attributes['data-src'] ??
                    coverElement?.attributes['src'] ??
                    '');

            // Extract tag IDs from data-tags attribute
            // final tagIds = _parseTagIds(gallery.attributes['data-tags']);

            // Create minimal content for related items
            final content = ContentModel(
              id: contentId,
              title: title,
              coverUrl: coverUrl,
              tags: const [], // Will be resolved later if needed
              artists: const [],
              characters: const [],
              parodies: const [],
              groups: const [],
              language: 'unknown',
              pageCount: 0,
              imageUrls: const [],
              uploadDate: DateTime.now(),
              favorites: 0,
              relatedContent: const [],
            );

            relatedContent.add(content);
          } catch (e) {
            _logger.w('Failed to parse related content item: $e');
            continue;
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to parse related content: $e');
    }

    _logger.d('Parsed ${relatedContent.length} related content items');
    return relatedContent;
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

  /// Resolve tag IDs to Tag objects using external tag mapping
  /// This method can be used when tag ID to name mapping is available
  /// For example, using data from https://github.com/maxwai/NClientV3/blob/main/data/tagsPretty.json
  List<Tag> resolveTagIds(
      List<String> tagIds, Map<String, Map<String, dynamic>>? tagMapping) {
    if (tagMapping == null || tagIds.isEmpty) return [];

    final tags = <Tag>[];

    for (final tagId in tagIds) {
      final tagData = tagMapping[tagId];
      if (tagData != null) {
        try {
          tags.add(Tag(
            id: tagData['id'] ?? 0,
            name: tagData['name'] ?? 'Unknown',
            type: tagData['type'] ?? 'tag',
            count: tagData['count'] ?? 0,
            url: '/tag/${tagData['name']?.replaceAll(' ', '-') ?? tagId}/',
          ));
        } catch (e) {
          _logger.w('Failed to resolve tag ID $tagId: $e');
        }
      }
    }

    return tags;
  }

  /// Create enhanced ContentModel with resolved tags from tag IDs (async version)
  /// Uses TagResolver to automatically download and cache tag mapping
  /// This is now an alias to the main _parseContentCard method
  Future<ContentModel?> parseContentCardWithTagsAsync(
      html_dom.Element element) async {
    return await _parseContentCard(element);
  }

  /// Parse homepage content with resolved tags (async version)
  /// This is now an alias to the main parseHomepage method
  Future<Map<String, List<ContentModel>>> parseHomepageWithTagsAsync(
      String html) async {
    return await parseHomepage(html);
  }

  /// Parse content list with resolved tags (async version)
  /// This is now an alias to the main parseContentList method
  Future<List<ContentModel>> parseContentListWithTagsAsync(String html) async {
    return await parseContentList(html);
  }

  /// Get TagResolver instance for direct access
  TagResolver get tagResolver => _tagResolver;

  /// Create enhanced ContentModel with resolved tags from tag IDs (sync version with mapping)
  /// This method can be used when tag mapping is already available
  ContentModel? parseContentCardWithTags(
      html_dom.Element element, Map<String, Map<String, dynamic>>? tagMapping) {
    final baseContent = _parseContentCardSync(element);
    if (baseContent == null) return null;

    // Extract tag IDs and resolve them to Tag objects
    final tagIds = _parseTagIds(element.attributes['data-tags']);
    final resolvedTags = resolveTagIds(tagIds, tagMapping);

    // Extract tags by type for better categorization
    final artists = resolvedTags
        .where((tag) => tag.type == 'artist')
        .map((tag) => tag.name)
        .toList();
    final characters = resolvedTags
        .where((tag) => tag.type == 'character')
        .map((tag) => tag.name)
        .toList();
    final parodies = resolvedTags
        .where((tag) => tag.type == 'parody')
        .map((tag) => tag.name)
        .toList();
    final groups = resolvedTags
        .where((tag) => tag.type == 'group')
        .map((tag) => tag.name)
        .toList();

    // Determine language from resolved tags
    final languageTags =
        resolvedTags.where((tag) => tag.type == 'language').toList();
    final language =
        languageTags.isNotEmpty ? languageTags.first.name : 'japanese';

    return ContentModel(
      id: baseContent.id,
      title: baseContent.title,
      coverUrl: baseContent.coverUrl,
      tags: resolvedTags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: language,
      pageCount: baseContent.pageCount,
      imageUrls: baseContent.imageUrls,
      uploadDate: baseContent.uploadDate,
      favorites: baseContent.favorites,
      englishTitle: baseContent.englishTitle,
      japaneseTitle: baseContent.japaneseTitle,
      relatedContent: baseContent.relatedContent,
      cachedAt: baseContent.cachedAt,
    );
  }

  /// Parse page count from dedicated Pages section
  int _parsePageCount(html_dom.Document document) {
    try {
      // Look for Pages section specifically
      final tagContainers = document.querySelectorAll('#tags .tag-container');

      for (final container in tagContainers) {
        final fieldName = container.text.trim();
        if (fieldName.startsWith('Pages:')) {
          final pageElement = container.querySelector('.tag .name');
          if (pageElement != null) {
            final pageText = pageElement.text.trim();
            return int.tryParse(pageText) ?? 0;
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to parse page count: $e');
    }
    return 0;
  }
}
