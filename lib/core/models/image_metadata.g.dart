// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImageMetadata _$ImageMetadataFromJson(Map<String, dynamic> json) =>
    _ImageMetadata(
      imageUrl: json['imageUrl'] as String,
      contentId: json['contentId'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      imageType: $enumDecode(_$ImageTypeEnumMap, json['imageType']),
    );

Map<String, dynamic> _$ImageMetadataToJson(_ImageMetadata instance) =>
    <String, dynamic>{
      'imageUrl': instance.imageUrl,
      'contentId': instance.contentId,
      'pageNumber': instance.pageNumber,
      'imageType': _$ImageTypeEnumMap[instance.imageType]!,
    };

const _$ImageTypeEnumMap = {
  ImageType.online: 'online',
  ImageType.cached: 'cached',
};
