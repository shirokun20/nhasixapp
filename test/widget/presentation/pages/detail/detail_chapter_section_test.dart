import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/pages/detail/widgets/detail_info_sections.dart';

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  setUp(() async {
    await getIt.reset();
    final mockConfig = MockRemoteConfigService();
    when(() => mockConfig.getRawConfig(any())).thenReturn({});
    getIt.registerSingleton<RemoteConfigService>(mockConfig);
  });

  Chapter chapter(String id, String title, String language) => Chapter(
        id: id,
        title: title,
        url: '/$id',
        language: language,
      );

  Content content(List<Chapter> chapters) => Content(
        id: 'series',
        sourceId: 'mangadex',
        title: 'Series',
        coverUrl: '',
        tags: const [],
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'en',
        pageCount: 0,
        imageUrls: const [],
        uploadDate: DateTime(2026),
        chapters: chapters,
      );

  String label(String key) => switch (key) {
        'en' => 'English',
        'id' => 'Indonesian',
        _ => 'Language',
      };

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  Widget section(Content content) => wrap(
        DetailChapterSection(
          content: content,
          chapterHistory: const {},
          onChapterTap: (_) {},
          onViewAll: (_) {},
          formatDate: (_) => 'today',
          formatLanguageLabel: label,
          canDownload: false,
        ),
      );

  testWidgets('shows language chips and switches preview lane', (tester) async {
    await tester.pumpWidget(
      section(
        content([
          chapter('en-1', 'English 1', 'english'),
          chapter('en-2', 'English 2', 'en-US'),
          chapter('id-1', 'Indonesian 1', 'id'),
        ]),
      ),
    );

    expect(find.text('English  2'), findsOneWidget);
    expect(find.text('Indonesian  1'), findsOneWidget);
    expect(find.text('English 1'), findsOneWidget);
    expect(find.text('Indonesian 1'), findsNothing);

    await tester.tap(find.text('Indonesian  1'));
    await tester.pumpAndSettle();

    expect(find.text('English 1'), findsNothing);
    expect(find.text('Indonesian 1'), findsOneWidget);
  });

  testWidgets('keeps single-language section non-tabbed', (tester) async {
    await tester.pumpWidget(
      section(
        content([
          chapter('en-1', 'English 1', 'en'),
          chapter('en-2', 'English 2', 'english'),
        ]),
      ),
    );

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('English 1'), findsOneWidget);
    expect(find.text('English 2'), findsOneWidget);
  });
}
