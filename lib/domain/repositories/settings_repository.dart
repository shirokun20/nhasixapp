import '../entities/entities.dart';

/// Repository interface for app settings and preferences
abstract class SettingsRepository {
  // ==================== USER PREFERENCES ====================

  /// Get current user preferences
  ///
  /// Returns current user preferences with defaults if not set
  Future<UserPreferences> getUserPreferences();

  /// Update user preferences
  ///
  /// [preferences] - Updated preferences to save
  Future<void> updateUserPreferences(UserPreferences preferences);

  /// Reset preferences to default values
  ///
  /// Returns default preferences
  Future<UserPreferences> resetToDefaults();

  /// Get specific preference value
  ///
  /// [key] - Preference key
  /// [defaultValue] - Default value if key not found
  /// Returns preference value or default
  Future<T> getPreference<T>(String key, T defaultValue);

  /// Set specific preference value
  ///
  /// [key] - Preference key
  /// [value] - Value to set
  Future<void> setPreference<T>(String key, T value);

  /// Remove specific preference
  ///
  /// [key] - Preference key to remove
  Future<void> removePreference(String key);

  /// Check if preference exists
  ///
  /// [key] - Preference key to check
  /// Returns true if preference exists
  Future<bool> hasPreference(String key);

  // ==================== THEME SETTINGS ====================

  /// Get current theme settings
  ///
  /// Returns current theme configuration
  Future<ThemeSettings> getThemeSettings();

  /// Update theme settings
  ///
  /// [settings] - New theme settings
  Future<void> updateThemeSettings(ThemeSettings settings);

  /// Get available themes
  ///
  /// Returns list of available theme options
  Future<List<ThemeOption>> getAvailableThemes();

  /// Create custom theme
  ///
  /// [theme] - Custom theme configuration
  /// Returns created theme
  Future<CustomTheme> createCustomTheme(CustomTheme theme);

  /// Delete custom theme
  ///
  /// [themeId] - Theme ID to delete
  Future<void> deleteCustomTheme(String themeId);

  /// Get custom themes
  ///
  /// Returns list of user-created themes
  Future<List<CustomTheme>> getCustomThemes();

  // ==================== READER SETTINGS ====================

  /// Get reader settings
  ///
  /// Returns current reader configuration
  Future<ReaderSettings> getReaderSettings();

  /// Update reader settings
  ///
  /// [settings] - New reader settings
  Future<void> updateReaderSettings(ReaderSettings settings);

  /// Get reading direction options
  ///
  /// Returns available reading directions
  Future<List<ReadingDirection>> getReadingDirections();

  // ==================== DOWNLOAD SETTINGS ====================

  /// Get download settings
  ///
  /// Returns current download configuration
  Future<DownloadSettings> getDownloadSettings();

  /// Update download settings
  ///
  /// [settings] - New download settings
  Future<void> updateDownloadSettings(DownloadSettings settings);

  // ==================== PRIVACY SETTINGS ====================

  /// Get privacy settings
  ///
  /// Returns current privacy configuration
  Future<PrivacySettings> getPrivacySettings();

  /// Update privacy settings
  ///
  /// [settings] - New privacy settings
  Future<void> updatePrivacySettings(PrivacySettings settings);

  /// Get content filter settings
  ///
  /// Returns current content filtering configuration
  Future<ContentFilterSettings> getContentFilterSettings();

  /// Update content filter settings
  ///
  /// [settings] - New content filter settings
  Future<void> updateContentFilterSettings(ContentFilterSettings settings);

  // ==================== NETWORK SETTINGS ====================

  /// Get network settings
  ///
  /// Returns current network configuration
  Future<NetworkSettings> getNetworkSettings();

  /// Update network settings
  ///
  /// [settings] - New network settings
  Future<void> updateNetworkSettings(NetworkSettings settings);

  /// Test network connection
  ///
  /// Returns network connectivity status
  Future<NetworkStatus> testNetworkConnection();

  /// Get proxy settings
  ///
  /// Returns current proxy configuration
  Future<ProxySettings> getProxySettings();

  /// Update proxy settings
  ///
  /// [settings] - New proxy settings
  Future<void> updateProxySettings(ProxySettings settings);

  // ==================== BACKUP SETTINGS ====================

  /// Get backup settings
  ///
  /// Returns current backup configuration
  Future<BackupSettings> getBackupSettings();

  /// Update backup settings
  ///
  /// [settings] - New backup settings
  Future<void> updateBackupSettings(BackupSettings settings);

  /// Get backup history
  ///
  /// Returns list of previous backups
  Future<List<BackupInfo>> getBackupHistory();

  /// Create manual backup
  ///
  /// Returns backup result
  Future<BackupResult> createBackup();

