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
  final Future<void> Function()? _delayApplier;
  final RateLimiter? _rateLimiter;

  GenericScraperAdapter({
    required Dio dio,
    required GenericUrlBuilder urlBuilder,
    required GenericHtmlParser parser,
    required Logger logger,
    required String sourceId,
    Future<void> Function()? delayApplier,
    RateLimiter? rateLimiter,
  })  : _dio = dio,
        _urlBuilder = urlBuilder,
        _parser = parser,
        _logger = logger,
        _sourceId = sourceId,
        _delayApplier = delayApplier,
        _rateLimiter = rateLimiter;

  Future<void> _prepareRequestDelay() async {
    if (_delayApplier != null) {
      await _delayApplier();
    }
  }

  Future<T> _executeRequest<T>(Future<T> Function() request) async {
    await _prepareRequestDelay();
    if (_rateLimiter == null) {
      return request();
    }
    return _rateLimiter.execute(request);
  }

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
    // 3) Empty query      → category-routed browse (if configured)
    // 4) Empty query      → home/homePage fallback
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
      patternKey = _resolveBrowsePatternKey(
        filter: filter,
        scraper: scraper,
        urlPatternsCfg: urlPatternsCfg,
      );
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

    final pagedUrl = _ensurePageQueryForStandardSearch(
      resolvedUrl: url,
      patternKey: patternKey,
      filter: filter,
      rawConfig: rawConfig,
      urlPatternsCfg: urlPatternsCfg,
    );

    _logger.d('$_sourceId scraper [$patternKey]: $pagedUrl');
    return _fetchListPage(pagedUrl, rawConfig, listConfig,
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
    // Parse raw params (e.g. "s=manga&status=ongoing")
    final rawMap = <String, List<String>>{};
    for (final pair in rawParams.split('&')) {
      if (pair.isEmpty) continue;
      final idx = pair.indexOf('=');
      if (idx < 0) continue;
      final key = _safeDecodeComponent(pair.substring(0, idx));
      final value = _safeDecodeComponent(pair.substring(idx + 1));
      rawMap.putIfAbsent(key, () => <String>[]).add(value);
    }

    String? firstRawValue(String key) {
      final values = rawMap[key];
      if (values == null || values.isEmpty) return null;
      final value = values.first.trim();
      return value.isEmpty ? null : value;
    }

    // Determine which URL pattern to use from searchForm config.
    final searchFormCfg = rawConfig['searchForm'] as Map<String, dynamic>?;
    final basePatternKey =
        (searchFormCfg?['urlPattern'] as String?) ?? 'search';
    final formParamsCfg =
        (searchFormCfg?['params'] as Map?)?.cast<String, dynamic>() ?? {};
    final queryParamName = ((formParamsCfg['query']
            as Map<String, dynamic>?)?['queryParam'] as String?) ??
        'query';
    final tagParamName = ((formParamsCfg['tag']
            as Map<String, dynamic>?)?['queryParam'] as String?) ??
        'tag';
    final categoryParamName = ((formParamsCfg['category']
            as Map<String, dynamic>?)?['queryParam'] as String?) ??
        'category';

    final rawQueryValue =
        firstRawValue(queryParamName) ?? firstRawValue('query');
    final rawTagValue = firstRawValue(tagParamName) ?? firstRawValue('tag');
    final rawCategoryValue =
        firstRawValue(categoryParamName) ?? firstRawValue('category');

    // Prefer category browse routing when form sends only category in raw mode,
    // e.g. "raw:type=Doujinshi" with empty text query.
    String patternKey;
    if (rawQueryValue == null &&
        rawTagValue == null &&
        rawCategoryValue != null) {
      patternKey = _resolveBrowsePatternKey(
        filter: SearchFilter(
          query: '',
          page: page,
          category: rawCategoryValue,
        ),
        scraper: scraper,
        urlPatternsCfg: urlPatternsCfg,
      );
      rawMap.remove(categoryParamName);
      rawMap.remove('category');
    } else {
      // Prefer `{pattern}Page` variant for page > 1 when provided by config.
      final pagedPatternKey = '${basePatternKey}Page';
      patternKey = page > 1 && urlPatternsCfg.containsKey(pagedPatternKey)
          ? pagedPatternKey
          : basePatternKey;
    }

    if (!urlPatternsCfg.containsKey(patternKey)) {
      _logger.w('$_sourceId: raw search — URL pattern "$patternKey" not found');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    final pagedPatternKey = '${basePatternKey}Page';

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

    // Derive page query key from config/template (generic, no source hardcode).
    final pageParam = _resolvePageParamName(
      rawConfig: rawConfig,
      urlPatternsCfg: urlPatternsCfg,
      patternKeys: [patternKey, pagedPatternKey, basePatternKey],
    );

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

    // Resolve path placeholders from raw params for templates like
    // /search/keyword/{query}/ and /search/tag/{tag}/.

    final queryInPathTemplate = basePath.contains('{query}');
    final tagInPathTemplate = basePath.contains('{tag}');

    if (rawQueryValue != null) {
      basePath = basePath.replaceAll(
          '{query}', Uri.encodeQueryComponent(rawQueryValue));
    }
    if (rawTagValue != null) {
      final normalizedTag = rawTagValue.toLowerCase().replaceAll(' ', '-');
      basePath =
          basePath.replaceAll('{tag}', Uri.encodeQueryComponent(normalizedTag));
    }

    if (queryInPathTemplate) {
      rawMap.remove(queryParamName);
      rawMap.remove('query');
    }
    if (tagInPathTemplate) {
      rawMap.remove(tagParamName);
      rawMap.remove('tag');
    }

    final hasPageInPathTemplate = basePath.contains('{page}');
    final hasPageInQueryTemplate = _queryContainsPagePlaceholder(templateQuery);
    // Substitute {page} if present in path (some sources embed page in path).
    basePath = basePath.replaceAll('{page}', page.toString());

    // Clean unreplaced placeholders in path to avoid `%7Bquery%7D` leak.
    basePath = basePath.replaceAll('{query}', '');
    basePath = basePath.replaceAll('{tag}', '');

    final isAbsolutePath = Uri.tryParse(basePath)?.hasScheme ?? false;
    if (!isAbsolutePath) {
      basePath = basePath.replaceAll('//', '/');
      if (!basePath.startsWith('/')) {
        basePath = '/$basePath';
      } else {
        while (basePath.contains('//')) {
          basePath = basePath.replaceAll('//', '/');
        }
      }
    }

    // Merge template query defaults with raw params (raw params take priority).
    // This keeps mandatory params from template, e.g. `title=value`.
    // Only merge raw params that have non-empty values to avoid overwriting
    // template defaults like `post_type=manga` with `post_type=`.
    final mergedParams = <String, List<String>>{};
    if (templateQuery.isNotEmpty) {
      for (final pair in templateQuery.split('&')) {
        if (pair.isEmpty) continue;
        final idx = pair.indexOf('=');
        final key = idx < 0 ? pair : pair.substring(0, idx);
        if (key.isEmpty) continue;
        var value = idx < 0 ? '' : pair.substring(idx + 1);
        final decodedValue = _safeDecodeComponent(value);
        if (decodedValue == '{query}' || decodedValue == '{tag}') {
          value = '';
        } else if (decodedValue == '{page}') {
          value = page.toString();
        }
        mergedParams[key] = <String>[value];
      }
    }
    // Pagination is controlled by adapter/page argument. Remove stale page
    // values supplied from raw query params before merging; template/default
    // page (e.g. p={page}) should remain intact.
    final pageKeys = <String>{pageParam, 'page', 'paged', 'p'};
    for (final key in pageKeys) {
      rawMap.remove(key);
    }

    // Only add raw params with non-empty values
    rawMap.forEach((key, values) {
      if (values.isNotEmpty && values.first.isNotEmpty) {
        mergedParams[key] = values;
      }
    });

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
    if (page > 1 && !hasPageInPathTemplate && !hasPageInQueryTemplate) {
      queryParts.add('$pageParam=${Uri.encodeComponent(page.toString())}');
    }

    final baseUrl = _urlBuilder.resolve(basePath, {});
    final finalUrl =
        queryParts.isEmpty ? baseUrl : '$baseUrl?${queryParts.join('&')}';

    _logger.d('$_sourceId scraper [raw/$patternKey]: $finalUrl');
    return _fetchListPage(finalUrl, rawConfig, listConfig,
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

  String _safeDecodeComponent(String value) {
    if (value.isEmpty || !value.contains('%')) {
      return value;
    }

    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return _decodePercentEncodedSegments(value) ?? value;
    }
  }

  String _resolvePageParamName({
    required Map<String, dynamic> rawConfig,
    required Map<String, dynamic> urlPatternsCfg,
    required Iterable<String> patternKeys,
    String fallback = 'paged',
  }) {
    final searchFormCfg = rawConfig['searchForm'] as Map<String, dynamic>?;
    final formParams =
        (searchFormCfg?['params'] as Map?)?.cast<String, dynamic>() ?? {};

    for (final entry in formParams.entries) {
      final def = entry.value as Map<String, dynamic>?;
      if ((def?['type'] as String?) != 'page') continue;
      final configured = (def?['queryParam'] as String?)?.trim() ?? '';
      if (configured.isNotEmpty) {
        return configured;
      }
    }

    for (final key in patternKeys) {
      if (key.isEmpty) continue;
      final template = _patternUrl(urlPatternsCfg, key);
      final inferred = _inferPageParamFromTemplate(template);
      if (inferred != null && inferred.isNotEmpty) {
        return inferred;
      }
    }

    return fallback;
  }

  String? _inferPageParamFromTemplate(String templateUrl) {
    if (templateUrl.isEmpty) return null;
    final queryIndex = templateUrl.indexOf('?');
    if (queryIndex < 0 || queryIndex >= templateUrl.length - 1) {
      return null;
    }

    final query = templateUrl.substring(queryIndex + 1);
    for (final pair in query.split('&')) {
      if (pair.isEmpty) continue;
      final eqIndex = pair.indexOf('=');
      if (eqIndex <= 0) continue;
      final rawKey = pair.substring(0, eqIndex).trim();
      if (rawKey.isEmpty) continue;
      final rawValue = pair.substring(eqIndex + 1).trim();
      if (_safeDecodeComponent(rawValue) == '{page}') {
        return _safeDecodeComponent(rawKey);
      }
    }

    return null;
  }

  bool _queryContainsPagePlaceholder(String query) {
    if (query.isEmpty) return false;
    for (final pair in query.split('&')) {
      if (pair.isEmpty) continue;
      final eqIndex = pair.indexOf('=');
      if (eqIndex < 0 || eqIndex >= pair.length - 1) continue;
      final value = pair.substring(eqIndex + 1).trim();
      if (_safeDecodeComponent(value) == '{page}') {
        return true;
      }
    }
    return false;
  }

  String _ensurePageQueryForStandardSearch({
    required String resolvedUrl,
    required String patternKey,
    required SearchFilter filter,
    required Map<String, dynamic> rawConfig,
    required Map<String, dynamic> urlPatternsCfg,
  }) {
    if (filter.page <= 1) {
      return resolvedUrl;
    }

    // Raw-mode search already handles page injection explicitly.
    if (filter.query.startsWith('raw:')) {
      return resolvedUrl;
    }

    final patternValue = urlPatternsCfg[patternKey];
    String template = '';
    if (patternValue is String) {
      template = patternValue;
    } else if (patternValue is Map<String, dynamic>) {
      template = (patternValue['url'] as String?) ?? '';
    }

    // If template already encodes page placeholder, do not append fallback.
    if (template.contains('{page}')) {
      return resolvedUrl;
    }

    final lowerPath = Uri.tryParse(resolvedUrl)?.path.toLowerCase() ?? '';
    if (RegExp(r'/page/\d+/?$').hasMatch(lowerPath)) {
      return resolvedUrl;
    }

    final pageParam = _resolvePageParamName(
      rawConfig: rawConfig,
      urlPatternsCfg: urlPatternsCfg,
      patternKeys: [patternKey],
    );

    final pageParamRegex = RegExp('([?&])${RegExp.escape(pageParam)}=');
    if (pageParamRegex.hasMatch(resolvedUrl)) {
      return resolvedUrl;
    }

    final separator = resolvedUrl.contains('?') ? '&' : '?';
    return '$resolvedUrl$separator$pageParam=${Uri.encodeComponent(filter.page.toString())}';
  }

  String _resolveBrowsePatternKey({
    required SearchFilter filter,
    required Map<String, dynamic> scraper,
    required Map<String, dynamic> urlPatternsCfg,
  }) {
    final fallback = _homeFallbackPatternKey(
      page: filter.page,
      urlPatternsCfg: urlPatternsCfg,
    );

    final routing = (scraper['routing'] as Map?)?.cast<String, dynamic>();
    final categoryPatterns =
        (routing?['categoryPatterns'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    if (categoryPatterns.isEmpty) return fallback;

    var selectedCategory = (filter.category ?? '').trim();
    if (selectedCategory.isEmpty) {
      selectedCategory = (routing?['defaultCategory'] as String? ?? '').trim();
    }
    if (selectedCategory.isEmpty) return fallback;

    final route = _resolveCategoryRoute(
      selectedCategory: selectedCategory,
      categoryPatterns: categoryPatterns,
    );
    if (route == null) {
      _logger.w(
        '$_sourceId: browse category "$selectedCategory" is unknown; fallback to "$fallback"',
      );
      return fallback;
    }

    final firstPageKey = (route['firstPage'] ?? '').trim();
    final pagedKey = (route['paged'] ?? '').trim();
    final candidate = filter.page > 1
        ? (pagedKey.isNotEmpty ? pagedKey : firstPageKey)
        : firstPageKey;

    if (candidate.isEmpty) {
      _logger.w(
        '$_sourceId: category "$selectedCategory" has empty route; fallback to "$fallback"',
      );
      return fallback;
    }

    if (!urlPatternsCfg.containsKey(candidate)) {
      _logger.w(
        '$_sourceId: category "$selectedCategory" maps to missing pattern "$candidate"; fallback to "$fallback"',
      );
      return fallback;
    }

    return candidate;
  }

  Map<String, String>? _resolveCategoryRoute({
    required String selectedCategory,
    required Map<String, dynamic> categoryPatterns,
  }) {
    final byAlias = <String, Map<String, String>>{};
    for (final entry in categoryPatterns.entries) {
      final route = _parseCategoryRoute(entry.value);
      if (route == null) continue;

      final aliases = <String>{
        ..._splitCategoryAliasTokens(entry.key),
      };

      final raw = entry.value;
      if (raw is Map) {
        final aliasRaw = raw['aliases'];
        if (aliasRaw is List) {
          for (final value in aliasRaw) {
            aliases.addAll(_splitCategoryAliasTokens(value.toString()));
          }
        } else if (aliasRaw is String) {
          aliases.addAll(_splitCategoryAliasTokens(aliasRaw));
        }
      }

      if (aliases.isEmpty) {
        aliases.add(entry.key);
      }

      for (final alias in aliases) {
        final normalized = _normalizeCategoryKey(alias);
        if (normalized.isEmpty) continue;
        byAlias.putIfAbsent(normalized, () => route);
      }
    }

    final selected = _normalizeCategoryKey(selectedCategory);
    if (selected.isEmpty) return null;
    return byAlias[selected];
  }

  Map<String, String>? _parseCategoryRoute(dynamic raw) {
    if (raw is String) {
      final firstPage = raw.trim();
      if (firstPage.isEmpty) return null;
      return <String, String>{'firstPage': firstPage};
    }

    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();

    final firstPage = (map['firstPage'] as String?)?.trim() ??
        (map['first'] as String?)?.trim() ??
        (map['pattern'] as String?)?.trim() ??
        (map['key'] as String?)?.trim() ??
        '';
    final paged = (map['paged'] as String?)?.trim() ??
        (map['page'] as String?)?.trim() ??
        (map['pagedPattern'] as String?)?.trim() ??
        '';

    if (firstPage.isEmpty && paged.isEmpty) {
      return null;
    }

    return <String, String>{
      if (firstPage.isNotEmpty) 'firstPage': firstPage,
      if (paged.isNotEmpty) 'paged': paged,
    };
  }

  Set<String> _splitCategoryAliasTokens(String raw) {
    return raw
        .split(RegExp(r'[|,;]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  String _normalizeCategoryKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _homeFallbackPatternKey({
    required int page,
    required Map<String, dynamic> urlPatternsCfg,
  }) {
    return page > 1 && urlPatternsCfg.containsKey('homePage')
        ? 'homePage'
        : 'home';
  }

  Future<Response<String>> _getWithRedirectFallback(
    String url, {
    required Map<String, dynamic> rawConfig,
  }) async {
    final headers = _resolveRequestHeaders(rawConfig, fallbackReferer: url);

    final initialResponse = await _executeRequest<Response<String>>(
      () => _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: headers,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      ),
    );

    final initialStatus = initialResponse.statusCode ?? 0;
    if (_isSuccessStatus(initialStatus)) {
      return initialResponse;
    }

    // 🚀 CRITICAL: Detect Cloudflare 403 and throw so WebViewSessionAdapter can handle it
    // GenericScraperAdapter uses validateStatus < 500 to be permissive, but this prevents
    // Cloudflare 403 from being caught by WebViewSessionAdapter.
    // Solution: manually check for CF 403 and throw DioException so WebView can trigger.
    if (initialStatus == 403) {
      final cfMitigated = initialResponse.headers.value('cf-mitigated');
      if (cfMitigated != null) {
        _logger.w(
            '$_sourceId detected Cloudflare 403 (cf-mitigated: $cfMitigated), throwing for WebViewSessionAdapter');
        throw DioException.badResponse(
          statusCode: 403,
          requestOptions: initialResponse.requestOptions,
          response: initialResponse,
        );
      }
    }

    if (_isRedirectStatus(initialStatus)) {
      final location = initialResponse.headers.value('location')?.trim();
      if (location != null && location.isNotEmpty) {
        final resolvedUrl = Uri.parse(url).resolve(location).toString();
        final resolvedResponse = await _executeRequest<Response<String>>(
          () => _dio.get<String>(
            resolvedUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: headers,
              validateStatus: (status) => status != null && status < 500,
            ),
          ),
        );

        if (_isSuccessStatus(resolvedResponse.statusCode)) {
          return resolvedResponse;
        }

        // 🚀 Also detect CF 403 in resolved redirect response
        final resolvedStatus = resolvedResponse.statusCode ?? 0;
        if (resolvedStatus == 403) {
          final cfMitigated = resolvedResponse.headers.value('cf-mitigated');
          if (cfMitigated != null) {
            _logger.w(
                '$_sourceId detected Cloudflare 403 in redirect target (cf-mitigated: $cfMitigated), throwing for WebViewSessionAdapter');
            throw DioException.badResponse(
              statusCode: 403,
              requestOptions: resolvedResponse.requestOptions,
              response: resolvedResponse,
            );
          }
        }
      }

      // Some WAFs (for example Sucuri) may respond with redirect status but no
      // Location header when client fingerLogger().i looks suspicious. In that case,
      // retry once with an isolated clean Dio instance so inherited global
      // headers from other sources do not leak into this request.
      if (location == null || location.isEmpty) {
        _logger.w(
          '$_sourceId redirect loop without Location, retrying with isolated client: $url',
        );

        final isolatedHeaders = _resolveIsolatedHeaders(headers);
        final fallbackUrls = _buildRedirectLoopFallbackUrls(
          url,
          rawConfig: rawConfig,
        );

        for (final candidateUrl in fallbackUrls) {
          try {
            final isolatedResponse = await _fetchWithIsolatedClient(
              candidateUrl,
              headers: isolatedHeaders,
            );

            if (_isSuccessStatus(isolatedResponse.statusCode)) {
              _logger.i(
                '$_sourceId isolated fallback succeeded: $candidateUrl (${isolatedResponse.statusCode})',
              );
              return isolatedResponse;
            }

            // 🚀 Also check for CF 403 in isolated response
            final isolatedStatus = isolatedResponse.statusCode ?? 0;
            if (isolatedStatus == 403) {
              final cfMitigated =
                  isolatedResponse.headers.value('cf-mitigated');
              if (cfMitigated != null) {
                _logger.w(
                    '$_sourceId detected Cloudflare 403 in isolated fallback (cf-mitigated: $cfMitigated), throwing for WebViewSessionAdapter');
                throw DioException.badResponse(
                  statusCode: 403,
                  requestOptions: isolatedResponse.requestOptions,
                  response: isolatedResponse,
                );
              }
            }
          } on DioException catch (isolatedError) {
            _logger.w(
              '$_sourceId isolated fallback failed for $candidateUrl',
              error: isolatedError,
            );
          }
        }
      }
    }

    throw DioException.badResponse(
      statusCode: initialStatus,
      requestOptions: initialResponse.requestOptions,
      response: initialResponse,
    );
  }

  Future<Response<String>> _fetchWithIsolatedClient(
    String url, {
    required Map<String, dynamic> headers,
  }) async {
    final isolatedDio = Dio(
      BaseOptions(
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        sendTimeout: _dio.options.sendTimeout,
        responseType: ResponseType.plain,
        followRedirects: false,
        maxRedirects: 5,
        headers: headers,
      ),
    );

    try {
      return await isolatedDio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } finally {
      isolatedDio.close(force: true);
    }
  }

  Map<String, dynamic> _resolveIsolatedHeaders(Map<String, dynamic> headers) {
    final isolated = <String, dynamic>{};

    final userAgent = headers['User-Agent']?.toString();
    final referer = headers['Referer']?.toString();

    isolated['User-Agent'] = (userAgent == null || userAgent.isEmpty)
        ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        : userAgent;
    isolated['Accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
    isolated['Accept-Language'] = 'en-US,en;q=0.9';
    if (referer != null && referer.isNotEmpty) {
      isolated['Referer'] = referer;
    }

    return isolated;
  }

  Map<String, dynamic> _resolveRequestHeaders(
    Map<String, dynamic> rawConfig, {
    required String fallbackReferer,
  }) {
    final headers = <String, dynamic>{};
    final network = rawConfig['network'];
    if (network is Map<String, dynamic>) {
      final rawHeaders = network['headers'];
      if (rawHeaders is Map<String, dynamic>) {
        headers.addAll(rawHeaders);
      }
    }

    headers.putIfAbsent('Referer', () => fallbackReferer);
    return headers;
  }

  bool _isRedirectStatus(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  bool _isSuccessStatus(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode >= 200 && statusCode < 300;
  }

  List<String> _buildRedirectLoopFallbackUrls(
    String originalUrl, {
    required Map<String, dynamic> rawConfig,
  }) {
    final urls = <String>[originalUrl];

    final baseUrl = rawConfig['baseUrl'] as String?;
    if (baseUrl != null && baseUrl.isNotEmpty) {
      final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      urls.add(normalizedBase);
      urls.add('${normalizedBase}page/1/');
    }

    final originalUri = Uri.tryParse(originalUrl);
    if (originalUri != null && originalUri.path == '/') {
      urls.add(originalUri.replace(path: '/page/1/').toString());
    }

    return urls.toSet().toList();
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
    Logger().i(
        '[$_sourceId] getDetail: contentId=$contentId, detailTemplate=$detailTemplate');
    if (detailTemplate.isEmpty) {
      Logger().i('[$_sourceId] ERROR: no detail URL pattern configured');
      _logger.w('$_sourceId: no scraper detail URL pattern configured');
      return AdapterDetailResult(
          content: _emptyContent(contentId), imageUrls: []);
    }

    final url = _urlBuilder.buildDetailUrl(detailTemplate, contentId);
    Logger().i('[$_sourceId] getDetail: fetching URL=$url');
    _logger.d('$_sourceId scraper detail: $url');
    final requestHeaders =
        _resolveRequestHeaders(rawConfig, fallbackReferer: url);

    try {
      Logger().i('[$_sourceId] getDetail: about to fetch...');
      final response = await _executeRequest<Response<String>>(
        () => _dio.get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            headers: requestHeaders,
          ),
        ),
      );
      Logger().i(
          '[$_sourceId] getDetail: response received, status=${response.statusCode}');
      Logger().i(
          '[$_sourceId] getDetail: response.data type=${response.data.runtimeType}, value=${response.data?.substring(1, 10)}');
      final doc = _parser.parse(response.data ?? '');

      final selectors = (scraper?['selectors'] as Map<String, dynamic>?) ?? {};
      final detailCfg = (selectors['detail'] as Map<String, dynamic>?) ?? {};
      final fieldsConfig =
          (detailCfg['fields'] as Map?)?.cast<String, dynamic>() ?? {};

      Logger().i(
          '[$_sourceId] getDetail: fieldsConfig keys=${fieldsConfig.keys.toList()}');

      final fields = _extractDocumentFields(doc, fieldsConfig);
      Logger().i(
          '[$_sourceId] getDetail: extracted fields=${fields.keys.toList()}');

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

      final readerConfig = selectors['reader'] as Map<String, dynamic>?;
      List<String> detailImageUrls = const [];
      final hasChapters = chapters?.isNotEmpty == true;
      if (readerConfig != null && !hasChapters) {
        final imagesDef = readerConfig['images'];
        final defMap = _toDefMap(imagesDef);
        if (defMap != null) {
          final sel = _fieldDefToSelector(defMap);
          if (sel != null) {
            final seen = <String>{};
            detailImageUrls = _parser
                .extractList(doc, sel)
                .map((u) => u.trim())
                .where((u) => u.isNotEmpty)
                .map((u) => _urlBuilder.resolve(u, const {}))
                .where((u) => seen.add(u))
                .toList();
          }
        }
      }

      if (detailImageUrls.isNotEmpty) {
        content = content.copyWith(
          imageUrls: detailImageUrls,
          pageCount: detailImageUrls.length,
        );
      }

      return AdapterDetailResult(content: content, imageUrls: detailImageUrls);
    } on DioException catch (e, stack) {
      Logger().i(
          '[$_sourceId] getDetail ERROR (DioException): ${e.message}, statusCode=${e.response?.statusCode}');
      Logger().i('[$_sourceId] stack: $stack');
      // 🚀 Re-throw Cloudflare 403 so WebViewSessionAdapter can handle it
      if (e.response?.statusCode == 403) {
        final cfMitigated = e.response?.headers.value('cf-mitigated');
        if (cfMitigated != null) {
          _logger.w(
              '$_sourceId detected Cloudflare 403 in detail page for $contentId, re-throwing for WebViewSessionAdapter');
          rethrow;
        }
      }
      _logger.e('$_sourceId scraper detail failed for $contentId', error: e);
      return AdapterDetailResult(
          content: _emptyContent(contentId), imageUrls: []);
    } catch (e, stack) {
      Logger().e('[$_sourceId] getDetail ERROR (Exception): $e');
      Logger().e('[$_sourceId] stack: $stack');
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
    final requestHeaders =
        _resolveRequestHeaders(rawConfig, fallbackReferer: url);

    try {
      final response = await _executeRequest<Response<String>>(
        () => _dio.get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            headers: requestHeaders,
          ),
        ),
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
    } on DioException catch (e) {
      // 🚀 Re-throw Cloudflare 403 so WebViewSessionAdapter can handle it
      if (e.response?.statusCode == 403) {
        final cfMitigated = e.response?.headers.value('cf-mitigated');
        if (cfMitigated != null) {
          _logger.w(
              '$_sourceId detected Cloudflare 403 in related content for $contentId, re-throwing for WebViewSessionAdapter');
          rethrow;
        }
      }
      _logger.e('$_sourceId scraper related fetch failed for $contentId',
          error: e);
      return const [];
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
    final detailRequestHeaders =
        _resolveRequestHeaders(rawConfig, fallbackReferer: url);

    // 1) API-first comments path (e.g. HentaiFox includes/comments.php)
    final commentsEndpoint = commentsCfg['endpoint'] as String?;
    if (commentsEndpoint != null && commentsEndpoint.isNotEmpty) {
      try {
        final galleryIdParam =
            (commentsCfg['galleryIdParam'] as String?) ?? 'gallery_id';
        final commentsUrl = _urlBuilder.resolve(commentsEndpoint, const {});

        // comments.php is protected by CSRF/session checks.
        final detailResponse = await _executeRequest<Response<String>>(
          () => _dio.get<String>(
            url,
            options: Options(
              responseType: ResponseType.plain,
              headers: detailRequestHeaders,
            ),
          ),
        );
        cachedDetailHtml = detailResponse.data;

        final csrfToken = _extractCsrfToken(cachedDetailHtml ?? '');
        final cookieHeader = _buildCookieHeader(detailResponse.headers);
        final requestHeaders = <String, dynamic>{
          ...detailRequestHeaders,
          'Referer': url,
          'Origin': Uri.parse(url).origin,
          'X-Requested-With': 'XMLHttpRequest',
          if (csrfToken != null && csrfToken.isNotEmpty)
            'X-CSRF-TOKEN': csrfToken,
          if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
        };

        final response = await _executeRequest<Response<dynamic>>(
          () => _dio.post<dynamic>(
            commentsUrl,
            data: {galleryIdParam: contentId},
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              responseType: ResponseType.plain,
              headers: requestHeaders,
              validateStatus: (status) => status != null && status < 500,
            ),
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
        // 🚀 Re-throw Cloudflare 403 so WebViewSessionAdapter can handle it
        if (e is DioException && e.response?.statusCode == 403) {
          final cfMitigated = e.response?.headers.value('cf-mitigated');
          if (cfMitigated != null) {
            _logger.w(
                '$_sourceId detected Cloudflare 403 in comments API for $contentId, re-throwing for WebViewSessionAdapter');
            rethrow;
          }
        }
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
          (await _executeRequest<Response<String>>(
            () => _dio.get<String>(
              url,
              options: Options(
                responseType: ResponseType.plain,
                headers: detailRequestHeaders,
              ),
            ),
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
    } on DioException catch (e) {
      // 🚀 Re-throw Cloudflare 403 so WebViewSessionAdapter can handle it
      if (e.response?.statusCode == 403) {
        final cfMitigated = e.response?.headers.value('cf-mitigated');
        if (cfMitigated != null) {
          _logger.w(
              '$_sourceId detected Cloudflare 403 in HTML comments for $contentId, re-throwing for WebViewSessionAdapter');
          rethrow;
        }
      }
      _logger.e('$_sourceId scraper comments fetch failed for $contentId',
          error: e);
      return const [];
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
    final chapterRequestHeaders =
        _resolveRequestHeaders(rawConfig, fallbackReferer: url);

    try {
      final response = await _executeRequest<Response<String>>(
        () => _dio.get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            headers: chapterRequestHeaders,
          ),
        ),
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

      if (imageUrls.isEmpty &&
          (readerConfig['mode'] as String?) == 'ajaxHtmlImages') {
        imageUrls = await _fetchAjaxHtmlImages(
          rawConfig: rawConfig,
          readerConfig: readerConfig,
          readerDocument: doc,
          readerPageUrl: url,
        );
      }

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
          final readerResp = await _executeRequest<Response<String>>(
            () => _dio.get<String>(
              readerPageUrl,
              options: Options(
                responseType: ResponseType.plain,
                headers: _resolveRequestHeaders(
                  rawConfig,
                  fallbackReferer: readerPageUrl,
                ),
              ),
            ),
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
        imageUrls = _extractScriptSlidesImageUrls(htmlContent);
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

      imageUrls = _normalizeChapterImageUrls(imageUrls);

      // 3. DOM fallback for navigation via reader.nav.{next,prev}.
      final navCfg = readerConfig['nav'] as Map<String, dynamic>?;
      nextId ??= _extractNavChapterId(doc, navCfg?['next']);
      prevId ??= _extractNavChapterId(doc, navCfg?['prev']);

      return ChapterData(
        images: imageUrls,
        nextChapterId: nextId,
        prevChapterId: prevId,
      );
    } on DioException catch (e) {
      // 🚀 Re-throw Cloudflare 403 so WebViewSessionAdapter can handle it
      if (e.response?.statusCode == 403) {
        final cfMitigated = e.response?.headers.value('cf-mitigated');
        if (cfMitigated != null) {
          _logger.w(
              '$_sourceId detected Cloudflare 403 in chapter fetch for $chapterId, re-throwing for WebViewSessionAdapter');
          rethrow;
        }
      }
      _logger.e('$_sourceId scraper chapter fetch failed for $chapterId',
          error: e);
      return null;
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

    final rawQuery = filter.query == '{query}' ? '' : filter.query;
    final params = <String, String>{
      'page': filter.page.toString(),
      'query': Uri.encodeQueryComponent(rawQuery),
      'tag': filter.includeTags.isNotEmpty
          ? filter.includeTags.first.name.toLowerCase().replaceAll(' ', '-')
          : '',
    };

    // Merge custom params from pattern config (e.g., "params": { "n": "{query}" })
    if (patternMap != null) {
      final customParams =
          (patternMap['params'] as Map?)?.cast<String, String>() ?? {};
      for (final entry in customParams.entries) {
        var value = entry.value;
        if (value == '{query}') {
          value = Uri.encodeQueryComponent(rawQuery);
        } else if (value == '{page}') {
          value = filter.page.toString();
        } else if (value == '{tag}' && filter.includeTags.isNotEmpty) {
          value =
              filter.includeTags.first.name.toLowerCase().replaceAll(' ', '-');
        }
        params[entry.key] = value;
      }
    }

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
    Map<String, dynamic> rawConfig,
    Map<String, dynamic> listConfig, {
    String? defaultLanguage,
  }) async {
    try {
      final response = await _getWithRedirectFallback(
        url,
        rawConfig: rawConfig,
      );
      final doc = _parser.parse(response.data ?? '');

      final container = listConfig['container'] as String?;
      final fieldsConfig =
          (listConfig['fields'] as Map?)?.cast<String, dynamic>() ?? {};
      final paginationConfig =
          (listConfig['pagination'] as Map<String, dynamic>?) ?? {};
      final sectionFilterConfig =
          (listConfig['sectionFilter'] as Map<String, dynamic>?) ?? {};
      final sectionFilterEnabled = sectionFilterConfig['enabled'] == true;
      final allowedSectionTitles =
          (sectionFilterConfig['allowedTitleContains'] as List?)
                  ?.map((e) => e.toString().toLowerCase().trim())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const <String>[];
      final idFallbackSelectors = (listConfig['idFallbackSelectors'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[];

      final items = <Content>[];
      if (container != null) {
        final elements = _parser.selectAll(doc, container);
        _logger.i(
            '$_sourceId list parse: container="$container" matched ${elements.length} elements for $url');

        var index = 0;
        for (final el in elements) {
          if (sectionFilterEnabled && allowedSectionTitles.isNotEmpty) {
            final sectionTitle = el.parent?.parent?.previousElementSibling?.text
                    .trim()
                    .toLowerCase() ??
                '';
            final isAllowed = allowedSectionTitles
                .any((needle) => sectionTitle.contains(needle));
            if (sectionTitle.isNotEmpty && !isAllowed) {
              continue;
            }
          }

          final fields = _extractElementFields(el, fieldsConfig);
          var item =
              GenericContentMapper.toListItem(fields, sourceId: _sourceId);
          if (item.id.isEmpty && idFallbackSelectors.isNotEmpty) {
            String fallbackHref = '';
            for (final selector in idFallbackSelectors) {
              final href =
                  (el.querySelector(selector)?.attributes['href'] ?? '').trim();
              if (href.isNotEmpty) {
                fallbackHref = href;
                break;
              }
            }
            final fallbackId = _extractSlugFromUrl(fallbackHref);
            if (fallbackId.isNotEmpty) {
              item = item.copyWith(id: fallbackId);
            }
          }
          if (defaultLanguage != null &&
              (item.language.isEmpty || item.language == 'unknown')) {
            item = item.copyWith(language: defaultLanguage);
          }
          if (item.id.isNotEmpty) {
            items.add(item);
          } else if (index < 5) {
            _logger.w(
                '$_sourceId list parse drop[$index]: empty id. fields=$fields');
          }
          index++;
        }
        _logger.i(
            '$_sourceId list parse: mapped ${items.length}/${elements.length} items for $url');
      } else {
        _logger.w('$_sourceId list parse: container null for $url');
      }

      final nextSel = paginationConfig['next'] as String?;
      final altSel = paginationConfig['alt'] as String?;
      final linksSel = paginationConfig['links'] as String?;
      final lastSel = paginationConfig['last'] as String?;

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

      if (totalPages == null && lastSel != null && lastSel.isNotEmpty) {
        final lastHref = _parser.extractString(
          doc,
          FieldSelector(selector: lastSel, attribute: 'href'),
        );
        if (lastHref != null && lastHref.isNotEmpty) {
          final match = RegExp(r'/page/(\d+)/').firstMatch(lastHref);
          totalPages = int.tryParse(match?.group(1) ?? '');
        }
      }

      if (totalPages == null) {
        final pageLinks = _parser.selectAll(doc, 'a[href]');
        for (final link in pageLinks) {
          final href = (link.attributes['href'] ?? '').trim();
          if (href.isEmpty) continue;
          final match = RegExp(r'/page/(\d+)/').firstMatch(href);
          final pageNum = int.tryParse(match?.group(1) ?? '');
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

        final seenValues = <String>{};
        values = values.where((v) => seenValues.add(v)).toList();

        // 🆕 parseTagNamespace: split "namespace:name" strings into typed Tags
        // Used by sources like E-Hentai where tag title attributes carry the
        // full "namespace:tagname" string (e.g. "artist:john", "other:ai generated").
        final parseNamespace = defMap['parseTagNamespace'] as bool? ?? false;
        if (parseNamespace && entry.key == 'tags') {
          final tagObjects = <Tag>[];
          for (final raw in values) {
            final colonIdx = raw.indexOf(':');
            if (colonIdx > 0 && colonIdx < raw.length - 1) {
              final ns = raw.substring(0, colonIdx).trim().toLowerCase();
              final name = raw.substring(colonIdx + 1).trim();
              if (ns.isNotEmpty && name.isNotEmpty) {
                tagObjects.add(Tag(id: 0, name: name, type: ns, count: 0));
                continue;
              }
            }
            tagObjects.add(Tag(id: 0, name: raw, type: 'tag', count: 0));
          }
          _logger.d(
              '$_sourceId: parsed ${tagObjects.length} namespace-typed tags for "${entry.key}"');
          result[entry.key] = tagObjects;
        } else {
          _logger.d(
              '$_sourceId: extracted field "${entry.key}" (multi): ${values.length} values = $values');
          result[entry.key] = values;
        }
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
  ///
  /// We match the common `/manga/<slug>` and `/<slug>-chapter-<number>`
  /// shapes before attempting [Uri.parse]. Regex matching tolerates raw
  /// Unicode path characters such as `〜` and `ー`, which can appear in source
  /// URLs and may throw inside `Uri.parse` when the path is not already
  /// percent-encoded.
  ///
  /// Examples:
  /// - `https://komiku.org/manga/one-piece/` -> `one-piece`
  /// - `https://komiku.org/manga/title-%E3%80%9Cspecial%E3%80%9C/` ->
  ///   `title-〜special〜`
  /// - `https://komiku.org/nishuume-cheat-〜-chapter-1/` ->
  ///   `nishuume-cheat-〜-chapter-1`
  String _extractSlugFromUrl(String url) {
    if (url.isEmpty) return '';

    final patterns = <RegExp>[
      RegExp(r'/manga/([^/?#]+)'),
      RegExp(r'/([^/?#]+?-chapter-[\d.-]+)(?:/|[?#]|$)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      final slug = match?.group(1);
      if (slug != null && slug.isNotEmpty) {
        return _decodeSlugComponent(slug);
      }
    }

    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        final mangaIndex = segments.indexOf('manga');
        final slug = mangaIndex != -1 && mangaIndex + 1 < segments.length
            ? segments[mangaIndex + 1]
            : segments.last;
        return _decodeSlugComponent(slug);
      }
    } catch (_) {}
    return '';
  }

  /// Decode percent-encoded slugs without turning malformed inputs into errors.
  String _decodeSlugComponent(String slug) {
    if (!slug.contains('%')) return slug;
    try {
      return Uri.decodeComponent(slug);
    } catch (_) {
      return _decodePercentEncodedSegments(slug) ?? slug;
    }
  }

  /// Decode only valid `%HH` sequences so mixed raw+encoded Unicode survives.
  String? _decodePercentEncodedSegments(String slug) {
    bool isHexDigit(int codeUnit) =>
        (codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0x41 && codeUnit <= 0x46) ||
        (codeUnit >= 0x61 && codeUnit <= 0x66);

    final output = StringBuffer();
    var index = 0;
    while (index < slug.length) {
      final current = slug.codeUnitAt(index);
      if (current != 0x25) {
        output.writeCharCode(current);
        index++;
        continue;
      }

      if (index + 2 >= slug.length ||
          !isHexDigit(slug.codeUnitAt(index + 1)) ||
          !isHexDigit(slug.codeUnitAt(index + 2))) {
        return null;
      }

      final bytes = <int>[];
      while (index + 2 < slug.length && slug.codeUnitAt(index) == 0x25) {
        final first = slug.codeUnitAt(index + 1);
        final second = slug.codeUnitAt(index + 2);
        if (!isHexDigit(first) || !isHexDigit(second)) {
          return null;
        }
        bytes.add(int.parse(slug.substring(index + 1, index + 3), radix: 16));
        index += 3;
      }

      try {
        output.write(utf8.decode(bytes));
      } catch (_) {
        return null;
      }
    }

    return output.toString();
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

  String? _extractNavChapterId(dom.Document doc, dynamic navDef) {
    if (navDef is String) {
      final href = _parser.extractString(
        doc,
        FieldSelector(selector: navDef, attribute: 'href'),
      );
      if (href == null || href.isEmpty || href.startsWith('#')) {
        return null;
      }
      return _extractSlugFromUrl(href);
    }

    final defMap = _toDefMap(navDef);
    if (defMap == null) return null;

    final transform = defMap['transform'] as String?;
    final selector = _fieldDefToSelector(defMap);
    if (selector == null) return null;

    var value = _parser.extractString(doc, selector)?.trim() ?? '';
    if (value.isEmpty || value == '#') return null;
    if (transform == 'slug') {
      value = _extractSlugFromUrl(value);
    }

    return value.isEmpty ? null : value;
  }

  Future<List<String>> _fetchAjaxHtmlImages({
    required Map<String, dynamic> rawConfig,
    required Map<String, dynamic> readerConfig,
    required dom.Document readerDocument,
    required String readerPageUrl,
  }) async {
    final requestConfig =
        (readerConfig['request'] as Map?)?.cast<String, dynamic>();
    if (requestConfig == null) {
      _logger.w(
        '$_sourceId ajaxHtmlImages: missing reader.request config',
      );
      return const [];
    }

    final method =
        ((requestConfig['method'] as String?) ?? 'POST').trim().toUpperCase();
    final requestUrlTemplate = (requestConfig['url'] as String?)?.trim() ?? '';
    if (requestUrlTemplate.isEmpty) {
      _logger.w(
        '$_sourceId ajaxHtmlImages: request.url is empty',
      );
      return const [];
    }

    final bodyFields = _extractAjaxRequestFields(
      readerDocument: readerDocument,
      requestConfig: requestConfig,
      fieldGroup: 'body',
    );
    if (bodyFields == null) return const [];

    final queryFields = _extractAjaxRequestFields(
      readerDocument: readerDocument,
      requestConfig: requestConfig,
      fieldGroup: 'query',
    );
    if (queryFields == null) return const [];

    final queryParameters = <String, dynamic>{...queryFields};
    if (method == 'GET' && bodyFields.isNotEmpty) {
      for (final entry in bodyFields.entries) {
        queryParameters.putIfAbsent(entry.key, () => entry.value);
      }
    }

    final headers = _resolveRequestHeaders(
      rawConfig,
      fallbackReferer: readerPageUrl,
    );
    headers['Referer'] = readerPageUrl;

    final origin = Uri.tryParse(readerPageUrl)?.origin;
    if (origin != null && origin.isNotEmpty) {
      headers.putIfAbsent('Origin', () => origin);
    }

    final ajaxHeaders =
        (requestConfig['headers'] as Map?)?.cast<String, dynamic>() ?? {};
    headers.addAll(ajaxHeaders);

    final requestUrl = _urlBuilder.resolve(requestUrlTemplate, const {});
    final configuredContentType =
        (requestConfig['contentType'] as String?)?.trim();
    final contentType =
        configuredContentType == null || configuredContentType.isEmpty
            ? (method == 'POST' ? Headers.formUrlEncodedContentType : null)
            : configuredContentType;

    final response = await _executeRequest<Response<String>>(
      () => _dio.request<String>(
        requestUrl,
        data: method == 'GET' ? null : bodyFields,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: Options(
          method: method,
          headers: headers,
          contentType: contentType,
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      ),
    );

    if (!_isSuccessStatus(response.statusCode)) {
      if (response.statusCode == 403 &&
          (response.headers.value('cf-mitigated')?.isNotEmpty ?? false)) {
        _logger.w(
          '$_sourceId ajaxHtmlImages: blocked by site protection (403 cf-mitigated) for $requestUrl',
        );
      }
      _logger.w(
        '$_sourceId ajaxHtmlImages: request failed with status ${response.statusCode} for $requestUrl',
      );
      return const [];
    }

    final responseHtml = response.data ?? '';
    if (responseHtml.trim().isEmpty) {
      _logger.w(
        '$_sourceId ajaxHtmlImages: empty HTML response for $requestUrl',
      );
      return const [];
    }

    final responseConfig =
        (readerConfig['response'] as Map?)?.cast<String, dynamic>() ?? {};
    final imagesDef = responseConfig['images'] ?? readerConfig['images'];
    final defMap = _toDefMap(imagesDef);
    if (defMap == null) {
      _logger.w(
        '$_sourceId ajaxHtmlImages: response.images selector is missing',
      );
      return const [];
    }

    final selector = _fieldDefToSelector(defMap);
    if (selector == null) {
      _logger.w(
        '$_sourceId ajaxHtmlImages: response.images selector is invalid',
      );
      return const [];
    }

    final responseDoc = _parser.parse(responseHtml);
    final rawUrls = _parser.extractList(responseDoc, selector);
    final normalizedUrls = _normalizeChapterImageUrls(rawUrls);
    if (normalizedUrls.isEmpty) {
      _logger.w(
        '$_sourceId ajaxHtmlImages: no images extracted using selector "${selector.selector}"',
      );
    }

    return normalizedUrls;
  }

  Map<String, dynamic>? _extractAjaxRequestFields({
    required dom.Document readerDocument,
    required Map<String, dynamic> requestConfig,
    required String fieldGroup,
  }) {
    final defs =
        (requestConfig[fieldGroup] as Map?)?.cast<String, dynamic>() ?? {};
    final values = <String, dynamic>{};

    for (final entry in defs.entries) {
      final name = entry.key;
      final rawDef = entry.value;
      final required = rawDef is Map
          ? (rawDef.cast<String, dynamic>()['required'] as bool? ?? true)
          : true;

      final value = _extractAjaxRequestFieldValue(
        readerDocument: readerDocument,
        definition: rawDef,
      );
      if ((value == null || value.isEmpty) && required) {
        _logger.w(
          '$_sourceId ajaxHtmlImages: missing required $fieldGroup field "$name"',
        );
        return null;
      }
      if (value != null && value.isNotEmpty) {
        values[name] = value;
      }
    }

    return values;
  }

  String? _extractAjaxRequestFieldValue({
    required dom.Document readerDocument,
    required dynamic definition,
  }) {
    if (definition is String) return definition.trim();
    if (definition is num || definition is bool) return definition.toString();
    if (definition is! Map) return null;

    final map = definition.cast<String, dynamic>();
    final constant = map['value'];
    if (constant != null) {
      return constant.toString().trim();
    }

    final selector = _fieldDefToSelector(map);
    if (selector == null) return null;
    final value = _parser.extractString(readerDocument, selector)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  List<String> _extractScriptSlidesImageUrls(String htmlContent) {
    final slidesMatch = RegExp(
      r'slides_p_path\s*=\s*\[(.*?)\]\s*;',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(htmlContent);
    if (slidesMatch == null) {
      return const [];
    }

    final rawArray = slidesMatch.group(1);
    if (rawArray == null || rawArray.isEmpty) {
      return const [];
    }

    final encodedItems = RegExp(r"""["']([^"']+)["']""")
        .allMatches(rawArray)
        .map((match) => match.group(1))
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (encodedItems.isEmpty) {
      return const [];
    }

    final decodedUrls = <String>[];
    for (final item in encodedItems) {
      final decoded = _decodeMaybeBase64Url(item);
      if (decoded != null) {
        decodedUrls.add(decoded);
      }
    }

    return decodedUrls;
  }

  String? _decodeMaybeBase64Url(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    try {
      final decoded = utf8.decode(base64.decode(value)).trim();
      if (decoded.startsWith('http://') || decoded.startsWith('https://')) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  List<String> _normalizeChapterImageUrls(List<String> values) {
    if (values.isEmpty) return const [];

    final expanded = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final parsed = json.decode(trimmed);
          if (parsed is List) {
            for (final entry in parsed) {
              final asString = entry.toString();
              if (asString.isNotEmpty) {
                expanded.add(asString);
              }
            }
            continue;
          }
        } catch (_) {}
      }
      expanded.add(value);
    }

    final seen = <String>{};
    final normalized = <String>[];
    for (final raw in expanded) {
      final sanitized = _sanitizeImageUrl(raw);
      if (sanitized.isEmpty) continue;
      final resolved = _urlBuilder.resolve(sanitized, const {});
      if (seen.add(resolved)) {
        normalized.add(resolved);
      }
    }

    return normalized;
  }

  String _sanitizeImageUrl(String value) {
    var cleaned = value.trim();
    if (cleaned.length >= 2 &&
        ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
            (cleaned.startsWith("'") && cleaned.endsWith("'")))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    cleaned = cleaned
        .replaceAll(r'\/', '/')
        .replaceAll(r'\n', '')
        .replaceAll(r'\r', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();

    if (cleaned.startsWith('//')) {
      cleaned = 'https:$cleaned';
    }

    return cleaned;
  }

  bool _hasEnabledLink(dom.Document doc, String selector) {
    final link = doc.querySelector(selector);
    if (link == null) return false;

    final href = (link.attributes['href'] ?? '').trim();
    final hxGet = (link.attributes['hx-get'] ?? '').trim();
    if ((href.isEmpty || href == '#') && hxGet.isEmpty) return false;

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
