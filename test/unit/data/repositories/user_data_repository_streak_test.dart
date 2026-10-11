import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/repositories/user_data_repository_impl.dart';

class MockLocalDataSource extends Mock implements LocalDataSource {}

void main() {
  late UserDataRepositoryImpl repository;
  late MockLocalDataSource localDataSource;
  late Map<String, String> prefs;

  // Fixed Monday-based dates so week math is deterministic.
  final day1 = DateTime(2026, 3, 9); // Monday
  final day2 = DateTime(2026, 3, 10);
  final day3 = DateTime(2026, 3, 11);

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    prefs = <String, String>{};
    localDataSource = MockLocalDataSource();

    when(() => localDataSource.getPreference(any())).thenAnswer(
      (invocation) async =>
          prefs[invocation.positionalArguments.first as String],
    );
    when(() => localDataSource.savePreference(any(), any())).thenAnswer(
      (invocation) async {
        prefs[invocation.positionalArguments[0] as String] =
            invocation.positionalArguments[1] as String;
      },
    );
    when(() => localDataSource.getHistoryCount()).thenAnswer((_) async => 3);
    when(() => localDataSource.getCompletedHistoryCount())
        .thenAnswer((_) async => 1);
    when(() => localDataSource.getLatestHistoryContentId())
        .thenAnswer((_) async => null);

    repository = UserDataRepositoryImpl(localDataSource: localDataSource);
  });

  group('recordReadingDay', () {
    test('first read starts streak at 1', () async {
      final stats = await repository.recordReadingDay(
        date: day1,
        contentId: 'c1',
      );

      expect(stats.readingStreak, 1);
      expect(stats.lastReadDate, day1);
      expect(prefs['reading_streak_count'], '1');
      expect(prefs['reading_last_date'], '2026-03-09');
      expect(prefs['reading_last_content_id'], 'c1');
      expect(prefs['reading_read_days'], contains('2026-03-09'));
    });

    test('consecutive day increments streak to 2', () async {
      await repository.recordReadingDay(date: day1);
      final stats = await repository.recordReadingDay(date: day2);

      expect(stats.readingStreak, 2);
      expect(prefs['reading_streak_count'], '2');
    });

    test('skipped day resets streak to 1', () async {
      await repository.recordReadingDay(date: day1);
      final stats = await repository.recordReadingDay(date: day3);

      expect(stats.readingStreak, 1);
      expect(prefs['reading_streak_count'], '1');
    });

    test('same-day record does not duplicate the day', () async {
      await repository.recordReadingDay(date: day1);
      final stats = await repository.recordReadingDay(date: day1);

      expect(stats.readingStreak, 1);
      expect(stats.readDays, [day1]);
      expect(prefs['reading_read_days'], '["2026-03-09"]');
    });

    test('prunes future days when the clock moves back', () async {
      await repository.recordReadingDay(date: day2);
      final stats = await repository.recordReadingDay(date: day1);

      expect(stats.readingStreak, 1);
      expect(stats.lastReadDate, day1);
      expect(stats.readDays, [day1]);
      expect(prefs['reading_last_date'], '2026-03-09');
    });
  });

  group('getReadingStatistics', () {
    test('returns 0 when the last read is more than a day ago', () async {
      prefs['reading_streak_count'] = '5';
      prefs['reading_last_date'] = '2026-03-09';

      final stats = await repository.getReadingStatistics(now: day3);

      expect(stats.readingStreak, 0);
    });

    test('keeps stored streak when last read was yesterday', () async {
      prefs['reading_streak_count'] = '5';
      prefs['reading_last_date'] = '2026-03-09';

      final stats = await repository.getReadingStatistics(now: day2);

      expect(stats.readingStreak, 5);
    });

    test('filters read days to the current Monday-Sunday week', () async {
      prefs['reading_streak_count'] = '2';
      prefs['reading_last_date'] = '2026-03-11';
      prefs['reading_read_days'] =
          '["2026-03-02","2026-03-09","2026-03-15","2026-03-16"]';

      final stats = await repository.getReadingStatistics(
        now: DateTime(2026, 3, 11), // Wednesday
      );

      expect(stats.readDays, [DateTime(2026, 3, 9), DateTime(2026, 3, 15)]);
    });

    test('malformed stored values fall back to defaults', () async {
      prefs['reading_streak_count'] = 'oops';
      prefs['reading_read_days'] = 'not-json';

      final stats = await repository.getReadingStatistics(now: day1);

      expect(stats.readingStreak, 0);
      expect(stats.lastReadDate, isNull);
      expect(stats.readDays, isEmpty);
    });
  });

  group('getLastReadContentId', () {
    test('falls back to latest history content id', () async {
      when(() => localDataSource.getLatestHistoryContentId())
          .thenAnswer((_) async => 'from-history');

      expect(await repository.getLastReadContentId(), 'from-history');
    });

    test('prefers the recorded streak content id', () async {
      prefs['reading_last_content_id'] = 'from-streak';
      when(() => localDataSource.getLatestHistoryContentId())
          .thenAnswer((_) async => 'from-history');

      expect(await repository.getLastReadContentId(), 'from-streak');
    });

    test('returns null when nothing is stored', () async {
      expect(await repository.getLastReadContentId(), isNull);
    });
  });
}
