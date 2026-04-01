import 'package:logger/logger.dart';
import 'package:nhasixapp/data/datasources/remote/tags/tags_remote_data_source.dart';
import 'package:nhasixapp/domain/entities/tags/tag_autocomplete_result.dart';
import 'package:nhasixapp/domain/entities/tags/tag_detail_entity.dart';
import 'package:nhasixapp/domain/entities/tags/tag_entity.dart';
import 'package:nhasixapp/domain/repositories/tag_repository.dart';

/// Implementation of TagRepository
class TagRepositoryImpl implements TagRepository {
  final TagsRemoteDataSource _remoteDataSource;
  final Logger _logger;

  TagRepositoryImpl({
    required TagsRemoteDataSource remoteDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _logger = logger;

  @override
  Future<List<TagEntity>> getTagsByType({
    required String tagType,
    required String sourceId,
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final models = await _remoteDataSource.getTagsByType(
        tagType: tagType,
        sourceId: sourceId,
        page: page,
        perPage: perPage,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e, stackTrace) {
      _logger.e('Error in getTagsByType', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<TagAutocompleteResult> getAutocomplete({
    required String query,
    required String sourceId,
    String? tagType,
    int limit = 10,
  }) async {
    try {
      final model = await _remoteDataSource.getAutocomplete(
        query: query,
        sourceId: sourceId,
        tagType: tagType,
        limit: limit,
      );
      return model.toEntity();
    } catch (e, stackTrace) {
      _logger.e('Error in getAutocomplete', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<TagDetailEntity> getTagDetail({
    required String tagType,
    required String slug,
    required String sourceId,
  }) async {
    try {
      final model = await _remoteDataSource.getTagDetail(
        tagType: tagType,
        slug: slug,
        sourceId: sourceId,
      );
      return model.toEntity();
    } catch (e, stackTrace) {
      _logger.e('Error in getTagDetail', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
