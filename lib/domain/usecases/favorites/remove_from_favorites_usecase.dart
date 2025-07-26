import '../base_usecase.dart';
import '../../value_objects/value_objects.dart';
import '../../repositories/repositories.dart';

/// Use case for removing content from favorites
class RemoveFromFavoritesUseCase
    extends UseCase<void, RemoveFromFavoritesParams> {
  RemoveFromFavoritesUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<void> call(RemoveFromFavoritesParams params) async {
    try {
      // Validate parameters
      if (!params.contentId.isValid) {
        throw ValidationException(
            'Invalid content ID: ${params.contentId.value}');
      }

      // Check if content is in favorites (optional)
      if (params.checkExists) {
        final isFavorite = await _userDataRepository.isFavorite(
          contentId: params.contentId,
          categoryId: params.categoryId,
        );

        if (!isFavorite) {
          if (params.throwIfNotExists) {
            throw const NotFoundException('Content is not in favorites');
          } else {
            // Silently return if not in favorites and not throwing
            return;
          }
        }
      }

      // Remove from favorites
      await _userDataRepository.removeFromFavorites(
        contentId: params.contentId,
        categoryId: params.categoryId,
      );
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to remove from favorites: ${e.toString()}');
    }
  }
}

/// Parameters for RemoveFromFavoritesUseCase
class RemoveFromFavoritesParams extends UseCaseParams {
  const RemoveFromFavoritesParams({
    required this.contentId,
    this.categoryId,
    this.checkExists = true,
    this.throwIfNotExists = false,
  });

  final ContentId contentId;
  final int? categoryId;
  final bool checkExists;
  final bool throwIfNotExists;

  @override
  List<Object?> get props => [
        contentId,
        categoryId,
        checkExists,
        throwIfNotExists,
      ];

  RemoveFromFavoritesParams copyWith({
    ContentId? contentId,
    int? categoryId,
    bool? checkExists,
    bool? throwIfNotExists,
  }) {
    return RemoveFromFavoritesParams(
      contentId: contentId ?? this.contentId,
      categoryId: categoryId ?? this.categoryId,
      checkExists: checkExists ?? this.checkExists,
      throwIfNotExists: throwIfNotExists ?? this.throwIfNotExists,
    );
  }

  /// Create params from string ID
  factory RemoveFromFavoritesParams.fromString(
    String contentId, {
    int? categoryId,
    bool checkExists = true,
    bool throwIfNotExists = false,
  }) {
    return RemoveFromFavoritesParams(
      contentId: ContentId.fromString(contentId),
      categoryId: categoryId,
      checkExists: checkExists,
      throwIfNotExists: throwIfNotExists,
    );
  }

  /// Create params from int ID
  factory RemoveFromFavoritesParams.fromInt(
    int contentId, {
    int? categoryId,
    bool checkExists = true,
    bool throwIfNotExists = false,
  }) {
    return RemoveFromFavoritesParams(
      contentId: ContentId.fromInt(contentId),
      categoryId: categoryId,
      checkExists: checkExists,
      throwIfNotExists: throwIfNotExists,
    );
  }

  /// Create params for removing from all categories
  factory RemoveFromFavoritesParams.fromAllCategories(ContentId contentId) {
    return RemoveFromFavoritesParams(
      contentId: contentId,
      categoryId: null, // null means remove from all categories
    );
  }

  /// Create params with existence check disabled
  factory RemoveFromFavoritesParams.force(ContentId contentId,
      {int? categoryId}) {
    return RemoveFromFavoritesParams(
      contentId: contentId,
      categoryId: categoryId,
      checkExists: false,
    );
  }
}
