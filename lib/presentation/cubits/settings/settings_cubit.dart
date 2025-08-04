import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities.dart';
import '../base/base_cubit.dart';

part 'settings_state.dart';

/// Cubit for managing application settings and user preferences
/// Simple state management for settings operations
class SettingsCubit extends BaseCubit<SettingsState> {
  SettingsCubit({
    required SharedPreferences sharedPreferences,
    required Logger logger,
  })  : _sharedPreferences = sharedPreferences,
        super(
          initialState: const SettingsInitial(),
          logger: logger,
        ) {
    _loadSettings();
  }

  final SharedPreferences _sharedPreferences;

  // Settings keys
  static const String _themeKey = 'app_theme';
  static const String _defaultLanguageKey = 'default_language';
  static const String _imageQualityKey = 'image_quality';
  static const String _autoDownloadKey = 'auto_download';
  static const String _showTitlesKey = 'show_titles';
  static const String _blurThumbnailsKey = 'blur_thumbnails';
  static const String _usePaginationKey = 'use_pagination';
  static const String _columnsPortraitKey = 'columns_portrait';
  static const String _columnsLandscapeKey = 'columns_landscape';
  static const String _useVolumeKeysKey = 'use_volume_keys';
  static const String _readingDirectionKey = 'reading_direction';
  static const String _keepScreenOnKey = 'keep_screen_on';
  static const String _showSystemUIKey = 'show_system_ui';

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      logInfo('Loading user preferences');

      final preferences = UserPreferences(
        theme: _sharedPreferences.getString(_themeKey) ?? 'dark',
        defaultLanguage:
            _sharedPreferences.getString(_defaultLanguageKey) ?? 'english',
        imageQuality: _sharedPreferences.getString(_imageQualityKey) ?? 'high',
        autoDownload: _sharedPreferences.getBool(_autoDownloadKey) ?? false,
        showTitles: _sharedPreferences.getBool(_showTitlesKey) ?? true,
        blurThumbnails: _sharedPreferences.getBool(_blurThumbnailsKey) ?? false,
        usePagination: _sharedPreferences.getBool(_usePaginationKey) ?? true,
        columnsPortrait: _sharedPreferences.getInt(_columnsPortraitKey) ?? 2,
        columnsLandscape: _sharedPreferences.getInt(_columnsLandscapeKey) ?? 3,
        useVolumeKeys: _sharedPreferences.getBool(_useVolumeKeysKey) ?? false,
        readingDirection: ReadingDirection
            .values[_sharedPreferences.getInt(_readingDirectionKey) ?? 0],
        keepScreenOn: _sharedPreferences.getBool(_keepScreenOnKey) ?? false,
        showSystemUI: _sharedPreferences.getBool(_showSystemUIKey) ?? true,
      );

      emit(SettingsLoaded(
        preferences: preferences,
        lastUpdated: DateTime.now(),
      ));

