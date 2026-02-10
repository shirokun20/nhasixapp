import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/domain/entities/crotpedia/crotpedia_entities.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_cubit.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_state.dart';
import 'package:nhasixapp/presentation/pages/crotpedia/doujin_list_screen.dart';
import 'package:nhasixapp/presentation/widgets/error_widget.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';

class MockCrotpediaFeatureCubit extends MockCubit<CrotpediaFeatureState>
    implements CrotpediaFeatureCubit {}

void main() {
  late MockCrotpediaFeatureCubit mockCubit;

  setUp(() {
    mockCubit = MockCrotpediaFeatureCubit();
    if (GetIt.instance.isRegistered<CrotpediaFeatureCubit>()) {
      GetIt.instance.unregister<CrotpediaFeatureCubit>();
    }
    GetIt.instance.registerFactory<CrotpediaFeatureCubit>(() => mockCubit);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: CrotpediaDoujinListScreen(),
    );
  }

  group('CrotpediaDoujinListScreen', () {
    testWidgets('shows loading indicator when state is loading', (tester) async {
      when(() => mockCubit.state).thenReturn(CrotpediaFeatureLoading());
      when(() => mockCubit.loadDoujinList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(AppProgressIndicator), findsOneWidget);
    });

    testWidgets('shows syncing indicator when state is syncing', (tester) async {
      const syncMessage = 'Syncing data...';
      when(() => mockCubit.state).thenReturn(const CrotpediaFeatureSyncing(syncMessage));
      when(() => mockCubit.loadDoujinList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text(syncMessage), findsOneWidget);
      expect(find.byType(AppProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error widget when state is error', (tester) async {
      const errorMessage = 'Failed to load doujins';
      when(() => mockCubit.state).thenReturn(const CrotpediaFeatureError(errorMessage));
      when(() => mockCubit.loadDoujinList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('shows list of doujins when state is loaded', (tester) async {
      final doujins = [
        DoujinListItem(title: 'Doujin A', url: '/doujin/a'),
        DoujinListItem(title: 'Doujin B', url: '/doujin/b'),
      ];
      when(() => mockCubit.state).thenReturn(DoujinListLoaded(doujins));
      when(() => mockCubit.loadDoujinList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      // Should find titles
      expect(find.text('Doujin A'), findsOneWidget);
      expect(find.text('Doujin B'), findsOneWidget);

      // Should find search field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows empty message when list is empty', (tester) async {
      when(() => mockCubit.state).thenReturn(const DoujinListLoaded([]));
      when(() => mockCubit.loadDoujinList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No doujins found'), findsOneWidget);
    });
  });
}
