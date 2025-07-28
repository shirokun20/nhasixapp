import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';

// Generate mocks
@GenerateMocks([Dio, Logger, Connectivity])
import 'splash_bloc_test.mocks.dart';

void main() {
  group('SplashBloc', () {
    late SplashBloc splashBloc;
    late MockDio mockDio;
    late MockLogger mockLogger;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockDio = MockDio();
      mockLogger = MockLogger();
      mockConnectivity = MockConnectivity();

      splashBloc = SplashBloc(
        httpClient: mockDio,
        logger: mockLogger,
        connectivity: mockConnectivity,
      );
    });

    tearDown(() {
      splashBloc.close();
    });

    test('initial state is SplashInitial', () {
      expect(splashBloc.state, isA<SplashInitial>());
    });

    group('SplashStartedEvent', () {
      blocTest<SplashBloc, SplashState>(
        'emits correct sequence when connectivity is available',
        build: () {
          when(mockConnectivity.checkConnectivity())
              .thenAnswer((_) async => ConnectivityResult.wifi);
          return splashBloc;
        },
        act: (bloc) => bloc.add(SplashStartedEvent()),
        expect: () => [
          isA<SplashInitializing>(),
          isA<SplashBypassInProgress>(),
          isA<SplashBypassInProgress>(),
          isA<SplashCloudflareInitial>(),
        ],
        wait: const Duration(seconds: 2),
      );

      blocTest<SplashBloc, SplashState>(
        'emits [SplashInitializing, SplashError] when no connectivity',
        build: () {
          when(mockConnectivity.checkConnectivity())
              .thenAnswer((_) async => ConnectivityResult.none);
          return splashBloc;
        },
        act: (bloc) => bloc.add(SplashStartedEvent()),
        expect: () => [
          isA<SplashInitializing>(),
          isA<SplashError>(),
        ],
        wait: const Duration(seconds: 2),
      );
    });

    group('SplashCFBypassEvent', () {
      blocTest<SplashBloc, SplashState>(
        'emits [SplashError] when bypass verification fails',
        build: () => splashBloc,
        act: (bloc) => bloc.add(SplashCFBypassEvent(status: 'success')),
        expect: () => [
          isA<SplashError>(),
        ],
        wait: const Duration(seconds: 1),
      );

      blocTest<SplashBloc, SplashState>(
        'emits [SplashError] when bypass fails',
        build: () => splashBloc,
        act: (bloc) => bloc.add(SplashCFBypassEvent(status: 'error')),
        expect: () => [
          isA<SplashError>(),
        ],
      );
    });

    group('SplashRetryBypassEvent', () {
      blocTest<SplashBloc, SplashState>(
        'emits correct sequence when retrying with connectivity',
        build: () {
          when(mockConnectivity.checkConnectivity())
              .thenAnswer((_) async => ConnectivityResult.wifi);
          return splashBloc;
        },
        act: (bloc) => bloc.add(SplashRetryBypassEvent()),
        expect: () => [
          isA<SplashBypassInProgress>(),
          isA<SplashBypassInProgress>(),
          isA<SplashBypassInProgress>(),
          isA<SplashCloudflareInitial>(),
        ],
        wait: const Duration(seconds: 1),
      );

      blocTest<SplashBloc, SplashState>(
        'emits [SplashError] when retrying without connectivity',
        build: () {
          when(mockConnectivity.checkConnectivity())
              .thenAnswer((_) async => ConnectivityResult.none);
          return splashBloc;
        },
        act: (bloc) => bloc.add(SplashRetryBypassEvent()),
        expect: () => [
          isA<SplashError>(),
        ],
      );
    });
  });
}
