import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
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
  Future<DataState<List<TagEntity>>> getTagsByType({
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

      final entities = models.map((model) => model.toEntity()).toList();

      return DataSuccess(entities);
    } on DioException catch (e) {
      _logger.e('DioException in getTagsByType', error: e);
      return DataFailed(
        DioException(
          requestOptions: e.requestOptions,
          error: e.error,
          response: e.response,
          type: e.type,
        ),
      );
    } on SocketException catch (e) {
      _logger.e('SocketException in getTagsByType', error: e);
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
          type: DioExceptionType.connectionError,
        ),
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error in getTagsByType',
        error: e,
        stackTrace: stackTrace,
      );
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<TagAutocompleteResult>> getAutocomplete({
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

      return DataSuccess(model.toEntity());
    } on DioException catch (e) {
      _logger.e('DioException in getAutocomplete', error: e);
      return DataFailed(
        DioException(
          requestOptions: e.requestOptions,
          error: e.error,
          response: e.response,
          type: e.type,
        ),
      );
    } on SocketException catch (e) {
      _logger.e('SocketException in getAutocomplete', error: e);
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
          type: DioExceptionType.connectionError,
        ),
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error in getAutocomplete',
        error: e,
        stackTrace: stackTrace,
      );
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<DataState<TagDetailEntity>> getTagDetail({
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

      return DataSuccess(model.toEntity());
    } on DioException catch (e) {
      _logger.e('DioException in getTagDetail', error: e);
      return DataFailed(
        DioException(
          requestOptions: e.requestOptions,
          error: e.error,
          response: e.response,
          type: e.type,
        ),
      );
    } on SocketException catch (e) {
      _logger.e('SocketException in getTagDetail', error: e);
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
          type: DioExceptionType.connectionError,
        ),
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error in getTagDetail',
        error: e,
        stackTrace: stackTrace,
      );
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
