import '../../entities/crotpedia/crotpedia_entities.dart';
import '../../repositories/crotpedia/crotpedia_feature_repository.dart';

class GetGenreListUseCase {
  final CrotpediaFeatureRepository repository;

  GetGenreListUseCase(this.repository);

  Future<List<GenreItem>> call() async {
    return await repository.getGenreList();
  }
}
