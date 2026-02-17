import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';

/// Use case for getting content list by type with pagination
/// Used for KomikTap list pages: Manga, Manhua, Manhwa, Project, A-Z
class GetContentListByTypeUseCase
    extends UseCase<ContentListResult, GetContentListByTypeParams> {
  GetContentListByTypeUseCase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<ContentListResult> call(GetContentListByTypeParams params) async {
    try {
      // Validate parameters
      if (params.page < 1) {
        throw const ValidationException('Page number must be greater than 0');
      }

      // Get content list from repository
      final result = await _contentRepository.getContentListByType(
        sourceId: params.sourceId,
        listType: params.listType,
        page: params.page,
        filter: params.filter,
      );

      return result;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw NetworkException(
          'Failed to get ${params.listType.displayName} list: ${e.toString()}');
    }
  }
}

/// Parameters for GetContentListByTypeUseCase
class GetContentListByTypeParams extends UseCaseParams {
  const GetContentListByTypeParams({
    required this.sourceId,
    required this.listType,
    this.page = 1,
    this.filter,
  });

  final String sourceId;
  final ContentListType listType;
  final int page;
  final String? filter;

  @override
  List<Object?> get props => [sourceId, listType, page, filter];

  GetContentListByTypeParams copyWith({
    String? sourceId,
    ContentListType? listType,
    int? page,
    String? filter,
  }) {
    return GetContentListByTypeParams(
      sourceId: sourceId ?? this.sourceId,
      listType: listType ?? this.listType,
      page: page ?? this.page,
      filter: filter ?? this.filter,
    );
  }

  /// Create params for next page
  GetContentListByTypeParams nextPage() {
    return copyWith(page: page + 1);
  }

  /// Create params for previous page
  GetContentListByTypeParams previousPage() {
    return copyWith(page: page > 1 ? page - 1 : 1);
  }

  /// Create params for first page
  GetContentListByTypeParams firstPage() {
    return copyWith(page: 1);
  }

  /// Change alphabet filter (for A-Z list)
  GetContentListByTypeParams withFilter(String? newFilter) {
    return copyWith(filter: newFilter, page: 1);
  }
}
