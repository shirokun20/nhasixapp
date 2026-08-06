import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/ai_settings/ai_settings_cubit.dart';
import 'settings_theme_widgets.dart';
import 'glossary_screen.dart';

/// AI Translation settings: provider management, target language,
/// translation style, cache clearing, privacy disclosure.
class AiSettingsScreen extends StatelessWidget {
  const AiSettingsScreen({super.key});

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
        appBar: AppBar(title: const Text('AI Translation')),
        body: const _AiSettingsBody(),
      ),
    );
  }
}

class _AiSettingsBody extends StatelessWidget {
  const _AiSettingsBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        final cubit = context.read<AiSettingsCubit>();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            buildSettingsSectionHeader(
                Icons.auto_awesome_outlined, 'PROVIDERS', theme),
            const SizedBox(height: 12),
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
                onPressed: () => _showAddProviderSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Provider'),
              ),
            ),
            const SizedBox(height: 24),
            buildSettingsSectionHeader(Icons.translate, 'TRANSLATION', theme),
            const SizedBox(height: 12),
            buildSettingsCard([
              buildSettingsDropdownTile<String>(
                context: context,
                title: 'Target Language',
                subtitle: 'Language AI translates into',
                value: state.targetLang,
                items: AiSettingsCubit.supportedLanguages
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) cubit.setTargetLanguage(v);
                },
                theme: theme,
              ),
              buildSettingsDivider(theme),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text('Translation Style',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  state.style.instruction,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: DropdownButton<TranslationStyle>(
                  value: state.style,
                  underline: const SizedBox(),
                  items: TranslationStyle.values
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    if (v == TranslationStyle.kasar) {
                      _confirmKasarStyle(context, cubit, v);
                    } else {
                      cubit.setTranslationStyle(v);
                    }
                  },
                ),
              ),
              buildSettingsDivider(theme),
              SwitchListTile(
                title: const Text('Skip SFX bubbles'),
                subtitle:
                    const Text('Skip sound-effect-only bubbles (default on)'),
                value: state.skipSfx,
                onChanged: (v) => cubit.setSkipSfx(v),
              ),
            ], theme),
            const SizedBox(height: 24),
            buildSettingsSectionHeader(
                Icons.privacy_tip_outlined, 'PRIVACY', theme),
            const SizedBox(height: 12),
            buildSettingsCard([
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Disclosure'),
                subtitle: const Text(
                    'Images are sent to your chosen provider. Kuron does not relay your data.'),
              ),
              buildSettingsDivider(theme),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear Translation Cache'),
                subtitle: const Text('Delete all cached page translations'),
                onTap: () async {
                  await cubit.clearCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Translation cache cleared')),
                    );
                  }
                },
              ),
              buildSettingsDivider(theme),
              ListTile(
                leading: const Icon(Icons.bookmarks_outlined),
                title: const Text('Learning Glossary'),
                subtitle: const Text('Review saved vocabulary'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const GlossaryScreen()),
                ),
              ),
            ], theme),
          ],
        );
      },
    );
  }

  void _confirmKasarStyle(
      BuildContext context, AiSettingsCubit cubit, TranslationStyle style) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mode Kasar (18+)'),
        content:
            const Text('Mode Kasar menggunakan kata-kata keras. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.setTranslationStyle(style);
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showAddProviderSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      // Wrap in BlocProvider.value: modal sheets live on the root navigator
      // and lose access to the screen-scoped AiSettingsCubit.
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<AiSettingsCubit>(),
        child: _ProviderFormSheet(provider: null),
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
          '${isZen ? ' • No key needed' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.colorScheme.surfaceContainer,
          builder: (sheetContext) => BlocProvider.value(
            value: cubit,
            child: _ProviderFormSheet(provider: provider),
          ),
        ),
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
              _isEditing ? 'Edit Provider' : 'Add Provider',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              DropdownButtonFormField<AiProviderType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
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
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            if (!_isEditing || widget.provider!.id != 'zen-builtin') ...[
              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Leave empty for no-key free models',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            if (_type == AiProviderType.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(labelText: 'Base URL'),
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
                                    ? '✓ Valid key — model ${_modelController.text} OK'
                                    : '✗ ${result.substring(0, result.length > 100 ? 100 : result.length)}'),
                              ),
                            );
                          },
                    child: Text(_isTesting ? 'Testing...' : 'Test Key'),
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
                      child: const Text('Delete'),
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
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            if (_testRan) ...[
              const SizedBox(height: 12),
              Text(
                _testResult == null ? '✓ Valid key' : '✗ $_testResult',
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
                'Default: ${_type.defaultModel ?? 'user must supply'}',
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
