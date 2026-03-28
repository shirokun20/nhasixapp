import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/user_preferences.dart';

import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/source/source_cubit.dart';
import '../../cubits/source/source_state.dart';
import '../../../core/utils/app_update_test.dart';
import '../../widgets/app_main_drawer_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      drawer: AppMainDrawerWidget(context: context),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoaded) {
              return _buildSettingsContent(
                context,
                state.preferences,
                theme,
                l10n,
              );
            } else if (state is SettingsError) {
              return Center(child: Text(state.getUserFriendlyMessage(l10n)));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    UserPreferences prefs,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 16),

          // Display Settings Card
          _buildSectionHeader(Icons.palette_outlined, 'DISPLAY', theme),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildDropdownTile(
              context: context,
              title: l10n.theme,
              subtitle: l10n.themeDescription,
              value: prefs.theme,
              items: ThemeOption.all
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(ThemeOption.getDisplayName(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => context.read<SettingsCubit>().updateTheme(v!),
              theme: theme,
            ),
            _buildDivider(theme),
            _buildDropdownTile(
              context: context,
              title: l10n.appLanguage,
              subtitle: 'Select your preferred language',
              value: prefs.defaultLanguage,
              items: [
                DropdownMenuItem(value: 'english', child: Text(l10n.english)),
                DropdownMenuItem(
                  value: 'indonesian',
                  child: Text(l10n.indonesian),
                ),
                DropdownMenuItem(value: 'chinese', child: Text(l10n.chinese)),
              ],
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateDefaultLanguage(v!),
              theme: theme,
            ),
            _buildDivider(theme),
            _buildDropdownTile(
              context: context,
              title: l10n.imageQuality,
              subtitle: l10n.imageQualityDescription,
              value: prefs.imageQuality,
              items: ImageQuality.all
                  .map(
                    (q) => DropdownMenuItem(
                      value: q,
                      child: Text(ImageQuality.getDisplayName(q)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateImageQuality(v!),
              theme: theme,
            ),
            _buildDivider(theme),
            _buildSwitchTile(
              title: l10n.blurThumbnails,
              subtitle: l10n.blurThumbnailsDescription,
              value: prefs.blurThumbnails,
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateBlurThumbnails(v),
              theme: theme,
            ),
          ], theme),

          const SizedBox(height: 24),

          // Reader Settings Card
          _buildSectionHeader(Icons.auto_stories_outlined, 'READER', theme),
          const SizedBox(height: 12),
          _buildInfoBanner(
            l10n.autoCleanupDescription,
            Icons.info_outline,
            theme,
          ),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              title: l10n.autoCleanupHistory,
              subtitle: l10n.automaticallyCleanOldReadingHistory,
              value: prefs.autoCleanupHistory,
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateAutoCleanupHistory(v),
              theme: theme,
            ),
            if (prefs.autoCleanupHistory) ...[
              _buildDivider(theme),
              _buildDropdownTile(
                context: context,
                title: l10n.cleanupInterval,
                subtitle: l10n.howOftenToCleanupHistory,
                value: prefs.historyCleanupIntervalHours,
                items: [6, 12, 24, 48, 168].map((h) {
                  final String label = h < 24
                      ? '${h}h'
                      : h == 24
                          ? l10n.oneDay
                          : h == 48
                              ? l10n.twoDays
                              : l10n.oneWeek;
                  return DropdownMenuItem(value: h, child: Text(label));
                }).toList(),
                onChanged: (v) => context
                    .read<SettingsCubit>()
                    .updateHistoryCleanupInterval(v!),
                theme: theme,
              ),
              _buildDivider(theme),
              _buildDropdownTile(
                context: context,
                title: l10n.maxHistoryDays,
                subtitle: l10n.maximumDaysToKeepHistory,
                value: prefs.maxHistoryDays,
                items: [0, 7, 14, 30, 60, 90]
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          d == 0 ? l10n.unlimited : l10n.daysValue(d),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    context.read<SettingsCubit>().updateMaxHistoryDays(v!),
                theme: theme,
              ),
              _buildDivider(theme),
              _buildSwitchTile(
                title: l10n.cleanupOnInactivity,
                subtitle: l10n.cleanHistoryWhenAppUnused,
                value: prefs.cleanupOnInactivity,
                onChanged: (v) =>
                    context.read<SettingsCubit>().updateCleanupOnInactivity(v),
                theme: theme,
              ),
              if (prefs.cleanupOnInactivity) ...[
                _buildDivider(theme),
                _buildDropdownTile(
                  context: context,
                  title: l10n.inactivityThreshold,
                  subtitle: l10n.daysOfInactivityBeforeCleanup,
                  value: prefs.inactivityCleanupDays,
                  items: [3, 5, 7, 14, 30]
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(l10n.daysValue(d)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => context
                      .read<SettingsCubit>()
                      .updateInactivityCleanupDays(v!),
                  theme: theme,
                ),
              ],
            ],
          ], theme),

          const SizedBox(height: 24),

          // App Disguise Card
          _buildSectionHeader(
            Icons.visibility_off_outlined,
            'APP DISGUISE',
            theme,
          ),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildDisguiseModeTile(prefs, theme, l10n),
          ], theme),

          const SizedBox(height: 24),

          // Available Sources Section
          _buildAvailableSourcesSection(theme, l10n),

          const SizedBox(height: 24),

          // Developer Tools Card
          _buildSectionHeader(
            Icons.bug_report_outlined,
            'DEVELOPER TOOLS',
            theme,
          ),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildActionTile(
              title: l10n.testCacheClearing,
              subtitle: l10n.testCacheClearingDescription,
              actionLabel: l10n.runTest,
              onTap: () => AppUpdateTest.runTests(context),
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionTile(
              title: l10n.forceClearCache,
              subtitle: l10n.forceClearCacheDescription,
              actionLabel: l10n.clearCacheButton,
              onTap: () => AppUpdateTest.forceClearCache(context),
              isDestructive: true,
              theme: theme,
            ),
          ], theme),

          const SizedBox(height: 24),

          // Reset Button
          _buildResetButton(context, theme, l10n),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: theme.dividerColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required ThemeData theme,
    bool enabled = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: TextStyleConst.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyleConst.bodySmall.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: DropdownButton<T>(
          value: value,
          underline: const SizedBox(),
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          style: TextStyleConst.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required ThemeData theme,
    bool enabled = true,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: TextStyleConst.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyleConst.bodySmall.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: theme.colorScheme.primary,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: TextStyleConst.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyleConst.bodySmall.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          foregroundColor: isDestructive
              ? theme.colorScheme.onError
              : theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          actionLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyleConst.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisguiseModeTile(
    UserPreferences prefs,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isLoading =
            state is SettingsLoaded && state.isUpdatingDisguiseMode;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Text(
            l10n.disguiseMode,
            style: TextStyleConst.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            isLoading
                ? l10n.applyingDisguiseMode
                : l10n.disguiseModeDescription,
            style: TextStyleConst.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: DropdownButton<String>(
              value: prefs.disguiseMode,
              underline: const SizedBox(),
              icon: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
              style: TextStyleConst.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              items: [
                DropdownMenuItem(
                  value: 'default',
                  child: Text(l10n.disguiseDefault),
                ),
                DropdownMenuItem(
                  value: 'calculator',
                  child: Text(l10n.disguiseCalculator),
                ),
                DropdownMenuItem(
                  value: 'notes',
                  child: Text(l10n.disguiseNotes),
                ),
                DropdownMenuItem(
                  value: 'weather',
                  child: Text(l10n.disguiseWeather),
                ),
              ],
              onChanged: isLoading
                  ? null
                  : (mode) {
                      if (mode != null) {
                        context.read<SettingsCubit>().updateDisguiseMode(mode);
                      }
                    },
            ),
          ),
        );
      },
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return FilledButton.icon(
      onPressed: () async {
        final settingsCubit = context.read<SettingsCubit>();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(l10n.resetSettings, style: TextStyleConst.headingSmall),
            content: Text(
              l10n.confirmResetSettings,
              style: TextStyleConst.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.reset),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await settingsCubit.resetToDefaults();
        }
      },
      icon: const Icon(Icons.refresh),
      label: Text(l10n.resetToDefault),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Build the "Available Sources" section for manual Link/ZIP installation.
  Widget _buildAvailableSourcesSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader(
          Icons.download_outlined,
          'AVAILABLE SOURCES',
          theme,
        ),
        const SizedBox(height: 12),

        _buildSettingsCard([
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              l10n.settingsCustomSourceTitle,
              style: TextStyleConst.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              l10n.settingsCustomSourceSubtitle,
              style: TextStyleConst.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _installSourceFromLink(context),
                    icon: const Icon(Icons.link),
                    label: Text(l10n.settingsAddViaLink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _installSourceFromZip(context),
                    icon: const Icon(Icons.folder_zip_outlined),
                    label: Text(l10n.settingsImportZip),
                  ),
                ),
              ],
            ),
          ),
        ], theme),

        const SizedBox(height: 12),

        BlocBuilder<SourceCubit, SourceState>(
          builder: (context, state) {
            return _buildSettingsCard([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  l10n.sourceSelectorSelectSource,
                  style: TextStyleConst.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${state.availableSources.length} source(s) installed',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (state.availableSources.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    l10n.sourceSelectorNoSourceSelected,
                    style: TextStyleConst.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...state.availableSources.map((source) {
                  final isActive = state.activeSource?.id == source.id;
                  final canUninstall = source.id != 'nhentai';
                  final remoteConfig = getIt<RemoteConfigService>();
                  final rawConfig = remoteConfig.getRawConfig(source.id);
                  final meta = rawConfig?['meta'] as Map<String, dynamic>?;
                  final ui = rawConfig?['ui'] as Map<String, dynamic>?;
                  final description =
                      (meta?['description'] as String?)?.trim() ??
                          (ui?['description'] as String?)?.trim();
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.extension_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      source.displayName,
                      style: TextStyleConst.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      (description != null && description.isNotEmpty)
                          ? '$description\n${source.id}'
                          : source.id,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleConst.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.sourceSelectorActiveSource,
                              style: TextStyleConst.bodySmall.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (canUninstall) ...[
                          if (isActive) const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Uninstall source',
                            onPressed: () =>
                                _confirmAndUninstallSource(context, source.id),
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ], theme);
          },
        ),
      ],
    );
  }

  Future<void> _registerSourceInRegistry(
    BuildContext context,
    String sourceId,
  ) async {
    final remoteConfig = getIt<RemoteConfigService>();
    final registry = getIt<ContentSourceRegistry>();
    final resolver = getIt<SourceFactoryResolver>();
    final logger = getIt<Logger>();
    final raw = remoteConfig.getRawConfig(sourceId);

    if (raw == null) {
      throw StateError('$sourceId config missing after apply');
    }

    final wasActive = registry.currentSourceId == sourceId;
    if (registry.hasSource(sourceId)) {
      registry.unregister(sourceId);
    }

    ContentSource instance;
    try {
      instance = resolver.createSource(raw);
    } catch (e, stackTrace) {
      logger.w(
        'Specialized source factory failed for $sourceId, falling back to GenericSourceFactory',
        error: e,
        stackTrace: stackTrace,
      );
      instance = getIt<GenericSourceFactory>().create(raw);
    }

    registry.register(instance);
    if (wasActive) {
      registry.switchSource(sourceId);
    }

    context.read<SourceCubit>().refreshSources();
    setState(() {});
  }

  Future<void> _confirmAndUninstallSource(
    BuildContext context,
    String sourceId,
  ) async {
    if (sourceId == 'nhentai') {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final sourceCubit = context.read<SourceCubit>();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Uninstall Source'),
            content: Text(
              'Remove "$sourceId" from local installed sources?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Uninstall'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final remoteConfig = getIt<RemoteConfigService>();
      final registry = getIt<ContentSourceRegistry>();
      final wasActive = registry.currentSourceId == sourceId;

      await remoteConfig.uninstallSourceConfig(sourceId);
      if (registry.hasSource(sourceId)) {
        registry.unregister(sourceId);
      }

      sourceCubit.refreshSources();

      if (wasActive && registry.currentSourceId != null) {
        sourceCubit.switchSource(registry.currentSourceId!);
        sourceCubit.clearSwitching();
      }

      if (!mounted) return;
      setState(() {});

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Source "$sourceId" uninstalled.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e, stackTrace) {
      Logger().e('Failed to uninstall source: $e', stackTrace: stackTrace);
      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to uninstall "$sourceId": $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _installSourceFromLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final link = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sourceImportLinkDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.sourceImportConfigUrlHint,
            labelText: l10n.sourceImportConfigUrlLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.sourceImportConfirmInstall),
          ),
        ],
      ),
    );

    if (link == null || link.isEmpty) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.sourceImportInstallingFromLink),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final dio = getIt<Dio>();
      final candidate = await _buildCandidateFromLinkManifest(
        link: link,
        dio: dio,
        l10n: l10n,
      );

      if (!context.mounted) return;
      final shouldInstall = await _showInstallPreviewDialog(
        context,
        candidate,
      );
      if (!shouldInstall) {
        messenger.hideCurrentSnackBar();
        return;
      }

      final remoteConfig = getIt<RemoteConfigService>();
      await remoteConfig.applySourceConfigFromJson(
        sourceId: candidate.sourceId,
        rawJson: candidate.rawJson,
        sourceLabel: 'link',
      );
      await remoteConfig.markSourceInstalled(candidate.sourceId);

      if (!context.mounted) return;
      await _registerSourceInRegistry(context, candidate.sourceId);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sourceImportInstalledFromLink(candidate.sourceId)),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e, stackTrace) {
      Logger()
          .e('Failed to install source from link: $e', stackTrace: stackTrace);
      if (!context.mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sourceImportFailedFromLink(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _installSourceFromZip(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      final bytes = await KuronNative.instance.pickBinaryFile(
        mimeType: 'application/zip',
      );
      if (bytes == null || bytes.isEmpty) {
        return;
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sourceImportInstallingFromZip),
          duration: const Duration(seconds: 30),
        ),
      );

      if (!context.mounted) return;

      final candidates = await _buildCandidateFromZip(
        context: context,
        bytes: bytes,
        l10n: l10n,
      );

      if (candidates.isEmpty) {
        messenger.hideCurrentSnackBar();
        return;
      }

      if (!context.mounted) return;
      final shouldInstall = candidates.length == 1
          // ignore: use_build_context_synchronously
          ? await _showInstallPreviewDialog(context, candidates.first)
          // ignore: use_build_context_synchronously
          : await _showBatchInstallPreviewDialog(context, candidates);
      if (!shouldInstall) {
        messenger.hideCurrentSnackBar();
        return;
      }

      final remoteConfig = getIt<RemoteConfigService>();
      final installed = <String>[];
      final failed = <String>[];
      final failedReasons = <String, String>{};

      for (final candidate in candidates) {
        try {
          await remoteConfig.applySourceConfigFromJson(
            sourceId: candidate.sourceId,
            rawJson: candidate.rawJson,
            sourceLabel: 'ZIP',
          );
          await remoteConfig.markSourceInstalled(candidate.sourceId);

          if (!context.mounted) return;
          await _registerSourceInRegistry(context, candidate.sourceId);
          installed.add(candidate.sourceId);
        } catch (e, stackTrace) {
          Logger().e(
            'Failed installing ZIP source ${candidate.sourceId}: $e',
            stackTrace: stackTrace,
          );
          failed.add(candidate.sourceId);
          failedReasons[candidate.sourceId] = e.toString();
        }
      }

      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      if (failed.isEmpty) {
        final message = installed.length == 1
            ? l10n.sourceImportInstalledFromZip(installed.first)
            : 'Installed ${installed.length} sources from ZIP';
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        final reasonHint = failed.isNotEmpty
            ? ' • ${failed.first}: ${failedReasons[failed.first] ?? 'unknown error'}'
            : '';
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Installed ${installed.length}, failed ${failed.length}: ${failed.join(', ')}$reasonHint',
            ),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger()
          .e('Failed to install source from ZIP: $e', stackTrace: stackTrace);
      if (!context.mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sourceImportFailedFromZip(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<_InstallCandidate> _buildCandidateFromLinkManifest({
    required String link,
    required Dio dio,
    required AppLocalizations l10n,
  }) async {
    final manifestResponse = await dio.get<String>(
      link,
      options: Options(
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.plain,
      ),
    );

    final manifestRaw = manifestResponse.data;
    if (manifestRaw == null || manifestRaw.trim().isEmpty) {
      throw FormatException(l10n.sourceImportManifestInvalid);
    }

    final manifestMap = _decodeJsonObject(
      rawJson: manifestRaw,
      invalidMessage: l10n.sourceImportManifestInvalid,
    );

    // Case A: direct source config JSON (legacy/admin friendly).
    if (manifestMap.containsKey('source')) {
      final sourceId = _requiredString(
        manifestMap,
        'source',
        l10n.sourceImportSourceMismatch,
      );
      final version = (manifestMap['version'] as String?)?.trim() ?? 'unknown';
      return _InstallCandidate(
        sourceId: sourceId,
        version: version,
        displayName: null,
        description: null,
        rawJson: manifestRaw,
        isVerified: false,
      );
    }

    // Case B: global app manifest with installableSources list.
    final installableSources =
        _parseGlobalManifestEntries(manifestMap, l10n).toList();
    if (installableSources.isNotEmpty) {
      if (!mounted) {
        throw StateError('SettingsScreen is no longer mounted');
      }
      final selectedEntry = await _selectGlobalManifestEntry(
        context: context,
        entries: installableSources,
      );
      if (selectedEntry == null) {
        throw const FormatException('Source selection cancelled');
      }

      return _downloadCandidateFromEntry(
        baseLink: link,
        dio: dio,
        entry: selectedEntry,
        l10n: l10n,
      );
    }

    // Case C: package-level manifest for a single source.
    final manifest = _SourcePackageManifest.fromMap(manifestMap, l10n);
    final resolvedConfigUrl =
        Uri.parse(link).resolve(manifest.configPath).toString();
    final configResponse = await dio.get<String>(
      resolvedConfigUrl,
      options: Options(
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.plain,
      ),
    );

    final rawJson = configResponse.data;
    if (rawJson == null || rawJson.trim().isEmpty) {
      throw FormatException(l10n.sourceImportConfigEmpty);
    }

    final configBytes = utf8.encode(rawJson);
    _validateChecksum(
      contentBytes: configBytes,
      expectedSha256: manifest.checksumSha256,
      checksumMismatchMessage: l10n.sourceImportChecksumMismatch,
    );

    final configMap = _decodeJsonObject(
      rawJson: rawJson,
      invalidMessage: l10n.sourceImportManifestInvalid,
    );
    final sourceIdFromConfig = _requiredString(
      configMap,
      'source',
      l10n.sourceImportSourceMismatch,
    );
    if (sourceIdFromConfig != manifest.sourceId) {
      throw FormatException(l10n.sourceImportSourceMismatch);
    }

    return _InstallCandidate(
      sourceId: manifest.sourceId,
      version: manifest.version,
      displayName: manifest.displayName,
      description: null,
      rawJson: rawJson,
      isVerified: true,
    );
  }

  Future<_InstallCandidate> _downloadCandidateFromEntry({
    required String baseLink,
    required Dio dio,
    required _GlobalManifestEntry entry,
    required AppLocalizations l10n,
  }) async {
    final resolvedConfigUrl = Uri.parse(baseLink).resolve(entry.url).toString();
    final configResponse = await dio.get<String>(
      resolvedConfigUrl,
      options: Options(
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.plain,
      ),
    );

    final rawJson = configResponse.data;
    if (rawJson == null || rawJson.trim().isEmpty) {
      throw FormatException(l10n.sourceImportConfigEmpty);
    }

    var isVerified = false;
    final checksum = entry.checksumSha256;
    if (checksum != null && checksum.isNotEmpty) {
      final configBytes = utf8.encode(rawJson);
      _validateChecksum(
        contentBytes: configBytes,
        expectedSha256: checksum,
        checksumMismatchMessage: l10n.sourceImportChecksumMismatch,
      );
      isVerified = true;
    }

    final configMap = _decodeJsonObject(
      rawJson: rawJson,
      invalidMessage: l10n.sourceImportManifestInvalid,
    );
    final sourceIdFromConfig = _requiredString(
      configMap,
      'source',
      l10n.sourceImportSourceMismatch,
    );
    if (sourceIdFromConfig != entry.id) {
      throw FormatException(l10n.sourceImportSourceMismatch);
    }

    _attachManifestMetadata(
      configMap,
      displayName: entry.displayName,
      description: entry.description,
    );
    await _cacheIconForLinkCandidate(
      sourceId: entry.id,
      configMap: configMap,
      entryIconUrl: entry.iconUrl,
      baseLink: baseLink,
      dio: dio,
    );

    return _InstallCandidate(
      sourceId: entry.id,
      version: entry.version,
      displayName: entry.displayName,
      description: entry.description,
      rawJson: jsonEncode(configMap),
      isVerified: isVerified,
    );
  }

  Iterable<_GlobalManifestEntry> _parseGlobalManifestEntries(
    Map<String, dynamic> map,
    AppLocalizations l10n,
  ) sync* {
    final rawList = map['installableSources'];
    if (rawList is! List<dynamic>) return;

    for (final item in rawList) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      try {
        yield _GlobalManifestEntry.fromMap(item, l10n);
      } catch (_) {
        continue;
      }
    }
  }

  Future<_GlobalManifestEntry?> _selectGlobalManifestEntry({
    required BuildContext context,
    required List<_GlobalManifestEntry> entries,
  }) async {
    if (entries.length == 1) {
      return entries.first;
    }

    return showModalBottomSheet<_GlobalManifestEntry>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Select Source from Manifest'),
              subtitle: Text('Choose one source to install.'),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final entry = entries[index];
                  return ListTile(
                    title: Text(entry.displayName ?? entry.id),
                    subtitle: Text('${entry.id} • v${entry.version}'),
                    onTap: () => Navigator.pop(ctx, entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<_GlobalManifestEntry>> _selectGlobalManifestEntries({
    required BuildContext context,
    required List<_GlobalManifestEntry> entries,
  }) async {
    if (entries.length == 1) {
      return entries;
    }

    final selected = <_GlobalManifestEntry>{};
    final result = await showModalBottomSheet<List<_GlobalManifestEntry>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              children: [
                const ListTile(
                  title: Text('Select Source from Manifest'),
                  subtitle: Text('Choose one or more sources to install.'),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final entry = entries[index];
                      final isSelected = selected.contains(entry);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(entry.displayName ?? entry.id),
                        subtitle: Text('${entry.id} • v${entry.version}'),
                        onChanged: (value) {
                          setModalState(() {
                            if (value == true) {
                              selected.add(entry);
                            } else {
                              selected.remove(entry);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, const []),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: selected.isEmpty
                              ? null
                              : () => Navigator.pop(
                                    ctx,
                                    entries
                                        .where(
                                            (entry) => selected.contains(entry))
                                        .toList(growable: false),
                                  ),
                          child: Text('Install Selected (${selected.length})'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return result ?? const [];
  }

  Future<List<_InstallCandidate>> _buildCandidateFromZip({
    required BuildContext context,
    required List<int> bytes,
    required AppLocalizations l10n,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.files.where((file) {
      if (!file.isFile) return false;
      final segments = file.name.split('/');
      final name = segments.isEmpty ? file.name : segments.last;
      return name.toLowerCase() == 'manifest.json';
    }).firstOrNull;

    if (manifestFile == null) {
      throw FormatException(l10n.sourceImportZipManifestRequired);
    }

    final manifestBytes = _archiveFileBytes(manifestFile);
    final manifestRaw = utf8.decode(manifestBytes);
    final manifestMap = _decodeJsonObject(
      rawJson: manifestRaw,
      invalidMessage: l10n.sourceImportManifestInvalid,
    );

    // ZIP may contain a global manifest (`installableSources`) similar to
    // app/manifest.json. Let user choose one source and load its config file
    // from within the same ZIP package.
    final installableSources =
        _parseGlobalManifestEntries(manifestMap, l10n).toList(growable: false);
    if (installableSources.isNotEmpty) {
      if (!mounted) {
        throw StateError('SettingsScreen is no longer mounted');
      }

      final selectedEntries = await _selectGlobalManifestEntries(
        context: context,
        entries: installableSources,
      );
      if (selectedEntries.isEmpty) {
        return const [];
      }

      final candidates = <_InstallCandidate>[];
      for (final selectedEntry in selectedEntries) {
        final configFile = _findConfigFileInArchive(
          archive: archive,
          targetPath: selectedEntry.url,
        );
        if (configFile == null) {
          continue;
        }

        final configBytes = _archiveFileBytes(configFile);
        final checksum = selectedEntry.checksumSha256;
        var isVerified = false;
        if (checksum != null && checksum.isNotEmpty) {
          _validateChecksum(
            contentBytes: configBytes,
            expectedSha256: checksum,
            checksumMismatchMessage: l10n.sourceImportChecksumMismatch,
          );
          isVerified = true;
        }

        final rawJson = utf8.decode(configBytes);
        final configMap = _decodeJsonObject(
          rawJson: rawJson,
          invalidMessage: l10n.sourceImportManifestInvalid,
        );
        final sourceIdFromConfig = _requiredString(
          configMap,
          'source',
          l10n.sourceImportSourceMismatch,
        );
        if (sourceIdFromConfig != selectedEntry.id) {
          continue;
        }

        _attachManifestMetadata(
          configMap,
          displayName: selectedEntry.displayName,
          description: selectedEntry.description,
        );
        await _cacheIconForZipCandidate(
          sourceId: selectedEntry.id,
          configMap: configMap,
          archive: archive,
          entryIconUrl: selectedEntry.iconUrl,
        );

        candidates.add(
          _InstallCandidate(
            sourceId: selectedEntry.id,
            version: selectedEntry.version,
            displayName: selectedEntry.displayName,
            description: selectedEntry.description,
            rawJson: jsonEncode(configMap),
            isVerified: isVerified,
          ),
        );
      }

      return candidates;
    }

    // Backward-compatible path: some legacy ZIPs put source config directly
    // in manifest.json without package wrapper fields.
    if (manifestMap.containsKey('source')) {
      final sourceId = _requiredString(
        manifestMap,
        'source',
        l10n.sourceImportSourceMismatch,
      );
      final version = (manifestMap['version'] as String?)?.trim() ?? 'unknown';
      return [
        _InstallCandidate(
          sourceId: sourceId,
          version: version,
          displayName: null,
          description: null,
          rawJson: manifestRaw,
          isVerified: false,
        ),
      ];
    }

    final manifest = _SourcePackageManifest.fromMap(manifestMap, l10n);

    final configFile = _findConfigFileInArchive(
      archive: archive,
      targetPath: manifest.configPath,
    );

    if (configFile == null) {
      throw FormatException(l10n.sourceImportManifestInvalid);
    }

    final configBytes = _archiveFileBytes(configFile);
    if (manifest.checksumSha256.isNotEmpty) {
      _validateChecksum(
        contentBytes: configBytes,
        expectedSha256: manifest.checksumSha256,
        checksumMismatchMessage: l10n.sourceImportChecksumMismatch,
      );
    }

    final rawJson = utf8.decode(configBytes);
    final configMap = _decodeJsonObject(
      rawJson: rawJson,
      invalidMessage: l10n.sourceImportManifestInvalid,
    );
    final sourceIdFromConfig = _requiredString(
      configMap,
      'source',
      l10n.sourceImportSourceMismatch,
    );

    if (sourceIdFromConfig != manifest.sourceId) {
      throw FormatException(l10n.sourceImportSourceMismatch);
    }

    return [
      _InstallCandidate(
        sourceId: manifest.sourceId,
        version: manifest.version,
        displayName: manifest.displayName,
        description: null,
        rawJson: rawJson,
        isVerified: manifest.checksumSha256.isNotEmpty,
      ),
    ];
  }

  void _attachManifestMetadata(
    Map<String, dynamic> configMap, {
    String? displayName,
    String? description,
  }) {
    final meta = (configMap['meta'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    if (displayName != null && displayName.trim().isNotEmpty) {
      meta['displayName'] = displayName.trim();
    }
    if (description != null && description.trim().isNotEmpty) {
      meta['description'] = description.trim();
    }

    if (meta.isNotEmpty) {
      configMap['meta'] = meta;
    }
  }

  Future<void> _cacheIconForZipCandidate({
    required String sourceId,
    required Map<String, dynamic> configMap,
    required Archive archive,
    String? entryIconUrl,
  }) async {
    final configIconPath = _readConfigIconPath(configMap);
    final candidatePath =
        (entryIconUrl != null && entryIconUrl.trim().isNotEmpty)
            ? entryIconUrl.trim()
            : configIconPath;
    if (candidatePath == null || candidatePath.isEmpty) {
      return;
    }

    final iconFile = _findConfigFileInArchive(
      archive: archive,
      targetPath: candidatePath,
    );
    if (iconFile == null) {
      return;
    }

    final iconBytes = _archiveFileBytes(iconFile);
    final localPath = await _persistSourceIconBytes(
      sourceId: sourceId,
      iconBytes: iconBytes,
      originalPath: candidatePath,
    );
    if (localPath != null) {
      _setConfigIconPath(configMap, localPath);
    }
  }

  Future<void> _cacheIconForLinkCandidate({
    required String sourceId,
    required Map<String, dynamic> configMap,
    required String baseLink,
    required Dio dio,
    String? entryIconUrl,
  }) async {
    final configIconPath = _readConfigIconPath(configMap);
    final candidatePath =
        (entryIconUrl != null && entryIconUrl.trim().isNotEmpty)
            ? entryIconUrl.trim()
            : configIconPath;
    if (candidatePath == null || candidatePath.isEmpty) {
      return;
    }

    final iconUri = Uri.tryParse(candidatePath);
    final isAbsoluteHttp = iconUri != null &&
        (iconUri.scheme == 'http' || iconUri.scheme == 'https');
    final resolvedUrl = isAbsoluteHttp
        ? candidatePath
        : Uri.parse(baseLink).resolve(candidatePath).toString();

    try {
      final response = await dio.get<List<int>>(
        resolvedUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return;
      }

      final localPath = await _persistSourceIconBytes(
        sourceId: sourceId,
        iconBytes: bytes,
        originalPath: candidatePath,
      );
      if (localPath != null) {
        _setConfigIconPath(configMap, localPath);
      }
    } catch (e, stackTrace) {
      Logger().w(
        'Failed to cache icon for $sourceId from $resolvedUrl',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  String? _readConfigIconPath(Map<String, dynamic> configMap) {
    final rawTopLevel = configMap['iconPath'] as String?;
    if (rawTopLevel != null && rawTopLevel.trim().isNotEmpty) {
      return rawTopLevel.trim();
    }

    final uiMap = (configMap['ui'] as Map?)?.cast<String, dynamic>();
    final rawUi = uiMap?['iconPath'] as String?;
    if (rawUi != null && rawUi.trim().isNotEmpty) {
      return rawUi.trim();
    }
    return null;
  }

  void _setConfigIconPath(Map<String, dynamic> configMap, String localPath) {
    configMap['iconPath'] = localPath;

    final uiMap = (configMap['ui'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    uiMap['iconPath'] = localPath;
    configMap['ui'] = uiMap;
  }

  Future<String?> _persistSourceIconBytes({
    required String sourceId,
    required List<int> iconBytes,
    required String originalPath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final iconDir = Directory(p.join(appDir.path, 'source_icons'));
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }

      final extension = _resolveImageExtension(originalPath);
      final filePath = p.join(iconDir.path, '$sourceId$extension');
      final iconFile = File(filePath);
      await iconFile.writeAsBytes(iconBytes, flush: true);
      return filePath;
    } catch (e, stackTrace) {
      Logger().w(
        'Failed to persist local icon for $sourceId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _resolveImageExtension(String pathOrUrl) {
    final uri = Uri.tryParse(pathOrUrl);
    final rawPath = (uri?.path.isNotEmpty == true) ? uri!.path : pathOrUrl;
    final ext = p.extension(rawPath).toLowerCase();
    switch (ext) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.webp':
      case '.gif':
      case '.svg':
        return ext;
      default:
        return '.png';
    }
  }

  ArchiveFile? _findConfigFileInArchive({
    required Archive archive,
    required String targetPath,
  }) {
    final target = targetPath.replaceAll('\\', '/').toLowerCase();
    return archive.files.where((file) {
      if (!file.isFile) return false;
      final normalized = file.name.replaceAll('\\', '/').toLowerCase();
      return normalized == target || normalized.endsWith('/$target');
    }).firstOrNull;
  }

  Future<bool> _showInstallPreviewDialog(
    BuildContext context,
    _InstallCandidate candidate,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sourceImportPreviewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.sourceImportPreviewSourceId}: ${candidate.sourceId}'),
            const SizedBox(height: 6),
            Text('${l10n.sourceImportPreviewVersion}: ${candidate.version}'),
            if (candidate.displayName != null &&
                candidate.displayName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                  '${l10n.sourceImportPreviewDisplayName}: ${candidate.displayName}'),
            ],
            const SizedBox(height: 6),
            Text(
              '${l10n.sourceImportPreviewVerified}: ${candidate.isVerified ? l10n.sourceImportPreviewVerifiedYes : l10n.sourceImportPreviewVerifiedNo}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.sourceImportConfirmInstall),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<bool> _showBatchInstallPreviewDialog(
    BuildContext context,
    List<_InstallCandidate> candidates,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sourceImportPreviewTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected sources: ${candidates.length}'),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, index) {
                    final candidate = candidates[index];
                    return Text(
                      '- ${candidate.displayName ?? candidate.sourceId} (v${candidate.version})',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Install Selected'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Map<String, dynamic> _decodeJsonObject({
    required String rawJson,
    required String invalidMessage,
  }) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(invalidMessage);
    }
    return decoded;
  }

  String _requiredString(
    Map<String, dynamic> map,
    String key,
    String errorMessage,
  ) {
    final value = map[key] as String?;
    if (value == null || value.trim().isEmpty) {
      throw FormatException(errorMessage);
    }
    return value.trim();
  }

  List<int> _archiveFileBytes(ArchiveFile file) {
    return file.content;
  }

  void _validateChecksum({
    required List<int> contentBytes,
    required String expectedSha256,
    required String checksumMismatchMessage,
  }) {
    final actual = sha256.convert(contentBytes).toString().toLowerCase();
    if (actual != expectedSha256.toLowerCase()) {
      throw FormatException(checksumMismatchMessage);
    }
  }
}

class _SourcePackageManifest {
  const _SourcePackageManifest({
    required this.schemaVersion,
    required this.sourceId,
    required this.version,
    required this.configPath,
    required this.checksumSha256,
    required this.displayName,
  });

  final int schemaVersion;
  final String sourceId;
  final String version;
  final String configPath;
  final String checksumSha256;
  final String? displayName;

  static _SourcePackageManifest fromMap(
    Map<String, dynamic> map,
    AppLocalizations l10n,
  ) {
    final rawSchemaVersion = map['schemaVersion'];
    final schemaVersion = rawSchemaVersion is int ? rawSchemaVersion : 1;

    String readAnyString(List<String> keys, {bool required = true}) {
      for (final key in keys) {
        final value = map[key] as String?;
        if (value != null && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      if (!required) return '';
      throw FormatException(l10n.sourceImportManifestInvalid);
    }

    String normalizeConfigPath(String rawPath) {
      if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
        final uri = Uri.tryParse(rawPath);
        if (uri != null && uri.path.isNotEmpty) {
          rawPath = uri.path;
        }
      }

      var normalized = rawPath.replaceAll('\\', '/').trim();
      while (normalized.startsWith('/')) {
        normalized = normalized.substring(1);
      }
      if (normalized.startsWith('./')) {
        normalized = normalized.substring(2);
      }
      return normalized;
    }

    final sourceId = readAnyString(const ['sourceId', 'id', 'source']);
    final version = readAnyString(const ['version']);
    final configPathRaw = readAnyString(const ['configPath', 'path', 'url']);
    final checksum = readAnyString(
      const ['checksumSha256', 'checksum'],
      required: false,
    );

    return _SourcePackageManifest(
      schemaVersion: schemaVersion,
      sourceId: sourceId,
      version: version,
      configPath: normalizeConfigPath(configPathRaw),
      checksumSha256: checksum,
      displayName: (map['displayName'] as String?)?.trim(),
    );
  }
}

class _InstallCandidate {
  const _InstallCandidate({
    required this.sourceId,
    required this.version,
    required this.displayName,
    required this.description,
    required this.rawJson,
    required this.isVerified,
  });

  final String sourceId;
  final String version;
  final String? displayName;
  final String? description;
  final String rawJson;
  final bool isVerified;
}

class _GlobalManifestEntry {
  const _GlobalManifestEntry({
    required this.id,
    required this.version,
    required this.url,
    required this.checksumSha256,
    required this.displayName,
    required this.description,
    required this.iconUrl,
  });

  final String id;
  final String version;
  final String url;
  final String? checksumSha256;
  final String? displayName;
  final String? description;
  final String? iconUrl;

  static _GlobalManifestEntry fromMap(
    Map<String, dynamic> map,
    AppLocalizations l10n,
  ) {
    String readRequired(String key) {
      final value = map[key] as String?;
      if (value == null || value.trim().isEmpty) {
        throw FormatException(l10n.sourceImportManifestInvalid);
      }
      return value.trim();
    }

    final meta = map['meta'];
    String? displayName;
    String? description;
    String? iconUrl;
    if (meta is Map<String, dynamic>) {
      displayName = (meta['displayName'] as String?)?.trim();
      description = (meta['description'] as String?)?.trim();
      iconUrl = (meta['iconUrl'] as String?)?.trim();
    }

    return _GlobalManifestEntry(
      id: readRequired('id'),
      version: readRequired('version'),
      url: readRequired('url'),
      checksumSha256: (map['checksum'] as String?)?.trim(),
      displayName: displayName,
      description: description,
      iconUrl: iconUrl,
    );
  }
}
