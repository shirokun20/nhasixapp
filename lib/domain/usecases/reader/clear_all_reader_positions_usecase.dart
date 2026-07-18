import '../../repositories/reader_repository.dart';

/// Use case for clearing all reader positions
class ClearAllReaderPositionsUseCase {
  ClearAllReaderPositionsUseCase(this._repository);

  final ReaderRepository _repository;

  Future<void> call() {
    return _repository.clearAllReaderPositions();
  }
}
