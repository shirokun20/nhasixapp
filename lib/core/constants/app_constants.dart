/// App-wide constants to avoid magic numbers and duplicated values
///
/// This file centralizes all hardcoded values for easier maintenance
/// and consistency across the codebase.
library;

import 'dart:core';

/// Pagination and data fetching limits
class AppLimits {
  AppLimits._();

  /// Default page size for paginated lists
  static const int defaultPageSize = 20;

  /// Maximum items to fetch for offline/downloads lists
  static const int maxBatchSize = 1000;

  /// Default page for pagination (1-indexed)
  static const int defaultPage = 1;

  /// Maximum concurrent downloads
  static const int maxConcurrentDownloads = 3;

  /// Search history limit
  static const int searchHistoryLimit = 50;

  /// Image preload buffer size
  static const int imagePreloadBuffer = 5;
}

/// Duration constants for timeouts, delays, and animations
class AppDurations {
  AppDurations._();

  /// Splash screen delay before initialization
  static const Duration splashDelay = Duration(seconds: 1);

  /// Snackbar display duration (short)
  static const Duration snackbarShort = Duration(seconds: 2);

  /// Snackbar display duration (long)
  static const Duration snackbarLong = Duration(seconds: 4);

  /// Animation duration for page transitions
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// Debounce delay for search input
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Timeout for network requests
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Cache expiration time
  static const Duration cacheExpiration = Duration(hours: 24);

  /// Auto-hide UI delay for reader
  static const Duration readerAutoHideDelay = Duration(seconds: 3);

  /// Download progress update interval
  static const Duration progressUpdateInterval = Duration(milliseconds: 100);
}

/// File and storage related constants
class AppStorage {
  AppStorage._();

  /// Backup folder name
  static const String backupFolderName = 'nhasix';

  /// Default source ID for backward compatibility with existing downloads
  static const String defaultSourceId = 'nhentai';

  /// Known content sources for validation
  static const List<String> knownSources = ['nhentai', 'crotpedia'];

  /// Metadata file name
  static const String metadataFileName = 'metadata.json';

  /// Images subfolder name
  static const String imagesSubfolder = 'images';

  /// Maximum image file size (for compression threshold)
  static const int maxImageSizeKb = 200;

  /// PDF parts size limit in pages
  static const int pdfPartsSizePages = 100;
}

/// UI related constants
class AppUI {
  AppUI._();

  /// Grid columns for portrait mode
  static const int gridColumnsPortrait = 2;

  /// Grid columns for landscape mode
  static const int gridColumnsLandscape = 3;

  /// Minimum card width for responsive grids
  static const double minCardWidth = 150.0;

  /// Content card aspect ratio
  static const double cardAspectRatio = 0.65;

  /// Border radius for cards
  static const double cardBorderRadius = 12.0;

  /// Default padding
  static const double defaultPadding = 16.0;

  /// Title max length before truncation
  static const int titleMaxLength = 40;

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
