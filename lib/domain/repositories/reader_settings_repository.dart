import '../entities/reader_settings_entity.dart';

/// Repository interface for reader settings persistence
abstract class ReaderSettingsEntityRepository {
  /// Get complete reader settings
  ///
  /// Returns current reader settings with defaults if not set
  /// Handles errors gracefully by returning default settings
  Future<ReaderSettingsEntity> getReaderSettingsEntity();

  /// Save complete reader settings
  ///
  /// [settings] - Complete settings object to save
  /// Handles errors gracefully without throwing exceptions
  Future<void> saveReaderSettingsEntity(ReaderSettingsEntity settings);

  /// Save reading mode preference
  ///
  /// [mode] - Reading mode to save
  /// Updates only the reading mode while preserving other settings
  Future<void> saveReadingMode(ReadingMode mode);

  /// Save keep screen on preference
  ///
  /// [keepScreenOn] - Whether to keep screen on during reading
  /// Updates only the keep screen on setting while preserving other settings
  Future<void> saveKeepScreenOn(bool keepScreenOn);

  /// Save show UI preference
  ///
  /// [showUI] - Whether to show UI elements in reader
  /// Updates only the show UI setting while preserving other settings
  Future<void> saveShowUI(bool showUI);

  /// Save tap direction preference
  ///
  /// [tapDirection] - Tap direction for prev/next navigation
  Future<void> saveTapDirection(TapDirection tapDirection);

  /// Reset all reader settings to defaults
  ///
  /// Clears all stored reader preferences and returns to default values
  /// Handles errors gracefully without throwing exceptions
  Future<void> resetToDefaults();
}
