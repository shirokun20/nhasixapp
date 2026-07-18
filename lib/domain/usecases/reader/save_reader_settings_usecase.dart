import '../../entities/reader_settings_entity.dart';
import '../../repositories/reader_settings_repository.dart';

/// Use case for saving reader settings
class SaveReaderSettingsUseCase {
  SaveReaderSettingsUseCase(this._repository);

  final ReaderSettingsEntityRepository _repository;

  Future<void> call(ReaderSettingsEntity settings) {
    return _repository.saveReaderSettingsEntity(settings);
  }
}
