import 'package:kuron_generic/kuron_generic.dart'
    show DynamicSearchFormContract, SearchFormFieldContract;
import 'package:nhasixapp/core/config/config_models.dart';

class SearchFormContractAdapter {
  const SearchFormContractAdapter._();

  static SearchFormConfig toSearchFormConfig(
    DynamicSearchFormContract contract,
  ) {
    return SearchFormConfig(
      urlPattern: contract.urlPattern,
      params: <String, SearchFormFieldConfig>{
        for (final field in contract.fields) field.id: _toFieldConfig(field),
      },
    );
  }

  static Map<String, dynamic> toRawSearchForm(
    DynamicSearchFormContract contract,
  ) {
    return <String, dynamic>{
      'urlPattern': contract.urlPattern,
      if (contract.dataSources.isNotEmpty) 'dataSources': contract.dataSources,
      'params': <String, dynamic>{
        for (final field in contract.fields) field.id: _toRawField(field),
      },
    };
  }

  static SearchFormFieldConfig _toFieldConfig(
    SearchFormFieldContract field,
  ) {
    return SearchFormFieldConfig(
      type: _appFieldType(field),
      queryParam: field.queryParam,
      placeholder: field.placeholder,
      options: field.options
          .map((option) => option.value)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _toRawField(SearchFormFieldContract field) {
    return <String, dynamic>{
      'type': _appFieldType(field),
      'queryParam': field.queryParam,
      if (field.label != null) 'label': field.label,
      if (field.placeholder != null) 'placeholder': field.placeholder,
      if (field.valuePrefix != null) 'valuePrefix': field.valuePrefix,
      if (field.valueSuffix != null) 'valueSuffix': field.valueSuffix,
      if (field.quoteIfContainsSpace)
        'quoteIfContainsSpace': field.quoteIfContainsSpace,
      if (field.multiInput) 'multiInput': field.multiInput,
      if (field.joinMode != null) 'joinMode': field.joinMode,
      if (field.uiSelector != null)
        'ui': <String, dynamic>{
          'selector': field.uiSelector,
          if (field.multiInput) 'multi': true,
          if (field.uiDataSource != null) 'dataSource': field.uiDataSource,
        },
      if (field.options.isNotEmpty)
        'options': field.options
            .map((option) => <String, dynamic>{
                  'value': option.value,
                  'label': option.label ?? option.value,
                })
            .toList(growable: false),
    };
  }

  static String _appFieldType(SearchFormFieldContract field) {
    return switch (field.type.name) {
      'hidden' => 'page',
      _ => field.type.name,
    };
  }
}
