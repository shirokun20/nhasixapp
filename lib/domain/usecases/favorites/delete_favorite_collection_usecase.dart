import '../../repositories/user_data_repository.dart';

/// Use case for deleting a favorite collection
class DeleteFavoriteCollectionUseCase {
  DeleteFavoriteCollectionUseCase(this._repository);

  final UserDataRepository _repository;

  Future<void> call(String collectionId) {
    return _repository.deleteFavoriteCollection(collectionId);
  }
}
