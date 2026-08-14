import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/ai_settings/ai_settings_cubit.dart';
import 'settings_theme_widgets.dart';

/// Dedicated AI provider (BYOK) manager: list, CRUD, set-default, validate.
/// Reuses [AiSettingsCubit] — no separate cubit.
class ProviderManagerScreen extends StatelessWidget {
  const ProviderManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiSettingsCubit(
        providerRepository: getIt(),
        preferencesRepository: getIt(),
        providerFactory: getIt(),
        cacheRepository: getIt(),
        logger: getIt(),
        localizations: AppLocalizations.of(context),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('AI Providers')),
        body: const _ProviderManagerBody(),
      ),
    );
  }
}

class _ProviderManagerBody extends StatelessWidget {
  const _ProviderManagerBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AiSettingsCubit, AiSettingsState>(
      builder: (context, state) {
        if (state is AiSettingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AiSettingsError) {
          return Center(child: Text(state.message));
        }
        if (state is! AiSettingsLoaded) {
          return const SizedBox.shrink();
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            buildSettingsCard([
              for (final p in state.providers) ...[
                _ProviderTile(provider: p),
                if (p != state.providers.last) buildSettingsDivider(theme),
              ],
            ], theme),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showProviderForm(context, null),
                icon: const Icon(Icons.add),
                label: Text(l10n.aiAddProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProviderForm(BuildContext context, AiProviderConfig? provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      // Modal sheets live on the root navigator and lose the screen-scoped
      // cubit — re-provide by value.
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<AiSettingsCubit>(),
        child: _ProviderFormSheet(provider: provider),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider});

  final AiProviderConfig provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZen = provider.id == 'zen-builtin';
    final cubit = context.read<AiSettingsCubit>();
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: InkWell(
          onTap: () => cubit.setDefault(provider.id),
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            provider.isDefault
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: provider.isDefault
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        title: Text(
          provider.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${provider.type.displayName} • ${provider.model}'
          '${isZen ? ' • ${AppLocalizations.of(context)!.aiNoKeyNeeded}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: () {
          final sheetCtx = context;
          showModalBottomSheet<void>(
            context: sheetCtx,
            isScrollControlled: true,
            backgroundColor: theme.colorScheme.surfaceContainer,
            builder: (sheetContext) => BlocProvider.value(
              value: cubit,
              child: _ProviderFormSheet(provider: provider),
            ),
          );
        },
      ),
    );
  }
}

class _ProviderFormSheet extends StatefulWidget {
  const _ProviderFormSheet({required this.provider});

  final AiProviderConfig? provider;

  @override
  State<_ProviderFormSheet> createState() => _ProviderFormSheetState();
}

class _ProviderFormSheetState extends State<_ProviderFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _keyController;
  late final TextEditingController _modelController;
  late final TextEditingController _baseUrlController;
  late AiProviderType _type;
  bool _isTesting = false;
  String? _testResult;
  bool _testRan = false; // distinguishes "valid (null)" from "not yet tested"

  bool get _isEditing => widget.provider != null;

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _type = p?.type ?? AiProviderType.openCodeGo;
    _nameController = TextEditingController(text: p?.displayName ?? '');
    _keyController = TextEditingController(text: p?.apiKey ?? '');
    _modelController =
        TextEditingController(text: p?.model ?? p?.type.defaultModel ?? '');
    _baseUrlController = TextEditingController(text: p?.baseUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  AiProviderConfig _buildConfig() {
    final existing = widget.provider;
    return AiProviderConfig(
      id: existing?.id ?? 'prov_${DateTime.now().millisecondsSinceEpoch}',
      displayName: _nameController.text.trim().isEmpty
          ? _type.displayName
          : _nameController.text.trim(),
      type: _type,
      model: _modelController.text.trim().isEmpty
          ? (_type.defaultModel ?? '')
          : _modelController.text.trim(),
      apiKey: _keyController.text.trim().isEmpty
          ? null
          : _keyController.text.trim(),
      baseUrl: _type == AiProviderType.custom
          ? (_baseUrlController.text.trim().isEmpty
              ? null
              : _baseUrlController.text.trim())
          : existing?.baseUrl,
      isDefault: existing?.isDefault ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AiSettingsCubit>();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? l10n.aiEditProvider : l10n.aiAddProvider,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              DropdownButtonFormField<AiProviderType>(
                initialValue: _type,
                decoration: InputDecoration(labelText: l10n.aiProviderType),
                items: AiProviderType.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.displayName)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _type = v;
                    _modelController.text = v.defaultModel ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.aiDisplayName),
            ),
            const SizedBox(height: 12),
            if (!_isEditing || widget.provider!.id != 'zen-builtin') ...[
              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.aiApiKey,
                  hintText: l10n.aiApiKeyHint,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _modelController,
              decoration: InputDecoration(labelText: l10n.aiModel),
            ),
            if (_type == AiProviderType.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _baseUrlController,
                decoration: InputDecoration(labelText: l10n.aiBaseUrl),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting
                        ? null
                        : () async {
                            setState(() {
                              _isTesting = true;
                              _testResult = null;
                              _testRan = false;
                            });
                            final result =
                                await cubit.validateProvider(_buildConfig());
                            if (!context.mounted) return;
                            setState(() {
                              _isTesting = false;
                              _testResult = result;
                              _testRan = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result == null
                                    ? l10n.aiCheckIconD(_modelController.text)
                                    : '✗ ${result.substring(0, result.length > 100 ? 100 : result.length)}'),
                              ),
                            );
                          },
                    child: Text(_isTesting ? l10n.aiTesting : l10n.aiTestKey),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isEditing && !_isEditingZenOnly)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () async {
                        await cubit.deleteProvider(widget.provider!.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(l10n.aiDelete),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () async {
                      final config = _buildConfig();
                      await cubit.saveProvider(config);
                      // New provider becomes the active (default) one.
                      if (!_isEditing) {
                        await cubit.setDefault(config.id);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(l10n.aiSave),
                  ),
                ),
              ],
            ),
            if (_testRan) ...[
              const SizedBox(height: 12),
              Text(
                _testResult == null ? l10n.aiValidKey : '✗ $_testResult',
                style: TextStyle(
                  color: _testResult == null
                      ? Colors.green
                      : theme.colorScheme.error,
                ),
              ),
            ],
            if (!_isEditing) ...[
              const SizedBox(height: 12),
              Text(
                l10n.aiDefaultModel(_type.defaultModel ?? l10n.aiCustomTypeDefault),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _isEditingZenOnly =>
      _isEditing && widget.provider!.id == 'zen-builtin';
}