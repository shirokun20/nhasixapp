import '../../entities/reader_position.dart';
import '../../repositories/reader_repository.dart';

/// Use case for saving reader position
class SaveReaderPositionUseCase {
  SaveReaderPositionUseCase(this._repository);

  final ReaderRepository _repository;

  Future<void> call(ReaderPosition position) {
    return _repository.saveReaderPosition(position);
  }
}
