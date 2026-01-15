// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'config_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchConfig {
  SearchMode get searchMode;
  String get endpoint;
  SortingConfig? get sortingConfig;
  String? get queryParam;
  FilterSupportConfig? get filterSupport;
  List<TextFieldConfig>? get textFields;
  List<RadioGroupConfig>? get radioGroups;
  List<CheckboxGroupConfig>? get checkboxGroups;
  PaginationConfig? get pagination;

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SearchConfigCopyWith<SearchConfig> get copyWith =>
      _$SearchConfigCopyWithImpl<SearchConfig>(
          this as SearchConfig, _$identity);

  /// Serializes this SearchConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SearchConfig &&
            (identical(other.searchMode, searchMode) ||
                other.searchMode == searchMode) &&
            (identical(other.endpoint, endpoint) ||
                other.endpoint == endpoint) &&
            (identical(other.sortingConfig, sortingConfig) ||
                other.sortingConfig == sortingConfig) &&
            (identical(other.queryParam, queryParam) ||
                other.queryParam == queryParam) &&
            (identical(other.filterSupport, filterSupport) ||
                other.filterSupport == filterSupport) &&
            const DeepCollectionEquality()
                .equals(other.textFields, textFields) &&
            const DeepCollectionEquality()
                .equals(other.radioGroups, radioGroups) &&
            const DeepCollectionEquality()
                .equals(other.checkboxGroups, checkboxGroups) &&
            (identical(other.pagination, pagination) ||
                other.pagination == pagination));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      searchMode,
      endpoint,
      sortingConfig,
      queryParam,
      filterSupport,
      const DeepCollectionEquality().hash(textFields),
      const DeepCollectionEquality().hash(radioGroups),
      const DeepCollectionEquality().hash(checkboxGroups),
      pagination);

  @override
  String toString() {
    return 'SearchConfig(searchMode: $searchMode, endpoint: $endpoint, sortingConfig: $sortingConfig, queryParam: $queryParam, filterSupport: $filterSupport, textFields: $textFields, radioGroups: $radioGroups, checkboxGroups: $checkboxGroups, pagination: $pagination)';
  }
}

/// @nodoc
abstract mixin class $SearchConfigCopyWith<$Res> {
  factory $SearchConfigCopyWith(
          SearchConfig value, $Res Function(SearchConfig) _then) =
      _$SearchConfigCopyWithImpl;
  @useResult
  $Res call(
      {SearchMode searchMode,
      String endpoint,
      SortingConfig? sortingConfig,
      String? queryParam,
      FilterSupportConfig? filterSupport,
      List<TextFieldConfig>? textFields,
      List<RadioGroupConfig>? radioGroups,
      List<CheckboxGroupConfig>? checkboxGroups,
      PaginationConfig? pagination});

  $SortingConfigCopyWith<$Res>? get sortingConfig;
  $FilterSupportConfigCopyWith<$Res>? get filterSupport;
  $PaginationConfigCopyWith<$Res>? get pagination;
}

/// @nodoc
class _$SearchConfigCopyWithImpl<$Res> implements $SearchConfigCopyWith<$Res> {
  _$SearchConfigCopyWithImpl(this._self, this._then);

