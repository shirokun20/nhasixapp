import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';

/// Use case for getting genre list (no pagination)
/// Used for KomikTap genre list page
class GetGenreListUseCase extends UseCase<List<Genre>, GetGenreListParams> {
  GetGenreListUseCase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<List<Genre>> call(GetGenreListParams params) async {
    try {
      // Get genre list from repository
      final result = await _contentRepository.getGenreList(
        sourceId: params.sourceId,
      );

      return result;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to get genre list: ${e.toString()}');
    }
  }
}

/// Parameters for GetGenreListUseCase
class GetGenreListParams extends UseCaseParams {
  const GetGenreListParams({
    required this.sourceId,
  });

  final String sourceId;

  @override
  List<Object> get props => [sourceId];

  GetGenreListParams copyWith({
    String? sourceId,
  }) {
    return GetGenreListParams(
      sourceId: sourceId ?? this.sourceId,
    );
  }
}
