import '../base_usecase.dart';
import '../../repositories/repositories.dart';

/// Use case for clearing all reading history
class ClearHistoryUseCase extends UseCase<void, NoParams> {
  ClearHistoryUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<void> call(NoParams params) async {
    try {
      // Clear all history from repository
      await _userDataRepository.clearHistory();
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to clear history: ${e.toString()}');
    }
  }
}
