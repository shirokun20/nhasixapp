import '../base_usecase.dart';
import '../../repositories/repositories.dart';

/// Use case for getting total history count
class GetHistoryCountUseCase extends UseCase<int, NoParams> {
  GetHistoryCountUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<int> call(NoParams params) async {
    try {
      // Get history count from repository
      final count = await _userDataRepository.getHistoryCount();
      return count;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to get history count: ${e.toString()}');
    }
  }
}
