import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/core/utils/app_state_manager.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/core/utils/directory_utils.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required RemoteDataSource remoteDataSource,
    required UserDataRepository userDataRepository,
    required Logger logger,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _userDataRepository = userDataRepository,
        _logger = logger,
        _connectivity = connectivity,
        super(SplashInitial()) {
    on<SplashStartedEvent>(_onSplashStarted);
    on<SplashInitializeBypassEvent>(_onInitializeBypass);
    on<SplashCFBypassEvent>(_onByPassCloudflare);
    on<SplashRetryBypassEvent>(_onRetryBypass);
    on<SplashOfflineModeEvent>(_onOfflineMode);
    on<SplashForceOfflineModeEvent>(_onForceOfflineMode);
    on<SplashCheckOfflineContentEvent>(_onCheckOfflineContent);
  }

  final RemoteDataSource _remoteDataSource;
  final UserDataRepository _userDataRepository;
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
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      if (connectivityResult == ConnectivityResult.none) {
        _logger.i(
            'SplashBloc: No internet connection, entering enhanced offline mode...');
        await _handleOfflineMode(emit);
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

        // Check if we can offer offline mode
        final downloadedContents = await _userDataRepository.getAllDownloads();
        final completedDownloads =
            downloadedContents.where((d) => d.isCompleted).toList();
        final canUseOffline = completedDownloads.isNotEmpty;

        emit(SplashError(
          message:
              'Failed to bypass Cloudflare protection. This may be due to:\n'
              '• Strong Cloudflare protection\n'
              '• Network restrictions\n'
              '• Server maintenance\n\n'
              'Try using a VPN or different DNS server.'
              '${canUseOffline ? '\n\nOr continue with offline content (${completedDownloads.length} downloads available).' : ''}',
          canRetry: true,
          canUseOffline: canUseOffline,
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
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      if (connectivityResult == ConnectivityResult.none) {
        _logger.i(
            'SplashBloc: No internet connection during retry, checking offline content...');

        // Check if there are downloaded contents for offline use
        final downloadedContents = await _userDataRepository.getAllDownloads();
        final completedDownloads =
            downloadedContents.where((d) => d.isCompleted).toList();

        if (completedDownloads.isNotEmpty) {
          _logger.i(
              'SplashBloc: Found ${completedDownloads.length} offline contents');
          emit(SplashOfflineSuccess(
            downloadCount: completedDownloads.length,
            message:
                'Offline mode: ${completedDownloads.length} downloaded contents available',
          ));
          return;
        } else {
          emit(SplashError(
            message:
                'No internet connection and no offline content available.\nPlease connect to internet or download content when online.',
            canRetry: true,
            canUseOffline: false,
          ));
          return;
        }
      }

      final result = await _remoteDataSource.bypassCloudflare();

      if (result) {
        emit(SplashSuccess(message: 'Successfully connected to nhentai.net'));
      } else {
        // Check if we can offer offline mode
        final downloadedContents = await _userDataRepository.getAllDownloads();
        final completedDownloads =
            downloadedContents.where((d) => d.isCompleted).toList();
        final canUseOffline = completedDownloads.isNotEmpty;

        emit(SplashError(
          message: 'Failed to bypass Cloudflare protection. Please try again.'
              '${canUseOffline ? '\n\nOr continue with offline content (${completedDownloads.length} downloads available).' : ''}',
          canRetry: true,
          canUseOffline: canUseOffline,
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

  Future<void> _onOfflineMode(
    SplashOfflineModeEvent event,
    Emitter<SplashState> emit,
  ) async {
    try {
      _logger.i('SplashBloc: Switching to offline mode...');
      emit(SplashInitializing());

      // Get all downloaded content
      final downloadedContents = await _userDataRepository.getAllDownloads();
      final completedDownloads =
          downloadedContents.where((d) => d.isCompleted).toList();

      if (completedDownloads.isNotEmpty) {
        _logger.i(
            'SplashBloc: Offline mode activated with ${completedDownloads.length} contents');
        emit(SplashOfflineSuccess(
          downloadCount: completedDownloads.length,
          message:
              'Offline mode: ${completedDownloads.length} downloaded contents available',
        ));
      } else {
        emit(SplashError(
          message:
              'No offline content available.\nPlease download content when internet is available.',
          canRetry: true,
          canUseOffline: false,
        ));
      }
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error in offline mode',
          error: e, stackTrace: stackTrace);
      emit(SplashError(
        message: 'Failed to load offline content: ${e.toString()}',
        canRetry: true,
        canUseOffline: false,
      ));
    }
  }

  /// Enhanced offline mode handling with smart auto-continue functionality
  /// Checks for offline content and either auto-continues or shows options
  Future<void> _handleOfflineMode(Emitter<SplashState> emit) async {
    try {
      // First, show that we're checking offline content
      emit(SplashOfflineDetected(
          message: 'No internet connection. Checking offline content...'));

      // Get offline content from multiple sources
      int totalOfflineContent = 0;

      // 1. Check database downloads first
      List<String> databaseContentIds = [];
      try {
        final offlineManager = OfflineContentManager(
          userDataRepository: _userDataRepository,
          logger: _logger,
        );
        databaseContentIds = await offlineManager.getOfflineContentIds();
        totalOfflineContent += databaseContentIds.length;
        _logger.i(
            'SplashBloc: Found ${databaseContentIds.length} offline items from database');
      } catch (e) {
        _logger.w('SplashBloc: Error checking database offline content: $e');
      }

      // 2. Check nhasix filesystem folder
      List<String> filesystemContentIds = [];
      try {
        final backupPath = await DirectoryUtils.findNhasixBackupFolder();
        if (backupPath != null) {
          final offlineManager = OfflineContentManager(
            userDataRepository: _userDataRepository,
            logger: _logger,
          );
          final filesystemContents =
              await offlineManager.scanBackupFolder(backupPath);
          filesystemContentIds = filesystemContents.map((c) => c.id).toList();

          // Filter out duplicates with database content
          filesystemContentIds = filesystemContentIds
              .where((id) => !databaseContentIds.contains(id))
              .toList();
          totalOfflineContent += filesystemContentIds.length;

          _logger.i(
              'SplashBloc: Found ${filesystemContentIds.length} additional offline items from filesystem');
        } else {
          _logger.i('SplashBloc: No nhasix backup folder found');
        }
      } catch (e) {
        _logger.w('SplashBloc: Error checking filesystem offline content: $e');
      }

      final hasOfflineContent = totalOfflineContent > 0;

      // Update AppStateManager with offline content info
      AppStateManager().updateOfflineContentInfo(
        hasContent: hasOfflineContent,
        contentCount: totalOfflineContent,
      );

      if (hasOfflineContent) {
        // ✅ Auto-continue to main app with offline mode
        _logger.i(
            'SplashBloc: Found $totalOfflineContent offline items total (DB: ${databaseContentIds.length}, FS: ${filesystemContentIds.length}), auto-continuing');
        emit(SplashOfflineReady(
          offlineContentCount: totalOfflineContent,
          message: 'Found $totalOfflineContent offline items. Continuing...',
        ));

        // Enable global offline mode
        AppStateManager().enableOfflineMode();

        // Auto-navigate to main after brief delay
        await Future.delayed(const Duration(seconds: 1));
        emit(SplashSuccess(message: 'Ready (Offline Mode)'));
      } else {
        // ❌ No offline content - show options
        _logger.i('SplashBloc: No offline content available, showing options');
        emit(SplashOfflineEmpty(
          message: 'No internet connection and no offline content available.',
        ));
      }
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error during offline mode handling',
          error: e, stackTrace: stackTrace);
      emit(SplashOfflineEmpty(
        message: 'Unable to check offline content. ${e.toString()}',
      ));
    }
  }

  /// Force continue to main app even without offline content
  /// Enables limited offline mode for basic app functionality
  Future<void> _onForceOfflineMode(
    SplashForceOfflineModeEvent event,
    Emitter<SplashState> emit,
  ) async {
    try {
      _logger.i('SplashBloc: Force enabling offline mode without content');

      // Enable global offline mode with no content
      AppStateManager().updateOfflineContentInfo(
        hasContent: false,
        contentCount: 0,
      );
      AppStateManager().enableOfflineMode();

      emit(SplashOfflineMode(
        message: 'Offline Mode (Limited Features)',
        canRetryOnline: true,
      ));

      // Auto-continue to main app
      await Future.delayed(const Duration(seconds: 1));
      emit(SplashSuccess(message: 'Ready (Offline Mode - Limited Features)'));
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error forcing offline mode',
          error: e, stackTrace: stackTrace);
      emit(SplashError(
        message: 'Failed to enable offline mode: ${e.toString()}',
        canRetry: true,
        canUseOffline: false,
      ));
    }
  }

  /// Manually check for offline content availability
  /// Useful for refresh functionality when user wants to recheck
  Future<void> _onCheckOfflineContent(
    SplashCheckOfflineContentEvent event,
    Emitter<SplashState> emit,
  ) async {
    try {
      _logger.i('SplashBloc: Manually checking offline content');
      await _handleOfflineMode(emit);
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error during manual offline content check',
          error: e, stackTrace: stackTrace);
      emit(SplashError(
        message: 'Failed to check offline content: ${e.toString()}',
        canRetry: true,
        canUseOffline: false,
      ));
    }
  }
}
