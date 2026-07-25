import '../entities/reader_settings_entity.dart';

abstract class ReaderSettingsEntityRepository {
  Future<ReaderSettingsEntity> getReaderSettingsEntity();

  Future<void> saveReaderSettingsEntity(ReaderSettingsEntity settings);

  Future<void> saveReadingMode(ReadingMode mode);

  Future<void> saveKeepScreenOn(bool keepScreenOn);

  Future<void> saveShowUI(bool showUI);

  Future<void> saveTapDirection(TapDirection tapDirection);

  Future<void> resetToDefaults();
}
