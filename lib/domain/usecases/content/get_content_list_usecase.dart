import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';

/// Use case for getting paginated content list
class GetContentListUseCase
    extends UseCase<ContentListResult, GetContentListParams> {
  GetContentListUseCase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<ContentListResult> call(GetContentListParams params) async {
    try {
      // Validate parameters
      if (params.page < 1) {
        throw const ValidationException('Page number must be greater than 0');
      }

      // Get content list from repository
      final result = await _contentRepository.getContentList(
        page: params.page,
        sortBy: params.sortBy,
      );

      return result;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to get content list: ${e.toString()}');
    }
  }
}

/// Parameters for GetContentListUseCase
class GetContentListParams extends UseCaseParams {
  const GetContentListParams({
    this.page = 1,
    this.sortBy = SortOption.newest,
  });

  final int page;
  final SortOption sortBy;

  @override
  List<Object> get props => [page, sortBy];

  GetContentListParams copyWith({
    int? page,
    SortOption? sortBy,
  }) {
    return GetContentListParams(
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Create params for next page
  GetContentListParams nextPage() {
    return copyWith(page: page + 1);
  }

  /// Create params for previous page
  GetContentListParams previousPage() {
    return copyWith(page: page > 1 ? page - 1 : 1);
  }

  /// Create params for first page
  GetContentListParams firstPage() {
    return copyWith(page: 1);
  }
}
