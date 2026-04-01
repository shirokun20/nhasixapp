import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/domain/entities/tags/tag_autocomplete_result.dart';
import 'package:nhasixapp/domain/entities/tags/tag_detail_entity.dart';
import 'package:nhasixapp/domain/entities/tags/tag_entity.dart';

/// Repository interface for tag operations using API v2 endpoints
abstract class TagRepository {
  /// Get tags by type (artist, tag, character, etc.)
  /// Uses: GET /api/v2/tags/{tag_type}
  Future<DataState<List<TagEntity>>> getTagsByType({
    required String tagType,
    required String sourceId,
    int page = 1,
    int perPage = 30,
  });

  /// Get autocomplete suggestions for a query
  /// Uses: POST /api/v2/tags/autocomplete
  Future<DataState<TagAutocompleteResult>> getAutocomplete({
    required String query,
    required String sourceId,
    String? tagType,
    int limit = 10,
  });

  /// Get detailed information about a specific tag
  /// Uses: GET /api/v2/tags/{tag_type}/{slug}
  Future<DataState<TagDetailEntity>> getTagDetail({
    required String tagType,
    required String slug,
    required String sourceId,
  });
}