  final SearchConfig _self;
  final $Res Function(SearchConfig) _then;

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchMode = null,
    Object? endpoint = null,
    Object? sortingConfig = freezed,
    Object? queryParam = freezed,
    Object? filterSupport = freezed,
    Object? textFields = freezed,
    Object? radioGroups = freezed,
    Object? checkboxGroups = freezed,
    Object? pagination = freezed,
  }) {
    return _then(_self.copyWith(
      searchMode: null == searchMode
          ? _self.searchMode
          : searchMode // ignore: cast_nullable_to_non_nullable
              as SearchMode,
      endpoint: null == endpoint
          ? _self.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String,
      sortingConfig: freezed == sortingConfig
          ? _self.sortingConfig
          : sortingConfig // ignore: cast_nullable_to_non_nullable
              as SortingConfig?,
      queryParam: freezed == queryParam
          ? _self.queryParam
          : queryParam // ignore: cast_nullable_to_non_nullable
              as String?,
      filterSupport: freezed == filterSupport
          ? _self.filterSupport
          : filterSupport // ignore: cast_nullable_to_non_nullable
              as FilterSupportConfig?,
      textFields: freezed == textFields
          ? _self.textFields
          : textFields // ignore: cast_nullable_to_non_nullable
              as List<TextFieldConfig>?,
      radioGroups: freezed == radioGroups
          ? _self.radioGroups
          : radioGroups // ignore: cast_nullable_to_non_nullable
              as List<RadioGroupConfig>?,
      checkboxGroups: freezed == checkboxGroups
          ? _self.checkboxGroups
          : checkboxGroups // ignore: cast_nullable_to_non_nullable
              as List<CheckboxGroupConfig>?,
      pagination: freezed == pagination
          ? _self.pagination
          : pagination // ignore: cast_nullable_to_non_nullable
              as PaginationConfig?,
    ));
  }

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SortingConfigCopyWith<$Res>? get sortingConfig {
    if (_self.sortingConfig == null) {
      return null;
    }

    return $SortingConfigCopyWith<$Res>(_self.sortingConfig!, (value) {
      return _then(_self.copyWith(sortingConfig: value));
    });
  }

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FilterSupportConfigCopyWith<$Res>? get filterSupport {
    if (_self.filterSupport == null) {
      return null;
    }

    return $FilterSupportConfigCopyWith<$Res>(_self.filterSupport!, (value) {
      return _then(_self.copyWith(filterSupport: value));
    });
  }

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaginationConfigCopyWith<$Res>? get pagination {
    if (_self.pagination == null) {
      return null;
    }

    return $PaginationConfigCopyWith<$Res>(_self.pagination!, (value) {
      return _then(_self.copyWith(pagination: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SearchConfig].
extension SearchConfigPatterns on SearchConfig {
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
    TResult Function(_SearchConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchConfig() when $default != null:
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
    TResult Function(_SearchConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchConfig():
        return $default(_that);
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
    TResult? Function(_SearchConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchConfig() when $default != null:
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
            SearchMode searchMode,
            String endpoint,
            SortingConfig? sortingConfig,
            String? queryParam,
            FilterSupportConfig? filterSupport,
            List<TextFieldConfig>? textFields,
            List<RadioGroupConfig>? radioGroups,
            List<CheckboxGroupConfig>? checkboxGroups,
            PaginationConfig? pagination)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchConfig() when $default != null:
        return $default(
            _that.searchMode,
            _that.endpoint,
            _that.sortingConfig,
            _that.queryParam,
            _that.filterSupport,
            _that.textFields,
            _that.radioGroups,
            _that.checkboxGroups,
            _that.pagination);
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
            SearchMode searchMode,
            String endpoint,
            SortingConfig? sortingConfig,
            String? queryParam,
            FilterSupportConfig? filterSupport,
            List<TextFieldConfig>? textFields,
            List<RadioGroupConfig>? radioGroups,
            List<CheckboxGroupConfig>? checkboxGroups,
            PaginationConfig? pagination)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchConfig():
        return $default(
            _that.searchMode,
            _that.endpoint,
            _that.sortingConfig,
            _that.queryParam,
            _that.filterSupport,
            _that.textFields,
            _that.radioGroups,
            _that.checkboxGroups,
            _that.pagination);
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
            SearchMode searchMode,
            String endpoint,
            SortingConfig? sortingConfig,
            String? queryParam,
            FilterSupportConfig? filterSupport,
            List<TextFieldConfig>? textFields,
            List<RadioGroupConfig>? radioGroups,
            List<CheckboxGroupConfig>? checkboxGroups,
            PaginationConfig? pagination)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchConfig() when $default != null:
        return $default(
            _that.searchMode,
            _that.endpoint,
            _that.sortingConfig,
            _that.queryParam,
            _that.filterSupport,
            _that.textFields,
            _that.radioGroups,
            _that.checkboxGroups,
            _that.pagination);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SearchConfig implements SearchConfig {
  const _SearchConfig(
      {required this.searchMode,
      required this.endpoint,
      this.sortingConfig,
      this.queryParam,
      this.filterSupport,
      final List<TextFieldConfig>? textFields,
      final List<RadioGroupConfig>? radioGroups,
      final List<CheckboxGroupConfig>? checkboxGroups,
      this.pagination})
      : _textFields = textFields,
        _radioGroups = radioGroups,
        _checkboxGroups = checkboxGroups;
  factory _SearchConfig.fromJson(Map<String, dynamic> json) =>
      _$SearchConfigFromJson(json);

  @override
  final SearchMode searchMode;
  @override
  final String endpoint;
  @override
  final SortingConfig? sortingConfig;
  @override
  final String? queryParam;
  @override
  final FilterSupportConfig? filterSupport;
  final List<TextFieldConfig>? _textFields;
  @override
  List<TextFieldConfig>? get textFields {
    final value = _textFields;
    if (value == null) return null;
    if (_textFields is EqualUnmodifiableListView) return _textFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<RadioGroupConfig>? _radioGroups;
  @override
  List<RadioGroupConfig>? get radioGroups {
    final value = _radioGroups;
    if (value == null) return null;
    if (_radioGroups is EqualUnmodifiableListView) return _radioGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<CheckboxGroupConfig>? _checkboxGroups;
  @override
  List<CheckboxGroupConfig>? get checkboxGroups {
    final value = _checkboxGroups;
    if (value == null) return null;
    if (_checkboxGroups is EqualUnmodifiableListView) return _checkboxGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final PaginationConfig? pagination;

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchConfigCopyWith<_SearchConfig> get copyWith =>
      __$SearchConfigCopyWithImpl<_SearchConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SearchConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchConfig &&
            (identical(other.searchMode, searchMode) ||
                other.searchMode == searchMode) &&
            (identical(other.endpoint, endpoint) ||
                other.endpoint == endpoint) &&
            (identical(other.sortingConfig, sortingConfig) ||
                other.sortingConfig == sortingConfig) &&
            (identical(other.queryParam, queryParam) ||
                other.queryParam == queryParam) &&
            (identical(other.filterSupport, filterSupport) ||
                other.filterSupport == filterSupport) &&
            const DeepCollectionEquality()
                .equals(other._textFields, _textFields) &&
            const DeepCollectionEquality()
                .equals(other._radioGroups, _radioGroups) &&
            const DeepCollectionEquality()
                .equals(other._checkboxGroups, _checkboxGroups) &&
            (identical(other.pagination, pagination) ||
                other.pagination == pagination));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      searchMode,
      endpoint,
      sortingConfig,
      queryParam,
      filterSupport,
      const DeepCollectionEquality().hash(_textFields),
      const DeepCollectionEquality().hash(_radioGroups),
      const DeepCollectionEquality().hash(_checkboxGroups),
      pagination);

  @override
  String toString() {
    return 'SearchConfig(searchMode: $searchMode, endpoint: $endpoint, sortingConfig: $sortingConfig, queryParam: $queryParam, filterSupport: $filterSupport, textFields: $textFields, radioGroups: $radioGroups, checkboxGroups: $checkboxGroups, pagination: $pagination)';
  }
}

/// @nodoc
abstract mixin class _$SearchConfigCopyWith<$Res>
    implements $SearchConfigCopyWith<$Res> {
  factory _$SearchConfigCopyWith(
          _SearchConfig value, $Res Function(_SearchConfig) _then) =
      __$SearchConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {SearchMode searchMode,
      String endpoint,
      SortingConfig? sortingConfig,
      String? queryParam,
      FilterSupportConfig? filterSupport,
      List<TextFieldConfig>? textFields,
      List<RadioGroupConfig>? radioGroups,
      List<CheckboxGroupConfig>? checkboxGroups,
      PaginationConfig? pagination});

  @override
  $SortingConfigCopyWith<$Res>? get sortingConfig;
  @override
  $FilterSupportConfigCopyWith<$Res>? get filterSupport;
  @override
  $PaginationConfigCopyWith<$Res>? get pagination;
}

/// @nodoc
class __$SearchConfigCopyWithImpl<$Res>
    implements _$SearchConfigCopyWith<$Res> {
  __$SearchConfigCopyWithImpl(this._self, this._then);

  final _SearchConfig _self;
  final $Res Function(_SearchConfig) _then;

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? searchMode = null,
    Object? endpoint = null,
    Object? sortingConfig = freezed,
    Object? queryParam = freezed,
    Object? filterSupport = freezed,
    Object? textFields = freezed,
    Object? radioGroups = freezed,
    Object? checkboxGroups = freezed,
    Object? pagination = freezed,
  }) {
    return _then(_SearchConfig(
      searchMode: null == searchMode
          ? _self.searchMode
          : searchMode // ignore: cast_nullable_to_non_nullable
              as SearchMode,
      endpoint: null == endpoint
          ? _self.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String,
      sortingConfig: freezed == sortingConfig
          ? _self.sortingConfig
          : sortingConfig // ignore: cast_nullable_to_non_nullable
              as SortingConfig?,
      queryParam: freezed == queryParam
          ? _self.queryParam
          : queryParam // ignore: cast_nullable_to_non_nullable
              as String?,
      filterSupport: freezed == filterSupport
          ? _self.filterSupport
          : filterSupport // ignore: cast_nullable_to_non_nullable
              as FilterSupportConfig?,
      textFields: freezed == textFields
          ? _self._textFields
          : textFields // ignore: cast_nullable_to_non_nullable
              as List<TextFieldConfig>?,
      radioGroups: freezed == radioGroups
          ? _self._radioGroups
          : radioGroups // ignore: cast_nullable_to_non_nullable
              as List<RadioGroupConfig>?,
      checkboxGroups: freezed == checkboxGroups
          ? _self._checkboxGroups
          : checkboxGroups // ignore: cast_nullable_to_non_nullable
              as List<CheckboxGroupConfig>?,
      pagination: freezed == pagination
          ? _self.pagination
          : pagination // ignore: cast_nullable_to_non_nullable
              as PaginationConfig?,
    ));
  }

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SortingConfigCopyWith<$Res>? get sortingConfig {
    if (_self.sortingConfig == null) {
      return null;
    }

    return $SortingConfigCopyWith<$Res>(_self.sortingConfig!, (value) {
      return _then(_self.copyWith(sortingConfig: value));
    });
  }

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FilterSupportConfigCopyWith<$Res>? get filterSupport {
    if (_self.filterSupport == null) {
      return null;
    }

    return $FilterSupportConfigCopyWith<$Res>(_self.filterSupport!, (value) {
      return _then(_self.copyWith(filterSupport: value));
    });
  }

  /// Create a copy of SearchConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaginationConfigCopyWith<$Res>? get pagination {
    if (_self.pagination == null) {
      return null;
    }

    return $PaginationConfigCopyWith<$Res>(_self.pagination!, (value) {
      return _then(_self.copyWith(pagination: value));
    });
  }
}

/// @nodoc
mixin _$FilterSupportConfig {
  List<String> get singleSelect;
  List<String> get multiSelect;
  bool get supportsExclude;

  /// Create a copy of FilterSupportConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FilterSupportConfigCopyWith<FilterSupportConfig> get copyWith =>
      _$FilterSupportConfigCopyWithImpl<FilterSupportConfig>(
          this as FilterSupportConfig, _$identity);

  /// Serializes this FilterSupportConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FilterSupportConfig &&
            const DeepCollectionEquality()
                .equals(other.singleSelect, singleSelect) &&
            const DeepCollectionEquality()
                .equals(other.multiSelect, multiSelect) &&
            (identical(other.supportsExclude, supportsExclude) ||
                other.supportsExclude == supportsExclude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(singleSelect),
      const DeepCollectionEquality().hash(multiSelect),
      supportsExclude);

  @override
  String toString() {
    return 'FilterSupportConfig(singleSelect: $singleSelect, multiSelect: $multiSelect, supportsExclude: $supportsExclude)';
  }
}

/// @nodoc
abstract mixin class $FilterSupportConfigCopyWith<$Res> {
  factory $FilterSupportConfigCopyWith(
          FilterSupportConfig value, $Res Function(FilterSupportConfig) _then) =
      _$FilterSupportConfigCopyWithImpl;
  @useResult
  $Res call(
      {List<String> singleSelect,
      List<String> multiSelect,
      bool supportsExclude});
}

/// @nodoc
class _$FilterSupportConfigCopyWithImpl<$Res>
    implements $FilterSupportConfigCopyWith<$Res> {
  _$FilterSupportConfigCopyWithImpl(this._self, this._then);

  final FilterSupportConfig _self;
  final $Res Function(FilterSupportConfig) _then;

  /// Create a copy of FilterSupportConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? singleSelect = null,
    Object? multiSelect = null,
    Object? supportsExclude = null,
  }) {
    return _then(_self.copyWith(
      singleSelect: null == singleSelect
          ? _self.singleSelect
          : singleSelect // ignore: cast_nullable_to_non_nullable
              as List<String>,
      multiSelect: null == multiSelect
          ? _self.multiSelect
          : multiSelect // ignore: cast_nullable_to_non_nullable
              as List<String>,
      supportsExclude: null == supportsExclude
          ? _self.supportsExclude
          : supportsExclude // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [FilterSupportConfig].
extension FilterSupportConfigPatterns on FilterSupportConfig {
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
    TResult Function(_FilterSupportConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterSupportConfig() when $default != null:
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
    TResult Function(_FilterSupportConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSupportConfig():
        return $default(_that);
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
    TResult? Function(_FilterSupportConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSupportConfig() when $default != null:
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
    TResult Function(List<String> singleSelect, List<String> multiSelect,
            bool supportsExclude)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FilterSupportConfig() when $default != null:
        return $default(
            _that.singleSelect, _that.multiSelect, _that.supportsExclude);
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
    TResult Function(List<String> singleSelect, List<String> multiSelect,
            bool supportsExclude)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSupportConfig():
        return $default(
            _that.singleSelect, _that.multiSelect, _that.supportsExclude);
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
    TResult? Function(List<String> singleSelect, List<String> multiSelect,
            bool supportsExclude)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FilterSupportConfig() when $default != null:
        return $default(
            _that.singleSelect, _that.multiSelect, _that.supportsExclude);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FilterSupportConfig implements FilterSupportConfig {
  const _FilterSupportConfig(
      {required final List<String> singleSelect,
      required final List<String> multiSelect,
      required this.supportsExclude})
      : _singleSelect = singleSelect,
        _multiSelect = multiSelect;
  factory _FilterSupportConfig.fromJson(Map<String, dynamic> json) =>
      _$FilterSupportConfigFromJson(json);

  final List<String> _singleSelect;
  @override
  List<String> get singleSelect {
    if (_singleSelect is EqualUnmodifiableListView) return _singleSelect;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_singleSelect);
  }

  final List<String> _multiSelect;
  @override
  List<String> get multiSelect {
    if (_multiSelect is EqualUnmodifiableListView) return _multiSelect;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_multiSelect);
  }

  @override
  final bool supportsExclude;

  /// Create a copy of FilterSupportConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FilterSupportConfigCopyWith<_FilterSupportConfig> get copyWith =>
      __$FilterSupportConfigCopyWithImpl<_FilterSupportConfig>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FilterSupportConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FilterSupportConfig &&
            const DeepCollectionEquality()
                .equals(other._singleSelect, _singleSelect) &&
            const DeepCollectionEquality()
                .equals(other._multiSelect, _multiSelect) &&
            (identical(other.supportsExclude, supportsExclude) ||
                other.supportsExclude == supportsExclude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_singleSelect),
      const DeepCollectionEquality().hash(_multiSelect),
      supportsExclude);

  @override
  String toString() {
    return 'FilterSupportConfig(singleSelect: $singleSelect, multiSelect: $multiSelect, supportsExclude: $supportsExclude)';
  }
}

/// @nodoc
abstract mixin class _$FilterSupportConfigCopyWith<$Res>
    implements $FilterSupportConfigCopyWith<$Res> {
  factory _$FilterSupportConfigCopyWith(_FilterSupportConfig value,
          $Res Function(_FilterSupportConfig) _then) =
      __$FilterSupportConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<String> singleSelect,
      List<String> multiSelect,
      bool supportsExclude});
}

/// @nodoc
class __$FilterSupportConfigCopyWithImpl<$Res>
    implements _$FilterSupportConfigCopyWith<$Res> {
  __$FilterSupportConfigCopyWithImpl(this._self, this._then);

  final _FilterSupportConfig _self;
  final $Res Function(_FilterSupportConfig) _then;

  /// Create a copy of FilterSupportConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? singleSelect = null,
    Object? multiSelect = null,
    Object? supportsExclude = null,
  }) {
    return _then(_FilterSupportConfig(
      singleSelect: null == singleSelect
          ? _self._singleSelect
          : singleSelect // ignore: cast_nullable_to_non_nullable
              as List<String>,
      multiSelect: null == multiSelect
          ? _self._multiSelect
          : multiSelect // ignore: cast_nullable_to_non_nullable
              as List<String>,
      supportsExclude: null == supportsExclude
          ? _self.supportsExclude
          : supportsExclude // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$TextFieldConfig {
  String get name;
  String get label;
  String get type;
  String? get placeholder;
  int? get maxLength;
  int? get min;
  int? get max;

  /// Create a copy of TextFieldConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TextFieldConfigCopyWith<TextFieldConfig> get copyWith =>
      _$TextFieldConfigCopyWithImpl<TextFieldConfig>(
          this as TextFieldConfig, _$identity);

  /// Serializes this TextFieldConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TextFieldConfig &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.placeholder, placeholder) ||
                other.placeholder == placeholder) &&
            (identical(other.maxLength, maxLength) ||
                other.maxLength == maxLength) &&
            (identical(other.min, min) || other.min == min) &&
            (identical(other.max, max) || other.max == max));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, label, type, placeholder, maxLength, min, max);

  @override
  String toString() {
    return 'TextFieldConfig(name: $name, label: $label, type: $type, placeholder: $placeholder, maxLength: $maxLength, min: $min, max: $max)';
  }
}

/// @nodoc
abstract mixin class $TextFieldConfigCopyWith<$Res> {
  factory $TextFieldConfigCopyWith(
          TextFieldConfig value, $Res Function(TextFieldConfig) _then) =
      _$TextFieldConfigCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String label,
      String type,
      String? placeholder,
      int? maxLength,
      int? min,
      int? max});
}

