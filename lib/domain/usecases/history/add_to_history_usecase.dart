import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';
import '../../repositories/repositories.dart';

/// Use case for adding content to reading history
class AddToHistoryUseCase extends UseCase<void, AddToHistoryParams> {
  AddToHistoryUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<void> call(AddToHistoryParams params) async {
    try {
      // Validate parameters
      if (!params.contentId.isValid) {
        throw ValidationException(
            'Invalid content ID: ${params.contentId.value}');
      }

      if (params.page < 1) {
        throw const ValidationException('Page number must be greater than 0');
      }

      if (params.totalPages < 1) {
        throw const ValidationException('Total pages must be greater than 0');
      }

      if (params.page > params.totalPages) {
        throw const ValidationException(
            'Current page cannot exceed total pages');
      }

      if (params.timeSpent != null && params.timeSpent!.isNegative) {
        throw const ValidationException('Time spent cannot be negative');
      }

      // Create history entry and save it
      final history = History(
        contentId: params.contentId.value,
        lastViewed: DateTime.now(),
        lastPage: params.page,
        totalPages: params.totalPages,
        timeSpent: params.timeSpent ?? Duration.zero,
        isCompleted: params.page >= params.totalPages,
        coverUrl: params.coverUrl,
        title: params.title,
      );

      await _userDataRepository.saveHistory(history);
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to add to history: ${e.toString()}');
    }
  }
}

/// Parameters for AddToHistoryUseCase
class AddToHistoryParams extends UseCaseParams {
  const AddToHistoryParams({
    required this.contentId,
    required this.page,
    required this.totalPages,
    this.timeSpent,
    this.coverUrl,
    this.title,
  });

  final ContentId contentId;
  final int page;
  final int totalPages;
  final Duration? timeSpent;
  final String? coverUrl;
  final String? title;

  @override
  List<Object?> get props => [contentId, page, totalPages, timeSpent];

  AddToHistoryParams copyWith({
    ContentId? contentId,
    int? page,
    int? totalPages,
    Duration? timeSpent,
    String? coverUrl,
    String? title,
  }) {
    return AddToHistoryParams(
      contentId: contentId ?? this.contentId,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      timeSpent: timeSpent ?? this.timeSpent,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Create params from string ID
  factory AddToHistoryParams.fromString(
    String contentId,
    int page,
    int totalPages, {
    Duration? timeSpent,
    String? coverUrl,
    String? title,
  }) {
    return AddToHistoryParams(
      contentId: ContentId.fromString(contentId),
      page: page,
      totalPages: totalPages,
      timeSpent: timeSpent,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Create params from int ID
  factory AddToHistoryParams.fromInt(
    int contentId,
    int page,
    int totalPages, {
    Duration? timeSpent,
    String? coverUrl,
    String? title,
  }) {
    return AddToHistoryParams(
      contentId: ContentId.fromInt(contentId),
      page: page,
      totalPages: totalPages,
      timeSpent: timeSpent,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Create params for starting to read (page 1)
  factory AddToHistoryParams.startReading(
    ContentId contentId,
    int totalPages,
  ) {
    return AddToHistoryParams(
      contentId: contentId,
      page: 1,
      totalPages: totalPages,
    );
  }

  /// Create params for completing reading (last page)
  factory AddToHistoryParams.completeReading(
    ContentId contentId,
    int totalPages, {
    Duration? timeSpent,
    String? coverUrl,
    String? title,
  }) {
    return AddToHistoryParams(
      contentId: contentId,
      page: totalPages,
      totalPages: totalPages,
      timeSpent: timeSpent,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Create params with reading time
  AddToHistoryParams withTimeSpent(Duration timeSpent) {
    return copyWith(timeSpent: timeSpent);
  }

  /// Create params for next page
  AddToHistoryParams nextPage({Duration? additionalTime}) {
    return copyWith(
      page: page < totalPages ? page + 1 : totalPages,
      timeSpent: additionalTime,
    );
  }

  /// Create params for previous page
  AddToHistoryParams previousPage({Duration? additionalTime}) {
    return copyWith(
      page: page > 1 ? page - 1 : 1,
      timeSpent: additionalTime,
    );
  }

  /// Check if this is the first page
  bool get isFirstPage => page == 1;

  /// Check if this is the last page
  bool get isLastPage => page == totalPages;

  /// Get reading progress percentage
  double get progressPercentage => page / totalPages;
}
