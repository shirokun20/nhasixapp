part of 'dynamic_form_search_cubit.dart';

class DynamicFormSearchState extends BaseCubitState {
  final Map<String, dynamic>? rawSearchForm;
  final Map<String, dynamic> dataSources;
  final Map<String, List<DynamicOption>> optionCacheBySource;
  final Set<String> loadingPickerSources;
  final Map<String, String> pickerLoadErrorBySource;
  final Map<String, List<DynamicOption>> checkboxOptionCache;
  final Set<String> loadingCheckboxFields;
  final Map<String, String> checkboxLoadErrorByField;
  final SearchFilter? savedFilter;
  final bool isLoadingSavedFilter;
  final String? savedFilterError;
  final bool isSavingFilter;
  final String? saveFilterError;

  const DynamicFormSearchState({
    this.rawSearchForm,
    this.dataSources = const {},
    this.optionCacheBySource = const {},
    this.loadingPickerSources = const {},
    this.pickerLoadErrorBySource = const {},
    this.checkboxOptionCache = const {},
    this.loadingCheckboxFields = const {},
    this.checkboxLoadErrorByField = const {},
    this.savedFilter,
    this.isLoadingSavedFilter = false,
    this.savedFilterError,
    this.isSavingFilter = false,
    this.saveFilterError,
  });

  Map<String, dynamic>? rawFieldConfig(String name) {
    final params = rawSearchForm?['params'];
    if (params is Map<String, dynamic> &&
        params[name] is Map<String, dynamic>) {
      return params[name] as Map<String, dynamic>;
    }
    return null;
  }

  String? pickerDataSource(String name, SearchFormFieldConfig field) {
    // Original semantics: per-field source lives at raw `ui.dataSource`;
    // the typed config has no such field (verified against
    // SearchFormFieldConfig). `field` kept for call-site compatibility.
    final raw = rawFieldConfig(name);
    final ui = raw?['ui'];
    if (ui is Map<String, dynamic>) return ui['dataSource'] as String?;
    return null;
  }

  DynamicFormSearchState copyWith({
    Map<String, dynamic>? rawSearchForm,
    bool clearRawSearchForm = false,
    Map<String, dynamic>? dataSources,
    Map<String, List<DynamicOption>>? optionCacheBySource,
    Set<String>? loadingPickerSources,
    Map<String, String>? pickerLoadErrorBySource,
    Map<String, List<DynamicOption>>? checkboxOptionCache,
    Set<String>? loadingCheckboxFields,
    Map<String, String>? checkboxLoadErrorByField,
    SearchFilter? savedFilter,
    bool clearSavedFilter = false,
    bool? isLoadingSavedFilter,
    String? savedFilterError,
    bool clearSavedFilterError = false,
    bool? isSavingFilter,
    String? saveFilterError,
    bool clearSaveFilterError = false,
  }) {
    return DynamicFormSearchState(
      rawSearchForm: clearRawSearchForm
          ? null
          : (rawSearchForm ?? this.rawSearchForm),
      dataSources: dataSources ?? this.dataSources,
      optionCacheBySource: optionCacheBySource ?? this.optionCacheBySource,
      loadingPickerSources: loadingPickerSources ?? this.loadingPickerSources,
      pickerLoadErrorBySource:
          pickerLoadErrorBySource ?? this.pickerLoadErrorBySource,
      checkboxOptionCache: checkboxOptionCache ?? this.checkboxOptionCache,
      loadingCheckboxFields:
          loadingCheckboxFields ?? this.loadingCheckboxFields,
      checkboxLoadErrorByField:
          checkboxLoadErrorByField ?? this.checkboxLoadErrorByField,
      savedFilter:
          clearSavedFilter ? null : (savedFilter ?? this.savedFilter),
      isLoadingSavedFilter: isLoadingSavedFilter ?? this.isLoadingSavedFilter,
      savedFilterError: clearSavedFilterError
          ? null
          : (savedFilterError ?? this.savedFilterError),
      isSavingFilter: isSavingFilter ?? this.isSavingFilter,
      saveFilterError: clearSaveFilterError
          ? null
          : (saveFilterError ?? this.saveFilterError),
    );
  }

  @override
  List<Object?> get props => [
        rawSearchForm,
        dataSources,
        optionCacheBySource,
        loadingPickerSources,
        pickerLoadErrorBySource,
        checkboxOptionCache,
        loadingCheckboxFields,
        checkboxLoadErrorByField,
        savedFilter,
        isLoadingSavedFilter,
        savedFilterError,
        isSavingFilter,
        saveFilterError,
      ];
}
