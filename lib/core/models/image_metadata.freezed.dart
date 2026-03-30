// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImageMetadata {
  /// Final resolved URL for image loading
  String get imageUrl;

  /// nhentai Gallery ID (public identifier)
  String get contentId;

  /// 1-based page number
  int get pageNumber;

  /// Type of image source (online/cached)
  ImageType get imageType;

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImageMetadataCopyWith<ImageMetadata> get copyWith =>
      _$ImageMetadataCopyWithImpl<ImageMetadata>(
          this as ImageMetadata, _$identity);

  /// Serializes this ImageMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImageMetadata &&
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

  @override
  String toString() {
    return 'ImageMetadata(imageUrl: $imageUrl, contentId: $contentId, pageNumber: $pageNumber, imageType: $imageType)';
  }
}

/// @nodoc
abstract mixin class $ImageMetadataCopyWith<$Res> {
  factory $ImageMetadataCopyWith(
          ImageMetadata value, $Res Function(ImageMetadata) _then) =
      _$ImageMetadataCopyWithImpl;
  @useResult
  $Res call(
      {String imageUrl, String contentId, int pageNumber, ImageType imageType});
}

/// @nodoc
class _$ImageMetadataCopyWithImpl<$Res>
    implements $ImageMetadataCopyWith<$Res> {
  _$ImageMetadataCopyWithImpl(this._self, this._then);

  final ImageMetadata _self;
  final $Res Function(ImageMetadata) _then;

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
    return _then(_self.copyWith(
      imageUrl: null == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      contentId: null == contentId
          ? _self.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as String,
      pageNumber: null == pageNumber
          ? _self.pageNumber
          : pageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      imageType: null == imageType
          ? _self.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as ImageType,
    ));
  }
}

/// Adds pattern-matching-related methods to [ImageMetadata].
extension ImageMetadataPatterns on ImageMetadata {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ImageMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImageMetadata() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ImageMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImageMetadata():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ImageMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImageMetadata() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String imageUrl, String contentId, int pageNumber,
            ImageType imageType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImageMetadata() when $default != null:
        return $default(
            _that.imageUrl, _that.contentId, _that.pageNumber, _that.imageType);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String imageUrl, String contentId, int pageNumber,
            ImageType imageType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImageMetadata():
        return $default(
            _that.imageUrl, _that.contentId, _that.pageNumber, _that.imageType);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String imageUrl, String contentId, int pageNumber,
            ImageType imageType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImageMetadata() when $default != null:
        return $default(
            _that.imageUrl, _that.contentId, _that.pageNumber, _that.imageType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ImageMetadata implements ImageMetadata {
  const _ImageMetadata(
      {required this.imageUrl,
      required this.contentId,
      required this.pageNumber,
      required this.imageType});
  factory _ImageMetadata.fromJson(Map<String, dynamic> json) =>
      _$ImageMetadataFromJson(json);

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

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ImageMetadataCopyWith<_ImageMetadata> get copyWith =>
      __$ImageMetadataCopyWithImpl<_ImageMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ImageMetadataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ImageMetadata &&
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

  @override
  String toString() {
    return 'ImageMetadata(imageUrl: $imageUrl, contentId: $contentId, pageNumber: $pageNumber, imageType: $imageType)';
  }
}

/// @nodoc
abstract mixin class _$ImageMetadataCopyWith<$Res>
    implements $ImageMetadataCopyWith<$Res> {
  factory _$ImageMetadataCopyWith(
          _ImageMetadata value, $Res Function(_ImageMetadata) _then) =
      __$ImageMetadataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String imageUrl, String contentId, int pageNumber, ImageType imageType});
}

/// @nodoc
class __$ImageMetadataCopyWithImpl<$Res>
    implements _$ImageMetadataCopyWith<$Res> {
  __$ImageMetadataCopyWithImpl(this._self, this._then);

  final _ImageMetadata _self;
  final $Res Function(_ImageMetadata) _then;

  /// Create a copy of ImageMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? imageUrl = null,
    Object? contentId = null,
    Object? pageNumber = null,
    Object? imageType = null,
  }) {
    return _then(_ImageMetadata(
      imageUrl: null == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      contentId: null == contentId
          ? _self.contentId
          : contentId // ignore: cast_nullable_to_non_nullable
              as String,
      pageNumber: null == pageNumber
          ? _self.pageNumber
          : pageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      imageType: null == imageType
          ? _self.imageType
          : imageType // ignore: cast_nullable_to_non_nullable
              as ImageType,
    ));
  }
}

// dart format on
