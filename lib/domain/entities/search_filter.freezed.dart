// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FilterItem {
  String get value;
  bool get isExcluded;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilterItemCopyWith<FilterItem> get copyWith =>
      _$FilterItemCopyWithImpl<FilterItem>(this as FilterItem, _$identity);

  /// Serializes this FilterItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilterItem &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isExcluded, isExcluded) ||
                other.isExcluded == isExcluded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value, isExcluded);

  @override
  String toString() {
    return 'FilterItem(value: $value, isExcluded: $isExcluded)';
  }
}

/// @nodoc
abstract mixin class $FilterItemCopyWith<$Res> {
  factory $FilterItemCopyWith(
          FilterItem value, $Res Function(FilterItem) _then) =
      _$FilterItemCopyWithImpl;
  @useResult
  $Res call({String value, bool isExcluded});
}

/// @nodoc
class _$FilterItemCopyWithImpl<$Res> implements $FilterItemCopyWith<$Res> {
  _$FilterItemCopyWithImpl(this._self, this._then);

  final FilterItem _self;
  final $Res Function(FilterItem) _then;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? isExcluded = null,
  }) {
    return _then(_self.copyWith(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      isExcluded: null == isExcluded
          ? _self.isExcluded
          : isExcluded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [FilterItem].
extension FilterItemPatterns on FilterItem {
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
    TResult Function(_FilterItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterItem() when $default != null:
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
    TResult Function(_FilterItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterItem():
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
    TResult? Function(_FilterItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterItem() when $default != null:
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
    TResult Function(String value, bool isExcluded)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterItem() when $default != null:
        return $default(_that.value, _that.isExcluded);
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
    TResult Function(String value, bool isExcluded) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterItem():
        return $default(_that.value, _that.isExcluded);
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
    TResult? Function(String value, bool isExcluded)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterItem() when $default != null:
        return $default(_that.value, _that.isExcluded);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FilterItem implements FilterItem {
  const _FilterItem({required this.value, required this.isExcluded});
  factory _FilterItem.fromJson(Map<String, dynamic> json) =>
      _$FilterItemFromJson(json);

  @override
  final String value;
  @override
  final bool isExcluded;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FilterItemCopyWith<_FilterItem> get copyWith =>
      __$FilterItemCopyWithImpl<_FilterItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FilterItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FilterItem &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.isExcluded, isExcluded) ||
                other.isExcluded == isExcluded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value, isExcluded);

  @override
  String toString() {
    return 'FilterItem(value: $value, isExcluded: $isExcluded)';
  }
}

/// @nodoc
abstract mixin class _$FilterItemCopyWith<$Res>
    implements $FilterItemCopyWith<$Res> {
  factory _$FilterItemCopyWith(
          _FilterItem value, $Res Function(_FilterItem) _then) =
      __$FilterItemCopyWithImpl;
  @override
  @useResult
  $Res call({String value, bool isExcluded});
}

/// @nodoc
class __$FilterItemCopyWithImpl<$Res> implements _$FilterItemCopyWith<$Res> {
  __$FilterItemCopyWithImpl(this._self, this._then);

  final _FilterItem _self;
  final $Res Function(_FilterItem) _then;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
    Object? isExcluded = null,
  }) {
    return _then(_FilterItem(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      isExcluded: null == isExcluded
          ? _self.isExcluded
          : isExcluded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$SearchFilter {
  String? get query;
  List<FilterItem> get tags;
  List<FilterItem> get artists;
  List<FilterItem> get characters;
  List<FilterItem> get parodies;
  List<FilterItem> get groups;
  String? get language; // Single select only
  String? get category; // Single select only
  int get page;
  SortOption get sortBy;
  bool get popular; // Popular filter
  IntRange? get pageCountRange;
  SearchSource get source; // Navigation source tracking
  bool get highlightMode; // Enable blur effect for excluded content
  String? get highlightQuery;

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SearchFilterCopyWith<SearchFilter> get copyWith =>
      _$SearchFilterCopyWithImpl<SearchFilter>(
          this as SearchFilter, _$identity);

  /// Serializes this SearchFilter to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SearchFilter &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality().equals(other.artists, artists) &&
            const DeepCollectionEquality()
                .equals(other.characters, characters) &&
            const DeepCollectionEquality().equals(other.parodies, parodies) &&
            const DeepCollectionEquality().equals(other.groups, groups) &&
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
      const DeepCollectionEquality().hash(tags),
      const DeepCollectionEquality().hash(artists),
      const DeepCollectionEquality().hash(characters),
      const DeepCollectionEquality().hash(parodies),
      const DeepCollectionEquality().hash(groups),
      language,
      category,
      page,
      sortBy,
      popular,
      pageCountRange,
      source,
      highlightMode,
      highlightQuery);

  @override
  String toString() {
    return 'SearchFilter(query: $query, tags: $tags, artists: $artists, characters: $characters, parodies: $parodies, groups: $groups, language: $language, category: $category, page: $page, sortBy: $sortBy, popular: $popular, pageCountRange: $pageCountRange, source: $source, highlightMode: $highlightMode, highlightQuery: $highlightQuery)';
  }
}

/// @nodoc
abstract mixin class $SearchFilterCopyWith<$Res> {
  factory $SearchFilterCopyWith(
          SearchFilter value, $Res Function(SearchFilter) _then) =
      _$SearchFilterCopyWithImpl;
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
class _$SearchFilterCopyWithImpl<$Res> implements $SearchFilterCopyWith<$Res> {
  _$SearchFilterCopyWithImpl(this._self, this._then);

  final SearchFilter _self;
  final $Res Function(SearchFilter) _then;

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
    return _then(_self.copyWith(
      query: freezed == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      artists: null == artists
          ? _self.artists
          : artists // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      characters: null == characters
          ? _self.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      parodies: null == parodies
          ? _self.parodies
          : parodies // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      groups: null == groups
          ? _self.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      language: freezed == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      sortBy: null == sortBy
          ? _self.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as SortOption,
      popular: null == popular
          ? _self.popular
          : popular // ignore: cast_nullable_to_non_nullable
              as bool,
      pageCountRange: freezed == pageCountRange
          ? _self.pageCountRange
          : pageCountRange // ignore: cast_nullable_to_non_nullable
              as IntRange?,
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as SearchSource,
      highlightMode: null == highlightMode
          ? _self.highlightMode
          : highlightMode // ignore: cast_nullable_to_non_nullable
              as bool,
      highlightQuery: freezed == highlightQuery
          ? _self.highlightQuery
          : highlightQuery // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IntRangeCopyWith<$Res>? get pageCountRange {
    if (_self.pageCountRange == null) {
      return null;
    }

    return $IntRangeCopyWith<$Res>(_self.pageCountRange!, (value) {
      return _then(_self.copyWith(pageCountRange: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SearchFilter].
extension SearchFilterPatterns on SearchFilter {
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
    TResult Function(_SearchFilter value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchFilter() when $default != null:
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
    TResult Function(_SearchFilter value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchFilter():
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
    TResult? Function(_SearchFilter value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchFilter() when $default != null:
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
    TResult Function(
            String? query,
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
            String? highlightQuery)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchFilter() when $default != null:
        return $default(
            _that.query,
            _that.tags,
            _that.artists,
            _that.characters,
            _that.parodies,
            _that.groups,
            _that.language,
            _that.category,
            _that.page,
            _that.sortBy,
            _that.popular,
            _that.pageCountRange,
            _that.source,
            _that.highlightMode,
            _that.highlightQuery);
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
    TResult Function(
            String? query,
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
            String? highlightQuery)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchFilter():
        return $default(
            _that.query,
            _that.tags,
            _that.artists,
            _that.characters,
            _that.parodies,
            _that.groups,
            _that.language,
            _that.category,
            _that.page,
            _that.sortBy,
            _that.popular,
            _that.pageCountRange,
            _that.source,
            _that.highlightMode,
            _that.highlightQuery);
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
    TResult? Function(
            String? query,
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
            String? highlightQuery)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchFilter() when $default != null:
        return $default(
            _that.query,
            _that.tags,
            _that.artists,
            _that.characters,
            _that.parodies,
            _that.groups,
            _that.language,
            _that.category,
            _that.page,
            _that.sortBy,
            _that.popular,
            _that.pageCountRange,
            _that.source,
            _that.highlightMode,
            _that.highlightQuery);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SearchFilter implements SearchFilter {
  const _SearchFilter(
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
  factory _SearchFilter.fromJson(Map<String, dynamic> json) =>
      _$SearchFilterFromJson(json);

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

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchFilterCopyWith<_SearchFilter> get copyWith =>
      __$SearchFilterCopyWithImpl<_SearchFilter>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SearchFilterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchFilter &&
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

  @override
  String toString() {
    return 'SearchFilter(query: $query, tags: $tags, artists: $artists, characters: $characters, parodies: $parodies, groups: $groups, language: $language, category: $category, page: $page, sortBy: $sortBy, popular: $popular, pageCountRange: $pageCountRange, source: $source, highlightMode: $highlightMode, highlightQuery: $highlightQuery)';
  }
}

/// @nodoc
abstract mixin class _$SearchFilterCopyWith<$Res>
    implements $SearchFilterCopyWith<$Res> {
  factory _$SearchFilterCopyWith(
          _SearchFilter value, $Res Function(_SearchFilter) _then) =
      __$SearchFilterCopyWithImpl;
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
class __$SearchFilterCopyWithImpl<$Res>
    implements _$SearchFilterCopyWith<$Res> {
  __$SearchFilterCopyWithImpl(this._self, this._then);

  final _SearchFilter _self;
  final $Res Function(_SearchFilter) _then;

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_SearchFilter(
      query: freezed == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      artists: null == artists
          ? _self._artists
          : artists // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      characters: null == characters
          ? _self._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      parodies: null == parodies
          ? _self._parodies
          : parodies // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      groups: null == groups
          ? _self._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      language: freezed == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      sortBy: null == sortBy
          ? _self.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as SortOption,
      popular: null == popular
          ? _self.popular
          : popular // ignore: cast_nullable_to_non_nullable
              as bool,
      pageCountRange: freezed == pageCountRange
          ? _self.pageCountRange
          : pageCountRange // ignore: cast_nullable_to_non_nullable
              as IntRange?,
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as SearchSource,
      highlightMode: null == highlightMode
          ? _self.highlightMode
          : highlightMode // ignore: cast_nullable_to_non_nullable
              as bool,
      highlightQuery: freezed == highlightQuery
          ? _self.highlightQuery
          : highlightQuery // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of SearchFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IntRangeCopyWith<$Res>? get pageCountRange {
    if (_self.pageCountRange == null) {
      return null;
    }

    return $IntRangeCopyWith<$Res>(_self.pageCountRange!, (value) {
      return _then(_self.copyWith(pageCountRange: value));
    });
  }
}

/// @nodoc
mixin _$IntRange {
  int? get min;
  int? get max;

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $IntRangeCopyWith<IntRange> get copyWith =>
      _$IntRangeCopyWithImpl<IntRange>(this as IntRange, _$identity);

  /// Serializes this IntRange to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is IntRange &&
            (identical(other.min, min) || other.min == min) &&
            (identical(other.max, max) || other.max == max));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, min, max);

  @override
  String toString() {
    return 'IntRange(min: $min, max: $max)';
  }
}

/// @nodoc
abstract mixin class $IntRangeCopyWith<$Res> {
  factory $IntRangeCopyWith(IntRange value, $Res Function(IntRange) _then) =
      _$IntRangeCopyWithImpl;
  @useResult
  $Res call({int? min, int? max});
}

/// @nodoc
class _$IntRangeCopyWithImpl<$Res> implements $IntRangeCopyWith<$Res> {
  _$IntRangeCopyWithImpl(this._self, this._then);

  final IntRange _self;
  final $Res Function(IntRange) _then;

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_self.copyWith(
      min: freezed == min
          ? _self.min
          : min // ignore: cast_nullable_to_non_nullable
              as int?,
      max: freezed == max
          ? _self.max
          : max // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [IntRange].
extension IntRangePatterns on IntRange {
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
    TResult Function(_IntRange value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _IntRange() when $default != null:
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
    TResult Function(_IntRange value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IntRange():
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
    TResult? Function(_IntRange value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IntRange() when $default != null:
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
    TResult Function(int? min, int? max)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _IntRange() when $default != null:
        return $default(_that.min, _that.max);
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
    TResult Function(int? min, int? max) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IntRange():
        return $default(_that.min, _that.max);
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
    TResult? Function(int? min, int? max)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _IntRange() when $default != null:
        return $default(_that.min, _that.max);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _IntRange implements IntRange {
  const _IntRange({this.min, this.max});
  factory _IntRange.fromJson(Map<String, dynamic> json) =>
      _$IntRangeFromJson(json);

  @override
  final int? min;
  @override
  final int? max;

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$IntRangeCopyWith<_IntRange> get copyWith =>
      __$IntRangeCopyWithImpl<_IntRange>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$IntRangeToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _IntRange &&
            (identical(other.min, min) || other.min == min) &&
            (identical(other.max, max) || other.max == max));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, min, max);

  @override
  String toString() {
    return 'IntRange(min: $min, max: $max)';
  }
}

/// @nodoc
abstract mixin class _$IntRangeCopyWith<$Res>
    implements $IntRangeCopyWith<$Res> {
  factory _$IntRangeCopyWith(_IntRange value, $Res Function(_IntRange) _then) =
      __$IntRangeCopyWithImpl;
  @override
  @useResult
  $Res call({int? min, int? max});
}

/// @nodoc
class __$IntRangeCopyWithImpl<$Res> implements _$IntRangeCopyWith<$Res> {
  __$IntRangeCopyWithImpl(this._self, this._then);

  final _IntRange _self;
  final $Res Function(_IntRange) _then;

  /// Create a copy of IntRange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_IntRange(
      min: freezed == min
          ? _self.min
          : min // ignore: cast_nullable_to_non_nullable
              as int?,
      max: freezed == max
          ? _self.max
          : max // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
mixin _$FilterValidationResult {
  bool get isValid;
  List<String> get errors;
  List<String> get warnings;

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilterValidationResultCopyWith<FilterValidationResult> get copyWith =>
      _$FilterValidationResultCopyWithImpl<FilterValidationResult>(
          this as FilterValidationResult, _$identity);

  /// Serializes this FilterValidationResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilterValidationResult &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            const DeepCollectionEquality().equals(other.errors, errors) &&
            const DeepCollectionEquality().equals(other.warnings, warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isValid,
      const DeepCollectionEquality().hash(errors),
      const DeepCollectionEquality().hash(warnings));

  @override
  String toString() {
    return 'FilterValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

/// @nodoc
abstract mixin class $FilterValidationResultCopyWith<$Res> {
  factory $FilterValidationResultCopyWith(FilterValidationResult value,
          $Res Function(FilterValidationResult) _then) =
      _$FilterValidationResultCopyWithImpl;
  @useResult
  $Res call({bool isValid, List<String> errors, List<String> warnings});
}

/// @nodoc
class _$FilterValidationResultCopyWithImpl<$Res>
    implements $FilterValidationResultCopyWith<$Res> {
  _$FilterValidationResultCopyWithImpl(this._self, this._then);

  final FilterValidationResult _self;
  final $Res Function(FilterValidationResult) _then;

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? errors = null,
    Object? warnings = null,
  }) {
    return _then(_self.copyWith(
      isValid: null == isValid
          ? _self.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errors: null == errors
          ? _self.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _self.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [FilterValidationResult].
extension FilterValidationResultPatterns on FilterValidationResult {
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
    TResult Function(_FilterValidationResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterValidationResult() when $default != null:
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
    TResult Function(_FilterValidationResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterValidationResult():
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
    TResult? Function(_FilterValidationResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterValidationResult() when $default != null:
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
    TResult Function(bool isValid, List<String> errors, List<String> warnings)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterValidationResult() when $default != null:
        return $default(_that.isValid, _that.errors, _that.warnings);
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
    TResult Function(bool isValid, List<String> errors, List<String> warnings)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterValidationResult():
        return $default(_that.isValid, _that.errors, _that.warnings);
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
    TResult? Function(bool isValid, List<String> errors, List<String> warnings)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterValidationResult() when $default != null:
        return $default(_that.isValid, _that.errors, _that.warnings);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FilterValidationResult implements FilterValidationResult {
  const _FilterValidationResult(
      {required this.isValid,
      required final List<String> errors,
      required final List<String> warnings})
      : _errors = errors,
        _warnings = warnings;
  factory _FilterValidationResult.fromJson(Map<String, dynamic> json) =>
      _$FilterValidationResultFromJson(json);

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

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FilterValidationResultCopyWith<_FilterValidationResult> get copyWith =>
      __$FilterValidationResultCopyWithImpl<_FilterValidationResult>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FilterValidationResultToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FilterValidationResult &&
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

  @override
  String toString() {
    return 'FilterValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

/// @nodoc
abstract mixin class _$FilterValidationResultCopyWith<$Res>
    implements $FilterValidationResultCopyWith<$Res> {
  factory _$FilterValidationResultCopyWith(_FilterValidationResult value,
          $Res Function(_FilterValidationResult) _then) =
      __$FilterValidationResultCopyWithImpl;
  @override
  @useResult
  $Res call({bool isValid, List<String> errors, List<String> warnings});
}

/// @nodoc
class __$FilterValidationResultCopyWithImpl<$Res>
    implements _$FilterValidationResultCopyWith<$Res> {
  __$FilterValidationResultCopyWithImpl(this._self, this._then);

  final _FilterValidationResult _self;
  final $Res Function(_FilterValidationResult) _then;

  /// Create a copy of FilterValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isValid = null,
    Object? errors = null,
    Object? warnings = null,
  }) {
    return _then(_FilterValidationResult(
      isValid: null == isValid
          ? _self.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errors: null == errors
          ? _self._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _self._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
