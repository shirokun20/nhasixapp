import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/core/utils/app_state_manager.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/core/utils/directory_utils.dart';
import 'package:nhasixapp/core/utils/tag_data_manager.dart';
import 'package:nhasixapp/core/constants/app_constants.dart';

import 'package:kuron_core/kuron_core.dart'; // For ContentSourceRegistry

part 'splash_event.dart';
part 'splash_state.dart';

// Extension to add message to SplashInitializing if it doesn't exist
// Assuming SplashState has a message property or SplashInitializing does not taking it.
// Let's modify SplashState separately if needed, but for now I will assume existing structure or update state.
// Checking SplashState file content is safer.

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required RemoteConfigService remoteConfigService,
    required RemoteDataSource remoteDataSource,
    required UserDataRepository userDataRepository,
    required Logger logger,
    required Connectivity connectivity,
    required TagDataManager tagDataManager,
    required ContentSourceRegistry contentSourceRegistry,
  })  : _remoteConfigService = remoteConfigService,
        _remoteDataSource = remoteDataSource,
        _userDataRepository = userDataRepository,
        _logger = logger,
        _connectivity = connectivity,
        _tagDataManager = tagDataManager,
        _contentSourceRegistry = contentSourceRegistry,
        super(SplashInitial()) {
    on<SplashStartedEvent>(_onSplashStarted);
    on<SplashInitializeBypassEvent>(_onInitializeBypass);
    on<SplashCFBypassEvent>(_onByPassCloudflare);
    on<SplashRetryBypassEvent>(_onRetryBypass);
    on<SplashOfflineModeEvent>(_onOfflineMode);
    on<SplashForceOfflineModeEvent>(_onForceOfflineMode);
    on<SplashCheckOfflineContentEvent>(_onCheckOfflineContent);
  }

  final RemoteConfigService _remoteConfigService;
  final RemoteDataSource _remoteDataSource;
  final UserDataRepository _userDataRepository;
  final Logger _logger;
  final Connectivity _connectivity;
  final TagDataManager _tagDataManager;
  final ContentSourceRegistry _contentSourceRegistry;

  // static const Duration _initialDelay = Duration(seconds: 1); // Removed for optimization

  Future<void> _onSplashStarted(
    SplashStartedEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashInitializing());
    try {
      _logger.i('SplashBloc: Starting initialization...');

      // Smart Config Sync
      // 1. Check if we have valid cache (Condition 1 vs Condition 2)
      // We check nhentai as valid proxy for "has config"
      final hasCache = await _remoteConfigService.hasValidCache('nhentai');

      if (!hasCache) {
        // Condition 1: No Cache (Fresh Install)
        // Check internet first
        final connectivityResults = await _connectivity.checkConnectivity();
        final hasInternet = connectivityResults.isNotEmpty &&
            connectivityResults.first != ConnectivityResult.none;

        if (!hasInternet) {
          // No cache and no internet - go to offline mode
          _logger
              .i('SplashBloc: No cache and no internet, enabling offline mode');
          AppStateManager().enableOfflineMode();
          AppStateManager().updateOfflineContentInfo(
            hasContent: false,
            contentCount: 0,
          );
          emit(SplashSuccess(message: 'Ready (Offline Mode - First Run)'));
          return;
        }

        emit(SplashInitializing(
            message: 'Downloading initial configuration...', progress: 0.05));
        // Will throw if download fails
        await _remoteConfigService.smartInitialize(
          isFirstRun: true,
          onProgress: (progress, message) {
            emit(SplashInitializing(message: message, progress: progress));
          },
        );
      } else {
        // Condition 2: Has Cache (Normal Run) -> SMART UPDATE
        emit(SplashInitializing(
            message: 'Checking for updates...', progress: 0.1));

        // This won't throw on error, keeps old config
        await _remoteConfigService.smartInitialize(
          isFirstRun: false,
          onProgress: (progress, message) {
            emit(SplashInitializing(message: message, progress: progress));
          },
        );
      }

      // Get last sync time for UI
      final lastSync = await _remoteConfigService.getLastSyncTime();
      _logger.i(
          'SplashBloc: Config synced (Last: ${lastSync?.toIso8601String()})');

      // 4. Initialize Tag Data for all sources
      emit(SplashInitializing(
          message: 'Initializing tags database...', progress: 1.0));

      // Initialize sources
      final sources = _contentSourceRegistry.sourceIds;
      final tagsManifest = _remoteConfigService.tagsManifest;

      for (final source in sources) {
        // Skip sources that don't have tag configuration
        if (tagsManifest?.sources.containsKey(source) != true) {
          _logger.d('SplashBloc: Skipping tag init for $source (no config)');
          continue;
        }

        await _tagDataManager.initialize(source: source);

        // Check for updates (Blocking if no tags, Background if has tags)
        if (!_tagDataManager.hasTags(source)) {
          emit(SplashInitializing(
              message: 'Downloading tags for $source...', progress: 1.0));
          await _tagDataManager.checkForUpdates(source: source);
        } else {
          _tagDataManager.checkForUpdates(source: source).ignore();
        }
      }

      // Check network connectivity first
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      if (connectivityResult == ConnectivityResult.none) {
        _logger.i(
            'SplashBloc: No internet connection, checking offline content...');
        // Instead of immediate success, check offline content
        await _handleOfflineMode(emit);
        return;
      }

      // Check if bypass is already working
      final isAlreadyBypassed = await _remoteDataSource.checkCloudflareStatus();
      if (isAlreadyBypassed) {
        _logger.i('SplashBloc: Cloudflare already bypassed');
        emit(SplashSuccess(
            message:
                'Ready (Last Sync: ${lastSync != null ? "${lastSync.hour}:${lastSync.minute}" : "Unknown"})'));
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
      // await Future.delayed(Duration(seconds: 1)); // Removed for optimization
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

      if (event.status.contains('success')) {
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
        _logger.w('SplashBloc: Cloudflare bypass failed, forcing offline mode');

        // Force continue with offline mode
        AppStateManager().enableOfflineMode();
        emit(SplashSuccess(message: 'Offline Mode (Bypass Failed)'));
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
    try {
      _logger.i('SplashBloc: Retrying - checking connectivity first...');

      // Check connectivity first
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;

      if (connectivityResult == ConnectivityResult.none) {
        _logger.i(
            'SplashBloc: No internet connection during retry, going to offline mode...');

        // Check if there are downloaded contents for offline use
        final downloadedContents = await _userDataRepository.getAllDownloads(
            limit:
                _remoteConfigService.appConfig?.limits?.maxBatchSize ?? 1000);
        final completedDownloads =
            downloadedContents.where((d) => d.isCompleted).toList();

        if (completedDownloads.isNotEmpty) {
          _logger.i(
              'SplashBloc: Found ${completedDownloads.length} offline contents');
          AppStateManager().enableOfflineMode();
          emit(SplashSuccess(
            message:
                'Ready (Offline Mode - ${completedDownloads.length} contents)',
          ));
        } else {
          // No offline content but still force offline mode
          _logger.i(
              'SplashBloc: No offline content, forcing limited offline mode');
          AppStateManager().enableOfflineMode();
          AppStateManager().updateOfflineContentInfo(
            hasContent: false,
            contentCount: 0,
          );
          emit(SplashSuccess(message: 'Ready (Offline Mode - Limited)'));
        }
        return;
      }

      // There is internet - try to connect but with timeout
      _logger.i('SplashBloc: Has internet, attempting to connect...');

      // Check if we have valid cache
      final hasCache = await _remoteConfigService.hasValidCache('nhentai');

      if (!hasCache) {
        // No cache - need to download initial config
        _logger.i(
            'SplashBloc: No cache found, downloading initial configuration...');
        emit(SplashInitializing(
            message: 'Downloading initial configuration...', progress: 0.05));

        try {
          await _remoteConfigService.smartInitialize(
            isFirstRun: true,
            onProgress: (progress, message) {
              emit(SplashInitializing(message: message, progress: progress));
            },
          );
          // Config downloaded successfully, now try to bypass
          emit(SplashBypassInProgress(message: 'Connecting to nhentai.net...'));
          final result = await _remoteDataSource.bypassCloudflare().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              _logger
                  .w('SplashBloc: Connection timeout, going to offline mode');
              return false;
            },
          );

          if (result) {
            emit(SplashSuccess(
                message: 'Successfully connected to nhentai.net'));
          } else {
            AppStateManager().enableOfflineMode();
            emit(SplashSuccess(message: 'Ready (Offline Mode)'));
          }
        } catch (e) {
          _logger.w('SplashBloc: Failed to download config: $e');
          AppStateManager().enableOfflineMode();
          AppStateManager().updateOfflineContentInfo(
            hasContent: false,
            contentCount: 0,
          );
          emit(SplashSuccess(message: 'Ready (Offline Mode)'));
        }
        return;
      }

      // Has cache - try to bypass cloudflare
      emit(SplashBypassInProgress(message: 'Connecting...'));

      final result = await _remoteDataSource.bypassCloudflare().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _logger.w('SplashBloc: Connection timeout, going to offline mode');
          return false;
        },
      );

      if (result) {
        emit(SplashSuccess(message: 'Successfully connected to nhentai.net'));
      } else {
        // Connection failed - go to offline mode instead of showing error
        _logger.w('SplashBloc: Connection failed, forcing offline mode');
        AppStateManager().enableOfflineMode();
        emit(SplashSuccess(message: 'Ready (Offline Mode)'));
      }
    } catch (e, stackTrace) {
      _logger.e('SplashBloc: Error during retry - going to offline mode',
          error: e, stackTrace: stackTrace);
      // Instead of showing error, go to offline mode
      AppStateManager().enableOfflineMode();
      emit(SplashSuccess(message: 'Ready (Offline Mode)'));
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
      final downloadedContents = await _userDataRepository.getAllDownloads(
          limit: AppLimits.maxBatchSize);
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
