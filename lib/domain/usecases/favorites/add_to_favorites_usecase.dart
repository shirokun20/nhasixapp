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
          contentId: ContentId.fromString(params.content.id),
          categoryId: params.categoryId,
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

      // Add to favorites
      await _userDataRepository.addToFavorites(
        content: params.content,
        categoryId: params.categoryId,
      );
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to add to favorites: ${e.toString()}');
    }
  }
}

/// Parameters for AddToFavoritesUseCase
class AddToFavoritesParams extends UseCaseParams {
  const AddToFavoritesParams({
    required this.content,
    this.categoryId,
    this.checkDuplicate = true,
    this.throwIfDuplicate = false,
  });

  final Content content;
  final int? categoryId;
  final bool checkDuplicate;
  final bool throwIfDuplicate;

  @override
  List<Object?> get props => [
        content,
        categoryId,
        checkDuplicate,
        throwIfDuplicate,
      ];

  AddToFavoritesParams copyWith({
    Content? content,
    int? categoryId,
    bool? checkDuplicate,
    bool? throwIfDuplicate,
  }) {
    return AddToFavoritesParams(
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      checkDuplicate: checkDuplicate ?? this.checkDuplicate,
      throwIfDuplicate: throwIfDuplicate ?? this.throwIfDuplicate,
    );
  }

  /// Create params for default category
  factory AddToFavoritesParams.defaultCategory(Content content) {
    return AddToFavoritesParams(content: content);
  }

  /// Create params for specific category
  factory AddToFavoritesParams.category(Content content, int categoryId) {
    return AddToFavoritesParams(
      content: content,
      categoryId: categoryId,
    );
  }

  /// Create params with duplicate check disabled
  factory AddToFavoritesParams.force(Content content, {int? categoryId}) {
    return AddToFavoritesParams(
      content: content,
      categoryId: categoryId,
      checkDuplicate: false,
    );
  }
}
