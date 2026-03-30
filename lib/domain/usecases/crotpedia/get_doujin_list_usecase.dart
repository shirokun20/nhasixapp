import '../../entities/crotpedia/crotpedia_entities.dart';
import '../../repositories/crotpedia/crotpedia_feature_repository.dart';

class GetDoujinListUseCase {
  final CrotpediaFeatureRepository repository;

  GetDoujinListUseCase(this.repository);

  Future<List<DoujinListItem>> call({bool forceRefresh = false}) async {
    return await repository.getDoujinList(forceRefresh: forceRefresh);
  }
}
