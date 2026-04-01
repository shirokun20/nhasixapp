import 'package:equatable/equatable.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/domain/entities/tags/tag_autocomplete_result.dart';
import 'package:nhasixapp/domain/repositories/tag_repository.dart';

/// UseCase for getting autocomplete suggestions from API v2
class GetTagAutocompleteUseCase
    extends UseCase<TagAutocompleteResult, GetTagAutocompleteParams> {
  final TagRepository _tagRepository;

  GetTagAutocompleteUseCase(this._tagRepository);

  @override
  Future<DataState<TagAutocompleteResult>> call(
    GetTagAutocompleteParams params,
  ) async {
    return await _tagRepository.getAutocomplete(
      query: params.query,
      sourceId: params.sourceId,
      tagType: params.tagType,
      limit: params.limit,
    );
  }
}

class GetTagAutocompleteParams extends Equatable {
  final String query;
  final String sourceId;
  final String? tagType;
  final int limit;

  const GetTagAutocompleteParams({
    required this.query,
    required this.sourceId,
    this.tagType,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [query, sourceId, tagType, limit];
}
