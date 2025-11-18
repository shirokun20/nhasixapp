import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/content.dart';
import '../../../domain/entities/reader_position.dart';
import '../../../domain/usecases/content/get_content_detail_usecase.dart';
import '../../../domain/usecases/history/add_to_history_usecase.dart';
import '../../../domain/repositories/reader_settings_repository.dart';
import '../../../domain/repositories/reader_repository.dart';
import '../../../data/models/reader_settings_model.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../core/models/image_metadata.dart';
import '../../../services/image_metadata_service.dart';
import '../../../services/local_image_preloader.dart';
import '../network/network_cubit.dart';

part 'reader_state.dart';

/// Simple cubit for managing reader functionality with offline support
class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required this.getContentDetailUseCase,
    required this.addToHistoryUseCase,
    required this.readerSettingsRepository,
    required this.readerRepository,
    required this.offlineContentManager,
    required this.networkCubit,
    required this.imageMetadataService,
  }) : super(const ReaderInitial());

  final GetContentDetailUseCase getContentDetailUseCase;
  final AddToHistoryUseCase addToHistoryUseCase;
  final ReaderSettingsRepository readerSettingsRepository;
  final ReaderRepository readerRepository;
  final OfflineContentManager offlineContentManager;
  final NetworkCubit networkCubit;
  final ImageMetadataService imageMetadataService;
  final Logger _logger = Logger();

  Timer? _readingTimer;
  Timer? _autoHideTimer;

  /// Load content for reading with offline support - OPTIMIZED VERSION
  Future<void> loadContent(String contentId,
      {int initialPage = 1,
      bool forceStartFromBeginning = false,
      Content? preloadedContent,
      List<ImageMetadata>? imageMetadata}) async {
    try {
      _stopAutoHideTimer();
      emit(ReaderLoading(state));

      final isConnected = networkCubit.isConnected;

      // 🚀 OPTIMIZATION: Run multiple async operations in parallel
      final results = await Future.wait([
        // Check offline availability
        offlineContentManager.isContentAvailableOffline(contentId),
        // Load reader settings (simplified version)
        _loadReaderSettingsOptimized(),
        // Restore reader position if exists (override initialPage)
        if (forceStartFromBeginning)
          Future<int>.value(1)
        else
          _restoreReaderPosition(contentId),
        // If connected, start loading online content in parallel
        if (isConnected)
          () async {
            try {
              return await getContentDetailUseCase(
                  GetContentDetailParams.fromString(contentId));
            } catch (e) {
              _logger.w("Online content load failed: $e");
              return null;
            }
          }()
        else
          Future<Content?>.value(null),
      ]);

      final isOfflineAvailable = results[0] as bool;
      final savedSettings = results[1] as ReaderSettings;
      final restoredPage = results[2] as int;
      final onlineContent = results.length > 3 ? results[3] as Content? : null;

      // Use initialPage if user explicitly requested a specific page (initialPage > 1)
      // Otherwise use restored page if available, fallback to initialPage
      final startPage = initialPage > 1
          ? initialPage
          : (restoredPage > 1 ? restoredPage : initialPage);

      _logger.i(
          '📍 Loading content: $contentId, initialPage: $initialPage, restoredPage: $restoredPage, startPage: $startPage, preloaded: ${preloadedContent != null}');

      Content? content;
      bool isOfflineMode = false;

      // 🚀 OPTIMIZATION: Use preloaded content if available (highest priority)
      if (preloadedContent != null) {
        _logger.i("✅ Using preloaded content from navigation: $contentId");
        content = preloadedContent;
        // Detect if preloaded content is from offline storage by checking if we're offline
        isOfflineMode = !isConnected;
      } else if (isOfflineAvailable &&
          (!isConnected || _shouldPreferOffline())) {
        _logger.i("💾 Loading content from offline storage: $contentId");
        content = await offlineContentManager.createOfflineContent(contentId);
        isOfflineMode = true;
      } else if (onlineContent != null) {
        _logger.i("🌐 Using preloaded online content: $contentId");
        content = onlineContent;
        isOfflineMode = false;
      }

      // Fallback to offline if online failed (even if isOfflineAvailable is false)
      if (content == null) {
        _logger.w("⚠️ Primary loading failed, attempting offline fallback...");
        try {
          content = await offlineContentManager.createOfflineContent(contentId);
          if (content != null) {
            _logger.i("✅ Successfully loaded content from offline fallback");
            isOfflineMode = true;
          }
        } catch (e) {
          _logger.e("❌ Offline fallback also failed: $e");
        }
      }

      if (content == null) {
        throw Exception('Content not available online or offline');
      }

      // 🚀 OPTIMIZATION: Emit loaded state immediately, then handle side effects
      emit(state.copyWith(
        content: content,
        currentPage: startPage,
        readingMode: savedSettings.readingMode,
        showUI: savedSettings.showUI,
        keepScreenOn: savedSettings.keepScreenOn,
        readingTimer: Duration.zero,
        isOfflineMode: isOfflineMode,
        imageMetadata: imageMetadata,
      ));

      // 🐛 DEBUG: Log all image URLs with their page numbers
      _logImageUrlMapping(content);

      emit(ReaderLoaded(state));

      // 🚀 OPTIMIZATION: Handle side effects asynchronously (don't block UI)
      _handlePostLoadSetup(savedSettings);
    } catch (e, stackTrace) {
      _logger.e("Reader Cubit: $e, $stackTrace");
      _stopAutoHideTimer();

      if (!isClosed) {
        emit(ReaderError(state.copyWith(
          message: 'Failed to load content: ${e.toString()}',
        )));
      }
    }
  }

  /// 🚀 OPTIMIZATION: Simplified reader settings loading
  Future<ReaderSettings> _loadReaderSettingsOptimized() async {
    try {
      return await readerSettingsRepository.getReaderSettings();
    } catch (e) {
      _logger.w("Failed to load reader settings, using defaults: $e");
      return const ReaderSettings(); // Use defaults
    }
  }

  /// 🚀 OPTIMIZATION: Handle post-load setup asynchronously
  Future<void> _handlePostLoadSetup(ReaderSettings savedSettings) async {
    try {
      // Apply keep screen on setting
      if (savedSettings.keepScreenOn) {
        await WakelockPlus.enable();
      }

      // Start reading timer
      _startReadingTimer();

      // Save to history (don't await to avoid blocking)
      _saveToHistory();
    } catch (e) {
      _logger.w("Post-load setup failed: $e");
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
    if (!state.isLastPage && !isClosed && state.content != null) {
      final currentPage = state.currentPage ?? 1;
      final newPage = (currentPage + 1).clamp(1, state.content!.pageCount);

      _logger.d(
          'Next page: $currentPage -> $newPage (total: ${state.content!.pageCount})');

      emit(state.copyWith(currentPage: newPage));
      _saveReaderPosition();
      _saveToHistory();
    }
  }

  /// Navigate to previous page
  void previousPage() {
    if (!state.isFirstPage && !isClosed && state.content != null) {
      final currentPage = state.currentPage ?? 1;
      final newPage = (currentPage - 1).clamp(1, state.content!.pageCount);

      _logger.d(
          'Previous page: $currentPage -> $newPage (total: ${state.content!.pageCount})');

      emit(state.copyWith(currentPage: newPage));
      _saveReaderPosition();
      _saveToHistory();
    }
  }

  /// Jump to specific page
  void jumpToPage(int page) {
    goToPage(page);
  }

  /// Navigate to specific page
  void goToPage(int page) {
    if (!isClosed && state.content != null) {
      // Validate page range
      final totalPages = state.content!.pageCount;
      final validPage = page.clamp(1, totalPages);

      if (page != validPage) {
        _logger.w(
            'Invalid page requested: $page, clamped to: $validPage (total: $totalPages)');
      }

      _logger.d(
          'Navigating to page: $validPage (requested: $page, total: $totalPages)');

      emit(state.copyWith(currentPage: validPage));
      _saveReaderPosition();
      _saveToHistory();
    } else {
      _logger.e(
          'Cannot navigate to page $page - cubit closed or content not loaded');
    }
  }

  /// Update current page from user swipe (without triggering navigation sync)
  void updateCurrentPageFromSwipe(int page) {
    if (!isClosed && state.content != null) {
      // Validate page range
      final totalPages = state.content!.pageCount;
      final validPage = page.clamp(1, totalPages);

      _logger.d('Updating page from swipe: $validPage (total: $totalPages)');

      // Only emit state change, don't trigger sync navigation
      emit(state.copyWith(currentPage: validPage));
      _saveReaderPosition();
      _saveToHistory();
    }
  }

  /// Toggle UI visibility
  void toggleUI() {
    if (!isClosed) {
      final newShowUI = !(state.showUI ?? true);
      emit(state.copyWith(showUI: newShowUI));

      // Save to preferences with error handling
      readerSettingsRepository
          .saveShowUI(newShowUI)
          .catchError((e, stackTrace) {
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
  }

  /// Show UI temporarily
  void showUI() {
    if (!isClosed) {
      emit(state.copyWith(showUI: true));
    }
    _startAutoHideTimer();
  }

  /// Hide UI
  void hideUI() {
    if (!isClosed) {
      emit(state.copyWith(showUI: false));
    }
    _stopAutoHideTimer();
  }

  /// Change reading mode
  Future<void> changeReadingMode(ReadingMode mode) async {
    if (!isClosed) {
      emit(state.copyWith(readingMode: mode));
    }

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

      if (!isClosed) {
        emit(state.copyWith(keepScreenOn: newKeepScreenOn));
      }

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

  /// Clear reader position for specific content (useful for debugging)
  Future<void> clearReaderPosition(String contentId) async {
    try {
      await readerRepository.deleteReaderPosition(contentId);
      _logger.i('🗑️ Cleared reader position for content: $contentId');
    } catch (e) {
      _logger.e('Failed to clear reader position: $e');
    }
  }

  /// Clear all reader positions (useful for debugging)
  Future<void> clearAllReaderPositions() async {
    try {
      await readerRepository.clearAllReaderPositions();
      _logger.i('🗑️ Cleared all reader positions');
    } catch (e) {
      _logger.e('Failed to clear all reader positions: $e');
    }
  }

  /// Clear image cache for specific content (useful for debugging)
  Future<void> clearImageCache(String contentId) async {
    try {
      await LocalImagePreloader.clearContentCache(contentId);
      _logger.i('🖼️ Cleared image cache for content: $contentId');

      // Note: CachedNetworkImage cache clearing requires DefaultCacheManager
      // Users can manually clear app data if needed
      _logger
          .i('ℹ️ To clear network image cache, clear app data or restart app');
    } catch (e) {
      _logger.e('Failed to clear image cache: $e');
    }
  }

  /// Debug: Log image URL mapping for current content
  void _logImageUrlMapping(Content content) {
    if (content.imageUrls.isEmpty) {
      _logger.w('⚠️ No image URLs found for content: ${content.id}');
      return;
    }

    _logger.i(
        '🖼️ Image URL Mapping for ${content.id} (${content.imageUrls.length} pages):');

    for (int i = 0; i < content.imageUrls.length && i < 10; i++) {
      final pageNumber = i + 1;
      final url = content.imageUrls[i];

      // Extract page number from URL if possible
      final urlPageNumber = _extractPageNumberFromUrl(url);

      final isMatch = urlPageNumber == pageNumber;
      final status = isMatch ? '✅' : '❌';

      _logger.i('  Page $pageNumber: $status URL contains page $urlPageNumber');
      _logger.d('    URL: $url');

      // Additional validation for first few pages
      if (i < 3) {
        _validateImageUrl(url, pageNumber, content.id);
      }
    }

    if (content.imageUrls.length > 10) {
      _logger.i('  ... and ${content.imageUrls.length - 10} more pages');
    }

    // Check for duplicate URLs in first few pages
    _checkForDuplicateUrls(content);
  }

  /// Validate individual image URL
  void _validateImageUrl(String url, int expectedPage, String contentId) {
    try {
      // Check if URL is accessible (basic validation)
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        _logger.w('⚠️ Invalid URL format for page $expectedPage: $url');
        return;
      }

      // Extract gallery ID from URL
      final galleryMatch = RegExp(r'/galleries/(\d+)/').firstMatch(url);
      if (galleryMatch != null) {
        final galleryId = galleryMatch.group(1);
        if (galleryId != contentId) {
          _logger.w(
              '⚠️ URL gallery ID mismatch! Expected $contentId, got $galleryId in URL: $url');
        }
      }

      _logger.d('✅ URL validation passed for page $expectedPage: $url');
    } catch (e) {
      _logger.w('⚠️ URL validation failed for page $expectedPage: $e');
    }
  }

  /// Check for duplicate URLs in content
  void _checkForDuplicateUrls(Content content) {
    final urlSet = <String>{};
    final duplicates = <String>[];

    for (final url in content.imageUrls) {
      if (!urlSet.add(url)) {
        duplicates.add(url);
      }
    }

    if (duplicates.isNotEmpty) {
      _logger.e('🚨 DUPLICATE URLs FOUND in content ${content.id}:');
      for (final duplicate in duplicates) {
        final indices = <int>[];
        for (int i = 0; i < content.imageUrls.length; i++) {
          if (content.imageUrls[i] == duplicate) {
            indices.add(i + 1); // Convert to 1-based page numbers
          }
        }
        _logger.e('  URL: $duplicate appears on pages: ${indices.join(", ")}');
      }
    } else {
      _logger.i('✅ No duplicate URLs found in content ${content.id}');
    }
  }

  /// Extract page number from image URL
  int? _extractPageNumberFromUrl(String url) {
    // Try to extract page number from patterns like:
    // https://i.nhentai.net/galleries/123456/1.jpg -> 1
    // https://i.nhentai.net/galleries/123456/86.jpg -> 86
    final match = RegExp(r'/galleries/\d+/(\d+)\.[^/]+$').firstMatch(url);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    // Try other patterns if needed
    final match2 = RegExp(r'/(\d+)\.[^/]*$').firstMatch(url);
    if (match2 != null) {
      return int.tryParse(match2.group(1)!);
    }

    return null;
  }

  /// Reset all reader settings to defaults
  Future<void> resetReaderSettings() async {
    try {
      await readerSettingsRepository.resetToDefaults();
      _logger.i("Successfully reset reader settings to defaults");

      // Apply default settings to current state
      if (!isClosed) {
        emit(state.copyWith(
          readingMode: ReadingMode.singlePage,
          keepScreenOn: false,
          showUI: true,
        ));
      }

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
      if (!isClosed) {
        emit(state.copyWith(
          readingMode: ReadingMode.singlePage,
          keepScreenOn: false,
          showUI: true,
        ));
      }

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
        title: state.content!.title,
        coverUrl: state.content!.coverUrl,
      );
      await addToHistoryUseCase(params);
    } catch (e) {
      // Log error but don't emit error state for history saving
    }
  }

  /// Save reader position for persistence
  Future<void> _saveReaderPosition() async {
    if (state.content == null) return;

    try {
      final position = ReaderPosition.create(
        contentId: state.content!.id,
        currentPage: state.currentPage ?? 1,
        totalPages: state.content!.pageCount,
        title: state.content!.title,
        coverUrl: state.content!.coverUrl,
        readingTimeMinutes: (state.readingTimer?.inMinutes ?? 0),
      );

      await readerRepository.saveReaderPosition(position);
      _logger.i(
          '✅ Saved reader position: ${state.content!.id} at page ${state.currentPage}/${state.content!.pageCount}');
    } catch (e) {
      _logger.e('Failed to save reader position: $e');
      // Don't emit error state for position saving
    }
  }

  /// Restore reader position if exists
  Future<int> _restoreReaderPosition(String contentId) async {
    try {
      final position = await readerRepository.getReaderPosition(contentId);
      if (position != null) {
        _logger.i(
            '📖 Restored reader position: $contentId at page ${position.currentPage}/${position.totalPages}');
        return position.currentPage;
      }
    } catch (e) {
      _logger.e('Failed to restore reader position: $e');
    }

    // Return first page as default
    return 1;
  }

  /// Start reading timer
  void _startReadingTimer() {
    _logger.i("start reading timer");
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Check if cubit is still active before emitting state
      if (!isClosed) {
        final currentTimer = state.readingTimer ?? Duration.zero;
        emit(state.copyWith(
          readingTimer: currentTimer + const Duration(seconds: 1),
        ));
      } else {
        // Cancel timer if cubit is closed
        timer.cancel();
      }
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
      // Check if cubit is still active before calling hideUI
      if (!isClosed && (state.showUI ?? false)) {
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
