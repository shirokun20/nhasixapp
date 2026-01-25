library;
 
import 'dart:core';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
 
/// Pagination and data fetching limits
class AppLimits {
  AppLimits._();
 
  static RemoteConfigService get _remoteConfig => getIt<RemoteConfigService>();
 
  /// Default page size for paginated lists
  static int get defaultPageSize =>
      _remoteConfig.appConfig?.limits?.defaultPageSize ?? 20;
 
  /// Maximum items to fetch for offline/downloads lists
  static int get maxBatchSize =>
      _remoteConfig.appConfig?.limits?.maxBatchSize ?? 1000;
 
  /// Default page for pagination (1-indexed)
  static const int defaultPage = 1;
 
  /// Maximum concurrent downloads
  static int get maxConcurrentDownloads =>
      _remoteConfig.appConfig?.limits?.maxConcurrentDownloads ?? 3;
 
  /// Search history limit
  static int get searchHistoryLimit =>
      _remoteConfig.appConfig?.limits?.searchHistoryLimit ?? 50;
 
  /// Image preload buffer size
  static int get imagePreloadBuffer =>
      _remoteConfig.appConfig?.limits?.imagePreloadBuffer ?? 5;
}

/// Duration constants for timeouts, delays, and animations
class AppDurations {
  AppDurations._();
 
  static RemoteConfigService get _remoteConfig => getIt<RemoteConfigService>();
 
  /// Splash screen delay before initialization
  static Duration get splashDelay => Duration(
      milliseconds: _remoteConfig.appConfig?.durations?.splashDelayMs ?? 1000);
 
  /// Snackbar display duration (short)
  static Duration get snackbarShort => Duration(
      milliseconds: _remoteConfig.appConfig?.durations?.snackbarShortMs ?? 2000);
 
  /// Snackbar display duration (long)
  static Duration get snackbarLong => Duration(
      milliseconds: _remoteConfig.appConfig?.durations?.snackbarLongMs ?? 4000);
 
  /// Animation duration for page transitions
  static Duration get pageTransition => Duration(
      milliseconds:
          _remoteConfig.appConfig?.durations?.pageTransitionMs ?? 300);
 
  /// Debounce delay for search input
  static Duration get searchDebounce => Duration(
      milliseconds:
          _remoteConfig.appConfig?.durations?.searchDebounceMs ?? 300);
 
  /// Timeout for network requests
  static Duration get networkTimeout => Duration(
      milliseconds:
          _remoteConfig.appConfig?.durations?.networkTimeoutMs ?? 30000);
 
  /// Cache expiration time
  static Duration get cacheExpiration => Duration(
      hours: _remoteConfig.appConfig?.durations?.cacheExpirationHours ?? 24);
 
  /// Auto-hide UI delay for reader
  static Duration get readerAutoHideDelay => Duration(
      seconds:
          _remoteConfig.appConfig?.durations?.readerAutoHideDelaySeconds ?? 3);
 
  /// Download progress update interval
  static Duration get progressUpdateInterval => Duration(
      milliseconds:
          _remoteConfig.appConfig?.durations?.progressUpdateIntervalMs ?? 100);
}

/// File and storage related constants
class AppStorage {
  AppStorage._();
 
  static RemoteConfigService get _remoteConfig => getIt<RemoteConfigService>();
 
  /// Backup folder name
  static String get backupFolderName =>
      _remoteConfig.appConfig?.storage?.backupFolderName ?? 'nhasix';
 
  /// Default source ID for backward compatibility with existing downloads
  static final String defaultSourceId = SourceType.nhentai.id;
 
  /// Known content sources for validation
  static List<String> get knownSources {
    try {
      final registry = getIt<ContentSourceRegistry>();
      if (registry.isNotEmpty) {
        return registry.sourceIds;
      }
    } catch (_) {
      // Fallback if getIt not ready
    }
    return [
      SourceType.nhentai.id,
      SourceType.crotpedia.id,
      SourceType.komiktap.id,
    ];
  }
 
  /// Metadata file name
  static const String metadataFileName = 'metadata.json';
 
  /// Images subfolder name
  static const String imagesSubfolder = 'images';
 
  /// Maximum image file size (for compression threshold)
  static int get maxImageSizeKb =>
      _remoteConfig.appConfig?.storage?.maxImageSizeKb ?? 200;
 
  /// PDF parts size limit in pages
  static int get pdfPartsSizePages =>
      _remoteConfig.appConfig?.storage?.pdfPartsSizePages ?? 100;
}

/// UI related constants
class AppUI {
  AppUI._();
 
  static RemoteConfigService get _remoteConfig => getIt<RemoteConfigService>();
 
  /// Grid columns for portrait mode
  static int get gridColumnsPortrait =>
      _remoteConfig.appConfig?.ui?.gridColumnsPortrait ?? 2;
 
  /// Grid columns for landscape mode
  static int get gridColumnsLandscape =>
      _remoteConfig.appConfig?.ui?.gridColumnsLandscape ?? 3;
 
  /// Minimum card width for responsive grids
  static double get minCardWidth =>
      _remoteConfig.appConfig?.ui?.minCardWidth ?? 150.0;
 
  /// Content card aspect ratio
  static double get cardAspectRatio =>
      _remoteConfig.appConfig?.ui?.cardAspectRatio ?? 0.65;
 
  /// Border radius for cards
  static double get cardBorderRadius =>
      _remoteConfig.appConfig?.ui?.cardBorderRadius ?? 12.0;
 
  /// Default padding
  static double get defaultPadding =>
      _remoteConfig.appConfig?.ui?.defaultPadding ?? 16.0;
 
  /// Title max length before truncation
  static int get titleMaxLength =>
      _remoteConfig.appConfig?.ui?.titleMaxLength ?? 40;
 
  /// Error message max length before truncation
  static const int errorMaxLength = 100;
}

/// Feature flags and configuration
class AppConfig {
  AppConfig._();

  /// Enable performance monitoring in debug mode
  static const bool enablePerformanceMonitoring = true;

  /// Enable analytics tracking
  static const bool enableAnalytics = true;

  /// Minimum Android SDK version
  static const int minAndroidSdk = 21;
}
