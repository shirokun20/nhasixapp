/// Typed dynamic search form contract.
///
/// Parses the `searchForm` block of a Source Config into strongly-typed
/// models so the validator and the UI filter system can work without
/// inspecting raw maps.
///
/// Supported dialects:
///   - HentaiNexus-style: `searchForm.params.*` with valuePrefix, operators,
///     quoteIfContainsSpace, joinMode, multiInput, ui.selector.
///   - KomikCast-style: `searchConfig.sortingConfig` separate from
///     `searchForm`.
library;

import 'package:equatable/equatable.dart';
import 'package:kuron_core/kuron_core.dart';

/// Kind of a single search form field.
enum SearchFormFieldType {
  /// Free-text input.
  text,

  /// Tag chips input (multiInput true by default).
  tag,

  /// Single-value dropdown.
  select,

  /// Boolean checkbox.
  checkbox,

  /// Sort order selector. Serialized as `sort`.
  sort,

  /// Visual separator — no value.
  separator,

  /// Unknown type preserved verbatim.
  unknown,
}

/// A selectable option in a `select`, `checkbox`, or `sort` field.
class SearchFormFieldOption extends Equatable {
  const SearchFormFieldOption({required this.value, this.label});

  final String value;
  final String? label;

  factory SearchFormFieldOption.fromMap(Map<String, Object?> map) {
    return SearchFormFieldOption(
      value: map['value']?.toString() ?? '',
      label: map['label']?.toString(),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'value': value,
        if (label != null) 'label': label,
      };

  @override
  List<Object?> get props => <Object?>[value, label];
}

/// Contract for a single field in a dynamic search form.
class SearchFormFieldContract extends Equatable {
  const SearchFormFieldContract({
    required this.id,
    required this.queryParam,
    required this.type,
    this.label,
    this.placeholder,
    this.valuePrefix,
    this.valueSuffix,
    this.quoteIfContainsSpace = false,
    this.multiInput = false,
    this.joinMode,
    this.uiSelector,
    this.operators = const <String>[],
    this.options = const <SearchFormFieldOption>[],
  });

  /// Field identifier (key in `searchForm.params` map).
  final String id;

  /// Query parameter name the value is appended to.
  final String queryParam;

  final SearchFormFieldType type;

  final String? label;
  final String? placeholder;

  /// Prefix prepended to the value before appending to [queryParam].
  /// Example: `"artist:"` for HentaiNexus artist search.
  final String? valuePrefix;

  /// Suffix appended after the value.
  final String? valueSuffix;

  /// When true, the value is quoted if it contains whitespace.
  final bool quoteIfContainsSpace;

  /// When true, multiple values can be submitted for this field.
  final bool multiInput;

  /// How multiple values are joined. Common: `"space"`, `"comma"`, `"+"`.
  final String? joinMode;

  /// UI control hint from `ui.selector` (e.g. `"chips"`, `"dropdown"`).
  final String? uiSelector;

  /// Operator list for range/comparison fields (e.g. `[">=", "<="]`).
  final List<String> operators;

  /// Selectable options for `select`, `checkbox`, or `sort` fields.
  final List<SearchFormFieldOption> options;

  factory SearchFormFieldContract.fromEntry(
    String id,
    Map<String, Object?> map,
  ) {
    final String typeStr = map['type']?.toString() ?? 'text';
    final SearchFormFieldType type = switch (typeStr) {
      'tag' => SearchFormFieldType.tag,
      'select' => SearchFormFieldType.select,
      'checkbox' => SearchFormFieldType.checkbox,
      'sort' => SearchFormFieldType.sort,
      'separator' => SearchFormFieldType.separator,
      _ => SearchFormFieldType.text,
    };

    final Object? uiRaw = map['ui'];
    final String? uiSelector = uiRaw is Map
        ? uiRaw.cast<String, Object?>()['selector']?.toString()
        : null;

    final Object? opsRaw = map['operators'];
    final List<String> operators = opsRaw is List
        ? opsRaw
            .map<String>((Object? e) => e.toString())
            .toList(growable: false)
        : const <String>[];

    final Object? optsRaw = map['options'];
    final List<SearchFormFieldOption> options = optsRaw is List
        ? optsRaw
            .whereType<Map>()
            .map<SearchFormFieldOption>((Map<Object?, Object?> e) =>
                SearchFormFieldOption.fromMap(e.cast<String, Object?>()))
            .toList(growable: false)
        : const <SearchFormFieldOption>[];

    return SearchFormFieldContract(
      id: id,
      queryParam: map['queryParam']?.toString() ?? id,
      type: type,
      label: map['label']?.toString(),
      placeholder: map['placeholder']?.toString(),
      valuePrefix: map['valuePrefix']?.toString(),
      valueSuffix: map['valueSuffix']?.toString(),
      quoteIfContainsSpace: map['quoteIfContainsSpace'] as bool? ?? false,
      multiInput:
          map['multiInput'] as bool? ?? (type == SearchFormFieldType.tag),
      joinMode: map['joinMode']?.toString(),
      uiSelector: uiSelector,
      operators: operators,
      options: options,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'queryParam': queryParam,
        'type': type.name,
        if (label != null) 'label': label,
        if (placeholder != null) 'placeholder': placeholder,
        if (valuePrefix != null) 'valuePrefix': valuePrefix,
        if (valueSuffix != null) 'valueSuffix': valueSuffix,
        if (quoteIfContainsSpace) 'quoteIfContainsSpace': quoteIfContainsSpace,
        if (multiInput) 'multiInput': multiInput,
        if (joinMode != null) 'joinMode': joinMode,
        if (uiSelector != null) 'uiSelector': uiSelector,
        if (operators.isNotEmpty) 'operators': operators,
        if (options.isNotEmpty)
          'options': options
              .map((SearchFormFieldOption o) => o.toJson())
              .toList(growable: false),
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        queryParam,
        type,
        label,
        placeholder,
        valuePrefix,
        valueSuffix,
        quoteIfContainsSpace,
        multiInput,
        joinMode,
        uiSelector,
        operators,
        options,
      ];
}

/// Aggregated dynamic search form contract for a source.
class DynamicSearchFormContract extends Equatable {
  DynamicSearchFormContract({
    required this.urlPattern,
    required List<SearchFormFieldContract> fields,
    this.defaultSort,
    this.diagnostics = const <ValidationDiagnostic>[],
  }) : fields = List<SearchFormFieldContract>.unmodifiable(fields);

