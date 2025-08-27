// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FilterItem _$FilterItemFromJson(Map<String, dynamic> json) {
  return _FilterItem.fromJson(json);
}

/// @nodoc
mixin _$FilterItem {
  String get value => throw _privateConstructorUsedError;
  bool get isExcluded => throw _privateConstructorUsedError;

  /// Serializes this FilterItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterItemCopyWith<FilterItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterItemCopyWith<$Res> {
  factory $FilterItemCopyWith(
          FilterItem value, $Res Function(FilterItem) then) =
      _$FilterItemCopyWithImpl<$Res, FilterItem>;
  @useResult
  $Res call({String value, bool isExcluded});
}

/// @nodoc
class _$FilterItemCopyWithImpl<$Res, $Val extends FilterItem>
    implements $FilterItemCopyWith<$Res> {
  _$FilterItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? isExcluded = null,
  }) {
    return _then(_value.copyWith(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      isExcluded: null == isExcluded
          ? _value.isExcluded
          : isExcluded // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FilterItemImplCopyWith<$Res>
    implements $FilterItemCopyWith<$Res> {
  factory _$$FilterItemImplCopyWith(
          _$FilterItemImpl value, $Res Function(_$FilterItemImpl) then) =
      __$$FilterItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String value, bool isExcluded});
}

/// @nodoc
class __$$FilterItemImplCopyWithImpl<$Res>
    extends _$FilterItemCopyWithImpl<$Res, _$FilterItemImpl>
    implements _$$FilterItemImplCopyWith<$Res> {
  __$$FilterItemImplCopyWithImpl(
      _$FilterItemImpl _value, $Res Function(_$FilterItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? isExcluded = null,
  }) {
    return _then(_$FilterItemImpl(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      isExcluded: null == isExcluded
          ? _value.isExcluded
          : isExcluded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterItemImpl implements _FilterItem {
  const _$FilterItemImpl({required this.value, required this.isExcluded});

  factory _$FilterItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterItemImplFromJson(json);

  @override
  final String value;
  @override
  final bool isExcluded;

  @override
  String toString() {
    return 'FilterItem(value: $value, isExcluded: $isExcluded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterItemImpl &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isExcluded, isExcluded) ||
                other.isExcluded == isExcluded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value, isExcluded);

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterItemImplCopyWith<_$FilterItemImpl> get copyWith =>
      __$$FilterItemImplCopyWithImpl<_$FilterItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterItemImplToJson(
      this,
    );
  }
}

abstract class _FilterItem implements FilterItem {
  const factory _FilterItem(
      {required final String value,
      required final bool isExcluded}) = _$FilterItemImpl;

  factory _FilterItem.fromJson(Map<String, dynamic> json) =
      _$FilterItemImpl.fromJson;

  @override
  String get value;
  @override
  bool get isExcluded;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterItemImplCopyWith<_$FilterItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SearchFilter _$SearchFilterFromJson(Map<String, dynamic> json) {
  return _SearchFilter.fromJson(json);
}

/// @nodoc
mixin _$SearchFilter {
  String? get query => throw _privateConstructorUsedError;
  List<FilterItem> get tags => throw _privateConstructorUsedError;
  List<FilterItem> get artists => throw _privateConstructorUsedError;
  List<FilterItem> get characters => throw _privateConstructorUsedError;
  List<FilterItem> get parodies => throw _privateConstructorUsedError;
  List<FilterItem> get groups => throw _privateConstructorUsedError;
  String? get language =>
      throw _privateConstructorUsedError; // Single select only
  String? get category =>
      throw _privateConstructorUsedError; // Single select only
  int get page => throw _privateConstructorUsedError;
  SortOption get sortBy => throw _privateConstructorUsedError;
  bool get popular => throw _privateConstructorUsedError; // Popular filter
  IntRange? get pageCountRange => throw _privateConstructorUsedError;
  SearchSource get source =>
      throw _privateConstructorUsedError; // Navigation source tracking
  bool get highlightMode =>
      throw _privateConstructorUsedError; // Enable blur effect for excluded content
  String? get highlightQuery => throw _privateConstructorUsedError;

  /// Serializes this SearchFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchFilterCopyWith<SearchFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchFilterCopyWith<$Res> {
  factory $SearchFilterCopyWith(
          SearchFilter value, $Res Function(SearchFilter) then) =
      _$SearchFilterCopyWithImpl<$Res, SearchFilter>;
  @useResult
  $Res call(
      {String? query,
      List<FilterItem> tags,
      List<FilterItem> artists,
      List<FilterItem> characters,
      List<FilterItem> parodies,
      List<FilterItem> groups,
      String? language,
      String? category,
      int page,
      SortOption sortBy,
      bool popular,
      IntRange? pageCountRange,
      SearchSource source,
      bool highlightMode,
      String? highlightQuery});

  $IntRangeCopyWith<$Res>? get pageCountRange;
}

/// @nodoc
class _$SearchFilterCopyWithImpl<$Res, $Val extends SearchFilter>
    implements $SearchFilterCopyWith<$Res> {
  _$SearchFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = freezed,
    Object? tags = null,
    Object? artists = null,
    Object? characters = null,
    Object? parodies = null,
    Object? groups = null,
    Object? language = freezed,
    Object? category = freezed,
    Object? page = null,
    Object? sortBy = null,
    Object? popular = null,
    Object? pageCountRange = freezed,
    Object? source = null,
    Object? highlightMode = null,
    Object? highlightQuery = freezed,
  }) {
    return _then(_value.copyWith(
      query: freezed == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      artists: null == artists
          ? _value.artists
          : artists // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      characters: null == characters
          ? _value.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      parodies: null == parodies
          ? _value.parodies
          : parodies // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      groups: null == groups
          ? _value.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as SortOption,
      popular: null == popular
          ? _value.popular
          : popular // ignore: cast_nullable_to_non_nullable
              as bool,
      pageCountRange: freezed == pageCountRange
          ? _value.pageCountRange
          : pageCountRange // ignore: cast_nullable_to_non_nullable
              as IntRange?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as SearchSource,
      highlightMode: null == highlightMode
          ? _value.highlightMode
          : highlightMode // ignore: cast_nullable_to_non_nullable
              as bool,
      highlightQuery: freezed == highlightQuery
          ? _value.highlightQuery
          : highlightQuery // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IntRangeCopyWith<$Res>? get pageCountRange {
    if (_value.pageCountRange == null) {
      return null;
    }

    return $IntRangeCopyWith<$Res>(_value.pageCountRange!, (value) {
      return _then(_value.copyWith(pageCountRange: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SearchFilterImplCopyWith<$Res>
    implements $SearchFilterCopyWith<$Res> {
  factory _$$SearchFilterImplCopyWith(
          _$SearchFilterImpl value, $Res Function(_$SearchFilterImpl) then) =
      __$$SearchFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? query,
      List<FilterItem> tags,
      List<FilterItem> artists,
      List<FilterItem> characters,
      List<FilterItem> parodies,
      List<FilterItem> groups,
      String? language,
      String? category,
      int page,
      SortOption sortBy,
      bool popular,
      IntRange? pageCountRange,
      SearchSource source,
      bool highlightMode,
      String? highlightQuery});

  @override
  $IntRangeCopyWith<$Res>? get pageCountRange;
}

/// @nodoc
class __$$SearchFilterImplCopyWithImpl<$Res>
    extends _$SearchFilterCopyWithImpl<$Res, _$SearchFilterImpl>
    implements _$$SearchFilterImplCopyWith<$Res> {
  __$$SearchFilterImplCopyWithImpl(
      _$SearchFilterImpl _value, $Res Function(_$SearchFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = freezed,
    Object? tags = null,
    Object? artists = null,
    Object? characters = null,
    Object? parodies = null,
    Object? groups = null,
    Object? language = freezed,
    Object? category = freezed,
    Object? page = null,
    Object? sortBy = null,
    Object? popular = null,
    Object? pageCountRange = freezed,
    Object? source = null,
    Object? highlightMode = null,
    Object? highlightQuery = freezed,
  }) {
    return _then(_$SearchFilterImpl(
      query: freezed == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      artists: null == artists
          ? _value._artists
          : artists // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      characters: null == characters
          ? _value._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      parodies: null == parodies
          ? _value._parodies
          : parodies // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      groups: null == groups
          ? _value._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as SortOption,
      popular: null == popular
          ? _value.popular
          : popular // ignore: cast_nullable_to_non_nullable
              as bool,
      pageCountRange: freezed == pageCountRange
          ? _value.pageCountRange
          : pageCountRange // ignore: cast_nullable_to_non_nullable
              as IntRange?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as SearchSource,
      highlightMode: null == highlightMode
          ? _value.highlightMode
          : highlightMode // ignore: cast_nullable_to_non_nullable
              as bool,
      highlightQuery: freezed == highlightQuery
          ? _value.highlightQuery
          : highlightQuery // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchFilterImpl implements _SearchFilter {
  const _$SearchFilterImpl(
      {this.query,
      final List<FilterItem> tags = const [],
      final List<FilterItem> artists = const [],
      final List<FilterItem> characters = const [],
      final List<FilterItem> parodies = const [],
      final List<FilterItem> groups = const [],
      this.language,
      this.category,
      this.page = 1,
      this.sortBy = SortOption.newest,
      this.popular = false,
      this.pageCountRange,
      this.source = SearchSource.unknown,
      this.highlightMode = false,
      this.highlightQuery})
      : _tags = tags,
        _artists = artists,
        _characters = characters,
        _parodies = parodies,
        _groups = groups;

  factory _$SearchFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchFilterImplFromJson(json);

  @override
  final String? query;
  final List<FilterItem> _tags;
  @override
  @JsonKey()
  List<FilterItem> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<FilterItem> _artists;
  @override
  @JsonKey()
  List<FilterItem> get artists {
    if (_artists is EqualUnmodifiableListView) return _artists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artists);
  }

  final List<FilterItem> _characters;
  @override
  @JsonKey()
  List<FilterItem> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  final List<FilterItem> _parodies;
  @override
  @JsonKey()
  List<FilterItem> get parodies {
    if (_parodies is EqualUnmodifiableListView) return _parodies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parodies);
  }

  final List<FilterItem> _groups;
  @override
  @JsonKey()
  List<FilterItem> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  @override
  final String? language;
// Single select only
  @override
  final String? category;
// Single select only
  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final SortOption sortBy;
  @override
  @JsonKey()
  final bool popular;
// Popular filter
  @override
  final IntRange? pageCountRange;
  @override
  @JsonKey()
  final SearchSource source;
// Navigation source tracking
  @override
  @JsonKey()
  final bool highlightMode;
// Enable blur effect for excluded content
  @override
  final String? highlightQuery;

  @override
  String toString() {
    return 'SearchFilter(query: $query, tags: $tags, artists: $artists, characters: $characters, parodies: $parodies, groups: $groups, language: $language, category: $category, page: $page, sortBy: $sortBy, popular: $popular, pageCountRange: $pageCountRange, source: $source, highlightMode: $highlightMode, highlightQuery: $highlightQuery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchFilterImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._artists, _artists) &&
            const DeepCollectionEquality()
                .equals(other._characters, _characters) &&
            const DeepCollectionEquality().equals(other._parodies, _parodies) &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.popular, popular) || other.popular == popular) &&
            (identical(other.pageCountRange, pageCountRange) ||
                other.pageCountRange == pageCountRange) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.highlightMode, highlightMode) ||
                other.highlightMode == highlightMode) &&
            (identical(other.highlightQuery, highlightQuery) ||
                other.highlightQuery == highlightQuery));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      query,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_artists),
      const DeepCollectionEquality().hash(_characters),
      const DeepCollectionEquality().hash(_parodies),
      const DeepCollectionEquality().hash(_groups),
      language,
      category,
      page,
      sortBy,
      popular,
      pageCountRange,
      source,
      highlightMode,
      highlightQuery);

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchFilterImplCopyWith<_$SearchFilterImpl> get copyWith =>
      __$$SearchFilterImplCopyWithImpl<_$SearchFilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchFilterImplToJson(
      this,
    );
  }
}

abstract class _SearchFilter implements SearchFilter {
  const factory _SearchFilter(
      {final String? query,
      final List<FilterItem> tags,
      final List<FilterItem> artists,
      final List<FilterItem> characters,
      final List<FilterItem> parodies,
      final List<FilterItem> groups,
      final String? language,
      final String? category,
      final int page,
      final SortOption sortBy,
      final bool popular,
      final IntRange? pageCountRange,
      final SearchSource source,
      final bool highlightMode,
      final String? highlightQuery}) = _$SearchFilterImpl;

  factory _SearchFilter.fromJson(Map<String, dynamic> json) =
      _$SearchFilterImpl.fromJson;

  @override
  String? get query;
  @override
  List<FilterItem> get tags;
  @override
  List<FilterItem> get artists;
  @override
  List<FilterItem> get characters;
  @override
  List<FilterItem> get parodies;
  @override
  List<FilterItem> get groups;
  @override
  String? get language; // Single select only
  @override
  String? get category; // Single select only
  @override
  int get page;
  @override
  SortOption get sortBy;
  @override
  bool get popular; // Popular filter
  @override
  IntRange? get pageCountRange;
  @override
  SearchSource get source; // Navigation source tracking
  @override
  bool get highlightMode; // Enable blur effect for excluded content
  @override
  String? get highlightQuery;

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchFilterImplCopyWith<_$SearchFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IntRange _$IntRangeFromJson(Map<String, dynamic> json) {
  return _IntRange.fromJson(json);
}

/// @nodoc
mixin _$IntRange {
  int? get min => throw _privateConstructorUsedError;
  int? get max => throw _privateConstructorUsedError;

  /// Serializes this IntRange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IntRangeCopyWith<IntRange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IntRangeCopyWith<$Res> {
  factory $IntRangeCopyWith(IntRange value, $Res Function(IntRange) then) =
      _$IntRangeCopyWithImpl<$Res, IntRange>;
  @useResult
  $Res call({int? min, int? max});
}

/// @nodoc
class _$IntRangeCopyWithImpl<$Res, $Val extends IntRange>
    implements $IntRangeCopyWith<$Res> {
  _$IntRangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_value.copyWith(
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as int?,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IntRangeImplCopyWith<$Res>
    implements $IntRangeCopyWith<$Res> {
  factory _$$IntRangeImplCopyWith(
          _$IntRangeImpl value, $Res Function(_$IntRangeImpl) then) =
      __$$IntRangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? min, int? max});
}

/// @nodoc
class __$$IntRangeImplCopyWithImpl<$Res>
    extends _$IntRangeCopyWithImpl<$Res, _$IntRangeImpl>
    implements _$$IntRangeImplCopyWith<$Res> {
  __$$IntRangeImplCopyWithImpl(
      _$IntRangeImpl _value, $Res Function(_$IntRangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_$IntRangeImpl(
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as int?,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IntRangeImpl implements _IntRange {
  const _$IntRangeImpl({this.min, this.max});

  factory _$IntRangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$IntRangeImplFromJson(json);

  @override
  final int? min;
  @override
  final int? max;

  @override
  String toString() {
    return 'IntRange(min: $min, max: $max)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IntRangeImpl &&
            (identical(other.min, min) || other.min == min) &&
            (identical(other.max, max) || other.max == max));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, min, max);

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IntRangeImplCopyWith<_$IntRangeImpl> get copyWith =>
      __$$IntRangeImplCopyWithImpl<_$IntRangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IntRangeImplToJson(
      this,
    );
  }
}

abstract class _IntRange implements IntRange {
  const factory _IntRange({final int? min, final int? max}) = _$IntRangeImpl;

  factory _IntRange.fromJson(Map<String, dynamic> json) =
      _$IntRangeImpl.fromJson;

  @override
  int? get min;
  @override
  int? get max;

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IntRangeImplCopyWith<_$IntRangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FilterValidationResult _$FilterValidationResultFromJson(
    Map<String, dynamic> json) {
  return _FilterValidationResult.fromJson(json);
}

/// @nodoc
mixin _$FilterValidationResult {
  bool get isValid => throw _privateConstructorUsedError;
  List<String> get errors => throw _privateConstructorUsedError;
  List<String> get warnings => throw _privateConstructorUsedError;

  /// Serializes this FilterValidationResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterValidationResultCopyWith<FilterValidationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterValidationResultCopyWith<$Res> {
  factory $FilterValidationResultCopyWith(FilterValidationResult value,
          $Res Function(FilterValidationResult) then) =
      _$FilterValidationResultCopyWithImpl<$Res, FilterValidationResult>;
  @useResult
  $Res call({bool isValid, List<String> errors, List<String> warnings});
}

/// @nodoc
class _$FilterValidationResultCopyWithImpl<$Res,
        $Val extends FilterValidationResult>
    implements $FilterValidationResultCopyWith<$Res> {
  _$FilterValidationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? errors = null,
    Object? warnings = null,
  }) {
    return _then(_value.copyWith(
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FilterValidationResultImplCopyWith<$Res>
    implements $FilterValidationResultCopyWith<$Res> {
  factory _$$FilterValidationResultImplCopyWith(
          _$FilterValidationResultImpl value,
          $Res Function(_$FilterValidationResultImpl) then) =
      __$$FilterValidationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isValid, List<String> errors, List<String> warnings});
}

/// @nodoc
class __$$FilterValidationResultImplCopyWithImpl<$Res>
    extends _$FilterValidationResultCopyWithImpl<$Res,
        _$FilterValidationResultImpl>
    implements _$$FilterValidationResultImplCopyWith<$Res> {
  __$$FilterValidationResultImplCopyWithImpl(
      _$FilterValidationResultImpl _value,
      $Res Function(_$FilterValidationResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? errors = null,
    Object? warnings = null,
  }) {
    return _then(_$FilterValidationResultImpl(
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errors: null == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterValidationResultImpl implements _FilterValidationResult {
  const _$FilterValidationResultImpl(
      {required this.isValid,
      required final List<String> errors,
      required final List<String> warnings})
      : _errors = errors,
        _warnings = warnings;

  factory _$FilterValidationResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterValidationResultImplFromJson(json);

  @override
  final bool isValid;
  final List<String> _errors;
  @override
  List<String> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  final List<String> _warnings;
  @override
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

  @override
  String toString() {
    return 'FilterValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterValidationResultImpl &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            const DeepCollectionEquality().equals(other._errors, _errors) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isValid,
      const DeepCollectionEquality().hash(_errors),
      const DeepCollectionEquality().hash(_warnings));

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterValidationResultImplCopyWith<_$FilterValidationResultImpl>
      get copyWith => __$$FilterValidationResultImplCopyWithImpl<
          _$FilterValidationResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterValidationResultImplToJson(
      this,
    );
  }
}

abstract class _FilterValidationResult implements FilterValidationResult {
  const factory _FilterValidationResult(
      {required final bool isValid,
      required final List<String> errors,
      required final List<String> warnings}) = _$FilterValidationResultImpl;

  factory _FilterValidationResult.fromJson(Map<String, dynamic> json) =
      _$FilterValidationResultImpl.fromJson;

  @override
  bool get isValid;
  @override
  List<String> get errors;
  @override
  List<String> get warnings;

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterValidationResultImplCopyWith<_$FilterValidationResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}
