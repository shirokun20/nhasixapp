import '../base_usecase.dart';
import '../../repositories/repositories.dart';

/// Use case for getting user's favorite content (simplified)
class GetFavoritesUseCase
    extends UseCase<List<Map<String, dynamic>>, GetFavoritesParams> {
  GetFavoritesUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<List<Map<String, dynamic>>> call(GetFavoritesParams params) async {
    try {
      // Validate parameters
      if (params.page < 1) {
        throw const ValidationException('Page number must be greater than 0');
      }

      if (params.limit < 1) {
        throw const ValidationException('Limit must be greater than 0');
      }

      // Get favorites from repository (simplified)
      final result = await _userDataRepository.getFavorites(
        page: params.page,
        limit: params.limit,
      );

      return result;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to get favorites: ${e.toString()}');
    }
  }
}

/// Parameters for GetFavoritesUseCase (simplified)
class GetFavoritesParams extends UseCaseParams {
  const GetFavoritesParams({
    this.page = 1,
    this.limit = 20,
  });

  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];

  GetFavoritesParams copyWith({
    int? page,
    int? limit,
  }) {
    return GetFavoritesParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Create params for first page
  factory GetFavoritesParams.firstPage({int limit = 20}) {
    return GetFavoritesParams(page: 1, limit: limit);
  }

  /// Create params for specific page
  factory GetFavoritesParams.page(int page, {int limit = 20}) {
    return GetFavoritesParams(page: page, limit: limit);
  }

  /// Create params for next page
  GetFavoritesParams nextPage() {
    return copyWith(page: page + 1);
  }

  /// Create params for previous page
  GetFavoritesParams previousPage() {
    return copyWith(page: page > 1 ? page - 1 : 1);
  }
}
