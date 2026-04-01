import 'package:equatable/equatable.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/domain/entities/tags/tag_entity.dart';
import 'package:nhasixapp/domain/repositories/tag_repository.dart';

/// UseCase for getting tags by type from API v2
class GetTagsByTypeUseCase
    extends UseCase<List<TagEntity>, GetTagsByTypeParams> {
  final TagRepository _tagRepository;

  GetTagsByTypeUseCase(this._tagRepository);

  @override
  Future<DataState<List<TagEntity>>> call(GetTagsByTypeParams params) async {
    return await _tagRepository.getTagsByType(
      tagType: params.tagType,
      sourceId: params.sourceId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class GetTagsByTypeParams extends Equatable {
  final String tagType;
  final String sourceId;
  final int page;
  final int perPage;

  const GetTagsByTypeParams({
    required this.tagType,
    required this.sourceId,
    this.page = 1,
    this.perPage = 30,
  });

  @override
  List<Object?> get props => [tagType, sourceId, page, perPage];
}
