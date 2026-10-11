import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/domain/entities/reading_statistics.dart';
import 'package:nhasixapp/domain/usecases/reader_identity/get_reading_streak_usecase.dart';
import 'package:nhasixapp/presentation/cubits/streak/streak_cubit.dart';
import 'package:nhasixapp/presentation/widgets/kuro_mascot.dart';
import 'package:nhasixapp/presentation/widgets/streak_card.dart';

class _MockGetReadingStreakUseCase extends Mock
    implements GetReadingStreakUseCase {}

// Sunday 2026-10-11, so the Mon–Sun checklist is fully inside one week.
final _now = DateTime(2026, 10, 11, 20, 30);

StreakCubit _cubitFor(
  ReadingStatistics stats,
  String? lastContentId,
) {
  final useCase = _MockGetReadingStreakUseCase();
  when(() => useCase.forDate(any())).thenAnswer((_) async => stats);
  when(() => useCase.getLastReadContentId())
      .thenAnswer((_) async => lastContentId);
  final cubit = StreakCubit(
    getReadingStreakUseCase: useCase,
    logger: Logger(),
    clock: () => _now,
  );
  return cubit;
}

Future<void> _pump(
  WidgetTester tester,
  StreakCubit cubit, {
  Future<void> Function(BuildContext, String)? onContinueReading,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StreakCard(cubit: cubit, onContinueReading: onContinueReading),
      ),
    ),
  );
  await cubit.loadStreak();
  await tester.pump();
}

KuroMood _moodOf(WidgetTester tester) =>
    tester.widget<KuroMascot>(find.byType(KuroMascot)).mood;

void main() {
  group('StreakCard', () {
    testWidgets('read today: shows streak, marks checklist, ceria mascot',
        (tester) async {
      final cubit = _cubitFor(
        ReadingStatistics.streak(
          readingStreak: 4,
          lastReadDate: DateTime(2026, 10, 11),
          readDays: [
            DateTime(2026, 10, 9),
            DateTime(2026, 10, 10),
            DateTime(2026, 10, 11),
          ],
          totalContentRead: 12,
        ),
        'content-1',
      );
      addTearDown(cubit.close);

      await _pump(tester, cubit);

      expect(find.text('4'), findsOneWidget);
      expect(find.text('Hari Streak'), findsOneWidget);
      // Friday, Saturday, Sunday read out of seven day dots.
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
      expect(isCeriaMood(_moodOf(tester)), isTrue);
    });

    testWidgets('absent 3 days: cry mascot', (tester) async {
      final cubit = _cubitFor(
        ReadingStatistics.streak(
          readingStreak: 0,
          lastReadDate: DateTime(2026, 10, 8),
        ),
        'content-1',
      );
      addTearDown(cubit.close);

      await _pump(tester, cubit);

      expect(_moodOf(tester), KuroMood.cry);
    });

    testWidgets('absent 10 days: tsundere mascot, streak 0', (tester) async {
      final cubit = _cubitFor(
        ReadingStatistics.streak(
          readingStreak: 0,
          lastReadDate: DateTime(2026, 10, 1),
        ),
        'content-1',
      );
      addTearDown(cubit.close);

      await _pump(tester, cubit);

      expect(_moodOf(tester), KuroMood.tsundere);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('tapping CTA resumes last content id', (tester) async {
      String? resumed;
      final cubit = _cubitFor(
        ReadingStatistics.streak(
          readingStreak: 1,
          lastReadDate: DateTime(2026, 10, 11),
        ),
        'content-42',
      );
      addTearDown(cubit.close);

      await _pump(
        tester,
        cubit,
        onContinueReading: (context, contentId) async => resumed = contentId,
      );

      await tester.tap(find.text('Lanjutkan Baca'));
      await tester.pump();

      expect(resumed, 'content-42');
    });

    testWidgets('CTA disabled without a last content id', (tester) async {
      final cubit = _cubitFor(
        ReadingStatistics.streak(
          readingStreak: 1,
          lastReadDate: DateTime(2026, 10, 11),
        ),
        null,
      );
      addTearDown(cubit.close);

      await _pump(tester, cubit);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Lanjutkan Baca'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
