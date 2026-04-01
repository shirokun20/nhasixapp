import 'package:equatable/equatable.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/domain/entities/tags/tag_detail_entity.dart';
import 'package:nhasixapp/domain/repositories/tag_repository.dart';

/// UseCase for getting detailed tag information from API v2
class GetTagDetailUseCase
    extends UseCase<TagDetailEntity, GetTagDetailParams> {
  final TagRepository _tagRepository;

  GetTagDetailUseCase(this._tagRepository);

  @override
  Future<DataState<TagDetailEntity>> call(GetTagDetailParams params) async {
    return await _tagRepository.getTagDetail(
      tagType: params.tagType,
      slug: params.slug,
      sourceId: params.sourceId,
    );
  }
}

class GetTagDetailParams extends Equatable {
  final String tagType;
  final String slug;
  final String sourceId;

  const GetTagDetailParams({
    required this.tagType,
    required this.slug,
    required this.sourceId,
  });

  @override
  List<Object?> get props => [tagType, slug, sourceId];
}
