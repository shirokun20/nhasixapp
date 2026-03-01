/// Generic scraper adapter — handles HTML scraping sources.
///
/// Uses [GenericHtmlParser] with CSS selectors from the config to map
/// scraped HTML to [Content] entities.
library;

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';

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

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) async {
    final scraper = rawConfig['scraper'] as Map<String, dynamic>?;
    final urlPatterns = (scraper?['urlPatterns'] as Map<String, dynamic>?)
            ?.cast<String, String>() ??
        {};
    final searchTemplate = urlPatterns['search'] ?? '';
    if (searchTemplate.isEmpty) {
      _logger.w('$_sourceId: no scraper search URL pattern configured');
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }

    final url = _urlBuilder.buildSearchUrl(searchTemplate, filter);
    _logger.d('$_sourceId scraper search: $url');

    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final doc = _parser.parse(response.data ?? '');
      final selectors = (scraper?['selectors'] as Map<String, dynamic>?) ?? {};

      final itemContainer = selectors['itemContainer'] as String?;
      final items = <Content>[];

      if (itemContainer != null) {
        final elements = _parser.selectAll(doc, itemContainer);
        for (final el in elements) {
          final id = _parser.extractFromElement(
                  el,
                  _sel(selectors, 'id') ??
                      const FieldSelector(selector: 'a')) ??
              '';
          final title = _parser.extractFromElement(
                  el,
                  _sel(selectors, 'title') ??
                      const FieldSelector(selector: '.title')) ??
              'Unknown';
          final coverUrl = _parser.extractFromElement(
                  el,
                  _sel(selectors, 'thumbnail') ??
                      _sel(selectors, 'coverUrl') ??
                      const FieldSelector(selector: 'img', attribute: 'src')) ??
              '';

          items.add(Content(
            id: id,
            sourceId: _sourceId,
            title: title,
            coverUrl: coverUrl,
            tags: const [],
            artists: const [],
            characters: const [],
            parodies: const [],
            groups: const [],
            language: 'unknown',
            pageCount: 0,
            imageUrls: const [],
            uploadDate: DateTime.fromMillisecondsSinceEpoch(0),
          ));
        }
      }

      final hasNextSelector = selectors['hasNextPage'] as String?;
      final hasNext = hasNextSelector != null
          ? _parser.selectAll(doc, hasNextSelector).isNotEmpty
          : false;

      return AdapterSearchResult(items: items, hasNextPage: hasNext);
    } catch (e) {
      _logger.e('$_sourceId scraper search failed', error: e);
      return const AdapterSearchResult(items: [], hasNextPage: false);
    }
  }

  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final scraper = rawConfig['scraper'] as Map<String, dynamic>?;
    final urlPatterns = (scraper?['urlPatterns'] as Map<String, dynamic>?)
            ?.cast<String, String>() ??
        {};
    final detailTemplate = urlPatterns['detail'] ?? '';
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

      final title = _parser.extractString(
              doc,
              _sel(selectors, 'title') ??
                  const FieldSelector(selector: 'h1')) ??
          'Unknown';
      final coverUrl = _parser.extractString(
              doc,
              _sel(selectors, 'thumbnail') ??
                  _sel(selectors, 'coverUrl') ??
                  const FieldSelector(
                      selector: 'img.cover', attribute: 'src')) ??
          '';
      final imageUrls = _parser.extractList(
        doc,
        _sel(selectors, 'imageUrls') ??
            const FieldSelector(selector: '.page-image img', attribute: 'src'),
      );
      final tagsRaw = _parser.extractList(
        doc,
        _sel(selectors, 'tags') ?? const FieldSelector(selector: '.tag'),
      );
      final artistsRaw = _parser.extractList(
        doc,
        _sel(selectors, 'artists') ?? const FieldSelector(selector: '.artist'),
      );
      final charactersRaw = _parser.extractList(
        doc,
        _sel(selectors, 'characters') ??
            const FieldSelector(selector: '.character'),
      );
      final parodiesRaw = _parser.extractList(
        doc,
        _sel(selectors, 'parodies') ?? const FieldSelector(selector: '.parody'),
      );
      final groupsRaw = _parser.extractList(
        doc,
        _sel(selectors, 'groups') ?? const FieldSelector(selector: '.group'),
      );
      final languageStr = _parser.extractString(
            doc,
            _sel(selectors, 'language') ??
                const FieldSelector(selector: '.language'),
          ) ??
          'unknown';

      final tags = tagsRaw
          .map((name) => Tag(id: 0, name: name, type: 'tag', count: 0))
          .toList();

      final content = Content(
        id: contentId,
        sourceId: _sourceId,
        title: title,
        coverUrl: coverUrl,
        tags: tags,
        artists: artistsRaw,
        characters: charactersRaw,
        parodies: parodiesRaw,
        groups: groupsRaw,
        language: languageStr,
        pageCount: imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: DateTime.fromMillisecondsSinceEpoch(0),
      );

      return AdapterDetailResult(content: content, imageUrls: imageUrls);
    } catch (e) {
      _logger.e('$_sourceId scraper detail failed for $contentId', error: e);
      return AdapterDetailResult(
          content: _emptyContent(contentId), imageUrls: []);
    }
  }

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    // Most scrapers don't have a dedicated related endpoint — return empty.
    return const [];
  }

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    // Most HTML scrapers don't have dedicated comments API endpoints.
    // Return empty list for now; can be implemented per-source if needed.
    return const [];
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  FieldSelector? _sel(Map<String, dynamic> selectors, String key) {
    final raw = selectors[key];
    if (raw == null) return null;
    if (raw is String) return FieldSelector(selector: raw);
    if (raw is Map<String, dynamic>) return FieldSelector.fromMap(raw);
    return null;
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
