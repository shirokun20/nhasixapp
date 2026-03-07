import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';

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

  // Keyed by field logical name (e.g. "query", "status", "order", "genre")
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _selectValues = {};

  @override
  void initState() {
    super.initState();
    _initFields();
    context
        .read<SearchBloc>()
        .add(SearchInitializeEvent(sourceId: widget.sourceId));
    _restoreSaved();
  }

  void _initFields() {
    for (final entry in widget.config.params.entries) {
      final field = entry.value;
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

  Future<void> _restoreSaved() async {
    try {
      final savedJson =
          await getIt<LocalDataSource>().getLastSearchFilter(widget.sourceId);
      if (savedJson == null) return;

      final saved = SearchFilter.fromJson(savedJson);
      final query = saved.query;
      if (query == null || !query.startsWith('raw:')) return;

      final parsed = _parseRaw(query.substring(4));

      for (final entry in widget.config.params.entries) {
        final field = entry.value;
        final qp = field.queryParam;
        if (qp == null) continue;

        final val = parsed[qp]?.first;
        if (val == null) continue;

        switch (field.type) {
          case 'text':
          case 'tag':
            _textControllers[entry.key]?.text = val;
          case 'select':
            if (mounted) setState(() => _selectValues[entry.key] = val);
          default:
            break;
        }
      }
    } catch (e) {
      _logger.w('DynamicFormSearchUI: failed to restore filter: $e');
    }
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

    final parts = <String>[];

    for (final entry in widget.config.params.entries) {
      final name = entry.key;
      final field = entry.value;
      final qp = field.queryParam;
      if (qp == null) continue;

      switch (field.type) {
        case 'text':
        case 'tag':
          final val = _textControllers[name]?.text.trim() ?? '';
          if (val.isNotEmpty) {
            parts.add('${Uri.encodeComponent(qp)}=${Uri.encodeComponent(val)}');
          }
        case 'select':
          final val = _selectValues[name];
          if (val != null && val.isNotEmpty) {
            parts.add('${Uri.encodeComponent(qp)}=${Uri.encodeComponent(val)}');
          }
        default:
          break; // 'page' handled by adapter internally
      }
    }

    final rawQuery = parts.isNotEmpty ? 'raw:${parts.join('&')}' : '';
    final filter = SearchFilter(query: rawQuery, tags: []);

    try {
      await getIt<LocalDataSource>()
          .saveSearchFilter(widget.sourceId, filter.toJson());
      if (mounted) context.pop(true);
    } catch (e) {
      _logger.e('DynamicFormSearchUI: failed to save filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply search: $e')),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleFields = widget.config.params.entries
        .where((e) => e.value.type != 'page')
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
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _onSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('SEARCH'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _onReset,
                    child: const Text('Reset'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (field.type) {
        'text' => _buildTextField(name, field),
        'tag' => _buildTagField(name, field),
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
      onFieldSubmitted: (_) => _onSearch(),
    );
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
              label: const Text('All'),
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
        'query' => 'Search',
        'genre' => 'Genre',
        'status' => 'Status',
        'order' => 'Order by',
        'author' => 'Author',
        'artist' => 'Artist',
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
