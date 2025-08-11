import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/reader_settings_repository.dart';
import '../models/reader_settings_model.dart';

/// Implementation of ReaderSettingsRepository using SharedPreferences
class ReaderSettingsRepositoryImpl implements ReaderSettingsRepository {
  const ReaderSettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  // Storage keys
  static const String _keyReaderSettings = 'reader_settings';
  static const String _keyReadingMode = 'reading_mode';
  static const String _keyKeepScreenOn = 'keep_screen_on';
  static const String _keyShowUI = 'show_ui';

  @override
  Future<ReaderSettings> getReaderSettings() async {
    try {
      // Try to get complete settings first (new format)
      final settingsJson = _prefs.getString(_keyReaderSettings);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        return ReaderSettings.fromJsonString(settingsJson);
      }

      // Fallback to individual keys for backward compatibility (old format)
      final readingModeString = _prefs.getString(_keyReadingMode);
      final keepScreenOn = _prefs.getBool(_keyKeepScreenOn);
      final showUI = _prefs.getBool(_keyShowUI);

      // Parse reading mode with fallback to default
      ReadingMode readingMode = ReadingMode.singlePage;
      if (readingModeString != null) {
        try {
          readingMode = ReadingMode.values.firstWhere(
            (mode) => mode.name == readingModeString,
            orElse: () => ReadingMode.singlePage,
          );
        } catch (e) {
          developer.log(
            'Invalid reading mode in preferences: $readingModeString',
            name: 'ReaderSettingsRepository',
          );
        }
      }

      return ReaderSettings(
        readingMode: readingMode,
        keepScreenOn: keepScreenOn ?? false,
        showUI: showUI ?? true,
      );
    } catch (e, stackTrace) {
      // Log error and return defaults for graceful degradation
      developer.log(
        'Error loading reader settings: $e',
        name: 'ReaderSettingsRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return const ReaderSettings();
    }
  }

  @override
  Future<void> saveReaderSettings(ReaderSettings settings) async {
    try {
      // Save as complete JSON object (new format)
      final settingsJson = settings.toJsonString();
      await _prefs.setString(_keyReaderSettings, settingsJson);

      // Also save individual keys for backward compatibility
      await Future.wait([
        _prefs.setString(_keyReadingMode, settings.readingMode.name),
        _prefs.setBool(_keyKeepScreenOn, settings.keepScreenOn),
        _prefs.setBool(_keyShowUI, settings.showUI),
      ]);
    } catch (e, stackTrace) {
      // Log error but don't throw to avoid breaking the app
      developer.log(
        'Error saving reader settings: $e',
        name: 'ReaderSettingsRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveReadingMode(ReadingMode mode) async {
    try {
      // Get current settings and update only reading mode
      final currentSettings = await getReaderSettings();
      final updatedSettings = currentSettings.copyWith(readingMode: mode);
      await saveReaderSettings(updatedSettings);
    } catch (e, stackTrace) {
      // Log error but don't throw to avoid breaking the app
      developer.log(
        'Error saving reading mode: $e',
        name: 'ReaderSettingsRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveKeepScreenOn(bool keepScreenOn) async {
    try {
      // Get current settings and update only keep screen on
      final currentSettings = await getReaderSettings();
      final updatedSettings =
          currentSettings.copyWith(keepScreenOn: keepScreenOn);
      await saveReaderSettings(updatedSettings);
    } catch (e, stackTrace) {
      // Log error but don't throw to avoid breaking the app
      developer.log(
        'Error saving keep screen on setting: $e',
        name: 'ReaderSettingsRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> saveShowUI(bool showUI) async {
    try {
      // Get current settings and update only show UI
      final currentSettings = await getReaderSettings();
      final updatedSettings = currentSettings.copyWith(showUI: showUI);
      await saveReaderSettings(updatedSettings);
    } catch (e, stackTrace) {
      // Log error but don't throw to avoid breaking the app
      developer.log(
        'Error saving show UI setting: $e',
        name: 'ReaderSettingsRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> resetToDefaults() async {
    try {
      // Remove all reader settings keys
      await Future.wait([
        _prefs.remove(_keyReaderSettings),
        _prefs.remove(_keyReadingMode),
        _prefs.remove(_keyKeepScreenOn),
        _prefs.remove(_keyShowUI),
      ]);
    } catch (e, stackTrace) {
      // Log error but don't throw to avoid breaking the app
      developer.log(
        'Error resetting reader settings to defaults: $e',
        name: 'ReaderSettingsRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
