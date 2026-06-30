import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

import 'mangafire_vrf_cache.dart';
import 'mangafire_webview_helper.dart';

const mangafireChapterLanguageTagType = '__mangafire_chapter_language';
const mangafireChapterGroupTagType = '__mangafire_chapter_group';
const mangafireUnknownLanguageKey = 'unknown';

String resolveMangaFireSearchQuery(
  SearchFilter filter,
  Map<String, dynamic> rawConfig,
) {
  final query = filter.query.trim();
  if (!query.startsWith('raw:')) {
    return query;
  }

  final queryParam = (((rawConfig['searchForm'] as Map?)?['params']
          as Map?)?['query'] as Map?)?['queryParam'] as String? ??
      'keyword';
  return extractMangaFireRawQueryValue(query, queryParam: queryParam) ?? '';
}

String resolveMangaFireLanguage(
  SearchFilter filter,
  Map<String, dynamic> rawConfig,
) {
  final rawLanguage = extractMangaFireRawQueryValue(
    filter.query,
    queryParam: 'language[]',
  );
  if (rawLanguage != null && rawLanguage.isNotEmpty) {
    return rawLanguage;
  }

  final language = filter.language?.trim();
  if (language != null && language.isNotEmpty) {
    return language;
  }
  final defaultLanguage = (rawConfig['defaultLanguage'] as String?)?.trim();
  if (defaultLanguage != null && defaultLanguage.isNotEmpty) {
    return defaultLanguage;
  }
  return 'en';
}

String? resolveMangaFireSort(
  SearchFilter filter,
  Map<String, dynamic> rawConfig, {
  required String configKey,
}) {
  final sortParam = (((rawConfig['searchForm'] as Map?)?['params']
          as Map?)?['sort'] as Map?)?['queryParam'] as String? ??
      'sort';

  final rawSort = extractMangaFireRawQueryValue(
    filter.query,
    queryParam: sortParam,
  );
  if (rawSort != null && rawSort.isNotEmpty) {
    return rawSort;
  }

  // Fallback to sort from config url patterns
  final patterns =
      ((rawConfig['scraper'] as Map?)?['urlPatterns'] as Map?)?[configKey];
  if (patterns != null) {
    final url =
        patterns is Map ? patterns['url'] as String? : patterns as String?;
    if (url != null && url.isNotEmpty) {
      final sortMatch = RegExp(r'[?&]sort=([^&]+)').firstMatch(url);
      if (sortMatch != null) {
        return sortMatch.group(1);
      }
    }
  }

  return null;
}

String? extractMangaFireRawQueryValue(
  String input, {
  required String queryParam,
}) {
  if (!input.startsWith('raw:')) {
    return null;
  }

  for (final pair in input.substring(4).split('&')) {
    if (pair.isEmpty) {
      continue;
    }
    final index = pair.indexOf('=');
    if (index < 0) {
      continue;
    }
    final key = decodeMangaFireQueryComponent(pair.substring(0, index));
    if (key != queryParam) {
      continue;
    }
    final value =
        decodeMangaFireQueryComponent(pair.substring(index + 1)).trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  return null;
}

String decodeMangaFireQueryComponent(String value) {
  try {
    return Uri.decodeQueryComponent(value);
  } catch (_) {
    return value;
  }
}

String? normalizeMangaFireHtmlResponse(String? raw) {
  if (raw == null || raw.isEmpty) {
    return raw;
  }

  final trimmed = raw.trim();
  if (!trimmed.startsWith('"')) {
    return raw;
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is String && decoded.isNotEmpty) {
      return decoded.replaceAll(r'\/', '/');
    }
  } catch (_) {
    // Leave response as-is when it is not actually a JSON-encoded HTML string.
  }

  return raw;
}

String buildMangaFireFilterUrl({
  required String baseUrl,
  required String keyword,
  required String language,
  required int page,
  String? sort,
  String vrf = '',
  Map<String, dynamic>? rawConfig,
}) {
  final base = Uri.parse(baseUrl).resolve('/filter').toString();

  // Read param names from config's searchForm.params
  final params = (rawConfig?['searchForm'] as Map?)?['params'] as Map? ?? {};
  String qp(String key, String fallback) {
    final raw = (params[key] as Map?)?['queryParam'] as String? ?? fallback;
    return Uri.encodeQueryComponent(raw);
  }

  final pairs = <String>[
    '${qp('query', 'keyword')}=${Uri.encodeQueryComponent(keyword)}',
    '${qp('language', 'language[]')}=${Uri.encodeQueryComponent(language)}',
    if (sort != null && sort.isNotEmpty)
      '${qp('sort', 'sort')}=${Uri.encodeQueryComponent(sort)}',
    // ponytail: skip empty vrf; it's valid but adds noise
    if (vrf.isNotEmpty) 'vrf=${Uri.encodeQueryComponent(vrf)}',
    '${qp('page', 'page')}=$page',
  ];
  return '$base?${pairs.join('&')}';
}

List<dom.Element> selectMangaFireListNodes(dom.Document document) {
  final primary = document.querySelectorAll('.original.card-lg .unit .inner');
  if (primary.isNotEmpty) {
    return primary;
  }

  final cardFallback = document.querySelectorAll('.card-lg .unit .inner');
  if (cardFallback.isNotEmpty) {
    return cardFallback;
  }

  return document.querySelectorAll('.unit .inner');
}

