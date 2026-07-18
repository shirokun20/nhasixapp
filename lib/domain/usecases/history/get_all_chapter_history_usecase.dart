import '../../entities/history.dart';
import '../../repositories/user_data_repository.dart';

/// Use case for getting all chapter history for a content item
class GetAllChapterHistoryUseCase {
  GetAllChapterHistoryUseCase(this._repository);

  final UserDataRepository _repository;

  Future<List<History>> call(String contentId) {
    return _repository.getAllChapterHistory(contentId);
  }
}
