import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/user_preferences.dart';
import '../../../services/analytics_service.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../widgets/app_scaffold_with_offline.dart';
import '../../../core/utils/app_update_test.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<bool> _getAnalyticsStatus() async {
    final analytics = getIt<AnalyticsService>();
    await analytics.initialize();
    return analytics.isAnalyticsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleOfflineScaffold(
      title: AppLocalizations.of(context)?.settings ?? 'Settings',
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            final prefs = state.preferences;
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                      AppLocalizations.of(context)?.displaySettings ??
                          'Tampilan',
                      style: TextStyleConst.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      )),
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text(AppLocalizations.of(context)?.theme ?? 'Theme',
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  subtitle: Text(
                    'Choose your preferred color theme for the app interface.',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.2),
                    ),
                    child: DropdownButton<String>(
                      value: prefs.theme,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.outline),
                      style: TextStyleConst.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: ThemeOption.all.map((theme) {
                        return DropdownMenuItem<String>(
                          value: theme,
                          child: Text(
                            ThemeOption.getDisplayName(theme),
                            style: TextStyleConst.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        );
                      }).toList(),
                      onChanged: (theme) {
                        if (theme != null) {
                          context.read<SettingsCubit>().updateTheme(theme);
                        }
                      },
                    ),
                  ),
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                      AppLocalizations.of(context)?.appLanguage ?? 'Language',
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  subtitle: Text(
                    'Select your preferred language for the app interface and content.',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.2),
                    ),
                    child: DropdownButton<String>(
                      value: prefs.defaultLanguage,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.outline),
                      style: TextStyleConst.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: [
                        DropdownMenuItem(
                          value: 'english',
                          child: Text(
                              AppLocalizations.of(context)?.english ??
                                  'English',
                              style: TextStyleConst.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                        ),
                        DropdownMenuItem(
                          value: 'indonesian',
                          child: Text(
                              AppLocalizations.of(context)?.indonesian ??
                                  'Bahasa Indonesia',
                              style: TextStyleConst.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                        ),
                      ],
                      onChanged: (lang) {
                        if (lang != null) {
                          context
                              .read<SettingsCubit>()
                              .updateDefaultLanguage(lang);
                        }
                      },
                    ),
                  ),
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                      AppLocalizations.of(context)?.imageQuality ??
                          'Image Quality',
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  subtitle: Text(
                    'Choose image quality for downloads. Higher quality uses more storage and data.',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.2),
                    ),
                    child: DropdownButton<String>(
                      value: prefs.imageQuality,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.outline),
                      style: TextStyleConst.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: ImageQuality.all.map((q) {
                        return DropdownMenuItem<String>(
                          value: q,
                          child: Text(
                            ImageQuality.getDisplayName(q),
                            style: TextStyleConst.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        );
                      }).toList(),
                      onChanged: (q) {
                        if (q != null) {
                          context.read<SettingsCubit>().updateImageQuality(q);
                        }
                      },
                    ),
                  ),
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                      AppLocalizations.of(context)?.gridColumns ??
                          'Grid Columns (Portrait)',
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  subtitle: Text(
                    'Choose how many columns to display content in portrait mode. More columns show more content but smaller items.',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.2),
                    ),
                    child: DropdownButton<int>(
                      value: prefs.columnsPortrait,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.outline),
                      style: TextStyleConst.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: [2, 3].map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text('$count',
                              style: TextStyleConst.bodyLarge.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        );
                      }).toList(),
                      onChanged: (count) {
                        if (count != null) {
                          context
                              .read<SettingsCubit>()
                              .updateColumnsPortrait(count);
                        }
                      },
                    ),
                  ),
                ),
                // Live preview for grid columns
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grid Preview',
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Preview grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: prefs.columnsPortrait,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: prefs.columnsPortrait * 2, // Show 2 rows
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 🚀 Cache Management Section (Debug) - MOVED HERE FOR EASY ACCESS
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Text('🚀 Cache Management (Debug)',
                          style: TextStyleConst.headingSmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.bug_report,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text('Test App Update Cache Clearing',
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                  subtitle: Text(
                    'Simulate app update and test cache clearing behavior.',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => AppUpdateTest.runTests(context),
                    child: Text('Run Test'),
                  ),
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text('Force Clear All Caches',
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                  subtitle: Text(
                    'Manually clear all image caches.',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => AppUpdateTest.forceClearCache(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    child: Text('Clear Cache'),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(AppLocalizations.of(context)!.reader,
                      style: TextStyleConst.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    AppLocalizations.of(context)!.manageAutoCleanupDescription,
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SwitchListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  title: Text(AppLocalizations.of(context)!.autoCleanupHistory,
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  subtitle: Text(
                      AppLocalizations.of(context)!
                          .automaticallyCleanOldReadingHistory,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  value: prefs.autoCleanupHistory,
                  onChanged: (val) {
                    context.read<SettingsCubit>().updateAutoCleanupHistory(val);
                  },
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  enabled: prefs.autoCleanupHistory,
                  title: Text(AppLocalizations.of(context)!.cleanupInterval,
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: prefs.autoCleanupHistory
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  subtitle: Text(
                      AppLocalizations.of(context)!.howOftenToCleanupHistory,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: prefs.autoCleanupHistory
                          ? Theme.of(context).colorScheme.surfaceContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.2),
                    ),
                    child: DropdownButton<int>(
                      value: prefs.historyCleanupIntervalHours,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.outline),
                      style: TextStyleConst.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: [6, 12, 24, 48, 168].map((hours) {
                        String label;
                        if (hours < 24) {
                          label = '${hours}h';
                        } else if (hours == 24) {
                          label = AppLocalizations.of(context)!.oneDay;
                        } else if (hours == 48) {
                          label = AppLocalizations.of(context)!.twoDays;
                        } else {
                          label = AppLocalizations.of(context)!.oneWeek;
                        }
                        return DropdownMenuItem<int>(
                          value: hours,
                          child: Text(label,
                              style: TextStyleConst.bodyLarge.copyWith(
                                color: prefs.autoCleanupHistory
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              )),
                        );
                      }).toList(),
                      onChanged: prefs.autoCleanupHistory
                          ? (hours) {
                              if (hours != null) {
                                context
                                    .read<SettingsCubit>()
                                    .updateHistoryCleanupInterval(hours);
                              }
                            }
                          : null,
                    ),
                  ),
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  enabled: prefs.autoCleanupHistory,
                  title: Text(AppLocalizations.of(context)!.maxHistoryDays,
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: prefs.autoCleanupHistory
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  subtitle: Text(
                      AppLocalizations.of(context)!.maximumDaysToKeepHistory,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: prefs.autoCleanupHistory
                          ? Theme.of(context).colorScheme.surfaceContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.2),
                    ),
                    child: DropdownButton<int>(
                      value: prefs.maxHistoryDays,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.outline),
                      style: TextStyleConst.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: [0, 7, 14, 30, 60, 90].map((days) {
                        return DropdownMenuItem<int>(
                          value: days,
                          child: Text(
                            days == 0
                                ? AppLocalizations.of(context)!.unlimited
                                : AppLocalizations.of(context)!.daysValue(days),
                            style: TextStyleConst.bodyLarge.copyWith(
                              color: prefs.autoCleanupHistory
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: prefs.autoCleanupHistory
                          ? (days) {
                              if (days != null) {
                                context
                                    .read<SettingsCubit>()
                                    .updateMaxHistoryDays(days);
                              }
                            }
                          : null,
                    ),
                  ),
                ),
                SwitchListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  title: Text(AppLocalizations.of(context)!.cleanupOnInactivity,
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: prefs.autoCleanupHistory
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  subtitle: Text(
                      AppLocalizations.of(context)!.cleanHistoryWhenAppUnused,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  value: prefs.cleanupOnInactivity,
                  onChanged: prefs.autoCleanupHistory
                      ? (val) {
                          context
                              .read<SettingsCubit>()
                              .updateCleanupOnInactivity(val);
                        }
                      : null,
                ),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  enabled:
                      prefs.autoCleanupHistory && prefs.cleanupOnInactivity,
                  title: Text(AppLocalizations.of(context)!.inactivityThreshold,
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: (prefs.autoCleanupHistory &&
                                prefs.cleanupOnInactivity)
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  subtitle: Text(
                      AppLocalizations.of(context)!
                          .daysOfInactivityBeforeCleanup,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: (prefs.autoCleanupHistory &&
                              prefs.cleanupOnInactivity)
                          ? Theme.of(context).colorScheme.surfaceContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.2),
                    ),
                    child: DropdownButton<int>(
                      value: prefs.inactivityCleanupDays,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.outline),
                      style: TextStyleConst.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      items: [3, 5, 7, 14, 30].map((days) {
                        return DropdownMenuItem<int>(
                          value: days,
                          child: Text(
                              AppLocalizations.of(context)!.daysValue(days),
                              style: TextStyleConst.bodyLarge.copyWith(
                                color: (prefs.autoCleanupHistory &&
                                        prefs.cleanupOnInactivity)
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              )),
                        );
                      }).toList(),
                      onChanged: (prefs.autoCleanupHistory &&
                              prefs.cleanupOnInactivity)
                          ? (days) {
                              if (days != null) {
                                context
                                    .read<SettingsCubit>()
                                    .updateInactivityCleanupDays(days);
                              }
                            }
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(AppLocalizations.of(context)!.other,
                      style: TextStyleConst.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      )),
                ),
                // Analytics Consent Section
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                      AppLocalizations.of(context)?.allowAnalytics ??
                          'Izinkan Analytics',
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  subtitle: Text(
                    AppLocalizations.of(context)!.analyticsSubtitle,
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  trailing: FutureBuilder<bool>(
                    future: _getAnalyticsStatus(),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return Switch(
                        value: isEnabled,
                        onChanged: (value) async {
                          final analytics = getIt<AnalyticsService>();
                          await analytics.setAnalyticsEnabled(value);
                          // Force rebuild to show new state
                          if (context.mounted) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
                ),

                // Privacy Information
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.privacy_tip_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)
                                        ?.privacyAnalytics ??
                                    'Privasi Analytics',
                                style: TextStyleConst.bodyLarge.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.privacyInfoText,
                            style: TextStyleConst.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // App Disguise Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                      AppLocalizations.of(context)?.appDisguise ??
                          'App Disguise',
                      style: TextStyleConst.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      )),
                ),
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, settingsState) {
                    final isLoading = settingsState is SettingsLoaded &&
                        settingsState.isUpdatingDisguiseMode;

                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      title: Text(
                          AppLocalizations.of(context)?.disguiseMode ??
                              'Disguise Mode',
                          style: TextStyleConst.bodyLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          )),
                      subtitle: Text(
                        isLoading
                            ? 'Applying disguise mode changes...'
                            : 'Choose how the app appears in your launcher for privacy.',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1.2),
                        ),
                        child: DropdownButton<String>(
                          value: prefs.disguiseMode,
                          underline: const SizedBox(),
                          icon: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                )
                              : Icon(Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.outline),
                          style: TextStyleConst.bodyLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          items: [
                            DropdownMenuItem(
                              value: 'default',
                              child: Text('Default',
                                  style: TextStyleConst.bodyLarge.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                            ),
                            DropdownMenuItem(
                              value: 'calculator',
                              child: Text('Calculator',
                                  style: TextStyleConst.bodyLarge.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                            ),
                            DropdownMenuItem(
                              value: 'notes',
                              child: Text('Notes',
                                  style: TextStyleConst.bodyLarge.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                            ),
                            DropdownMenuItem(
                              value: 'weather',
                              child: Text('Weather',
                                  style: TextStyleConst.bodyLarge.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                            ),
                          ],
                          onChanged: isLoading
                              ? null
                              : (mode) {
                                  if (mode != null) {
                                    context
                                        .read<SettingsCubit>()
                                        .updateDisguiseMode(mode);
                                  }
                                },
                        ),
                      ),
                    );
                  },
                ),

                // Contoh: Reset ke default
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.refresh,
                        color: Theme.of(context).colorScheme.onError),
                    label: Text(AppLocalizations.of(context)!.resetToDefault,
                        style: TextStyleConst.buttonLarge.copyWith(
                            color: Theme.of(context).colorScheme.onError)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final settingsCubit = context.read<SettingsCubit>();
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          title: Text(
                              AppLocalizations.of(context)?.resetSettings ??
                                  'Reset Settings',
                              style: TextStyleConst.headingSmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                          content: Text(
                              AppLocalizations.of(context)!
                                  .confirmResetSettings,
                              style: TextStyleConst.bodyLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(AppLocalizations.of(context)!.cancel,
                                  style: TextStyleConst.bodyLarge.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onError,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(AppLocalizations.of(context)!.reset,
                                  style: TextStyleConst.bodyLarge.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onError)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        settingsCubit.resetToDefaults();
                      }
                    },
                  ),
                ),
              ],
            );
          } else if (state is SettingsError) {
            return Center(
                child: Text(state
                    .getUserFriendlyMessage(AppLocalizations.of(context))));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