List<dom.Element> selectMangaFireDetailChapterNodes(
  dom.Document document, {
  required String dataName,
}) {
  return document.querySelectorAll(
    '.tab-content[data-name="$dataName"] .list-body li.item',
  );
}

List<dom.Element> selectMangaFireRelatedNodes(dom.Document document) {
  return document.querySelectorAll('section.m-related .unit');
}

List<({String language, String type})> computeMissingMangaFireChapterRequests({
  required List<Chapter> chapters,
  required Set<String> languages,
}) {
  final availableLanguages = languages
      .map((language) => language.trim().toLowerCase())
      .where((language) => language.isNotEmpty)
      .toSet();
  final seenByType = <String, Set<String>>{
    'chapter': <String>{},
    'volume': <String>{},
  };

  for (final chapter in chapters) {
    final language = (chapter.language ?? '').trim().toLowerCase();
    if (language.isEmpty) {
      continue;
    }

    final scanGroup = (chapter.scanGroup ?? '').trim().toLowerCase();
    final type = scanGroup.startsWith('vol') ? 'volume' : 'chapter';
    seenByType[type]!.add(language);
  }

  final requests = <({String language, String type})>[];
  for (final type in const <String>['chapter', 'volume']) {
    final seenLanguages = seenByType[type] ?? const <String>{};
    final missingLanguages = seenLanguages.isEmpty
        ? availableLanguages
        : availableLanguages.difference(seenLanguages);
    for (final language in missingLanguages) {
      requests.add((language: language, type: type));
    }
  }

  return requests;
}

String? resolveMangaFireReaderLanguage(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }

  final segments = uri.pathSegments;
  final readIndex = segments.indexOf('read');
  if (readIndex < 0 || readIndex + 2 >= segments.length) {
    return null;
  }

  final value = segments[readIndex + 2].trim().toLowerCase();
  if (value.isEmpty || value.contains('chapter') || value.contains('volume')) {
    return null;
  }
  return value;
}

bool hasMangaFireChapterGroupMetadata(Content content, String group) {
  return content.tags.any(
    (tag) => tag.type == mangafireChapterGroupTagType && tag.name == group,
  );
}

List<String> extractMangaFireAvailableLanguageKeys(Content content) {
  final keys = content.tags
      .where((tag) => tag.type == mangafireChapterLanguageTagType)
      .map((tag) => normalizeMangaFireLanguageKey(tag.name))
      .where((key) => key.isNotEmpty)
      .toList(growable: false);
  if (keys.isNotEmpty) {
    return keys;
  }
  return content.chapters
          ?.map((chapter) => normalizeMangaFireLanguageKey(chapter.language))
          .toSet()
          .toList(growable: false) ??
      const <String>[];
}

String normalizeMangaFireLanguageKey(String? value) {
  final raw = value?.trim().toLowerCase().replaceAll('_', '-');
  if (raw == null || raw.isEmpty) return mangafireUnknownLanguageKey;
  if (raw == 'pt-br' || raw == 'es-la') {
    return raw;
  }
  final base = raw.split('-').first;
  return switch (base) {
    'english' => 'en',
    'eng' => 'en',
    'indonesian' => 'id',
    'indo' => 'id',
    'japanese' => 'ja',
    'jpn' => 'ja',
    'korean' => 'ko',
    'kor' => 'ko',
    'chinese' => 'zh',
    'unknown' => mangafireUnknownLanguageKey,
    _ => base,
  };
}

class MangaFireAdapter implements GenericAdapter {
  MangaFireAdapter({
    required Dio dio,
    required Logger logger,
    required MangaFireVrfCache vrfCache,
    required MangaFireWebViewHelper webViewHelper,
    required String baseUrl,
    RateLimiter? rateLimiter,
  })  : _dio = dio,
        _logger = logger,
        _vrfCache = vrfCache,
        _webViewHelper = webViewHelper,
        _baseUrl = baseUrl,
        _rateLimiter = rateLimiter ??
            RateLimiter(
              delay: const Duration(milliseconds: 500),
              maxConcurrent: 1,
            );

