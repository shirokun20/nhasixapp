import '../../repositories/user_data_repository.dart';

/// Use case for adding content to a favorite collection
class AddToFavoriteCollectionUseCase {
  AddToFavoriteCollectionUseCase(this._repository);

  final UserDataRepository _repository;

  Future<void> call({
    required String favoriteId,
    required String sourceId,
    required List<String> collectionIds,
  }) {
    return _repository.setFavoriteCollectionIds(
      favoriteId: favoriteId,
      sourceId: sourceId,
      collectionIds: collectionIds,
    );
  }
}
