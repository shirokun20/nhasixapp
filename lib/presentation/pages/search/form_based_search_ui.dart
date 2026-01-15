import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/utils/tag_data_manager.dart' hide TagType;
import 'package:nhasixapp/domain/entities/search_filter.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';

class FormBasedSearchUI extends StatefulWidget {
  final SearchConfig config;
  final String sourceId;

  const FormBasedSearchUI({
    super.key,
    required this.config,
    required this.sourceId,
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
  final Map<String, List<String>> _loadedTags = {};
  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadTagsIfNeeded();
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
  }

  Future<void> _restoreSavedFilter() async {
    try {
      final savedFilterJson =
          await getIt<LocalDataSource>().getLastSearchFilter();
      if (savedFilterJson == null) return;

      final savedFilter = SearchFilter.fromJson(savedFilterJson);
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
        if (group.tagType != null) {
          final tags = await getIt<TagDataManager>().getTagsByType(
            group.tagType!,
            source: widget.sourceId,
          );

          if (mounted) {
            setState(() {
              _loadedTags[group.name] = tags.map((t) => t.name).toList();
            });
          }
        }
      }
    } catch (e) {
      _logger.e('Failed to load tags: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTags = false);
    }
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

    // 1. Text Fields - only include non-empty values after trimming
    _controllers.forEach((name, controller) {
      final trimmedValue = controller.text.trim();
      if (trimmedValue.isNotEmpty) {
        params.add(
            '${Uri.encodeComponent(name)}=${Uri.encodeComponent(trimmedValue)}');
      }
    });

    // 2. Radio Values - only include non-empty values
    _radioValues.forEach((name, value) {
      final trimmedValue = value.trim();
      if (trimmedValue.isNotEmpty) {
        params.add(
            '${Uri.encodeComponent(name)}=${Uri.encodeComponent(trimmedValue)}');
      }
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
      await getIt<LocalDataSource>().saveSearchFilter(filter.toJson());

      if (mounted) {
        // Return true to indicate search was applied
        context.pop(true);
      }
    } catch (e) {
      _logger.e('Failed to save search filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply search: $e')),
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
                      label: const Text('SEARCH'),
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
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
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

    // Only show if we have tags (or if we don't expect to load them)
    if (availableTags.isEmpty) {
      if (!group.loadFromTags) return const SizedBox.shrink();
      if (_isLoadingTags) return const SizedBox.shrink();
      return const SizedBox.shrink();
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
        borderRadius: BorderRadius.circular(12),
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
                      color: Theme.of(context).primaryColor,
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
                      ? 'Show Less'
                      : 'Show All (${availableTags.length})'),
                )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleTags.map((tag) {
              final isSelected = selectedValues.contains(tag);
              return FilterChip(
                label: Text(tag),
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
                      _checkboxValues[group.name]!.add(tag);
                    } else {
                      _checkboxValues[group.name]!.remove(tag);
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