  final Dio _dio;
  final Logger _logger;
  final MangaFireVrfCache _vrfCache;
  final MangaFireWebViewHelper _webViewHelper;
  final String _baseUrl;
  final RateLimiter _rateLimiter;

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) async {
    final language = resolveMangaFireLanguage(filter, rawConfig);

    // Pre-process raw tag queries from generic mapping config
    var baseQuery = filter.query.trim();
    if (baseQuery.startsWith('raw:author:{value}=')) {
      baseQuery =
          'author:${baseQuery.replaceFirst('raw:author:{value}=', '').trim()}';
    } else if (baseQuery.startsWith('raw:magazine:{value}=')) {
      baseQuery =
          'magazine:${baseQuery.replaceFirst('raw:magazine:{value}=', '').trim()}';
    } else if (baseQuery.startsWith('raw:genre:{value}=')) {
      baseQuery =
          'genre:${baseQuery.replaceFirst('raw:genre:{value}=', '').trim()}';
    }

    if (baseQuery.startsWith('author:')) {
      final value = baseQuery.replaceFirst('author:', '').trim();
      return _fetchList(
          _absoluteUrl('/author/${_slugify(value)}?page=${filter.page}'),
          sourceLanguage: language);
    }

    if (baseQuery.startsWith('magazine:')) {
      final value = baseQuery.replaceFirst('magazine:', '').trim();
      return _fetchList(
          _absoluteUrl('/magazine/${_slugify(value)}?page=${filter.page}'),
          sourceLanguage: language);
    }

    if (baseQuery.startsWith('genre:')) {
      final value = baseQuery.replaceFirst('genre:', '').trim();
      return _fetchList(
          _absoluteUrl('/genre/${_slugify(value)}?page=${filter.page}'),
          sourceLanguage: language);
    }

    final query = resolveMangaFireSearchQuery(filter, rawConfig);

    if (query.isNotEmpty) {
      return _searchWithQuery(
        filter: filter,
        language: language,
        query: query,
        rawConfig: rawConfig,
      );
    }

    if (filter.includeTags.isNotEmpty) {
      final tag = filter.includeTags.first;
      String route = 'genre';
      String slug = _slugify(tag.name);

      // Handle the prefix we injected in ContentRepositoryImpl
      if (slug.startsWith('artist-')) {
        route = 'author';
        slug = slug.substring(7);
      } else if (slug.startsWith('author-')) {
        route = 'author';
        slug = slug.substring(7);
      } else if (slug.startsWith('magazine-')) {
        route = 'magazine';
        slug = slug.substring(9);
      } else if (tag.type == 'artist') {
        route = 'author';
      } else if (tag.type == 'magazine') {
        route = 'magazine';
      }

      final url = _absoluteUrl('/$route/$slug?page=${filter.page}');
      return _fetchList(url, sourceLanguage: language);
    }

    final category = filter.category?.trim() ?? '';
    if (category.isNotEmpty) {
      final url =
          _absoluteUrl('/type/${_slugify(category)}?page=${filter.page}');
      return _fetchList(url, sourceLanguage: language);
    }

    final sort = resolveMangaFireSort(filter, rawConfig, configKey: 'home');
    final url = buildMangaFireFilterUrl(
      baseUrl: _baseUrl,
      keyword: '',
      language: language,
      sort: sort,
      vrf: '',
      page: filter.page,
      rawConfig: rawConfig,
    );
    return _fetchList(url, sourceLanguage: language);
  }


  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final detailUrl = _absoluteUrl('/manga/$contentId');

    final htmlContent = await _getHtml(detailUrl);

    if (htmlContent == null || htmlContent.isEmpty) {
      return AdapterDetailResult(
        content: _emptyContent(contentId),
        imageUrls: const <String>[],
      );
    }

    final document = html.parse(htmlContent);
    final title = _text(document.querySelector('h1'));
    final altTitle = _text(document.querySelector('h6'));
    final coverUrl = _attr(document.querySelector('.poster img'), 'src');
    final statusText = _text(document.querySelector('.info > p'));
    final typeText =
        _text(document.querySelector('.min-info a[href*="/type/"]'));
    final author = _extractMetaValue(document, 'Author');
    final published = _extractMetaValue(document, 'Published');
    final rating = _extractRating(document);
    final description = _cleanDescription(document);

    // Parse languages
    final langCodes = <String>{};
    final langNodes =
        document.querySelectorAll('.list-menu .dropdown-menu .dropdown-item');
    for (final node in langNodes) {
      String code = node.attributes['data-code']?.trim().toLowerCase() ?? '';
      if (code.isEmpty) {
        final href = node.attributes['href']?.trim() ?? '';
        if (href.isNotEmpty) {
          code = href.split('/').last.toLowerCase();
        }
      }

      // Clean up in case it accidentally got parsed as a full URL
      if (code.contains('/')) {
        code = code.split('/').last;
      }

      if (code.isNotEmpty) {
        langCodes.add(code);
      }
    }
    if (langCodes.isEmpty) {
      langCodes.add(resolveMangaFireLanguage(const SearchFilter(), rawConfig));
    }

    final metaLinks = document.querySelectorAll('.meta a');
    final tags = <Tag>[];
    for (final link in metaLinks) {
      final text = _text(link);
      if (text.isEmpty) continue;

      final href = _attr(link, 'href');
      if (href.isEmpty) continue;

      String type = TagType.tag;
      if (href.contains('/author/')) {
        type = TagType.artist;
      } else if (href.contains('/magazine/')) {
        type = 'magazine';
      } else if (href.contains('/type/')) {
        type = TagType.category;
      }

      tags.add(Tag(
        id: text.hashCode,
        name: text,
        type: type,
        count: 0,
        url: _absoluteUrl(href),
        slug: _slugify(text),
      ));
    }

    final hasChapterGroup =
        document.querySelector('.tab-content[data-name="chapter"]') != null;
    final hasVolumeGroup =
        document.querySelector('.tab-content[data-name="volume"]') != null;
    tags.addAll(_buildMangaFireLaneMetadataTags(
      languages: langCodes,
      hasChapterGroup: hasChapterGroup,
      hasVolumeGroup: hasVolumeGroup,
    ));

    final fallbackLanguage = langCodes.first;
    final chapters = _parseChaptersFromDetailDocument(
      document,
      fallbackLanguage: fallbackLanguage,
      allowedGroups: const <String>{'Chapter'},
    );

    final relatedContent = <Content>[];

    // First try the regular card format (like "You may also like")
    final relatedNodes = selectMangaFireRelatedNodes(document);
    for (final node in relatedNodes) {
      final href = _attr(node, 'href');
      if (href.isEmpty) continue;

      final relatedId = _contentIdFromUrl(href);
      if (relatedId == null || relatedId.isEmpty) continue;

      final relTitle = node.querySelector('.info h6')?.text.trim() ?? '';
      final relCover = _attr(node.querySelector('.poster img'), 'src');

      relatedContent.add(Content(
        id: relatedId,
        sourceId: 'mangafire',
        title: relTitle.isNotEmpty ? relTitle : relatedId,
        url: _absoluteUrl(href),
        coverUrl: relCover,
        contentType: ContentType.manga,
        status: ContentStatus.unknown,
        pageCount: 0,
        chapters: const [],
        imageUrls: const [],
        tags: const [],
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'en',
        uploadDate: DateTime.now(),
      ));
    }

    // Then try the list format (like "Related Manga" tabs)
    final relatedListNodes =
        document.querySelectorAll('section.m-related ul.tab-content li a');
    for (final node in relatedListNodes) {
      final href = _attr(node, 'href');
      if (href.isEmpty) continue;

      final relatedId = _contentIdFromUrl(href);
      if (relatedId == null || relatedId.isEmpty) continue;

      // Avoid duplicates if somehow the same manga is in both sections
      if (relatedContent.any((c) => c.id == relatedId)) continue;

      final relTitle = _text(node);

      relatedContent.add(Content(
        id: relatedId,
        sourceId: 'mangafire',
        title: relTitle.isNotEmpty ? relTitle : relatedId,
        url: _absoluteUrl(href),
        coverUrl: '', // List items usually don't have covers readily available
        contentType: ContentType.manga,
        status: ContentStatus.unknown,
        pageCount: 0,
        chapters: const [],
        imageUrls: const [],
        tags: const [],
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'en',
        uploadDate: DateTime.now(),
      ));
    }

    final content = Content(
      id: contentId,
      sourceId: 'mangafire',
      title: title.isNotEmpty ? title : contentId,
      englishTitle: altTitle.isNotEmpty ? altTitle : null,
      japaneseTitle: null,
      subTitle: _joinSubtitleParts(<String>[
        if (typeText.isNotEmpty) typeText,
        if (author.isNotEmpty) author,
        if (published.isNotEmpty) published,
        if (rating.isNotEmpty) 'MAL $rating',
        if (description.isNotEmpty) description,
      ]),
      coverUrl: coverUrl,
      tags: tags,
      artists: author.isNotEmpty ? <String>[author] : const <String>[],
      characters: const <String>[],
      parodies: const <String>[],
      groups: const <String>[],
      language: langCodes.first,
      pageCount: chapters.isNotEmpty ? chapters.length : 0,
      imageUrls: const <String>[],
      uploadDate: _parseDate(published) ?? DateTime.now(),
      relatedContent: relatedContent,
      chapters: chapters,
      url: '/manga/$contentId',
      contentType: _mapContentType(typeText),
      status: _mapStatus(statusText),
      sourceUrl: detailUrl,
      totalChapters: chapters.length,
    );

    return AdapterDetailResult(
      content: content,
      imageUrls: const <String>[],
    );
  }

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final detail = await fetchDetail(contentId, rawConfig);
    return detail.content.relatedContent;
  }

  @override
  Future<List<Chapter>> fetchChapters(
    String contentId,
    Map<String, dynamic> rawConfig, {
    String? language,
    String? scanGroup,
  }) async {
    final normalizedLanguage = normalizeMangaFireLanguageKey(language);
    final group = (scanGroup ?? 'Chapter').trim();
    final requestType =
        group.toLowerCase().startsWith('vol') ? 'volume' : 'chapter';
    return _fetchChaptersFromAjax(
      detailUrl: _absoluteUrl('/manga/$contentId'),
      requests: <({String language, String type})>[
        (
          language: normalizedLanguage == mangafireUnknownLanguageKey
              ? resolveMangaFireLanguage(const SearchFilter(), rawConfig)
              : normalizedLanguage,
          type: requestType,
        ),
      ],
      seenIds: <String>{},
    );
  }

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    return const <Comment>[];
  }

  @override
  Future<ChapterData?> fetchChapterImages(
    String chapterId,
    Map<String, dynamic> rawConfig,
  ) async {
    final readerUrl = _readerUrlFromChapterId(chapterId);
    if (readerUrl == null) {
      _logger.w('MangaFire chapter id is missing reader URL: $chapterId');
      return null;
    }

    final cacheKey = readerUrl;
    final cachedUrl = _vrfCache.get(
      scope: MangaFireVrfScope.reader,
      key: cacheKey,
    );

    final ajaxUrl = cachedUrl ??
        await _webViewHelper.captureReaderRequestUrl(
          readerUrl: _absoluteUrl(readerUrl),
        );
    if (ajaxUrl == null || ajaxUrl.isEmpty) {
      return null;
    }

    final ajaxUri = Uri.tryParse(ajaxUrl);
    final vrf = ajaxUri?.queryParameters['vrf'];
    if (vrf == null || vrf.isEmpty) {
      _logger.w('MangaFire reader capture returned URL without vrf: $ajaxUrl');
      return null;
    }
    _vrfCache.set(
      scope: MangaFireVrfScope.reader,
      key: cacheKey,
      token: ajaxUrl,
    );

    final payload = await _getJsonWithRetry(
      url: ajaxUrl,
      scope: MangaFireVrfScope.reader,
      cacheKey: cacheKey,
      onRetry: () => _webViewHelper.captureReaderRequestUrl(
        readerUrl: _absoluteUrl(readerUrl),
      ),
    );
    final images = _parseReaderImages(payload);
    if (images.isEmpty) {
      _logger.w('MangaFire reader returned no images for $readerUrl');
    }

    return ChapterData(images: images);
  }

  Future<AdapterSearchResult> _searchWithQuery({
    required SearchFilter filter,
    required String language,
    required String query,
    required Map<String, dynamic> rawConfig,
  }) async {
    final cacheKey = '${query.toLowerCase()}::$language';
    final cachedToken = _vrfCache.get(
      scope: MangaFireVrfScope.search,
      key: cacheKey,
    );

    String? vrf = cachedToken;
    if (vrf == null || vrf.isEmpty) {
      final capturedUrl = await _webViewHelper.captureSearchRequestUrl(
        baseUrl: _baseUrl,
        query: query,
      );
      vrf = Uri.tryParse(capturedUrl ?? '')?.queryParameters['vrf'];
      if (vrf == null || vrf.isEmpty) {
        _logger.w('MangaFire search capture did not return vrf');
        return const AdapterSearchResult(
            items: <Content>[], hasNextPage: false);
      }
      _vrfCache.set(
        scope: MangaFireVrfScope.search,
        key: cacheKey,
        token: vrf,
      );
    }

    Future<String?> refreshVrf() async {
      final capturedUrl = await _webViewHelper.captureSearchRequestUrl(
        baseUrl: _baseUrl,
        query: query,
      );
      final refreshed = Uri.tryParse(capturedUrl ?? '')?.queryParameters['vrf'];
      if (refreshed != null && refreshed.isNotEmpty) {
        _vrfCache.set(
          scope: MangaFireVrfScope.search,
          key: cacheKey,
          token: refreshed,
        );
      }
      return refreshed;
    }

    final sort = resolveMangaFireSort(filter, rawConfig, configKey: 'search');
    final url = buildMangaFireFilterUrl(
      baseUrl: _baseUrl,
      keyword: query,
      language: language,
      sort: sort,
      vrf: vrf,
      page: filter.page,
      rawConfig: rawConfig,
    );

    final htmlContent = await _getHtmlWithRetry(
      url: url,
      scope: MangaFireVrfScope.search,
      cacheKey: cacheKey,
      onRetry: refreshVrf,
      rebuildUrl: (token) => buildMangaFireFilterUrl(
        baseUrl: _baseUrl,
        keyword: query,
        language: language,
        sort: sort,
        vrf: token,
        page: filter.page,
        rawConfig: rawConfig,
      ),
    );
    if (htmlContent == null || htmlContent.isEmpty) {
      return const AdapterSearchResult(items: <Content>[], hasNextPage: false);
    }

    return _parseListDocument(
      html.parse(htmlContent),
      sourceLanguage: language,
    );
  }

  Future<AdapterSearchResult> _fetchList(
    String url, {
    required String sourceLanguage,
  }) async {
    final htmlContent = await _getHtml(url);
    if (htmlContent == null || htmlContent.isEmpty) {
      return const AdapterSearchResult(items: <Content>[], hasNextPage: false);
    }
    return _parseListDocument(html.parse(htmlContent),
        sourceLanguage: sourceLanguage);
  }

  AdapterSearchResult _parseListDocument(
    dom.Document document, {
    required String sourceLanguage,
  }) {
    final listNodes = selectMangaFireListNodes(document);
    final items = listNodes
        .map((element) => _mapListItem(element, sourceLanguage: sourceLanguage))
        .whereType<Content>()
        .toList(growable: false);

    if (items.isEmpty) {
      _logger.w(
        'MangaFire list parse returned 0 items '
        '(title="${_text(document.querySelector('title'))}", '
        'primary=${document.querySelectorAll('.original.card-lg .unit .inner').length}, '
        'cardFallback=${document.querySelectorAll('.card-lg .unit .inner').length}, '
        'unitFallback=${document.querySelectorAll('.unit .inner').length})',
      );
    }

    int? totalPages;
    final paginationNode = document.querySelector('.pagination');
    if (paginationNode != null) {
      final pageLinks =
          paginationNode.querySelectorAll('.page-item a, .page-item span');
      for (final link in pageLinks) {
        final text = _text(link).trim();
        final pageNum = int.tryParse(text);
        if (pageNum != null) {
          if (totalPages == null || pageNum > totalPages) {
            totalPages = pageNum;
          }
        }

        final href = _attr(link, 'href');
        if (href.isNotEmpty) {
          final uri = Uri.tryParse(href);
          if (uri != null && uri.queryParameters.containsKey('page')) {
            final hrefPageNum = int.tryParse(uri.queryParameters['page']!);
            if (hrefPageNum != null) {
              if (totalPages == null || hrefPageNum > totalPages) {
                totalPages = hrefPageNum;
              }
            }
          }
        }
      }
    }

    final hasNext =
        document.querySelector('.page-item.active + .page-item .page-link') !=
                null ||
            document.querySelector(
                    '.pagination .page-item:last-child a[rel="next"]') !=
                null;

    return AdapterSearchResult(
      items: items,
      hasNextPage: hasNext,
      totalPages: totalPages,
    );
  }

  List<Chapter> _parseChaptersFromDetailDocument(
    dom.Document document, {
    required String fallbackLanguage,
    Set<String>? allowedGroups,
  }) {
    final chapters = <Chapter>[];
    final seenIds = <String>{};
    final normalizedAllowedGroups =
        allowedGroups?.map((group) => group.trim().toLowerCase()).toSet();

    for (final entry in const <(String, String)>[
      ('chapter', 'Chapter'),
      ('volume', 'Volume'),
    ]) {
      if (normalizedAllowedGroups != null &&
          !normalizedAllowedGroups.contains(entry.$2.toLowerCase())) {
        continue;
      }
      final items = selectMangaFireDetailChapterNodes(
        document,
        dataName: entry.$1,
      );
      for (final item in items) {
        final chapter = _mapDetailChapterItem(
          item,
          scanGroup: entry.$2,
          fallbackLanguage: fallbackLanguage,
        );
        if (chapter != null && seenIds.add(chapter.id)) {
          chapters.add(chapter);
        }
      }
    }

    if (chapters.isEmpty) {
      _logger.w(
        'MangaFire detail HTML contained no chapter items '
        '(chapter=${selectMangaFireDetailChapterNodes(document, dataName: 'chapter').length}, '
        'volume=${selectMangaFireDetailChapterNodes(document, dataName: 'volume').length})',
      );
    }

    return chapters;
  }

  List<Tag> _buildMangaFireLaneMetadataTags({
    required Set<String> languages,
    required bool hasChapterGroup,
    required bool hasVolumeGroup,
  }) {
    final tags = <Tag>[
      for (final language in languages.toList()..sort())
        Tag(
          id: language.hashCode,
          name: normalizeMangaFireLanguageKey(language),
          type: mangafireChapterLanguageTagType,
          count: 0,
        ),
    ];

    if (hasChapterGroup) {
      tags.add(
        const Tag(
          id: 1,
          name: 'Chapter',
          type: mangafireChapterGroupTagType,
          count: 0,
        ),
      );
    }
    if (hasVolumeGroup) {
      tags.add(
        const Tag(
          id: 2,
          name: 'Volume',
          type: mangafireChapterGroupTagType,
          count: 0,
        ),
      );
    }

    return tags;
  }

  Chapter? _mapDetailChapterItem(
    dom.Element item, {
    required String scanGroup,
    required String fallbackLanguage,
  }) {
    final anchor = item.querySelector('a');
    final href = _attr(anchor, 'href');
    if (href.isEmpty) {
      return null;
    }

    final spans = anchor?.querySelectorAll('span') ?? const <dom.Element>[];
    final titleText = spans.isNotEmpty ? spans.first.text.trim() : '';
    final dateText = spans.length > 1 ? spans[1].text.trim() : '';
    final number = item.attributes['data-number']?.trim() ?? '';
    final language = resolveMangaFireReaderLanguage(href) ?? fallbackLanguage;

    return Chapter(
      id: href,
      title: _buildChapterTitle(
        label: scanGroup,
        number: number,
        titleText: titleText,
      ),
      url: href,
      uploadDate: _parseDate(dateText),
      language: language,
      scanGroup: scanGroup,
    );
  }

  Future<List<Chapter>> _fetchChaptersFromAjax({
    required String detailUrl,
    required List<({String language, String type})> requests,
    Set<String>? seenIds,
  }) async {
    final contentIdStr = _contentIdFromUrl(detailUrl);
    if (contentIdStr == null || contentIdStr.isEmpty) {
      return const <Chapter>[];
    }

    final parts = contentIdStr.split('.');
    final ajaxId = parts.length > 1 ? parts.last : contentIdStr;
    final chapters = <Chapter>[];
    final knownIds = seenIds ?? <String>{};

    for (final request in requests) {
      final ajaxUrl = _absoluteUrl(
        '/ajax/manga/$ajaxId/${request.type}/${request.language}',
      );
      Map<String, dynamic> ajaxRes;
      try {
        ajaxRes = await _getJson(ajaxUrl);
      } on DioException catch (error) {
        _logger.w(
          'MangaFire chapter AJAX failed for $ajaxUrl '
          '(${error.response?.statusCode})',
        );
        continue;
      } catch (_) {
        _logger.w('MangaFire chapter AJAX failed for $ajaxUrl');
        continue;
      }

      final resultStr = ajaxRes['result'] as String?;
      if (resultStr == null || resultStr.isEmpty) {
        _logger.w('MangaFire chapter AJAX returned empty result for $ajaxUrl');
        continue;
      }

      final doc = html.parse(resultStr);
      var items = request.type == 'volume'
          ? doc.querySelectorAll('.vol-list .item')
          : doc.querySelectorAll('li.item');
      if (items.isEmpty) {
        items = doc.querySelectorAll('.item');
      }

      for (final item in items) {
        final chapter = _mapDetailChapterItem(
          item,
          scanGroup: request.type == 'volume' ? 'Volume' : 'Chapter',
          fallbackLanguage: request.language,
        );
        if (chapter == null || !knownIds.add(chapter.id)) {
          continue;
        }
        chapters.add(chapter);
      }
    }

    if (chapters.isEmpty) {
      _logger.w('MangaFire chapter parsing returned no entries for $detailUrl');
    }

    return chapters;
  }

  String _buildChapterTitle({
    required String label,
    required String number,
    required String titleText,
  }) {
    final cleanLabel = label.trim().isEmpty ? 'Chapter' : label.trim();
    final cleanTitle = titleText.trim();
    if (cleanTitle.isEmpty) {
      return number.isEmpty ? cleanLabel : '$cleanLabel $number';
    }

    final lowerTitle = cleanTitle.toLowerCase();
    final lowerLabel = cleanLabel.toLowerCase();
    if (lowerTitle.contains(lowerLabel == 'volume' ? 'vol' : 'chap')) {
      return cleanTitle;
    }

    return number.isEmpty
        ? '$cleanLabel: $cleanTitle'
        : '$cleanLabel $number: $cleanTitle';
  }

  Content? _mapListItem(
    dom.Element element, {
    required String sourceLanguage,
  }) {
    final anchor = element.querySelector('.info > a');
    final href = _attr(anchor, 'href');
    final contentId = _contentIdFromUrl(href);
    if (contentId == null || contentId.isEmpty) {
      return null;
    }

    final title = _text(anchor);
    final coverUrl = _attr(element.querySelector('img'), 'src');
    final typeText = _text(element.querySelector('.type'));
    final latestChapterText =
        _text(element.querySelector('ul.content[data-name="chap"] li a span'));
    final subtitle = _joinSubtitleParts(<String>[
      if (typeText.isNotEmpty) typeText,
      if (latestChapterText.isNotEmpty) latestChapterText,
    ]);

    return Content(
      id: contentId,
      sourceId: 'mangafire',
      title: title.isNotEmpty ? title : contentId,
      coverUrl: coverUrl,
      tags: const <Tag>[],
      artists: const <String>[],
      characters: const <String>[],
      parodies: const <String>[],
      groups: const <String>[],
      language: sourceLanguage,
      pageCount: 0,
      imageUrls: const <String>[],
      uploadDate: DateTime.now(),
      subTitle: subtitle,
      url: href,
      contentType: _mapContentType(typeText),
      status: ContentStatus.unknown,
      sourceUrl: _absoluteUrl(href),
    );
  }

  List<String> _parseReaderImages(Map<String, dynamic> payload) {
    final result = payload['result'];
    if (result is! Map<String, dynamic>) {
      return const <String>[];
    }
    final images = result['images'];
    if (images is! List) {
      return const <String>[];
    }

    return images
        .map<String?>((entry) {
          if (entry is! List || entry.isEmpty) {
            return null;
          }
          final url = entry.first?.toString() ?? '';
          if (url.isEmpty) {
            return null;
          }
          final offset =
              entry.length > 2 ? int.tryParse('${entry[2]}') ?? 0 : 0;
          if (offset > 0) {
            return '$url#scrambled_$offset';
          }
          return url;
        })
        .whereType<String>()
        .toList(growable: false);
  }

  Future<String?> _getHtml(String url) {
    return _rateLimiter.execute(() async {
      try {
        final response = await _dio.get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            headers: _htmlRequestHeaders(referer: url),
          ),
        );
        return normalizeMangaFireHtmlResponse(response.data);
      } on DioException catch (error) {
        _logger.w(
            'MangaFire HTML request failed: $url (${error.response?.statusCode})');
        return null;
      }
    });
  }

  Future<String?> _getHtmlWithRetry({
    required String url,
    required MangaFireVrfScope scope,
    required String cacheKey,
    required Future<String?> Function() onRetry,
    required String Function(String token) rebuildUrl,
  }) async {
    final first = await _getHtml(url);
    if (first != null) {
      return first;
    }

    final refreshed = await onRetry();
    if (refreshed == null || refreshed.isEmpty) {
      _vrfCache.invalidate(scope: scope, key: cacheKey);
      return null;
    }
    return _getHtml(rebuildUrl(refreshed));
  }

  Future<Map<String, dynamic>> _getJson(String url) {
    return _rateLimiter.execute(() async {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: _requestHeaders(referer: _baseUrl),
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is String && data.isNotEmpty) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    });
  }

  Future<Map<String, dynamic>> _getJsonWithRetry({
    required String url,
    required MangaFireVrfScope scope,
    required String cacheKey,
    required Future<String?> Function() onRetry,
  }) async {
    try {
      return await _getJson(url);
    } on DioException catch (error) {
      if (error.response?.statusCode != 403) {
        rethrow;
      }
    }

    _vrfCache.invalidate(scope: scope, key: cacheKey);
    final refreshedUrl = await onRetry();
    if (refreshedUrl == null || refreshedUrl.isEmpty) {
      return <String, dynamic>{};
    }
    _vrfCache.set(scope: scope, key: cacheKey, token: refreshedUrl);
    return _getJson(refreshedUrl);
  }

  Map<String, dynamic> _requestHeaders({required String referer}) {
    return <String, dynamic>{
      'Referer': referer,
      'X-Requested-With': 'XMLHttpRequest',
      if (!_dio.options.headers.containsKey('Accept'))
        'Accept': 'application/json, text/plain, */*',
    };
  }

  Map<String, dynamic> _htmlRequestHeaders({required String referer}) {
    return <String, dynamic>{
      'Referer': referer,
      if (!_dio.options.headers.containsKey('Accept'))
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };
  }

  String _absoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return Uri.parse(_baseUrl).resolve(url).toString();
  }

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String? _contentIdFromUrl(String url) {
    final uri = Uri.tryParse(_absoluteUrl(url));
    if (uri == null) {
      return null;
    }
    final segments = uri.pathSegments;
    final mangaIndex = segments.indexOf('manga');
    if (mangaIndex >= 0 && mangaIndex + 1 < segments.length) {
      return segments[mangaIndex + 1];
    }
    return segments.isNotEmpty ? segments.last : null;
  }

  String? _readerUrlFromChapterId(String chapterId) {
    if (chapterId.startsWith('/read/')) {
      return chapterId;
    }
    final parsed = Uri.tryParse(chapterId);
    if (parsed != null && parsed.path.startsWith('/read/')) {
      return parsed.path;
    }
    return null;
  }

  String _cleanDescription(dom.Document document) {
    final synopsis = document.querySelector('#synopsis .modal-content');
    if (synopsis == null) {
      return '';
    }
    final base = synopsis.text.trim();
    final parts = <String>[
      if (base.isNotEmpty) base,
    ];
    final alt = _text(document.querySelector('h6'));
    if (alt.isNotEmpty) {
      parts.add('Alternative title: $alt');
    }
    final published = _extractMetaValue(document, 'Published');
    if (published.isNotEmpty) {
      parts.add('Published: $published');
    }
    return parts.join('\n\n');
  }

  String _extractMetaValue(dom.Document document, String label) {
    for (final element
        in document.querySelectorAll('.meta span, .meta a, .meta div')) {
      final text = element.text.trim();
      if (!text.toLowerCase().startsWith('${label.toLowerCase()}:')) {
        continue;
      }
      return text.substring(label.length + 1).trim();
    }
    return '';
  }

  String _extractRating(dom.Document document) {
    for (final element
        in document.querySelectorAll('.min-info span, .rating-box *')) {
      final text = element.text.trim();
      if (text.contains('MAL')) {
        return text.replaceAll('MAL', '').trim();
      }
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(text)) {
        return text;
      }
    }
    return '';
  }

  String _joinSubtitleParts(List<String> parts) {
    final filtered =
        parts.where((part) => part.trim().isNotEmpty).toList(growable: false);
    return filtered.isEmpty ? '' : filtered.join(' • ');
  }

  String _text(dom.Element? element) => element?.text.trim() ?? '';

  String _attr(dom.Element? element, String name) {
    if (element == null) {
      return '';
    }
    final raw = _rawAttr(element, name);
    if (raw.isEmpty) {
      return '';
    }
    return _absoluteUrl(raw);
  }

  String _rawAttr(dom.Element? element, String name) {
    if (element == null) {
      return '';
    }
    return element.attributes[name] ??
        element.attributes['data-$name'] ??
        element.attributes['abs:$name'] ??
        '';
  }

  DateTime? _parseDate(String raw) {
    final match = RegExp(r'^([A-Za-z]{3})\s+(\d{1,2}),\s*(\d{4})$')
        .firstMatch(raw.trim());
    if (match == null) {
      return null;
    }
    const months = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final month = months[match.group(1)!.toLowerCase()];
    final day = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (month == null || day == null || year == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  ContentType _mapContentType(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'manga':
        return ContentType.manga;
      case 'manhwa':
        return ContentType.manhwa;
      case 'manhua':
        return ContentType.manhua;
      case 'doujinshi':
        return ContentType.doujinshi;
      default:
        return ContentType.unknown;
    }
  }

  ContentStatus _mapStatus(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'releasing':
        return ContentStatus.ongoing;
      case 'completed':
        return ContentStatus.publishingFinished;
      case 'on_hiatus':
        return ContentStatus.onHiatus;
      case 'discontinued':
        return ContentStatus.cancelled;
      default:
        return ContentStatus.unknown;
    }
  }

  Content _emptyContent(String contentId) {
    return Content(
      id: contentId,
      sourceId: 'mangafire',
      title: contentId,
      coverUrl: '',
      tags: const <Tag>[],
      artists: const <String>[],
      characters: const <String>[],
      parodies: const <String>[],
      groups: const <String>[],
      language: 'en',
      pageCount: 0,
      imageUrls: const <String>[],
      uploadDate: DateTime.now(),
    );
  }
}
