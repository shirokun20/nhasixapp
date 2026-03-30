import '../base_usecase.dart';
import '../../repositories/repositories.dart';

/// Use case for removing specific item from reading history
class RemoveHistoryItemUseCase extends UseCase<void, RemoveHistoryItemParams> {
  RemoveHistoryItemUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<void> call(RemoveHistoryItemParams params) async {
    try {
      // Validate parameters
      if (params.contentId.trim().isEmpty) {
        throw const ValidationException('Content ID cannot be empty');
      }

      // Remove item from history
      await _userDataRepository.removeFromHistory(params.contentId);
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to remove history item: ${e.toString()}');
    }
  }
}

/// Parameters for RemoveHistoryItemUseCase
class RemoveHistoryItemParams extends UseCaseParams {
  const RemoveHistoryItemParams({
    required this.contentId,
  });

  final String contentId;

  @override
  List<Object?> get props => [contentId];

  RemoveHistoryItemParams copyWith({
    String? contentId,
  }) {
    return RemoveHistoryItemParams(
      contentId: contentId ?? this.contentId,
    );
  }

  /// Create params from content ID
  factory RemoveHistoryItemParams.fromContentId(String contentId) {
    return RemoveHistoryItemParams(contentId: contentId);
  }
}
