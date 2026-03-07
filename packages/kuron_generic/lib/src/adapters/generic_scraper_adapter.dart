/// Generic scraper adapter — handles HTML scraping sources.
///
/// All extraction behaviour is driven purely by the source config JSON; the
/// adapter has no knowledge of any specific source's CSS selectors or field
/// naming conventions.
///
/// ### Config schema expected by this adapter
///
/// Each **list URL pattern** (home, search, genreSearch, …) is either a plain
/// String (URL only) or a Map with at minimum a `"url"` key and a `"list"`
/// sub-block:
///
/// ```json
/// "home": {
///   "url": "/",
///   "list": {
///     "container": ".utao",
///     "fields": {
///       "id":       { "selector": "a.series", "attribute": "href", "transform": "slug" },
///       "title":    { "selector": ".luf > a > h4" },
///       "coverUrl": { "selector": "img.ts-post-image", "attribute": "src" }
///     },
///     "pagination": { "next": ".hpage a.r", "alt": ".pagination .next.page-numbers" }
///   }
/// }
/// ```
///
/// Patterns may declare `"inherits": "home"` to copy the parent pattern's
/// `"list"` block (then optionally override individual keys locally).
///
/// The **detail** selectors live in `scraper.selectors.detail`:
///
/// ```json
/// "detail": {
///   "fields": {
///     "title":    { "selector": ".entry-title" },
///     "coverUrl": { "selector": ".thumb img", "attribute": "src" },
///     "tags":     { "selector": ".seriestugenre a", "multi": true }
///   },
///   "chapters": {
///     "container": "#chapterlist li",
///     "fields": {
///       "id":    { "selector": ".chbox a", "attribute": "href", "transform": "slug" },
///       "title": { "selector": ".chapternum" },
///       "date":  { "selector": ".chapterdate" }
///     }
///   }
/// }
/// ```
///
/// The **reader** config (for chapter image extraction) lives in
/// `scraper.selectors.reader`:
///
/// ```json
/// "reader": {
///   "tsReaderRegex": "ts_reader\\.run\\((.*?)\\);",
///   "container": "#readerarea",
///   "images":    { "selector": "img", "attribute": "src" },
///   "nav": { "next": "a.next-chapter", "prev": "a.prev-chapter" }
/// }
/// ```
///
/// ### URL template placeholders
/// `{page}`, `{query}` (URI-encoded), `{tag}` (first included tag, kebab-case).
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';

import '../mappers/generic_content_mapper.dart';
import '../models/source_config_runtime.dart';
import '../parsers/generic_html_parser.dart';
import '../url_builder/generic_url_builder.dart';
import 'generic_adapter.dart';

class GenericScraperAdapter implements GenericAdapter {
  final Dio _dio;
  final GenericUrlBuilder _urlBuilder;
  final GenericHtmlParser _parser;
  final Logger _logger;
  final String _sourceId;

  GenericScraperAdapter({
    required Dio dio,
    required GenericUrlBuilder urlBuilder,
    required GenericHtmlParser parser,
    required Logger logger,
    required String sourceId,
  })  : _dio = dio,
        _urlBuilder = urlBuilder,
        _parser = parser,
        _logger = logger,
        _sourceId = sourceId;

