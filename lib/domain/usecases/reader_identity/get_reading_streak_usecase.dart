import '../../entities/reading_statistics.dart';
import '../../repositories/user_data_repository.dart';
import '../base_usecase.dart';

// Reading streak read/write entry point for the streak card and launcher
// widget. NoParams: the streak always reflects the whole local library.
class GetReadingStreakUseCase extends NoParamsUseCase<ReadingStatistics> {
  GetReadingStreakUseCase({
    required UserDataRepository userDataRepository,
  }) : _userData = userDataRepository;

  final UserDataRepository _userData;

  @override
  Future<ReadingStatistics> call() => _userData.getReadingStatistics();

  /// Streak evaluated against an explicit clock, so day rollover can be
  /// tested without waiting for midnight.
  Future<ReadingStatistics> forDate(DateTime now) =>
      _userData.getReadingStatistics(now: now);

  Future<ReadingStatistics> recordRead({
    DateTime? date,
    String? contentId,
  }) =>
      _userData.recordReadingDay(date: date, contentId: contentId);

  Future<String?> getLastReadContentId() => _userData.getLastReadContentId();
}

typedef GetReadingStreak = GetReadingStreakUseCase;
