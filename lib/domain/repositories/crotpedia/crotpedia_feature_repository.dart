import '../../entities/crotpedia/crotpedia_entities.dart';

abstract class CrotpediaFeatureRepository {
  Future<List<GenreItem>> getGenreList();
  Future<List<DoujinListItem>> getDoujinList({bool forceRefresh = false});
  Future<List<RequestItem>> getRequestList({int page = 1});
}