  /// Restore from backup
  ///
  /// [backupId] - Backup ID to restore from
  /// Returns restore result
  Future<RestoreResult> restoreFromBackup(String backupId);

  // ==================== ADVANCED SETTINGS ====================

  /// Get advanced settings
  ///
  /// Returns current advanced configuration
  Future<AdvancedSettings> getAdvancedSettings();

  /// Update advanced settings
  ///
  /// [settings] - New advanced settings
  Future<void> updateAdvancedSettings(AdvancedSettings settings);

  /// Get debug settings
  ///
  /// Returns current debug configuration
  Future<DebugSettings> getDebugSettings();

  /// Update debug settings
  ///
  /// [settings] - New debug settings
  Future<void> updateDebugSettings(DebugSettings settings);

  /// Clear all app data
  ///
  /// [keepSettings] - Keep user settings
  /// [keepFavorites] - Keep favorites
  /// [keepHistory] - Keep reading history
  /// Returns clear result
  Future<ClearDataResult> clearAppData({
    bool keepSettings = true,
    bool keepFavorites = false,
    bool keepHistory = false,
  });

  // ==================== SETTINGS EXPORT/IMPORT ====================

  /// Export settings to JSON
  ///
  /// [includeCustomThemes] - Include custom themes in export
  /// Returns JSON string with settings
  Future<String> exportSettings({bool includeCustomThemes = true});

  /// Import settings from JSON
  ///
  /// [jsonData] - JSON string with settings
  /// [mergeWithExisting] - Merge with existing settings
  Future<void> importSettings({
    required String jsonData,
    bool mergeWithExisting = true,
  });

  /// Get settings migration status
  ///
  /// Returns information about settings migration
  Future<MigrationStatus> getMigrationStatus();

  /// Migrate settings from older version
  ///
  /// [fromVersion] - Source version
  /// [toVersion] - Target version
  /// Returns migration result
  Future<MigrationResult> migrateSettings({
    required String fromVersion,
    required String toVersion,
  });
}

/// Theme settings configuration
class ThemeSettings {
  const ThemeSettings({
    required this.currentTheme,
    required this.useSystemTheme,
    required this.customThemes,
    this.accentColor,
    this.useAmoledDark = false,
  });

  final String currentTheme;
  final bool useSystemTheme;
  final List<String> customThemes;
  final String? accentColor;
  final bool useAmoledDark;

  ThemeSettings copyWith({
    String? currentTheme,
    bool? useSystemTheme,
    List<String>? customThemes,
    String? accentColor,
    bool? useAmoledDark,
  }) {
    return ThemeSettings(
      currentTheme: currentTheme ?? this.currentTheme,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      customThemes: customThemes ?? this.customThemes,
      accentColor: accentColor ?? this.accentColor,
      useAmoledDark: useAmoledDark ?? this.useAmoledDark,
    );
  }
}

/// Theme option
class ThemeOption {
  const ThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.previewColors,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final List<String> previewColors;
  final bool isCustom;
}

/// Custom theme configuration
class CustomTheme {
  const CustomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String surfaceColor;
  final DateTime createdAt;
}

/// Reader settings configuration
class ReaderSettings {
  const ReaderSettings({
    required this.readingDirection,
    required this.pageTransition,
    required this.fitMode,
    required this.keepScreenOn,
    required this.showSystemUI,
    required this.useVolumeKeys,
    required this.tapZones,
    this.brightness,
    this.preloadPages = 3,
  });

  final ReadingDirection readingDirection;
  final PageTransition pageTransition;
  final FitMode fitMode;
  final bool keepScreenOn;
  final bool showSystemUI;
  final bool useVolumeKeys;
  final TapZones tapZones;
  final double? brightness;
  final int preloadPages;
}

/// Page transition types
enum PageTransition {
  slide,
  fade,
  curl,
  none,
}

/// Image fit modes
enum FitMode {
  fitWidth,
  fitHeight,
  fitScreen,
  originalSize,
  smartFit,
}

/// Tap zones configuration
class TapZones {
  const TapZones({
    required this.leftZone,
    required this.rightZone,
    required this.centerZone,
  });

  final bool leftZone;
  final bool rightZone;
  final bool centerZone;
}

/// Download settings configuration
class DownloadSettings {
  const DownloadSettings({
    required this.maxConcurrentDownloads,
    required this.autoRetryFailed,
    required this.wifiOnlyDownload,
    required this.deleteAfterReading,
    this.maxRetryAttempts = 3,
    this.downloadQuality = 'high',
  });

  final int maxConcurrentDownloads;
  final bool autoRetryFailed;
  final bool wifiOnlyDownload;
  final bool deleteAfterReading;
  final int maxRetryAttempts;
  final String downloadQuality;
}

