// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImageMetadataImpl _$$ImageMetadataImplFromJson(Map<String, dynamic> json) =>
    _$ImageMetadataImpl(
      imageUrl: json['imageUrl'] as String,
      contentId: json['contentId'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      imageType: $enumDecode(_$ImageTypeEnumMap, json['imageType']),
    );

Map<String, dynamic> _$$ImageMetadataImplToJson(_$ImageMetadataImpl instance) =>
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
