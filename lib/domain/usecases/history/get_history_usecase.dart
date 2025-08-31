import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';

/// Use case for getting reading history with pagination
class GetHistoryUseCase extends UseCase<List<History>, GetHistoryParams> {
  GetHistoryUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<List<History>> call(GetHistoryParams params) async {
    try {
      // Validate parameters
      if (params.page < 1) {
        throw const ValidationException('Page number must be greater than 0');
      }

      if (params.limit < 1) {
        throw const ValidationException('Limit must be greater than 0');
      }

      if (params.limit > 100) {
        throw const ValidationException('Limit cannot exceed 100');
      }

      // Get history from repository
      final history = await _userDataRepository.getHistory(
        page: params.page,
        limit: params.limit,
      );

      return history;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to get history: ${e.toString()}');
    }
  }
}

/// Parameters for GetHistoryUseCase
class GetHistoryParams extends UseCaseParams {
  const GetHistoryParams({
    this.page = 1,
    this.limit = 50,
  });

  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];

  GetHistoryParams copyWith({
    int? page,
    int? limit,
  }) {
    return GetHistoryParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Create params for first page
  factory GetHistoryParams.firstPage({int limit = 50}) {
    return GetHistoryParams(page: 1, limit: limit);
  }

  /// Create params for next page
  GetHistoryParams nextPage() {
    return copyWith(page: page + 1);
  }

  /// Create params for previous page
  GetHistoryParams previousPage() {
    return copyWith(page: page > 1 ? page - 1 : 1);
  }

  /// Check if this is the first page
  bool get isFirstPage => page == 1;

  /// Calculate offset for database queries
  int get offset => (page - 1) * limit;
}