/// Privacy settings configuration
class PrivacySettings {
  const PrivacySettings({
    required this.hideFromRecents,
    required this.requireAuthentication,
    required this.blurInBackground,
    required this.incognitoMode,
    this.authenticationTimeout = 300, // 5 minutes
  });

  final bool hideFromRecents;
  final bool requireAuthentication;
  final bool blurInBackground;
  final bool incognitoMode;
  final int authenticationTimeout; // seconds
}

/// Content filter settings
class ContentFilterSettings {
  const ContentFilterSettings({
    required this.showNsfwContent,
    required this.blacklistedTags,
    required this.whitelistedTags,
    required this.minimumRating,
    this.ageRestriction,
  });

  final bool showNsfwContent;
  final List<String> blacklistedTags;
  final List<String> whitelistedTags;
  final double minimumRating;
  final int? ageRestriction;
}

/// Network settings configuration
class NetworkSettings {
  const NetworkSettings({
    required this.connectionTimeout,
    required this.readTimeout,
    required this.maxRetries,
    required this.useProxy,
    this.userAgent,
  });

  final int connectionTimeout; // seconds
  final int readTimeout; // seconds
  final int maxRetries;
  final bool useProxy;
  final String? userAgent;
}

/// Network status information
class NetworkStatus {
  const NetworkStatus({
    required this.isConnected,
    required this.connectionType,
    required this.responseTime,
    this.error,
  });

  final bool isConnected;
  final String connectionType;
  final int responseTime; // milliseconds
  final String? error;
}

/// Proxy settings configuration
class ProxySettings {
  const ProxySettings({
    required this.enabled,
    this.host,
    this.port,
    this.username,
    this.password,
    this.type = 'HTTP',
  });

  final bool enabled;
  final String? host;
  final int? port;
  final String? username;
  final String? password;
  final String type;

  bool get isConfigured => enabled && host != null && port != null;
}

/// Backup settings configuration
class BackupSettings {
  const BackupSettings({
    required this.autoBackup,
    required this.backupFrequency,
    required this.includeImages,
    required this.cloudBackup,
    this.maxBackups = 5,
  });

  final bool autoBackup;
  final BackupFrequency backupFrequency;
  final bool includeImages;
  final bool cloudBackup;
  final int maxBackups;
}

/// Backup frequency options
enum BackupFrequency {
  daily,
  weekly,
  monthly,
  manual,
}

/// Backup information
class BackupInfo {
  const BackupInfo({
    required this.id,
    required this.createdAt,
    required this.size,
    required this.type,
    this.description,
  });

  final String id;
  final DateTime createdAt;
  final int size; // bytes
  final BackupType type;
  final String? description;
}

/// Backup types
enum BackupType {
  manual,
  automatic,
  cloud,
}

/// Backup result
class BackupResult {
  const BackupResult({
    required this.success,
    required this.backupId,
    required this.size,
    this.error,
  });

  final bool success;
  final String? backupId;
  final int size;
  final String? error;
}

/// Restore result
class RestoreResult {
  const RestoreResult({
    required this.success,
    required this.restoredItems,
    this.error,
  });

  final bool success;
  final int restoredItems;
  final String? error;
}

/// Advanced settings configuration
class AdvancedSettings {
  const AdvancedSettings({
    required this.enableLogging,
    required this.logLevel,
    required this.crashReporting,
    required this.analyticsEnabled,
    this.maxCacheSize = 500, // MB
    this.maxLogFiles = 10,
  });

  final bool enableLogging;
  final LogLevel logLevel;
  final bool crashReporting;
  final bool analyticsEnabled;
  final int maxCacheSize;
  final int maxLogFiles;
}

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// Debug settings configuration
class DebugSettings {
  const DebugSettings({
    required this.showDebugInfo,
    required this.enableTestMode,
    required this.mockNetworkCalls,
    required this.showPerformanceOverlay,
  });

  final bool showDebugInfo;
  final bool enableTestMode;
  final bool mockNetworkCalls;
  final bool showPerformanceOverlay;
}

/// Clear data result
class ClearDataResult {
  const ClearDataResult({
    required this.success,
    required this.clearedItems,
    required this.freedSpace,
    this.error,
  });

  final bool success;
  final int clearedItems;
  final int freedSpace; // bytes
  final String? error;
}

/// Migration status information
class MigrationStatus {
  const MigrationStatus({
    required this.currentVersion,
    required this.targetVersion,
    required this.needsMigration,
    this.migrationSteps,
  });

  final String currentVersion;
  final String targetVersion;
  final bool needsMigration;
  final List<String>? migrationSteps;
}

/// Migration result
class MigrationResult {
  const MigrationResult({
    required this.success,
    required this.migratedSettings,
    this.error,
  });

  final bool success;
  final int migratedSettings;
  final String? error;
}
