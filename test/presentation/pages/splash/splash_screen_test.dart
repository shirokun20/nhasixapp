import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/presentation/pages/splash/splash_screen.dart';
import 'package:nhasixapp/services/ad_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:bloc_test/bloc_test.dart';

class MockSplashBloc extends MockBloc<SplashEvent, SplashState>
    implements SplashBloc {}

class MockAdService extends Mock implements AdService {}

void main() {
  late MockSplashBloc mockSplashBloc;
  late MockAdService mockAdService;

  setUpAll(() {
    getIt.reset();
  });

  setUp(() {
    mockSplashBloc = MockSplashBloc();
    mockAdService = MockAdService();

    if (getIt.isRegistered<AdService>()) {
      getIt.unregister<AdService>();
    }
    getIt.registerLazySingleton<AdService>(() => mockAdService);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<SplashBloc>.value(
            value: mockSplashBloc,
            child: const SplashMainWidget(),
          ),
        ),
        GoRoute(
          name: AppRoute.mainName,
          path: '/main',
          builder: (context, state) => const SizedBox(), // Mock target
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  group('SplashScreen - AdGuard Detection', () {
    testWidgets(
        'shows AdGuard warning dialog when isAdGuardDnsActive is true on SplashSuccess',
        (tester) async {
      when(() => mockAdService.isAdGuardDnsActive())
          .thenAnswer((_) async => true);

      final streamController = StreamController<SplashState>.broadcast();

      whenListen(
        mockSplashBloc,
        streamController.stream,
        initialState: SplashInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Trigger success state
      streamController.add(SplashSuccess());

      // Wait for the state to be processed and animation to start
      await tester.pump(const Duration(
          seconds:
              2)); // allow _successAnimationController.forward() to complete
      await tester.pumpAndSettle(); // process showDialog and its animation

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Peringatan'), findsOneWidget);

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle(); // process dialog dismiss animation

      expect(find.byType(AlertDialog), findsNothing);

      // Wait for the navigation timer (200ms) to complete
      await tester.pump(const Duration(milliseconds: 500));

      await streamController.close();
    });

    testWidgets(
        'does not show AdGuard warning dialog when isAdGuardDnsActive is false on SplashSuccess',
        (tester) async {
      when(() => mockAdService.isAdGuardDnsActive())
          .thenAnswer((_) async => false);

      final streamController = StreamController<SplashState>.broadcast();

      whenListen(
        mockSplashBloc,
        streamController.stream,
        initialState: SplashInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Trigger success state
      streamController.add(SplashSuccess());

      await tester.pump(const Duration(seconds: 2)); // progress animation
      await tester.pumpAndSettle(); // process routing delay

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Peringatan'), findsNothing);

      // Wait for the navigation timer (200ms) to complete
      await tester.pump(const Duration(milliseconds: 500));

      await streamController.close();
    });
  });
}
