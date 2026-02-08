
import 'package:logger/logger.dart';
import '../../../../domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import '../../../../domain/entities/crotpedia/crotpedia_entities.dart';
import 'package:kuron_crotpedia/kuron_crotpedia.dart';
import '../../datasources/local/doujin_list_dao.dart';


class CrotpediaFeatureRepositoryImpl implements CrotpediaFeatureRepository {
  final CrotpediaSource crotpediaSource;
  final CrotpediaScraper scraper;
  final DoujinListDao doujinListDao;
  final Logger logger;

  CrotpediaFeatureRepositoryImpl({
    required this.crotpediaSource,
    required this.scraper,
    required this.doujinListDao,
    Logger? logger,
  }) : logger = logger ?? Logger();

  static const String _baseUrl = 'https://crotpedia.net';

  @override
  Future<List<GenreItem>> getGenreList() async {
    try {
        final html = await crotpediaSource.fetchHtml('$_baseUrl/genre-list/'); 
        final items = scraper.parseGenreList(html);
        return items.map((e) => GenreItem(
          name: e.name,
          slug: e.slug,
          url: e.url,
          count: e.count,
        )).toList();
    } catch (e) {
        logger.e('Error fetching genre list', error: e);
        rethrow;
    }
  }

  @override
  Future<List<DoujinListItem>> getDoujinList({bool forceRefresh = false}) async {
    try {
        if (!forceRefresh) {
            final local = await doujinListDao.getAll();
            if (local.isNotEmpty) {
                logger.i('Fetched ${local.length} doujin items from local cache');
                return local;
            }
        }
        
        logger.i('Fetching doujin list from remote');
        final html = await crotpediaSource.fetchHtml('$_baseUrl/doujin-list/');
        final items = scraper.parseDoujinList(html);
        
        final mappedItems = items.map((e) => DoujinListItem(
          title: e.title,
          url: e.url ?? '',
          id: e.id,
        )).where((e) => e.id != null).toList();
        
        if (mappedItems.isNotEmpty) {
            logger.i('Parsed ${mappedItems.length} doujin items from HTML');
            logger.i('Caching doujin items to DB...');
            await doujinListDao.clear(); 
            await doujinListDao.insertAll(mappedItems);
            
            // Verify saved count
            final savedCount = await doujinListDao.count();
            logger.i('Successfully saved $savedCount items to DB (expected: ${mappedItems.length})');
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
