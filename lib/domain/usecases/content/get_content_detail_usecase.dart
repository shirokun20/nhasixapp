import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';
import '../../repositories/repositories.dart';

/// Use case for getting detailed content information
class GetContentDetailUseCase extends UseCase<Content, GetContentDetailParams> {
  GetContentDetailUseCase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<Content> call(GetContentDetailParams params) async {
    try {
      // No validation needed for ContentId anymore to support unusual formats

      // Check if content exists first (optional optimization)
      if (params.verifyExists) {
        final exists =
            await _contentRepository.verifyContentExists(params.contentId);
        if (!exists) {
          throw NotFoundException(
              'Content with ID ${params.contentId.value} not found');
        }
      }

      // Get content detail from repository
      final content =
          await _contentRepository.getContentDetail(params.contentId);

      return content;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to get content detail: ${e.toString()}');
    }
  }
}

/// Parameters for GetContentDetailUseCase
class GetContentDetailParams extends UseCaseParams {
  const GetContentDetailParams({
    required this.contentId,
    this.verifyExists = false,
  });

  final ContentId contentId;
  final bool verifyExists;

  @override
  List<Object> get props => [contentId, verifyExists];

  GetContentDetailParams copyWith({
    ContentId? contentId,
    bool? verifyExists,
  }) {
    return GetContentDetailParams(
      contentId: contentId ?? this.contentId,
      verifyExists: verifyExists ?? this.verifyExists,
    );
  }

  /// Create params from string ID
  factory GetContentDetailParams.fromString(
    String contentId, {
    bool verifyExists = false,
  }) {
    return GetContentDetailParams(
      contentId: ContentId.fromString(contentId),
      verifyExists: verifyExists,
    );
  }

  /// Create params from int ID
  factory GetContentDetailParams.fromInt(
    int contentId, {
    bool verifyExists = false,
  }) {
    return GetContentDetailParams(
      contentId: ContentId.fromInt(contentId),
      verifyExists: verifyExists,
    );
  }
}
