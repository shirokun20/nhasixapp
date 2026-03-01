/// Generic REST adapter — handles JSON API sources.
///
/// Uses [GenericJsonParser] with JSONPath selectors from the config to map
/// API responses to [Content] entities.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';

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

    // Build URL using the effective query (with embedded filter tokens)
    final adjustedFilter = effectiveQuery != filter.query.trim()
        ? filter.copyWith(query: effectiveQuery)
        : filter;
    final url = _urlBuilder.buildSearchUrl(searchTemplate, adjustedFilter);
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
      final items = _parseItemList(data, selectors);
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
      return _parseItemList(data, selectors);
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

  // ── Private parsers ────────────────────────────────────────────────────────

  List<Content> _parseItemList(dynamic data, Map<String, dynamic> selectors) {
    final itemsSelector = _selectorOrNull(selectors, 'items') ??
        _selectorOrNull(selectors, 'results');
    if (itemsSelector == null) return const [];

    final items = _parser.extractItems(data, itemsSelector);
    return items.map((item) => _parseItem(item, selectors)).toList();
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
      Map<String, dynamic> item, Map<String, dynamic> selectors) {
    final id = _extract(item, selectors, 'id') ?? '';
    final title = _extract(item, selectors, 'title') ?? 'Unknown';
    final mediaId = _extract(item, selectors, 'mediaId');

    // Build cover URL: prefer explicit selector, then coverUrlBuilder, then empty
    final coverUrl = _extract(item, selectors, 'thumbnail') ??
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

    return Content(
      id: id,
      sourceId: _sourceId,
      title: title,
      coverUrl: coverUrl,
      tags: tags,
      artists: artistsRaw,
      characters: const [],
      parodies: const [],
      groups: const [],
      language: _extractLanguage(item, selectors),
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
    final title = _extract(data, selectors, 'title') ?? 'Unknown';
    final mediaId = _extract(data, selectors, 'mediaId');
    final coverUrl = _extract(data, selectors, 'thumbnail') ??
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
    }

    final pageCountStr = _extract(data, selectors, 'pageCount');
    final pageCount = int.tryParse(pageCountStr ?? '') ?? imageUrls.length;

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
      language: splitLanguage ?? _extractLanguage(data, selectors),
      pageCount: pageCount,
      imageUrls: imageUrls,
      uploadDate: _parseDate(_extract(data, selectors, 'uploadDate')),
      englishTitle: _extract(data, selectors, 'englishTitle'),
      japaneseTitle: _extract(data, selectors, 'japaneseTitle'),
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

      switch (type) {
        case 'artist':
          artists.add(name);
        case 'character':
          characters.add(name);
        case 'parody':
          parodies.add(name);
        case 'group':
          groups.add(name);
        case 'language':
          if (name != 'translated') languages.add(name);
        default:
          // 'tag', 'category', any unknown type — include in tag chips
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
  String _extractLanguage(dynamic data, Map<String, dynamic> selectors) {
    final sel = _selectorOrNull(selectors, 'language');
    if (sel == null) return 'unknown';
    final values = _parser.extractList(data, sel);
    final language =
        values.firstWhere((v) => v != 'translated', orElse: () => '');
    return language.isNotEmpty ? language : 'unknown';
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
    final builder = selectors['coverUrlBuilder'] as Map<String, dynamic>?;
    if (builder == null) return null;

    final template = builder['template'] as String?;
    if (template == null) return null;

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
