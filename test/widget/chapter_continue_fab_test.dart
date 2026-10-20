import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/pages/detail/widgets/chapter_continue_fab.dart';
import 'package:nhasixapp/presentation/widgets/kuro_mascot.dart';

Chapter _chapter(String id) =>
    Chapter(id: id, title: 'Chapter $id', url: '/chapter/$id');

Widget _harness(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('resume mode shows the reader mascot and page label',
      (tester) async {
    await tester.pumpWidget(_harness(ChapterContinueFab(
      target: ChapterContinueTarget(
        chapter: _chapter('c1'),
        page: 12,
        finished: false,
      ),
      onTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Continue from page 12'), findsOneWidget);
    expect(
      tester.widget<KuroMascot>(find.byType(KuroMascot)).mood,
      KuroMood.reader,
    );
  });

  testWidgets('finished mode shows the happy mascot and restart label',
      (tester) async {
    await tester.pumpWidget(_harness(ChapterContinueFab(
      target: ChapterContinueTarget(
        chapter: _chapter('c1'),
        page: 1,
        finished: true,
      ),
      onTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Go to First Page'), findsOneWidget);
    expect(
      tester.widget<KuroMascot>(find.byType(KuroMascot)).mood,
      KuroMood.happy,
    );
  });

  testWidgets('tap and drag still fire the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_harness(ChapterContinueFab(
      target: ChapterContinueTarget(
        chapter: _chapter('c1'),
        page: 3,
        finished: false,
      ),
      onTap: () => taps++,
    )));
    await tester.pump(const Duration(milliseconds: 16));

    final pill = find.text('Continue from page 3');
    await tester.tap(pill);
    await tester.pump(const Duration(milliseconds: 16));
    expect(taps, 1);

    // Drag far past the edges — must clamp, not throw, and stay tappable.
    await tester.drag(pill, const Offset(-4000, -4000));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(pill, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(taps, 2);
  });
}
