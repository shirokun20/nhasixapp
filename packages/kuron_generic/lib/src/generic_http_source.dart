/// Config-driven [ContentSource] implementation.
///
/// [GenericHttpSource] delegates all HTTP operations to either a
/// [GenericRestAdapter] (JSON API) or a [GenericScraperAdapter] (HTML scraping)
/// based on which block is present in the raw config JSON.
library;

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';

import 'adapters/generic_adapter.dart';
import 'adapters/generic_rest_adapter.dart';
import 'adapters/generic_scraper_adapter.dart';
import 'filters/generic_filter_transformer.dart';
import 'parsers/generic_html_parser.dart';
import 'parsers/generic_json_parser.dart';
import 'url_builder/generic_url_builder.dart';

/// A [ContentSource] that is entirely driven by a JSON config map.
///
/// No Dart code changes are required to add a new provider — only a new JSON
/// config file is needed. The config must contain either an `api` block
/// (REST/JSON) or a `scraper` block (HTML scraping).
class GenericHttpSource implements ContentSource {
  final Map<String, dynamic> _rawConfig;
  final Dio _dio;
  final HeadersGenerator? _headersGenerator;
  final DelayApplier? _delayApplier;
  final GenericAdapter _adapter;
  // ignore: unused_field — will be used in Phase 2 when filter UI is wired up
  final GenericFilterTransformer _filterTransformer;
  final Logger _logger;

  // Cached values from config
  final String _id;
  final String _displayName;
  final String _baseUrl;
  final String _iconPath;
  final bool _requiresBypass;
  final Map<String, String> _defaultHeaders;
  final int? _brandColorValue;

  GenericHttpSource({
    required Map<String, dynamic> rawConfig,
    required Dio dio,
    required Logger logger,
    HeadersGenerator? headersGenerator,
    DelayApplier? delayApplier,
    GenericAdapter? adapterOverride,
  })  : _rawConfig = rawConfig,
        _dio = dio,
        _headersGenerator = headersGenerator,
        _delayApplier = delayApplier,
        _logger = logger,
        _filterTransformer = const GenericFilterTransformer(),
        _id = rawConfig['source'] as String? ?? 'unknown',
        _displayName = _resolveDisplayName(rawConfig),
        _baseUrl = rawConfig['baseUrl'] as String? ?? '',
        _iconPath = rawConfig['iconPath'] as String? ??
            (rawConfig['ui'] as Map<String, dynamic>?)?['iconPath']
                as String? ??
            'assets/images/sources/generic.png',
        _requiresBypass = (rawConfig['network']
                as Map<String, dynamic>?)?['requiresBypass'] as bool? ??
            false,
        _defaultHeaders = _resolveHeaders(rawConfig),
        _brandColorValue = _resolveBrandColor(rawConfig),
        _adapter = adapterOverride ??
            _buildAdapter(
                rawConfig, dio, logger, headersGenerator, delayApplier);

  // ── ContentSource identity ─────────────────────────────────────────────────

  @override
  String get id => _id;

  @override
  String get displayName => _displayName;

  @override
  String get baseUrl => _baseUrl;

  @override
  String get iconPath => _iconPath;

  @override
  bool get requiresBypass => _requiresBypass;

  @override
  int? get brandColor => _brandColorValue;

  @override
  String get refererHeader => '$_baseUrl/';

  // ── Search capabilities ────────────────────────────────────────────────────

  @override
  SearchCapabilities get searchCapabilities {
    final search = _rawConfig['searchConfig'] as Map<String, dynamic>?;
    final supportsExclude = search?['supportsTagExclusion'] as bool? ?? false;
    return SearchCapabilities(
      supportsTagExclusion: supportsExclude,
      supportsAdvancedSyntax: false,
      availableFilters: const [FilterType.tag],
      availableSorts: SortOption.values,
      contentIdPattern: r'.*',
      searchHelpText: 'Enter keywords to search...',
    );
  }

  // ── Filter list ────────────────────────────────────────────────────────────

  @override
  FilterList get filterList {
    // Filters can be declared in config; for now return empty.
    // Future: parse config `filters` array into SourceFilter instances.
    return const [];
  }

