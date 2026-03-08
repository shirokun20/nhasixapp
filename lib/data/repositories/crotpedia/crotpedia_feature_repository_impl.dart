import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kuron_crotpedia/kuron_crotpedia.dart';

import '../../../../core/config/remote_config_service.dart';
import '../../../../domain/entities/crotpedia/crotpedia_entities.dart';
import '../../../../domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import '../../datasources/local/doujin_list_dao.dart';

class CrotpediaFeatureRepositoryImpl implements CrotpediaFeatureRepository {
  final CrotpediaSource crotpediaSource;
  final RemoteConfigService remoteConfigService;
  final DoujinListDao doujinListDao;
  final SharedPreferences sharedPreferences;
  final Logger logger;

  static const String _prefKeyGenreList = 'crotpedia_genre_list';
  static const String _prefKeyGenreTimestamp = 'crotpedia_genre_timestamp';
  static const String _prefKeyDoujinTimestamp = 'crotpedia_doujin_timestamp';
  static const int _cacheDurationHours = 24;

  CrotpediaFeatureRepositoryImpl({
    required this.crotpediaSource,
    required this.remoteConfigService,
    required this.doujinListDao,
    required this.sharedPreferences,
    Logger? logger,
  }) : logger = logger ?? Logger();

  static const String _baseUrl = 'https://crotpedia.net';

