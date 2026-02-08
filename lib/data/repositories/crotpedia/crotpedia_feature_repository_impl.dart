
import 'package:logger/logger.dart';
import '../../../../domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import '../../../../domain/entities/crotpedia/crotpedia_entities.dart';
import 'package:kuron_crotpedia/kuron_crotpedia.dart';
import '../../datasources/local/doujin_list_dao.dart';
import '../../datasources/remote/remote_data_source.dart';

class CrotpediaFeatureRepositoryImpl implements CrotpediaFeatureRepository {
  final RemoteDataSource remoteDataSource;
  final CrotpediaScraper scraper;
  final DoujinListDao doujinListDao;
  final Logger logger;

  CrotpediaFeatureRepositoryImpl({
    required this.remoteDataSource,
    required this.scraper,
    required this.doujinListDao,
    Logger? logger,
  }) : logger = logger ?? Logger();

  @override
  Future<List<GenreItem>> getGenreList() async {
    try {
        final html = await remoteDataSource.fetchHtml('/genre-list/'); 
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
        final html = await remoteDataSource.fetchHtml('/doujin-list/');
        final items = scraper.parseDoujinList(html);
        
        final mappedItems = items.map((e) => DoujinListItem(
          title: e.title,
          url: e.url ?? '',
          id: e.id,
        )).where((e) => e.id != null).toList();
        
        if (mappedItems.isNotEmpty) {
            logger.i('Caching ${mappedItems.length} doujin items');
            await doujinListDao.clear(); 
            await doujinListDao.insertAll(mappedItems);
        }
        
        return mappedItems;
    } catch (e) {
        logger.e('Error fetching doujin list', error: e);
        final local = await doujinListDao.getAll();
        if (local.isNotEmpty) {
             logger.w('Returning local doujin list due to error');
             return local;
        }
        rethrow;
    }
  }

  @override
  Future<List<RequestItem>> getRequestList({int page = 1}) async {
     try {
        final path = page == 1 ? '/baca/publisher/request/' : '/baca/publisher/request/page/$page/';
        final html = await remoteDataSource.fetchHtml(path);
        final items = scraper.parseRequestList(html);
        return items.map((e) => RequestItem(
          title: e.title,
          coverUrl: e.coverUrl,
          url: e.url ?? '',
          id: int.tryParse(e.id ?? '0') ?? 0,
          status: e.status ?? 'Unknown',
        )).toList();
     } catch (e) {
        logger.e('Error fetching request list', error: e);
        rethrow;
     }
  }
}