  /// URL pattern identifier this form maps to (e.g. `"search"`).
  final String urlPattern;

  final List<SearchFormFieldContract> fields;

  /// Default sort option when none is selected.
  final String? defaultSort;

  final List<ValidationDiagnostic> diagnostics;

  /// Whether any field uses operators (e.g. `>=`, `<=`).
  bool get hasOperators =>
      fields.any((SearchFormFieldContract f) => f.operators.isNotEmpty);

  /// Whether any field uses quoteIfContainsSpace.
  bool get hasQuoteWhitespace =>
      fields.any((SearchFormFieldContract f) => f.quoteIfContainsSpace);

  /// Required engine primitives implied by this form contract.
  Set<String> get impliedPrimitives => <String>{
        EnginePrimitive.dynamicFormBasic,
        if (hasOperators) EnginePrimitive.dynamicFormOperators,
        if (hasQuoteWhitespace) EnginePrimitive.dynamicFormQuoteWhitespace,
      };

  /// Parses a `searchForm` block from the raw config.
  ///
  /// Handles both the HentaiNexus-style `searchForm.params` block and the
  /// KomikCast-style `searchConfig.sortingConfig` block.
  factory DynamicSearchFormContract.fromConfig(
    Map<String, Object?> rawConfig,
  ) {
    final List<ValidationDiagnostic> diags = <ValidationDiagnostic>[];
    final Object? sfRaw = rawConfig['searchForm'];
    final bool hasSfBlock = sfRaw is Map;
    final bool hasScBlock = rawConfig['searchConfig'] is Map;

    if (!hasSfBlock && !hasScBlock) {
      return DynamicSearchFormContract(
        urlPattern: 'search',
        fields: const <SearchFormFieldContract>[],
        diagnostics: diags,
      );
    }

    String urlPattern = 'search';
    final List<SearchFormFieldContract> fields = <SearchFormFieldContract>[];

    // Parse HentaiNexus-style `params` map.
    if (sfRaw is Map) {
      final Map<String, Object?> sf = sfRaw.cast<String, Object?>();
      urlPattern = sf['urlPattern']?.toString() ?? 'search';
      final Object? paramsRaw = sf['params'];
      if (paramsRaw is Map) {
        for (final MapEntry<Object?, Object?> entry in paramsRaw.entries) {
          final String id = entry.key.toString();
          final Object? value = entry.value;
          if (value is Map) {
            fields.add(SearchFormFieldContract.fromEntry(
              id,
              value.cast<String, Object?>(),
            ));
          }
        }
      }
    }

    // Parse KomikCast-style `sortingConfig` if present in searchConfig.
    final Object? scRaw = rawConfig['searchConfig'];
    if (scRaw is Map) {
      final Map<String, Object?> sc = scRaw.cast<String, Object?>();
      final Object? sortingRaw = sc['sortingConfig'];
      if (sortingRaw is Map) {
        final Map<String, Object?> sorting = sortingRaw.cast<String, Object?>();
        final Object? optionsRaw = sorting['options'];
        final List<SearchFormFieldOption> sortOptions = optionsRaw is List
            ? optionsRaw
                .whereType<Map>()
                .map<SearchFormFieldOption>((Map<Object?, Object?> e) =>
                    SearchFormFieldOption.fromMap(e.cast<String, Object?>()))
                .toList(growable: false)
            : const <SearchFormFieldOption>[];
        if (sortOptions.isNotEmpty) {
          fields.add(SearchFormFieldContract(
            id: '_sort',
            queryParam: sorting['queryParam']?.toString() ?? 'orderby',
            type: SearchFormFieldType.sort,
            label: sorting['label']?.toString() ?? 'Sort',
            uiSelector: sorting['widgetType']?.toString(),
            options: sortOptions,
          ));
        }
      }
    }

    if (fields.isEmpty) {
      diags.add(const ValidationDiagnostic(
        severity: DiagnosticSeverity.warning,
        code: 'dynamicFormNoFields',
        message:
            'searchForm block is present but no parseable fields were found.',
        feature: FeatureKind.dynamicForm,
        path: 'searchForm.params',
      ));
    }

    return DynamicSearchFormContract(
      urlPattern: urlPattern,
      fields: fields,
      diagnostics: diags,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'urlPattern': urlPattern,
        if (defaultSort != null) 'defaultSort': defaultSort,
        'fields': fields
            .map((SearchFormFieldContract f) => f.toJson())
            .toList(growable: false),
      };

  @override
  List<Object?> get props => <Object?>[urlPattern, fields, defaultSort];
}
