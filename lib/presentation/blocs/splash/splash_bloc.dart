import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required RemoteDataSource remoteDataSource,
    required Logger logger,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _logger = logger,
        _connectivity = connectivity,
        super(SplashInitial()) {
    on<SplashStartedEvent>(_onSplashStarted);
    on<SplashInitializeBypassEvent>(_onInitializeBypass);
    on<SplashCFBypassEvent>(_onByPassCloudflare);
    on<SplashRetryBypassEvent>(_onRetryBypass);
  }

  final RemoteDataSource _remoteDataSource;
  final Logger _logger;
  final Connectivity _connectivity;

  static const Duration _initialDelay = Duration(seconds: 1);

  Future<void> _onSplashStarted(
    SplashStartedEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashInitializing());
    try {
      _logger.i('SplashBloc: Starting initialization...');

      // Add initial delay for splash screen visibility
      await Future.delayed(_initialDelay);

      // Check network connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        emit(SplashError(
          message:
              'No internet connection. Please check your network and try again.',
          canRetry: true,
        ));
        return;
      }

      // Check if bypass is already working
      final isAlreadyBypassed = await _remoteDataSource.checkCloudflareStatus();
      if (isAlreadyBypassed) {
        _logger.i('SplashBloc: Cloudflare already bypassed');
        emit(SplashSuccess(message: 'Already connected to nhentai.net'));
        return;
      }

      // Initialize bypass process
      add(SplashInitializeBypassEvent());
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error during initialization',
          error: e, stackTrace: stackTrace);
      emit(SplashError(
        message: 'Initialization failed: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  Future<void> _onInitializeBypass(
    SplashInitializeBypassEvent event,
    Emitter<SplashState> emit,
  ) async {
    try {
      _logger.i('SplashBloc: Initializing Cloudflare bypass...');
      emit(SplashBypassInProgress(message: 'Initializing bypass system...'));

      // Initialize the remote data source (includes anti-detection)
      await Future.delayed(Duration(seconds: 1));
      emit(SplashBypassInProgress(message: 'Connecting to nhentai.net...'));
      final success = await _remoteDataSource.initialize();

      if (success) {
        emit(SplashSuccess(message: 'Successfully connected to nhentai.net'));
      } else {
        emit(SplashError(
          message: 'Failed to connect to nhentai.net. Please try again.',
          canRetry: true,
        ));
      }

      // Start the bypass process
      // emit(SplashCloudflareInitial());
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error initializing bypass',
          error: e, stackTrace: stackTrace);
      emit(SplashError(
        message: 'Failed to initialize bypass system: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  Future<void> _onByPassCloudflare(
    SplashCFBypassEvent event,
    Emitter<SplashState> emit,
  ) async {
    try {
      _logger.i('SplashBloc: Processing bypass result: ${event.status}');

      if (event.status.contains("success")) {
        // Verify the bypass actually worked
        final isVerified = await _remoteDataSource.checkCloudflareStatus();

        if (isVerified) {
          _logger.i('SplashBloc: Cloudflare bypass successful and verified');
          emit(SplashSuccess(message: 'Successfully connected to nhentai.net'));
        } else {
          _logger
              .w('SplashBloc: Bypass reported success but verification failed');
          emit(SplashError(
            message: 'Bypass verification failed. Please try again.',
            canRetry: true,
          ));
        }
      } else {
        _logger.w('SplashBloc: Cloudflare bypass failed');
        emit(SplashError(
          message:
              'Failed to bypass Cloudflare protection. This may be due to:\n'
              '• Strong Cloudflare protection\n'
              '• Network restrictions\n'
              '• Server maintenance\n\n'
              'Try using a VPN or different DNS server.',
          canRetry: true,
        ));
      }
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error processing bypass result',
          error: e, stackTrace: stackTrace);
      emit(SplashError(
        message: 'Error processing bypass result: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  Future<void> _onRetryBypass(
    SplashRetryBypassEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashBypassInProgress(message: 'Retrying bypass...'));
    try {
      _logger.i('SplashBloc: Retrying Cloudflare bypass...');

      // Attempt bypass again

      // Check connectivity again
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        emit(SplashError(
          message:
              'No internet connection. Please check your network and try again.',
          canRetry: true,
        ));
        return;
      }

      final result = await _remoteDataSource.bypassCloudflare();

      if (result) {
        emit(SplashSuccess(message: 'Successfully connected to nhentai.net'));
      } else {
        emit(SplashError(
          message: 'Failed to bypass Cloudflare protection. Please try again.',
          canRetry: true,
        ));
      }
      // Restart the bypass process
      // add(SplashInitializeBypassEvent());
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error during retry',
          error: e, stackTrace: stackTrace);
      emit(SplashError(
        message: 'Retry failed: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  @override
  Future<void> close() {
    // HTTP client is managed as singleton and should never be disposed
    // to prevent connection errors across the application lifecycle
    return super.close();
  }
}
