import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/constants/colors_const.dart' show AppColors;
import 'package:nhasixapp/core/constants/design_tokens.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/network/source_health_monitor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/user_preferences.dart';
import '../../../core/utils/source_config_display_utils.dart';
import '../../../core/services/tag_blacklist_service.dart';

import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/source/source_cubit.dart';
import '../../cubits/source/source_state.dart';
import '../../blocs/download/download_bloc.dart';
import '../../../core/utils/app_update_test.dart';
import '../../widgets/app_main_drawer_widget.dart';
import 'settings_theme_widgets.dart';
import 'settings_download_widgets.dart';
import 'settings_privacy_widgets.dart';

part 'settings_source_install.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late final TagBlacklistService _tagBlacklistService;
  Map<String, dynamic>? _deviceDnsState;
  final SourceHealthMonitor _healthMonitor = getIt<SourceHealthMonitor>();
  Map<String, SourceHealthStatus> _sourceHealthStatuses = {};
  StreamSubscription<Map<String, SourceHealthStatus>>? _healthSub;

  void _ensureDownloadBlocInitialized() {
    final downloadBloc = context.read<DownloadBloc>();
    if (downloadBloc.state is DownloadInitial) {
      downloadBloc.add(const DownloadInitializeEvent());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tagBlacklistService = getIt<TagBlacklistService>();
    _ensureDownloadBlocInitialized();

    unawaited(
      Future.wait([
        _tagBlacklistService.syncOnlineEntries('nhentai'),
        _tagBlacklistService.syncOnlineRules('nhentai'),
      ]),
    );
    _loadDnsDiagnostics();
    _runHealthCheck();
  }

  Future<void> _loadDnsDiagnostics() async {
    try {
      final deviceState = await KuronNative.instance.getPrivateDnsDiagnostics();
      if (mounted) {
        setState(() {
          _deviceDnsState = deviceState;
        });
      }
    } catch (e) {
      getIt<Logger>().w('DNS diagnostics failed', error: e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDnsDiagnostics();
      _runHealthCheck();
    }
  }

  @override
  void dispose() {
    _healthSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _triggerRebuild() {
    setState(() {});
  }

  void _runHealthCheck() {
    _healthSub?.cancel();
    _healthSub = _healthMonitor.healthStream.listen(
      (statuses) {
        if (mounted) setState(() => _sourceHealthStatuses = statuses);
      },
    );
    unawaited(_healthMonitor.checkAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
        elevation: DesignTokens.elevationNone,
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
          buildSettingsSectionHeader(Icons.palette_outlined, 'DISPLAY', theme),
          const SizedBox(height: 12),
          buildSettingsCard([
            buildSettingsDropdownTile(
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
            buildSettingsDivider(theme),
            buildSettingsDropdownTile(
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
            buildSettingsDivider(theme),
            buildSettingsDropdownTile(
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
            buildSettingsDivider(theme),
            buildSettingsSwitchTile(
              title: l10n.blurThumbnails,
              subtitle: l10n.blurThumbnailsDescription,
              value: prefs.blurThumbnails,
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateBlurThumbnails(v),
              theme: theme,
            ),
          ], theme),

          const SizedBox(height: 24),

          buildSettingsSectionHeader(
            Icons.visibility_off_outlined,
            AppLocalizations.of(context)!.contentFilters,
            theme,
          ),
          const SizedBox(height: 12),
          buildSettingsInfoBanner(
            AppLocalizations.of(context)!.blurCoversDescription,
            Icons.shield_moon_outlined,
            theme,
          ),
          const SizedBox(height: 12),
          buildTagBlacklistSection(context, prefs, theme, tagBlacklistService: _tagBlacklistService),

          const SizedBox(height: 24),

          // Storage Settings Card
          buildSettingsSectionHeader(Icons.folder_outlined, 'STORAGE', theme),
          const SizedBox(height: 12),
          buildSettingsInfoBanner(
            l10n.storageDescription,
            Icons.info_outline,
            theme,
          ),
          const SizedBox(height: 12),
          buildStorageSection(context, theme, l10n, onRefresh: () => setState(() {})),

          const SizedBox(height: 24),

          // Download Settings Card
          buildSettingsSectionHeader(Icons.download_outlined, 'DOWNLOAD', theme),
          const SizedBox(height: 12),
          buildSettingsInfoBanner(
            l10n.imageQualityDescription,
            Icons.info_outline,
            theme,
          ),
          const SizedBox(height: 12),
          buildDownloadSection(context, theme, l10n),

          const SizedBox(height: 24),

          // Reader Settings Card
          buildSettingsSectionHeader(Icons.auto_stories_outlined, 'READER', theme),
          const SizedBox(height: 12),
          buildSettingsInfoBanner(
            l10n.autoCleanupDescription,
            Icons.info_outline,
            theme,
          ),
          const SizedBox(height: 12),
          buildSettingsCard([
            buildSettingsSwitchTile(
              title: l10n.autoCleanupHistory,
              subtitle: l10n.automaticallyCleanOldReadingHistory,
              value: prefs.autoCleanupHistory,
              onChanged: (v) =>
                  context.read<SettingsCubit>().updateAutoCleanupHistory(v),
              theme: theme,
            ),
            if (prefs.autoCleanupHistory) ...[
              buildSettingsDivider(theme),
              buildSettingsDropdownTile(
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
              buildSettingsDivider(theme),
              buildSettingsDropdownTile(
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
              buildSettingsDivider(theme),
              buildSettingsSwitchTile(
                title: l10n.cleanupOnInactivity,
                subtitle: l10n.cleanHistoryWhenAppUnused,
                value: prefs.cleanupOnInactivity,
                onChanged: (v) =>
                    context.read<SettingsCubit>().updateCleanupOnInactivity(v),
                theme: theme,
              ),
              if (prefs.cleanupOnInactivity) ...[
                buildSettingsDivider(theme),
                buildSettingsDropdownTile(
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
          buildSettingsSectionHeader(
            Icons.visibility_off_outlined,
            AppLocalizations.of(context)!.appDisguise,
            theme,
          ),
          const SizedBox(height: 12),
          buildSettingsCard([
            buildDisguiseModeTile(prefs, theme, l10n),
          ], theme),

          const SizedBox(height: 24),

          // DNS Status Section
          buildSettingsSectionHeader(
            Icons.dns_outlined,
            'DNS',
            theme,
          ),
          const SizedBox(height: 12),
          buildDnsStatusCard(context, theme, l10n, deviceDnsState: _deviceDnsState),

          const SizedBox(height: 24),

          // Available Sources Section
          _buildAvailableSourcesSection(this, theme, l10n),

          const SizedBox(height: 24),

          // Developer Tools Card
          buildSettingsSectionHeader(
            Icons.bug_report_outlined,
            AppLocalizations.of(context)!.developerTools,
            theme,
          ),
          const SizedBox(height: 12),
          buildSettingsCard([
            if (kDebugMode) ...[
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.dns_outlined),
                title: const Text('DoH Test'),
                subtitle:
                    const Text('Test DNS-over-HTTPS resolver and responses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AppRouter.goToDohTest(context),
              ),
              buildSettingsDivider(theme),
            ],
            buildSettingsActionTile(
              title: l10n.testCacheClearing,
              subtitle: l10n.testCacheClearingDescription,
              actionLabel: l10n.runTest,
              onTap: () => AppUpdateTest.runTests(context),
              theme: theme,
            ),
            buildSettingsDivider(theme),
            buildSettingsActionTile(
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
          buildResetButton(context, theme, l10n),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