/// @nodoc
class _$TextFieldConfigCopyWithImpl<$Res>
    implements $TextFieldConfigCopyWith<$Res> {
  _$TextFieldConfigCopyWithImpl(this._self, this._then);

  final TextFieldConfig _self;
  final $Res Function(TextFieldConfig) _then;

  /// Create a copy of TextFieldConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? label = null,
    Object? type = null,
    Object? placeholder = freezed,
    Object? maxLength = freezed,
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      placeholder: freezed == placeholder
          ? _self.placeholder
          : placeholder // ignore: cast_nullable_to_non_nullable
              as String?,
      maxLength: freezed == maxLength
          ? _self.maxLength
          : maxLength // ignore: cast_nullable_to_non_nullable
              as int?,
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

/// Adds pattern-matching-related methods to [TextFieldConfig].
extension TextFieldConfigPatterns on TextFieldConfig {
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
    TResult Function(_TextFieldConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TextFieldConfig() when $default != null:
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
    TResult Function(_TextFieldConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextFieldConfig():
        return $default(_that);
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
    TResult? Function(_TextFieldConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextFieldConfig() when $default != null:
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
    TResult Function(String name, String label, String type,
            String? placeholder, int? maxLength, int? min, int? max)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TextFieldConfig() when $default != null:
        return $default(_that.name, _that.label, _that.type, _that.placeholder,
            _that.maxLength, _that.min, _that.max);
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
    TResult Function(String name, String label, String type,
            String? placeholder, int? maxLength, int? min, int? max)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextFieldConfig():
        return $default(_that.name, _that.label, _that.type, _that.placeholder,
            _that.maxLength, _that.min, _that.max);
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
    TResult? Function(String name, String label, String type,
            String? placeholder, int? maxLength, int? min, int? max)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextFieldConfig() when $default != null:
        return $default(_that.name, _that.label, _that.type, _that.placeholder,
            _that.maxLength, _that.min, _that.max);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TextFieldConfig implements TextFieldConfig {
  const _TextFieldConfig(
      {required this.name,
      required this.label,
      required this.type,
      this.placeholder,
      this.maxLength,
      this.min,
      this.max});
  factory _TextFieldConfig.fromJson(Map<String, dynamic> json) =>
      _$TextFieldConfigFromJson(json);

  @override
  final String name;
  @override
  final String label;
  @override
  final String type;
  @override
  final String? placeholder;
  @override
  final int? maxLength;
  @override
  final int? min;
  @override
  final int? max;

  /// Create a copy of TextFieldConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TextFieldConfigCopyWith<_TextFieldConfig> get copyWith =>
      __$TextFieldConfigCopyWithImpl<_TextFieldConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TextFieldConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TextFieldConfig &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.placeholder, placeholder) ||
                other.placeholder == placeholder) &&
            (identical(other.maxLength, maxLength) ||
                other.maxLength == maxLength) &&
            (identical(other.min, min) || other.min == min) &&
            (identical(other.max, max) || other.max == max));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, label, type, placeholder, maxLength, min, max);

  @override
  String toString() {
    return 'TextFieldConfig(name: $name, label: $label, type: $type, placeholder: $placeholder, maxLength: $maxLength, min: $min, max: $max)';
  }
}

/// @nodoc
abstract mixin class _$TextFieldConfigCopyWith<$Res>
    implements $TextFieldConfigCopyWith<$Res> {
  factory _$TextFieldConfigCopyWith(
          _TextFieldConfig value, $Res Function(_TextFieldConfig) _then) =
      __$TextFieldConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String label,
      String type,
      String? placeholder,
      int? maxLength,
      int? min,
      int? max});
}

