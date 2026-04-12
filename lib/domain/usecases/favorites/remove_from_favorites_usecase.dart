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
          params.contentId.value,
          sourceId: params.sourceId,
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

      // Remove from favorites (simplified)
      await _userDataRepository.removeFromFavorites(
        params.contentId.value,
        sourceId: params.sourceId,
      );
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to remove from favorites: ${e.toString()}');
    }
  }
}

/// Parameters for RemoveFromFavoritesUseCase (simplified)
class RemoveFromFavoritesParams extends UseCaseParams {
  const RemoveFromFavoritesParams({
    required this.contentId,
    this.sourceId,
    this.checkExists = true,
    this.throwIfNotExists = false,
  });

  final ContentId contentId;
  final String? sourceId;
  final bool checkExists;
  final bool throwIfNotExists;

  @override
  List<Object?> get props => [
        contentId,
        sourceId,
        checkExists,
        throwIfNotExists,
      ];

  RemoveFromFavoritesParams copyWith({
    ContentId? contentId,
    String? sourceId,
    bool? checkExists,
    bool? throwIfNotExists,
  }) {
    return RemoveFromFavoritesParams(
      contentId: contentId ?? this.contentId,
      sourceId: sourceId ?? this.sourceId,
      checkExists: checkExists ?? this.checkExists,
      throwIfNotExists: throwIfNotExists ?? this.throwIfNotExists,
    );
  }

  /// Create params from string ID
  factory RemoveFromFavoritesParams.fromString(
    String contentId, {
    String? sourceId,
    bool checkExists = true,
    bool throwIfNotExists = false,
  }) {
    return RemoveFromFavoritesParams(
      contentId: ContentId.fromString(contentId),
      sourceId: sourceId,
      checkExists: checkExists,
      throwIfNotExists: throwIfNotExists,
    );
  }

  /// Create params from int ID
  factory RemoveFromFavoritesParams.fromInt(
    int contentId, {
    String? sourceId,
    bool checkExists = true,
    bool throwIfNotExists = false,
  }) {
    return RemoveFromFavoritesParams(
      contentId: ContentId.fromInt(contentId),
      sourceId: sourceId,
      checkExists: checkExists,
      throwIfNotExists: throwIfNotExists,
    );
  }

  /// Create params with existence check disabled
  factory RemoveFromFavoritesParams.force(ContentId contentId) {
    return RemoveFromFavoritesParams(
      contentId: contentId,
      checkExists: false,
    );
  }
}
