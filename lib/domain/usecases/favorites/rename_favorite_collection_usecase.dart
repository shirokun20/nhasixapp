import '../../repositories/user_data_repository.dart';

/// Use case for renaming a favorite collection
class RenameFavoriteCollectionUseCase {
  RenameFavoriteCollectionUseCase(this._repository);

  final UserDataRepository _repository;

  Future<void> call({required String collectionId, required String name}) {
    return _repository.renameFavoriteCollection(
      collectionId: collectionId,
      name: name,
    );
  }
}
