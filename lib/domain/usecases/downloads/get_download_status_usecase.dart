import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';
import '../../repositories/repositories.dart';

/// Use case for getting download status of specific content
class GetDownloadStatusUseCase
    extends UseCase<DownloadStatus?, GetDownloadStatusParams> {
  GetDownloadStatusUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<DownloadStatus?> call(GetDownloadStatusParams params) async {
    try {
      // Validate parameters
      if (!params.contentId.isValid) {
        throw ValidationException(
            'Invalid content ID: ${params.contentId.value}');
      }

      // Get download status from repository
      final status =
          await _userDataRepository.getDownloadStatus(params.contentId.value);

      return status;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to get download status: ${e.toString()}');
    }
  }
}

/// Parameters for GetDownloadStatusUseCase
class GetDownloadStatusParams extends UseCaseParams {
  const GetDownloadStatusParams({
    required this.contentId,
  });

  final ContentId contentId;

  @override
  List<Object> get props => [contentId];

  GetDownloadStatusParams copyWith({
    ContentId? contentId,
  }) {
    return GetDownloadStatusParams(
      contentId: contentId ?? this.contentId,
    );
  }

  /// Create params from string ID
  factory GetDownloadStatusParams.fromString(String contentId) {
    return GetDownloadStatusParams(
      contentId: ContentId.fromString(contentId),
    );
  }

  /// Create params from int ID
  factory GetDownloadStatusParams.fromInt(int contentId) {
    return GetDownloadStatusParams(
      contentId: ContentId.fromInt(contentId),
    );
  }
}
