import '../../entities/favorite_collection.dart';
import '../../repositories/user_data_repository.dart';

/// Use case for creating a favorite collection
class CreateFavoriteCollectionUseCase {
  CreateFavoriteCollectionUseCase(this._repository);

  final UserDataRepository _repository;

  Future<FavoriteCollection> call(String name) {
    return _repository.createFavoriteCollection(name: name);
  }
}
