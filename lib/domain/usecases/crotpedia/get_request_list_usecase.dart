import '../../entities/crotpedia/crotpedia_entities.dart';
import '../../repositories/crotpedia/crotpedia_feature_repository.dart';

class GetRequestListUseCase {
  final CrotpediaFeatureRepository repository;

  GetRequestListUseCase(this.repository);

  Future<List<RequestItem>> call({int page = 1}) async {
    return await repository.getRequestList(page: page);
  }
}