/// @nodoc
class __$TextFieldConfigCopyWithImpl<$Res>
    implements _$TextFieldConfigCopyWith<$Res> {
  __$TextFieldConfigCopyWithImpl(this._self, this._then);

  final _TextFieldConfig _self;
  final $Res Function(_TextFieldConfig) _then;

  /// Create a copy of TextFieldConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? label = null,
    Object? type = null,
    Object? placeholder = freezed,
    Object? maxLength = freezed,
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_TextFieldConfig(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      placeholder: freezed == placeholder
          ? _self.placeholder
          : placeholder // ignore: cast_nullable_to_non_nullable
              as String?,
      maxLength: freezed == maxLength
          ? _self.maxLength
          : maxLength // ignore: cast_nullable_to_non_nullable
              as int?,
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
mixin _$RadioGroupConfig {
  String get name;
  String get label;
  List<RadioOptionConfig> get options;

  /// Create a copy of RadioGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RadioGroupConfigCopyWith<RadioGroupConfig> get copyWith =>
      _$RadioGroupConfigCopyWithImpl<RadioGroupConfig>(
          this as RadioGroupConfig, _$identity);

  /// Serializes this RadioGroupConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RadioGroupConfig &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.label, label) || other.label == label) &&
            const DeepCollectionEquality().equals(other.options, options));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, label, const DeepCollectionEquality().hash(options));

  @override
  String toString() {
    return 'RadioGroupConfig(name: $name, label: $label, options: $options)';
  }
}

/// @nodoc
abstract mixin class $RadioGroupConfigCopyWith<$Res> {
  factory $RadioGroupConfigCopyWith(
          RadioGroupConfig value, $Res Function(RadioGroupConfig) _then) =
      _$RadioGroupConfigCopyWithImpl;
  @useResult
  $Res call({String name, String label, List<RadioOptionConfig> options});
}

/// @nodoc
class _$RadioGroupConfigCopyWithImpl<$Res>
    implements $RadioGroupConfigCopyWith<$Res> {
  _$RadioGroupConfigCopyWithImpl(this._self, this._then);

  final RadioGroupConfig _self;
  final $Res Function(RadioGroupConfig) _then;

  /// Create a copy of RadioGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? label = null,
    Object? options = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _self.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<RadioOptionConfig>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RadioGroupConfig].
extension RadioGroupConfigPatterns on RadioGroupConfig {
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
    TResult Function(_RadioGroupConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RadioGroupConfig() when $default != null:
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
    TResult Function(_RadioGroupConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioGroupConfig():
        return $default(_that);
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
    TResult? Function(_RadioGroupConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioGroupConfig() when $default != null:
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
            String name, String label, List<RadioOptionConfig> options)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RadioGroupConfig() when $default != null:
        return $default(_that.name, _that.label, _that.options);
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
    TResult Function(String name, String label, List<RadioOptionConfig> options)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioGroupConfig():
        return $default(_that.name, _that.label, _that.options);
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
            String name, String label, List<RadioOptionConfig> options)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioGroupConfig() when $default != null:
        return $default(_that.name, _that.label, _that.options);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RadioGroupConfig implements RadioGroupConfig {
  const _RadioGroupConfig(
      {required this.name,
      required this.label,
      required final List<RadioOptionConfig> options})
      : _options = options;
  factory _RadioGroupConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioGroupConfigFromJson(json);

  @override
  final String name;
  @override
  final String label;
  final List<RadioOptionConfig> _options;
  @override
  List<RadioOptionConfig> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  /// Create a copy of RadioGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RadioGroupConfigCopyWith<_RadioGroupConfig> get copyWith =>
      __$RadioGroupConfigCopyWithImpl<_RadioGroupConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RadioGroupConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RadioGroupConfig &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.label, label) || other.label == label) &&
            const DeepCollectionEquality().equals(other._options, _options));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, label, const DeepCollectionEquality().hash(_options));

  @override
  String toString() {
    return 'RadioGroupConfig(name: $name, label: $label, options: $options)';
  }
}

/// @nodoc
abstract mixin class _$RadioGroupConfigCopyWith<$Res>
    implements $RadioGroupConfigCopyWith<$Res> {
  factory _$RadioGroupConfigCopyWith(
          _RadioGroupConfig value, $Res Function(_RadioGroupConfig) _then) =
      __$RadioGroupConfigCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String label, List<RadioOptionConfig> options});
}

/// @nodoc
class __$RadioGroupConfigCopyWithImpl<$Res>
    implements _$RadioGroupConfigCopyWith<$Res> {
  __$RadioGroupConfigCopyWithImpl(this._self, this._then);

  final _RadioGroupConfig _self;
  final $Res Function(_RadioGroupConfig) _then;

  /// Create a copy of RadioGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? label = null,
    Object? options = null,
  }) {
    return _then(_RadioGroupConfig(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _self._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<RadioOptionConfig>,
    ));
  }
}

/// @nodoc
mixin _$RadioOptionConfig {
  String get value;
  String get label;
  bool get isDefault;

  /// Create a copy of RadioOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RadioOptionConfigCopyWith<RadioOptionConfig> get copyWith =>
      _$RadioOptionConfigCopyWithImpl<RadioOptionConfig>(
          this as RadioOptionConfig, _$identity);

  /// Serializes this RadioOptionConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RadioOptionConfig &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value, label, isDefault);

  @override
  String toString() {
    return 'RadioOptionConfig(value: $value, label: $label, isDefault: $isDefault)';
  }
}

/// @nodoc
abstract mixin class $RadioOptionConfigCopyWith<$Res> {
  factory $RadioOptionConfigCopyWith(
          RadioOptionConfig value, $Res Function(RadioOptionConfig) _then) =
      _$RadioOptionConfigCopyWithImpl;
  @useResult
  $Res call({String value, String label, bool isDefault});
}

