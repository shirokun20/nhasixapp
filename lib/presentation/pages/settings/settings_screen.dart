import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import '../../../domain/entities/user_preferences.dart';

import '../../cubits/settings/settings_cubit.dart';
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
                  context, state.preferences, theme, l10n);
            } else if (state is SettingsError) {
              return Center(
                child: Text(state.getUserFriendlyMessage(l10n)),
              );
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
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(ThemeOption.getDisplayName(t))))
                  .toList(),
              onChanged: (v) => context.read<SettingsCubit>().updateTheme(v!),
              theme: theme,
            ),
            // _buildDivider(theme),
            // _buildDropdownTile(
            //   context: context,
            //   title: l10n.appLanguage,
            //   subtitle: 'Select your preferred language',
            //   value: 'indonesian', // FORCE SELECTION
            //   items: [
            //     // DropdownMenuItem(value: 'english', child: Text(l10n.english)),
            //     DropdownMenuItem(
            //         value: 'indonesian', child: Text(l10n.indonesian)),
            //     // DropdownMenuItem(value: 'chinese', child: Text(l10n.chinese)),
            //   ],
            //   onChanged: (v) =>
            //       context.read<SettingsCubit>().updateDefaultLanguage(v!),
            //   theme: theme,
            // ),
            _buildDivider(theme),
            _buildDropdownTile(
              context: context,
              title: l10n.imageQuality,
              subtitle: l10n.imageQualityDescription,
              value: prefs.imageQuality,
              items: ImageQuality.all
                  .map((q) => DropdownMenuItem(
                      value: q, child: Text(ImageQuality.getDisplayName(q))))
                  .toList(),
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateImageQuality(v!),
              theme: theme,
            ),
            _buildDivider(theme),
            _buildDropdownTile(
              context: context,
              title: l10n.gridColumns,
              subtitle: l10n.gridColumnsDescription,
              value: prefs.columnsPortrait,
              items: [2, 3]
                  .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                  .toList(),
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateColumnsPortrait(v!),
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

          // Grid Preview
          const SizedBox(height: 12),
          _buildGridPreview(prefs.columnsPortrait, theme, l10n),

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
                  String label = h < 24
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
                    .map((d) => DropdownMenuItem(
                        value: d,
                        child:
                            Text(d == 0 ? l10n.unlimited : l10n.daysValue(d))))
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
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(l10n.daysValue(d))))
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
              Icons.visibility_off_outlined, 'APP DISGUISE', theme),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildDisguiseModeTile(prefs, theme, l10n),
          ], theme),

          const SizedBox(height: 24),

          // Developer Tools Card
          _buildSectionHeader(
              Icons.bug_report_outlined, 'DEVELOPER TOOLS', theme),
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
          icon: Icon(Icons.arrow_drop_down,
              color: theme.colorScheme.primary, size: 20),
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
        child: Text(actionLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildGridPreview(
      int columns, ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gridPreview,
              style: TextStyleConst.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: columns * 2,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ],
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
      UserPreferences prefs, ThemeData theme, AppLocalizations l10n) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isLoading =
            state is SettingsLoaded && state.isUpdatingDisguiseMode;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  : Icon(Icons.arrow_drop_down,
                      color: theme.colorScheme.primary, size: 20),
              style: TextStyleConst.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              items: [
                DropdownMenuItem(
                    value: 'default', child: Text(l10n.disguiseDefault)),
                DropdownMenuItem(
                    value: 'calculator', child: Text(l10n.disguiseCalculator)),
                DropdownMenuItem(
                    value: 'notes', child: Text(l10n.disguiseNotes)),
                DropdownMenuItem(
                    value: 'weather', child: Text(l10n.disguiseWeather)),
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
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return FilledButton.icon(
      onPressed: () async {
        final settingsCubit = context.read<SettingsCubit>();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.resetSettings, style: TextStyleConst.headingSmall),
            content: Text(l10n.confirmResetSettings,
                style: TextStyleConst.bodyMedium),
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
          settingsCubit.resetToDefaults();
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
}
