// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FilterItem _$FilterItemFromJson(Map<String, dynamic> json) => _FilterItem(
      value: json['value'] as String,
      isExcluded: json['isExcluded'] as bool,
    );

Map<String, dynamic> _$FilterItemToJson(_FilterItem instance) =>
    <String, dynamic>{
      'value': instance.value,
      'isExcluded': instance.isExcluded,
    };

_SearchFilter _$SearchFilterFromJson(Map<String, dynamic> json) =>
    _SearchFilter(
      query: json['query'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      parodies: (json['parodies'] as List<dynamic>?)
              ?.map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      language: json['language'] as String?,
      category: json['category'] as String?,
      genre: json['genre'] as String?,
      page: (json['page'] as num?)?.toInt() ?? 1,
      sortBy: $enumDecodeNullable(_$SortOptionEnumMap, json['sortBy']) ??
          SortOption.newest,
      popular: json['popular'] as bool? ?? false,
      pageCountRange: json['pageCountRange'] == null
          ? null
          : IntRange.fromJson(json['pageCountRange'] as Map<String, dynamic>),
      source: $enumDecodeNullable(_$SearchSourceEnumMap, json['source']) ??
          SearchSource.unknown,
      highlightMode: json['highlightMode'] as bool? ?? false,
      highlightQuery: json['highlightQuery'] as String?,
    );

Map<String, dynamic> _$SearchFilterToJson(_SearchFilter instance) =>
    <String, dynamic>{
      'query': instance.query,
      'tags': instance.tags,
      'artists': instance.artists,
      'characters': instance.characters,
      'parodies': instance.parodies,
      'groups': instance.groups,
      'language': instance.language,
      'category': instance.category,
      'genre': instance.genre,
      'page': instance.page,
      'sortBy': _$SortOptionEnumMap[instance.sortBy]!,
      'popular': instance.popular,
      'pageCountRange': instance.pageCountRange,
      'source': _$SearchSourceEnumMap[instance.source]!,
      'highlightMode': instance.highlightMode,
      'highlightQuery': instance.highlightQuery,
    };

const _$SortOptionEnumMap = {
  SortOption.newest: 'newest',
  SortOption.popular: 'popular',
  SortOption.popularWeek: 'popularWeek',
  SortOption.popularToday: 'popularToday',
};

const _$SearchSourceEnumMap = {
  SearchSource.searchScreen: 'searchScreen',
  SearchSource.detailScreen: 'detailScreen',
  SearchSource.homeScreen: 'homeScreen',
  SearchSource.unknown: 'unknown',
};

_IntRange _$IntRangeFromJson(Map<String, dynamic> json) => _IntRange(
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IntRangeToJson(_IntRange instance) => <String, dynamic>{
      'min': instance.min,
      'max': instance.max,
    };

_FilterValidationResult _$FilterValidationResultFromJson(
        Map<String, dynamic> json) =>
    _FilterValidationResult(
      isValid: json['isValid'] as bool,
      errors:
          (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
      warnings:
          (json['warnings'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$FilterValidationResultToJson(
        _FilterValidationResult instance) =>
    <String, dynamic>{
      'isValid': instance.isValid,
      'errors': instance.errors,
      'warnings': instance.warnings,
    };
