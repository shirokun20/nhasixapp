import '../../entities/favorite_collection.dart';
import '../../repositories/user_data_repository.dart';

/// Use case for getting all favorite collections
class GetFavoriteCollectionsUseCase {
  GetFavoriteCollectionsUseCase(this._repository);

  final UserDataRepository _repository;

  Future<List<FavoriteCollection>> call() {
    return _repository.getFavoriteCollections();
  }
}
