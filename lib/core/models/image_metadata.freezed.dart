// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ImageMetadata _$ImageMetadataFromJson(Map<String, dynamic> json) {
  return _ImageMetadata.fromJson(json);
}

/// @nodoc
mixin _$ImageMetadata {
  /// Final resolved URL for image loading
  String get imageUrl => throw _privateConstructorUsedError;

  /// nhentai Gallery ID (public identifier)
  String get contentId => throw _privateConstructorUsedError;

  /// 1-based page number
  int get pageNumber => throw _privateConstructorUsedError;

  /// Type of image source (online/cached)
  ImageType get imageType => throw _privateConstructorUsedError;

  /// Serializes this ImageMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImageMetadataCopyWith<ImageMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageMetadataCopyWith<$Res> {
  factory $ImageMetadataCopyWith(
          ImageMetadata value, $Res Function(ImageMetadata) then) =
      _$ImageMetadataCopyWithImpl<$Res, ImageMetadata>;
  @useResult
  $Res call(
      {String imageUrl, String contentId, int pageNumber, ImageType imageType});
}

/// @nodoc
class _$ImageMetadataCopyWithImpl<$Res, $Val extends ImageMetadata>
    implements $ImageMetadataCopyWith<$Res> {
  _$ImageMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageUrl = null,
    Object? contentId = null,
    Object? pageNumber = null,
    Object? imageType = null,
  }) {
    return _then(_value.copyWith(
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      contentId: null == contentId
          ? _value.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as String,
      pageNumber: null == pageNumber
          ? _value.pageNumber
          : pageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      imageType: null == imageType
          ? _value.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as ImageType,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImageMetadataImplCopyWith<$Res>
    implements $ImageMetadataCopyWith<$Res> {
  factory _$$ImageMetadataImplCopyWith(
          _$ImageMetadataImpl value, $Res Function(_$ImageMetadataImpl) then) =
      __$$ImageMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String imageUrl, String contentId, int pageNumber, ImageType imageType});
}

/// @nodoc
class __$$ImageMetadataImplCopyWithImpl<$Res>
    extends _$ImageMetadataCopyWithImpl<$Res, _$ImageMetadataImpl>
    implements _$$ImageMetadataImplCopyWith<$Res> {
  __$$ImageMetadataImplCopyWithImpl(
      _$ImageMetadataImpl _value, $Res Function(_$ImageMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageUrl = null,
    Object? contentId = null,
    Object? pageNumber = null,
    Object? imageType = null,
  }) {
    return _then(_$ImageMetadataImpl(
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      contentId: null == contentId
          ? _value.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as String,
      pageNumber: null == pageNumber
          ? _value.pageNumber
          : pageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      imageType: null == imageType
          ? _value.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as ImageType,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImageMetadataImpl implements _ImageMetadata {
  const _$ImageMetadataImpl(
      {required this.imageUrl,
      required this.contentId,
      required this.pageNumber,
      required this.imageType});

  factory _$ImageMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImageMetadataImplFromJson(json);

  /// Final resolved URL for image loading
  @override
  final String imageUrl;

  /// nhentai Gallery ID (public identifier)
  @override
  final String contentId;

  /// 1-based page number
  @override
  final int pageNumber;

  /// Type of image source (online/cached)
  @override
  final ImageType imageType;

  @override
  String toString() {
    return 'ImageMetadata(imageUrl: $imageUrl, contentId: $contentId, pageNumber: $pageNumber, imageType: $imageType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageMetadataImpl &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.contentId, contentId) ||
                other.contentId == contentId) &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber) &&
            (identical(other.imageType, imageType) ||
                other.imageType == imageType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, imageUrl, contentId, pageNumber, imageType);

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageMetadataImplCopyWith<_$ImageMetadataImpl> get copyWith =>
      __$$ImageMetadataImplCopyWithImpl<_$ImageMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImageMetadataImplToJson(
      this,
    );
  }
}

abstract class _ImageMetadata implements ImageMetadata {
  const factory _ImageMetadata(
      {required final String imageUrl,
      required final String contentId,
      required final int pageNumber,
      required final ImageType imageType}) = _$ImageMetadataImpl;

  factory _ImageMetadata.fromJson(Map<String, dynamic> json) =
      _$ImageMetadataImpl.fromJson;

  /// Final resolved URL for image loading
  @override
  String get imageUrl;

  /// nhentai Gallery ID (public identifier)
  @override
  String get contentId;

  /// 1-based page number
  @override
  int get pageNumber;

  /// Type of image source (online/cached)
  @override
  ImageType get imageType;

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageMetadataImplCopyWith<_$ImageMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
