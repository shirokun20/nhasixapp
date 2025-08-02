import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';

// Generate mocks
@GenerateMocks([RemoteDataSource, Logger, Connectivity])
import 'splash_bloc_test.mocks.dart';

void main() {
  group('SplashBloc', () {
    late SplashBloc splashBloc;
    late MockRemoteDataSource mockRemoteDataSource;
    late MockLogger mockLogger;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockRemoteDataSource = MockRemoteDataSource();
      mockLogger = MockLogger();
      mockConnectivity = MockConnectivity();

      splashBloc = SplashBloc(
        remoteDataSource: mockRemoteDataSource,
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
          when(mockRemoteDataSource.checkCloudflareStatus())
              .thenAnswer((_) async => false);
          when(mockRemoteDataSource.initialize()).thenAnswer((_) async {
            return true;
          });
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
        'emits [SplashSuccess] when bypass verification succeeds',
        build: () {
          when(mockRemoteDataSource.checkCloudflareStatus())
              .thenAnswer((_) async => true);
          return splashBloc;
        },
        act: (bloc) => bloc.add(SplashCFBypassEvent(status: 'success')),
        expect: () => [
          isA<SplashSuccess>(),
        ],
        wait: const Duration(seconds: 1),
      );

      blocTest<SplashBloc, SplashState>(
        'emits [SplashError] when bypass verification fails',
        build: () {
          when(mockRemoteDataSource.checkCloudflareStatus())
              .thenAnswer((_) async => false);
          return splashBloc;
        },
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
          when(mockRemoteDataSource.bypassCloudflare())
              .thenAnswer((_) async => true);
          when(mockRemoteDataSource.initialize()).thenAnswer((_) async {
            return true;
          });
          return splashBloc;
        },
        act: (bloc) => bloc.add(SplashRetryBypassEvent()),
        expect: () => [
          isA<SplashBypassInProgress>(), // Retrying bypass...
          isA<SplashBypassInProgress>(), // Initializing bypass system...
          isA<SplashBypassInProgress>(), // Connecting to nhentai.net...
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
