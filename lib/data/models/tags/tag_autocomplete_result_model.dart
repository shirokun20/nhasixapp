import 'package:nhasixapp/data/models/tags/tag_model.dart';
import 'package:nhasixapp/domain/entities/tags/tag_autocomplete_result.dart';

/// Data model for autocomplete result from API v2
class TagAutocompleteResultModel extends TagAutocompleteResult {
  const TagAutocompleteResultModel({
    required super.suggestions,
    required super.query,
    required super.totalResults,
  });

  factory TagAutocompleteResultModel.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?)
            ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return TagAutocompleteResultModel(
      suggestions: results,
      query: json['query'] as String? ?? '',
      totalResults: json['total'] as int? ?? results.length,
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
      'results': suggestions
          .map((e) => TagModel.fromEntity(e).toJson())
          .toList(),
      'query': query,
      'total': totalResults,
    };
  }
}