  // ── search ─────────────────────────────────────────────────────────────────

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) async {
    final scraper = rawConfig['scraper'] as Map<String, dynamic>?;
    if (scraper == null) {
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }
    final urlPatternsCfg =
        (scraper['urlPatterns'] as Map?)?.cast<String, dynamic>() ?? {};

    // ── Raw-param mode (from DynamicFormSearchUI) ──────────────────────────
    // When query starts with "raw:", the form supplied all query-params
    // directly. We build the URL from the searchForm.urlPattern base path and
    // append the raw params instead of using the {query} template substitution.
    if (filter.query.startsWith('raw:')) {
      return _searchRaw(
        rawParams: filter.query.substring(4),
        page: filter.page,
        rawConfig: rawConfig,
        scraper: scraper,
        urlPatternsCfg: urlPatternsCfg,
      );
    }

    // 1) Genre/tag filter → genreSearch
    // 2) Non-empty text   → search
    // 3) Empty query p>1  → homePage  (if defined)
    // 4) Empty query p=1  → home
    final String patternKey;
    if (filter.includeTags.isNotEmpty &&
        urlPatternsCfg.containsKey('genreSearch')) {
      patternKey = 'genreSearch';
    } else if (filter.query.trim().isNotEmpty) {
      patternKey = 'search';
    } else {
      patternKey = filter.page > 1 && urlPatternsCfg.containsKey('homePage')
          ? 'homePage'
          : 'home';
    }

    if (!urlPatternsCfg.containsKey(patternKey)) {
      _logger.w('$_sourceId: URL pattern "$patternKey" not configured');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    final (url, listConfig) = _resolvePattern(
      scraper,
      patternKey,
      filter: filter,
    );
    if (url.isEmpty) {
      _logger.w('$_sourceId: empty URL for pattern "$patternKey"');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }
    if (listConfig == null) {
      _logger
          .w('$_sourceId: no "list" block configured in pattern "$patternKey"');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    _logger.d('$_sourceId scraper [$patternKey]: $url');
    return _fetchListPage(url, listConfig,
        defaultLanguage: rawConfig['defaultLanguage'] as String?);
  }

  /// Handle `raw:` query format produced by [DynamicFormSearchUI].
  ///
  /// Parses the raw query-param string and builds the final URL by taking the
  /// base path of the appropriate URL pattern (strip any `?…` template vars)
  /// and appending all raw params + the page param.
  Future<AdapterSearchResult> _searchRaw({
    required String rawParams,
    required int page,
    required Map<String, dynamic> rawConfig,
    required Map<String, dynamic> scraper,
    required Map<String, dynamic> urlPatternsCfg,
  }) async {
    // Determine which URL pattern to use from searchForm config.
    final searchFormCfg = rawConfig['searchForm'] as Map<String, dynamic>?;
    final patternKey = (searchFormCfg?['urlPattern'] as String?) ?? 'search';
    final formParamsCfg =
        (searchFormCfg?['params'] as Map?)?.cast<String, dynamic>() ?? {};

    if (!urlPatternsCfg.containsKey(patternKey)) {
      _logger.w('$_sourceId: raw search — URL pattern "$patternKey" not found');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    // Parse raw params (e.g. "s=manga&status=ongoing")
    final rawMap = <String, String>{};
    for (final pair in rawParams.split('&')) {
      if (pair.isEmpty) continue;
      final idx = pair.indexOf('=');
      if (idx < 0) continue;
      rawMap[Uri.decodeComponent(pair.substring(0, idx))] =
          Uri.decodeComponent(pair.substring(idx + 1));
    }

    // Resolve list config from the URL pattern (for pagination/selector info).
    // We use a dummy SearchFilter to call _resolvePattern just for the listConfig.
    final (_, listConfig) = _resolvePattern(
      scraper,
      patternKey,
      filter: SearchFilter(query: '', page: page),
    );
    if (listConfig == null) {
      _logger.w(
          '$_sourceId: raw search — no list config in pattern "$patternKey"');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    // Derive the page param name from searchForm.params entry of type "page".
    String pageParam = 'paged';
    for (final entry in formParamsCfg.entries) {
      final def = entry.value as Map<String, dynamic>?;
      if ((def?['type'] as String?) == 'page') {
        pageParam = (def?['queryParam'] as String?) ?? pageParam;
        break;
      }
    }

    // Build the base URL path — strip the query-string portion of the template
    // so we append our own params cleanly.
    final patternValue = urlPatternsCfg[patternKey];
    String basePath = '';
    if (patternValue is String) {
      basePath = patternValue;
    } else if (patternValue is Map<String, dynamic>) {
      basePath = (patternValue['url'] as String?) ?? '';
    }
    // Remove everything from '?' onwards (we'll append our own query string).
    final qIdx = basePath.indexOf('?');
    if (qIdx >= 0) basePath = basePath.substring(0, qIdx);
    // Substitute {page} if present in path (some sources embed page in path).
    basePath = basePath.replaceAll('{page}', page.toString());

    // Assemble the final query string: raw user params + page.
    final queryParts = <String>[];
    rawMap.forEach((k, v) => queryParts.add('$k=${Uri.encodeComponent(v)}'));
    queryParts.add('$pageParam=${Uri.encodeComponent(page.toString())}');

    final baseUrl = _urlBuilder.resolve(basePath, {});
    final finalUrl =
        queryParts.isEmpty ? baseUrl : '$baseUrl?${queryParts.join('&')}';

    _logger.d('$_sourceId scraper [raw/$patternKey]: $finalUrl');
    return _fetchListPage(finalUrl, listConfig,
        defaultLanguage: rawConfig['defaultLanguage'] as String?);
  }

  // ── fetchDetail ────────────────────────────────────────────────────────────

  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final scraper = rawConfig['scraper'] as Map<String, dynamic>?;
    final urlPatternsCfg =
        (scraper?['urlPatterns'] as Map<String, dynamic>?) ?? {};
    final detailTemplate = _patternUrl(urlPatternsCfg, 'detail');
    if (detailTemplate.isEmpty) {
      _logger.w('$_sourceId: no scraper detail URL pattern configured');
      return AdapterDetailResult(
          content: _emptyContent(contentId), imageUrls: []);
    }

    final url = _urlBuilder.buildDetailUrl(detailTemplate, contentId);
    _logger.d('$_sourceId scraper detail: $url');

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final doc = _parser.parse(response.data ?? '');

      final selectors = (scraper?['selectors'] as Map<String, dynamic>?) ?? {};
      final detailCfg = (selectors['detail'] as Map<String, dynamic>?) ?? {};
      final fieldsConfig = (detailCfg['fields'] as Map<String, dynamic>?) ?? {};

      final fields = _extractDocumentFields(doc, fieldsConfig);

      // ── Chapters ──────────────────────────────────────────────────────────
      List<Chapter>? chapters;
      final chaptersCfg = detailCfg['chapters'] as Map<String, dynamic>?;
      if (chaptersCfg != null) {
        final containerSel = chaptersCfg['container'] as String?;
        final chFieldsCfg =
            (chaptersCfg['fields'] as Map<String, dynamic>?) ?? {};
        if (containerSel != null) {
          final chEls = _parser.selectAll(doc, containerSel);
          chapters = chEls.map((el) {
            final chFields = _extractElementFields(el, chFieldsCfg);
            return GenericContentMapper.toChapter(chFields);
          }).toList();
          _logger.d(
              '$_sourceId: extracted ${chapters.length} chapters for $contentId');
        }
      }

      var content = GenericContentMapper.toDetail(
        contentId,
        fields,
        sourceId: _sourceId,
        chapters: chapters,
      );

      final defaultLang = rawConfig['defaultLanguage'] as String?;
      if (defaultLang != null &&
          (content.language.isEmpty || content.language == 'unknown')) {
        content = content.copyWith(language: defaultLang);
      }

      return AdapterDetailResult(content: content, imageUrls: const []);
    } catch (e) {
      _logger.e('$_sourceId scraper detail failed for $contentId', error: e);
      return AdapterDetailResult(
          content: _emptyContent(contentId), imageUrls: []);
    }
  }

  // ── fetchRelated / fetchComments ───────────────────────────────────────────

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async =>
      const [];

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async =>
      const [];

  // ── fetchChapterImages ─────────────────────────────────────────────────────

  @override
  Future<ChapterData?> fetchChapterImages(
    String chapterId,
    Map<String, dynamic> rawConfig,
  ) async {
    final scraper = rawConfig['scraper'] as Map<String, dynamic>?;
    final urlPatternsCfg =
        (scraper?['urlPatterns'] as Map?)?.cast<String, dynamic>() ?? {};
    final chapterTemplate = _patternUrl(urlPatternsCfg, 'chapter');
    if (chapterTemplate.isEmpty) return null;

    final url = _urlBuilder.buildDetailUrl(chapterTemplate, chapterId);
    _logger.d('$_sourceId scraper chapter: $url');

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final htmlContent = response.data ?? '';

      final selectors = (scraper?['selectors'] as Map<String, dynamic>?) ?? {};
      final readerConfig = selectors['reader'] as Map<String, dynamic>?;
      if (readerConfig == null) return null;

      List<String> imageUrls = [];
      String? nextId;
      String? prevId;

      // 1. Try ts_reader regex extraction first.
      final regexStr = readerConfig['tsReaderRegex'] as String?;
      if (regexStr != null && regexStr.isNotEmpty) {
        final regex = RegExp(regexStr, dotAll: true);
        final match = regex.firstMatch(htmlContent);
        if (match != null) {
          final jsonStr =
              match.groupCount > 0 ? match.group(1) : match.group(0);
          if (jsonStr != null) {
            final cleanJson =
                jsonStr.replaceAll(r'\/', '/').replaceAll(r'\"', '"');
            try {
              final data = json.decode(cleanJson) as Map<String, dynamic>;
              final sources = data['sources'] as List<dynamic>?;
              if (sources != null && sources.isNotEmpty) {
                final first = sources[0] as Map<String, dynamic>;
                final images = first['images'] as List<dynamic>?;
                if (images != null) {
                  imageUrls = images
                      .map((img) => img.toString())
                      .where((u) => u.isNotEmpty)
                      .toList();
                }
              }
              final prevUrlRaw = data['prevUrl'] as String?;
              final nextUrlRaw = data['nextUrl'] as String?;
              if (prevUrlRaw != null && prevUrlRaw.isNotEmpty) {
                prevId = _extractSlugFromUrl(prevUrlRaw.replaceAll(r'\/', '/'));
              }
              if (nextUrlRaw != null && nextUrlRaw.isNotEmpty) {
                nextId = _extractSlugFromUrl(nextUrlRaw.replaceAll(r'\/', '/'));
              }
            } catch (e) {
              _logger.w('$_sourceId tsReaderRegex JSON parse failed', error: e);
            }
          }
        }
      }

      final doc = _parser.parse(htmlContent);

      // 2. DOM fallback for images.
      if (imageUrls.isEmpty) {
        final containerSel = readerConfig['container'] as String?;
        if (containerSel != null) {
          final imagesDef = readerConfig['images'];
          if (imagesDef != null) {
            final defMap = _toDefMap(imagesDef);
            if (defMap != null) {
              final sel = _fieldDefToSelector(defMap);
              if (sel != null) imageUrls = _parser.extractList(doc, sel);
            }
          }
        }
      }

      // 3. DOM fallback for navigation via reader.nav.{next,prev}.
      final navCfg = readerConfig['nav'] as Map<String, dynamic>?;
      if (nextId == null) {
        final nextSel = navCfg?['next'] as String?;
        if (nextSel != null) {
          final href = _parser.extractString(
              doc, FieldSelector(selector: nextSel, attribute: 'href'));
          if (href != null && href.isNotEmpty && !href.startsWith('#')) {
            nextId = _extractSlugFromUrl(href);
          }
        }
      }
      if (prevId == null) {
        final prevSel = navCfg?['prev'] as String?;
        if (prevSel != null) {
          final href = _parser.extractString(
              doc, FieldSelector(selector: prevSel, attribute: 'href'));
          if (href != null && href.isNotEmpty && !href.startsWith('#')) {
            prevId = _extractSlugFromUrl(href);
          }
        }
      }

      return ChapterData(
        images: imageUrls,
        nextChapterId: nextId,
        prevChapterId: prevId,
      );
    } catch (e) {
      _logger.e('$_sourceId scraper chapter fetch failed for $chapterId',
          error: e);
      return null;
    }
  }

  // ── Private: pattern resolution ────────────────────────────────────────────

  /// Resolve a named URL pattern into `(resolvedUrl, listConfig)`.
  ///
  /// - Plain String → URL only; `listConfig` is `null`.
  /// - Object with `"list"` key → URL + list config.
  /// - `"inherits"` borrows parent's `"list"` block; local overrides are merged.
  (String, Map<String, dynamic>?) _resolvePattern(
    Map<String, dynamic> scraper,
    String patternKey, {
    required SearchFilter filter,
  }) {
    final urlPatternsCfg =
        (scraper['urlPatterns'] as Map?)?.cast<String, dynamic>() ?? {};
    final patternValue = urlPatternsCfg[patternKey];

    String urlTemplate;
    Map<String, dynamic>? listConfig;

    if (patternValue is String) {
      urlTemplate = patternValue;
      listConfig = null;
    } else if (patternValue is Map<String, dynamic>) {
      urlTemplate = patternValue['url'] as String? ?? '';

      Map<String, dynamic>? parentList;
      final parentKey = patternValue['inherits'] as String?;
      if (parentKey != null) {
        final parentVal = urlPatternsCfg[parentKey];
        if (parentVal is Map<String, dynamic>) {
          parentList = parentVal['list'] as Map<String, dynamic>?;
        }
      }

      final localList = patternValue['list'] as Map<String, dynamic>?;

      if (parentList != null && localList != null) {
        // Shallow merge then deep-merge fields + pagination sub-blocks.
        listConfig = <String, dynamic>{...parentList, ...localList};
        final pf = parentList['fields'] as Map<String, dynamic>?;
        final lf = localList['fields'] as Map<String, dynamic>?;
        if (pf != null && lf != null) {
          listConfig['fields'] = <String, dynamic>{...pf, ...lf};
        }
        final pp = parentList['pagination'] as Map<String, dynamic>?;
        final lp = localList['pagination'] as Map<String, dynamic>?;
        if (pp != null && lp != null) {
          listConfig['pagination'] = <String, dynamic>{...pp, ...lp};
        }
      } else {
        listConfig = localList ?? parentList;
      }
    } else {
      return ('', null);
    }

    final params = <String, String>{
      'page': filter.page.toString(),
      'query': Uri.encodeQueryComponent(filter.query),
      'tag': filter.includeTags.isNotEmpty
          ? filter.includeTags.first.name.toLowerCase().replaceAll(' ', '-')
          : '',
    };
    return (_urlBuilder.resolve(urlTemplate, params), listConfig);
  }

  // ── Private: list page fetching ────────────────────────────────────────────

  Future<AdapterSearchResult> _fetchListPage(
    String url,
    Map<String, dynamic> listConfig, {
    String? defaultLanguage,
  }) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final doc = _parser.parse(response.data ?? '');

      final container = listConfig['container'] as String?;
      final fieldsConfig =
          (listConfig['fields'] as Map<String, dynamic>?) ?? {};
      final paginationConfig =
          (listConfig['pagination'] as Map<String, dynamic>?) ?? {};

      final items = <Content>[];
      if (container != null) {
        for (final el in _parser.selectAll(doc, container)) {
          final fields = _extractElementFields(el, fieldsConfig);
          var item =
              GenericContentMapper.toListItem(fields, sourceId: _sourceId);
          if (defaultLanguage != null &&
              (item.language.isEmpty || item.language == 'unknown')) {
            item = item.copyWith(language: defaultLanguage);
          }
          if (item.id.isNotEmpty) items.add(item);
        }
      }

      final nextSel = paginationConfig['next'] as String?;
      final altSel = paginationConfig['alt'] as String?;
      final hasNext =
          (nextSel != null && _parser.selectAll(doc, nextSel).isNotEmpty) ||
              (altSel != null && _parser.selectAll(doc, altSel).isNotEmpty);

      return AdapterSearchResult(items: items, hasNextPage: hasNext);
    } catch (e) {
      _logger.e('$_sourceId scraper list fetch failed: $url', error: e);
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }
  }

  // ── Private: field extraction ──────────────────────────────────────────────

  /// Extract a fields map from a full [dom.Document] (detail pages).
  Map<String, dynamic> _extractDocumentFields(
    dom.Document doc,
    Map<String, dynamic> fieldsConfig,
  ) {
    final result = <String, dynamic>{};
    for (final entry in fieldsConfig.entries) {
      final defMap = _toDefMap(entry.value);
      if (defMap == null) continue;

      final multi = defMap['multi'] as bool? ?? false;
      final transform = defMap['transform'] as String?;
      final sel = _fieldDefToSelector(defMap);
      if (sel == null) continue;

      if (multi) {
        result[entry.key] = _parser.extractList(doc, sel);
      } else {
        var value = _parser.extractString(doc, sel) ?? '';
        if (transform == 'slug' && value.isNotEmpty) {
          value = _extractSlugFromUrl(value);
        }
        result[entry.key] = value;
      }
    }
    return result;
  }

  /// Extract a fields map from a single [dom.Element] (list items / chapters).
  Map<String, dynamic> _extractElementFields(
    dom.Element el,
    Map<String, dynamic> fieldsConfig,
  ) {
    final result = <String, dynamic>{};
    for (final entry in fieldsConfig.entries) {
      final defMap = _toDefMap(entry.value);
      if (defMap == null) continue;

      final multi = defMap['multi'] as bool? ?? false;
      final transform = defMap['transform'] as String?;
      final sel = _fieldDefToSelector(defMap);
      if (sel == null) continue;

      if (multi) {
        result[entry.key] = el
            .querySelectorAll(sel.selector)
            .map((c) => sel.attribute != null
                ? (c.attributes[sel.attribute] ?? '')
                : c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        var value = _parser.extractFromElement(el, sel) ?? '';
        if (transform == 'slug' && value.isNotEmpty) {
          value = _extractSlugFromUrl(value);
        }
        result[entry.key] = value;
      }
    }
    return result;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// URL string from a urlPatterns entry (plain String or `{url:…}` Map).
  String _patternUrl(Map<String, dynamic> urlPatternsCfg, String key) {
    final val = urlPatternsCfg[key];
    if (val is String) return val;
    if (val is Map<String, dynamic>) return val['url'] as String? ?? '';
    return '';
  }

  /// Normalise a field definition value to `Map<String, dynamic>`.
  Map<String, dynamic>? _toDefMap(dynamic def) {
    if (def is Map<String, dynamic>) return def;
    if (def is String) return <String, dynamic>{'selector': def};
    return null;
  }

  /// Convert a field definition map to a [FieldSelector].
  FieldSelector? _fieldDefToSelector(Map<String, dynamic> def) {
    final selector = def['selector'] as String?;
    if (selector == null || selector.isEmpty) return null;
    return FieldSelector(
      selector: selector,
      attribute: def['attribute'] as String?,
      type: (def['type'] as String?) ?? 'css',
      regex: def['regex'] as String?,
      fallback: def['fallback'] as String?,
    );
  }

  Content _emptyContent(String id) => Content(
        id: id,
        sourceId: _sourceId,
        title: '',
        coverUrl: '',
        tags: const [],
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'unknown',
        pageCount: 0,
        imageUrls: const [],
        uploadDate: DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Extract the last meaningful path slug from a URL.
  String _extractSlugFromUrl(String url) {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        final mangaIndex = segments.indexOf('manga');
        if (mangaIndex != -1 && mangaIndex + 1 < segments.length) {
          return segments[mangaIndex + 1];
        }
        return segments.last;
      }
    } catch (_) {}
    final mangaRegex = RegExp(r'/manga/([^/]+)');
    final chapterRegex = RegExp(r'/([^/]+?-chapter-[\d.-]+)');
    var match = mangaRegex.firstMatch(url);
    if (match != null) return match.group(1) ?? '';
    match = chapterRegex.firstMatch(url);
    if (match != null) return match.group(1) ?? '';
    return '';
  }
}
