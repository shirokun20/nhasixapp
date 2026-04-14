import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';

import 'package:nhasixapp/l10n/app_localizations.dart';
/// Generic search form UI driven entirely by [SearchFormConfig].
///
/// Renders form fields based on the `searchForm.params` block in the source
/// config JSON. Supports field types:
///   - `text`   → [TextFormField]
///   - `select` → segmented choice chips
///   - `tag`    → text field (genre slug)
///   - `page`   → hidden (managed internally)
///
/// On submit it saves a `SearchFilter` with `query = "raw:<params>"` which
/// is consumed by [GenericScraperAdapter.search] to build the search URL.
class DynamicFormSearchUI extends StatefulWidget {
  final SearchFormConfig config;
  final String sourceId;

  const DynamicFormSearchUI({
    super.key,
    required this.config,
    required this.sourceId,
  });

  @override
  State<DynamicFormSearchUI> createState() => _DynamicFormSearchUIState();
}

class _DynamicFormSearchUIState extends State<DynamicFormSearchUI> {
  final _formKey = GlobalKey<FormState>();
  final _logger = getIt<Logger>();
  final _dio = getIt<Dio>();
  final _remoteConfigService = getIt<RemoteConfigService>();

  // Keyed by field logical name (e.g. "query", "status", "order", "genre")
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, List<_DynamicOption>> _multiSelectValues = {};
  final Map<String, List<String>> _tagChipValues = {};
  final Map<String, List<String>> _pendingMultiRestore = {};

  Map<String, dynamic>? _rawSearchForm;
  Map<String, dynamic> _dataSources = const {};
  final Map<String, List<_DynamicOption>> _optionCacheBySource = {};
  final Set<String> _loadingPickerSources = <String>{};
  final Map<String, String> _pickerLoadErrorBySource = <String, String>{};

  @override
  void initState() {
    super.initState();
    _initRawSearchForm();
    _initFields();
    context
        .read<SearchBloc>()
        .add(SearchInitializeEvent(sourceId: widget.sourceId));
    _initializeDynamicOptions();
  }

  void _initRawSearchForm() {
    final rawSource = _remoteConfigService.getRawConfig(widget.sourceId);
    final rawForm = rawSource?['searchForm'];
    if (rawForm is Map<String, dynamic>) {
      _rawSearchForm = rawForm;
      final dynamic dataSources = rawForm['dataSources'];
      if (dataSources is Map<String, dynamic>) {
        _dataSources = dataSources;
      }
    }
  }

  void _initFields() {
    for (final entry in widget.config.params.entries) {
      final field = entry.value;
      if (_isPickerField(entry.key, field)) {
        _multiSelectValues[entry.key] = [];
        continue;
      }

      if (_isTagChipsField(entry.key, field)) {
        _textControllers[entry.key] = TextEditingController();
        _tagChipValues[entry.key] = <String>[];
        continue;
      }

      switch (field.type) {
        case 'text':
        case 'tag':
          _textControllers[entry.key] = TextEditingController();
        case 'select':
          _selectValues[entry.key] = null; // null = "all" / no filter
        default:
          break; // 'page' and unknown types are ignored in the UI
      }
    }
  }

  Future<void> _initializeDynamicOptions() async {
    await _loadPickerOptions();
    await _restoreSaved();
  }

  Future<void> _loadPickerOptions() async {
    final sourceIds = <String>{};
    for (final entry in widget.config.params.entries) {
      final sourceId = _pickerDataSource(entry.key, entry.value);
      if (sourceId != null && sourceId.isNotEmpty) {
        sourceIds.add(sourceId);
      }
    }

    for (final sourceId in sourceIds) {
      if (_optionCacheBySource.containsKey(sourceId)) continue;
      await _loadPickerOptionsForSource(sourceId);
    }
  }