/// @nodoc
class _$RadioOptionConfigCopyWithImpl<$Res>
    implements $RadioOptionConfigCopyWith<$Res> {
  _$RadioOptionConfigCopyWithImpl(this._self, this._then);

  final RadioOptionConfig _self;
  final $Res Function(RadioOptionConfig) _then;

  /// Create a copy of RadioOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? isDefault = null,
  }) {
    return _then(_self.copyWith(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _self.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [RadioOptionConfig].
extension RadioOptionConfigPatterns on RadioOptionConfig {
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
    TResult Function(_RadioOptionConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RadioOptionConfig() when $default != null:
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
    TResult Function(_RadioOptionConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioOptionConfig():
        return $default(_that);
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
    TResult? Function(_RadioOptionConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioOptionConfig() when $default != null:
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
    TResult Function(String value, String label, bool isDefault)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RadioOptionConfig() when $default != null:
        return $default(_that.value, _that.label, _that.isDefault);
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
    TResult Function(String value, String label, bool isDefault) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioOptionConfig():
        return $default(_that.value, _that.label, _that.isDefault);
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
    TResult? Function(String value, String label, bool isDefault)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RadioOptionConfig() when $default != null:
        return $default(_that.value, _that.label, _that.isDefault);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RadioOptionConfig implements RadioOptionConfig {
  const _RadioOptionConfig(
      {required this.value, required this.label, this.isDefault = false});
  factory _RadioOptionConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioOptionConfigFromJson(json);

  @override
  final String value;
  @override
  final String label;
  @override
  @JsonKey()
  final bool isDefault;

  /// Create a copy of RadioOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RadioOptionConfigCopyWith<_RadioOptionConfig> get copyWith =>
      __$RadioOptionConfigCopyWithImpl<_RadioOptionConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RadioOptionConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RadioOptionConfig &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value, label, isDefault);

  @override
  String toString() {
    return 'RadioOptionConfig(value: $value, label: $label, isDefault: $isDefault)';
  }
}

/// @nodoc
abstract mixin class _$RadioOptionConfigCopyWith<$Res>
    implements $RadioOptionConfigCopyWith<$Res> {
  factory _$RadioOptionConfigCopyWith(
          _RadioOptionConfig value, $Res Function(_RadioOptionConfig) _then) =
      __$RadioOptionConfigCopyWithImpl;
  @override
  @useResult
  $Res call({String value, String label, bool isDefault});
}

/// @nodoc
class __$RadioOptionConfigCopyWithImpl<$Res>
    implements _$RadioOptionConfigCopyWith<$Res> {
  __$RadioOptionConfigCopyWithImpl(this._self, this._then);

  final _RadioOptionConfig _self;
  final $Res Function(_RadioOptionConfig) _then;

  /// Create a copy of RadioOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? isDefault = null,
  }) {
    return _then(_RadioOptionConfig(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      isDefault: null == isDefault
          ? _self.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$CheckboxGroupConfig {
  String get name;
  String get label;
  String get paramName;
  String get displayMode;
  int get columns;
  bool get loadFromTags;
  String? get tagType;

  /// Create a copy of CheckboxGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CheckboxGroupConfigCopyWith<CheckboxGroupConfig> get copyWith =>
      _$CheckboxGroupConfigCopyWithImpl<CheckboxGroupConfig>(
          this as CheckboxGroupConfig, _$identity);

  /// Serializes this CheckboxGroupConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CheckboxGroupConfig &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.paramName, paramName) ||
                other.paramName == paramName) &&
            (identical(other.displayMode, displayMode) ||
                other.displayMode == displayMode) &&
            (identical(other.columns, columns) || other.columns == columns) &&
            (identical(other.loadFromTags, loadFromTags) ||
                other.loadFromTags == loadFromTags) &&
            (identical(other.tagType, tagType) || other.tagType == tagType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, label, paramName,
      displayMode, columns, loadFromTags, tagType);

  @override
  String toString() {
    return 'CheckboxGroupConfig(name: $name, label: $label, paramName: $paramName, displayMode: $displayMode, columns: $columns, loadFromTags: $loadFromTags, tagType: $tagType)';
  }
}

/// @nodoc
abstract mixin class $CheckboxGroupConfigCopyWith<$Res> {
  factory $CheckboxGroupConfigCopyWith(
          CheckboxGroupConfig value, $Res Function(CheckboxGroupConfig) _then) =
      _$CheckboxGroupConfigCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String label,
      String paramName,
      String displayMode,
      int columns,
      bool loadFromTags,
      String? tagType});
}

/// @nodoc
class _$CheckboxGroupConfigCopyWithImpl<$Res>
    implements $CheckboxGroupConfigCopyWith<$Res> {
  _$CheckboxGroupConfigCopyWithImpl(this._self, this._then);

  final CheckboxGroupConfig _self;
  final $Res Function(CheckboxGroupConfig) _then;

  /// Create a copy of CheckboxGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? label = null,
    Object? paramName = null,
    Object? displayMode = null,
    Object? columns = null,
    Object? loadFromTags = null,
    Object? tagType = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      paramName: null == paramName
          ? _self.paramName
          : paramName // ignore: cast_nullable_to_non_nullable
              as String,
      displayMode: null == displayMode
          ? _self.displayMode
          : displayMode // ignore: cast_nullable_to_non_nullable
              as String,
      columns: null == columns
          ? _self.columns
          : columns // ignore: cast_nullable_to_non_nullable
              as int,
      loadFromTags: null == loadFromTags
          ? _self.loadFromTags
          : loadFromTags // ignore: cast_nullable_to_non_nullable
              as bool,
      tagType: freezed == tagType
          ? _self.tagType
          : tagType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [CheckboxGroupConfig].
extension CheckboxGroupConfigPatterns on CheckboxGroupConfig {
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
    TResult Function(_CheckboxGroupConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CheckboxGroupConfig() when $default != null:
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
    TResult Function(_CheckboxGroupConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CheckboxGroupConfig():
        return $default(_that);
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
    TResult? Function(_CheckboxGroupConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CheckboxGroupConfig() when $default != null:
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
            String name,
            String label,
            String paramName,
            String displayMode,
            int columns,
            bool loadFromTags,
            String? tagType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CheckboxGroupConfig() when $default != null:
        return $default(
            _that.name,
            _that.label,
            _that.paramName,
            _that.displayMode,
            _that.columns,
            _that.loadFromTags,
            _that.tagType);
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
    TResult Function(String name, String label, String paramName,
            String displayMode, int columns, bool loadFromTags, String? tagType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CheckboxGroupConfig():
        return $default(
            _that.name,
            _that.label,
            _that.paramName,
            _that.displayMode,
            _that.columns,
            _that.loadFromTags,
            _that.tagType);
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
            String name,
            String label,
            String paramName,
            String displayMode,
            int columns,
            bool loadFromTags,
            String? tagType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CheckboxGroupConfig() when $default != null:
        return $default(
            _that.name,
            _that.label,
            _that.paramName,
            _that.displayMode,
            _that.columns,
            _that.loadFromTags,
            _that.tagType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CheckboxGroupConfig implements CheckboxGroupConfig {
  const _CheckboxGroupConfig(
      {required this.name,
      required this.label,
      required this.paramName,
      this.displayMode = 'expandable',
      this.columns = 3,
      this.loadFromTags = false,
      this.tagType});
  factory _CheckboxGroupConfig.fromJson(Map<String, dynamic> json) =>
      _$CheckboxGroupConfigFromJson(json);

  @override
  final String name;
  @override
  final String label;
  @override
  final String paramName;
  @override
  @JsonKey()
  final String displayMode;
  @override
  @JsonKey()
  final int columns;
  @override
  @JsonKey()
  final bool loadFromTags;
  @override
  final String? tagType;

  /// Create a copy of CheckboxGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CheckboxGroupConfigCopyWith<_CheckboxGroupConfig> get copyWith =>
      __$CheckboxGroupConfigCopyWithImpl<_CheckboxGroupConfig>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CheckboxGroupConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CheckboxGroupConfig &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.paramName, paramName) ||
                other.paramName == paramName) &&
            (identical(other.displayMode, displayMode) ||
                other.displayMode == displayMode) &&
            (identical(other.columns, columns) || other.columns == columns) &&
            (identical(other.loadFromTags, loadFromTags) ||
                other.loadFromTags == loadFromTags) &&
            (identical(other.tagType, tagType) || other.tagType == tagType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, label, paramName,
      displayMode, columns, loadFromTags, tagType);

  @override
  String toString() {
    return 'CheckboxGroupConfig(name: $name, label: $label, paramName: $paramName, displayMode: $displayMode, columns: $columns, loadFromTags: $loadFromTags, tagType: $tagType)';
  }
}

/// @nodoc
abstract mixin class _$CheckboxGroupConfigCopyWith<$Res>
    implements $CheckboxGroupConfigCopyWith<$Res> {
  factory _$CheckboxGroupConfigCopyWith(_CheckboxGroupConfig value,
          $Res Function(_CheckboxGroupConfig) _then) =
      __$CheckboxGroupConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String label,
      String paramName,
      String displayMode,
      int columns,
      bool loadFromTags,
      String? tagType});
}

/// @nodoc
class __$CheckboxGroupConfigCopyWithImpl<$Res>
    implements _$CheckboxGroupConfigCopyWith<$Res> {
  __$CheckboxGroupConfigCopyWithImpl(this._self, this._then);

  final _CheckboxGroupConfig _self;
  final $Res Function(_CheckboxGroupConfig) _then;

  /// Create a copy of CheckboxGroupConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? label = null,
    Object? paramName = null,
    Object? displayMode = null,
    Object? columns = null,
    Object? loadFromTags = null,
    Object? tagType = freezed,
  }) {
    return _then(_CheckboxGroupConfig(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      paramName: null == paramName
          ? _self.paramName
          : paramName // ignore: cast_nullable_to_non_nullable
              as String,
      displayMode: null == displayMode
          ? _self.displayMode
          : displayMode // ignore: cast_nullable_to_non_nullable
              as String,
      columns: null == columns
          ? _self.columns
          : columns // ignore: cast_nullable_to_non_nullable
              as int,
      loadFromTags: null == loadFromTags
          ? _self.loadFromTags
          : loadFromTags // ignore: cast_nullable_to_non_nullable
              as bool,
      tagType: freezed == tagType
          ? _self.tagType
          : tagType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$SortingConfig {
  bool get allowDynamicReSort;
  String get defaultSort;
  SortWidgetType get widgetType;
  List<SortOptionConfig> get options;
  SortingMessages get messages;

  /// Create a copy of SortingConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SortingConfigCopyWith<SortingConfig> get copyWith =>
      _$SortingConfigCopyWithImpl<SortingConfig>(
          this as SortingConfig, _$identity);

  /// Serializes this SortingConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SortingConfig &&
            (identical(other.allowDynamicReSort, allowDynamicReSort) ||
                other.allowDynamicReSort == allowDynamicReSort) &&
            (identical(other.defaultSort, defaultSort) ||
                other.defaultSort == defaultSort) &&
            (identical(other.widgetType, widgetType) ||
                other.widgetType == widgetType) &&
            const DeepCollectionEquality().equals(other.options, options) &&
            (identical(other.messages, messages) ||
                other.messages == messages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, allowDynamicReSort, defaultSort,
      widgetType, const DeepCollectionEquality().hash(options), messages);

  @override
  String toString() {
    return 'SortingConfig(allowDynamicReSort: $allowDynamicReSort, defaultSort: $defaultSort, widgetType: $widgetType, options: $options, messages: $messages)';
  }
}

/// @nodoc
abstract mixin class $SortingConfigCopyWith<$Res> {
  factory $SortingConfigCopyWith(
          SortingConfig value, $Res Function(SortingConfig) _then) =
      _$SortingConfigCopyWithImpl;
  @useResult
  $Res call(
      {bool allowDynamicReSort,
      String defaultSort,
      SortWidgetType widgetType,
      List<SortOptionConfig> options,
      SortingMessages messages});

  $SortingMessagesCopyWith<$Res> get messages;
}

/// @nodoc
class _$SortingConfigCopyWithImpl<$Res>
    implements $SortingConfigCopyWith<$Res> {
  _$SortingConfigCopyWithImpl(this._self, this._then);

  final SortingConfig _self;
  final $Res Function(SortingConfig) _then;

  /// Create a copy of SortingConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allowDynamicReSort = null,
    Object? defaultSort = null,
    Object? widgetType = null,
    Object? options = null,
    Object? messages = null,
  }) {
    return _then(_self.copyWith(
      allowDynamicReSort: null == allowDynamicReSort
          ? _self.allowDynamicReSort
          : allowDynamicReSort // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultSort: null == defaultSort
          ? _self.defaultSort
          : defaultSort // ignore: cast_nullable_to_non_nullable
              as String,
      widgetType: null == widgetType
          ? _self.widgetType
          : widgetType // ignore: cast_nullable_to_non_nullable
              as SortWidgetType,
      options: null == options
          ? _self.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<SortOptionConfig>,
      messages: null == messages
          ? _self.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as SortingMessages,
    ));
  }

  /// Create a copy of SortingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SortingMessagesCopyWith<$Res> get messages {
    return $SortingMessagesCopyWith<$Res>(_self.messages, (value) {
      return _then(_self.copyWith(messages: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SortingConfig].
extension SortingConfigPatterns on SortingConfig {
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
    TResult Function(_SortingConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SortingConfig() when $default != null:
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
    TResult Function(_SortingConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingConfig():
        return $default(_that);
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
    TResult? Function(_SortingConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingConfig() when $default != null:
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
            bool allowDynamicReSort,
            String defaultSort,
            SortWidgetType widgetType,
            List<SortOptionConfig> options,
            SortingMessages messages)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SortingConfig() when $default != null:
        return $default(_that.allowDynamicReSort, _that.defaultSort,
            _that.widgetType, _that.options, _that.messages);
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
            bool allowDynamicReSort,
            String defaultSort,
            SortWidgetType widgetType,
            List<SortOptionConfig> options,
            SortingMessages messages)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingConfig():
        return $default(_that.allowDynamicReSort, _that.defaultSort,
            _that.widgetType, _that.options, _that.messages);
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
            bool allowDynamicReSort,
            String defaultSort,
            SortWidgetType widgetType,
            List<SortOptionConfig> options,
            SortingMessages messages)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingConfig() when $default != null:
        return $default(_that.allowDynamicReSort, _that.defaultSort,
            _that.widgetType, _that.options, _that.messages);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SortingConfig implements SortingConfig {
  const _SortingConfig(
      {required this.allowDynamicReSort,
      required this.defaultSort,
      required this.widgetType,
      required final List<SortOptionConfig> options,
      required this.messages})
      : _options = options;
  factory _SortingConfig.fromJson(Map<String, dynamic> json) =>
      _$SortingConfigFromJson(json);

  @override
  final bool allowDynamicReSort;
  @override
  final String defaultSort;
  @override
  final SortWidgetType widgetType;
  final List<SortOptionConfig> _options;
  @override
  List<SortOptionConfig> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  final SortingMessages messages;

  /// Create a copy of SortingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SortingConfigCopyWith<_SortingConfig> get copyWith =>
      __$SortingConfigCopyWithImpl<_SortingConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SortingConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SortingConfig &&
            (identical(other.allowDynamicReSort, allowDynamicReSort) ||
                other.allowDynamicReSort == allowDynamicReSort) &&
            (identical(other.defaultSort, defaultSort) ||
                other.defaultSort == defaultSort) &&
            (identical(other.widgetType, widgetType) ||
                other.widgetType == widgetType) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.messages, messages) ||
                other.messages == messages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, allowDynamicReSort, defaultSort,
      widgetType, const DeepCollectionEquality().hash(_options), messages);

  @override
  String toString() {
    return 'SortingConfig(allowDynamicReSort: $allowDynamicReSort, defaultSort: $defaultSort, widgetType: $widgetType, options: $options, messages: $messages)';
  }
}

/// @nodoc
abstract mixin class _$SortingConfigCopyWith<$Res>
    implements $SortingConfigCopyWith<$Res> {
  factory _$SortingConfigCopyWith(
          _SortingConfig value, $Res Function(_SortingConfig) _then) =
      __$SortingConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool allowDynamicReSort,
      String defaultSort,
      SortWidgetType widgetType,
      List<SortOptionConfig> options,
      SortingMessages messages});

  @override
  $SortingMessagesCopyWith<$Res> get messages;
}

/// @nodoc
class __$SortingConfigCopyWithImpl<$Res>
    implements _$SortingConfigCopyWith<$Res> {
  __$SortingConfigCopyWithImpl(this._self, this._then);

  final _SortingConfig _self;
  final $Res Function(_SortingConfig) _then;

  /// Create a copy of SortingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? allowDynamicReSort = null,
    Object? defaultSort = null,
    Object? widgetType = null,
    Object? options = null,
    Object? messages = null,
  }) {
    return _then(_SortingConfig(
      allowDynamicReSort: null == allowDynamicReSort
          ? _self.allowDynamicReSort
          : allowDynamicReSort // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultSort: null == defaultSort
          ? _self.defaultSort
          : defaultSort // ignore: cast_nullable_to_non_nullable
              as String,
      widgetType: null == widgetType
          ? _self.widgetType
          : widgetType // ignore: cast_nullable_to_non_nullable
              as SortWidgetType,
      options: null == options
          ? _self._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<SortOptionConfig>,
      messages: null == messages
          ? _self.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as SortingMessages,
    ));
  }

  /// Create a copy of SortingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SortingMessagesCopyWith<$Res> get messages {
    return $SortingMessagesCopyWith<$Res>(_self.messages, (value) {
      return _then(_self.copyWith(messages: value));
    });
  }
}

/// @nodoc
mixin _$SortOptionConfig {
  String get value;
  String get apiValue;
  String get label;
  String get displayLabel;
  String? get icon;
  bool get isDefault;

  /// Create a copy of SortOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SortOptionConfigCopyWith<SortOptionConfig> get copyWith =>
      _$SortOptionConfigCopyWithImpl<SortOptionConfig>(
          this as SortOptionConfig, _$identity);

  /// Serializes this SortOptionConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SortOptionConfig &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.apiValue, apiValue) ||
                other.apiValue == apiValue) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.displayLabel, displayLabel) ||
                other.displayLabel == displayLabel) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, value, apiValue, label, displayLabel, icon, isDefault);

  @override
  String toString() {
    return 'SortOptionConfig(value: $value, apiValue: $apiValue, label: $label, displayLabel: $displayLabel, icon: $icon, isDefault: $isDefault)';
  }
}

/// @nodoc
abstract mixin class $SortOptionConfigCopyWith<$Res> {
  factory $SortOptionConfigCopyWith(
          SortOptionConfig value, $Res Function(SortOptionConfig) _then) =
      _$SortOptionConfigCopyWithImpl;
  @useResult
  $Res call(
      {String value,
      String apiValue,
      String label,
      String displayLabel,
      String? icon,
      bool isDefault});
}

/// @nodoc
class _$SortOptionConfigCopyWithImpl<$Res>
    implements $SortOptionConfigCopyWith<$Res> {
  _$SortOptionConfigCopyWithImpl(this._self, this._then);

  final SortOptionConfig _self;
  final $Res Function(SortOptionConfig) _then;

  /// Create a copy of SortOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? apiValue = null,
    Object? label = null,
    Object? displayLabel = null,
    Object? icon = freezed,
    Object? isDefault = null,
  }) {
    return _then(_self.copyWith(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      apiValue: null == apiValue
          ? _self.apiValue
          : apiValue // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      displayLabel: null == displayLabel
          ? _self.displayLabel
          : displayLabel // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
      isDefault: null == isDefault
          ? _self.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [SortOptionConfig].
extension SortOptionConfigPatterns on SortOptionConfig {
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
    TResult Function(_SortOptionConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SortOptionConfig() when $default != null:
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
    TResult Function(_SortOptionConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortOptionConfig():
        return $default(_that);
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
    TResult? Function(_SortOptionConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortOptionConfig() when $default != null:
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
    TResult Function(String value, String apiValue, String label,
            String displayLabel, String? icon, bool isDefault)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SortOptionConfig() when $default != null:
        return $default(_that.value, _that.apiValue, _that.label,
            _that.displayLabel, _that.icon, _that.isDefault);
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
    TResult Function(String value, String apiValue, String label,
            String displayLabel, String? icon, bool isDefault)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortOptionConfig():
        return $default(_that.value, _that.apiValue, _that.label,
            _that.displayLabel, _that.icon, _that.isDefault);
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
    TResult? Function(String value, String apiValue, String label,
            String displayLabel, String? icon, bool isDefault)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortOptionConfig() when $default != null:
        return $default(_that.value, _that.apiValue, _that.label,
            _that.displayLabel, _that.icon, _that.isDefault);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SortOptionConfig implements SortOptionConfig {
  const _SortOptionConfig(
      {required this.value,
      required this.apiValue,
      required this.label,
      required this.displayLabel,
      this.icon,
      this.isDefault = false});
  factory _SortOptionConfig.fromJson(Map<String, dynamic> json) =>
      _$SortOptionConfigFromJson(json);

  @override
  final String value;
  @override
  final String apiValue;
  @override
  final String label;
  @override
  final String displayLabel;
  @override
  final String? icon;
  @override
  @JsonKey()
  final bool isDefault;

  /// Create a copy of SortOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SortOptionConfigCopyWith<_SortOptionConfig> get copyWith =>
      __$SortOptionConfigCopyWithImpl<_SortOptionConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SortOptionConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SortOptionConfig &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.apiValue, apiValue) ||
                other.apiValue == apiValue) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.displayLabel, displayLabel) ||
                other.displayLabel == displayLabel) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, value, apiValue, label, displayLabel, icon, isDefault);

  @override
  String toString() {
    return 'SortOptionConfig(value: $value, apiValue: $apiValue, label: $label, displayLabel: $displayLabel, icon: $icon, isDefault: $isDefault)';
  }
}

/// @nodoc
abstract mixin class _$SortOptionConfigCopyWith<$Res>
    implements $SortOptionConfigCopyWith<$Res> {
  factory _$SortOptionConfigCopyWith(
          _SortOptionConfig value, $Res Function(_SortOptionConfig) _then) =
      __$SortOptionConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String value,
      String apiValue,
      String label,
      String displayLabel,
      String? icon,
      bool isDefault});
}

/// @nodoc
class __$SortOptionConfigCopyWithImpl<$Res>
    implements _$SortOptionConfigCopyWith<$Res> {
  __$SortOptionConfigCopyWithImpl(this._self, this._then);

  final _SortOptionConfig _self;
  final $Res Function(_SortOptionConfig) _then;

  /// Create a copy of SortOptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
    Object? apiValue = null,
    Object? label = null,
    Object? displayLabel = null,
    Object? icon = freezed,
    Object? isDefault = null,
  }) {
    return _then(_SortOptionConfig(
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      apiValue: null == apiValue
          ? _self.apiValue
          : apiValue // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      displayLabel: null == displayLabel
          ? _self.displayLabel
          : displayLabel // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
      isDefault: null == isDefault
          ? _self.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$SortingMessages {
  String? get dropdownLabel;
  String? get noOptionsAvailable;
  String? get readOnlyPrefix;
  String? get readOnlySuffix;
  String? get tapToModifyHint;
  String? get returnToSearchButton;

  /// Create a copy of SortingMessages
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SortingMessagesCopyWith<SortingMessages> get copyWith =>
      _$SortingMessagesCopyWithImpl<SortingMessages>(
          this as SortingMessages, _$identity);

  /// Serializes this SortingMessages to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SortingMessages &&
            (identical(other.dropdownLabel, dropdownLabel) ||
                other.dropdownLabel == dropdownLabel) &&
            (identical(other.noOptionsAvailable, noOptionsAvailable) ||
                other.noOptionsAvailable == noOptionsAvailable) &&
            (identical(other.readOnlyPrefix, readOnlyPrefix) ||
                other.readOnlyPrefix == readOnlyPrefix) &&
            (identical(other.readOnlySuffix, readOnlySuffix) ||
                other.readOnlySuffix == readOnlySuffix) &&
            (identical(other.tapToModifyHint, tapToModifyHint) ||
                other.tapToModifyHint == tapToModifyHint) &&
            (identical(other.returnToSearchButton, returnToSearchButton) ||
                other.returnToSearchButton == returnToSearchButton));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dropdownLabel,
      noOptionsAvailable,
      readOnlyPrefix,
      readOnlySuffix,
      tapToModifyHint,
      returnToSearchButton);

  @override
  String toString() {
    return 'SortingMessages(dropdownLabel: $dropdownLabel, noOptionsAvailable: $noOptionsAvailable, readOnlyPrefix: $readOnlyPrefix, readOnlySuffix: $readOnlySuffix, tapToModifyHint: $tapToModifyHint, returnToSearchButton: $returnToSearchButton)';
  }
}

/// @nodoc
abstract mixin class $SortingMessagesCopyWith<$Res> {
  factory $SortingMessagesCopyWith(
          SortingMessages value, $Res Function(SortingMessages) _then) =
      _$SortingMessagesCopyWithImpl;
  @useResult
  $Res call(
      {String? dropdownLabel,
      String? noOptionsAvailable,
      String? readOnlyPrefix,
      String? readOnlySuffix,
      String? tapToModifyHint,
      String? returnToSearchButton});
}

/// @nodoc
class _$SortingMessagesCopyWithImpl<$Res>
    implements $SortingMessagesCopyWith<$Res> {
  _$SortingMessagesCopyWithImpl(this._self, this._then);

  final SortingMessages _self;
  final $Res Function(SortingMessages) _then;

  /// Create a copy of SortingMessages
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dropdownLabel = freezed,
    Object? noOptionsAvailable = freezed,
    Object? readOnlyPrefix = freezed,
    Object? readOnlySuffix = freezed,
    Object? tapToModifyHint = freezed,
    Object? returnToSearchButton = freezed,
  }) {
    return _then(_self.copyWith(
      dropdownLabel: freezed == dropdownLabel
          ? _self.dropdownLabel
          : dropdownLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      noOptionsAvailable: freezed == noOptionsAvailable
          ? _self.noOptionsAvailable
          : noOptionsAvailable // ignore: cast_nullable_to_non_nullable
              as String?,
      readOnlyPrefix: freezed == readOnlyPrefix
          ? _self.readOnlyPrefix
          : readOnlyPrefix // ignore: cast_nullable_to_non_nullable
              as String?,
      readOnlySuffix: freezed == readOnlySuffix
          ? _self.readOnlySuffix
          : readOnlySuffix // ignore: cast_nullable_to_non_nullable
              as String?,
      tapToModifyHint: freezed == tapToModifyHint
          ? _self.tapToModifyHint
          : tapToModifyHint // ignore: cast_nullable_to_non_nullable
              as String?,
      returnToSearchButton: freezed == returnToSearchButton
          ? _self.returnToSearchButton
          : returnToSearchButton // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [SortingMessages].
extension SortingMessagesPatterns on SortingMessages {
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
    TResult Function(_SortingMessages value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SortingMessages() when $default != null:
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
    TResult Function(_SortingMessages value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingMessages():
        return $default(_that);
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
    TResult? Function(_SortingMessages value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingMessages() when $default != null:
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
            String? dropdownLabel,
            String? noOptionsAvailable,
            String? readOnlyPrefix,
            String? readOnlySuffix,
            String? tapToModifyHint,
            String? returnToSearchButton)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SortingMessages() when $default != null:
        return $default(
            _that.dropdownLabel,
            _that.noOptionsAvailable,
            _that.readOnlyPrefix,
            _that.readOnlySuffix,
            _that.tapToModifyHint,
            _that.returnToSearchButton);
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
            String? dropdownLabel,
            String? noOptionsAvailable,
            String? readOnlyPrefix,
            String? readOnlySuffix,
            String? tapToModifyHint,
            String? returnToSearchButton)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingMessages():
        return $default(
            _that.dropdownLabel,
            _that.noOptionsAvailable,
            _that.readOnlyPrefix,
            _that.readOnlySuffix,
            _that.tapToModifyHint,
            _that.returnToSearchButton);
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
            String? dropdownLabel,
            String? noOptionsAvailable,
            String? readOnlyPrefix,
            String? readOnlySuffix,
            String? tapToModifyHint,
            String? returnToSearchButton)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SortingMessages() when $default != null:
        return $default(
            _that.dropdownLabel,
            _that.noOptionsAvailable,
            _that.readOnlyPrefix,
            _that.readOnlySuffix,
            _that.tapToModifyHint,
            _that.returnToSearchButton);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SortingMessages implements SortingMessages {
  const _SortingMessages(
      {this.dropdownLabel,
      this.noOptionsAvailable,
      this.readOnlyPrefix,
      this.readOnlySuffix,
      this.tapToModifyHint,
      this.returnToSearchButton});
  factory _SortingMessages.fromJson(Map<String, dynamic> json) =>
      _$SortingMessagesFromJson(json);

  @override
  final String? dropdownLabel;
  @override
  final String? noOptionsAvailable;
  @override
  final String? readOnlyPrefix;
  @override
  final String? readOnlySuffix;
  @override
  final String? tapToModifyHint;
  @override
  final String? returnToSearchButton;

  /// Create a copy of SortingMessages
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SortingMessagesCopyWith<_SortingMessages> get copyWith =>
      __$SortingMessagesCopyWithImpl<_SortingMessages>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SortingMessagesToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SortingMessages &&
            (identical(other.dropdownLabel, dropdownLabel) ||
                other.dropdownLabel == dropdownLabel) &&
            (identical(other.noOptionsAvailable, noOptionsAvailable) ||
                other.noOptionsAvailable == noOptionsAvailable) &&
            (identical(other.readOnlyPrefix, readOnlyPrefix) ||
                other.readOnlyPrefix == readOnlyPrefix) &&
            (identical(other.readOnlySuffix, readOnlySuffix) ||
                other.readOnlySuffix == readOnlySuffix) &&
            (identical(other.tapToModifyHint, tapToModifyHint) ||
                other.tapToModifyHint == tapToModifyHint) &&
            (identical(other.returnToSearchButton, returnToSearchButton) ||
                other.returnToSearchButton == returnToSearchButton));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dropdownLabel,
      noOptionsAvailable,
      readOnlyPrefix,
      readOnlySuffix,
      tapToModifyHint,
      returnToSearchButton);

  @override
  String toString() {
    return 'SortingMessages(dropdownLabel: $dropdownLabel, noOptionsAvailable: $noOptionsAvailable, readOnlyPrefix: $readOnlyPrefix, readOnlySuffix: $readOnlySuffix, tapToModifyHint: $tapToModifyHint, returnToSearchButton: $returnToSearchButton)';
  }
}

/// @nodoc
abstract mixin class _$SortingMessagesCopyWith<$Res>
    implements $SortingMessagesCopyWith<$Res> {
  factory _$SortingMessagesCopyWith(
          _SortingMessages value, $Res Function(_SortingMessages) _then) =
      __$SortingMessagesCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? dropdownLabel,
      String? noOptionsAvailable,
      String? readOnlyPrefix,
      String? readOnlySuffix,
      String? tapToModifyHint,
      String? returnToSearchButton});
}

