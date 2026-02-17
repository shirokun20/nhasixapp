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

  // Chapter navigation context
  Content? _parentContent; // Parent series for chapter navigation
  List<Chapter>? _allChapters; // All chapters available for navigation

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
    Content? parentContent, // Parent series for chapter mode
    List<Chapter>? allChapters, // All chapters for navigation
    Chapter? currentChapter, // Current chapter being read
  }) async {
    try {
      _stopAutoHideTimer();
      emit(ReaderLoading(state));

      // Store chapter navigation context first
      _parentContent = parentContent;
      _allChapters = allChapters;

      // 🔍 DEBUG LOGGING - What did ReaderCubit receive?
      _logger.i('📥 ReaderCubit.loadContent - Received:');
      _logger.i('  contentId: $contentId');
      _logger.i('  preloadedContent: ${preloadedContent?.title ?? "NULL"}');
      _logger.i('  parentContent: ${parentContent?.title ?? "NULL"}');
      _logger.i('  parentContent.id: ${parentContent?.id ?? "NULL"}');
      _logger.i('  allChapters: ${allChapters?.length ?? 0} chapters');
      if (allChapters != null && allChapters.isNotEmpty) {
        _logger.i(
            '    First: ${allChapters.first.title} (${allChapters.first.id})');
        _logger
            .i('    Last: ${allChapters.last.title} (${allChapters.last.id})');
      }
      _logger.i('  currentChapter: ${currentChapter?.title ?? "NULL"}');
      _logger.i(
          '  chapterData: prev=${chapterData?.prevChapterId}, next=${chapterData?.nextChapterId}');
      _logger.i('');
      _logger.i('  Stored in ReaderCubit:');
      _logger.i('  _parentContent: ${_parentContent?.title ?? "NULL"}');
      _logger.i('  _allChapters: ${_allChapters?.length ?? 0} chapters');

      // Check network connectivity?.chapters;

      final isConnected = networkCubit.isConnected;

      // 1. Check offline availability first (Fastest)
      // This uses the new caching in OfflineContentManager so it's very fast
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

      // Use initialPage if user explicitly requested a specific page (initialPage > 1)
      // Otherwise use restored page if available, fallback to initialPage
      final startPage = initialPage > 1
          ? initialPage
          : (restoredPage > 1 ? restoredPage : initialPage);

      Content? content;
      bool isOfflineMode = false;

      // 3. Determine Loading Strategy

      // Strategy A: Preloaded Content (Navigation from specialized screens)
      // If preloaded content has local paths (starting with /), use it directly - it's offline content
      final shouldUsePreloaded =
          preloadedContent != null && preloadedContent.imageUrls.isNotEmpty;

      if (shouldUsePreloaded) {
        // Check if preloaded content has local paths (offline content)
        final hasLocalPaths =
            preloadedContent.imageUrls.any((url) => url.startsWith('/'));
        if (hasLocalPaths) {
          // ✅ Preloaded content IS offline content - use it directly
          _logger
              .i('✅ Strategy A: Using preloaded OFFLINE content: $contentId');
          content = preloadedContent;
          isOfflineMode = true;
        } else {
          // Has http URLs - check if offline is available first
          final hasRemoteUrls =
              preloadedContent.imageUrls.any((url) => url.startsWith('http'));

          if (isOfflineAvailable && hasRemoteUrls) {
            // Prefer offline path if available, even if we have preloaded content with remote URLs
            _logger.i(
                '💾 Strategy A2: Found offline available, loading from local storage');
            content =
                await offlineContentManager.createOfflineContent(contentId);
            isOfflineMode = true;
          } else if (hasRemoteUrls) {
            // Use preloaded content with remote URLs (will load from network)
            _logger.i(
                '✅ Strategy A3: Using preloaded content with remote URLs: $contentId');
            content = preloadedContent;
            isOfflineMode = !isConnected;
          }
        }
      }

      // Strategy B: Offline Content (Primary Performance Path) - only if content not set yet
      if (content == null && isOfflineAvailable) {
        _logger.i(
            '💾 Strategy B: Loading content from offline storage: $contentId');
        content = await offlineContentManager.createOfflineContent(contentId);
        isOfflineMode = true;

        // 🚀 OPTIONAL: Trigger background online update if connected
        // This updates metadata/details silently without blocking UI
        if (isConnected && !_isCrotpediaChapterId(contentId)) {
          await _fetchOnlineDetailsInBackground(contentId);
        }
      }
      // Strategy C: Online Content (Fallback) - only if content not set yet
      else if (content == null &&
          isConnected &&
          !_isCrotpediaChapterId(contentId)) {
        _logger.i('🌐 Strategy C: Fetching online content: $contentId');
        try {
          content = await getContentDetailUseCase(
              GetContentDetailParams.fromString(contentId));
          isOfflineMode = false;
        } catch (e) {
          _logger.w('Online fetch failed: $e');
        }
      }
      // Strategy D: Last Resort Fallback (Partial Preloaded or Offline Retry)
      if (content == null) {
        if (preloadedContent != null && preloadedContent.imageUrls.isNotEmpty) {
          _logger.w(
              '⚠️ Strategy D: Using preloaded content as fallback: $contentId');
          content = preloadedContent;
          isOfflineMode = !isConnected;
        } else {
          // Try offline creation one last time (maybe cache missed?)
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
      // If we loaded content but don't have chapterData (navigation links), try to fetch it
      if (chapterData == null &&
          isConnected &&
          _isCrotpediaChapterId(contentId)) {
        try {
          _logger
              .i('🔍 Fetching missing chapter data for navigation: $contentId');
          final fetchedChapterData =
              await getChapterImagesUseCase(GetChapterImagesParams.fromString(
            contentId,
            sourceId: content.sourceId,
          ));
          chapterData = fetchedChapterData;
        } catch (e) {
          _logger.w('Failed to fetch chapter navigation data: $e');
          // Start without navigation rather than failing completely
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
      await _handlePostLoadSetup(savedSettings);
    } catch (e, stackTrace) {
      _logger.e('Reader Cubit Error: $e', error: e, stackTrace: stackTrace);
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
      // Results are cached by repository, so next load handles it.
      // We don't update current UI to avoid jarring changes while reading.
    } catch (e) {
      // Ignore background errors
    }
  }

  /// 🚀 OPTIMIZATION: Simplified reader settings loading
  Future<ReaderSettings> _loadReaderSettingsOptimized() async {
    try {
      return await readerSettingsRepository.getReaderSettings();
    } catch (e) {
      _logger.w('Failed to load reader settings, using defaults: $e');
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
      await _saveToHistory();
    } catch (e) {
      _logger.w('Post-load setup failed: $e');
    }
  }

  /// Navigate to next page
  void nextPage() {
    if (!isClosed && state.content != null) {
      final currentPage = state.currentPage ?? 1;
      final pageCount = state.content!.pageCount;

      // Check if navigation page should be shown
      final hasNavigationPage = !(state.isOfflineMode ?? false) &&
          state.content!.imageUrls.isNotEmpty;

      // If we're at last page and navigation page exists, allow +1 to show navigation
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

  /// Load next chapter
  Future<void> loadNextChapter() async {
    if (state.chapterData?.nextChapterId == null) return;
    await loadChapter(state.chapterData!.nextChapterId!);
  }

  /// Load previous chapter
  Future<void> loadPreviousChapter() async {
    if (state.chapterData?.prevChapterId == null) return;
    await loadChapter(state.chapterData!.prevChapterId!);
  }

  Future<void> loadChapter(String chapterId) async {
    try {
      if (_allChapters == null || _allChapters!.isEmpty) {
        _logger.e('⛔ Cannot navigate: No chapter list available');
        emit(ReaderError(state.copyWith(
          message: 'Chapter navigation not available',
        )));
        return;
      }

      emit(ReaderLoading(state));

      // IMPORTANT: We now rely on _allChapters list passed from DetailScreen
      // This list contains chapters in the correct order with their IDs
      final chapter = _allChapters!.firstWhere(
        (ch) => ch.id == chapterId,
        orElse: () =>
            Chapter(id: chapterId, title: 'Unknown Chapter', url: chapterId),
      );

      _logger.i('Loading chapter: ${chapter.title} (${chapter.id})');

      // 🚀 OFFLINE-FIRST: Check if chapter is available offline
      final isOfflineAvailable =
          await offlineContentManager.isContentAvailableOffline(chapterId);

      List<String> chapterImages = [];
      bool loadedFromOffline = false;

      if (isOfflineAvailable) {
        _logger.i(
            '✅ Chapter $chapterId found offline, loading from local storage');
        chapterImages =
            await offlineContentManager.getOfflineImageUrls(chapterId);

        if (chapterImages.isNotEmpty) {
          loadedFromOffline = true;
          _logger.i(
              '✅ Loaded ${chapterImages.length} images from offline storage');
        } else {
          _logger.w('⚠️ Offline chapter directory exists but no images found');
        }
      }

      // Fallback to online API if offline content not available or failed
      ChapterData? chapterData;
      if (!loadedFromOffline) {
        _logger.i('📡 Fetching chapter from online API');

        // Check connectivity before making online request
        final hasConnection = networkCubit.isConnected;

        if (!hasConnection) {
          _logger
              .e('❌ No internet connection and chapter not available offline');
          emit(ReaderError(state.copyWith(
            message:
                'Cannot load chapter: No internet connection and chapter not downloaded',
          )));
          return;
        }

        try {
          chapterData =
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

          chapterImages = chapterData.images;
        } catch (e) {
          _logger.e('Failed to load chapter from online API: $e');
          emit(ReaderError(state.copyWith(
            message: 'Failed to load chapter: ${e.toString()}',
          )));
          return;
        }
      }

      // Extract the parent series title (before the ' - Chapter' part)
      final parentTitle =
          _parentContent?.title ?? state.content?.title.split(' - ')[0] ?? '';
      final fullTitle = '$parentTitle - ${chapter.title}';

      final newContent = (_parentContent ?? state.content!).copyWith(
        id: chapterId,
        title: fullTitle,
        imageUrls: chapterImages,
        pageCount: chapterImages.length,
        chapters: _allChapters ?? [], // Include all chapters for navigation
      );

      emit(ReaderLoaded(state.copyWith(
        content: newContent,
        currentPage: 1,
        chapterData: chapterData,
        currentChapter: chapter,
        readingTimer: Duration.zero,
        isOfflineMode:
            loadedFromOffline, // Mark as offline if loaded from local storage
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

      // Allow +1 for navigation page (if exists)
      final hasNavigationPage = !(state.isOfflineMode ?? false) &&
          state.content!.imageUrls.isNotEmpty;
      final maxPage = hasNavigationPage ? totalPages + 1 : totalPages;

      final validPage = page.clamp(1, maxPage);

      _logger.d(
          'Updating page from swipe: $validPage (total: $totalPages, max with nav: $maxPage)');

      // Only emit state change, don't trigger sync navigation
      emit(state.copyWith(currentPage: validPage));
      _saveReaderPosition();
      _saveToHistory();
    }
  }

  /// Update current page for continuous scroll (silent update without state emission)
  /// This prevents re-rendering all ListView items when page changes
  void updateCurrentPageSilent(int page) async {
    if (!isClosed && state.content == null) return;

    final totalPages = state.content!.pageCount;
    final validPage = page.clamp(1, totalPages);

    _logger.d(
        '📍 Silent page update for continuous scroll: $validPage (total: $totalPages)');

    // DON'T emit state - this prevents BlocBuilder rebuilds
    // But still save position and history for persistence
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

      if (state.isOfflineMode == true) return;

      int? chapterIndex;
      if (state.currentChapter != null && state.content?.chapters != null) {
        chapterIndex = state.content!.chapters!
            .indexWhere((c) => c.id == state.currentChapter!.id);
      }

      // Determine chapter ID - fallback to content.id for chapter mode
      String? chapterId = state.currentChapter?.id;
      String? chapterTitle = state.currentChapter?.title;

      // If currentChapter is null but content.id looks like a chapter ID, use it
      if (chapterId == null || chapterId.isEmpty) {
        final contentId = state.content!.id;
        if (_isCrotpediaChapterId(contentId)) {
          chapterId = contentId;
          // Try to extract chapter title from content title
          final title = state.content!.title;
          if (title.contains(' - ')) {
            chapterTitle = title.split(' - ').last;
          } else {
            chapterTitle = title;
          }
        }
      }

      // Additional fallback: if chapterId is still empty but we have chapterTitle
      // that looks like a chapter ID (contains "-chapter-"), use it
      if ((chapterId == null || chapterId.isEmpty) &&
          chapterTitle != null &&
          chapterTitle.isNotEmpty &&
          chapterTitle.contains('-chapter-')) {
        chapterId = chapterTitle;
      }

      // NEW LOGIC:
      // - If chapter mode: contentId = chapter.id, parentId = series.id
      // - If non-chapter mode: contentId = content.id, parentId = null
      final bool isChapterMode = chapterId != null && chapterId.isNotEmpty;
      final String historyContentId;
      final String? historyParentId;

      if (isChapterMode) {
        // Chapter mode: use chapter.id as contentId
        historyContentId = chapterId;
        // parentId is the series ID
        historyParentId = _parentContent?.id;
      } else {
        // Non-chapter mode: use content.id as contentId
        historyContentId = state.content!.id;
        historyParentId = null;
      }

      final params = AddToHistoryParams.fromString(
        historyContentId,
        validPage,
        totalPages,
        timeSpent: state.readingTimer ?? Duration.zero,
        title: state.content!.title,
        coverUrl: state.content!.coverUrl,
        sourceId: state.content!.sourceId,
        parentId: historyParentId,
        chapterId: chapterId,
        chapterIndex: chapterIndex,
        chapterTitle: chapterTitle,
      );
      await addToHistoryUseCase(params);
    } catch (e, stackTrace) {
      _logger.e('Failed to save silent page update to history',
          error: e, stackTrace: stackTrace);
      // Don't emit error state
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
        _logger.e('Failed to save show UI setting: $e',
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

  /// Handle image loaded and detect webtoon/manhwa format
  /// Auto-switches to continuous scroll for vertical images
  void onImageLoaded(int pageNumber, Size imageSize) {
    // Only check first few images to avoid performance overhead
    if (pageNumber > 3 || _hasDetectedWebtoon) return;

    final isWebtoon = WebtoonDetector.isWebtoon(imageSize);
    final aspectRatio = WebtoonDetector.getAspectRatio(imageSize);

    if (isWebtoon) {
      _hasDetectedWebtoon = true;
      final currentMode = state.readingMode ?? ReadingMode.singlePage;

      // Only auto-switch if not already in continuous scroll
      if (currentMode != ReadingMode.continuousScroll) {
        _logger.i('🎨 Webtoon/Manhwa detected on page $pageNumber! '
            'AR=${aspectRatio?.toStringAsFixed(2)} (${imageSize.width.toInt()}x${imageSize.height.toInt()}px) '
            '→ Auto-switching from ${currentMode.name} to continuousScroll');

        // Switch to continuous scroll (best for vertical images)
        if (!isClosed) {
          emit(state.copyWith(readingMode: ReadingMode.continuousScroll));
        }

        // Note: We don't save this to preferences to preserve user's choice
        // The auto-switch only applies to current reading session
      }
    } else {
      // _logger.d('📖 Normal image detected on page $pageNumber: '
      //     'AR=${aspectRatio?.toStringAsFixed(2)} (${imageSize.width.toInt()}x${imageSize.height.toInt()}px)');
    }
  }

  /// Change reading mode
  Future<void> changeReadingMode(ReadingMode mode) async {
    if (!isClosed) {
      emit(state.copyWith(readingMode: mode));
    }

    // Reset webtoon detection if user manually changes mode
    _hasDetectedWebtoon = false;

    // Save to preferences with error handling
    try {
      await readerSettingsRepository.saveReadingMode(mode);
      _logger.i('Successfully saved reading mode: ${mode.name}');
    } catch (e, stackTrace) {
      _logger.e('Failed to save reading mode: $e',
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
        _logger.i('Successfully saved keep screen on: $newKeepScreenOn');
      } catch (e, stackTrace) {
        _logger.e('Failed to save keep screen on setting: $e',
            error: e, stackTrace: stackTrace);
        // Settings will still apply for current session
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to toggle wakelock: $e',
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
      // Allow local file paths (start with /)
      if (url.startsWith('/')) {
        _logger.d(
            '✅ Local file path validation passed for page $expectedPage: $url');
        return;
      }

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
      _logger.i('Successfully reset reader settings to defaults');

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
        _logger.e('Failed to disable wakelock during reset: $e',
            error: e, stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to reset reader settings: $e',
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
            .e('Failed to disable wakelock after reset error: $wakelockError');
      }

      // Re-throw to let UI handle the error
      rethrow;
    }
  }

  /// Save current reading progress to history
  Future<void> _saveToHistory() async {
    if (state.isOfflineMode == true) return;

    try {
      _logger.d('📝 _saveToHistory called');
      _logger.d(
          '   state.currentChapter: ${state.currentChapter?.title ?? "NULL"}');
      _logger.d(
          '   state.currentChapter.id: ${state.currentChapter?.id ?? "NULL"}');
      _logger.d('   state.content.id: ${state.content!.id}');

      // Calculate chapter index if available
      int? chapterIndex;
      if (state.currentChapter != null && state.content?.chapters != null) {
        chapterIndex = state.content!.chapters!
            .indexWhere((c) => c.id == state.currentChapter!.id);
      }

      // Determine chapter ID - fallback to content.id for chapter mode
      // This ensures chapterId is set even when currentChapter is null
      String? chapterId = state.currentChapter?.id;
      String? chapterTitle = state.currentChapter?.title;

      _logger.d('   Initial chapterId: $chapterId');
      _logger.d('   Initial chapterTitle: $chapterTitle');

      // If currentChapter is null but content.id looks like a chapter ID, use it
      if (chapterId == null || chapterId.isEmpty) {
        final contentId = state.content!.id;
        if (_isCrotpediaChapterId(contentId)) {
          chapterId = contentId;
          // Try to extract chapter title from content title
          // Format: "Series Title - Chapter X" or just "Chapter X"
          final title = state.content!.title;
          if (title.contains(' - ')) {
            chapterTitle = title.split(' - ').last;
          } else {
            chapterTitle = title;
          }
          _logger.d('📝 Using content.id as chapterId: $chapterId');
        }
      }

      // Additional fallback: if chapterId is still empty but we have chapterTitle
      // that looks like a chapter ID (contains "-chapter-"), use it
      if ((chapterId == null || chapterId.isEmpty) &&
          chapterTitle != null &&
          chapterTitle.isNotEmpty &&
          chapterTitle.contains('-chapter-')) {
        chapterId = chapterTitle;
        _logger.d('📝 Using chapterTitle as chapterId: $chapterId');
      }

      _logger.d('   Final chapterId: $chapterId');
      _logger.d('   _parentContent.id: ${_parentContent?.id ?? "NULL"}');

      // NEW LOGIC:
      // - If chapter mode: contentId = chapter.id, parentId = series.id
      // - If non-chapter mode: contentId = content.id, parentId = null
      final bool isChapterMode = chapterId != null && chapterId.isNotEmpty;
      final String historyContentId;
      final String? historyParentId;

      if (isChapterMode) {
        // Chapter mode: use chapter.id as contentId
        historyContentId = chapterId;
        // parentId is the series ID
        historyParentId = _parentContent?.id;
        // _logger.d(
        //     '📚 CHAPTER MODE: contentId=$historyContentId, parentId=$historyParentId');
      } else {
        // Non-chapter mode: use content.id as contentId
        historyContentId = state.content!.id;
        historyParentId = null;
        _logger.d('📖 NON-CHAPTER MODE: contentId=$historyContentId');
      }

      final params = AddToHistoryParams.fromString(
        historyContentId,
        state.currentPage ?? 1,
        state.content!.pageCount,
        timeSpent: state.readingTimer ?? Duration.zero,
        title: state.content!.title,
        coverUrl: state.content!.coverUrl,
        sourceId: state.content!.sourceId,
        parentId: historyParentId,
        chapterId: chapterId,
        chapterIndex: chapterIndex,
        chapterTitle: chapterTitle,
      );

      _logger.d(
          '📤 Saving history with contentId: ${params.contentId.value}, parentId: ${params.parentId}, chapterId: ${params.chapterId}');
      if (params.page <= params.totalPages) {
        await addToHistoryUseCase(params);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to save reading progress to history',
          error: e, stackTrace: stackTrace);
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
      // if (position.currentPage <= position.totalPages) {
      await readerRepository.saveReaderPosition(position);
      // }
      // _logger.i(
      //     '✅ Saved reader position: ${state.content!.id} at page ${state.currentPage}/${state.content!.pageCount}');
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
    _logger.i('start reading timer');
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
    _logger.i('end reading timer');
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

  /// Check if contentId is a Crotpedia chapter ID
  /// Crotpedia chapter IDs typically contain "chapter" in the slug
  /// e.g., "manga-name-chapter-1-bahasa-indonesia"
  bool _isCrotpediaChapterId(String contentId) {
    // Nhentai IDs are pure numbers (e.g., "123456")
    // Crotpedia chapter IDs are slugs with "chapter" keyword or multiple dashes

    // If it's purely numeric, it's definitely not a Crotpedia chapter
    if (RegExp(r'^\d+$').hasMatch(contentId)) {
      return false;
    }

    // If it contains "chapter" or "ch-", it's likely a Crotpedia chapter
    if (contentId.contains('chapter') || contentId.contains('ch-')) {
      return true;
    }

    // Additional check: Crotpedia slugs typically have multiple dashes
    // and contain language indicators like "bahasa-indonesia"
    final dashCount = '-'.allMatches(contentId).length;
    return dashCount >= 3; // e.g., "series-name-chapter-1" has 3 dashes minimum
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
