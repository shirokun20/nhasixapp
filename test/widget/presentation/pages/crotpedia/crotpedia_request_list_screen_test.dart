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
import 'package:nhasixapp/presentation/pages/crotpedia/request_list_screen.dart';
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
      home: CrotpediaRequestListScreen(),
    );
  }

  group('CrotpediaRequestListScreen', () {
    testWidgets('shows loading indicator when state is loading', (tester) async {
      when(() => mockCubit.state).thenReturn(CrotpediaFeatureLoading());
      when(() => mockCubit.loadRequestList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(AppProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error widget when state is error', (tester) async {
      const errorMessage = 'Failed to load requests';
      when(() => mockCubit.state).thenReturn(const CrotpediaFeatureError(errorMessage));
      when(() => mockCubit.loadRequestList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('shows list of requests when state is loaded', (tester) async {
      final requests = [
        RequestItem(
          id: 1,
          title: 'Request A',
          url: '/request/a',
          coverUrl: 'https://example.com/cover1.jpg',
          genres: {'action': 'Action'},
        ),
        RequestItem(
          id: 2,
          title: 'Request B',
          url: '/request/b',
          coverUrl: 'https://example.com/cover2.jpg',
          genres: {'romance': 'Romance'},
        ),
      ];
      when(() => mockCubit.state).thenReturn(RequestListLoaded(requests));
      when(() => mockCubit.loadRequestList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      // Should find titles
      expect(find.text('Request A'), findsOneWidget);
      expect(find.text('Request B'), findsOneWidget);

      // Should find genres
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Romance'), findsOneWidget);
    });

    testWidgets('shows empty message when list is empty', (tester) async {
      when(() => mockCubit.state).thenReturn(const RequestListLoaded([]));
      when(() => mockCubit.loadRequestList()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No requests found'), findsOneWidget);
    });
  });
}