  // ── Core operations ────────────────────────────────────────────────────────

  @override
  Future<ContentListResult> search(SearchFilter filter) async {
    final result = await _adapter.search(filter, _rawConfig);
    return ContentListResult(
      contents: result.items,
      currentPage: filter.page,
      totalPages: result.totalPages ??
          (result.hasNextPage ? filter.page + 1 : filter.page),
      totalCount: result.totalItems ?? result.items.length,
      hasNext: result.hasNextPage,
      hasPrevious: filter.page > 1,
    );
  }

  @override
  Future<Content> getDetail(String contentId) async {
    final result = await _adapter.fetchDetail(contentId, _rawConfig);
    return result.content.copyWith(imageUrls: result.imageUrls);
  }

  @override
  Future<ContentListResult> getList({
    int page = 1,
    SortOption sort = SortOption.newest,
  }) async {
    final filter = SearchFilter(query: '', page: page, sort: sort);
    return search(filter);
  }

  @override
  Future<ContentListResult> getPopular({
    PopularTimeframe timeframe = PopularTimeframe.allTime,
    int page = 1,
  }) async {
    final sort = _timeframeToSort(timeframe);
    return getList(page: page, sort: sort);
  }

  @override
  Future<List<Content>> getRandom({int count = 1}) async {
    try {
      final api = _rawConfig['api'] as Map<String, dynamic>?;
      final endpoints =
          (api?['endpoints'] as Map<String, dynamic>?) ?? const {};
      final configuredRandomEndpoint = endpoints['random']?.toString() ?? '';
      final randomEndpoint = configuredRandomEndpoint.isNotEmpty
          ? configuredRandomEndpoint
          : (_id == 'nhentai' ? '/api/v2/galleries/random' : '');
      final apiBase = api?['apiBase']?.toString() ?? _baseUrl;

      if (randomEndpoint.isEmpty) {
        _logger
            .d('$_id: getRandom not supported — no random endpoint configured');
        return const [];
      }

      _logger.i('$_id: Fetching random galleries (count: $count)');
      final results = <Content>[];

      for (var index = 0; index < count; index++) {
        try {
          final url = Uri.parse(apiBase).resolve(randomEndpoint).toString();
          _logger.d('$_id: Random request #${index + 1}: GET $url');

          await _prepareRandomRequest(referer: _baseUrl);
          final response = await _dio.get<dynamic>(
            url,
            options: Options(
              headers: _mergeHeaders(_dio.options.headers, {
                if (!_defaultHeaders.containsKey('Accept'))
                  'Accept': 'application/json',
                if (!_defaultHeaders.containsKey('Referer'))
                  'Referer': refererHeader,
              }),
            ),
          );

          final contentId = _extractRandomContentId(response.data, response);
          if (contentId == null || contentId.isEmpty) {
            _logger
                .w('$_id: Failed to extract content ID from random response');
            continue;
          }

          _logger.d('$_id: Extracted content ID: $contentId from random');
          final detail = await getDetail(contentId);
          results.add(detail);
        } catch (e) {
          _logger.w('$_id: Failed to fetch random gallery ${index + 1}: $e');
        }
      }

      _logger.i(
          '$_id: Successfully fetched ${results.length}/$count random galleries');
      return results;
    } catch (e, stackTrace) {
      _logger.e('$_id: Failed to get random galleries',
          error: e, stackTrace: stackTrace);
      return const [];
    }
  }

  Future<void> _prepareRandomRequest({String? referer}) async {
    if (_delayApplier != null) {
      await _delayApplier();
    }

    if (_headersGenerator != null) {
      final generatedHeaders = _headersGenerator(referer: referer);
      _dio.options.headers =
          _mergeHeaders(_dio.options.headers, generatedHeaders);
      return;
    }

    if (_defaultHeaders.isNotEmpty) {
      _dio.options.headers =
          _mergeHeaders(_dio.options.headers, _defaultHeaders);
    }
  }

  Map<String, dynamic> _mergeHeaders(
    Map<String, dynamic>? base,
    Map<String, dynamic> extra,
  ) {
    final merged = <String, dynamic>{
      if (base != null) ...base,
      ...extra,
    };
    return merged;
  }

