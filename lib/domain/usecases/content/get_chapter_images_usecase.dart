import '../base_usecase.dart';
import '../../value_objects/value_objects.dart';
import '../../repositories/repositories.dart';
import '../../entities/entities.dart';

/// Use case for getting chapter images and navigation data
class GetChapterImagesUseCase
    extends UseCase<ChapterData, GetChapterImagesParams> {
  GetChapterImagesUseCase(this._contentRepository);

  final ContentRepository _contentRepository;

  @override
  Future<ChapterData> call(GetChapterImagesParams params) async {
    return await _contentRepository.getChapterImages(
      params.chapterId,
      sourceId: params.sourceId,
    );
  }
}

/// Parameters for GetChapterImagesUseCase
class GetChapterImagesParams extends UseCaseParams {
  const GetChapterImagesParams({
    required this.chapterId,
    this.sourceId,
  });

  final ContentId chapterId;
  final String? sourceId;

  @override
  List<Object?> get props => [chapterId, sourceId];

  factory GetChapterImagesParams.fromString(String chapterId,
      {String? sourceId}) {
    return GetChapterImagesParams(
      chapterId: ContentId.fromString(chapterId),
      sourceId: sourceId,
    );
  }
}
