import '../base_usecase.dart';
import '../../repositories/repositories.dart';

/// Use case for getting user's favorite content
class GetFavoritesUseCase
    extends UseCase<FavoriteListResult, GetFavoritesParams> {
  GetFavoritesUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<FavoriteListResult> call(GetFavoritesParams params) async {
    try {
      // Validate parameters
      if (params.page < 1) {
        throw const ValidationException('Page number must be greater than 0');
      }

      if (params.categoryId != null && params.categoryId! < 1) {
        throw const ValidationException('Category ID must be greater than 0');
      }

      // Get favorites from repository
      final result = await _userDataRepository.getFavorites(
        categoryId: params.categoryId,
        page: params.page,
        sortBy: params.sortBy,
      );

      return result;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to get favorites: ${e.toString()}');
    }
  }
}

/// Parameters for GetFavoritesUseCase
class GetFavoritesParams extends UseCaseParams {
  const GetFavoritesParams({
    this.categoryId,
    this.page = 1,
    this.sortBy = FavoriteSortOption.dateAdded,
  });

  final int? categoryId;
  final int page;
  final FavoriteSortOption sortBy;

  @override
  List<Object?> get props => [categoryId, page, sortBy];

  GetFavoritesParams copyWith({
    int? categoryId,
    int? page,
    FavoriteSortOption? sortBy,
  }) {
    return GetFavoritesParams(
      categoryId: categoryId ?? this.categoryId,
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Create params for all categories
  factory GetFavoritesParams.allCategories({
    int page = 1,
    FavoriteSortOption sortBy = FavoriteSortOption.dateAdded,
  }) {
    return GetFavoritesParams(
      categoryId: null,
      page: page,
      sortBy: sortBy,
    );
  }

  /// Create params for specific category
  factory GetFavoritesParams.category(
    int categoryId, {
    int page = 1,
    FavoriteSortOption sortBy = FavoriteSortOption.dateAdded,
  }) {
    return GetFavoritesParams(
      categoryId: categoryId,
      page: page,
      sortBy: sortBy,
    );
  }

  /// Create params for first page
  GetFavoritesParams firstPage() {
    return copyWith(page: 1);
  }

  /// Create params for next page
  GetFavoritesParams nextPage() {
    return copyWith(page: page + 1);
  }

  /// Create params for previous page
  GetFavoritesParams previousPage() {
    return copyWith(page: page > 1 ? page - 1 : 1);
  }

  /// Create params with different sort option
  GetFavoritesParams withSort(FavoriteSortOption sortBy) {
    return copyWith(
        sortBy: sortBy, page: 1); // Reset to first page when sorting
  }
}