  /// Extract content ID from a random API response.
  String? _extractRandomContentId(dynamic data, Response<dynamic> response) {
    try {
      if (data is Map<String, dynamic>) {
        final id = data['id'];
        if (id != null) {
          return id.toString();
        }

        final result = data['result'];
        if (result is Map<String, dynamic> && result['id'] != null) {
          return result['id'].toString();
        }

        if (result is List && result.isNotEmpty) {
          final first = result.first;
          if (first is Map<String, dynamic> && first['id'] != null) {
            return first['id'].toString();
          }
        }
      }

      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic> && first['id'] != null) {
          return first['id'].toString();
        }
      }

      if (data is String) {
        final idMatch = RegExp(r'"id"\s*:\s*(\d+)').firstMatch(data);
        if (idMatch != null) {
          return idMatch.group(1);
        }
      }

      final pathMatch = RegExp(r'/g/(\d+)/').firstMatch(response.realUri.path);
      if (pathMatch != null) {
        return pathMatch.group(1);
      }

      return null;
    } catch (e) {
      _logger.w('$_id: Failed to extract content ID from random response: $e');
      return null;
    }
  }

  @override
  Future<List<Content>> getRelated(String contentId) async {
    return _adapter.fetchRelated(contentId, _rawConfig);
  }

  @override
  Future<List<Comment>> getComments(String contentId) async {
    return _adapter.fetchComments(contentId, _rawConfig);
  }

  @override
  Future<ChapterData?> getChapterImages(String chapterId) async {
    return _adapter.fetchChapterImages(chapterId, _rawConfig);
  }

  /// Build the web-facing content URL from the `contentUrl` endpoint
  /// template in config (e.g. `"/g/{id}/"`). Returns empty string if
  /// the template is not defined in the config.
  String buildContentUrl(String contentId) {
    final api = _rawConfig['api'] as Map<String, dynamic>?;
    final endpoints = (api?['endpoints'] as Map<String, dynamic>?) ?? {};
    final template = endpoints['contentUrl'] as String? ?? '';
    if (template.isEmpty) return '';
    return GenericUrlBuilder(baseUrl: _baseUrl)
        .buildDetailUrl(template, contentId);
  }

  @override
  bool get participatesInGlobalSearch => true;

  @override
  int get globalSearchPriority => 100;

  @override
  int get globalSearchMaxResults => 5;

  @override
  bool canHandleGlobalQuery(String query) => true;

  @override
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions(
    String query,
  ) async =>
      const [];

  @override
  bool get supportsAuthentication => false;

  @override
  bool get supportsBookmarks => false;

  @override
  bool get showsPageCountInList => true;

  // ── URL building ───────────────────────────────────────────────────────────

  @override
  String buildImageUrl({
    required String contentId,
    required String mediaId,
    required int page,
    required String extension,
    bool thumbnail = false,
  }) {
    final tmpl = _rawConfig['imageUrlTemplate'] as String?;
    if (tmpl == null) return '';
    return tmpl
        .replaceAll('{contentId}', contentId)
        .replaceAll('{mediaId}', mediaId)
        .replaceAll('{page}', page.toString())
        .replaceAll('{ext}', extension)
        .replaceAll('{type}', thumbnail ? 'thumb' : 'image');
  }

  @override
  String buildThumbnailUrl({
    required String contentId,
    required String mediaId,
  }) =>
      buildImageUrl(
        contentId: contentId,
        mediaId: mediaId,
        page: 1,
        extension: 'jpg',
        thumbnail: true,
      );

  @override
  String? parseContentIdFromUrl(String url) {
    final pattern = _rawConfig['contentIdPattern'] as String?;
    if (pattern == null) return null;
    final match = RegExp(pattern).firstMatch(url);
    return match?.group(1);
  }

  @override
  bool isValidContentId(String contentId) {
    final pattern = _rawConfig['contentIdPattern'] as String?;
    if (pattern == null) return true;
    return RegExp(pattern).hasMatch(contentId);
  }

  // ── Download headers ───────────────────────────────────────────────────────

  @override
  Map<String, String> getImageDownloadHeaders({
    required String imageUrl,
    Map<String, String>? cookies,
  }) {
    final headers = Map<String, String>.from(_defaultHeaders);
    headers['Referer'] = refererHeader;

    // 🔥 HOTFIX: HentaiNexus throttles requests with minimal headers
    // Add full browser headers to bypass server-side rate limiting
    if (_id == 'hentainexus') {
      headers['Accept'] =
          'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8';
      headers['Accept-Encoding'] = 'gzip, deflate, br';
      headers['Accept-Language'] = 'en-US,en;q=0.9';
      headers['DNT'] = '1';
      headers['Sec-Fetch-Dest'] = 'image';
      headers['Sec-Fetch-Mode'] = 'no-cors';
      headers['Sec-Fetch-Site'] = 'cross-site';
      // Already have Referer, don't override

      // Enhance User-Agent to look more like Chrome
      if (!headers.containsKey('User-Agent') ||
          headers['User-Agent']?.isEmpty == true) {
        headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';
      }
    }

    if (cookies != null && cookies.isNotEmpty) {
      headers['Cookie'] =
          cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    if (_id == 'hitomi') {
      _logger.i(
        'hitomi download headers: imageUrl=$imageUrl, referer=${headers['Referer']}, headerKeys=${headers.keys.join(", ")}',
      );
    }
    return headers;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _resolveDisplayName(Map<String, dynamic> config) {
    final ui = config['ui'] as Map<String, dynamic>?;
    return (ui?['displayName'] as String?) ??
        (config['source'] as String? ?? 'Unknown Source');
  }

  static Map<String, String> _resolveHeaders(Map<String, dynamic> config) {
    final network = config['network'] as Map<String, dynamic>?;
    final headers = (network?['headers'] as Map<String, dynamic>?)
            ?.cast<String, String>() ??
        {};
    return headers;
  }

  static int? _resolveBrandColor(Map<String, dynamic> config) {
    final ui = config['ui'] as Map<String, dynamic>?;
    final colorStr = ui?['brandColor'] as String?;
    if (colorStr == null) return null;
    final hex = colorStr.replaceFirst('#', '');
    return int.tryParse('FF$hex', radix: 16);
  }

  static GenericAdapter _buildAdapter(
    Map<String, dynamic> rawConfig,
    Dio dio,
    Logger logger,
    HeadersGenerator? headersGenerator,
    DelayApplier? delayApplier,
  ) {
    final sourceId = rawConfig['source'] as String? ?? 'unknown';
    final baseUrl = rawConfig['baseUrl'] as String? ?? '';
    logger.d('[$sourceId] Adapter baseUrl: "$baseUrl"');

    final urlBuilder = GenericUrlBuilder(baseUrl: baseUrl);

    if (rawConfig.containsKey('scraper')) {
      // HTML scraping path — uses CSS selectors from config's `scraper` block.
      logger.d(
          '[$sourceId] Using GenericScraperAdapter (scraper block detected)');
      final htmlParser = GenericHtmlParser(logger: logger);
      return GenericScraperAdapter(
        dio: dio,
        urlBuilder: urlBuilder,
        parser: htmlParser,
        logger: logger,
        sourceId: sourceId,
      );
    } else {
      // REST / JSON API path — uses JSONPath selectors from config's `api` block.
      logger.d('[$sourceId] Using GenericRestAdapter (api block detected)');
      final jsonParser = GenericJsonParser(logger: logger);
      return GenericRestAdapter(
        dio: dio,
        urlBuilder: urlBuilder,
        parser: jsonParser,
        logger: logger,
        sourceId: sourceId,
        headersGenerator: headersGenerator,
        delayApplier: delayApplier,
      );
    }
  }

  SortOption _timeframeToSort(PopularTimeframe timeframe) {
    switch (timeframe) {
      case PopularTimeframe.today:
        return SortOption.popularToday;
      case PopularTimeframe.week:
        return SortOption.popularWeek;
      case PopularTimeframe.allTime:
        return SortOption.popular;
    }
  }
}
