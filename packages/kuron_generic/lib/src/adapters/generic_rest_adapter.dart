/// Generic REST adapter — handles JSON API sources.
///
/// Uses [GenericJsonParser] with JSONPath selectors from the config to map
/// API responses to [Content] entities.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';

import '../mappers/generic_content_mapper.dart';
import '../models/source_config_runtime.dart';
import '../parsers/generic_json_parser.dart';
import '../url_builder/generic_url_builder.dart';
import 'generic_adapter.dart';

/// Function type for generating anti-detection headers dynamically.
/// Returns a map of HTTP headers. Optional [referer] parameter can be passed.
typedef HeadersGenerator = Map<String, String> Function({String? referer});

/// Function type for applying rate limiting delays before HTTP requests.
/// Used to prevent IP banning by spreading out requests over time.
typedef DelayApplier = Future<void> Function();

class GenericRestAdapter implements GenericAdapter {
  final Dio _dio;
  final GenericUrlBuilder _urlBuilder;
  final GenericJsonParser _parser;
  final Logger _logger;
  final String _sourceId;
  final HeadersGenerator? _headersGenerator;
  final DelayApplier? _delayApplier;

  GenericRestAdapter({
    required Dio dio,
    required GenericUrlBuilder urlBuilder,
    required GenericJsonParser parser,
    required Logger logger,
    required String sourceId,
    HeadersGenerator? headersGenerator,
    DelayApplier? delayApplier,
  })  : _dio = dio,
        _urlBuilder = urlBuilder,
        _parser = parser,
        _logger = logger,
        _sourceId = sourceId,
        _headersGenerator = headersGenerator,
        _delayApplier = delayApplier;

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) async {
    final api = rawConfig['api'] as Map<String, dynamic>?;
    // ── Schema detection ────────────────────────────────────────────────────
    // New schema: config has `api.list` block with `items` + `fields`.
    // Old schema (nhentai): config uses flat `selectors` map.
    final apiList = api?['list'] as Map<String, dynamic>?;
    if (apiList != null) {
      return _searchNewSchema(filter, rawConfig, api!, apiList);
    }

    final endpoints =
        (api?['endpoints'] as Map<String, dynamic>?)?.cast<String, String>() ??
            {};

    // Build effective query from all active filters using `queryTokenTemplates`
    // declared in the source config's `searchConfig`.
    //
    // Template variables:
    //   `{type}` — the filter type (tag, artist, language, category, etc.)
    //   `{name}` — the filter value
    //
    // Example nhentai config:
    //   include: `{type}:"{name}"` → `tag:"big breasts"`, `language:"english"`
    //   exclude: `-{type}:"{name}"` → `-tag:"netorare"`
    //
    // Covers: includeTags, excludeTags (all typed) + language + category fields.
    final searchConfig =
        (rawConfig['searchConfig'] as Map<String, dynamic>?) ?? {};
    final tokenTemplates =
        searchConfig['queryTokenTemplates'] as Map<String, dynamic>?;
    final includeTemplate = tokenTemplates?['include'] as String?;
    final excludeTemplate = tokenTemplates?['exclude'] as String?;

    String effectiveQuery = filter.query.trim();
    final embeddedTokens = <String>[];

    if (includeTemplate != null) {
      // Build tokens for included filter items (tags, artists, characters, etc.)
      for (final item in filter.includeTags) {
        embeddedTokens.add(
          includeTemplate
              .replaceAll('{type}', item.type.toLowerCase())
              .replaceAll('{name}', item.name),
        );
      }

      // Build tokens for excluded filter items
      final excl = excludeTemplate ?? '-$includeTemplate';
      for (final item in filter.excludeTags) {
        embeddedTokens.add(
          excl
              .replaceAll('{type}', item.type.toLowerCase())
              .replaceAll('{name}', item.name),
        );
      }

      // Embed language and category as typed tokens (e.g. language:"english")
      if (filter.language != null && filter.language!.isNotEmpty) {
        embeddedTokens.add(
          includeTemplate
              .replaceAll('{type}', 'language')
              .replaceAll('{name}', filter.language!),
        );
      }
      if (filter.category != null && filter.category!.isNotEmpty) {
        embeddedTokens.add(
          includeTemplate
              .replaceAll('{type}', 'category')
              .replaceAll('{name}', filter.category!),
        );
      }
    }

    if (embeddedTokens.isNotEmpty) {
      effectiveQuery = [effectiveQuery, ...embeddedTokens]
          .where((s) => s.isNotEmpty)
          .join(' ');
    }

    // Use 'allGalleries' endpoint ONLY when there are truly no active filters.
    // If language/category/tags are set (even with empty text query), use 'search'.
    final isEmptyQuery = effectiveQuery.isEmpty && !filter.hasFilters;

    final searchTemplate = isEmptyQuery
        ? (endpoints['allGalleries'] ?? endpoints['search'] ?? '')
        : (endpoints['search'] ?? '');

    _logger.d('$_sourceId REST search config: api=$api');
    _logger.d(
        '$_sourceId REST search: effectiveQuery="$effectiveQuery", useAllGalleries=$isEmptyQuery, template="$searchTemplate"');

    if (searchTemplate.isEmpty) {
      _logger.w('$_sourceId: no search endpoint configured');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    // Build URL using the effective query (with embedded filter tokens).
    // For raw tag_id searches (e.g. from detail tag tap), prefer dedicated
    // tagSearch endpoint when configured.
    final adjustedFilter = effectiveQuery != filter.query.trim()
        ? filter.copyWith(query: effectiveQuery)
        : filter;
    final sortValue = _resolveSearchSortValue(adjustedFilter, rawConfig);
    final rawParams = _extractRawSearchParams(adjustedFilter.query);
    String url;

    if (rawParams != null && rawParams.isNotEmpty) {
      final rawMap = _parseRawQueryParams(rawParams);
      final tagIdValues = rawMap['tag_id'] ?? const <String>[];
      final tagId = tagIdValues.isNotEmpty ? tagIdValues.first.trim() : '';
      final tagSearchTemplate = endpoints['tagSearch'] ?? '';

      if (tagId.isNotEmpty && tagSearchTemplate.isNotEmpty) {
        final page = adjustedFilter.page > 0 ? adjustedFilter.page : 1;
        final baseTaggedUrl = _urlBuilder.resolve(tagSearchTemplate, {
          'tagId': tagId,
          'page': page.toString(),
          'sort': sortValue,
          'query': '',
        });

        final mergedParams = _parseUrlQueryParams(baseTaggedUrl);
        for (final entry in rawMap.entries) {
          mergedParams[entry.key] = entry.value;
        }

        if (sortValue.isNotEmpty &&
            !(mergedParams['sort']?.any((v) => v.trim().isNotEmpty) ?? false)) {
          mergedParams['sort'] = [sortValue];
        }

        url = _rebuildUrlWithQueryParams(baseTaggedUrl, mergedParams);
      } else {
        url = _buildRawSearchUrl(searchTemplate, rawParams, adjustedFilter);
      }
    } else {
      url = _urlBuilder.buildSearchUrl(
        searchTemplate,
        adjustedFilter,
        sortValue: sortValue,
      );
    }

    _logger.d('$_sourceId REST search: Built URL: $url');

    try {
      // Prepare request: apply delays + set anti-detection headers
      await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));

      _logger.d('$_sourceId REST search: Fetching URL: $url');
      final response = await _dio.get<dynamic>(url);
      _logger.d(
          '$_sourceId REST search: Got response status=${response.statusCode}');

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final selectors = (rawConfig['selectors'] as Map<String, dynamic>?) ?? {};
      final items = _parseItemList(data, selectors, rawConfig);
      _logger.d('$_sourceId REST search: Parsed ${items.length} items');

      final hasNext = _parseHasNextPage(data, selectors);
      final totalPages = _parseTotalPages(data, selectors);
      final totalItems = _parseTotalItems(data, selectors);

      return AdapterSearchResult(
        items: items,
        hasNextPage: hasNext,
        totalPages: totalPages,
        totalItems: totalItems,
      );
    } catch (e, stackTrace) {
      _logger.e('$_sourceId REST search failed',
          error: e, stackTrace: stackTrace);
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }
  }

  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final api = rawConfig['api'] as Map<String, dynamic>?;
    // ── Schema detection ────────────────────────────────────────────────────
    final apiDetail = api?['detail'] as Map<String, dynamic>?;
    if (apiDetail != null) {
      return _fetchDetailNewSchema(contentId, rawConfig, api!, apiDetail);
    }

    final endpoints =
        (api?['endpoints'] as Map<String, dynamic>?)?.cast<String, String>() ??
            {};
    final detailTemplate =
        endpoints['detail'] ?? endpoints['galleryDetail'] ?? '';
    if (detailTemplate.isEmpty) {
      _logger.w('$_sourceId: no detail endpoint configured');
      return AdapterDetailResult(
        content: _emptyContent(contentId),
        imageUrls: [],
      );
    }

    final url = _urlBuilder.buildDetailUrl(detailTemplate, contentId);
    _logger.d('$_sourceId REST detail: $url');

    try {
      // Prepare request: apply delays + set anti-detection headers
      await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));

      _logger.d('$_sourceId REST detail: Fetching URL: $url');
      final response = await _dio.get<dynamic>(url);
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final selectors = (rawConfig['selectors'] as Map<String, dynamic>?) ?? {};
      final imageUrls = _parseImageUrls(data, selectors, rawConfig);
      final content =
          _parseDetail(contentId, data, selectors, rawConfig, imageUrls);

      return AdapterDetailResult(content: content, imageUrls: imageUrls);
    } catch (e) {
      _logger.e('$_sourceId REST detail failed for $contentId', error: e);
      return AdapterDetailResult(
        content: _emptyContent(contentId),
        imageUrls: [],
      );
    }
  }

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final api = rawConfig['api'] as Map<String, dynamic>?;
    final endpoints =
        (api?['endpoints'] as Map<String, dynamic>?)?.cast<String, String>() ??
            {};
    final relatedTemplate = endpoints['related'] ?? '';
    if (relatedTemplate.isEmpty) return const [];

    final url = _urlBuilder.buildDetailUrl(relatedTemplate, contentId);
    try {
      // Prepare request: apply delays + set anti-detection headers
      await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));

      _logger.d('$_sourceId REST related: Fetching URL: $url');
      final response = await _dio.get<dynamic>(url);
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final selectors = (rawConfig['selectors'] as Map<String, dynamic>?) ?? {};
      return _parseItemList(data, selectors, rawConfig);
    } catch (e) {
      _logger.w('$_sourceId: fetchRelated failed for $contentId', error: e);
      return const [];
    }
  }

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final api = rawConfig['api'] as Map<String, dynamic>?;
    final endpoints =
        (api?['endpoints'] as Map<String, dynamic>?)?.cast<String, String>() ??
            {};
    final commentsTemplate = endpoints['comments'] ?? '';
    if (commentsTemplate.isEmpty) return const [];

    final url = _urlBuilder.buildDetailUrl(commentsTemplate, contentId);
    try {
      // Prepare request: apply delays + set anti-detection headers
      await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));

      _logger.d('$_sourceId REST comments: Fetching URL: $url');
      final response = await _dio.get<dynamic>(url);
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final selectors = (rawConfig['selectors'] as Map<String, dynamic>?) ?? {};
      return _parseCommentList(data, selectors, rawConfig);
    } catch (e) {
      _logger.w('$_sourceId: fetchComments failed for $contentId', error: e);
      return const [];
    }
  }

  @override
  Future<ChapterData?> fetchChapterImages(
    String chapterId,
    Map<String, dynamic> rawConfig,
  ) async {
    final imagesCfg = rawConfig['api']?['images'] as Map<String, dynamic>?;
    if (imagesCfg == null) return null;

    final mode = imagesCfg['mode'] as String?;
    if (mode == 'atHome') {
      final endpoint = imagesCfg['atHomeEndpoint'] as String?;
      if (endpoint == null) return null;

      final baseApiUrl = _getBaseUrl(rawConfig);
      final fullPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final url = '$baseApiUrl${fullPath.replaceAll('{chapterId}', chapterId)}';
      _logger.d('$_sourceId REST at-home request: $url');

      try {
        final data = await _getAtHomePayloadWithRetry(
          url,
          rawConfig,
          maxAttempts: 3,
        );

        final baseUrl = data['baseUrl'] as String?;
        final chapterNode = data['chapter'] as Map<String, dynamic>?;
        if (baseUrl != null && chapterNode != null) {
          final hash = chapterNode['hash'] as String?;
          final dataFiles = (chapterNode['data'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const <String>[];
          final dataSaverFiles = (chapterNode['dataSaver'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const <String>[];
          final useDataSaver = dataFiles.isEmpty && dataSaverFiles.isNotEmpty;
          final fileNames = useDataSaver ? dataSaverFiles : dataFiles;

          if (hash != null && fileNames.isNotEmpty) {
            final imagePathSegment = useDataSaver ? 'data-saver' : 'data';
            final images = fileNames
                .map((fn) => '$baseUrl/$imagePathSegment/$hash/$fn')
                .toList();
            return ChapterData(
              images: images,
            );
          }
        }
      } catch (e, st) {
        _logger.e('$_sourceId fetchChapterImages (atHome) failed',
            error: e, stackTrace: st);
      }
    }

    return null;
  }

  Future<dynamic> _getAtHomePayloadWithRetry(
    String url,
    Map<String, dynamic> rawConfig, {
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));
        final response = await _dio.get<dynamic>(
          url,
          options: Options(
            responseType: ResponseType.json,
            headers: const {
              'Accept': 'application/json',
              // For unstable mobile networks this can reduce half-closed
              // keep-alive socket issues on subsequent retries.
              'Connection': 'close',
            },
          ),
        );
        return response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
      } on DioException catch (e, st) {
        lastError = e;
        lastStackTrace = st;

        if (attempt >= maxAttempts || !_shouldRetryAtHomeDioError(e)) {
          rethrow;
        }

        _logger.w(
          '$_sourceId at-home transient error, retrying '
          '($attempt/$maxAttempts): ${e.message}',
        );
        await Future<void>.delayed(Duration(milliseconds: attempt * 250));
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        _logger.w(
          '$_sourceId at-home unknown transient error, retrying '
          '($attempt/$maxAttempts): $e',
        );
        await Future<void>.delayed(Duration(milliseconds: attempt * 250));
      }
    }

    if (lastError != null) {
      Error.throwWithStackTrace(
        lastError,
        lastStackTrace ?? StackTrace.current,
      );
    }
    throw StateError('Unexpected at-home retry flow termination');
  }

  bool _shouldRetryAtHomeDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    final message = (e.message ?? '').toLowerCase();
    if (message.contains('connection closed before full header') ||
        message.contains('connection reset by peer') ||
        message.contains('socket') ||
        message.contains('stream was terminated')) {
      return true;
    }

    final error = e.error;
    if (error is SocketException) return true;
    if (error is HttpException &&
        error.message.toLowerCase().contains(
              'connection closed before full header',
            )) {
      return true;
    }

    return false;
  }

  // ── New schema: api.list / api.detail ─────────────────────────────────────
  //
  // When `rawConfig['api']['list']` is present the adapter uses the declarative
  // field-map approach powered by [GenericContentMapper] instead of the
  // legacy flat-selectors path used by nhentai.
  //
  // New config shape:
  //   api.list.items      — JSONPath to items array   (e.g. "$.result[*]")
  //   api.list.fields     — map of fieldName → fieldDef  (see below)
  //   api.list.pagination — { totalPages: {path:…}, currentPage: {path:…} }
  //   api.detail.fields   — same field-map approach
  //   api.detail.images   — image URL builder config
  //
  // Field definitions (values in the `fields` map):
  //   { "selector": "$.id" }                    — scalar JSONPath extraction
  //   { "selector": "$.tags[*].name", "multi": true }  — list extraction
  //   { "type": "tagObjects", "selector": "$.tags[*]" } — nhentai tag split
  //   { "type": "coverBuilder", … }              — template cover URL

  Future<AdapterSearchResult> _searchNewSchema(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
    Map<String, dynamic> api,
    Map<String, dynamic> apiList,
  ) async {
    final endpoints =
        (api['endpoints'] as Map<String, dynamic>?)?.cast<String, String>() ??
            {};
    final isEmptyQuery = filter.query.trim().isEmpty && !filter.hasFilters;
    final template = isEmptyQuery
        ? (endpoints['allGalleries'] ?? endpoints['search'] ?? '')
        : (endpoints['search'] ?? '');
    if (template.isEmpty) {
      _logger.w('$_sourceId (new schema): no search endpoint configured');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    final rawParams = _extractRawSearchParams(filter.query);
    final sortValue = _resolveSearchSortValue(filter, rawConfig);
    String url = rawParams != null
        ? _buildRawSearchUrl(template, rawParams, filter)
        : _urlBuilder.buildSearchUrl(
            template,
            filter,
            sortValue: sortValue,
          );
    final paginationCfg =
        (apiList['pagination'] as Map<String, dynamic>?) ?? {};
    if (paginationCfg['offsetMode'] == true) {
      final pageSize = paginationCfg['pageSize'] as int? ?? 20;
      final maxOffset = paginationCfg['maxOffset'] as int?;
      var offset = ((filter.page > 0 ? filter.page : 1) - 1) * pageSize;
      // Guard offset-based sources that enforce strict query window caps.
      if (maxOffset != null && offset > maxOffset) {
        offset = maxOffset;
      }
      url = url.replaceAll('{offset}', offset.toString());
    }
    url = _applyLanguagePlaceholder(
      url,
      rawConfig,
      requestedLanguage: filter.language,
    );
    final queryRules = (api['queryRules'] as Map<String, dynamic>?)?['search']
        as Map<String, dynamic>?;
    url = _applyQueryRules(url, queryRules);
    _logger.d('$_sourceId REST [new schema] search: $url');

    try {
      await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));
      final response = await _dio.get<dynamic>(url);
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final itemsPath = apiList['items'] as String?;
      if (itemsPath == null) {
        return const AdapterSearchResult(items: [], hasNextPage: false);
      }

      final rawItems =
          _parser.extractItems(data, FieldSelector(selector: itemsPath));
      final fieldsConfig = (apiList['fields'] as Map<String, dynamic>?) ?? {};
      final items = rawItems
          .map((item) {
            final fields = _extractRestFields(item, fieldsConfig);
            return GenericContentMapper.toListItem(fields, sourceId: _sourceId);
          })
          .where((c) => c.id.isNotEmpty)
          .toList();

      // Pagination
      final paginationCfg =
          (apiList['pagination'] as Map<String, dynamic>?) ?? {};
      bool hasNext = true;
      int? totalPages;

      if (paginationCfg['offsetMode'] == true) {
        final totalStr = _extractRestScalar(data, paginationCfg['total']);
        final limitStr = _extractRestScalar(data, paginationCfg['limit']);
        final offsetStr = _extractRestScalar(data, paginationCfg['offset']);
        final maxOffset = paginationCfg['maxOffset'] as int?;

        final total = int.tryParse(totalStr ?? '');
        final limit = int.tryParse(limitStr ?? '');
        final offset = int.tryParse(offsetStr ?? '');

        if (total != null && limit != null && offset != null) {
          hasNext = (offset + limit) < total;
          totalPages = (total / limit).ceil();

          if (maxOffset != null && limit > 0) {
            final maxReachablePages = (maxOffset ~/ limit) + 1;
            if (totalPages > maxReachablePages) {
              totalPages = maxReachablePages;
            }

            // Prevent next-page navigation beyond allowed offset window.
            final nextOffset = offset + limit;
            if (nextOffset > maxOffset) {
              hasNext = false;
            }
          }
        }
      } else {
        final totalPagesStr =
            _extractRestScalar(data, paginationCfg['totalPages']);
        final currentPageStr =
            _extractRestScalar(data, paginationCfg['currentPage']);

        if (totalPagesStr != null && currentPageStr != null) {
          totalPages = int.tryParse(totalPagesStr);
          final current = int.tryParse(currentPageStr);
          if (totalPages != null && current != null) {
            hasNext = current < totalPages;
          }
        }
      }

      return AdapterSearchResult(
        items: items,
        hasNextPage: hasNext,
        totalPages: totalPages,
      );
    } catch (e, st) {
      _logger.e('$_sourceId REST new schema search failed',
          error: e, stackTrace: st);
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }
  }

  Future<AdapterDetailResult> _fetchDetailNewSchema(
    String contentId,
    Map<String, dynamic> rawConfig,
    Map<String, dynamic> api,
    Map<String, dynamic> apiDetail,
  ) async {
    final endpoints =
        (api['endpoints'] as Map<String, dynamic>?)?.cast<String, String>() ??
            {};
    final template = endpoints['detail'] ?? endpoints['galleryDetail'] ?? '';
    if (template.isEmpty) {
      _logger.w('$_sourceId (new schema): no detail endpoint configured');
      return AdapterDetailResult(
          content: _emptyContent(contentId), imageUrls: []);
    }

    final url = _urlBuilder.buildDetailUrl(template, contentId);
    final detailUrl = _applyLanguagePlaceholder(url, rawConfig);
    _logger.d('$_sourceId REST [new schema] detail: $detailUrl');

    try {
      await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));
      final response = await _dio.get<dynamic>(detailUrl);
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final fieldsConfig = (apiDetail['fields'] as Map<String, dynamic>?) ?? {};
      final fields = _extractRestFields(data, fieldsConfig);

      // Enrich tags/artists from configurable relationship mapping so UI chips
      // can carry stable IDs (e.g., UUID for authorOrArtist navigation).
      _applyConfiguredTagRelationsToFields(
        data: data,
        rawConfig: rawConfig,
        fields: fields,
      );

      // Optional statistics enrichment (e.g., MangaDex follows count).
      final statsCfg = api['statistics'] as Map<String, dynamic>?;
      if (statsCfg != null) {
        final followsEndpoint = statsCfg['followsEndpoint'] as String?;
        if (followsEndpoint != null && followsEndpoint.isNotEmpty) {
          final baseApiUrl = _getBaseUrl(rawConfig);
          final fullPath = followsEndpoint.startsWith('/')
              ? followsEndpoint
              : '/$followsEndpoint';
          final statsUrl =
              '$baseApiUrl${fullPath.replaceAll('{id}', contentId)}';

          try {
            final statsRes = await _dio.get<dynamic>(statsUrl);
            final statsData = statsRes.data is String
                ? jsonDecode(statsRes.data as String)
                : statsRes.data;

            final followsPath = statsCfg['followsPath'] as String?;
            final follows = _extractIntByPath(
              statsData,
              followsPath,
              dynamicId: contentId,
            );
            if (follows != null) {
              fields['favorites'] = follows;
            }
          } catch (e) {
            _logger.w('$_sourceId detail statistics fetch failed: $e');
          }
        }
      }

      // Image URLs
      List<String> imageUrls = const [];
      final imagesCfg = apiDetail['images'] as Map<String, dynamic>?;
      if (imagesCfg != null) {
        imageUrls = _buildImageUrlsFromTemplate(data, imagesCfg);
      }

      // Chapters
      List<Chapter>? chapters;
      final chaptersCfg = apiDetail['chapters'] as Map<String, dynamic>?;
      if (chaptersCfg != null) {
        final chapterEndpoint = chaptersCfg['endpoint'] as String?;
        if (chapterEndpoint != null) {
          final baseApiUrl = _getBaseUrl(rawConfig);
          final fullPath = chapterEndpoint.startsWith('/')
              ? chapterEndpoint
              : '/$chapterEndpoint';
          var chapterUrl =
              '$baseApiUrl${fullPath.replaceAll('{id}', contentId)}';
          chapterUrl = _applyLanguagePlaceholder(chapterUrl, rawConfig);
          final chapterQueryRules = (api['queryRules']
              as Map<String, dynamic>?)?['chapters'] as Map<String, dynamic>?;
          chapterUrl = _applyQueryRules(chapterUrl, chapterQueryRules);

          try {
            final itemsSelector = chaptersCfg['items'] as String?;
            if (itemsSelector != null) {
              final cFields =
                  (chaptersCfg['fields'] as Map<String, dynamic>?) ?? {};
              final fallbackFields =
                  (chaptersCfg['fallbackFields'] as Map<String, dynamic>?);
              chapters = await _fetchChapters(
                chapterUrl,
                itemsSelector: itemsSelector,
                cFields: cFields,
                rawConfig: rawConfig,
                fallbackFields: fallbackFields,
              );
            }
          } catch (e) {
            _logger.w('$_sourceId detail chapters fetch failed: $e');
          }
        }
      }

      final content = GenericContentMapper.toDetail(
        contentId,
        fields,
        sourceId: _sourceId,
        imageUrls: imageUrls,
        chapters: chapters,
      );
      return AdapterDetailResult(content: content, imageUrls: imageUrls);
    } catch (e) {
      _logger.e('$_sourceId REST new schema detail failed for $contentId',
          error: e);
      return AdapterDetailResult(
          content: _emptyContent(contentId), imageUrls: []);
    }
  }

  /// Extract all `fields` from a JSON [data] object according to `fieldsConfig`.
  ///
  /// Field def types:
  /// - default (`path`)  — JSONPath scalar (or list if `multi: true`)
  /// - `tagObjects`      — extract list of tag Maps and store as `tagObjects`
  ///   key so [GenericContentMapper] can split by type.
  /// - `coverBuilder`    — build cover URL via template (same as old adapter).
  Map<String, dynamic> _extractRestFields(
    dynamic data,
    Map<String, dynamic> fieldsConfig,
  ) {
    final result = <String, dynamic>{};
    for (final entry in fieldsConfig.entries) {
      final fieldName = entry.key;
      final def = entry.value;
      if (def is! Map<String, dynamic>) continue;

      final type = def['type'] as String? ?? 'path';
      final path = def['selector'] as String? ?? def['path'] as String? ?? '';

      switch (type) {
        case 'tagObjects':
          if (path.isNotEmpty) {
            final objs =
                _parser.extractItems(data, FieldSelector(selector: path));
            result['tagObjects'] = objs;
          }

        case 'coverBuilder':
          result[fieldName] = _buildCoverUrl(data, def, null) ?? '';

        default:
          if (path.isEmpty) continue;
          final multi = def['multi'] as bool? ?? false;
          final sel = FieldSelector(selector: path);
          if (multi) {
            result[fieldName] = _parser.extractList(data, sel);
          } else {
            result[fieldName] = _parser.extractRaw(data, sel);
          }
      }
    }
    return result;
  }

  /// Extract a scalar string from [data] using a field def `{path: "…"}`.
  String? _extractRestScalar(dynamic data, dynamic fieldDef) {
    if (fieldDef == null) return null;
    final path = fieldDef is Map ? fieldDef['path'] as String? ?? '' : '';
    if (path.isEmpty) return null;
    return _parser.extractString(data, FieldSelector(selector: path));
  }

  // ── Private parsers ────────────────────────────────────────────────────────

  List<Content> _parseItemList(
    dynamic data,
    Map<String, dynamic> selectors,
    Map<String, dynamic> rawConfig,
  ) {
    final itemsSelector = _selectorOrNull(selectors, 'items') ??
        _selectorOrNull(selectors, 'results');
    if (itemsSelector == null) return const [];

    final items = _parser.extractItems(data, itemsSelector);
    return items.map((item) => _parseItem(item, selectors, rawConfig)).toList();
  }

  List<Comment> _parseCommentList(dynamic data, Map<String, dynamic> selectors,
      Map<String, dynamic> rawConfig) {
    final commentsSelector = _selectorOrNull(selectors, 'comments');
    if (commentsSelector == null) return const [];

    final baseUrl = _getBaseUrl(rawConfig);
    final avatarBaseUrl = rawConfig['avatarBaseUrl'] as String? ?? baseUrl;
    final items = _parser.extractItems(data, commentsSelector);
    return items
        .map((item) => _parseComment(item, selectors, avatarBaseUrl))
        .toList();
  }

  Comment _parseComment(
      Map<String, dynamic> item, Map<String, dynamic> selectors,
      [String? baseUrl]) {
    final id = _extract(item, selectors, 'commentId') ?? '';
    final username =
        _extract(item, selectors, 'commentUsername') ?? 'Anonymous';
    final body = _extract(item, selectors, 'commentBody') ?? '';
    final rawAvatarUrl = _extract(item, selectors, 'commentAvatarUrl');
    final avatarUrl = _resolveAvatarUrl(rawAvatarUrl, baseUrl);
    _logger.t(
        '$_sourceId comment avatar: raw=$rawAvatarUrl → resolved=$avatarUrl');
    final postDateStr = _extract(item, selectors, 'commentPostDate');

    DateTime? postDate;
    if (postDateStr != null) {
      // Unix timestamp (seconds)
      final timestamp = int.tryParse(postDateStr);
      if (timestamp != null) {
        postDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }

    return Comment(
      id: id,
      username: username,
      body: body,
      avatarUrl: avatarUrl,
      postDate: postDate,
    );
  }

  Content _parseItem(
    Map<String, dynamic> item,
    Map<String, dynamic> selectors,
    Map<String, dynamic> rawConfig,
  ) {
    final id = _extract(item, selectors, 'id') ?? '';
    final title = _extract(item, selectors, 'listTitle') ??
        _extract(item, selectors, 'title') ??
        _extractNhentaiV2ListTitle(item);
    final mediaId = _extract(item, selectors, 'mediaId');

    // Build cover URL: prefer config-driven relative asset path, then legacy fields.
    final coverUrl = _extractResolvedAsset(
          item,
          selectors,
          key: 'listThumbnailPath',
          rawConfig: rawConfig,
          hostKey: 'thumbnail',
        ) ??
        _extractResolvedAsset(
          item,
          selectors,
          key: 'listCoverPath',
          rawConfig: rawConfig,
          hostKey: 'thumbnail',
        ) ??
        _resolveNhentaiV2CoverUrl(item) ??
        _extract(item, selectors, 'thumbnail') ??
        _extract(item, selectors, 'coverUrl') ??
        _buildCoverUrl(item, selectors, mediaId) ??
        '';

    final tagsRaw = _parser.extractList(
      item,
      _selectorOrDefault(
          selectors, 'tags', const FieldSelector(selector: r'$.tags[*].name')),
    );
    final tags = _stringsToTags(tagsRaw, 'tag');

    final artistsRaw = _parser.extractList(
      item,
      _selectorOrDefault(selectors, 'artists',
          const FieldSelector(selector: r'$.artists[*].name')),
    );

    final charactersRaw = _parser.extractList(
      item,
      _selectorOrDefault(selectors, 'characters',
          const FieldSelector(selector: r'$.characters[*].name')),
    );

    final tagIdsRaw = _selectorOrNull(selectors, 'tagIds') != null
        ? _parser.extractList(item, _selectorOrNull(selectors, 'tagIds')!)
        : const <String>[];
    final tagIdTokens = tagIdsRaw
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final blacklistCharacterTokens = tagIdTokens.isEmpty
        ? charactersRaw
        : <String>{...charactersRaw, ...tagIdTokens}.toList(growable: false);

    return Content(
      id: id,
      sourceId: _sourceId,
      title: title,
      coverUrl: coverUrl,
      tags: tags,
      artists: artistsRaw,
      characters: blacklistCharacterTokens,
      parodies: const [],
      groups: const [],
      language: _extractLanguage(item, selectors, rawConfig: rawConfig),
      pageCount:
          int.tryParse(_extract(item, selectors, 'pageCount') ?? '') ?? 0,
      imageUrls: const [],
      uploadDate: _parseDate(_extract(item, selectors, 'uploadDate')),
      mediaId: mediaId,
    );
  }

  Content _parseDetail(
    String contentId,
    dynamic data,
    Map<String, dynamic> selectors,
    Map<String, dynamic> rawConfig,
    List<String> imageUrls,
  ) {
    final id = _extract(data, selectors, 'id') ?? contentId;
    final title = _extract(data, selectors, 'detailTitle') ??
        _extract(data, selectors, 'title') ??
        _extractNhentaiV2DetailTitle(data);
    final mediaId = _extract(data, selectors, 'mediaId');
    final coverUrl = _extractResolvedAsset(
          data,
          selectors,
          key: 'detailCoverPath',
          rawConfig: rawConfig,
          hostKey: 'thumbnail',
        ) ??
        _extractResolvedAsset(
          data,
          selectors,
          key: 'detailThumbnailPath',
          rawConfig: rawConfig,
          hostKey: 'thumbnail',
        ) ??
        _resolveNhentaiV2CoverUrl(data) ??
        _extract(data, selectors, 'thumbnail') ??
        _extract(data, selectors, 'coverUrl') ??
        _buildCoverUrl(data, selectors, mediaId) ??
        (imageUrls.isNotEmpty ? imageUrls.first : '');

    // If the source puts ALL metadata (artists, characters, etc.) into a
    // single `tags[]` array differentiated by a `type` field (e.g. nhentai),
    // the config can declare a `tagObjects` selector pointing to that array.
    // The adapter will parse full objects and split by type, preserving id/count.
    final tagObjectsSel = _selectorOrNull(selectors, 'tagObjects');
    late List<Tag> tags;
    late List<String> artistsRaw;
    late List<String> charactersRaw;
    late List<String> parodiesRaw;
    late List<String> groupsRaw;
    String? splitLanguage;

    if (tagObjectsSel != null) {
      final split = _parseTagObjects(data, tagObjectsSel);
      tags = split.tags;
      artistsRaw = split.artists;
      charactersRaw = split.characters;
      parodiesRaw = split.parodies;
      groupsRaw = split.groups;
      splitLanguage = split.language.isNotEmpty ? split.language : null;
    } else {
      final tagsRaw = _parser.extractList(
        data,
        _selectorOrDefault(selectors, 'tags',
            const FieldSelector(selector: r'$.tags[*].name')),
      );
      tags = _stringsToTags(tagsRaw, 'tag');
      artistsRaw = _parser.extractList(
        data,
        _selectorOrDefault(selectors, 'artists',
            const FieldSelector(selector: r'$.artists[*].name')),
      );
      charactersRaw = _parser.extractList(
        data,
        _selectorOrDefault(selectors, 'characters',
            const FieldSelector(selector: r'$.characters[*].name')),
      );
      parodiesRaw = _parser.extractList(
        data,
        _selectorOrDefault(selectors, 'parodies',
            const FieldSelector(selector: r'$.parodies[*].name')),
      );
      groupsRaw = _parser.extractList(
        data,
        _selectorOrDefault(selectors, 'groups',
            const FieldSelector(selector: r'$.groups[*].name')),
      );

      _applyConfiguredTagRelations(
        data: data,
        rawConfig: rawConfig,
        tags: tags,
        artistsRaw: artistsRaw,
      );
    }

    final pageCountStr = _extract(data, selectors, 'pageCount');
    final pageCount = int.tryParse(pageCountStr ?? '') ?? imageUrls.length;
    final favoritesFromSelector =
        int.tryParse(_extract(data, selectors, 'favorites') ?? '');
    final favoritesFromNhentai = (data is Map)
        ? int.tryParse(data['num_favorites']?.toString() ?? '')
        : null;
    final favorites = favoritesFromSelector ?? favoritesFromNhentai ?? 0;

    return Content(
      id: id,
      sourceId: _sourceId,
      title: title,
      coverUrl: coverUrl,
      tags: tags,
      artists: artistsRaw,
      characters: charactersRaw,
      parodies: parodiesRaw,
      groups: groupsRaw,
      language: splitLanguage ??
          _extractLanguage(data, selectors, rawConfig: rawConfig),
      pageCount: pageCount,
      imageUrls: imageUrls,
      uploadDate: _parseDate(_extract(data, selectors, 'uploadDate')),
      favorites: favorites,
      englishTitle: _extract(data, selectors, 'detailEnglishTitle') ??
          _extract(data, selectors, 'englishTitle') ??
          _extractNhentaiV2Field(data, 'english'),
      japaneseTitle: _extract(data, selectors, 'detailJapaneseTitle') ??
          _extract(data, selectors, 'japaneseTitle') ??
          _extractNhentaiV2Field(data, 'japanese'),
      mediaId: mediaId,
    );
  }

  /// Extract image URLs from the response.
  ///
  /// Supports two modes:
  /// 1. Direct JSONPath selector under `selectors['imageUrls']` or `selectors['images']`
  /// 2. Template-based URL building via `selectors['imageUrlBuilder']` — used for sources
  ///    like nhentai where image URLs must be constructed from `media_id` + page extensions.
  List<String> _parseImageUrls(
    dynamic data,
    Map<String, dynamic> selectors,
    Map<String, dynamic> rawConfig,
  ) {
    final configuredPaths = _extractResolvedAssetList(
      data,
      selectors,
      key: 'imagePaths',
      rawConfig: rawConfig,
      hostKey: 'image',
    );
    if (configuredPaths.isNotEmpty) {
      return configuredPaths;
    }

    final nhentaiV2Urls = _resolveNhentaiV2ImageUrls(data);
    if (nhentaiV2Urls.isNotEmpty) {
      return nhentaiV2Urls;
    }

    // Mode 2: imageUrlBuilder (template + per-page extension list)
    final builder = selectors['imageUrlBuilder'] as Map<String, dynamic>?;
    if (builder != null) {
      return _buildImageUrlsFromTemplate(data, builder);
    }

    // Mode 1: direct JSONPath selector
    final imageSelector = _selectorOrNull(selectors, 'imageUrls') ??
        _selectorOrNull(selectors, 'images');
    if (imageSelector == null) return const [];
    return _parser.extractList(data, imageSelector);
  }

  bool _parseHasNextPage(dynamic data, Map<String, dynamic> selectors) {
    final totalPagesStr = _extract(data, selectors, 'totalPages');
    final currentPageStr = _extract(data, selectors, 'currentPage');
    if (totalPagesStr != null && currentPageStr != null) {
      final total = int.tryParse(totalPagesStr);
      final current = int.tryParse(currentPageStr);
      if (total != null && current != null) return current < total;
    }
    // If no pagination info, assume more pages unless empty result.
    return true;
  }

  int? _parseTotalPages(dynamic data, Map<String, dynamic> selectors) {
    final totalPagesStr = _extract(data, selectors, 'totalPages');
    if (totalPagesStr != null) {
      return int.tryParse(totalPagesStr);
    }
    return null;
  }

  int? _parseTotalItems(dynamic data, Map<String, dynamic> selectors) {
    final totalItemsStr = _extract(data, selectors, 'totalItems') ??
        _extract(data, selectors, 'totalCount');
    if (totalItemsStr != null) {
      return int.tryParse(totalItemsStr);
    }
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Extract headers from network.headers configuration block.
  Map<String, String> _extractHeaders(Map<String, dynamic> rawConfig) {
    _logger.d(
        '$_sourceId: _extractHeaders called, rawConfig keys: ${rawConfig.keys.toList()}');

    final network = rawConfig['network'] as Map<String, dynamic>?;
    if (network == null) {
      _logger.w('$_sourceId: network config is null');
      return const {};
    }

    _logger.d('$_sourceId: network keys: ${network.keys.toList()}');

    final headersRaw = network['headers'] as Map<String, dynamic>?;
    if (headersRaw == null) {
      _logger.w('$_sourceId: network.headers is null');
      return const {};
    }

    _logger.d('$_sourceId: Found ${headersRaw.length} headers in config');

    // Convert all values to strings
    final headers =
        headersRaw.map((key, value) => MapEntry(key, value.toString()));
    _logger.d('$_sourceId: Extracted headers: ${headers.keys.toList()}');
    return headers;
  }

  /// Merge Dio's default headers with configured headers.
  /// Configured headers take precedence for conflicts (e.g., override User-Agent).
  /// Preserves critical headers like cookies from Cloudflare bypass.
  Map<String, dynamic> _mergeHeaders(
    Map<String, dynamic> dioDefaultHeaders,
    Map<String, String> configuredHeaders,
  ) {
    final merged = <String, dynamic>{...dioDefaultHeaders};
    configuredHeaders.forEach((key, value) {
      merged[key] = value;
    });
    _logger.d(
        '$_sourceId: Merged headers - Dio: ${dioDefaultHeaders.length}, Configured: ${configuredHeaders.length}, Total: ${merged.length}');
    return merged;
  }

  /// Get request headers with proper priority:
  /// 1. If HeadersGenerator provided (AntiDetection), use it (highest priority)
  /// 2. Otherwise, merge config headers with Dio defaults
  /// 3. If no config headers, use Dio defaults only
  /// Prepare HTTP request by applying delays and setting anti-detection headers.
  ///
  /// This method mimics NhentaiApiClient's per-request preparation:
  /// 1. Apply rate limiting delay (if configured)
  /// 2. Generate and apply fresh headers to Dio instance (if configured)
  ///
  /// CRITICAL: Headers are set DIRECTLY on `_dio.options.headers`, not via `Options()`,
  /// to match the behavior of specialized sources like NhentaiSource.
  Future<void> _prepareRequest(
    Map<String, dynamic> rawConfig, {
    String? referer,
  }) async {
    // Step 1: Apply rate limiting delay (mimics AntiDetection.applyRandomDelay)
    if (_delayApplier != null) {
      await _delayApplier();
    }

    // Step 2: Apply anti-detection headers (mimics NhentaiApiClient behavior)
    if (_headersGenerator != null) {
      final generatedHeaders = _headersGenerator(referer: referer);
      _logger.d(
          '$_sourceId: Using dynamic headers generator (${generatedHeaders.length} headers)');

      // SET headers directly on Dio instance (not via Options)
      _dio.options.headers =
          _mergeHeaders(_dio.options.headers, generatedHeaders);
      return;
    }

    // Fallback: Use static config headers if no generator provided
    final configHeaders = _extractHeaders(rawConfig);
    if (configHeaders.isNotEmpty) {
      _logger.d(
          '$_sourceId: Using config headers (${configHeaders.length} headers)');
      _dio.options.headers = _mergeHeaders(_dio.options.headers, configHeaders);
      return;
    }

    // Priority 3: Dio defaults only (no modification needed)
    _logger.d('$_sourceId: Using Dio default headers only');
  }

  /// Extract base URL from config for referer header.
  String? _getBaseUrl(Map<String, dynamic> rawConfig) {
    return rawConfig['baseUrl'] as String?;
  }

  /// Resolves an avatar URL that may be:
  ///  - protocol-relative  (`//i1.nhentai.net/avatars/…`)
  ///  - root-relative      (`/avatars/…`)
  ///  - bare relative      (`avatars/177627.png?_=…`)  ← nhentai API format
  ///  - already absolute   (`https://…`)
  ///
  /// [avatarBaseUrl] should be the CDN origin declared in the source config
  /// as `avatarBaseUrl` (e.g. `https://i1.nhentai.net`).
  String? _resolveAvatarUrl(String? raw, String? avatarBaseUrl) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('https://') || raw.startsWith('http://')) return raw;
    if (raw.startsWith('//')) return 'https:$raw';

    final base = (avatarBaseUrl ?? '').replaceAll(RegExp(r'/+$'), '');
    if (raw.startsWith('/')) {
      return base.isNotEmpty ? '$base$raw' : 'https:/$raw';
    }
    // Bare relative path (nhentai: `avatars/3407292.png?_=…`)
    return base.isNotEmpty ? '$base/$raw' : raw;
  }

  String? _extractResolvedAsset(
    dynamic data,
    Map<String, dynamic> selectors, {
    required String key,
    required Map<String, dynamic> rawConfig,
    required String hostKey,
  }) {
    final value = _extract(data, selectors, key);
    if (value == null || value.trim().isEmpty) return null;
    return _resolveConfiguredAssetUrl(value, rawConfig, hostKey: hostKey);
  }

  List<String> _extractResolvedAssetList(
    dynamic data,
    Map<String, dynamic> selectors, {
    required String key,
    required Map<String, dynamic> rawConfig,
    required String hostKey,
  }) {
    final selector = _selectorOrNull(selectors, key);
    if (selector == null) return const [];

    return _parser
        .extractList(data, selector)
        .where((value) => value.trim().isNotEmpty)
        .map((value) =>
            _resolveConfiguredAssetUrl(value, rawConfig, hostKey: hostKey))
        .toList();
  }

  String _resolveConfiguredAssetUrl(
    String rawPath,
    Map<String, dynamic> rawConfig, {
    required String hostKey,
  }) {
    if (rawPath.startsWith('https://') || rawPath.startsWith('http://')) {
      return rawPath;
    }

    final assetHosts =
        (rawConfig['assetHosts'] as Map<String, dynamic>?) ?? const {};
    final host = assetHosts[hostKey]?.toString().trim() ?? '';
    if (host.isEmpty) return rawPath;

    final normalizedHost = host.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath =
        rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
    return '$normalizedHost/$normalizedPath';
  }

  String _extractNhentaiV2ListTitle(dynamic data) {
    if (!_isNhentaiV2Shape(data)) return 'Unknown';

    if (data is Map) {
      final english = data['english_title']?.toString().trim() ?? '';
      if (english.isNotEmpty) return english;

      final japanese = data['japanese_title']?.toString().trim() ?? '';
      if (japanese.isNotEmpty) return japanese;
    }

    return 'Unknown';
  }

  String _extractNhentaiV2DetailTitle(dynamic data) {
    if (!_isNhentaiV2Shape(data)) return 'Unknown';

    final pretty = _extractNhentaiV2Field(data, 'pretty');
    if (pretty != null && pretty.trim().isNotEmpty) {
      return pretty;
    }

    final english = _extractNhentaiV2Field(data, 'english');
    if (english != null && english.trim().isNotEmpty) {
      return english;
    }

    final japanese = _extractNhentaiV2Field(data, 'japanese');
    if (japanese != null && japanese.trim().isNotEmpty) {
      return japanese;
    }

    return 'Unknown';
  }

  String? _extractNhentaiV2Field(dynamic data, String field) {
    if (!_isNhentaiV2Shape(data) || data is! Map) return null;
    final title = data['title'];
    if (title is Map) {
      final value = title[field]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? _resolveNhentaiV2CoverUrl(dynamic data) {
    if (!_isNhentaiV2Shape(data) || data is! Map) return null;

    final thumbnail = data['thumbnail'];
    final cover = data['cover'];

    if (thumbnail is String && thumbnail.trim().isNotEmpty) {
      return _resolveNhentaiV2AssetUrl(thumbnail, thumbnail: true);
    }

    if (cover is Map) {
      final path = cover['path']?.toString().trim() ?? '';
      if (path.isNotEmpty) {
        return _resolveNhentaiV2AssetUrl(path, thumbnail: true);
      }
    }

    if (thumbnail is Map) {
      final path = thumbnail['path']?.toString().trim() ?? '';
      if (path.isNotEmpty) {
        return _resolveNhentaiV2AssetUrl(path, thumbnail: true);
      }
    }

    return null;
  }

  List<String> _resolveNhentaiV2ImageUrls(dynamic data) {
    if (!_isNhentaiV2Shape(data) || data is! Map) return const [];

    final pages = data['pages'];
    if (pages is! List) return const [];

    return pages
        .whereType<Map>()
        .map((page) => page['path']?.toString().trim() ?? '')
        .where((path) => path.isNotEmpty)
        .map((path) => _resolveNhentaiV2AssetUrl(path, thumbnail: false))
        .toList();
  }

  String _resolveNhentaiV2AssetUrl(
    String rawPath, {
    required bool thumbnail,
  }) {
    if (rawPath.startsWith('https://') || rawPath.startsWith('http://')) {
      return rawPath;
    }

    final normalized = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
    final host = thumbnail ? 'https://t.nhentai.net' : 'https://i.nhentai.net';
    return '$host/$normalized';
  }

  bool _isNhentaiV2Shape(dynamic data) {
    if (_sourceId != 'nhentai' || data is! Map) return false;

    return data.containsKey('media_id') &&
        (data.containsKey('thumbnail') ||
            data.containsKey('cover') ||
            data.containsKey('pages') ||
            data.containsKey('english_title'));
  }

  /// Convert raw string tag names to [Tag] entities with default values.
  List<Tag> _stringsToTags(List<String> names, String type) {
    return names
        .map((name) => Tag(id: 0, name: name, type: type, count: 0))
        .toList();
  }

  /// Parse full tag objects from a selector that points to an array like
  /// `[{"id":1,"name":"english","type":"language","count":12345}, …]`.
  ///
  /// Splits the list by `type` field so callers can populate separate
  /// entity fields (artists, characters, etc.) while keeping proper
  /// id/count on the pure-tag entries.
  _TagSplit _parseTagObjects(dynamic data, FieldSelector selector) {
    final objects = _parser.extractItems(data, selector);
    final tags = <Tag>[];
    final artists = <String>[];
    final characters = <String>[];
    final parodies = <String>[];
    final groups = <String>[];
    final languages = <String>[];

    for (final obj in objects) {
      final name = obj['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final type = obj['type']?.toString() ?? 'tag';
      final id = (obj['id'] as num?)?.toInt() ?? 0;
      final count = (obj['count'] as num?)?.toInt() ?? 0;

      // Always add to tags list (preserves id/count for display).
      // Also populate the typed string lists used by metadata section.
      switch (type) {
        case 'artist':
          artists.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'character':
          characters.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'parody':
          parodies.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'group':
          groups.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'language':
          if (name != 'translated') {
            languages.add(name);
            tags.add(Tag(id: id, name: name, type: type, count: count));
          }
        default:
          // 'tag', 'category', any unknown type
          tags.add(Tag(id: id, name: name, type: type, count: count));
      }
    }

    return _TagSplit(
      tags: tags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: languages.isNotEmpty ? languages.first : '',
    );
  }

  /// Parse a date string, defaulting to epoch on failure.
  DateTime _parseDate(String? raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    // Try unix timestamp (seconds)
    final seconds = int.tryParse(raw);
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String? _extract(dynamic data, Map<String, dynamic> selectors, String key) {
    final sel = _selectorOrNull(selectors, key);
    if (sel == null) return null;
    return _parser.extractString(data, sel);
  }

  /// Extract language, skipping "translated" — matches native CommentModel.fromApi logic.
  /// nhentai tags often include both the real language (e.g. "chinese") AND "translated",
  /// so the plain JSONPath selector may return "translated" first depending on tag order.
  /// This method uses extractList and picks the first non-"translated" value.
  String _extractLanguage(
    dynamic data,
    Map<String, dynamic> selectors, {
    Map<String, dynamic>? rawConfig,
  }) {
    final sel = _selectorOrNull(selectors, 'language');
    if (sel != null) {
      final values = _parser.extractList(data, sel);
      final language =
          values.firstWhere((v) => v != 'translated', orElse: () => '');
      if (language.isNotEmpty) return language;
    }

    final tagIdLanguage =
        _extractLanguageFromTagIds(data, selectors, rawConfig: rawConfig);
    if (tagIdLanguage != null && tagIdLanguage.isNotEmpty) {
      return tagIdLanguage;
    }

    return 'unknown';
  }

  String? _extractLanguageFromTagIds(
    dynamic data,
    Map<String, dynamic> selectors, {
    Map<String, dynamic>? rawConfig,
  }) {
    final tagIdsSelector = _selectorOrNull(selectors, 'tagIds');
    if (tagIdsSelector == null) return null;

    final rawTagIds = _parser.extractList(data, tagIdsSelector);
    if (rawTagIds.isEmpty) return null;

    final rawLanguageTagMap =
        (rawConfig?['languageTagMap'] as Map<String, dynamic>?) ?? const {};
    if (rawLanguageTagMap.isEmpty) return null;

    final languageTagMap = <String, String>{};
    rawLanguageTagMap.forEach((key, value) {
      final normalizedKey = key.toString().trim();
      final normalizedValue = value.toString().trim();
      if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
        languageTagMap[normalizedKey] = normalizedValue;
      }
    });
    if (languageTagMap.isEmpty) return null;

    for (final tagId in rawTagIds) {
      final normalizedTagId = tagId.toString().trim();
      if (normalizedTagId.isEmpty) continue;

      final language = languageTagMap[normalizedTagId] ?? '';
      if (language.isNotEmpty && language.toLowerCase() != 'translated') {
        return language;
      }
    }

    return null;
  }

  FieldSelector? _selectorOrNull(Map<String, dynamic> selectors, String key) {
    final raw = selectors[key];
    if (raw == null) return null;
    if (raw is String) return FieldSelector(selector: raw);
    if (raw is Map<String, dynamic>) return FieldSelector.fromMap(raw);
    return null;
  }

  FieldSelector _selectorOrDefault(
      Map<String, dynamic> selectors, String key, FieldSelector fallback) {
    return _selectorOrNull(selectors, key) ?? fallback;
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

  void _applyConfiguredTagRelationsToFields({
    required dynamic data,
    required Map<String, dynamic> rawConfig,
    required Map<String, dynamic> fields,
  }) {
    final currentTags = fields['tags'];
    final tags = <Tag>[];

    if (currentTags is List<Tag>) {
      tags.addAll(currentTags);
    } else if (currentTags is List) {
      tags.addAll(
        currentTags
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .map((name) => Tag(id: 0, name: name, type: 'tag', count: 0)),
      );
    }

    final artists = <String>[];
    final currentArtists = fields['artists'];
    if (currentArtists is List) {
      artists.addAll(
        currentArtists
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    }

    _applyConfiguredTagRelations(
      data: data,
      rawConfig: rawConfig,
      tags: tags,
      artistsRaw: artists,
    );

    fields['tags'] = tags;
    fields['artists'] = artists;
  }

  void _applyConfiguredTagRelations({
    required dynamic data,
    required Map<String, dynamic> rawConfig,
    required List<Tag> tags,
    required List<String> artistsRaw,
  }) {
    final api = rawConfig['api'] as Map<String, dynamic>?;
    final detail = api?['detail'] as Map<String, dynamic>?;
    final relationConfig = detail?['tagRelations'] as Map<String, dynamic>?;
    if (relationConfig == null) return;

    final sourcePath = relationConfig['sourcePath'] as String?;
    final mappings = relationConfig['mappings'] as List<dynamic>?;
    if (sourcePath == null || sourcePath.isEmpty || mappings == null) {
      return;
    }

    final relations =
        _parser.extractItems(data, FieldSelector(selector: sourcePath));
    if (relations.isEmpty) return;

    for (final rawMapping in mappings.whereType<Map<String, dynamic>>()) {
      final relationType =
          (rawMapping['relationshipType'] as String? ?? '').toLowerCase();
      final tagType = (rawMapping['tagType'] as String? ?? relationType)
          .trim()
          .toLowerCase();
      final namePath =
          (rawMapping['namePath'] as String? ?? 'attributes.name').trim();
      final idPath = (rawMapping['idPath'] as String? ?? 'id').trim();
      final appendToArtists = rawMapping['appendToArtists'] == true;

      if (relationType.isEmpty || tagType.isEmpty) continue;

      for (final rel in relations.whereType<Map<String, dynamic>>()) {
        final relType = (rel['type'] as String? ?? '').trim().toLowerCase();
        if (relType != relationType) continue;

        final relName =
            _extractSimplePathValue(rel, namePath)?.toString().trim() ?? '';
        if (relName.isEmpty) continue;

        final relId =
            _extractSimplePathValue(rel, idPath)?.toString().trim() ?? '';
        final slug = relId.isEmpty ? null : relId;

        if (appendToArtists && !artistsRaw.contains(relName)) {
          artistsRaw.add(relName);
        }

        final exists = tags.any((t) =>
            t.type.toLowerCase() == tagType &&
            t.name.toLowerCase() == relName.toLowerCase());
        if (!exists) {
          tags.add(Tag(
            id: 0,
            name: relName,
            type: tagType,
            count: 0,
            slug: slug,
          ));
        }
      }
    }
  }

  // ── URL builder helpers ────────────────────────────────────────────────────

  /// Build a cover/thumbnail URL for a list item using the `coverUrlBuilder`
  /// config block. Returns null if the block is absent or required data is
  /// missing.
  ///
  /// Config shape:
  /// ```json
  /// "coverUrlBuilder": {
  ///   "mediaIdSelector": "$.media_id",
  ///   "coverExtSelector": "$.images.cover.t",
  ///   "template": "https://t.nhentai.net/galleries/{mediaId}/cover.{ext}",
  ///   "extensionMapping": { "j": "jpg", "p": "png", "g": "gif", "w": "webp" }
  /// }
  /// ```
  String? _buildCoverUrl(
    dynamic data,
    Map<String, dynamic> selectors,
    String? alreadyExtractedMediaId,
  ) {
    final builder = selectors.containsKey('mangaIdPath')
        ? selectors
        : selectors['coverUrlBuilder'] as Map<String, dynamic>?;
    if (builder == null) return null;

    final template = builder['template'] as String?;
    if (template == null) return null;

    if (builder.containsKey('mangaIdPath')) {
      final mangaIdSel = builder['mangaIdPath'] as String?;
      final filenameSel = builder['filenamePath'] as String?;

      final mangaId = mangaIdSel != null
          ? _parser.extractString(data, FieldSelector(selector: mangaIdSel))
          : alreadyExtractedMediaId;
      final filename = filenameSel != null
          ? _parser.extractString(data, FieldSelector(selector: filenameSel))
          : null;

      if (mangaId != null && filename != null) {
        return template
            .replaceAll('{mangaId}', mangaId)
            .replaceAll('{fileName}', filename);
      }
      return null;
    }

    // Resolve media_id
    final mediaIdSel = builder['mediaIdSelector'] as String?;
    final mediaId = alreadyExtractedMediaId ??
        (mediaIdSel != null
            ? _parser.extractString(data, FieldSelector(selector: mediaIdSel))
            : null);
    if (mediaId == null) return null;

    // Resolve extension
    final extSel = builder['coverExtSelector'] as String?;
    String ext = 'jpg'; // safe default
    if (extSel != null) {
      final extCode =
          _parser.extractString(data, FieldSelector(selector: extSel));
      if (extCode != null) {
        final mapping = (builder['extensionMapping'] as Map<String, dynamic>?)
            ?.cast<String, String>();
        ext = mapping?[extCode] ?? ext;
      }
    }

    // Smart webp handling: some CDNs (like nhentai) convert originals to webp
    // and serve them with double extension (e.g., thumb.jpg.webp)
    // If preferWebpSuffix is true, append .webp to the resolved extension
    final preferWebp = builder['preferWebpSuffix'] as bool? ?? false;
    String finalUrl =
        template.replaceAll('{mediaId}', mediaId).replaceAll('{ext}', ext);

    if (preferWebp && !finalUrl.endsWith('.webp')) {
      finalUrl = '$finalUrl.webp';
    }

    return finalUrl;
  }

  int? _extractIntByPath(
    dynamic data,
    String? path, {
    String? dynamicId,
  }) {
    final value = _extractDynamicPathValue(data, path, dynamicId: dynamicId);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  dynamic _extractDynamicPathValue(
    dynamic data,
    String? path, {
    String? dynamicId,
  }) {
    if (path == null || path.isEmpty) return null;

    if (path.contains('{id}') && dynamicId != null) {
      final normalized = path.replaceAll('{id}', dynamicId);
      return _extractSimplePathValue(data, normalized);
    }

    return _parser.extractRaw(data, FieldSelector(selector: path));
  }

  dynamic _extractSimplePathValue(dynamic data, String path) {
    var current = data;
    final normalized = path.trim().replaceFirst(r'$.', '');
    if (normalized.isEmpty) return null;

    final keys = normalized
        .split('.')
        .map((k) => k.replaceAll("'", '').replaceAll('"', '').trim())
        .where((k) => k.isNotEmpty)
        .toList();

    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current;
  }

  String _applyLanguagePlaceholder(
    String url,
    Map<String, dynamic> rawConfig, {
    String? requestedLanguage,
  }) {
    if (!url.contains('{language}')) return url;
    final language = _resolveLanguageCode(
      requestedLanguage: requestedLanguage,
      defaultLanguage: rawConfig['defaultLanguage'] as String?,
    );
    if (language == 'all') {
      return _removeLanguagePlaceholderParam(url);
    }
    return url.replaceAll('{language}', language);
  }

  String _resolveLanguageCode({
    String? requestedLanguage,
    String? defaultLanguage,
  }) {
    final raw = (requestedLanguage ?? defaultLanguage ?? 'en').trim();
    if (raw.isEmpty) return 'en';

    final normalized = raw.toLowerCase().replaceAll('_', '-');
    if (RegExp(r'^[a-z]{2}(-[a-z0-9]+)?$').hasMatch(normalized)) {
      return normalized;
    }

    const mapping = <String, String>{
      'all': 'all',
      'all languages': 'all',
      'english': 'en',
      'indonesian': 'id',
      'indonesia': 'id',
      'japanese': 'ja',
      'korean': 'ko',
      'chinese': 'zh',
      'simplified chinese': 'zh-hans',
      'traditional chinese': 'zh-hant',
      'vietnamese': 'vi',
      'thai': 'th',
      'spanish': 'es',
      'portuguese': 'pt',
      'french': 'fr',
      'german': 'de',
      'italian': 'it',
      'russian': 'ru',
      'turkish': 'tr',
      'arabic': 'ar',
      'polish': 'pl',
    };

    return mapping[normalized] ?? 'en';
  }

  Future<List<Chapter>> _fetchChapters(
    String url, {
    required String itemsSelector,
    required Map<String, dynamic> cFields,
    required Map<String, dynamic> rawConfig,
    Map<String, dynamic>? fallbackFields,
  }) async {
    final chapters = <Chapter>[];
    var pageUrl = url;
    var guard = 0;

    while (true) {
      await _prepareRequest(rawConfig, referer: _getBaseUrl(rawConfig));
      final chapterRes = await _dio.get<dynamic>(pageUrl);
      final cData = chapterRes.data is String
          ? jsonDecode(chapterRes.data as String)
          : chapterRes.data;

      final rawChapters =
          _parser.extractItems(cData, FieldSelector(selector: itemsSelector));
      for (final c in rawChapters) {
        final cFieldsExtracted = _extractRestFields(c, cFields);
        _applyFallbackFields(cFieldsExtracted, c, fallbackFields);
        chapters.add(GenericContentMapper.toChapter(cFieldsExtracted));
      }

      final nextUrl = _nextOffsetPageUrl(pageUrl, cData);
      if (nextUrl == null) {
        break;
      }

      pageUrl = nextUrl;
      guard += 1;
      if (guard > 200) {
        _logger.w(
          '$_sourceId chapter pagination guard reached, stopping at ${chapters.length} items',
        );
        break;
      }
    }

    return chapters;
  }

  String? _nextOffsetPageUrl(String currentUrl, dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final total = (data['total'] as num?)?.toInt();
    final limit = (data['limit'] as num?)?.toInt();
    final offset = (data['offset'] as num?)?.toInt();

    if (total == null || limit == null || offset == null || limit <= 0) {
      return null;
    }

    final nextOffset = offset + limit;
    if (nextOffset >= total) return null;

    return _upsertQueryParam(currentUrl, 'offset', nextOffset.toString());
  }

  String _upsertQueryParam(String url, String key, String value) {
    final stripped = _removeQueryParam(url, key);
    final separator = stripped.contains('?') ? '&' : '?';
    return '$stripped$separator'
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}';
  }

  String _removeLanguagePlaceholderParam(String url) {
    return url
        .replaceAll(RegExp(r'([?&])[^=&]*=\{language\}(?=&|$)'), '')
        .replaceAll('?&', '?')
        .replaceAll(RegExp(r'[?&]$'), '');
  }

  String _resolveSearchSortValue(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) {
    final searchConfig =
        (rawConfig['searchConfig'] as Map<String, dynamic>?) ?? const {};

    final sortingConfig =
        (searchConfig['sortingConfig'] as Map<String, dynamic>?) ?? const {};
    final options =
        (sortingConfig['options'] as List<dynamic>?) ?? const <dynamic>[];

    final candidates = <String>{
      filter.sort.name,
      filter.sort.apiValue,
      _toKebabCase(filter.sort.name),
    }..removeWhere((value) => value.trim().isEmpty);

    for (final option in options) {
      if (option is! Map<String, dynamic>) continue;

      final value = option['value']?.toString().trim() ?? '';
      final apiValue = option['apiValue']?.toString().trim() ?? '';

      if (candidates.contains(value) || candidates.contains(apiValue)) {
        return apiValue;
      }
    }

    if (_isNhentaiV2Search(rawConfig)) {
      switch (filter.sort) {
        case SortOption.newest:
          return 'date';
        case SortOption.popular:
        case SortOption.popularToday:
        case SortOption.popularWeek:
        case SortOption.popularMonth:
          return filter.sort.apiValue;
      }
    }

    return '';
  }

  bool _isNhentaiV2Search(Map<String, dynamic> rawConfig) {
    final api = rawConfig['api'] as Map<String, dynamic>?;
    final apiBase = api?['apiBase']?.toString() ?? '';
    final endpoints = (api?['endpoints'] as Map<String, dynamic>?) ?? const {};
    final searchEndpoint = endpoints['search']?.toString() ?? '';

    return _sourceId == 'nhentai' &&
        (apiBase.contains('/api/v2') || searchEndpoint.contains('/api/v2/'));
  }

  String _toKebabCase(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}-${match.group(2)}',
        )
        .toLowerCase();
  }

  String _removeQueryParam(String url, String paramName) {
    final escaped = RegExp.escape(paramName);
    return url
        .replaceAll(RegExp('([?&])$escaped=[^&]*(?=&|\$)'), '')
        .replaceAll('?&', '?')
        .replaceAll(RegExp(r'[?&]$'), '');
  }

  String? _extractRawSearchParams(String query) {
    if (!query.startsWith('raw:')) return null;
    return query.substring(4);
  }

  String _buildRawSearchUrl(
    String template,
    String rawParams,
    SearchFilter filter,
  ) {
    final page = filter.page > 0 ? filter.page : 1;
    final baseUrl = _urlBuilder.resolve(template, {
      'query': '',
      'page': page.toString(),
      'sort': '',
    });

    if (rawParams.trim().isEmpty) {
      return baseUrl;
    }

    final templateParams = _parseUrlQueryParams(baseUrl);
    final rawMap = _parseRawQueryParams(rawParams);

    final merged = <String, List<String>>{};

    for (final entry in templateParams.entries) {
      final hasAnyValue =
          entry.value.any((v) => v.trim().isNotEmpty || v == '{offset}');
      if (hasAnyValue || rawMap.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }

    for (final entry in rawMap.entries) {
      merged[entry.key] = entry.value;
    }

    return _rebuildUrlWithQueryParams(baseUrl, merged);
  }

  Map<String, List<String>> _parseUrlQueryParams(String url) {
    final qIdx = url.indexOf('?');
    if (qIdx < 0 || qIdx + 1 >= url.length) {
      return {};
    }
    return _parseRawQueryParams(url.substring(qIdx + 1));
  }

  Map<String, List<String>> _parseRawQueryParams(String raw) {
    final result = <String, List<String>>{};
    for (final pair in raw.split('&')) {
      if (pair.isEmpty) continue;
      final idx = pair.indexOf('=');
      if (idx < 0) continue;
      final key = Uri.decodeQueryComponent(pair.substring(0, idx));
      final value = Uri.decodeQueryComponent(pair.substring(idx + 1));
      result.putIfAbsent(key, () => <String>[]).add(value);
    }
    return result;
  }

  String _rebuildUrlWithQueryParams(
      String baseUrl, Map<String, List<String>> p) {
    final qIdx = baseUrl.indexOf('?');
    final path = qIdx >= 0 ? baseUrl.substring(0, qIdx) : baseUrl;
    if (p.isEmpty) return path;

    final pairs = <String>[];
    for (final entry in p.entries) {
      if (entry.value.isEmpty) {
        pairs.add('${entry.key}=');
        continue;
      }
      for (final value in entry.value) {
        final encodedValue = (value.startsWith('{') && value.endsWith('}'))
            ? value
            : Uri.encodeQueryComponent(value);
        pairs.add('${entry.key}=$encodedValue');
      }
    }

    return '$path?${pairs.join('&')}';
  }

  String _applyQueryRules(String url, Map<String, dynamic>? rules) {
    if (rules == null) return url;

    var normalized = url;

    final enforceMulti =
        rules['enforceMultiValueParams'] as Map<String, dynamic>?;
    if (enforceMulti != null) {
      for (final entry in enforceMulti.entries) {
        final values = _toStringList(entry.value);
        if (values.isEmpty) continue;
        normalized = _replaceMultiValueParam(
          normalized,
          paramName: entry.key,
          values: values,
        );
      }
    }

    final ensureSingle = rules['ensureParams'] as Map<String, dynamic>?;
    if (ensureSingle != null) {
      for (final entry in ensureSingle.entries) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isEmpty) continue;
        normalized = _ensureQueryParam(normalized, entry.key, value);
      }
    }

    final ensureMultiIfMissing =
        rules['ensureMultiValueParamsIfMissing'] as Map<String, dynamic>?;
    if (ensureMultiIfMissing != null) {
      for (final entry in ensureMultiIfMissing.entries) {
        final values = _toStringList(entry.value);
        if (values.isEmpty) continue;
        normalized = _ensureMultiValueParamIfMissing(
          normalized,
          paramName: entry.key,
          values: values,
        );
      }
    }

    return normalized;
  }

  List<String> _toStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _replaceMultiValueParam(
    String url, {
    required String paramName,
    required List<String> values,
  }) {
    var normalized = _removeQueryParam(url, paramName);
    for (final value in values) {
      normalized = normalized.contains('?')
          ? '$normalized&$paramName=$value'
          : '$normalized?$paramName=$value';
    }
    return normalized;
  }

  String _ensureQueryParam(String url, String paramName, String value) {
    if (url.contains('$paramName=')) return url;
    return url.contains('?')
        ? '$url&$paramName=$value'
        : '$url?$paramName=$value';
  }

  String _ensureMultiValueParamIfMissing(
    String url, {
    required String paramName,
    required List<String> values,
  }) {
    if (url.contains('$paramName=')) return url;
    var normalized = url;
    for (final value in values) {
      normalized = normalized.contains('?')
          ? '$normalized&$paramName=$value'
          : '$normalized?$paramName=$value';
    }
    return normalized;
  }

  void _applyFallbackFields(
    Map<String, dynamic> extracted,
    dynamic item,
    Map<String, dynamic>? fallbackFields,
  ) {
    if (fallbackFields == null || fallbackFields.isEmpty) return;

    for (final entry in fallbackFields.entries) {
      final fieldName = entry.key;
      final selector = entry.value?.toString().trim() ?? '';
      if (selector.isEmpty) continue;

      final current = extracted[fieldName]?.toString().trim() ?? '';
      if (current.isNotEmpty) continue;

      final value = _parser.extractString(
        item,
        FieldSelector(selector: selector),
      );
      if (value != null && value.trim().isNotEmpty) {
        extracted[fieldName] = value.trim();
      }
    }
  }

  /// Build the full list of image URLs for a detail response using the
  /// `imageUrlBuilder` config block.
  ///
  /// Config shape:
  /// ```json
  /// "imageUrlBuilder": {
  ///   "mediaIdSelector": "$.media_id",
  ///   "pageExtSelector": "$.images.pages[*].t",
  ///   "template": "https://i.nhentai.net/galleries/{mediaId}/{page}.{ext}",
  ///   "extensionMapping": { "j": "jpg", "p": "png", "g": "gif", "w": "webp" }
  /// }
  /// ```
  List<String> _buildImageUrlsFromTemplate(
    dynamic data,
    Map<String, dynamic> builder,
  ) {
    final template = builder['template'] as String?;
    if (template == null) return const [];

    final mediaIdSel = builder['mediaIdSelector'] as String?;
    final mediaId = mediaIdSel != null
        ? _parser.extractString(data, FieldSelector(selector: mediaIdSel))
        : null;
    if (mediaId == null) {
      _logger.w('$_sourceId: imageUrlBuilder — media_id not found');
      return const [];
    }

    final pageExtSel = builder['pageExtSelector'] as String?;
    if (pageExtSel == null) return const [];

    final extCodes = _parser.extractList(
      data,
      FieldSelector(selector: pageExtSel),
    );
    if (extCodes.isEmpty) {
      _logger.w('$_sourceId: imageUrlBuilder — no page extensions found');
      return const [];
    }

    final mapping = (builder['extensionMapping'] as Map<String, dynamic>?)
            ?.cast<String, String>() ??
        const {};

    final urls = <String>[];
    for (int i = 0; i < extCodes.length; i++) {
      final extCode = extCodes[i];
      final ext = mapping[extCode] ?? 'jpg';
      final url = template
          .replaceAll('{mediaId}', mediaId)
          .replaceAll('{page}', (i + 1).toString())
          .replaceAll('{ext}', ext);
      urls.add(url);
    }
    return urls;
  }
}

/// Internal DTO used by [GenericRestAdapter._parseTagObjects] to return the
/// result of splitting a unified tags array by type.
class _TagSplit {
  const _TagSplit({
    required this.tags,
    required this.artists,
    required this.characters,
    required this.parodies,
    required this.groups,
    required this.language,
  });

  final List<Tag> tags;
  final List<String> artists;
  final List<String> characters;
  final List<String> parodies;
  final List<String> groups;
  final String language;
}
