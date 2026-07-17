import '../entities/entities.dart' hide ThemeOption;
import '../entities/settings/settings.dart';

/// Repository interface for app settings and preferences
abstract class SettingsRepository {
  // ==================== USER PREFERENCES ====================

  /// Get current user preferences
  Future<UserPreferences> getUserPreferences();

  /// Update user preferences
  Future<void> updateUserPreferences(UserPreferences preferences);

  /// Reset preferences to default values
  Future<UserPreferences> resetToDefaults();

  /// Get specific preference value
  Future<T> getPreference<T>(String key, T defaultValue);

  /// Set specific preference value
  Future<void> setPreference<T>(String key, T value);

  /// Remove specific preference
  Future<void> removePreference(String key);

  /// Check if preference exists
  Future<bool> hasPreference(String key);

  // ==================== THEME SETTINGS ====================

  Future<ThemeSettings> getThemeSettings();
  Future<void> updateThemeSettings(ThemeSettings settings);
  Future<List<ThemeOption>> getAvailableThemes();
  Future<CustomTheme> createCustomTheme(CustomTheme theme);
  Future<void> deleteCustomTheme(String themeId);
  Future<List<CustomTheme>> getCustomThemes();

  // ==================== READER SETTINGS ====================

  Future<ReaderSettingsEntity> getReaderSettingsEntity();
  Future<void> updateReaderSettingsEntity(ReaderSettingsEntity settings);
  Future<List<ReadingDirection>> getReadingDirections();

  // ==================== DOWNLOAD SETTINGS ====================

  Future<DownloadSettings> getDownloadSettings();
  Future<void> updateDownloadSettings(DownloadSettings settings);

  // ==================== PRIVACY SETTINGS ====================

  Future<PrivacySettings> getPrivacySettings();
  Future<void> updatePrivacySettings(PrivacySettings settings);
  Future<ContentFilterSettings> getContentFilterSettings();
  Future<void> updateContentFilterSettings(ContentFilterSettings settings);

  // ==================== NETWORK SETTINGS ====================

  Future<NetworkSettings> getNetworkSettings();
  Future<void> updateNetworkSettings(NetworkSettings settings);
  Future<NetworkStatus> testNetworkConnection();
  Future<ProxySettings> getProxySettings();
  Future<void> updateProxySettings(ProxySettings settings);

  // ==================== BACKUP SETTINGS ====================

  Future<BackupSettings> getBackupSettings();
  Future<void> updateBackupSettings(BackupSettings settings);
  Future<List<BackupInfo>> getBackupHistory();
  Future<BackupResult> createBackup();
  Future<RestoreResult> restoreFromBackup(String backupId);

  // ==================== ADVANCED SETTINGS ====================

  Future<AdvancedSettings> getAdvancedSettings();
  Future<void> updateAdvancedSettings(AdvancedSettings settings);
  Future<DebugSettings> getDebugSettings();
  Future<void> updateDebugSettings(DebugSettings settings);
  Future<ClearDataResult> clearAppData({
    bool keepSettings = true,
    bool keepFavorites = false,
    bool keepHistory = false,
  });

  // ==================== SETTINGS EXPORT/IMPORT ====================

  Future<String> exportSettings({bool includeCustomThemes = true});
  Future<void> importSettings({
    required String jsonData,
    bool mergeWithExisting = true,
  });
  Future<MigrationStatus> getMigrationStatus();
  Future<MigrationResult> migrateSettings({
    required String fromVersion,
    required String toVersion,
  });
}
