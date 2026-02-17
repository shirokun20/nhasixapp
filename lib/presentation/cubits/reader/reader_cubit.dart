import 'dart:async';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../../domain/entities/reader_position.dart';
import '../../../domain/usecases/content/get_content_detail_usecase.dart';
import '../../../domain/usecases/content/get_chapter_images_usecase.dart';
import '../../../domain/usecases/history/add_to_history_usecase.dart';
import '../../../domain/repositories/reader_settings_repository.dart';
import '../../../domain/repositories/reader_repository.dart';
import '../../../data/models/reader_settings_model.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../core/models/image_metadata.dart';
import '../../../services/image_metadata_service.dart';
import '../../../services/local_image_preloader.dart';
import '../network/network_cubit.dart';
import '../../../core/utils/webtoon_detector.dart';

part 'reader_state.dart';

/// Simple cubit for managing reader functionality with offline support
class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required this.getContentDetailUseCase,
    required this.getChapterImagesUseCase,
    required this.addToHistoryUseCase,
    required this.readerSettingsRepository,
    required this.readerRepository,
    required this.offlineContentManager,
    required this.networkCubit,
    required this.imageMetadataService,
  }) : super(const ReaderInitial());

  final GetContentDetailUseCase getContentDetailUseCase;
  final GetChapterImagesUseCase getChapterImagesUseCase;
  final AddToHistoryUseCase addToHistoryUseCase;
  final ReaderSettingsRepository readerSettingsRepository;
  final ReaderRepository readerRepository;
  final OfflineContentManager offlineContentManager;
  final NetworkCubit networkCubit;
  final ImageMetadataService imageMetadataService;
  final Logger _logger = Logger();

  Timer? _readingTimer;
  Timer? _autoHideTimer;

  // Webtoon/manhwa auto-detection
  bool _hasDetectedWebtoon = false;

  // Chapter navigation context (stored as instance vars, NOT in state)
  Content? _parentContent;
  List<Chapter>? _allChapters;

  // Public getters for chapter navigation
  Content? get parentContent => _parentContent;
  List<Chapter>? get allChapters => _allChapters;

  /// Load content for reading with offline support - OPTIMIZED VERSION
  Future<void> loadContent(
    String contentId, {
    int initialPage = 1,
    bool forceStartFromBeginning = false,
    Content? preloadedContent,
    List<ImageMetadata>? imageMetadata,
    ChapterData? chapterData,
    Content? parentContent,
    List<Chapter>? allChapters,
    Chapter? currentChapter,
  }) async {
    try {
      _stopAutoHideTimer();
      emit(ReaderLoading(state));

      // Store chapter navigation context as instance vars
      _parentContent = parentContent;
      _allChapters = allChapters;

      _logger.i('ReaderCubit.loadContent - Received:');
      _logger.i('  contentId: $contentId');
      _logger.i('  parentContent: ${parentContent?.title ?? "NULL"}');
      _logger.i('  allChapters: ${allChapters?.length ?? 0} chapters');
      _logger.i('  currentChapter: ${currentChapter?.title ?? "NULL"}');
      _logger.i(
          '  chapterData: prev=${chapterData?.prevChapterId}, next=${chapterData?.nextChapterId}');

      final isConnected = networkCubit.isConnected;

      // 1. Check offline availability first (Fastest)
      final isOfflineAvailable =
          await offlineContentManager.isContentAvailableOffline(contentId);

      // 2. Load settings and restore position in parallel (Fast local DB ops)
      final localResults = await Future.wait([
        _loadReaderSettingsOptimized(),
        if (forceStartFromBeginning)
          Future<int>.value(1)
        else
          _restoreReaderPosition(contentId),
      ]);

      final savedSettings = localResults[0] as ReaderSettings;
      final restoredPage = localResults[1] as int;

      final startPage = initialPage > 1
          ? initialPage
          : (restoredPage > 1 ? restoredPage : initialPage);

      Content? content;
      bool isOfflineMode = false;

      // 3. Determine Loading Strategy

      // Strategy A: Preloaded Content (Navigation from specialized screens)
      bool shouldUsePreloaded =
          preloadedContent != null && preloadedContent.imageUrls.isNotEmpty;

      if (shouldUsePreloaded && isOfflineAvailable) {
        final hasRemoteUrls =
            preloadedContent.imageUrls.any((url) => url.startsWith('http'));
        if (hasRemoteUrls) {
          shouldUsePreloaded = false;
        }
      }

      if (shouldUsePreloaded) {
        _logger.i("Strategy A: Using preloaded content: $contentId");
        content = preloadedContent;
        final hasLocalPaths =
            content!.imageUrls.any((url) => url.startsWith('/'));
        isOfflineMode = hasLocalPaths || !isConnected;
      }
      // Strategy B: Offline Content (Primary Performance Path)
      else if (isOfflineAvailable) {
        _logger
            .i("Strategy B: Loading content from offline storage: $contentId");
        content = await offlineContentManager.createOfflineContent(contentId);
        isOfflineMode = true;

        if (isConnected && !_isCrotpediaChapterId(contentId)) {
          _fetchOnlineDetailsInBackground(contentId);
        }
      }
      // Strategy C: Online Content (Fallback)
      else if (isConnected && !_isCrotpediaChapterId(contentId)) {
        _logger.i("Strategy C: Fetching online content: $contentId");
        try {
          content = await getContentDetailUseCase(
              GetContentDetailParams.fromString(contentId));
          isOfflineMode = false;
        } catch (e) {
          _logger.w("Online fetch failed: $e");
        }
      }

      // Strategy D: Last Resort Fallback
      if (content == null) {
        if (preloadedContent != null && preloadedContent.imageUrls.isNotEmpty) {
          _logger
              .w("Strategy D: Using preloaded content as fallback: $contentId");
          content = preloadedContent;
          isOfflineMode = !isConnected;
        } else {
          try {
            content =
                await offlineContentManager.createOfflineContent(contentId);
            if (content != null) isOfflineMode = true;
          } catch (_) {}
        }
      }

      if (content == null) {
        if (_isCrotpediaChapterId(contentId)) {
          throw Exception(
              'Chapter not available offline. Please access this chapter from the series detail page to read online.');
        }
        throw Exception('Content not available online or offline');
      }

      // 3.5. Fetch ChapterData if missing (for navigation)
      if (chapterData == null &&
          isConnected &&
          _isCrotpediaChapterId(contentId)) {
        try {
          _logger.i('Fetching missing chapter data for navigation: $contentId');
          final fetchedChapterData =
              await getChapterImagesUseCase(GetChapterImagesParams.fromString(
            contentId,
            sourceId: content.sourceId,
          ));
          chapterData = fetchedChapterData;
        } catch (e) {
          _logger.w('Failed to fetch chapter navigation data: $e');
        }
      }

      // 4. Emit Loaded State Immediately
      emit(state.copyWith(
        content: content,
        currentPage: startPage,
        readingMode: savedSettings.readingMode,
        showUI: savedSettings.showUI,
        keepScreenOn: savedSettings.keepScreenOn,
        readingTimer: Duration.zero,
        isOfflineMode: isOfflineMode,
        imageMetadata: imageMetadata,
        chapterData: chapterData,
        currentChapter: currentChapter,
      ));

      _logImageUrlMapping(content);
      emit(ReaderLoaded(state));

      // 5. Post-load setup (Async)
      _handlePostLoadSetup(savedSettings);
    } catch (e, stackTrace) {
      _logger.e("Reader Cubit Error: $e", error: e, stackTrace: stackTrace);
      _stopAutoHideTimer();
      if (!isClosed) {
        emit(ReaderError(state.copyWith(
          message: 'Failed to load content: ${e.toString()}',
        )));
      }
    }
  }

  /// Fire-and-forget online fetch to update metadata or cache
  Future<void> _fetchOnlineDetailsInBackground(String contentId) async {
    try {
      await getContentDetailUseCase(
          GetContentDetailParams.fromString(contentId));
    } catch (e) {
      // Ignore background errors
    }
  }

  /// Simplified reader settings loading
  Future<ReaderSettings> _loadReaderSettingsOptimized() async {
    try {
      return await readerSettingsRepository.getReaderSettings();
    } catch (e) {
      _logger.w("Failed to load reader settings, using defaults: $e");
      return const ReaderSettings();
    }
  }

  /// Handle post-load setup asynchronously
  Future<void> _handlePostLoadSetup(ReaderSettings savedSettings) async {
    try {
      if (savedSettings.keepScreenOn) {
        await WakelockPlus.enable();
      }
      _startReadingTimer();
      _saveToHistory();
    } catch (e) {
      _logger.w("Post-load setup failed: $e");
    }
  }

  /// Navigate to next page
  void nextPage() {
    if (!isClosed && state.content != null) {
      final currentPage = state.currentPage ?? 1;
      final pageCount = state.content!.pageCount;

      // Allow +1 for navigation page (if not offline)
      final hasNavigationPage = !(state.isOfflineMode ?? false) &&
          state.content!.imageUrls.isNotEmpty;
      final maxPage = hasNavigationPage ? pageCount + 1 : pageCount;

      if (currentPage < maxPage) {
        final newPage = (currentPage + 1).clamp(1, maxPage);

        _logger.d(
            'Next page: $currentPage -> $newPage (total: $pageCount, max with nav: $maxPage)');

        emit(state.copyWith(currentPage: newPage));
        _saveReaderPosition();
        _saveToHistory();
      } else {
        _logger.d('Already at last page ($currentPage), cannot go further');
      }
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

  /// Load next chapter using chapterData from API
  Future<void> loadNextChapter() async {
    if (state.chapterData?.nextChapterId == null) return;
    await loadChapter(state.chapterData!.nextChapterId!);
  }

  /// Load previous chapter using chapterData from API
  Future<void> loadPreviousChapter() async {
    if (state.chapterData?.prevChapterId == null) return;
    await loadChapter(state.chapterData!.prevChapterId!);
  }

  /// Load a specific chapter by ID - fetches images online
  Future<void> loadChapter(String chapterId) async {
    try {
      if (_allChapters == null || _allChapters!.isEmpty) {
        _logger.e('Cannot navigate: No chapter list available');
        emit(ReaderError(state.copyWith(
          message: 'Chapter navigation not available',
        )));
        return;
      }

      emit(ReaderLoading(state));

      // Find chapter in allChapters list
      final chapter = _allChapters!.firstWhere(
        (ch) => ch.id == chapterId,
        orElse: () =>
            Chapter(id: chapterId, title: 'Unknown Chapter', url: chapterId),
      );

      _logger.i('Loading chapter: ${chapter.title} (${chapter.id})');

      // Fetch chapter images and navigation data from API
      final chapterData =
          await getChapterImagesUseCase(GetChapterImagesParams.fromString(
        chapterId,
        sourceId: _parentContent?.sourceId ?? state.content?.sourceId,
      ));

      if (chapterData.images.isEmpty) {
        emit(ReaderError(state.copyWith(
          message: 'Failed to load chapter images',
        )));
        return;
      }

      // Build full title
      final parentTitle =
          _parentContent?.title ?? state.content?.title.split(' - ')[0] ?? '';
      final fullTitle = '$parentTitle - ${chapter.title}';

      final newContent = (_parentContent ?? state.content!).copyWith(
        id: chapterId,
        title: fullTitle,
        imageUrls: chapterData.images,
        pageCount: chapterData.images.length,
        chapters: _allChapters ?? [],
      );

      emit(ReaderLoaded(state.copyWith(
        content: newContent,
        currentPage: 1,
        chapterData: chapterData,
        currentChapter: chapter,
        readingTimer: Duration.zero,
      )));

      // Save to history
      await _saveToHistory();
    } catch (e) {
      _logger.e('Failed to load chapter: $e');
      emit(ReaderError(state.copyWith(
        message: 'Failed to load chapter: ${e.toString()}',
      )));
    }
  }

  // ==================== LEGACY Chapter Navigation (kept for backward compat) ====================

  /// Navigate to previous chapter using allChapters list
  /// Deprecated: prefer loadPreviousChapter() which uses chapterData from API
  Future<bool> goToPreviousChapter() async {
    // First try API-based navigation (more reliable)
    if (state.chapterData?.prevChapterId != null) {
      await loadChapter(state.chapterData!.prevChapterId!);
      return true;
    }

    // Fallback to allChapters list navigation
    if (isClosed || state.content == null) return false;
    if (_allChapters == null || _allChapters!.isEmpty) return false;
    if (state.currentChapter == null) return false;

    final currentIndex =
        _allChapters!.indexWhere((c) => c.id == state.currentChapter!.id);
    if (currentIndex <= 0) return false;

    final prevChapter = _allChapters![currentIndex - 1];
    _logger.i(
        'Navigating to previous chapter (list): ${prevChapter.id} - ${prevChapter.title}');

    await loadChapter(prevChapter.id);
    return true;
  }

  /// Navigate to next chapter using allChapters list
  /// Deprecated: prefer loadNextChapter() which uses chapterData from API
  Future<bool> goToNextChapter() async {
    // First try API-based navigation (more reliable)
    if (state.chapterData?.nextChapterId != null) {
      await loadChapter(state.chapterData!.nextChapterId!);
      return true;
    }

    // Fallback to allChapters list navigation
    if (isClosed || state.content == null) return false;
    if (_allChapters == null || _allChapters!.isEmpty) return false;
    if (state.currentChapter == null) return false;

    final currentIndex =
        _allChapters!.indexWhere((c) => c.id == state.currentChapter!.id);
    if (currentIndex < 0 || currentIndex >= _allChapters!.length - 1) {
      return false;
    }

    final nextChap = _allChapters![currentIndex + 1];
    _logger.i(
        'Navigating to next chapter (list): ${nextChap.id} - ${nextChap.title}');

    await loadChapter(nextChap.id);
    return true;
  }

  /// Jump to specific page
  void jumpToPage(int page) {
    goToPage(page);
  }

  /// Navigate to specific page
  void goToPage(int page) {
    if (!isClosed && state.content != null) {
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
      final totalPages = state.content!.pageCount;

      // Allow +1 for navigation page (if exists)
      final hasNavigationPage = !(state.isOfflineMode ?? false) &&
          state.content!.imageUrls.isNotEmpty;
      final maxPage = hasNavigationPage ? totalPages + 1 : totalPages;

      final validPage = page.clamp(1, maxPage);

      _logger.d(
          'Updating page from swipe: $validPage (total: $totalPages, max with nav: $maxPage)');

      emit(state.copyWith(currentPage: validPage));
      _saveReaderPosition();
      _saveToHistory();
    }
  }

  /// Update current page for continuous scroll (silent update without state emission)
  void updateCurrentPageSilent(int page) async {
    if (!isClosed && state.content == null) return;

    final totalPages = state.content!.pageCount;
    final validPage = page.clamp(1, totalPages);

    _logger.d(
        'Silent page update for continuous scroll: $validPage (total: $totalPages)');

    try {
      final position = ReaderPosition.create(
        contentId: state.content!.id,
        currentPage: validPage,
        totalPages: totalPages,
        title: state.content!.title,
        coverUrl: state.content!.coverUrl,
        readingTimeMinutes: (state.readingTimer?.inMinutes ?? 0),
      );

      await readerRepository.saveReaderPosition(position);

      // Also update history - ONLY for nhentai
      if (state.content!.sourceId == SourceType.nhentai.id) {
        final params = AddToHistoryParams.fromString(
          state.content!.id,
          validPage,
          totalPages,
          timeSpent: state.readingTimer ?? Duration.zero,
          title: state.content!.title,
          coverUrl: state.content!.coverUrl,
          sourceId: state.content!.sourceId,
        );
        await addToHistoryUseCase(params);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to save silent page update to history',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Toggle UI visibility
  void toggleUI() {
    if (!isClosed) {
      final newShowUI = !(state.showUI ?? true);
      emit(state.copyWith(showUI: newShowUI));

      readerSettingsRepository
          .saveShowUI(newShowUI)
          .catchError((e, stackTrace) {
        _logger.e("Failed to save show UI setting: $e",
            error: e, stackTrace: stackTrace);
      });

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

  /// Handle image loaded and detect webtoon/manhwa format
  void onImageLoaded(int pageNumber, Size imageSize) {
    if (pageNumber > 3 || _hasDetectedWebtoon) return;

    final isWebtoon = WebtoonDetector.isWebtoon(imageSize);
    final aspectRatio = WebtoonDetector.getAspectRatio(imageSize);

    if (isWebtoon) {
      _hasDetectedWebtoon = true;
      final currentMode = state.readingMode ?? ReadingMode.singlePage;

      if (currentMode != ReadingMode.continuousScroll) {
        _logger.i('Webtoon/Manhwa detected on page $pageNumber! '
            'AR=${aspectRatio?.toStringAsFixed(2)} (${imageSize.width.toInt()}x${imageSize.height.toInt()}px) '
            'Auto-switching from ${currentMode.name} to continuousScroll');

        if (!isClosed) {
          emit(state.copyWith(readingMode: ReadingMode.continuousScroll));
        }
      }
    }
  }

  /// Change reading mode
  Future<void> changeReadingMode(ReadingMode mode) async {
    if (!isClosed) {
      emit(state.copyWith(readingMode: mode));
    }

    _hasDetectedWebtoon = false;

    try {
      await readerSettingsRepository.saveReadingMode(mode);
      _logger.i("Successfully saved reading mode: ${mode.name}");
    } catch (e, stackTrace) {
      _logger.e("Failed to save reading mode: $e",
          error: e, stackTrace: stackTrace);
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

      try {
        await readerSettingsRepository.saveKeepScreenOn(newKeepScreenOn);
        _logger.i("Successfully saved keep screen on: $newKeepScreenOn");
      } catch (e, stackTrace) {
        _logger.e("Failed to save keep screen on setting: $e",
            error: e, stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      _logger.e("Failed to toggle wakelock: $e",
          error: e, stackTrace: stackTrace);
    }
  }

  /// Clear reader position for specific content
  Future<void> clearReaderPosition(String contentId) async {
    try {
      await readerRepository.deleteReaderPosition(contentId);
      _logger.i('Cleared reader position for content: $contentId');
    } catch (e) {
      _logger.e('Failed to clear reader position: $e');
    }
  }

  /// Clear all reader positions
  Future<void> clearAllReaderPositions() async {
    try {
      await readerRepository.clearAllReaderPositions();
      _logger.i('Cleared all reader positions');
    } catch (e) {
      _logger.e('Failed to clear all reader positions: $e');
    }
  }

  /// Clear image cache for specific content
  Future<void> clearImageCache(String contentId) async {
    try {
      await LocalImagePreloader.clearContentCache(contentId);
      _logger.i('Cleared image cache for content: $contentId');
      _logger.i('To clear network image cache, clear app data or restart app');
    } catch (e) {
      _logger.e('Failed to clear image cache: $e');
    }
  }

  /// Debug: Log image URL mapping for current content
  void _logImageUrlMapping(Content content) {
    if (content.imageUrls.isEmpty) {
      _logger.w('No image URLs found for content: ${content.id}');
      return;
    }

    _logger.i(
        'Image URL Mapping for ${content.id} (${content.imageUrls.length} pages):');

    for (int i = 0; i < content.imageUrls.length && i < 10; i++) {
      final pageNumber = i + 1;
      final url = content.imageUrls[i];

      final urlPageNumber = _extractPageNumberFromUrl(url);

      final isMatch = urlPageNumber == pageNumber;
      final status = isMatch ? 'OK' : 'MISMATCH';

      _logger.i('  Page $pageNumber: $status URL contains page $urlPageNumber');
      _logger.d('    URL: $url');

      if (i < 3) {
        _validateImageUrl(url, pageNumber, content.id);
      }
    }

    if (content.imageUrls.length > 10) {
      _logger.i('  ... and ${content.imageUrls.length - 10} more pages');
    }

    _checkForDuplicateUrls(content);
  }

  /// Validate individual image URL
  void _validateImageUrl(String url, int expectedPage, String contentId) {
    try {
      if (url.startsWith('/')) {
        _logger.d(
            'Local file path validation passed for page $expectedPage: $url');
        return;
      }

      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        _logger.w('Invalid URL format for page $expectedPage: $url');
        return;
      }

      final galleryMatch = RegExp(r'/galleries/(\d+)/').firstMatch(url);
      if (galleryMatch != null) {
        final galleryId = galleryMatch.group(1);
        if (galleryId != contentId) {
          _logger.w(
              'URL gallery ID mismatch! Expected $contentId, got $galleryId in URL: $url');
        }
      }

      _logger.d('URL validation passed for page $expectedPage: $url');
    } catch (e) {
      _logger.w('URL validation failed for page $expectedPage: $e');
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
      _logger.e('DUPLICATE URLs FOUND in content ${content.id}:');
      for (final duplicate in duplicates) {
        final indices = <int>[];
        for (int i = 0; i < content.imageUrls.length; i++) {
          if (content.imageUrls[i] == duplicate) {
            indices.add(i + 1);
          }
        }
        _logger.e('  URL: $duplicate appears on pages: ${indices.join(", ")}');
      }
    } else {
      _logger.i('No duplicate URLs found in content ${content.id}');
    }
  }

  /// Extract page number from image URL
  int? _extractPageNumberFromUrl(String url) {
    final match = RegExp(r'/galleries/\d+/(\d+)\.[^/]+$').firstMatch(url);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

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

      if (!isClosed) {
        emit(state.copyWith(
          readingMode: ReadingMode.singlePage,
          keepScreenOn: false,
          showUI: true,
        ));
      }

      try {
        await WakelockPlus.disable();
      } catch (e, stackTrace) {
        _logger.e("Failed to disable wakelock during reset: $e",
            error: e, stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      _logger.e("Failed to reset reader settings: $e",
          error: e, stackTrace: stackTrace);

      if (!isClosed) {
        emit(state.copyWith(
          readingMode: ReadingMode.singlePage,
          keepScreenOn: false,
          showUI: true,
        ));
      }

      try {
        await WakelockPlus.disable();
      } catch (wakelockError) {
        _logger
            .e("Failed to disable wakelock after reset error: $wakelockError");
      }

      rethrow;
    }
  }

  /// Save current reading progress to history
  /// Only save history for nhentai source (as requested)
  Future<void> _saveToHistory() async {
    try {
      if (state.content != null &&
          state.content!.sourceId != SourceType.nhentai.id) {
        _logger.d(
            'Skipping history save for non-nhentai source: ${state.content!.sourceId}');
        return;
      }

      final params = AddToHistoryParams.fromString(
        state.content!.id,
        state.currentPage ?? 1,
        state.content!.pageCount,
        timeSpent: state.readingTimer ?? Duration.zero,
        title: state.content!.title,
        coverUrl: state.content!.coverUrl,
        sourceId: state.content!.sourceId,
      );
      await addToHistoryUseCase(params);
    } catch (e, stackTrace) {
      _logger.e('Failed to save reading progress to history',
          error: e, stackTrace: stackTrace);
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
    } catch (e) {
      _logger.e('Failed to save reader position: $e');
    }
  }

  /// Restore reader position if exists
  Future<int> _restoreReaderPosition(String contentId) async {
    try {
      final position = await readerRepository.getReaderPosition(contentId);
      if (position != null) {
        _logger.i(
            'Restored reader position: $contentId at page ${position.currentPage}/${position.totalPages}');
        return position.currentPage;
      }
    } catch (e) {
      _logger.e('Failed to restore reader position: $e');
    }

    return 1;
  }

  /// Start reading timer
  void _startReadingTimer() {
    _logger.i("start reading timer");
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed) {
        final currentTimer = state.readingTimer ?? Duration.zero;
        emit(state.copyWith(
          readingTimer: currentTimer + const Duration(seconds: 1),
        ));
      } else {
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
      if (!isClosed && (state.showUI ?? false)) {
        hideUI();
      }
    });
  }

  /// Check if contentId is a Crotpedia chapter ID
  bool _isCrotpediaChapterId(String contentId) {
    if (RegExp(r'^\d+$').hasMatch(contentId)) {
      return false;
    }

    if (contentId.contains('chapter') || contentId.contains('ch-')) {
      return true;
    }

    final dashCount = '-'.allMatches(contentId).length;
    return dashCount >= 3;
  }

  /// Stop auto-hide UI timer
  void _stopAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  @override
  Future<void> close() async {
    _stopReadingTimer();
    _stopAutoHideTimer();

    await _saveToHistory();

    await WakelockPlus.disable();

    return super.close();
  }
}
