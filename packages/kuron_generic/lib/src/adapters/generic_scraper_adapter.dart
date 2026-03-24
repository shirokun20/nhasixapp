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

    // 1) Genre/tag filter → genreSearch / genreSearchPage
    // 2) Non-empty text   → search / searchPage
    // 3) Empty query p>1  → homePage (if defined)
    // 4) Empty query p=1  → home
    final String patternKey;
    if (filter.includeTags.isNotEmpty &&
        urlPatternsCfg.containsKey('genreSearch')) {
      patternKey =
          filter.page > 1 && urlPatternsCfg.containsKey('genreSearchPage')
              ? 'genreSearchPage'
              : 'genreSearch';
    } else if (filter.query.trim().isNotEmpty) {
      patternKey = filter.page > 1 && urlPatternsCfg.containsKey('searchPage')
          ? 'searchPage'
          : 'search';
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
    final basePatternKey =
        (searchFormCfg?['urlPattern'] as String?) ?? 'search';
    final formParamsCfg =
        (searchFormCfg?['params'] as Map?)?.cast<String, dynamic>() ?? {};

    // Prefer `{pattern}Page` variant for page > 1 when provided by config.
    final pagedPatternKey = '${basePatternKey}Page';
    final patternKey = page > 1 && urlPatternsCfg.containsKey(pagedPatternKey)
        ? pagedPatternKey
        : basePatternKey;

    if (!urlPatternsCfg.containsKey(patternKey)) {
      _logger.w('$_sourceId: raw search — URL pattern "$patternKey" not found');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    // Parse raw params (e.g. "s=manga&status=ongoing")
    final rawMap = <String, List<String>>{};
    for (final pair in rawParams.split('&')) {
      if (pair.isEmpty) continue;
      final idx = pair.indexOf('=');
      if (idx < 0) continue;
      final key = Uri.decodeComponent(pair.substring(0, idx));
      final value = Uri.decodeComponent(pair.substring(idx + 1));
      rawMap.putIfAbsent(key, () => <String>[]).add(value);
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

    // Build the base URL path and keep template query defaults.
    final patternValue = urlPatternsCfg[patternKey];
    String basePath = '';
    String templateQuery = '';
    if (patternValue is String) {
      basePath = patternValue;
    } else if (patternValue is Map<String, dynamic>) {
      basePath = (patternValue['url'] as String?) ?? '';
    }

    // Extract template query (if any) so we can preserve required keys
    // like `title=` when caller raw params omit them.
    final qIdx = basePath.indexOf('?');
    if (qIdx >= 0) {
      templateQuery = basePath.substring(qIdx + 1);
      basePath = basePath.substring(0, qIdx);
    }
    final hasPageInPathTemplate = basePath.contains('{page}');
    // Substitute {page} if present in path (some sources embed page in path).
    basePath = basePath.replaceAll('{page}', page.toString());

    // Merge template query defaults with raw params (raw params take priority).
    // This keeps mandatory but empty params from template, e.g. `title=`.
    final mergedParams = <String, List<String>>{};
    if (templateQuery.isNotEmpty) {
      for (final pair in templateQuery.split('&')) {
        if (pair.isEmpty) continue;
        final idx = pair.indexOf('=');
        final key = idx < 0 ? pair : pair.substring(0, idx);
        if (key.isEmpty) continue;
        mergedParams[key] = <String>[''];
      }
    }
    mergedParams.addAll(rawMap);

    // Pagination is controlled by adapter/page argument. Avoid carrying a
    // stale `page` query from saved raw filters to prevent duplicate params.
    mergedParams.remove(pageParam);

    // Assemble final query string.
    final queryParts = <String>[];
    mergedParams.forEach((k, values) {
      for (var i = 0; i < values.length; i++) {
        var key = k;
        // WordPress-style paged routes sometimes expect indexed array keys
        // (e.g. genre[0]=anal) instead of repeated genre[]=anal pairs.
        if (page > 1 && key.endsWith('[]')) {
          key = '${key.substring(0, key.length - 2)}[$i]';
        }
        queryParts.add('$key=${_encodeRawQueryValue(key, values[i])}');
      }
    });

    // Only append page query param when actually paginating and path does not
    // already encode page (many WordPress routes reject `page=1`).
    if (page > 1 && !hasPageInPathTemplate) {
      queryParts.add('$pageParam=${Uri.encodeComponent(page.toString())}');
    }

    final baseUrl = _urlBuilder.resolve(basePath, {});
    final finalUrl =
        queryParts.isEmpty ? baseUrl : '$baseUrl?${queryParts.join('&')}';

    _logger.d('$_sourceId scraper [raw/$patternKey]: $finalUrl');
    return _fetchListPage(finalUrl, listConfig,
        defaultLanguage: rawConfig['defaultLanguage'] as String?);
  }

  String _encodeRawQueryValue(String key, String value) {
    // HentaiNexus query grammar treats '+' as word separator in q values.
    // Normalize user-entered '+' to spaces so query encoding emits '+'
    // (instead of '%2B') and matches the site's expected parser behavior.
    if (_sourceId == 'hentainexus' && key == 'q') {
      final normalized = value.replaceAll('+', ' ');
      return Uri.encodeQueryComponent(normalized);
    }

    return Uri.encodeComponent(value);
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
      final fieldsConfig =
          (detailCfg['fields'] as Map?)?.cast<String, dynamic>() ?? {};

      final fields = _extractDocumentFields(doc, fieldsConfig);

      // ── Chapters ──────────────────────────────────────────────────────────
      List<Chapter>? chapters;
      final chaptersCfg = detailCfg['chapters'] as Map<String, dynamic>?;
      if (chaptersCfg != null) {
        final containerSel = chaptersCfg['container'] as String?;
        final chFieldsCfg =
            (chaptersCfg['fields'] as Map?)?.cast<String, dynamic>() ?? {};
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
  ) async {
    final scraper = rawConfig['scraper'] as Map<String, dynamic>?;
    final urlPatternsCfg =
        (scraper?['urlPatterns'] as Map<String, dynamic>?) ?? {};
    final detailTemplate = _patternUrl(urlPatternsCfg, 'detail');
    if (detailTemplate.isEmpty) return const [];

    final selectors = (scraper?['selectors'] as Map<String, dynamic>?) ?? {};
    final relatedCfg = selectors['related'] as Map<String, dynamic>?;
    if (relatedCfg == null) return const [];

    final containerSel = relatedCfg['container'] as String?;
    final fieldsConfig =
        (relatedCfg['fields'] as Map<String, dynamic>?) ?? const {};
    if (containerSel == null || containerSel.isEmpty || fieldsConfig.isEmpty) {
      return const [];
    }

    final url = _urlBuilder.buildDetailUrl(detailTemplate, contentId);

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final doc = _parser.parse(response.data ?? '');
      final relatedEls = _parser.selectAll(doc, containerSel);
      if (relatedEls.isEmpty) return const [];

      final defaultLang = rawConfig['defaultLanguage'] as String?;
      final seenIds = <String>{};
      final related = <Content>[];

      for (final el in relatedEls) {
        final fields = _extractElementFields(el, fieldsConfig);
        var item = GenericContentMapper.toListItem(fields, sourceId: _sourceId);

        if (defaultLang != null &&
            (item.language.isEmpty || item.language == 'unknown')) {
          item = item.copyWith(language: defaultLang);
        }

        if (item.id.isEmpty ||
            item.id == contentId ||
            seenIds.contains(item.id)) {
          continue;
        }

        seenIds.add(item.id);
        related.add(item);
      }

      return related;
    } catch (e) {
      _logger.e('$_sourceId scraper related fetch failed for $contentId',
          error: e);
      return const [];
    }
  }

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final scraper = rawConfig['scraper'] as Map<String, dynamic>?;
    final urlPatternsCfg =
        (scraper?['urlPatterns'] as Map<String, dynamic>?) ?? {};
    final detailTemplate = _patternUrl(urlPatternsCfg, 'detail');
    if (detailTemplate.isEmpty) return const [];

    final selectors = (scraper?['selectors'] as Map<String, dynamic>?) ?? {};
    final detailCfg = selectors['detail'] as Map<String, dynamic>?;
    final commentsCfg = (detailCfg?['comments'] as Map<String, dynamic>?) ??
        (selectors['comments'] as Map<String, dynamic>?);
    if (commentsCfg == null) return const [];

    final url = _urlBuilder.buildDetailUrl(detailTemplate, contentId);
    String? cachedDetailHtml;

    // 1) API-first comments path (e.g. HentaiFox includes/comments.php)
    final commentsEndpoint = commentsCfg['endpoint'] as String?;
    if (commentsEndpoint != null && commentsEndpoint.isNotEmpty) {
      try {
        final galleryIdParam =
            (commentsCfg['galleryIdParam'] as String?) ?? 'gallery_id';
        final commentsUrl = _urlBuilder.resolve(commentsEndpoint, const {});

        // comments.php is protected by CSRF/session checks.
        final detailResponse = await _dio.get<String>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
        cachedDetailHtml = detailResponse.data;

        final csrfToken = _extractCsrfToken(cachedDetailHtml ?? '');
        final cookieHeader = _buildCookieHeader(detailResponse.headers);
        final requestHeaders = <String, dynamic>{
          'Referer': url,
          'Origin': Uri.parse(url).origin,
          'X-Requested-With': 'XMLHttpRequest',
          if (csrfToken != null && csrfToken.isNotEmpty)
            'X-CSRF-TOKEN': csrfToken,
          if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
        };

        final response = await _dio.post<dynamic>(
          commentsUrl,
          data: {galleryIdParam: contentId},
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.plain,
            headers: requestHeaders,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != 200) {
          _logger.w(
            '$_sourceId comments API returned ${response.statusCode} for $contentId',
          );
        }

        final apiComments = _parseApiComments(response.data);
        if (apiComments.isNotEmpty) {
          return apiComments;
        }
      } catch (e) {
        _logger.w('$_sourceId comments API failed for $contentId', error: e);
      }
    }

    // 2) HTML fallback comments path

    final containerSel = commentsCfg['container'] as String?;
    final fieldsConfig =
        (commentsCfg['fields'] as Map<String, dynamic>?) ?? const {};
    if (containerSel == null || containerSel.isEmpty || fieldsConfig.isEmpty) {
      return const [];
    }

    try {
      final html = cachedDetailHtml ??
          (await _dio.get<String>(
            url,
            options: Options(responseType: ResponseType.plain),
          ))
              .data ??
          '';
      final doc = _parser.parse(html);
      final commentEls = _parser.selectAll(doc, containerSel);
      if (commentEls.isEmpty) return const [];

      final seenIds = <String>{};
      final comments = <Comment>[];

      for (final el in commentEls) {
        final fields = _extractElementFields(el, fieldsConfig);

        final id = (fields['id']?.toString() ?? '').trim();
        final username = (fields['username']?.toString() ?? '').trim();
        final body = (fields['body']?.toString() ?? '').trim();
        if (id.isEmpty || username.isEmpty || body.isEmpty) continue;
        if (seenIds.contains(id)) continue;

        final avatarRaw = (fields['avatarUrl']?.toString() ?? '').trim();
        final avatar =
            avatarRaw.isEmpty ? null : _urlBuilder.resolve(avatarRaw, const {});
        final postDateRaw = (fields['postDate']?.toString() ?? '').trim();

        comments.add(
          Comment(
            id: id,
            username: username,
            body: body,
            avatarUrl: avatar,
            postDate: _parseRelativeOrAbsoluteDate(postDateRaw),
          ),
        );
        seenIds.add(id);
      }

      return comments;
    } catch (e) {
      _logger.e('$_sourceId scraper comments fetch failed for $contentId',
          error: e);
      return const [];
    }
  }

  String? _extractCsrfToken(String html) {
    if (html.isEmpty) return null;

    final doc = _parser.parse(html);
    final metaEls = _parser.selectAll(doc, 'meta[name="csrf-token"]');
    final token =
        metaEls.isNotEmpty ? metaEls.first.attributes['content']?.trim() : null;
    if (token != null && token.isNotEmpty) {
      return token;
    }

    return RegExp(
      '<meta\\s+name=["\\\']csrf-token["\\\']\\s+content=["\\\']([^"\\\']+)["\\\']',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
  }

  String _buildCookieHeader(Headers headers) {
    final setCookies = headers.map['set-cookie'];
    if (setCookies == null || setCookies.isEmpty) return '';

    final cookiePairs = setCookies
        .map((raw) => raw.split(';').first.trim())
        .where((pair) => pair.isNotEmpty)
        .toSet();

    return cookiePairs.join('; ');
  }

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
      if (imageUrls.isEmpty && readerConfig['mode'] == 'hentaifoxCdn') {
        // Prefer true full-res URL from /g/{id}/1/ page so extension follows
        // the actual gallery format (webp/jpg/jpeg/png).
        final readerPagePattern =
            (readerConfig['readerPageUrlPattern'] as String?) ?? '/g/{id}/1/';
        String? readerSampleUrl;
        var readerPageCount = 0;
        Map<int, String> readerExtByPage = const {};
        try {
          final readerPageUrl = _urlBuilder.resolve(
            readerPagePattern.replaceAll('{id}', chapterId),
            const {},
          );
          final readerResp = await _dio.get<String>(
            readerPageUrl,
            options: Options(responseType: ResponseType.plain),
          );
          final readerHtml = readerResp.data ?? '';
          final readerDoc = _parser.parse(readerHtml);
          readerExtByPage = _extractHentaiFoxExtensionsByPage(readerHtml);

          final readerImageSelector =
              (readerConfig['readerImageSelector'] as String?) ?? '#gimg';
          final readerImageAttr =
              (readerConfig['readerImageAttr'] as String?) ?? 'data-src';
          readerSampleUrl = _parser.extractString(
            readerDoc,
            FieldSelector(
              selector: readerImageSelector,
              attribute: readerImageAttr,
            ),
          );
          if (readerSampleUrl == null || readerSampleUrl.isEmpty) {
            readerSampleUrl = _parser.extractString(
              readerDoc,
              FieldSelector(selector: readerImageSelector, attribute: 'src'),
            );
          }

          final readerPageCountSelector =
              (readerConfig['readerPageCountSelector'] as String?) ?? '#pages';
          final readerPageCountAttr =
              (readerConfig['readerPageCountAttr'] as String?) ?? 'value';
          final readerPageCountStr = _parser.extractString(
                readerDoc,
                FieldSelector(
                  selector: readerPageCountSelector,
                  attribute: readerPageCountAttr,
                ),
              ) ??
              _parser.extractString(
                readerDoc,
                const FieldSelector(selector: '.total_pages'),
              );

          final readerPagesMatch =
              RegExp(r'(\d+)').firstMatch(readerPageCountStr ?? '');
          readerPageCount =
              int.tryParse(readerPagesMatch?.group(1) ?? '0') ?? 0;

          if ((readerSampleUrl?.isNotEmpty ?? false) && readerPageCount > 0) {
            imageUrls = _buildHentaiFoxImageUrlsFromSample(
              readerSampleUrl!,
              readerPageCount,
              readerExtByPage,
            );
          }
        } catch (e) {
          _logger.w(
            '$_sourceId: failed to extract HentaiFox reader-page sample URL',
            error: e,
          );
        }

        final thumbSel = readerConfig['thumbSelector'] as String?;
        final thumbAttr = readerConfig['thumbSrcAttr'] as String? ?? 'src';
        final regexStr = readerConfig['cdnPathRegex'] as String?;
        final pageSelStr = readerConfig['pageCountSelector'] as String?;

        if (imageUrls.isEmpty &&
            thumbSel != null &&
            regexStr != null &&
            pageSelStr != null) {
          // Collect explicit thumb URLs as final fallback only.
          final thumbElements = _parser.selectAll(doc, thumbSel);
          final explicitThumbs = <String>[];
          for (final el in thumbElements) {
            final raw =
                (el.attributes[thumbAttr] ?? el.attributes['src'] ?? '').trim();
            if (raw.isEmpty || raw.startsWith('data:image/')) continue;
            if (raw.startsWith('http://') || raw.startsWith('https://')) {
              explicitThumbs.add(raw);
            }
          }

          final countStr =
              _parser.extractString(doc, FieldSelector(selector: pageSelStr));
          final pagesMatch = RegExp(r'(\d+)').firstMatch(countStr ?? '');
          final pageCount = int.tryParse(pagesMatch?.group(1) ?? '0') ?? 0;

          final thumbSrc = _parser.extractString(
              doc, FieldSelector(selector: thumbSel, attribute: thumbAttr));

          if (thumbSrc != null && pageCount > 0) {
            final regex = RegExp(regexStr);
            final match = regex.firstMatch(thumbSrc);
            if (match != null && match.groupCount >= 2) {
              final cdnHost = match.group(1);
              final internalPath = match.group(2);

              final preferredExt = _inferImageExtension(
                readerSampleUrl?.isNotEmpty == true
                    ? readerSampleUrl
                    : thumbSrc,
              );

              // Prefer metadata-based URL building when hidden fields exist.
              final loadDir = _parser.extractString(
                    doc,
                    const FieldSelector(
                        selector: '#load_dir', attribute: 'value'),
                  ) ??
                  _parser.extractString(
                    doc,
                    const FieldSelector(
                        selector: '#image_dir', attribute: 'value'),
                  );
              final loadId = _parser.extractString(
                    doc,
                    const FieldSelector(
                        selector: '#load_id', attribute: 'value'),
                  ) ??
                  _parser.extractString(
                    doc,
                    const FieldSelector(
                        selector: '#gallery_id', attribute: 'value'),
                  );

              if ((loadDir?.isNotEmpty ?? false) &&
                  (loadId?.isNotEmpty ?? false)) {
                for (int i = 1; i <= pageCount; i++) {
                  imageUrls.add(
                      'https://$cdnHost/$loadDir/$loadId/$i.$preferredExt');
                }
              } else {
                for (int i = 1; i <= pageCount; i++) {
                  imageUrls
                      .add('https://$cdnHost/$internalPath/$i.$preferredExt');
                }
              }
            }
          }

          // Absolute last fallback: keep using explicit thumb URLs.
          if (imageUrls.isEmpty && explicitThumbs.isNotEmpty) {
            imageUrls = explicitThumbs;
          }
        }
      }

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

    Map<String, dynamic>? patternMap;

    if (patternValue is String) {
      urlTemplate = patternValue;
      listConfig = null;
    } else if (patternValue is Map<String, dynamic>) {
      patternMap = patternValue;
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

    // Some sources use non-uniform URL path for specific pages, e.g. page 2.
    if (patternMap != null) {
      final pageOverrides =
          (patternMap['pageOverrides'] as Map?)?.cast<String, dynamic>();
      final overrideTemplate =
          pageOverrides?[filter.page.toString()] as String?;
      if (overrideTemplate != null && overrideTemplate.isNotEmpty) {
        urlTemplate = overrideTemplate;
      }
    }

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
          (listConfig['fields'] as Map?)?.cast<String, dynamic>() ?? {};
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
      final linksSel = paginationConfig['links'] as String?;

      final hasNext = (nextSel != null && _hasEnabledLink(doc, nextSel)) ||
          (altSel != null && _hasEnabledLink(doc, altSel));

      int? totalPages;
      if (linksSel != null) {
        final pageLinks = _parser.selectAll(doc, linksSel);
        for (final link in pageLinks) {
          final pageText = link.text.trim();
          final pageNum = int.tryParse(pageText);
          if (pageNum != null && (totalPages == null || pageNum > totalPages)) {
            totalPages = pageNum;
          }
        }
      }

      return AdapterSearchResult(
        items: items,
        hasNextPage: hasNext,
        totalPages: totalPages,
      );
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
    _logger.d(
        '$_sourceId: extracting ${fieldsConfig.length} fields from detail page');

    for (final entry in fieldsConfig.entries) {
      final defMap = _toDefMap(entry.value);
      if (defMap == null) continue;

      final multi = defMap['multi'] as bool? ?? false;
      final transform = defMap['transform'] as String?;
      final sel = _fieldDefToSelector(defMap);
      if (sel == null) continue;

      if (multi) {
        var values = _parser.extractList(doc, sel);
        if (transform == 'slug') {
          values = values
              .map(_extractSlugFromUrl)
              .where((v) => v.isNotEmpty)
              .toList();
        }
        _logger.d(
            '$_sourceId: extracted field "${entry.key}" (multi): ${values.length} values = $values');
        result[entry.key] = values;
      } else {
        var value = _parser.extractString(doc, sel) ?? '';
        if (transform == 'slug' && value.isNotEmpty) {
          value = _extractSlugFromUrl(value);
        }
        _logger
            .d('$_sourceId: extracted field "${entry.key}" (single): "$value"');
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
        var values = el
            .querySelectorAll(sel.selector)
            .map((c) => sel.attribute != null
                ? (c.attributes[sel.attribute] ?? '')
                : c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        // Apply regex filter if present
        if (sel.regex != null) {
          values = values
              .map((v) => _applyRegex(v, sel.regex!))
              .where((v) => v != null && v.isNotEmpty)
              .cast<String>()
              .toList();
        }

        if (transform == 'slug') {
          values = values
              .map(_extractSlugFromUrl)
              .where((v) => v.isNotEmpty)
              .toList();
        }
        result[entry.key] = values;
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
    if (def is Map) return def.cast<String, dynamic>();
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

  /// Apply a regex pattern to extract a substring.
  /// Returns the first capture group if it exists, else the entire match (group 0).
  String? _applyRegex(String input, String pattern) {
    try {
      final match = RegExp(pattern).firstMatch(input);
      if (match == null) return null;
      return match.groupCount > 0 ? match.group(1) : match.group(0);
    } catch (e) {
      _logger.w('$_sourceId: regex pattern error: $pattern', error: e);
      return null;
    }
  }

  bool _hasEnabledLink(dom.Document doc, String selector) {
    final link = doc.querySelector(selector);
    if (link == null) return false;

    final href = (link.attributes['href'] ?? '').trim();
    if (href.isEmpty || href == '#') return false;

    final parentClass = link.parent?.attributes['class'] ?? '';
    if (parentClass.contains('disabled')) return false;

    return true;
  }

  String _inferImageExtension(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return 'jpg';

    final clean = imageUrl.split('?').first;
    final extMatch = RegExp(
            r'\.(jpg|jpeg|webp|png|gif)$|\d+t\.(jpg|jpeg|webp|png|gif)$',
            caseSensitive: false)
        .firstMatch(clean);
    return (extMatch?.group(1) ?? extMatch?.group(2) ?? 'jpg').toLowerCase();
  }

  /// Build HentaiFox image URLs using per-page extension mapping from `g_th`.
  List<String> _buildHentaiFoxImageUrlsFromSample(
    String sampleUrl,
    int pageCount,
    Map<int, String> extByPage,
  ) {
    if (sampleUrl.isEmpty || pageCount <= 0) return const [];

    final normalized =
        sampleUrl.startsWith('//') ? 'https:$sampleUrl' : sampleUrl;
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty || uri.pathSegments.isEmpty) {
      return const [];
    }

    final segments = List<String>.from(uri.pathSegments);
    final fileName = segments.removeLast();
    final defaultExtMatch =
        RegExp(r'^\d+\.(jpg|jpeg|webp|png|gif)$', caseSensitive: false)
            .firstMatch(fileName);
    final defaultExt = (defaultExtMatch?.group(1) ?? 'jpg').toLowerCase();

    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    final origin = uri.hasPort
        ? '$scheme://${uri.host}:${uri.port}'
        : '$scheme://${uri.host}';
    final pathPrefix = '/${segments.join('/')}';

    return List<String>.generate(
      pageCount,
      (index) {
        final page = index + 1;
        final ext = (extByPage[page] ?? defaultExt).toLowerCase();
        return '$origin$pathPrefix/$page.$ext';
      },
      growable: false,
    );
  }

  /// Parse HentaiFox `g_th` map and return image extension by page number.
  Map<int, String> _extractHentaiFoxExtensionsByPage(String html) {
    if (html.isEmpty) return const {};

    String? rawJson;
    final parseJsonMatch = RegExp(
      r"var\s+g_th\s*=\s*\$\.parseJSON\(\s*'(.+?)'\s*\)\s*;",
      dotAll: true,
    ).firstMatch(html);
    if (parseJsonMatch != null) {
      rawJson = parseJsonMatch.group(1);
    }

    rawJson ??= RegExp(
      r'var\s+g_th\s*=\s*(\{.+?\})\s*;',
      dotAll: true,
    ).firstMatch(html)?.group(1);

    if (rawJson == null || rawJson.isEmpty) {
      return const {};
    }

    try {
      final parsed = json.decode(rawJson) as Map<String, dynamic>;
      const extMap = {
        'j': 'jpg',
        'w': 'webp',
        'p': 'png',
        'g': 'gif',
        'b': 'bmp',
      };

      final result = <int, String>{};
      parsed.forEach((key, value) {
        final page = int.tryParse(key);
        if (page == null) return;

        final parts = value.toString().split(',');
        if (parts.isEmpty || parts.first.isEmpty) return;

        final extCode = parts.first.trim().toLowerCase();
        final ext = extMap[extCode];
        if (ext != null && ext.isNotEmpty) {
          result[page] = ext;
        }
      });
      return result;
    } catch (_) {
      return const {};
    }
  }

  DateTime? _parseRelativeOrAbsoluteDate(String raw) {
    if (raw.isEmpty) return null;

    final absolute = DateTime.tryParse(raw);
    if (absolute != null) return absolute;

    final now = DateTime.now();
    final normalized = raw
        .toLowerCase()
        .replaceFirst(RegExp(r'^(posted|date)\s*:\s*'), '')
        .trim();

    if (normalized == 'just now' || normalized == 'today') return now;
    if (normalized == 'yesterday') {
      return now.subtract(const Duration(days: 1));
    }

    final match = RegExp(
      r'^(\d+|a|an)\s+(second|minute|hour|day|week|month|year)s?\s+ago$',
    ).firstMatch(normalized);
    if (match == null) return null;

    final quantityRaw = match.group(1) ?? '0';
    final unit = match.group(2) ?? '';
    final quantity = (quantityRaw == 'a' || quantityRaw == 'an')
        ? 1
        : (int.tryParse(quantityRaw) ?? 0);
    if (quantity <= 0) return null;

    switch (unit) {
      case 'second':
        return now.subtract(Duration(seconds: quantity));
      case 'minute':
        return now.subtract(Duration(minutes: quantity));
      case 'hour':
        return now.subtract(Duration(hours: quantity));
      case 'day':
        return now.subtract(Duration(days: quantity));
      case 'week':
        return now.subtract(Duration(days: quantity * 7));
      case 'month':
        return now.subtract(Duration(days: quantity * 30));
      case 'year':
        return now.subtract(Duration(days: quantity * 365));
      default:
        return null;
    }
  }

  List<Comment> _parseApiComments(dynamic data) {
    List<dynamic> rows;

    if (data is List) {
      rows = data;
    } else if (data is String) {
      final decoded = json.decode(data);
      if (decoded is List) {
        rows = decoded;
      } else {
        return const [];
      }
    } else {
      return const [];
    }

    final comments = <Comment>[];
    final seenIds = <String>{};

    for (final row in rows) {
      if (row is! Map) continue;

      final id = (row['comment_id'] ?? '').toString().trim();
      final username = (row['user_name'] ?? '').toString().trim();
      final body = (row['comment'] ?? '').toString().trim();
      if (id.isEmpty || username.isEmpty || body.isEmpty) continue;
      if (seenIds.contains(id)) continue;

      final avatarRaw = (row['user_avatar'] ?? '').toString().trim();
      String? avatarUrl;
      if (avatarRaw.isNotEmpty) {
        if (avatarRaw.startsWith('http://') ||
            avatarRaw.startsWith('https://')) {
          avatarUrl = avatarRaw;
        } else if (avatarRaw.startsWith('/')) {
          avatarUrl = _urlBuilder.resolve(avatarRaw, const {});
        } else {
          avatarUrl = _urlBuilder.resolve('/uploads/$avatarRaw', const {});
        }
      }

      final postedRaw = (row['posted'] ?? '').toString().trim();

      comments.add(
        Comment(
          id: id,
          username: username,
          body: body,
          avatarUrl: avatarUrl,
          postDate: _parseRelativeOrAbsoluteDate(postedRaw),
        ),
      );
      seenIds.add(id);
    }

    return comments;
  }
}