  bool _isCacheExpired(String timestampKey) {
    final lastUpdate = sharedPreferences.getInt(timestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastUpdate;
    return diff > (_cacheDurationHours * 60 * 60 * 1000);
  }

  Map<String, dynamic>? _featureConfig(String key) {
    final raw = remoteConfigService.getRawConfig('crotpedia');
    final featurePages = raw?['featurePages'];
    if (featurePages is! Map<String, dynamic>) {
      return null;
    }
    final selected = featurePages[key];
    return selected is Map<String, dynamic> ? selected : null;
  }

  String _resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$_baseUrl$path';
    }
    return '$_baseUrl/$path';
  }

  dom.Document _parseHtml(String htmlContent) => html_parser.parse(htmlContent);

  String _extractFieldValue(dom.Element element, Map<String, dynamic> config) {
    final selector = config['selector'] as String?;
    final attribute = config['attribute'] as String?;
    final type = config['type'] as String?;

    final target = selector == null || selector.isEmpty
        ? element
        : (element.querySelector(selector) ?? element);
    final raw = attribute != null
        ? (target.attributes[attribute] ?? '')
        : target.text.trim();

    if (type == 'text') {
      return raw.trim();
    }

    return raw;
  }

  int _extractIntField(dom.Element element, Map<String, dynamic> config) {
    final raw = _extractFieldValue(element, config);
    final normalized = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }

  String _extractSlugFromUrl(String url, {String? fallback}) {
    if (url.isEmpty) {
      return (fallback ?? '').toLowerCase().replaceAll(' ', '-');
    }

    try {
      final uri = Uri.parse(url);
      for (var i = uri.pathSegments.length - 1; i >= 0; i--) {
        final segment = uri.pathSegments[i].trim();
        if (segment.isNotEmpty) {
          return segment;
        }
      }
    } catch (_) {
      // Best-effort fallback below.
    }

    return (fallback ?? '').toLowerCase().replaceAll(' ', '-');
  }

  @override
  Future<List<GenreItem>> getGenreList({bool forceRefresh = false}) async {
    try {
      // 1. Check Cache
      if (!forceRefresh && !_isCacheExpired(_prefKeyGenreTimestamp)) {
        final jsonString = sharedPreferences.getString(_prefKeyGenreList);
        if (jsonString != null) {
          logger.i('Fetched genre list from SharedPreferences cache');
          final List<dynamic> jsonList = jsonDecode(jsonString);
          return jsonList
              .map((e) => GenreItem(
                    name: e['name'],
                    slug: e['slug'],
                    url: e['url'],
                    count: e['count'],
                  ))
              .toList();
        }
      }

      // 2. Fetch Remote
      logger.i('Fetching genre list from remote (Force: $forceRefresh)');
      final config = _featureConfig('genreList');
      final path = (config?['url'] as String?) ?? '/genre-list/';
      final container = (config?['container'] as String?) ?? 'ul.achlist li';
      final fields =
          (config?['fields'] as Map?)?.cast<String, dynamic>() ?? const {};

      final html = await crotpediaSource.fetchHtml(_resolveUrl(path));
      final document = _parseHtml(html);
      final items = document.querySelectorAll(container);

      final mappedItems = items.map((item) {
        final nameCfg =
            (fields['name'] as Map?)?.cast<String, dynamic>() ?? const {};
        final urlCfg =
            (fields['url'] as Map?)?.cast<String, dynamic>() ?? const {};
        final countCfg =
            (fields['count'] as Map?)?.cast<String, dynamic>() ?? const {};

        final rawName = _extractFieldValue(item, nameCfg);
        final count = _extractIntField(item, countCfg);
        final cleanedName =
            rawName.replaceAll(RegExp(r'\s*\d+\s*$'), '').trim();
        final url = _extractFieldValue(item, urlCfg);

        return GenreItem(
          name: cleanedName,
          slug: _extractSlugFromUrl(url, fallback: cleanedName),
          url: url,
          count: count,
        );
      }).toList();

      // 3. Save Cache
      if (mappedItems.isNotEmpty) {
        final jsonString = jsonEncode(mappedItems
            .map((e) => {
                  'name': e.name,
                  'slug': e.slug,
                  'url': e.url,
                  'count': e.count,
                })
            .toList());

        await sharedPreferences.setString(_prefKeyGenreList, jsonString);
        await sharedPreferences.setInt(
            _prefKeyGenreTimestamp, DateTime.now().millisecondsSinceEpoch);
        logger.i('Cached ${mappedItems.length} genre items');
      }

      return mappedItems;
    } catch (e) {
      logger.e('Error fetching genre list', error: e);

      // Fallback to cache on error
      final jsonString = sharedPreferences.getString(_prefKeyGenreList);
      if (jsonString != null) {
        logger.w('Returning cached genre list due to error');
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map((e) => GenreItem(
                  name: e['name'],
                  slug: e['slug'],
                  url: e['url'],
                  count: e['count'],
                ))
            .toList();
      }

      rethrow;
    }
  }

  @override
  Future<List<DoujinListItem>> getDoujinList(
      {bool forceRefresh = false}) async {
    try {
      // 1. Check Cache (SQLite + Timestamp)
      if (!forceRefresh && !_isCacheExpired(_prefKeyDoujinTimestamp)) {
        final local = await doujinListDao.getAll();
        if (local.isNotEmpty) {
          logger.i(
              'Fetched ${local.length} doujin items from local DB (Valid Cache)');
          return local;
        }
      }

      // 2. Fetch Remote
      logger.i('Fetching doujin list from remote (Force: $forceRefresh)');
      final config = _featureConfig('doujinList');
      final path = (config?['url'] as String?) ?? '/doujin-list/';
      final container =
          (config?['container'] as String?) ?? '.mangalist-blc a.series';
      final fields =
          (config?['fields'] as Map?)?.cast<String, dynamic>() ?? const {};

      final html = await crotpediaSource.fetchHtml(_resolveUrl(path));
      final document = _parseHtml(html);
      final items = document.querySelectorAll(container);

      final mappedItems = items
          .map((item) {
            final titleCfg =
                (fields['title'] as Map?)?.cast<String, dynamic>() ??
                    const {'type': 'text'};
            final urlCfg =
                (fields['url'] as Map?)?.cast<String, dynamic>() ?? const {};
            final idCfg =
                (fields['id'] as Map?)?.cast<String, dynamic>() ?? const {};

            return DoujinListItem(
              title: _extractFieldValue(item, titleCfg),
              url: _extractFieldValue(item, urlCfg),
              id: _extractFieldValue(item, idCfg),
            );
          })
          .where((e) => e.id != null)
          .toList();

      // 3. Save Cache (Clear DB + Insert + Update Timestamp)
      if (mappedItems.isNotEmpty) {
        logger.i('Caching ${mappedItems.length} doujin items to DB...');
        await doujinListDao.clear();
        await doujinListDao.insertAll(mappedItems);
        await sharedPreferences.setInt(
            _prefKeyDoujinTimestamp, DateTime.now().millisecondsSinceEpoch);

        // Verify saved count
        final savedCount = await doujinListDao.count();
        logger.i('Successfully saved $savedCount items to DB');
      }

      return mappedItems;
    } catch (e) {
      logger.e('Error fetching doujin list', error: e);
      final local = await doujinListDao.getAll();
      if (local.isNotEmpty) {
        logger.w(
            'Returning ${local.length} items from local doujin list due to error');
        return local;
      }
      rethrow;
    }
  }

  @override
  Future<List<RequestItem>> getRequestList({int page = 1}) async {
    try {
      final config = _featureConfig('requestList');
      final firstPagePath =
          (config?['url'] as String?) ?? '/baca/publisher/request/';
      final pageUrlPattern = (config?['pageUrl'] as String?) ??
          '/baca/publisher/request/page/{page}/';
      final container = (config?['container'] as String?) ?? '.flexbox2-item';
      final fields =
          (config?['fields'] as Map?)?.cast<String, dynamic>() ?? const {};

      final path = page == 1
          ? firstPagePath
          : pageUrlPattern.replaceAll('{page}', page.toString());

      final html = await crotpediaSource.fetchHtml(_resolveUrl(path));
      final document = _parseHtml(html);
      final items = document.querySelectorAll(container);

      return items.map((item) {
        final titleCfg =
            (fields['title'] as Map?)?.cast<String, dynamic>() ?? const {};
        final coverCfg =
            (fields['coverUrl'] as Map?)?.cast<String, dynamic>() ?? const {};
        final urlCfg =
            (fields['url'] as Map?)?.cast<String, dynamic>() ?? const {};
        final statusCfg =
            (fields['status'] as Map?)?.cast<String, dynamic>() ?? const {};

        final url = _extractFieldValue(item, urlCfg);
        final slug = _extractSlugFromUrl(url);

        return RequestItem(
          title: _extractFieldValue(item, titleCfg),
          coverUrl: _extractFieldValue(item, coverCfg),
          url: url,
          id: slug.hashCode,
          status: _extractFieldValue(item, statusCfg),
        );
      }).toList();
    } catch (e) {
      logger.e('Error fetching request list', error: e);
      rethrow;
    }
  }
}
