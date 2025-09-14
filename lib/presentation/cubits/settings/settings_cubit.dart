import '../../../domain/entities/entities.dart';
import '../../../services/preferences_service.dart';
import '../../../services/app_disguise_service.dart';
import '../../../l10n/app_localizations.dart';
import '../base/base_cubit.dart';

part 'settings_state.dart';

/// Cubit for managing application settings and user preferences
/// Simple state management for settings operations
class SettingsCubit extends BaseCubit<SettingsState> {
  SettingsCubit({
    required PreferencesService preferencesService,
    required super.logger,
    this.localizations,
  })  : _preferencesService = preferencesService,
        super(
          initialState: const SettingsInitial(),
        ) {
    _loadSettings();
  }

  final PreferencesService _preferencesService;
  final AppLocalizations? localizations;

  /// Load settings from PreferencesService
  Future<void> _loadSettings() async {
    try {
      logInfo('Loading user preferences');
      
      final preferences = await _preferencesService.getUserPreferences();

      // Check current disguise mode from Android
      try {
        final currentAndroidMode = await AppDisguiseService.getCurrentDisguiseMode();
        logInfo('Current Android disguise mode: $currentAndroidMode, saved mode: ${preferences.disguiseMode}');

        // If Android mode differs from saved preferences, update preferences
        if (currentAndroidMode != preferences.disguiseMode) {
          logInfo('Updating preferences to match Android mode: $currentAndroidMode');
          final updatedPreferences = preferences.copyWith(disguiseMode: currentAndroidMode);
          await _preferencesService.saveUserPreferences(updatedPreferences);

          emit(SettingsLoaded(
            preferences: updatedPreferences,
            lastUpdated: DateTime.now(),
          ));
        } else {
          emit(SettingsLoaded(
            preferences: preferences,
            lastUpdated: DateTime.now(),
          ));
        }
      } catch (e) {
        logWarning('Failed to get current disguise mode from Android: $e');
        emit(SettingsLoaded(
          preferences: preferences,
          lastUpdated: DateTime.now(),
        ));
      }

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
    await _updateSetting((prefs) => prefs.copyWith(theme: theme));
  }

  /// Update default language setting
  Future<void> updateDefaultLanguage(String language) async {
    await _updateSetting((prefs) => prefs.copyWith(defaultLanguage: language));
  }

  /// Update image quality setting
  Future<void> updateImageQuality(String quality) async {
    await _updateSetting((prefs) => prefs.copyWith(imageQuality: quality));
  }

  /// Update auto download setting
  Future<void> updateAutoDownload(bool autoDownload) async {
    await _updateSetting((prefs) => prefs.copyWith(autoDownload: autoDownload));
  }

  /// Update show titles setting
  Future<void> updateShowTitles(bool showTitles) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(showTitles: showTitles));
  }

  /// Update blur thumbnails setting
  Future<void> updateBlurThumbnails(bool blurThumbnails) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(blurThumbnails: blurThumbnails));
  }

  /// Update pagination setting
  Future<void> updateUsePagination(bool usePagination) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(usePagination: usePagination));
  }

  /// Update columns portrait setting
  Future<void> updateColumnsPortrait(int columns) async {
    if (columns < 1 || columns > 5) {
      logWarning('Invalid columns portrait value: $columns');
      return;
    }
    await _updateSetting(
        (prefs) => prefs.copyWith(columnsPortrait: columns));
  }

  /// Update columns landscape setting
  Future<void> updateColumnsLandscape(int columns) async {
    if (columns < 1 || columns > 7) {
      logWarning('Invalid columns landscape value: $columns');
      return;
    }
    await _updateSetting(
        (prefs) => prefs.copyWith(columnsLandscape: columns));
  }

  /// Update use volume keys setting
  Future<void> updateUseVolumeKeys(bool useVolumeKeys) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(useVolumeKeys: useVolumeKeys));
  }

  /// Update reading direction setting
  Future<void> updateReadingDirection(ReadingDirection direction) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(readingDirection: direction));
  }

  /// Update keep screen on setting
  Future<void> updateKeepScreenOn(bool keepScreenOn) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(keepScreenOn: keepScreenOn));
  }

  /// Update show system UI setting
  Future<void> updateShowSystemUI(bool showSystemUI) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(showSystemUI: showSystemUI));
  }

  /// Update auto cleanup history setting
  Future<void> updateAutoCleanupHistory(bool autoCleanupHistory) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(autoCleanupHistory: autoCleanupHistory));
  }

  /// Update history cleanup interval setting
  Future<void> updateHistoryCleanupInterval(int intervalHours) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(historyCleanupIntervalHours: intervalHours));
  }

  /// Update max history days setting
  Future<void> updateMaxHistoryDays(int maxDays) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(maxHistoryDays: maxDays));
  }

  /// Update cleanup on inactivity setting
  Future<void> updateCleanupOnInactivity(bool cleanupOnInactivity) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(cleanupOnInactivity: cleanupOnInactivity));
  }

  /// Update inactivity cleanup days setting
  Future<void> updateInactivityCleanupDays(int inactivityDays) async {
    await _updateSetting(
        (prefs) => prefs.copyWith(inactivityCleanupDays: inactivityDays));
  }

  /// Update disguise mode setting with loading
  Future<void> updateDisguiseMode(String disguiseMode) async {
    try {
      // Emit loading state
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(currentState.copyWith(isUpdatingDisguiseMode: true));
      }

      // Update preferences directly (without calling _updateSetting to avoid double emit)
      final currentState2 = state;
      if (currentState2 is SettingsLoaded) {
        final updatedPreferences = currentState2.preferences.copyWith(disguiseMode: disguiseMode);
        await _preferencesService.saveUserPreferences(updatedPreferences);

        emit(currentState2.copyWith(
          preferences: updatedPreferences,
          lastUpdated: DateTime.now(),
          isUpdatingDisguiseMode: true, // Keep loading
        ));
      }

      // Apply disguise mode to Android
      await AppDisguiseService.setDisguiseMode(disguiseMode);

      // Small delay for UI feedback
      await Future.delayed(const Duration(milliseconds: 800));

    } catch (e) {
      logWarning('Failed to update disguise mode: $e');
    } finally {
      // Clear loading state
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(currentState.copyWith(isUpdatingDisguiseMode: false));
      }
    }
  }

  /// Generic method to update a setting
  Future<void> _updateSetting(
    UserPreferences Function(UserPreferences) updateFunction,
  ) async {
    try {
      final currentState = state;
      if (currentState is! SettingsLoaded) return;

      // Update preferences
      final updatedPreferences = updateFunction(currentState.preferences);
      
      logInfo('Updating settings via PreferencesService');

      // Save to SharedPreferences via PreferencesService
      await _preferencesService.saveUserPreferences(updatedPreferences);
      
      emit(currentState.copyWith(
        preferences: updatedPreferences,
        lastUpdated: DateTime.now(),
      ));

      logInfo('Successfully updated settings');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'update setting');

      emit(SettingsError(
        message: localizations?.failedToUpdateSetting(e.toString()) ?? 'Failed to update setting: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    try {
      logInfo('Resetting all settings to defaults');

      // Clear all settings via PreferencesService
      await _preferencesService.clear();

      // Reload settings (will use defaults)
      await _loadSettings();

      logInfo('Successfully reset all settings to defaults');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'reset settings');

      emit(SettingsError(
        message: localizations?.failedToResetSettings(e.toString()) ?? 'Failed to reset settings: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Export settings as JSON string
  Future<String> exportSettings() async {
    try {
      final currentState = state;
      if (currentState is! SettingsLoaded) {
        throw Exception(localizations?.settingsNotLoaded ?? 'Settings not loaded');
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
      throw Exception(localizations?.failedToExportSettings(e.toString()) ?? 'Failed to export settings: ${e.toString()}');
    }
  }

  /// Import settings from JSON string
  Future<void> importSettings(String jsonString) async {
    try {
      logInfo('Importing settings');

      // Implement proper JSON parsing when json_annotation is available
      // For now, just reload current settings
      await _loadSettings();

      logInfo('Successfully imported settings');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'import settings');

      emit(SettingsError(
        message: localizations?.failedToImportSettings(e.toString()) ?? 'Failed to import settings: ${e.toString()}',
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
      // History cleanup defaults
      autoCleanupHistory: false,
      historyCleanupIntervalHours: 24,
      maxHistoryDays: 30,
      cleanupOnInactivity: true,
      inactivityCleanupDays: 7,
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
