import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';
import '../../repositories/repositories.dart';

/// Use case for adding content to favorites
class AddToFavoritesUseCase extends UseCase<void, AddToFavoritesParams> {
  AddToFavoritesUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<void> call(AddToFavoritesParams params) async {
    try {
      // Validate parameters
      if (params.content.id.isEmpty) {
        throw const ValidationException('Content ID cannot be empty');
      }

      // Check if already in favorites (optional)
      if (params.checkDuplicate) {
        final isAlreadyFavorite = await _userDataRepository.isFavorite(
          params.content.id,
        );

        if (isAlreadyFavorite) {
          if (params.throwIfDuplicate) {
            throw const ValidationException('Content is already in favorites');
          } else {
            // Silently return if already favorited and not throwing
            return;
          }
        }
      }

      // Add to favorites (simplified - only id and cover_url)
      await _userDataRepository.addToFavorites(
        id: params.content.id,
        coverUrl: params.content.coverUrl,
      );
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to add to favorites: ${e.toString()}');
    }
  }
}

/// Parameters for AddToFavoritesUseCase (simplified)
class AddToFavoritesParams extends UseCaseParams {
  const AddToFavoritesParams({
    required this.content,
    this.checkDuplicate = true,
    this.throwIfDuplicate = false,
  });

  final Content content;
  final bool checkDuplicate;
  final bool throwIfDuplicate;

  @override
  List<Object?> get props => [
        content,
        checkDuplicate,
        throwIfDuplicate,
      ];

  AddToFavoritesParams copyWith({
    Content? content,
    bool? checkDuplicate,
    bool? throwIfDuplicate,
  }) {
    return AddToFavoritesParams(
      content: content ?? this.content,
      checkDuplicate: checkDuplicate ?? this.checkDuplicate,
      throwIfDuplicate: throwIfDuplicate ?? this.throwIfDuplicate,
    );
  }

  /// Create params for content
  factory AddToFavoritesParams.create(Content content) {
    return AddToFavoritesParams(content: content);
  }

  /// Create params with duplicate check disabled
  factory AddToFavoritesParams.force(Content content) {
    return AddToFavoritesParams(
      content: content,
      checkDuplicate: false,
    );
  }
}
