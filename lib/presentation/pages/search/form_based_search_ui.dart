import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:kuron_core/kuron_core.dart' show Tag;
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/constants/design_tokens.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/utils/tag_data_manager.dart' hide TagType;
import 'package:nhasixapp/domain/entities/search_filter.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';

import 'package:nhasixapp/l10n/app_localizations.dart';

class FormBasedSearchUI extends StatefulWidget {
  final SearchConfig config;
  final String sourceId;
  final int reloadSignal;

  const FormBasedSearchUI({
    super.key,
    required this.config,
    required this.sourceId,
    this.reloadSignal = 0,
  });

  @override
  State<FormBasedSearchUI> createState() => _FormBasedSearchUIState();
}

class _FormBasedSearchUIState extends State<FormBasedSearchUI> {
  final _formKey = GlobalKey<FormState>();
  final _logger = getIt<Logger>();

  // Form State
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _radioValues = {};
  final Map<String, List<String>> _checkboxValues = {};
  final Map<String, bool> _checkboxExpanded = {};

  // Loaded tag data
  final Map<String, List<_TagOption>> _loadedTags = {};
  final Map<String, String> _tagLoadErrors = {};
  bool _isLoadingTags = true;
  int _lastReloadSignal = 0;

  @override
  void initState() {
    super.initState();
    _lastReloadSignal = widget.reloadSignal;
    _initializeForm();
    _loadTagsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FormBasedSearchUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadSignal != oldWidget.reloadSignal &&
        widget.reloadSignal != _lastReloadSignal) {
      _lastReloadSignal = widget.reloadSignal;
      _reloadTags();
    }
  }

  void _initializeForm() {
    // Init Text Fields
    for (var field in widget.config.textFields ?? []) {
      _controllers[field.name] = TextEditingController();
    }

    // Init Radio Groups with defaults
    for (var group in widget.config.radioGroups ?? []) {
      // Explicitly typed to avoid runtime errors
      final List<RadioOptionConfig> options = group.options;
      final RadioOptionConfig defaultOpt = options.firstWhere(
          (RadioOptionConfig o) => o.isDefault,
          orElse: () => options.first);
      _radioValues[group.name] = defaultOpt.value;
    }

    // Init Checkboxes
    for (var group in widget.config.checkboxGroups ?? []) {
      _checkboxValues[group.name] = [];
      _checkboxExpanded[group.name] = group.displayMode == 'expanded';
    }

    // Try to restore from saved filter
    _restoreSavedFilter();

    // Initialize SearchBloc with current source
    context
        .read<SearchBloc>()
        .add(SearchInitializeEvent(sourceId: widget.sourceId));
  }

  Future<void> _restoreSavedFilter() async {
    try {
      final savedFilter = await getIt<UserDataRepository>()
          .getLastSearchFilter(widget.sourceId);
      if (savedFilter == null) return;

      final query = savedFilter.query;

      // Only parse if it's a raw: format from FormBasedSearchUI
      if (query != null && query.startsWith('raw:')) {
        final rawParams = query.substring(4); // Remove 'raw:'
        final parsedParams = _parseRawParams(rawParams);

        // Restore text fields
        for (var entry in parsedParams.entries) {
          if (_controllers.containsKey(entry.key)) {
            _controllers[entry.key]!.text = entry.value.first;
          }
        }

        // Restore radio values
        for (var entry in parsedParams.entries) {
          if (_radioValues.containsKey(entry.key) && entry.value.isNotEmpty) {
            _radioValues[entry.key] = entry.value.first;
          }
        }

        // Restore checkbox values
        for (var group in widget.config.checkboxGroups ?? []) {
          // Match by paramName (e.g., 'genre[]')
          final paramKey = group.paramName;
          if (parsedParams.containsKey(paramKey)) {
            _checkboxValues[group.name] = parsedParams[paramKey]!;
          }
        }

        if (mounted) setState(() {});
      }
    } catch (e) {
      _logger.w('Failed to restore saved filter: $e');
    }
  }

  /// Parse raw URL params string into a map of key -> list of values
  /// Handles both single values and array params like genre[]=x&genre[]=y
  Map<String, List<String>> _parseRawParams(String rawParams) {
    final result = <String, List<String>>{};

    for (var param in rawParams.split('&')) {
      if (param.isEmpty) continue;

      final parts = param.split('=');
      if (parts.length < 2) continue;

      final key = Uri.decodeComponent(parts[0]);
      final value = Uri.decodeComponent(parts.sublist(1).join('='));

      if (result.containsKey(key)) {
        result[key]!.add(value);
      } else {
        result[key] = [value];
      }
    }

    return result;
  }

  Future<void> _loadTagsIfNeeded() async {
    final groupsToLoad =
        widget.config.checkboxGroups?.where((g) => g.loadFromTags).toList() ??
            [];
    if (groupsToLoad.isEmpty) {
      if (mounted) setState(() => _isLoadingTags = false);
      return;
    }

    try {
      _logger.i(
          'FormBasedSearchUI: Loading tags for ${groupsToLoad.length} groups');

      for (var group in groupsToLoad) {
        try {
          final List<_TagOption> options = await _loadTagsForGroup(group);
          if (!mounted) continue;
          setState(() {
            _loadedTags[group.name] = options;
            _tagLoadErrors.remove(group.name);
          });
        } catch (e) {
          _logger.w(
            'FormBasedSearchUI: Failed to load tags for ${group.name}',
            error: e,
          );
          if (!mounted) continue;
          setState(() {
            _loadedTags.remove(group.name);
            _tagLoadErrors[group.name] = e.toString();
          });
        }
      }
    } catch (e) {
      _logger.e('Failed to load tags: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTags = false);
    }
  }

  Future<void> _reloadTags() async {
    final groupsToLoad =
        widget.config.checkboxGroups?.where((g) => g.loadFromTags).toList() ??
            [];
    if (groupsToLoad.isEmpty) return;

    setState(() {
      _isLoadingTags = true;
      for (final group in groupsToLoad) {
        _loadedTags.remove(group.name);
        _tagLoadErrors.remove(group.name);
      }
    });

    await _loadTagsIfNeeded();
  }

  Future<List<_TagOption>> _loadTagsForGroup(CheckboxGroupConfig group) async {
    final tagManager = getIt<TagDataManager>();
    if (group.tagSourceUrl != null && group.tagSourceUrl!.isNotEmpty) {
      final tags = await tagManager.loadTagsFromUrl(group.tagSourceUrl!);
      return _mapTags(tags);
    }

    if (group.tagType != null) {
      final tags = await tagManager.getTagsByType(
        group.tagType!,
        source: widget.sourceId,
      );
      if (tags.isEmpty) {
        throw StateError(
          'No tags available for ${group.name} from source cache',
        );
      }
      return _mapTags(tags);
    }

    throw StateError('Missing tagSourceUrl and tagType for ${group.name}');
  }

  List<_TagOption> _mapTags(List<Tag> tags) {
    return tags
        .map(
          (t) => _TagOption(
            label: t.name,
            // Use slug as query value; fallback to name if slug missing.
            value: (t.slug ?? '').isNotEmpty ? t.slug! : t.name,
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _onSearch() async {
    if (!_formKey.currentState!.validate()) return;

    // Build form query string using "raw:" prefix for parameter-based search
    // Format: "raw:key=value&key2=value"
    final params = <String>[];

    // 1. Text Fields - keep keys even when empty for WordPress advanced-search
    // compatibility (some providers expect full query shape).
    _controllers.forEach((name, controller) {
      final trimmedValue = controller.text.trim();
      params.add(
          '${Uri.encodeComponent(name)}=${Uri.encodeComponent(trimmedValue)}');
    });

    // 2. Radio Values - keep keys even when value is empty (e.g. status/type)
    _radioValues.forEach((name, value) {
      final trimmedValue = value.trim();
      params.add(
          '${Uri.encodeComponent(name)}=${Uri.encodeComponent(trimmedValue)}');
    });

    // 3. Checkboxes (Tags/Genres)
    // Iterate config groups to get correct paramName
    for (var group in widget.config.checkboxGroups ?? []) {
      final values = _checkboxValues[group.name];
      if (values != null && values.isNotEmpty) {
        for (var val in values) {
          // paramName (e.g., 'genre[]') is used as key
          params.add(
              '${Uri.encodeComponent(group.paramName)}=${Uri.encodeComponent(val)}');
        }
      }
    }

    // Construct the raw query string
    final queryString = params.isNotEmpty ? 'raw:${params.join('&')}' : '';

    // Build Filter
    // Pass empty tags list because they are now encoded in the raw query string
    final filter = SearchFilter(
      query: queryString,
      tags: [],
    );

    try {
      // Save filter to local storage for MainScreen to pick up
      await getIt<UserDataRepository>()
          .saveSearchFilter(widget.sourceId, filter);

      if (mounted) {
        // Return true to indicate search was applied
        context.pop(true);
      }
    } catch (e) {
      _logger.e('Failed to save search filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedToApplySearch(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Form Section
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoadingTags) const AppLinearProgressIndicator(),

                    // textFields
                    ...?widget.config.textFields?.map(_buildTextField),
                    const SizedBox(height: 16),

                    // radioGroups
                    ...?widget.config.radioGroups?.map(_buildRadioGroup),
                    const SizedBox(height: 16),

                    // checkboxGroups
                    ...?widget.config.checkboxGroups?.map(_buildCheckboxGroup),

                    const SizedBox(height: 24),

                    // Search Button
                    ElevatedButton.icon(
                      onPressed: _onSearch,
                      icon: const Icon(Icons.search),
                      label: Text(AppLocalizations.of(context)!.search),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[field.name],
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.placeholder,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          prefixIcon: _getIconForField(field.name),
        ),
        keyboardType:
            field.type == 'number' ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Icon _getIconForField(String name) {
    switch (name.toLowerCase()) {
      case 'title':
        return const Icon(Icons.title);
      case 'author':
        return const Icon(Icons.person);
      case 'artist':
        return const Icon(Icons.brush);
      case 'year':
      case 'yearx':
        return const Icon(Icons.calendar_today);
      default:
        return const Icon(Icons.edit);
    }
  }

  Widget _buildRadioGroup(RadioGroupConfig group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.options.map((option) {
              final isSelected = _radioValues[group.name] == option.value;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _radioValues[group.name] = option.value;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGroup(CheckboxGroupConfig group) {
    final availableTags = _loadedTags[group.name] ?? [];
    final selectedValues = _checkboxValues[group.name] ?? [];
    final isExpanded = _checkboxExpanded[group.name] ?? false;
    final loadError = _tagLoadErrors[group.name];

    if (availableTags.isEmpty) {
      if (!group.loadFromTags) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (_isLoadingTags)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingTags)
              Text(
                AppLocalizations.of(context)!.loadingOptions,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              if (loadError != null) ...[
                Text(
                  'Failed to load options',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  loadError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                AppLocalizations.of(context)!.failedToLoadOptionsTap,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _reloadTags,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.tapToLoadOptions),
              ),
            ],
          ],
        ),
      );
    }

    // Limit visible tags if not expanded
    final visibleTags =
        isExpanded ? availableTags : availableTags.take(12).toList();

    // Check if any selected are hidden, if so, expand automatically or include them?
    // For now simple logic.

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (availableTags.length > 12)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _checkboxExpanded[group.name] = !isExpanded;
                    });
                  },
                  child: Text(isExpanded
                      ? AppLocalizations.of(context)!.showLess
                      : AppLocalizations.of(context)!
                          .showAllCount(availableTags.length)),
                )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleTags.map((tag) {
              final isSelected = selectedValues.contains(tag.value);
              return FilterChip(
                label: Text(tag.label),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _checkboxValues[group.name]!.add(tag.value);
                    } else {
                      _checkboxValues[group.name]!.remove(tag.value);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TagOption {
  final String label;
  final String value;

  const _TagOption({required this.label, required this.value});
}