/// @nodoc
class __$SortingMessagesCopyWithImpl<$Res>
    implements _$SortingMessagesCopyWith<$Res> {
  __$SortingMessagesCopyWithImpl(this._self, this._then);

  final _SortingMessages _self;
  final $Res Function(_SortingMessages) _then;

  /// Create a copy of SortingMessages
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dropdownLabel = freezed,
    Object? noOptionsAvailable = freezed,
    Object? readOnlyPrefix = freezed,
    Object? readOnlySuffix = freezed,
    Object? tapToModifyHint = freezed,
    Object? returnToSearchButton = freezed,
  }) {
    return _then(_SortingMessages(
      dropdownLabel: freezed == dropdownLabel
          ? _self.dropdownLabel
          : dropdownLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      noOptionsAvailable: freezed == noOptionsAvailable
          ? _self.noOptionsAvailable
          : noOptionsAvailable // ignore: cast_nullable_to_non_nullable
              as String?,
      readOnlyPrefix: freezed == readOnlyPrefix
          ? _self.readOnlyPrefix
          : readOnlyPrefix // ignore: cast_nullable_to_non_nullable
              as String?,
      readOnlySuffix: freezed == readOnlySuffix
          ? _self.readOnlySuffix
          : readOnlySuffix // ignore: cast_nullable_to_non_nullable
              as String?,
      tapToModifyHint: freezed == tapToModifyHint
          ? _self.tapToModifyHint
          : tapToModifyHint // ignore: cast_nullable_to_non_nullable
              as String?,
      returnToSearchButton: freezed == returnToSearchButton
          ? _self.returnToSearchButton
          : returnToSearchButton // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PaginationConfig {
  String get urlPattern;
  String get paramName;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaginationConfigCopyWith<PaginationConfig> get copyWith =>
      _$PaginationConfigCopyWithImpl<PaginationConfig>(
          this as PaginationConfig, _$identity);

  /// Serializes this PaginationConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PaginationConfig &&
            (identical(other.urlPattern, urlPattern) ||
                other.urlPattern == urlPattern) &&
            (identical(other.paramName, paramName) ||
                other.paramName == paramName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, urlPattern, paramName);

  @override
  String toString() {
    return 'PaginationConfig(urlPattern: $urlPattern, paramName: $paramName)';
  }
}

/// @nodoc
abstract mixin class $PaginationConfigCopyWith<$Res> {
  factory $PaginationConfigCopyWith(
          PaginationConfig value, $Res Function(PaginationConfig) _then) =
      _$PaginationConfigCopyWithImpl;
  @useResult
  $Res call({String urlPattern, String paramName});
}

/// @nodoc
class _$PaginationConfigCopyWithImpl<$Res>
    implements $PaginationConfigCopyWith<$Res> {
  _$PaginationConfigCopyWithImpl(this._self, this._then);

  final PaginationConfig _self;
  final $Res Function(PaginationConfig) _then;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? urlPattern = null,
    Object? paramName = null,
  }) {
    return _then(_self.copyWith(
      urlPattern: null == urlPattern
          ? _self.urlPattern
          : urlPattern // ignore: cast_nullable_to_non_nullable
              as String,
      paramName: null == paramName
          ? _self.paramName
          : paramName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [PaginationConfig].
extension PaginationConfigPatterns on PaginationConfig {
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
    TResult Function(_PaginationConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
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
    TResult Function(_PaginationConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig():
        return $default(_that);
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
    TResult? Function(_PaginationConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
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
    TResult Function(String urlPattern, String paramName)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
        return $default(_that.urlPattern, _that.paramName);
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
    TResult Function(String urlPattern, String paramName) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig():
        return $default(_that.urlPattern, _that.paramName);
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
    TResult? Function(String urlPattern, String paramName)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
        return $default(_that.urlPattern, _that.paramName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PaginationConfig implements PaginationConfig {
  const _PaginationConfig({required this.urlPattern, this.paramName = 'page'});
  factory _PaginationConfig.fromJson(Map<String, dynamic> json) =>
      _$PaginationConfigFromJson(json);

  @override
  final String urlPattern;
  @override
  @JsonKey()
  final String paramName;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaginationConfigCopyWith<_PaginationConfig> get copyWith =>
      __$PaginationConfigCopyWithImpl<_PaginationConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PaginationConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PaginationConfig &&
            (identical(other.urlPattern, urlPattern) ||
                other.urlPattern == urlPattern) &&
            (identical(other.paramName, paramName) ||
                other.paramName == paramName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, urlPattern, paramName);

  @override
  String toString() {
    return 'PaginationConfig(urlPattern: $urlPattern, paramName: $paramName)';
  }
}

/// @nodoc
abstract mixin class _$PaginationConfigCopyWith<$Res>
    implements $PaginationConfigCopyWith<$Res> {
  factory _$PaginationConfigCopyWith(
          _PaginationConfig value, $Res Function(_PaginationConfig) _then) =
      __$PaginationConfigCopyWithImpl;
  @override
  @useResult
  $Res call({String urlPattern, String paramName});
}

/// @nodoc
class __$PaginationConfigCopyWithImpl<$Res>
    implements _$PaginationConfigCopyWith<$Res> {
  __$PaginationConfigCopyWithImpl(this._self, this._then);

  final _PaginationConfig _self;
  final $Res Function(_PaginationConfig) _then;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? urlPattern = null,
    Object? paramName = null,
  }) {
    return _then(_PaginationConfig(
      urlPattern: null == urlPattern
          ? _self.urlPattern
          : urlPattern // ignore: cast_nullable_to_non_nullable
              as String,
      paramName: null == paramName
          ? _self.paramName
          : paramName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
