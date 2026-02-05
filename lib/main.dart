import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/config/multi_bloc_provider_config.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/presentation/cubits/settings/settings_cubit.dart';
import 'package:nhasixapp/presentation/cubits/theme/theme_cubit.dart';
import 'package:nhasixapp/presentation/widgets/platform_not_supported_dialog.dart';
import 'package:nhasixapp/presentation/widgets/lifecycle_watcher.dart';
import 'package:nhasixapp/services/analytics_service.dart';
import 'package:nhasixapp/services/history_cleanup_service.dart';
import 'package:nhasixapp/services/app_update_service.dart';
import 'package:nhasixapp/services/workers/download_worker.dart';
import 'package:nhasixapp/services/license_service.dart';
import 'package:nhasixapp/services/ad_service.dart';
import 'package:nhasixapp/core/utils/performance_monitor.dart';
import 'dart:io';

void main() async {
  // Catch platform-level errors early
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Setup error handlers to prevent app crashes (especially Impeller/Vulkan issues)
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('🔥 Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('🔥 Platform Error: $error');
      debugPrint('Stack: $stack');
      return true; // Prevent crash
    };

    await setupLocator();

    // Initialize Performance Monitoring
    await PerformanceMonitor.initialize().timeout(
      const Duration(seconds: 1),
      onTimeout: () => debugPrint('⚠️ PerformanceMonitor init timed out'),
    );

    // Initialize Analytics Service
    final analyticsService = getIt<AnalyticsService>();
    await analyticsService.initialize();

    // Initialize License Service (Security & Revalidation)
    // CRITICAL: Timeout to prevent blank screen if storage hangs
    await getIt<LicenseService>().initialize().timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('⚠️ LicenseService init timed out - proceeding'),
    ).catchError((e) {
      debugPrint('⚠️ LicenseService init failed: $e');
      return; // Continue startup
    });

    // Initialize AdService
    // Depends on LicenseService for premium check
    try {
      await getIt<AdService>().initialize();
    } catch (e) {
      debugPrint('⚠️ AdService init failed: $e');
    }

    // Initialize History Cleanup Service
    final historyCleanupService = getIt<HistoryCleanupService>();
    await historyCleanupService.initialize();

    // Initialize App Update Service (clears cache on app updates)
    await AppUpdateService.initialize();

    // Initialize WorkManager for background downloads
    await initializeWorkManager(isDebugMode: kDebugMode);

  } catch (e, stack) {
    debugPrint('🔥 CRITICAL STARTUP ERROR: $e');
    debugPrint('Stack: $stack');
    // We continue to runApp even if init fails to show error UI or degraded app
  }

  // Custom error widget instead of red screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'KomikTap Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode
                    ? details.exception.toString()
                    : 'Please restart the app',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: MultiBlocProviderConfig.data,
      child: LifecycleWatcher(
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settingsState) {
                // Get locale from settings
                final locale = _getLocaleFromSettings(settingsState);

                debugPrint(
                    '🎨 MaterialApp rebuilt with theme: ${themeState.currentTheme}, mode: ${themeState.themeMode}, brightness: ${themeState.themeData.brightness}');
                debugPrint(
                    '🌐 MaterialApp rebuilt with locale: ${locale.languageCode}');

                return MaterialApp.router(
                  title: "KomikTap",
                  debugShowCheckedModeBanner: false,
                  routerConfig: AppRouter.router,
                  theme: themeState.themeData,
                  themeMode: themeState.themeMode,
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) {
                    // Show platform warning for non-Android platforms
                    if (kIsWeb ||
                        (!kIsWeb && !Platform.isAndroid && !Platform.isMacOS)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        PlatformNotSupportedDialog.show(context);
                      });
                    }
                    return child ?? const SizedBox.shrink();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Convert settings language to Locale
  Locale _getLocaleFromSettings(SettingsState settingsState) {
    if (settingsState is SettingsLoaded) {
      switch (settingsState.preferences.defaultLanguage) {
        case 'indonesian':
          return const Locale('id');
        case 'chinese':
          return const Locale('zh');
        case 'english':
        default:
          return const Locale('en');
      }
    }
    return const Locale('en'); // Default to English
  }
}
