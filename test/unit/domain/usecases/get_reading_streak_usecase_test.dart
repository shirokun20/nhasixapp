import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/domain/entities/reading_statistics.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/domain/usecases/reader_identity/'
    'get_reading_streak_usecase.dart';

class _MockUserData extends Mock implements UserDataRepository {}

void main() {
  late _MockUserData userData;
  late GetReadingStreakUseCase usecase;

  final lastRead = DateTime(2026, 1, 10, 8);
  final stats = ReadingStatistics.streak(
    readingStreak: 5,
    lastReadDate: lastRead,
    readDays: [lastRead],
    totalContentRead: 12,
    completedContent: 3,
  );

  setUp(() {
    userData = _MockUserData();
    usecase = GetReadingStreakUseCase(userDataRepository: userData);

    when(() => userData.getReadingStatistics()).thenAnswer((_) async => stats);
    when(userData.getLastReadContentId).thenAnswer((_) async => 'content-1');
  });

  test('call() returns repository statistics', () async {
    final result = await usecase();

    expect(result, stats);
    expect(result.readingStreak, 5);
    expect(result.readDays, [lastRead]);
    verify(() => userData.getReadingStatistics()).called(1);
  });

  test('forDate() passes the clock through', () async {
    final now = DateTime(2026, 1, 10, 23, 59);
    when(() => userData.getReadingStatistics(now: now))
        .thenAnswer((_) async => stats);

    final result = await usecase.forDate(now);

    expect(result, stats);
    verify(() => userData.getReadingStatistics(now: now)).called(1);
  });

  test('recordRead() forwards date and contentId', () async {
    final refreshed = ReadingStatistics.streak(
      readingStreak: 6,
      lastReadDate: DateTime(2026, 1, 11),
    );
    when(() => userData.recordReadingDay(
          date: DateTime(2026, 1, 11),
          contentId: 'content-1',
        )).thenAnswer((_) async => refreshed);

    final result = await usecase.recordRead(
      date: DateTime(2026, 1, 11),
      contentId: 'content-1',
    );

    expect(result, refreshed);
    expect(result.readingStreak, 6);
    verify(() => userData.recordReadingDay(
          date: DateTime(2026, 1, 11),
          contentId: 'content-1',
        )).called(1);
  });

  test('recordRead() with no arguments records today', () async {
    when(() => userData.recordReadingDay(date: null, contentId: null))
        .thenAnswer((_) async => stats);

    final result = await usecase.recordRead();

    expect(result, stats);
    verify(() => userData.recordReadingDay(date: null, contentId: null))
        .called(1);
  });

  test('getLastReadContentId() delegates to repository', () async {
    expect(await usecase.getLastReadContentId(), 'content-1');
    verify(userData.getLastReadContentId).called(1);
  });

  test('getLastReadContentId() returns null when nothing was read', () async {
    when(userData.getLastReadContentId).thenAnswer((_) async => null);

    expect(await usecase.getLastReadContentId(), isNull);
  });
}
