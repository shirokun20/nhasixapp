import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/content.dart';
import '../../../domain/usecases/content/get_content_detail_usecase.dart';
import '../../../domain/usecases/history/add_to_history_usecase.dart';
import '../../../domain/repositories/reader_settings_repository.dart';
import '../../../data/models/reader_settings_model.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../network/network_cubit.dart';

part 'reader_state.dart';

/// Simple cubit for managing reader functionality with offline support
class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required this.getContentDetailUseCase,
    required this.addToHistoryUseCase,
    required this.readerSettingsRepository,
    required this.offlineContentManager,
    required this.networkCubit,
  }) : super(const ReaderInitial());

  final GetContentDetailUseCase getContentDetailUseCase;
  final AddToHistoryUseCase addToHistoryUseCase;
  final ReaderSettingsRepository readerSettingsRepository;
  final OfflineContentManager offlineContentManager;
  final NetworkCubit networkCubit;
  final Logger _logger = Logger();

  Timer? _readingTimer;
  Timer? _autoHideTimer;

  /// Load content for reading with offline support
  Future<void> loadContent(String contentId, {int initialPage = 1}) async {
    try {
      _stopAutoHideTimer();

      emit(ReaderLoading(state));

      Content? content;
      bool isOfflineMode = false;

      // Check if content is available offline first
      final isOfflineAvailable =
          await offlineContentManager.isContentAvailableOffline(contentId);
      final isConnected = networkCubit.isConnected;

      if (isOfflineAvailable && (!isConnected || _shouldPreferOffline())) {
        _logger.i("Loading content from offline storage: $contentId");
        content = await offlineContentManager.createOfflineContent(contentId);
        isOfflineMode = true;
      }

      // If offline content not available or failed, try online
      if (content == null && isConnected) {
        _logger.i("Loading content from online source: $contentId");
        try {
          final params = GetContentDetailParams.fromString(contentId);
          content = await getContentDetailUseCase(params);
          isOfflineMode = false;
        } catch (e) {
          _logger
              .w("Failed to load online content, trying offline fallback: $e");
          if (isOfflineAvailable) {
            content =
                await offlineContentManager.createOfflineContent(contentId);
            isOfflineMode = true;
          } else {
            rethrow;
          }
        }
      }

      // If still no content and offline available, use offline
      if (content == null && isOfflineAvailable) {
        _logger.i("Using offline content as fallback: $contentId");
        content = await offlineContentManager.createOfflineContent(contentId);
        isOfflineMode = true;
      }

      if (content == null) {
        throw Exception('Content not available online or offline');
      }

      // Load saved settings with error handling
      ReaderSettings savedSettings;
      try {
        savedSettings = await readerSettingsRepository.getReaderSettings();
        _logger.i("Successfully loaded reader settings: $savedSettings");
      } catch (e, stackTrace) {
        _logger.e("Failed to load reader settings, using defaults: $e",
            error: e, stackTrace: stackTrace);
        savedSettings = const ReaderSettings(); // Use defaults
      }

      // Emit loaded state with saved settings and offline mode info
      emit(state.copyWith(
        content: content,
        currentPage: initialPage,
        readingMode: savedSettings.readingMode,
        showUI: savedSettings.showUI,
        keepScreenOn: savedSettings.keepScreenOn,
        readingTimer: Duration.zero,
        isOfflineMode: isOfflineMode,
      ));

      emit(ReaderLoaded(state));

      // Apply keep screen on setting
      if (savedSettings.keepScreenOn) {
        await WakelockPlus.enable();
      }

      // Start reading timer
      _startReadingTimer();

      // Save to history
      await _saveToHistory();
    } catch (e, stackTrace) {
      _logger.e("Reader Cubit: $e, $stackTrace");
      _stopAutoHideTimer();

      final errorState = state.copyWith(
        message: 'Failed to load content: ${e.toString()}',
      );
      emit(ReaderError(errorState));
    }
  }

  /// Check if offline mode should be preferred
  bool _shouldPreferOffline() {
    // Prefer offline if on mobile data to save bandwidth
    final connectionType = networkCubit.connectionType;
    return connectionType == NetworkConnectionType.mobile;
  }

  /// Navigate to next page
  void nextPage() {
    if (!state.isLastPage) {
      final newPage = (state.currentPage ?? 1) + 1;
      emit(state.copyWith(currentPage: newPage));
      _saveToHistory();
    }
  }

  /// Navigate to previous page
  void previousPage() {
    if (!state.isFirstPage) {
      final newPage = (state.currentPage ?? 1) - 1;
      emit(state.copyWith(currentPage: newPage));
      _saveToHistory();
    }
  }

  /// Jump to specific page
  void jumpToPage(int page) {
    if (page >= 1 && page <= state.content!.pageCount) {
      emit(state.copyWith(currentPage: page));
      _saveToHistory();
    }
  }

  /// Toggle UI visibility
  void toggleUI() {
    final newShowUI = !(state.showUI ?? true);
    emit(state.copyWith(showUI: newShowUI));

    // Save to preferences with error handling
    readerSettingsRepository.saveShowUI(newShowUI).catchError((e, stackTrace) {
      _logger.e("Failed to save show UI setting: $e",
          error: e, stackTrace: stackTrace);
      // Settings will still apply for current session
    });

    // Start auto-hide timer if UI is shown
    if (newShowUI) {
      _startAutoHideTimer();
    } else {
      _stopAutoHideTimer();
    }
  }

  /// Show UI temporarily
  void showUI() {
    emit(state.copyWith(showUI: true));
    _startAutoHideTimer();
  }

  /// Hide UI
  void hideUI() {
    emit(state.copyWith(showUI: false));
    _stopAutoHideTimer();
  }

  /// Change reading mode
  Future<void> changeReadingMode(ReadingMode mode) async {
    emit(state.copyWith(readingMode: mode));

    // Save to preferences with error handling
    try {
      await readerSettingsRepository.saveReadingMode(mode);
      _logger.i("Successfully saved reading mode: ${mode.name}");
    } catch (e, stackTrace) {
      _logger.e("Failed to save reading mode: $e",
          error: e, stackTrace: stackTrace);
      // Settings will still apply for current session
    }
  }

  /// Toggle keep screen on
  Future<void> toggleKeepScreenOn() async {
    final newKeepScreenOn = !(state.keepScreenOn ?? false);

    try {
      if (newKeepScreenOn) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }

      emit(state.copyWith(keepScreenOn: newKeepScreenOn));

      // Save to preferences with error handling
      try {
        await readerSettingsRepository.saveKeepScreenOn(newKeepScreenOn);
        _logger.i("Successfully saved keep screen on: $newKeepScreenOn");
      } catch (e, stackTrace) {
        _logger.e("Failed to save keep screen on setting: $e",
            error: e, stackTrace: stackTrace);
        // Settings will still apply for current session
      }
    } catch (e, stackTrace) {
      _logger.e("Failed to toggle wakelock: $e",
          error: e, stackTrace: stackTrace);
      // Don't update state if wakelock operation failed
    }
  }

  /// Reset all reader settings to defaults
  Future<void> resetReaderSettings() async {
    try {
      await readerSettingsRepository.resetToDefaults();
      _logger.i("Successfully reset reader settings to defaults");

      // Apply default settings to current state
      emit(state.copyWith(
        readingMode: ReadingMode.singlePage,
        keepScreenOn: false,
        showUI: true,
      ));

      // Disable wakelock
      try {
        await WakelockPlus.disable();
      } catch (e, stackTrace) {
        _logger.e("Failed to disable wakelock during reset: $e",
            error: e, stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      _logger.e("Failed to reset reader settings: $e",
          error: e, stackTrace: stackTrace);

      // Still apply default settings to current state even if persistence failed
      emit(state.copyWith(
        readingMode: ReadingMode.singlePage,
        keepScreenOn: false,
        showUI: true,
      ));

      // Try to disable wakelock anyway
      try {
        await WakelockPlus.disable();
      } catch (wakelockError) {
        _logger
            .e("Failed to disable wakelock after reset error: $wakelockError");
      }

      // Re-throw to let UI handle the error
      rethrow;
    }
  }

  /// Save current reading progress to history
  Future<void> _saveToHistory() async {
    try {
      final params = AddToHistoryParams.fromString(
        state.content!.id,
        state.currentPage ?? 1,
        state.content!.pageCount,
        timeSpent: state.readingTimer ?? Duration.zero,
      );
      await addToHistoryUseCase(params);
    } catch (e) {
      // Log error but don't emit error state for history saving
    }
  }

  /// Start reading timer
  void _startReadingTimer() {
    _logger.i("start reading timer");
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimer = state.readingTimer ?? Duration.zero;
      emit(state.copyWith(
        readingTimer: currentTimer + const Duration(seconds: 1),
      ));
    });
    _logger.i("end reading timer");
  }

  /// Stop reading timer
  void _stopReadingTimer() {
    _readingTimer?.cancel();
    _readingTimer = null;
  }

  /// Start auto-hide UI timer
  void _startAutoHideTimer() {
    _stopAutoHideTimer();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (state.showUI ?? false) {
        hideUI();
      }
    });
  }

  /// Stop auto-hide UI timer
  void _stopAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  @override
  Future<void> close() async {
    // Stop timers
    _stopReadingTimer();
    _stopAutoHideTimer();

    // Save final reading progress
    await _saveToHistory();

    // Disable wakelock
    await WakelockPlus.disable();

    return super.close();
  }
}
