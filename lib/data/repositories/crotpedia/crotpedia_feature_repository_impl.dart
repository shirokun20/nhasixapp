
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import '../../../../domain/entities/crotpedia/crotpedia_entities.dart';
import 'package:kuron_crotpedia/kuron_crotpedia.dart';
import '../../datasources/local/doujin_list_dao.dart';


class CrotpediaFeatureRepositoryImpl implements CrotpediaFeatureRepository {
  final CrotpediaSource crotpediaSource;
  final CrotpediaScraper scraper;
  final DoujinListDao doujinListDao;
  final SharedPreferences sharedPreferences;
  final Logger logger;

  static const String _prefKeyGenreList = 'crotpedia_genre_list';
  static const String _prefKeyGenreTimestamp = 'crotpedia_genre_timestamp';
  static const String _prefKeyDoujinTimestamp = 'crotpedia_doujin_timestamp';
  static const int _cacheDurationHours = 24;

  CrotpediaFeatureRepositoryImpl({
    required this.crotpediaSource,
    required this.scraper,
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

  @override
  Future<List<GenreItem>> getGenreList({bool forceRefresh = false}) async {
    try {
      // 1. Check Cache
      if (!forceRefresh && !_isCacheExpired(_prefKeyGenreTimestamp)) {
        final jsonString = sharedPreferences.getString(_prefKeyGenreList);
        if (jsonString != null) {
          logger.i('Fetched genre list from SharedPreferences cache');
          final List<dynamic> jsonList = jsonDecode(jsonString);
          return jsonList.map((e) => GenreItem(
            name: e['name'],
            slug: e['slug'],
            url: e['url'],
            count: e['count'],
          )).toList();
        }
      }

      // 2. Fetch Remote
      logger.i('Fetching genre list from remote (Force: $forceRefresh)');
      final html = await crotpediaSource.fetchHtml('$_baseUrl/genre-list/');
      final items = scraper.parseGenreList(html);

      final mappedItems = items.map((e) => GenreItem(
        name: e.name,
        slug: e.slug,
        url: e.url,
        count: e.count,
      )).toList();

      // 3. Save Cache
      if (mappedItems.isNotEmpty) {
        final jsonString = jsonEncode(mappedItems.map((e) => {
          'name': e.name,
          'slug': e.slug,
          'url': e.url,
          'count': e.count,
        }).toList());

        await sharedPreferences.setString(_prefKeyGenreList, jsonString);
        await sharedPreferences.setInt(_prefKeyGenreTimestamp, DateTime.now().millisecondsSinceEpoch);
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
        return jsonList.map((e) => GenreItem(
          name: e['name'],
          slug: e['slug'],
          url: e['url'],
          count: e['count'],
        )).toList();
      }

      rethrow;
    }
  }

  @override
  Future<List<DoujinListItem>> getDoujinList({bool forceRefresh = false}) async {
    try {
      // 1. Check Cache (SQLite + Timestamp)
      if (!forceRefresh && !_isCacheExpired(_prefKeyDoujinTimestamp)) {
        final local = await doujinListDao.getAll();
        if (local.isNotEmpty) {
          logger.i('Fetched ${local.length} doujin items from local DB (Valid Cache)');
          return local;
        }
      }

      // 2. Fetch Remote
      logger.i('Fetching doujin list from remote (Force: $forceRefresh)');
      final html = await crotpediaSource.fetchHtml('$_baseUrl/doujin-list/');
      final items = scraper.parseDoujinList(html);

      final mappedItems = items.map((e) => DoujinListItem(
        title: e.title,
        url: e.url ?? '',
        id: e.id,
      )).where((e) => e.id != null).toList();

      // 3. Save Cache (Clear DB + Insert + Update Timestamp)
      if (mappedItems.isNotEmpty) {
        logger.i('Caching ${mappedItems.length} doujin items to DB...');
        await doujinListDao.clear();
        await doujinListDao.insertAll(mappedItems);
        await sharedPreferences.setInt(_prefKeyDoujinTimestamp, DateTime.now().millisecondsSinceEpoch);

        // Verify saved count
        final savedCount = await doujinListDao.count();
        logger.i('Successfully saved $savedCount items to DB');
      }

      return mappedItems;
    } catch (e) {
      logger.e('Error fetching doujin list', error: e);
      final local = await doujinListDao.getAll();
      if (local.isNotEmpty) {
        logger.w('Returning ${local.length} items from local doujin list due to error');
        return local;
      }
      rethrow;
    }
  }

  @override
  Future<List<RequestItem>> getRequestList({int page = 1}) async {
    try {
        final path = page == 1 ? '$_baseUrl/baca/publisher/request/' : '$_baseUrl/baca/publisher/request/page/$page/';
        final html = await crotpediaSource.fetchHtml(path);
        final items = scraper.parseRequestList(html);
        return items.map((e) => RequestItem(
          title: e.title,
          coverUrl: e.coverUrl,
          url: e.url ?? '',
          id: int.tryParse(e.id ?? '0') ?? 0,
          status: e.status,
          genres: e.genres,
        )).toList();
     } catch (e) {
        logger.e('Error fetching request list', error: e);
        rethrow;
     }
  }
}
