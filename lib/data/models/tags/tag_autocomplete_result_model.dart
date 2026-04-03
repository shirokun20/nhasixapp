import 'package:nhasixapp/data/models/tags/tag_model.dart';
import 'package:nhasixapp/domain/entities/tags/tag_autocomplete_result.dart';

/// Data model for autocomplete result from API v2
class TagAutocompleteResultModel extends TagAutocompleteResult {
  const TagAutocompleteResultModel({
    required super.suggestions,
    required super.query,
    required super.totalResults,
  });

  /// nhentai autocomplete returns a bare List OR a Map with a 'results' key
  factory TagAutocompleteResultModel.fromJson(
    dynamic json, {
    String query = '',
  }) {
    List<dynamic> items;
    if (json is List) {
      items = json;
    } else if (json is Map) {
      items = (json['results'] as List<dynamic>?) ?? [];
      query = (json['query'] as String?) ?? query;
    } else {
      items = [];
    }

    final results = items
        .map((e) => TagModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return TagAutocompleteResultModel(
      suggestions: results,
      query: query,
      totalResults:
          (json is Map ? json['total'] as int? : null) ?? results.length,
    );
  }

  factory TagAutocompleteResultModel.fromEntity(
    TagAutocompleteResult entity,
  ) {
    return TagAutocompleteResultModel(
      suggestions: entity.suggestions,
      query: entity.query,
      totalResults: entity.totalResults,
    );
  }

  TagAutocompleteResult toEntity() {
    return TagAutocompleteResult(
      suggestions: suggestions,
      query: query,
      totalResults: totalResults,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results':
          suggestions.map((e) => TagModel.fromEntity(e).toJson()).toList(),
      'query': query,
      'total': totalResults,
    };
  }
}