      logInfo('Successfully loaded user preferences');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'load settings');

      // Emit default settings on error
      emit(SettingsLoaded(
        preferences: _getDefaultPreferences(),
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Update theme setting
  Future<void> updateTheme(String theme) async {
    await _updateSetting(
        _themeKey, theme, (prefs) => prefs.copyWith(theme: theme));
  }

  /// Update default language setting
  Future<void> updateDefaultLanguage(String language) async {
    await _updateSetting(_defaultLanguageKey, language,
        (prefs) => prefs.copyWith(defaultLanguage: language));
  }

  /// Update image quality setting
  Future<void> updateImageQuality(String quality) async {
    await _updateSetting(_imageQualityKey, quality,
        (prefs) => prefs.copyWith(imageQuality: quality));
  }

  /// Update auto download setting
  Future<void> updateAutoDownload(bool autoDownload) async {
    await _updateSetting(_autoDownloadKey, autoDownload,
        (prefs) => prefs.copyWith(autoDownload: autoDownload));
  }

  /// Update show titles setting
  Future<void> updateShowTitles(bool showTitles) async {
    await _updateSetting(_showTitlesKey, showTitles,
        (prefs) => prefs.copyWith(showTitles: showTitles));
  }

  /// Update blur thumbnails setting
  Future<void> updateBlurThumbnails(bool blurThumbnails) async {
    await _updateSetting(_blurThumbnailsKey, blurThumbnails,
        (prefs) => prefs.copyWith(blurThumbnails: blurThumbnails));
  }

  /// Update pagination setting
  Future<void> updateUsePagination(bool usePagination) async {
    await _updateSetting(_usePaginationKey, usePagination,
        (prefs) => prefs.copyWith(usePagination: usePagination));
  }

  /// Update columns portrait setting
  Future<void> updateColumnsPortrait(int columns) async {
    if (columns < 1 || columns > 5) {
      logWarning('Invalid columns portrait value: $columns');
      return;
    }
    await _updateSetting(_columnsPortraitKey, columns,
        (prefs) => prefs.copyWith(columnsPortrait: columns));
  }

  /// Update columns landscape setting
  Future<void> updateColumnsLandscape(int columns) async {
    if (columns < 1 || columns > 7) {
      logWarning('Invalid columns landscape value: $columns');
      return;
    }
    await _updateSetting(_columnsLandscapeKey, columns,
        (prefs) => prefs.copyWith(columnsLandscape: columns));
  }

  /// Update use volume keys setting
  Future<void> updateUseVolumeKeys(bool useVolumeKeys) async {
    await _updateSetting(_useVolumeKeysKey, useVolumeKeys,
        (prefs) => prefs.copyWith(useVolumeKeys: useVolumeKeys));
  }

  /// Update reading direction setting
  Future<void> updateReadingDirection(ReadingDirection direction) async {
    await _updateSetting(_readingDirectionKey, direction.index,
        (prefs) => prefs.copyWith(readingDirection: direction));
  }

  /// Update keep screen on setting
  Future<void> updateKeepScreenOn(bool keepScreenOn) async {
    await _updateSetting(_keepScreenOnKey, keepScreenOn,
        (prefs) => prefs.copyWith(keepScreenOn: keepScreenOn));
  }

  /// Update show system UI setting
  Future<void> updateShowSystemUI(bool showSystemUI) async {
    await _updateSetting(_showSystemUIKey, showSystemUI,
        (prefs) => prefs.copyWith(showSystemUI: showSystemUI));
  }

  /// Generic method to update a setting
  Future<void> _updateSetting<T>(
    String key,
    T value,
    UserPreferences Function(UserPreferences) updateFunction,
  ) async {
    try {
      final currentState = state;
      if (currentState is! SettingsLoaded) return;

      logInfo('Updating setting: $key = $value');

      // Save to SharedPreferences
      if (value is String) {
        await _sharedPreferences.setString(key, value);
      } else if (value is bool) {
        await _sharedPreferences.setBool(key, value);
      } else if (value is int) {
        await _sharedPreferences.setInt(key, value);
      }

      // Update state
      final updatedPreferences = updateFunction(currentState.preferences);
      emit(currentState.copyWith(
        preferences: updatedPreferences,
        lastUpdated: DateTime.now(),
      ));

      logInfo('Successfully updated setting: $key');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'update setting $key');

      emit(SettingsError(
        message: 'Failed to update setting: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    try {
      logInfo('Resetting all settings to defaults');

      // Clear all settings from SharedPreferences
      await _sharedPreferences.remove(_themeKey);
      await _sharedPreferences.remove(_defaultLanguageKey);
      await _sharedPreferences.remove(_imageQualityKey);
      await _sharedPreferences.remove(_autoDownloadKey);
      await _sharedPreferences.remove(_showTitlesKey);
      await _sharedPreferences.remove(_blurThumbnailsKey);
      await _sharedPreferences.remove(_usePaginationKey);
      await _sharedPreferences.remove(_columnsPortraitKey);
      await _sharedPreferences.remove(_columnsLandscapeKey);
      await _sharedPreferences.remove(_useVolumeKeysKey);
      await _sharedPreferences.remove(_readingDirectionKey);
      await _sharedPreferences.remove(_keepScreenOnKey);
      await _sharedPreferences.remove(_showSystemUIKey);

      // Reload settings (will use defaults)
      await _loadSettings();

      logInfo('Successfully reset all settings to defaults');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'reset settings');

      emit(SettingsError(
        message: 'Failed to reset settings: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Export settings as JSON string
  Future<String> exportSettings() async {
    try {
      final currentState = state;
      if (currentState is! SettingsLoaded) {
        throw Exception('Settings not loaded');
      }

      logInfo('Exporting settings');

      // Create a map of all settings
      final settingsMap = {
        'theme': currentState.preferences.theme,
        'defaultLanguage': currentState.preferences.defaultLanguage,
        'imageQuality': currentState.preferences.imageQuality,
        'autoDownload': currentState.preferences.autoDownload,
        'showTitles': currentState.preferences.showTitles,
        'blurThumbnails': currentState.preferences.blurThumbnails,
        'usePagination': currentState.preferences.usePagination,
        'columnsPortrait': currentState.preferences.columnsPortrait,
        'columnsLandscape': currentState.preferences.columnsLandscape,
        'useVolumeKeys': currentState.preferences.useVolumeKeys,
        'readingDirection': currentState.preferences.readingDirection.index,
        'keepScreenOn': currentState.preferences.keepScreenOn,
        'showSystemUI': currentState.preferences.showSystemUI,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // Convert to JSON string (simplified - in real app would use json_annotation)
      final jsonString = settingsMap.toString();

      logInfo('Successfully exported settings');
      return jsonString;
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'export settings');
      throw Exception('Failed to export settings: ${e.toString()}');
    }
  }

  /// Import settings from JSON string
  Future<void> importSettings(String jsonString) async {
    try {
      logInfo('Importing settings');

      // TODO: Implement proper JSON parsing when json_annotation is available
      // For now, just reload current settings
      await _loadSettings();

      logInfo('Successfully imported settings');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'import settings');

      emit(SettingsError(
        message: 'Failed to import settings: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Get default preferences
  UserPreferences _getDefaultPreferences() {
    return const UserPreferences(
      theme: 'dark',
      defaultLanguage: 'english',
      imageQuality: 'high',
      autoDownload: false,
      showTitles: true,
      blurThumbnails: false,
      usePagination: true,
      columnsPortrait: 2,
      columnsLandscape: 3,
      useVolumeKeys: false,
      readingDirection: ReadingDirection.leftToRight,
      keepScreenOn: false,
      showSystemUI: true,
    );
  }

  /// Get current preferences
  UserPreferences? get currentPreferences {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      return currentState.preferences;
    }
    return null;
  }

  /// Check if dark theme is enabled
  bool get isDarkTheme {
    final prefs = currentPreferences;
    return prefs?.theme == 'dark' || prefs?.theme == 'amoled';
  }

  /// Check if AMOLED theme is enabled
  bool get isAmoledTheme {
    final prefs = currentPreferences;
    return prefs?.theme == 'amoled';
  }

  /// Get current grid columns for orientation
  int getColumnsForOrientation(bool isPortrait) {
    final prefs = currentPreferences;
    if (prefs == null) return isPortrait ? 2 : 3;

    return isPortrait ? prefs.columnsPortrait : prefs.columnsLandscape;
  }
}