  Future<void> _loadPickerOptionsForSource(String sourceId,
      {bool force = false}) async {
    if (_loadingPickerSources.contains(sourceId)) return;
    if (!force && _optionCacheBySource.containsKey(sourceId)) return;

    final dynamic sourceConfig = _dataSources[sourceId];
    if (sourceConfig is! Map<String, dynamic>) return;

    final endpoint = sourceConfig['endpoint'] as String?;
    if (endpoint == null || endpoint.isEmpty) {
      _optionCacheBySource[sourceId] = const [];
      _pickerLoadErrorBySource[sourceId] = 'Missing endpoint';
      return;
    }

    _loadingPickerSources.add(sourceId);
    if (mounted) setState(() {});

    try {
      final rawConfig = _remoteConfigService.getRawConfig(widget.sourceId);
      final baseUrl = ((rawConfig?['api'] as Map?)?['baseUrl'] as String?) ??
          (rawConfig?['baseUrl'] as String?) ??
          '';
      final url = endpoint.startsWith('http')
          ? endpoint
          : '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}${endpoint.startsWith('/') ? endpoint : '/$endpoint'}';

      final response = await _dio.get<dynamic>(url);
      // The global Dio client uses ResponseType.plain, so data may arrive as a
      // raw JSON string. Decode it so _extractByPath can navigate the Map/List.
      dynamic payload = response.data;
      if (payload is String) {
        try {
          payload = jsonDecode(payload);
        } catch (e) {
          _optionCacheBySource[sourceId] = const [];
          _pickerLoadErrorBySource[sourceId] =
              'Failed to parse response as JSON: $e';
          return;
        }
      }
      final itemsPath = sourceConfig['itemsPath'] as String? ?? 'data';
      final valuePath = sourceConfig['valuePath'] as String? ?? 'id';
      final labelPath = sourceConfig['labelPath'] as String? ?? 'id';
      final groupPath = sourceConfig['groupPath'] as String?;

      final items = _extractByPath(payload, itemsPath);
      if (items is! List) {
        _optionCacheBySource[sourceId] = const [];
        _pickerLoadErrorBySource[sourceId] =
            'Invalid response shape at "$itemsPath"';
        return;
      }

      final options = <_DynamicOption>[];
      for (final item in items) {
        final value = _extractByPath(item, valuePath)?.toString() ?? '';
        final label = _extractByPath(item, labelPath)?.toString() ?? value;
        if (value.isEmpty || label.isEmpty) continue;
        final group = groupPath == null
            ? null
            : _extractByPath(item, groupPath)?.toString();
        options.add(_DynamicOption(value: value, label: label, group: group));
      }

      _optionCacheBySource[sourceId] = options;
      _pickerLoadErrorBySource.remove(sourceId);
    } catch (e) {
      _logger.w('DynamicFormSearchUI: failed loading source $sourceId: $e');
      _optionCacheBySource[sourceId] = const [];
      _pickerLoadErrorBySource[sourceId] = e.toString();
    } finally {
      _loadingPickerSources.remove(sourceId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _restoreSaved() async {
    try {
      final savedJson =
          await getIt<LocalDataSource>().getLastSearchFilter(widget.sourceId);
      if (savedJson == null) return;

      final saved = SearchFilter.fromJson(savedJson);
      final query = saved.query;
      if (query == null || !query.startsWith('raw:')) return;

      final parsed = _parseRaw(query.substring(4));

      final fieldsByParam =
          <String, List<MapEntry<String, SearchFormFieldConfig>>>{};
      for (final entry in widget.config.params.entries) {
        final qp = entry.value.queryParam;
        if (qp == null) continue;
        (fieldsByParam[qp] ??= <MapEntry<String, SearchFormFieldConfig>>[])
            .add(entry);
      }

      for (final grouped in fieldsByParam.entries) {
        final queryParam = grouped.key;
        final fields = grouped.value;
        final values = parsed[queryParam] ?? const <String>[];
        if (values.isEmpty) continue;

        final hasSpaceJoin = fields.any((entry) {
          final raw = _rawFieldConfig(entry.key);
          return ((raw?['joinMode'] as String?)?.trim().toLowerCase() ?? '') ==
              'space';
        });

        if (fields.length > 1 && hasSpaceJoin) {
          _restoreJoinedParamGroup(queryParam, values.first, fields);
          continue;
        }

        for (final entry in fields) {
          final field = entry.value;
          if (_isPickerField(entry.key, field)) {
            _pendingMultiRestore[entry.key] = values;
            continue;
          }
          _setRestoredFieldValue(entry.key, field, values);
        }
      }

      // Chip/text/select restoration does not always go through
      // _applyPendingMultiRestore(), so ensure UI reflects restored values.
      if (mounted) {
        setState(() {});
      }

      _applyPendingMultiRestore();
    } catch (e) {
      _logger.w('DynamicFormSearchUI: failed to restore filter: $e');
    }
  }

  void _applyPendingMultiRestore() {
    if (_pendingMultiRestore.isEmpty) return;

    for (final entry in _pendingMultiRestore.entries) {
      final fieldName = entry.key;
      final field = widget.config.params[fieldName];
      if (field == null) continue;
      final sourceId = _pickerDataSource(fieldName, field);
      if (sourceId == null) continue;

      final options =
          _optionCacheBySource[sourceId] ?? const <_DynamicOption>[];
      final selected = entry.value
          .map((value) => options.firstWhere(
                (o) => o.value == value,
                orElse: () => _DynamicOption(value: value, label: value),
              ))
          .toList();
      _multiSelectValues[fieldName] = selected;
    }

    _pendingMultiRestore.clear();
    if (mounted) setState(() {});
  }

  Map<String, List<String>> _parseRaw(String raw) {
    final result = <String, List<String>>{};
    for (final pair in raw.split('&')) {
      if (pair.isEmpty) continue;
      final idx = pair.indexOf('=');
      if (idx < 0) continue;
      final k = Uri.decodeComponent(pair.substring(0, idx));
      final v = Uri.decodeComponent(pair.substring(idx + 1));
      (result[k] ??= []).add(v);
    }
    return result;
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onSearch() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedTagItems = <FilterItem>[];
    final parts = _collectEncodedQueryParts(selectedTagItems: selectedTagItems);
    final rawQuery = parts.isNotEmpty ? 'raw:${parts.join('&')}' : '';
    final filter = SearchFilter(query: rawQuery, tags: selectedTagItems);

    try {
      await getIt<LocalDataSource>()
          .saveSearchFilter(widget.sourceId, filter.toJson());
      if (mounted) context.pop(true);
    } catch (e) {
      _logger.e('DynamicFormSearchUI: failed to save filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToApplySearch(e.toString()))),
        );
      }
    }
  }

  void _onReset() {
    for (final c in _textControllers.values) {
      c.clear();
    }
    setState(() {
      for (final key in _selectValues.keys) {
        _selectValues[key] = null;
      }
      for (final key in _multiSelectValues.keys) {
        _multiSelectValues[key] = [];
      }
      for (final key in _tagChipValues.keys) {
        _tagChipValues[key] = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleFields = widget.config.params.entries
        .where((e) =>
            e.value.type != 'page' &&
            !_shouldHideBecauseCombinedPicker(e.key, e.value))
        .toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in visibleFields)
                    _buildField(entry.key, entry.value),
                  _buildQueryPreviewCard(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _onSearch,
                    icon: const Icon(Icons.search),
                    label: Text(AppLocalizations.of(context)!.search),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _onReset,
                    child: Text(AppLocalizations.of(context)!.reset),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String name, SearchFormFieldConfig field) {
    if (_isPickerField(name, field) && _isIncludedTagField(name, field)) {
      final excludedName = _findPairedExcludedFieldName();
      if (excludedName != null) {
        final excludedField = widget.config.params[excludedName];
        if (excludedField != null &&
            _isPickerField(excludedName, excludedField)) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCombinedPickerField(
              includedName: name,
              includedField: field,
              excludedName: excludedName,
              excludedField: excludedField,
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (field.type) {
        _ when _isPickerField(name, field) => _buildPickerField(name, field),
        'text' => _buildTextField(name, field),
        'tag' => _isTagChipsField(name, field)
            ? _buildTagChipsField(name, field)
            : _buildTagField(name, field),
        'select' => _buildSelectField(name, field),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildTextField(String name, SearchFormFieldConfig field) {
    return TextFormField(
      controller: _textControllers[name],
      decoration: InputDecoration(
        labelText: _labelFor(name),
        hintText: field.placeholder,
        prefixIcon: _iconFor(name),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      textInputAction: TextInputAction.search,
      onChanged: (_) => setState(() {}),
      onFieldSubmitted: (_) => _onSearch(),
    );
  }

  Widget _buildTagField(String name, SearchFormFieldConfig field) {
    return TextFormField(
      controller: _textControllers[name],
      decoration: InputDecoration(
        labelText: _labelFor(name),
        hintText: field.placeholder ?? 'Enter ${_labelFor(name).toLowerCase()}',
        prefixIcon: const Icon(Icons.tag),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      textInputAction: TextInputAction.search,
      onChanged: (_) => setState(() {}),
      onFieldSubmitted: (_) => _onSearch(),
    );
  }

  Widget _buildTagChipsField(String name, SearchFormFieldConfig field) {
    final chips = _tagChipValues[name] ?? const <String>[];
    final controller = _textControllers[name];
    final accent = _isExcludedTagField(name, field)
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;

    void addCurrentInput() {
      final value = controller?.text.trim() ?? '';
      if (value.isEmpty) return;
      final split = _splitFieldInput(_rawFieldConfig(name), value, field.type);
      if (split.isEmpty) return;

      setState(() {
        final next = <String>[...chips];
        for (final item in split) {
          if (!next.contains(item)) {
            next.add(item);
          }
        }
        _tagChipValues[name] = next;
        controller?.clear();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _labelFor(name),
            hintText: field.placeholder ?? 'Add tag and press +',
            prefixIcon: const Icon(Icons.tag),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              tooltip: AppLocalizations.of(context)!.addTag,
              onPressed: addCurrentInput,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onFieldSubmitted: (_) => addCurrentInput(),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.tagInputTip,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.9),
              ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map(
                  (chip) => InputChip(
                    label: Text(chip),
                    backgroundColor: accent.withValues(alpha: 0.14),
                    side: BorderSide(color: accent.withValues(alpha: 0.55)),
                    deleteIconColor: accent,
                    onDeleted: () {
                      setState(() {
                        _tagChipValues[name] =
                            chips.where((x) => x != chip).toList();
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPickerField(String name, SearchFormFieldConfig field) {
    final selected = _multiSelectValues[name] ?? const <_DynamicOption>[];
    final sourceId = _pickerDataSource(name, field);
    final accentColor = _pickerAccentColor(name, field, context);
    final baseIcon = _pickerLeadingIcon(name, field);
    final isLoading =
        sourceId != null && _loadingPickerSources.contains(sourceId);
    final hasLoadError =
        sourceId != null && _pickerLoadErrorBySource.containsKey(sourceId);
    final hasCachedOptions = sourceId != null &&
        (_optionCacheBySource[sourceId]?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _labelFor(name).toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openPicker(name, field),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasLoadError
                      ? Theme.of(context).colorScheme.error
                      : selected.isEmpty
                          ? Theme.of(context).colorScheme.outline
                          : accentColor.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLoadError ? Icons.warning_amber_rounded : baseIcon,
                    color: hasLoadError
                        ? Theme.of(context).colorScheme.error
                        : accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected.isEmpty
                          ? (isLoading
                              ? AppLocalizations.of(context)!.loadingOptions
                              : hasLoadError
                                  ? AppLocalizations.of(context)!.failedToLoadOptionsTap
                                  : hasCachedOptions
                                      ? (field.placeholder ??
                                          AppLocalizations.of(context)!.chooseField(_labelFor(name)))
                                      : AppLocalizations.of(context)!.tapToLoadOptions)
                          : AppLocalizations.of(context)!.nSelectedItems(selected.length),
                      style: selected.isEmpty
                          ? null
                          : TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, color: accentColor),
                ],
              ),
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected
                .map(
                  (e) => InputChip(
                    label: Text(e.label),
                    backgroundColor: accentColor.withValues(alpha: 0.14),
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.55),
                    ),
                    deleteIconColor: accentColor,
                    onDeleted: () {
                      setState(() {
                        _multiSelectValues[name] =
                            selected.where((x) => x.value != e.value).toList();
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCombinedPickerField({
    required String includedName,
    required SearchFormFieldConfig includedField,
    required String excludedName,
    required SearchFormFieldConfig excludedField,
  }) {
    final included =
        _multiSelectValues[includedName] ?? const <_DynamicOption>[];
    final excluded =
        _multiSelectValues[excludedName] ?? const <_DynamicOption>[];

    final sourceId = _pickerDataSource(includedName, includedField) ??
        _pickerDataSource(excludedName, excludedField);
    final isLoading =
        sourceId != null && _loadingPickerSources.contains(sourceId);
    final hasLoadError =
        sourceId != null && _pickerLoadErrorBySource.containsKey(sourceId);
    final hasCachedOptions = sourceId != null &&
        (_optionCacheBySource[sourceId]?.isNotEmpty ?? false);

    final includeColor =
        _pickerAccentColor(includedName, includedField, context);
    final excludeColor =
        _pickerAccentColor(excludedName, excludedField, context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.filterTags,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openCombinedPicker(
              includedName: includedName,
              includedField: includedField,
              excludedName: excludedName,
              excludedField: excludedField,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasLoadError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLoadError ? Icons.warning_amber_rounded : Icons.tune,
                    color: hasLoadError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (included.isEmpty && excluded.isEmpty)
                          ? (isLoading
                              ? AppLocalizations.of(context)!.loadingOptions
                              : hasLoadError
                                  ? AppLocalizations.of(context)!.failedToLoadOptionsTap
                                  : hasCachedOptions
                                      ? AppLocalizations.of(context)!.tapToChooseTags
                                      : AppLocalizations.of(context)!.tapToLoadOptions)
                          : AppLocalizations.of(context)!.includeExcludeCount(included.length, excluded.length),
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        if (included.isNotEmpty || excluded.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...included.map(
                (e) => InputChip(
                  label: Text(e.label),
                  avatar: Icon(Icons.add, size: 14, color: includeColor),
                  backgroundColor: includeColor.withValues(alpha: 0.14),
                  side: BorderSide(color: includeColor.withValues(alpha: 0.55)),
                  deleteIconColor: includeColor,
                  onDeleted: () {
                    setState(() {
                      _multiSelectValues[includedName] =
                          included.where((x) => x.value != e.value).toList();
                    });
                  },
                ),
              ),
              ...excluded.map(
                (e) => InputChip(
                  label: Text(e.label),
                  avatar: Icon(Icons.remove, size: 14, color: excludeColor),
                  backgroundColor: excludeColor.withValues(alpha: 0.14),
                  side: BorderSide(color: excludeColor.withValues(alpha: 0.55)),
                  deleteIconColor: excludeColor,
                  onDeleted: () {
                    setState(() {
                      _multiSelectValues[excludedName] =
                          excluded.where((x) => x.value != e.value).toList();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openCombinedPicker({
    required String includedName,
    required SearchFormFieldConfig includedField,
    required String excludedName,
    required SearchFormFieldConfig excludedField,
  }) async {
    final sourceId = _pickerDataSource(includedName, includedField) ??
        _pickerDataSource(excludedName, excludedField);
    if (sourceId == null) return;

    if (_loadingPickerSources.contains(sourceId)) return;

    final hasOptions = _optionCacheBySource[sourceId]?.isNotEmpty ?? false;
    if (!hasOptions) {
      await _loadPickerOptionsForSource(sourceId, force: true);
    }

    final options = List<_DynamicOption>.from(
      _optionCacheBySource[sourceId] ?? const <_DynamicOption>[],
    );

    if (options.isEmpty) {
      if (!mounted) return;
      final loadError = _pickerLoadErrorBySource[sourceId];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loadError == null || loadError.isEmpty
              ? AppLocalizations.of(context)!.noOptionsAvailable
              : AppLocalizations.of(context)!.failedLoadingOptions),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.retryAction,
            onPressed: () => _openCombinedPicker(
              includedName: includedName,
              includedField: includedField,
              excludedName: excludedName,
              excludedField: excludedField,
            ),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    final includeColor =
        _pickerAccentColor(includedName, includedField, context);
    final excludeColor =
        _pickerAccentColor(excludedName, excludedField, context);

    final selectedState = <String, _TagPickState>{
      for (final o
          in _multiSelectValues[includedName] ?? const <_DynamicOption>[])
        o.value: _TagPickState.include,
      for (final o
          in _multiSelectValues[excludedName] ?? const <_DynamicOption>[])
        o.value: _TagPickState.exclude,
    };

    var query = '';

    if (!mounted) return;

    final result = await showModalBottomSheet<_CombinedPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = options.where((o) {
              if (query.isEmpty) return true;
              return o.label.toLowerCase().contains(query.toLowerCase());
            }).toList();

            final grouped = <String, List<_DynamicOption>>{};
            for (final option in filtered) {
              final groupRaw = option.group?.trim();
              final key = (groupRaw == null || groupRaw.isEmpty)
                  ? 'other'
                  : groupRaw.toLowerCase();
              (grouped[key] ??= <_DynamicOption>[]).add(option);
            }

            const groupOrder = <String>[
              'format',
              'genre',
              'theme',
              'content',
              'other',
            ];

            final groupKeys = grouped.keys.toList()
              ..sort((a, b) {
                final ia = groupOrder.indexOf(a);
                final ib = groupOrder.indexOf(b);
                final ra = ia == -1 ? groupOrder.length : ia;
                final rb = ib == -1 ? groupOrder.length : ib;
                if (ra != rb) return ra.compareTo(rb);
                return a.compareTo(b);
              });

            int includeCount = 0;
            int excludeCount = 0;
            for (final state in selectedState.values) {
              if (state == _TagPickState.include) includeCount++;
              if (state == _TagPickState.exclude) excludeCount++;
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.filterTags,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: selectedState.isEmpty
                                ? null
                                : () => setSheetState(selectedState.clear),
                            child: Text(AppLocalizations.of(context)!.reset),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 16, color: includeColor),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context)!.includeCountLabel(includeCount)),
                          const SizedBox(width: 12),
                          Icon(Icons.remove_circle_outline,
                              size: 16, color: excludeColor),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context)!.excludeCountLabel(excludeCount)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: AppLocalizations.of(context)!.searchTagsHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        onChanged: (v) => setSheetState(() => query = v),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.noTagsFound,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : ListView(
                                controller: scrollController,
                                children: [
                                  for (final groupKey in groupKeys) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6, bottom: 8),
                                      child: Text(
                                        _capitalize(groupKey),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          grouped[groupKey]!.map((option) {
                                        final pickState =
                                            selectedState[option.value];
                                        final isInclude =
                                            pickState == _TagPickState.include;
                                        final isExclude =
                                            pickState == _TagPickState.exclude;
                                        final chipColor = isInclude
                                            ? includeColor
                                            : isExclude
                                                ? excludeColor
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .outlineVariant;

                                        return FilterChip(
                                          label: Text(option.label),
                                          selected: isInclude || isExclude,
                                          avatar: isInclude
                                              ? Icon(Icons.add,
                                                  size: 14, color: includeColor)
                                              : isExclude
                                                  ? Icon(Icons.remove,
                                                      size: 14,
                                                      color: excludeColor)
                                                  : null,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerLow,
                                          selectedColor:
                                              chipColor.withValues(alpha: 0.2),
                                          side: BorderSide(
                                            color: (isInclude || isExclude)
                                                ? chipColor.withValues(
                                                    alpha: 0.8)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .outlineVariant,
                                          ),
                                          checkmarkColor: chipColor,
                                          labelStyle: TextStyle(
                                            color: (isInclude || isExclude)
                                                ? chipColor
                                                : null,
                                            fontWeight: (isInclude || isExclude)
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                          onSelected: (_) {
                                            setSheetState(() {
                                              final current =
                                                  selectedState[option.value];
                                              if (current == null) {
                                                selectedState[option.value] =
                                                    _TagPickState.include;
                                              } else if (current ==
                                                  _TagPickState.include) {
                                                selectedState[option.value] =
                                                    _TagPickState.exclude;
                                              } else {
                                                selectedState
                                                    .remove(option.value);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            final include = options
                                .where((o) =>
                                    selectedState[o.value] ==
                                    _TagPickState.include)
                                .toList();
                            final exclude = options
                                .where((o) =>
                                    selectedState[o.value] ==
                                    _TagPickState.exclude)
                                .toList();
                            Navigator.of(context).pop(
                              _CombinedPickerResult(
                                included: include,
                                excluded: exclude,
                              ),
                            );
                          },
                          child: Text(AppLocalizations.of(context)!.applyWithCounts(includeCount, excludeCount)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _multiSelectValues[includedName] = result.included;
        _multiSelectValues[excludedName] = result.excluded;

        if (result.included.isNotEmpty) {
          final includedModeName =
              _findFieldNameByQueryParam('includedTagsMode');
          if (includedModeName != null &&
              _selectValues[includedModeName] == null) {
            _selectValues[includedModeName] = 'AND';
          }
        }

        if (result.excluded.isNotEmpty) {
          final excludedModeName =
              _findFieldNameByQueryParam('excludedTagsMode');
          if (excludedModeName != null &&
              _selectValues[excludedModeName] == null) {
            _selectValues[excludedModeName] = 'AND';
          }
        }
      });
    }
  }

  Future<void> _openPicker(String name, SearchFormFieldConfig field) async {
    final sourceId = _pickerDataSource(name, field);
    final accentColor = _pickerAccentColor(name, field, context);
    final pickerIcon = _pickerLeadingIcon(name, field);
    if (sourceId == null) return;

    if (_loadingPickerSources.contains(sourceId)) {
      return;
    }

    final hasOptions = _optionCacheBySource[sourceId]?.isNotEmpty ?? false;
    if (!hasOptions) {
      await _loadPickerOptionsForSource(sourceId, force: true);
    }

    final options = List<_DynamicOption>.from(
      _optionCacheBySource[sourceId] ?? const <_DynamicOption>[],
    );
    if (options.isEmpty) {
      if (!mounted) return;
      final loadError = _pickerLoadErrorBySource[sourceId];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loadError == null || loadError.isEmpty
              ? AppLocalizations.of(context)!.noOptionsAvailable
              : AppLocalizations.of(context)!.failedLoadingOptions),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.retryAction,
            onPressed: () => _openPicker(name, field),
          ),
        ),
      );
      return;
    }

    final selected = List<_DynamicOption>.from(_multiSelectValues[name] ?? []);
    final selectedValues = selected.map((e) => e.value).toSet();
    var query = '';

    if (!mounted) return;

    final result = await showModalBottomSheet<List<_DynamicOption>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = options.where((o) {
              if (query.isEmpty) return true;
              return o.label.toLowerCase().contains(query.toLowerCase());
            }).toList();

            final grouped = <String, List<_DynamicOption>>{};
            for (final option in filtered) {
              final groupRaw = option.group?.trim();
              final key = (groupRaw == null || groupRaw.isEmpty)
                  ? 'other'
                  : groupRaw.toLowerCase();
              (grouped[key] ??= <_DynamicOption>[]).add(option);
            }

            const groupOrder = <String>[
              'format',
              'genre',
              'theme',
              'content',
              'other',
            ];

            final groupKeys = grouped.keys.toList()
              ..sort((a, b) {
                final ia = groupOrder.indexOf(a);
                final ib = groupOrder.indexOf(b);
                final ra = ia == -1 ? groupOrder.length : ia;
                final rb = ib == -1 ? groupOrder.length : ib;
                if (ra != rb) return ra.compareTo(rb);
                return a.compareTo(b);
              });

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(pickerIcon, color: accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select ${_labelFor(name)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                            ),
                            onPressed: selectedValues.isEmpty
                                ? null
                                : () =>
                                    setSheetState(() => selectedValues.clear()),
                            child: Text(AppLocalizations.of(context)!.reset),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: AppLocalizations.of(context)!.searchTagsHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        onChanged: (v) => setSheetState(() => query = v),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.noTagsFound,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : ListView(
                                controller: scrollController,
                                children: [
                                  for (final groupKey in groupKeys) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6, bottom: 8),
                                      child: Text(
                                        _capitalize(groupKey),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: grouped[groupKey]!.map(
                                        (option) {
                                          final isSelected = selectedValues
                                              .contains(option.value);
                                          return FilterChip(
                                            label: Text(option.label),
                                            selected: isSelected,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerLow,
                                            selectedColor: accentColor
                                                .withValues(alpha: 0.2),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? accentColor.withValues(
                                                      alpha: 0.8)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .outlineVariant,
                                            ),
                                            checkmarkColor: accentColor,
                                            labelStyle: TextStyle(
                                              color: isSelected
                                                  ? accentColor
                                                  : null,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                            onSelected: (isSelected) {
                                              setSheetState(() {
                                                if (isSelected) {
                                                  selectedValues
                                                      .add(option.value);
                                                } else {
                                                  selectedValues
                                                      .remove(option.value);
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: _onAccentColor(accentColor),
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            final applied = options
                                .where((o) => selectedValues.contains(o.value))
                                .toList();
                            Navigator.of(context).pop(applied);
                          },
                          child: Text(AppLocalizations.of(context)!.applyWithCount(selectedValues.length)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _multiSelectValues[name] = result;
      });
    }
  }

  bool _isPickerField(String name, SearchFormFieldConfig field) {
    if (field.type != 'tag') return false;
    final rawField = _rawFieldConfig(name);
    final ui = rawField?['ui'];
    if (ui is Map<String, dynamic>) {
      return (ui['selector'] as String?) == 'picker' &&
          (ui['multi'] as bool? ?? false);
    }
    return false;
  }

  bool _isTagChipsField(String name, SearchFormFieldConfig field) {
    if (field.type != 'tag') return false;
    final rawField = _rawFieldConfig(name);
    final ui = rawField?['ui'];
    if (ui is Map<String, dynamic>) {
      return (ui['selector'] as String?) == 'chips';
    }
    return false;
  }

  bool _isIncludedTagField(String name, SearchFormFieldConfig field) {
    final lowerName = name.toLowerCase();
    final lowerQueryParam = (field.queryParam ?? '').toLowerCase();
    return lowerName.contains('included') ||
        lowerQueryParam.contains('includedtags');
  }

  bool _isExcludedTagField(String name, SearchFormFieldConfig field) {
    final lowerName = name.toLowerCase();
    final lowerQueryParam = (field.queryParam ?? '').toLowerCase();
    return lowerName.contains('excluded') ||
        lowerQueryParam.contains('excludedtags');
  }

  bool _shouldHideBecauseCombinedPicker(
      String name, SearchFormFieldConfig field) {
    if (!_isPickerField(name, field)) return false;
    if (!_isExcludedTagField(name, field)) return false;
    return _findPairedIncludedFieldName() != null;
  }

  String? _findPairedIncludedFieldName() {
    for (final entry in widget.config.params.entries) {
      if (_isIncludedTagField(entry.key, entry.value)) {
        return entry.key;
      }
    }
    return null;
  }

  String? _findPairedExcludedFieldName() {
    for (final entry in widget.config.params.entries) {
      if (_isExcludedTagField(entry.key, entry.value)) {
        return entry.key;
      }
    }
    return null;
  }

  String? _findFieldNameByQueryParam(String queryParam) {
    for (final entry in widget.config.params.entries) {
      if (entry.value.queryParam == queryParam) {
        return entry.key;
      }
    }
    return null;
  }

  IconData _pickerLeadingIcon(String name, SearchFormFieldConfig field) {
    if (_isIncludedTagField(name, field)) {
      return Icons.add_circle_outline;
    }
    if (_isExcludedTagField(name, field)) {
      return Icons.remove_circle_outline;
    }
    return Icons.local_offer_outlined;
  }

  Color _pickerAccentColor(
    String name,
    SearchFormFieldConfig field,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isIncludedTagField(name, field)) {
      return colorScheme.tertiary;
    }
    if (_isExcludedTagField(name, field)) {
      return colorScheme.error;
    }
    return colorScheme.primary;
  }

  Color _onAccentColor(Color accentColor) {
    final brightness = ThemeData.estimateBrightnessForColor(accentColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  String? _pickerDataSource(String name, SearchFormFieldConfig field) {
    final rawField = _rawFieldConfig(name);
    final ui = rawField?['ui'];
    if (ui is Map<String, dynamic>) {
      return ui['dataSource'] as String?;
    }
    return null;
  }

  Map<String, dynamic>? _rawFieldConfig(String name) {
    final rawParams = _rawSearchForm?['params'];
    if (rawParams is! Map<String, dynamic>) return null;
    final dynamic field = rawParams[name];
    if (field is Map<String, dynamic>) return field;
    return null;
  }

  String _formatFieldValue(Map<String, dynamic>? rawField, String value) {
    var result = value.trim();
    if (result.isEmpty) return result;

    final transform = (rawField?['transform'] as String? ?? '').trim();
    if (transform == 'lowercase') {
      result = result.toLowerCase();
    } else if (transform == 'uppercase') {
      result = result.toUpperCase();
    } else if (transform == 'spaceToPlus') {
      result = result.replaceAll(' ', '+');
    }

    final quoteIfContainsSpace = rawField?['quoteIfContainsSpace'] as bool?;
    if (quoteIfContainsSpace == true &&
        result.contains(' ') &&
        !result.startsWith('"') &&
        !result.endsWith('"')) {
      result = '"$result"';
    }

    final valuePrefix = (rawField?['valuePrefix'] as String? ?? '').trim();
    final valueSuffix = (rawField?['valueSuffix'] as String? ?? '').trim();
    if (valuePrefix.isNotEmpty) {
      result = '$valuePrefix$result';
    }
    if (valueSuffix.isNotEmpty) {
      result = '$result$valueSuffix';
    }

    return result;
  }

  List<String> _splitFieldInput(
    Map<String, dynamic>? rawField,
    String rawValue,
    String fieldType,
  ) {
    final value = rawValue.trim();
    if (value.isEmpty) return const <String>[];

    final multiInput = rawField?['multiInput'] as bool? ?? false;
    final shouldSplit = fieldType == 'tag' || multiInput;
    if (!shouldSplit) return <String>[value];

    return value
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _setRestoredFieldValue(
    String name,
    SearchFormFieldConfig field,
    List<String> values,
  ) {
    if (values.isEmpty) return;

    switch (field.type) {
      case 'text':
      case 'tag':
        if (_isTagChipsField(name, field)) {
          final parsed = <String>[];
          for (final value in values) {
            parsed
                .addAll(_splitFieldInput(_rawFieldConfig(name), value, 'tag'));
          }
          _tagChipValues[name] = parsed.toSet().toList();
          _textControllers[name]?.clear();
        } else {
          _textControllers[name]?.text = values.join(', ');
        }
      case 'select':
        _selectValues[name] = values.first;
      default:
        break;
    }
  }

  List<String> _collectTagFieldValues(
    String name,
    Map<String, dynamic>? rawField,
  ) {
    final field = widget.config.params[name];
    if (field == null || field.type != 'tag') return const <String>[];

    final values = <String>[];
    if (_isTagChipsField(name, field)) {
      values.addAll(_tagChipValues[name] ?? const <String>[]);

      final trailingInput = _textControllers[name]?.text.trim() ?? '';
      if (trailingInput.isNotEmpty) {
        values.addAll(_splitFieldInput(rawField, trailingInput, field.type));
      }

      return values;
    }

    final val = _textControllers[name]?.text.trim() ?? '';
    if (val.isNotEmpty) {
      values.addAll(_splitFieldInput(rawField, val, field.type));
    }

    return values;
  }

  List<String> _collectEncodedQueryParts({List<FilterItem>? selectedTagItems}) {
    final parts = <String>[];
    final partsByParam = <String, List<String>>{};
    final joinModeByParam = <String, String>{};

    void addParamValue(String queryParam, String value, {String? joinMode}) {
      final normalized = value.trim();
      if (normalized.isEmpty) return;
      (partsByParam[queryParam] ??= <String>[]).add(normalized);
      if (joinMode != null && joinMode.isNotEmpty) {
        joinModeByParam[queryParam] = joinMode;
      }
    }

    for (final entry in widget.config.params.entries) {
      final name = entry.key;
      final field = entry.value;
      final qp = field.queryParam;
      if (qp == null) continue;
      final rawField = _rawFieldConfig(name);
      final joinMode = (rawField?['joinMode'] as String?)?.trim();

      if (_isPickerField(name, field)) {
        final selected = _multiSelectValues[name] ?? const <_DynamicOption>[];
        for (final option in selected) {
          final formatted = _formatFieldValue(rawField, option.value);
          addParamValue(qp, formatted, joinMode: joinMode);

          if (selectedTagItems != null) {
            selectedTagItems.add(
              FilterItem(
                value: option.label,
                isExcluded: _isExcludedTagField(name, field),
              ),
            );
          }
        }
        continue;
      }

      switch (field.type) {
        case 'text':
          final val = _textControllers[name]?.text.trim() ?? '';
          if (val.isNotEmpty) {
            final splitValues = _splitFieldInput(rawField, val, field.type);
            for (final item in splitValues) {
              final formatted = _formatFieldValue(rawField, item);
              addParamValue(qp, formatted, joinMode: joinMode);
            }
          }
        case 'tag':
          final values = _collectTagFieldValues(name, rawField);
          for (final item in values) {
            final formatted = _formatFieldValue(rawField, item);
            addParamValue(qp, formatted, joinMode: joinMode);
          }
        case 'select':
          final val = _selectValues[name];
          if (val != null && val.isNotEmpty) {
            final formatted = _formatFieldValue(rawField, val);
            addParamValue(qp, formatted, joinMode: joinMode);
          }
        default:
          break;
      }
    }

    partsByParam.forEach((queryParam, values) {
      if (values.isEmpty) return;
      final mode = (joinModeByParam[queryParam] ?? '').toLowerCase();
      if (mode == 'space') {
        final joined = values.join(' ');
        parts.add(
          '${Uri.encodeComponent(queryParam)}=${Uri.encodeComponent(joined)}',
        );
        return;
      }

      for (final value in values) {
        parts.add(
          '${Uri.encodeComponent(queryParam)}=${Uri.encodeComponent(value)}',
        );
      }
    });

    return parts;
  }

  Widget _buildQueryPreviewCard() {
    final parts = _collectEncodedQueryParts();
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    final rawQuery = 'raw:${parts.join('&')}';
    final parsed = _parseRaw(rawQuery.substring(4));
    final queryExpression = (parsed['q'] ?? const <String>[]).join(' ').trim();
    if (queryExpression.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.previewQuery,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            queryExpression,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _restoreJoinedParamGroup(
    String queryParam,
    String joinedValue,
    List<MapEntry<String, SearchFormFieldConfig>> fields,
  ) {
    final tokens = _tokenizeQueryExpression(joinedValue);
    final consumed = List<bool>.filled(tokens.length, false);

    for (final entry in fields) {
      final name = entry.key;
      final field = entry.value;
      final rawField = _rawFieldConfig(name);

      if (_isPickerField(name, field)) continue;

      final hasAffix =
          ((rawField?['valuePrefix'] as String?)?.isNotEmpty ?? false) ||
              ((rawField?['valueSuffix'] as String?)?.isNotEmpty ?? false);
      if (!hasAffix) continue;

      final matched = <String>[];
      for (var i = 0; i < tokens.length; i++) {
        if (consumed[i]) continue;
        final extracted = _extractFieldCoreFromToken(tokens[i], rawField);
        if (extracted == null) continue;
        matched.add(extracted);
        consumed[i] = true;
      }

      if (matched.isNotEmpty) {
        _setRestoredFieldValue(name, field, matched);
      }
    }

    final leftovers = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      if (!consumed[i]) leftovers.add(tokens[i]);
    }

    if (leftovers.isEmpty) return;

    MapEntry<String, SearchFormFieldConfig>? fallback;
    for (final entry in fields) {
      final name = entry.key;
      final field = entry.value;
      final rawField = _rawFieldConfig(name);
      if (_isPickerField(name, field)) continue;
      if (field.type != 'text' && field.type != 'tag') continue;

      final hasAffix =
          ((rawField?['valuePrefix'] as String?)?.isNotEmpty ?? false) ||
              ((rawField?['valueSuffix'] as String?)?.isNotEmpty ?? false);
      if (!hasAffix) {
        if (name == 'query') {
          fallback = entry;
          break;
        }
        fallback ??= entry;
      }
    }

    if (fallback != null) {
      _setRestoredFieldValue(
        fallback.key,
        fallback.value,
        <String>[leftovers.join(' ')],
      );
    }
  }

  List<String> _tokenizeQueryExpression(String expression) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (final rune in expression.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '"') {
        inQuotes = !inQuotes;
        buffer.write(ch);
        continue;
      }

      if (!inQuotes && ch.trim().isEmpty) {
        final token = buffer.toString().trim();
        if (token.isNotEmpty) tokens.add(token);
        buffer.clear();
        continue;
      }

      buffer.write(ch);
    }

    final last = buffer.toString().trim();
    if (last.isNotEmpty) tokens.add(last);

    return tokens;
  }

  String? _extractFieldCoreFromToken(
    String token,
    Map<String, dynamic>? rawField,
  ) {
    var current = token.trim();
    if (current.isEmpty) return null;

    final prefix = (rawField?['valuePrefix'] as String? ?? '').trim();
    final suffix = (rawField?['valueSuffix'] as String? ?? '').trim();

    if (prefix.isNotEmpty) {
      if (!current.startsWith(prefix)) return null;
      current = current.substring(prefix.length);
    }

    if (suffix.isNotEmpty) {
      if (!current.endsWith(suffix)) return null;
      current = current.substring(0, current.length - suffix.length);
    }

    if (current.length >= 2 &&
        current.startsWith('"') &&
        current.endsWith('"')) {
      current = current.substring(1, current.length - 1);
    }

    return current.trim().isEmpty ? null : current.trim();
  }

  dynamic _extractByPath(dynamic node, String path) {
    if (path.isEmpty) return node;
    dynamic current = node;
    for (final seg in path.split('.')) {
      if (current is Map<String, dynamic>) {
        current = current[seg];
      } else if (current is Map) {
        current = current[seg];
      } else {
        return null;
      }
    }
    return current;
  }

  Widget _buildSelectField(String name, SearchFormFieldConfig field) {
    final options = field.options ?? [];
    final selected = _selectValues[name];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _labelFor(name).toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            // "All" chip = clear selection
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.all),
              selected: selected == null,
              onSelected: (_) => setState(() => _selectValues[name] = null),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            for (final opt in options)
              ChoiceChip(
                label: Text(_capitalize(opt)),
                selected: selected == opt,
                onSelected: (v) =>
                    setState(() => _selectValues[name] = v ? opt : null),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              ),
          ],
        ),
      ],
    );
  }

  String _labelFor(String name) => switch (name) {
        _ when _rawFieldConfig(name)?['label'] is String =>
          (_rawFieldConfig(name)?['label'] as String).trim().isEmpty
              ? _capitalize(name)
              : (_rawFieldConfig(name)?['label'] as String),
        'query' => AppLocalizations.of(context)!.searchLabel,
        'genre' => AppLocalizations.of(context)!.genreLabel,
        'status' => AppLocalizations.of(context)!.statusLabel,
        'order' => AppLocalizations.of(context)!.orderBy,
        'author' => AppLocalizations.of(context)!.authorLabel,
        'artist' => AppLocalizations.of(context)!.artistFilterLabel,
        _ => _capitalize(name),
      };

  Icon _iconFor(String name) => switch (name) {
        'query' => const Icon(Icons.search),
        'genre' => const Icon(Icons.category),
        'author' => const Icon(Icons.person),
        'artist' => const Icon(Icons.brush),
        _ => const Icon(Icons.edit),
      };

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _DynamicOption {
  const _DynamicOption({
    required this.value,
    required this.label,
    this.group,
  });

  final String value;
  final String label;
  final String? group;
}

enum _TagPickState {
  include,
  exclude,
}

class _CombinedPickerResult {
  const _CombinedPickerResult({
    required this.included,
    required this.excluded,
  });

  final List<_DynamicOption> included;
  final List<_DynamicOption> excluded;
}
