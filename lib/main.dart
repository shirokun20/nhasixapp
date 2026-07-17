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
import 'package:nhasixapp/presentation/widgets/app_privacy_overlay_gate.dart';
import 'package:nhasixapp/presentation/widgets/platform_not_supported_dialog.dart';
import 'package:nhasixapp/presentation/widgets/lifecycle_watcher.dart';
import 'package:nhasixapp/core/services/analytics_service.dart';
import 'package:nhasixapp/core/services/history_cleanup_service.dart';
import 'package:nhasixapp/core/services/app_update_service.dart';
import 'package:nhasixapp/core/services/language_service.dart';
import 'package:nhasixapp/core/services/workers/download_worker.dart';
import 'package:nhasixapp/core/utils/performance_monitor.dart';
import 'package:logger/logger.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // Initialize Performance Monitoring
  await PerformanceMonitor.initialize();

  // Initialize Analytics Service
  final analyticsService = getIt<AnalyticsService>();
  await analyticsService.initialize();

  // Initialize History Cleanup Service
  final historyCleanupService = getIt<HistoryCleanupService>();
  await historyCleanupService.initialize();

  // Initialize App Update Service (clears cache on app updates)
  await AppUpdateService.initialize();

  // Load language metadata from assets/configs/languages.json
  await getIt<LanguageService>().load();

  // Initialize WorkManager for background downloads
  await initializeWorkManager(isDebugMode: kDebugMode);

  // _setupAllServiceLocalizationCallbacks();

  // Setup error handlers to prevent app crashes (especially Impeller/Vulkan issues)
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    // ponytail: skip FlutterImageDecoderImpl error — Impeller coba decode
    // AVIF/WebP yang gak didukung; harmless, ExtendedImage otomatis fallback
    if (msg.contains('Invalid image data')) {
      return;
    }
    Logger().e('🔥 Flutter Error: ${details.exception}',
        error: details.exception, stackTrace: details.stack);
  };

  // Catch errors from platform (including Impeller/Vulkan)
  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    // ponytail: skip known benign Flutter assertion noise (FocusNode/FocusScopeNode
    // used-after-dispose fires in debug mode during navigation; not actionable)
    if (msg.contains('FocusScopeNode was used after being disposed') ||
        msg.contains('FocusNode was used after being disposed')) {
      return true;
    }
    // ponytail: native ImageDecoder fails on unsupported AVIF/WebP variants
    // when Impeller (Vulkan) tries to decode them. Harmless — the widget retries
    // via fallback URL or native animated view. Silent skip to avoid log spam.
    if (msg.contains('Failed to decode image') &&
        msg.contains('FlutterImageDecoderImplDefault')) {
      return true;
    }
    Logger().e('🔥 Platform Error: $msg', error: error, stackTrace: stack);
    return true; // Prevent crash
  };

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
                'Rendering Error',
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

                Logger().i(
                    '🎨 MaterialApp rebuilt with theme: ${themeState.currentTheme}, mode: ${themeState.themeMode}, brightness: ${themeState.themeData.brightness}');
                Logger().i(
                    '🌐 MaterialApp rebuilt with locale: ${locale.languageCode}');

                return MaterialApp.router(
                  title: 'Kuron',
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
                    final child_ = AppPrivacyOverlayGate(
                      child: child ?? const SizedBox.shrink(),
                    );
                    if (themeState.currentTheme != 'note' && themeState.currentTheme != 'note_dark') return child_;
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.299, 0.587, 0.114, 0, 0,
                        0.299, 0.587, 0.114, 0, 0,
                        0.299, 0.587, 0.114, 0, 0,
                        0,     0,     0,     1, 0,
                      ]),
                      child: child_,
                    );
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
