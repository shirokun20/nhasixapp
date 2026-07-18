import '../../entities/reader_settings_entity.dart';
import '../../repositories/reader_settings_repository.dart';

/// Use case for fetching reader settings
class GetReaderSettingsUseCase {
  GetReaderSettingsUseCase(this._repository);

  final ReaderSettingsEntityRepository _repository;

  Future<ReaderSettingsEntity> call() {
    return _repository.getReaderSettingsEntity();
  }
}
