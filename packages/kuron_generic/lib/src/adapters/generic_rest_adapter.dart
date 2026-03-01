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

class GenericRestAdapter implements GenericAdapter {
  final Dio _dio;
  final GenericUrlBuilder _urlBuilder;
  final GenericJsonParser _parser;
  final Logger _logger;
  final String _sourceId;

  GenericRestAdapter({
    required Dio dio,
    required GenericUrlBuilder urlBuilder,
    required GenericJsonParser parser,
    required Logger logger,
    required String sourceId,
  })  : _dio = dio,
        _urlBuilder = urlBuilder,
        _parser = parser,
        _logger = logger,
        _sourceId = sourceId;

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) async {
    final api = rawConfig['api'] as Map<String, dynamic>?;
    final endpoints =
        (api?['endpoints'] as Map<String, dynamic>?)?.cast<String, String>() ??
            {};
    final searchTemplate = endpoints['search'] ?? '';
    if (searchTemplate.isEmpty) {
      _logger.w('$_sourceId: no search endpoint configured');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    final url = _urlBuilder.buildSearchUrl(searchTemplate, filter);
    _logger.d('$_sourceId REST search: $url');

    try {
      final response = await _dio.get<dynamic>(url);
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final selectors = (rawConfig['selectors'] as Map<String, dynamic>?) ?? {};
      final items = _parseItemList(data, selectors);
      final hasNext = _parseHasNextPage(data, selectors);

      return AdapterSearchResult(items: items, hasNextPage: hasNext);
    } catch (e) {
      _logger.e('$_sourceId REST search failed', error: e);
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

  // ── Private parsers ────────────────────────────────────────────────────────

  List<Content> _parseItemList(dynamic data, Map<String, dynamic> selectors) {
    final itemsSelector = _selectorOrNull(selectors, 'items') ??
        _selectorOrNull(selectors, 'results');
    if (itemsSelector == null) return const [];

    final items = _parser.extractItems(data, itemsSelector);
    return items.map((item) => _parseItem(item, selectors)).toList();
  }

  Content _parseItem(
      Map<String, dynamic> item, Map<String, dynamic> selectors) {
    final id = _extract(item, selectors, 'id') ?? '';
    final title = _extract(item, selectors, 'title') ?? 'Unknown';
    final coverUrl = _extract(item, selectors, 'thumbnail') ??
        _extract(item, selectors, 'coverUrl') ??
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
      language: _extract(item, selectors, 'language') ?? 'unknown',
      pageCount:
          int.tryParse(_extract(item, selectors, 'pageCount') ?? '') ?? 0,
      imageUrls: const [],
      uploadDate: _parseDate(_extract(item, selectors, 'uploadDate')),
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
    final coverUrl = _extract(data, selectors, 'thumbnail') ??
        _extract(data, selectors, 'coverUrl') ??
        (imageUrls.isNotEmpty ? imageUrls.first : '');

    final tagsRaw = _parser.extractList(
      data,
      _selectorOrDefault(
          selectors, 'tags', const FieldSelector(selector: r'$.tags[*].name')),
    );
    final tags = _stringsToTags(tagsRaw, 'tag');

    final artistsRaw = _parser.extractList(
      data,
      _selectorOrDefault(selectors, 'artists',
          const FieldSelector(selector: r'$.artists[*].name')),
    );
    final charactersRaw = _parser.extractList(
      data,
      _selectorOrDefault(selectors, 'characters',
          const FieldSelector(selector: r'$.characters[*].name')),
    );
    final parodiesRaw = _parser.extractList(
      data,
      _selectorOrDefault(selectors, 'parodies',
          const FieldSelector(selector: r'$.parodies[*].name')),
    );
    final groupsRaw = _parser.extractList(
      data,
      _selectorOrDefault(selectors, 'groups',
          const FieldSelector(selector: r'$.groups[*].name')),
    );

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
      language: _extract(data, selectors, 'language') ?? 'unknown',
      pageCount: pageCount,
      imageUrls: imageUrls,
      uploadDate: _parseDate(_extract(data, selectors, 'uploadDate')),
      englishTitle: _extract(data, selectors, 'englishTitle'),
      japaneseTitle: _extract(data, selectors, 'japaneseTitle'),
    );
  }

  List<String> _parseImageUrls(
    dynamic data,
    Map<String, dynamic> selectors,
    Map<String, dynamic> rawConfig,
  ) {
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Convert raw string tag names to [Tag] entities with default values.
  List<Tag> _stringsToTags(List<String> names, String type) {
    return names
        .map((name) => Tag(id: 0, name: name, type: type, count: 0))
        .toList();
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
}
