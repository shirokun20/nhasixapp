import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import '../../../core/constants/colors_const.dart' show KuronColors;
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/text_style_const.dart';
import '../../../core/config/remote_config_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/image_metadata.dart';
import '../../../core/routing/reader_route_extra.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../core/utils/reader_image_repair_utils.dart';
import '../../../domain/entities/reader_settings_entity.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import '../../../services/local_image_preloader.dart';
import '../../cubits/reader/reader_cubit.dart';
import '../../utils/chapter_language_presenter.dart';
// import '../../cubits/reader/reader_state.dart';
import '../../widgets/progress_indicator_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/extended_image_reader_widget.dart';
import 'chapter_open_overlay.dart';
import 'end_of_chapter_overlay.dart';

/// Simple reader screen for reading manga/doujinshi content
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.contentId,
    this.initialPage = 1,
    this.forceStartFromBeginning = false,
    this.preloadedContent,
    this.imageMetadata,
    this.chapterData,
    this.parentContent, // Parent series for chapter mode
    this.allChapters, // All chapters for navigation
    this.currentChapter, // Current chapter being read
    this.activeChapterLanguage,
  });

  final String contentId;
  final int initialPage;
  final bool forceStartFromBeginning;
  final Content? preloadedContent;
  final List<ImageMetadata>? imageMetadata;
  final ChapterData? chapterData;
  final Content? parentContent; // Parent series
  final List<Chapter>? allChapters; // All chapters
  final Chapter? currentChapter; // Current chapter
  final String? activeChapterLanguage;

  @visibleForTesting
  static bool shouldSkipHeavyImageAutoSwitchForSource(String? sourceId) {
    final normalized = (sourceId ?? '').toLowerCase();
    return normalized == 'manga18.club';
  }

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  Logger get _logger => getIt<Logger>();

  late PageController _pageController;
  late PageController _verticalPageController;
  late ScrollController _scrollController;
  late ReaderCubit _readerCubit;

  // Debouncing for scroll updates
  int _lastReportedPage = 1;
  int _lastSavedPage = 0; // Track last saved page to prevent backward saves
  String? _lastTrackedProgressKey;

  // 🐛 FIX: Cache rendered image heights to prevent scroll jumping on scroll-up
  // When items are rebuilt after disposal, the loading placeholder must match
  // the original image height to keep the scroll offset stable.
  final Map<int, double> _cachedImageHeights = {};

  // Prefetch control
  final Set<int> _prefetchedPages = <int>{};
  static const int _prefetchCount = 3;
  static const int _prefetchBackCount = 1;
  // Throttle: track last two page-change timestamps for fast-scroll detection
  DateTime _lastPageChangedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _prevPageChangedAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Chapter open overlay: shown once per reader session
  bool _chapterOverlayShown = false;

  // 🎬 Heavy-image guard: content IDs where continuous-scroll is disabled.
  // Static so the lock persists across reader navigations in the same session.
  static final Set<String> _autoSwitchedContentIds = <String>{};

  // Throttle expensive continuous-scroll computations.
  // 🔥 THERMAL: Increased from 90ms → 150ms → 200ms to reduce frame pressure
  // More throttling = better GPU utilization, less buffer starvation
  static const Duration _scrollProcessInterval = DesignTokens.durationPageTurn;
  DateTime _lastScrollProcessAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Debounce mechanism to prevent onPageChanged loops
  bool _isProgrammaticAnimation = false;

  // 🚀 OPTIMIZATION: Throttle save to DB and UI toggle
  Timer? _saveDebounceTimer;
  Timer? _pageUpdateTimer; // Separate timer for page updates
  Timer? _uiToggleDebounceTimer;
  bool _lastUIVisibleState = true;

  // 🎯 Tap-to-toggle detection for continuous scroll
  Offset _tapDownPosition = Offset.zero;
  DateTime _tapDownTime = DateTime.now();
  Offset? _miniChromeToggleOffset;

  // 🎯 Floating page indicator (ValueNotifiers avoid full-screen rebuild)
  final ValueNotifier<int> _visiblePageNotifier = ValueNotifier<int>(1);
  final ValueNotifier<bool> _scrollingNotifier = ValueNotifier<bool>(false);
  Timer? _scrollIndicatorTimer;

  // Slider footer previews the destination locally while dragging and only
  // commits navigation once on release, preventing overlapping PageView syncs.
  double? _sliderPreviewValue;

  // 🚀 OPTIMIZATION: Preload content before BlocProvider setup
  Content? _preloadedContent;
  List<ImageMetadata>? _preloadedImageMetadata;
  ChapterData? _preloadedChapterData;
  Content? _preloadedParentContent; // Parent series for chapters
  List<Chapter>? _preloadedAllChapters; // All chapters for navigation
  Chapter? _preloadedCurrentChapter; // Current chapter
  String? _preloadedActiveChapterLanguage;
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _verticalPageController =
        PageController(initialPage: widget.initialPage - 1);

    // 🐛 CRITICAL FIX: Set flag BEFORE ScrollController to prevent false saves
    // When ScrollController is created with initialScrollOffset, it triggers
    // scroll events immediately which can cause false page saves
    if (widget.initialPage > 1) {
      _isProgrammaticAnimation = true;
      _logger.i(
          '🔒 Locked programmatic animation flag for initial scroll to page ${widget.initialPage}');
    }

    // 🚀 OPTIMIZATION: Calculate initial scroll offset for continuous scroll
    // This allows starting from a specific page while keeping all pages available
    final screenHeight = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.height /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final estimatedItemHeight = screenHeight * 0.9; // Approximate image height
    final initialScrollOffset = (widget.initialPage - 1) * estimatedItemHeight;

    _scrollController = ScrollController(
      initialScrollOffset: initialScrollOffset > 0 ? initialScrollOffset : 0,
    );
    _readerCubit = getIt<ReaderCubit>();

    // 🚀 OPTIMIZATION: Initialize route extra synchronously before build
    _initializeFromRouteExtraSync();

    // Defer GoRouterState access until after widget is mounted (for any additional processing)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start preloading after route extra is processed
      _startPreloading();

      // 🚀 FIX: Unlock flag after content settles (1.5s for images to load)
      if (widget.initialPage > 1) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _isProgrammaticAnimation = false;
            _logger.i(
                '🔓 Unlocked programmatic animation flag - user can scroll freely');
          }
        });
      }
    });

    // 🚀 REMOVED: _onScrollChanged listener (causes duplicate saves)
    // We now use ONLY NotificationListener for more accurate tracking
    // _scrollController.addListener(_onScrollChanged);

    // 🚀 OPTIMIZATION: Start preloading content immediately - MOVED TO POST FRAME CALLBACK
    // _startPreloading();
  }

  /// Initialize preloaded content from route extra synchronously (before build)
  void _initializeFromRouteExtraSync() {
    // This is called in initState, but we can't access context yet
    // The actual initialization will happen in build() or postFrameCallback
  }

  /// Initialize preloaded content from route extra (called from build or postFrameCallback)
  void _initializeFromRouteExtra() {
    if (_preloadedContent != null) return; // Already initialized

    // Get preloaded content and metadata from route extra if available
    final rawRouteExtra = GoRouterState.of(context).extra;
    final routeExtra = asReaderRouteExtra(rawRouteExtra);

    // 🔍 DEBUG LOGGING - What did we receive from router?
    _logger.i('📥 ReaderScreen._initializeFromRouteExtra - Received:');
    _logger.i('  routeExtra type: ${rawRouteExtra.runtimeType}');

    if (routeExtra != null) {
      _logger.i('  Map keys: ${routeExtra.keys.toList()}');

      final parsedContent = readReaderContent(routeExtra['content']);
      if (parsedContent != null && widget.preloadedContent == null) {
        _preloadedContent = parsedContent;
        _logger.i('  ✓ content: ${_preloadedContent?.title}');
      }

      final parsedImageMetadata = readReaderImageMetadata(
        routeExtra['imageMetadata'],
      );
      if (parsedImageMetadata != null && widget.imageMetadata == null) {
        _preloadedImageMetadata = parsedImageMetadata;
        Logger()
            .i('  ✓ imageMetadata: ${_preloadedImageMetadata?.length} items');
      }

      final parsedChapterData =
          readReaderChapterData(routeExtra['chapterData']);
      if (parsedChapterData != null && widget.chapterData == null) {
        _preloadedChapterData = parsedChapterData;
        _logger.i(
            '  ✓ chapterData: prev=${_preloadedChapterData?.prevChapterId}, next=${_preloadedChapterData?.nextChapterId}');
      }

      final parsedParentContent =
          readReaderContent(routeExtra['parentContent']);
      if (parsedParentContent != null && widget.parentContent == null) {
        _preloadedParentContent = parsedParentContent;
        _logger.i('  ✓ parentContent: ${_preloadedParentContent?.title}');
      }

      final parsedAllChapters = readReaderChapters(routeExtra['allChapters']);
      if (parsedAllChapters != null && widget.allChapters == null) {
        _preloadedAllChapters = parsedAllChapters;
        Logger()
            .i('  ✓ allChapters: ${_preloadedAllChapters?.length} chapters');
        if (_preloadedAllChapters != null &&
            _preloadedAllChapters!.isNotEmpty) {
          _logger.i('    First: ${_preloadedAllChapters!.first.title}');
          _logger.i('    Last: ${_preloadedAllChapters!.last.title}');
        }
      }

      final parsedCurrentChapter =
          readReaderChapter(routeExtra['currentChapter']);
      if (parsedCurrentChapter != null && widget.currentChapter == null) {
        _preloadedCurrentChapter = parsedCurrentChapter;
        _logger.i('  ✓ currentChapter: ${_preloadedCurrentChapter?.title}');
      }

      final parsedActiveChapterLanguage = readReaderActiveChapterLanguage(
        routeExtra['activeChapterLanguage'],
      );
      if (parsedActiveChapterLanguage != null &&
          widget.activeChapterLanguage == null) {
        _preloadedActiveChapterLanguage = parsedActiveChapterLanguage;
      }
    } else if (widget.preloadedContent == null) {
      // Fallback for direct Content object (backward compatibility)
      final parsedDirectContent = readReaderContent(rawRouteExtra);
      if (parsedDirectContent != null) {
        _preloadedContent = parsedDirectContent;
        _logger.i('  ✓ Direct Content: ${_preloadedContent?.title}');
      }
    }
  }

  /// 🚀 OPTIMIZATION: Preload content to reduce initial loading time
  Future<void> _startPreloading() async {
    // If we already have preloaded content from route extra, skip preloading
    if (_preloadedContent != null) {
      return;
    }

    if (_isPreloading) return;

    _isPreloading = true;
    try {
      // Quick offline check first
      final offlineManager = getIt<OfflineContentManager>();
      final isOfflineAvailable =
          await offlineManager.isContentAvailableOffline(widget.contentId);

      if (isOfflineAvailable) {
        // Preload offline content
        _preloadedContent =
            await offlineManager.createOfflineContent(widget.contentId);
      }
    } catch (e) {
      // Ignore preload errors, will fallback to normal loading
      _logger.d('Reader preload failed: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// 🚀 DEPRECATED: Old scroll handler - replaced by NotificationListener
  /// Keeping code for reference, but disabled to prevent duplicate saves
  /*
  void _onScrollChanged() {
    final state = _readerCubit.state;
    if (state.readingMode == ReadingMode.continuousScroll &&
        state.content != null) {
      // 🚀 SIMPLE: Only prefetch images, no page tracking or state updates
      // Calculate visible page for prefetching only
      final screenHeight = MediaQuery.of(context).size.height;
      final approximateItemHeight =
          screenHeight * 0.9; // Slightly larger for better detection
      final visiblePage =
          (_scrollController.offset / approximateItemHeight).round() + 1;
      final clampedPage = visiblePage.clamp(1, state.content!.pageCount);

      // 🚀 FIX: Update ReaderCubit state so progress bar moves (even if estimation is rough)
      if (clampedPage != _lastReportedPage) {
        _lastReportedPage = clampedPage;

        if (!_isProgrammaticAnimation) {
          _readerCubit.updateCurrentPageFromSwipe(clampedPage);
        }

        _prefetchImages(
            clampedPage, state.content!.imageUrls, state.imageMetadata);
      }

      // 🐛 FIX: Check if user truly reached bottom in continuous scroll
      // Mark as complete only when scroll position is at bottom
      final scrollPosition = _scrollController.position;
      if (scrollPosition.hasPixels) {
        final isAtBottom = scrollPosition.pixels >=
            scrollPosition.maxScrollExtent - 100; // 100px threshold

        if (isAtBottom) {
          // User reached bottom -> save with last page to mark complete
          _readerCubit.updateCurrentPageFromSwipe(state.content!.pageCount);
        }
      }

      // ✨ Auto-hide UI on scroll down
      final scrollDirection = _scrollController.position.userScrollDirection;
      if (scrollDirection == ScrollDirection.reverse &&
          (state.showUI ?? false)) {
        _readerCubit.hideUI();
      }
      // ✨ Auto-show UI on scroll up
      else if (scrollDirection == ScrollDirection.forward &&
          !(state.showUI ?? false)) {
        _readerCubit.showUI();
      }
    }
  }
  */

  /// 🚀 NEW: Handle scroll notification with accurate metrics
  void _onScrollNotification(
      ScrollUpdateNotification notification, ReaderState state) {
    if (state.content == null) return;

    final progressKey =
        '${state.content?.id ?? ''}::${state.currentChapter?.id ?? ''}';
    if (_lastTrackedProgressKey != progressKey) {
      _lastTrackedProgressKey = progressKey;
      _lastSavedPage = 0;
      _lastReportedPage = 0;
    }

    // 🐛 CRITICAL: Skip all processing during programmatic scroll
    // This prevents false page saves during initial positioning
    if (_isProgrammaticAnimation) {
      _logger.t(
          '⏭️  Skipping scroll event (programmatic): ${notification.metrics.pixels.toStringAsFixed(0)}px');
      return;
    }

    // Continuous scroll fires per-pixel updates. Throttle heavy page
    // estimation/prefetch logic to reduce main-thread pressure.
    final now = DateTime.now();
    if (now.difference(_lastScrollProcessAt) < _scrollProcessInterval) {
      return;
    }
    _lastScrollProcessAt = now;

    final metrics = notification.metrics;
    final totalPages = state.content!.pageCount;
    final screenHeight = MediaQuery.of(context).size.height;
    final estimatedPage = _estimateContinuousVisiblePage(
      metrics: metrics,
      totalPages: totalPages,
      screenHeight: screenHeight,
    );

    // Update current page for progress bar with debounce
    if (estimatedPage != _lastReportedPage) {
      _lastReportedPage = estimatedPage;

      // 🎯 Update floating page indicator (no setState needed — ValueNotifier)
      _visiblePageNotifier.value = estimatedPage;

      // 🚀 OPTIMIZATION: Debounce page updates to reduce DB writes
      _debouncePageUpdate(estimatedPage, state);

      // Prefetch next images
      _prefetchImages(
        estimatedPage,
        state.content!.imageUrls,
        state.imageMetadata,
        sourceId: state.content?.sourceId,
      );
    }

    // 🎯 Show floating page indicator while scrolling, auto-hide after 2s
    _scrollingNotifier.value = true;
    _scrollIndicatorTimer?.cancel();
    _scrollIndicatorTimer = Timer(const Duration(seconds: 2), () {
      _scrollingNotifier.value = false;
    });

    // 🐛 FIX: Check if user truly reached bottom using scroll metrics
    // More reliable than pixel threshold
    final isAtBottom =
        metrics.pixels >= metrics.maxScrollExtent - 50; // 50px threshold

    if (isAtBottom) {
      // User reached bottom -> save to DB with debounce to avoid spam
      _debounceSaveHistory(state, totalPages);
    }

    // ✨ Auto-hide/show UI based on scroll direction with debounce
    if (notification.scrollDelta != null && notification.scrollDelta! > 5) {
      // Scrolling down (threshold 5px to avoid micro-scrolls)
      _debounceUIToggle(false, state);
    } else if (notification.scrollDelta != null &&
        notification.scrollDelta! < -5) {
      // Scrolling up (threshold -5px to avoid micro-scrolls)
      _debounceUIToggle(true, state);
    }
  }

  int _estimateContinuousVisiblePage({
    required ScrollMetrics metrics,
    required int totalPages,
    required double screenHeight,
  }) {
    if (totalPages <= 0) {
      return 1;
    }

    final viewportCenter = metrics.pixels + (metrics.viewportDimension / 2);
    final fallbackItemHeight = _resolveContinuousFallbackItemHeight(
      metrics: metrics,
      totalPages: totalPages,
      screenHeight: screenHeight,
    );

    double cumulativeHeight = 0;
    for (int page = 1; page <= totalPages; page++) {
      final itemHeight = (_cachedImageHeights[page] ?? fallbackItemHeight)
          .clamp(1.0, double.infinity)
          .toDouble();
      cumulativeHeight += itemHeight;

      if (viewportCenter < cumulativeHeight) {
        return page;
      }
    }

    return totalPages;
  }

  double _resolveContinuousFallbackItemHeight({
    required ScrollMetrics metrics,
    required int totalPages,
    required double screenHeight,
  }) {
    if (metrics.maxScrollExtent > 0) {
      final estimatedContentExtent =
          metrics.maxScrollExtent + metrics.viewportDimension;
      return (estimatedContentExtent / totalPages)
          .clamp(1.0, double.infinity)
          .toDouble();
    }

    return (screenHeight * 0.9).clamp(1.0, double.infinity).toDouble();
  }

  double _resolveContinuousItemHeight(int pageNumber, double screenHeight) {
    final cachedHeight = _cachedImageHeights[pageNumber];
    if (cachedHeight != null && cachedHeight > 0) {
      return cachedHeight;
    }

    for (final candidatePage in <int>[
      pageNumber - 1,
      pageNumber + 1,
      pageNumber - 2,
      pageNumber + 2,
    ]) {
      final candidateHeight = _cachedImageHeights[candidatePage];
      if (candidateHeight != null && candidateHeight > 0) {
        return candidateHeight;
      }
    }

    if (_cachedImageHeights.isNotEmpty) {
      return _cachedImageHeights.values.last;
    }

    return (screenHeight * 0.9).clamp(1.0, double.infinity).toDouble();
  }

  /// 🚀 OPTIMIZATION: Debounce save to DB to prevent spam
  void _debounceSaveHistory(ReaderState state, int page) {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(DesignTokens.durationSlow, () {
      // Only save if still at bottom after 500ms
      if (state.readingMode == ReadingMode.continuousScroll) {
        _readerCubit.updateCurrentPageSilent(page);
      } else {
        _readerCubit.updateCurrentPageFromSwipe(page);
      }
    });
  }

  /// 🚀 OPTIMIZATION: Debounce page updates to reduce DB spam
  void _debouncePageUpdate(int page, ReaderState state) {
    // 🐛 FIX: Only save if progress moves forward (user reads more)
    // Don't save when scrolling back up to re-read
    if (page <= _lastSavedPage) {
      return; // Skip saving if scrolling backwards
    }

    final isHeavySource = _isHeavyPrefetchSource(state.content?.sourceId);
    final isTinyAdvance = page - _lastSavedPage < 2;
    if (isHeavySource && isTinyAdvance) {
      return;
    }

    _pageUpdateTimer?.cancel();
    _pageUpdateTimer = Timer(
      Duration(milliseconds: isHeavySource ? 1400 : 800),
      () {
        // Save page progress after user stops scrolling for 800ms
        // This prevents DB spam when user scrolls up/down repeatedly
        _lastSavedPage = page; // Update last saved page
        if (state.readingMode == ReadingMode.continuousScroll) {
          _readerCubit.updateCurrentPageSilent(page);
        } else {
          _readerCubit.updateCurrentPageFromSwipe(page);
        }
      },
    );
  }

  /// 🚀 OPTIMIZATION: Debounce UI toggle to prevent flickering
  void _debounceUIToggle(bool shouldShow, ReaderState state) {
    // Only toggle if state actually changed
    if (_lastUIVisibleState == shouldShow) return;

    _uiToggleDebounceTimer?.cancel();
    _uiToggleDebounceTimer = Timer(DesignTokens.durationFast, () {
      _lastUIVisibleState = shouldShow;
      if (shouldShow && !(state.showUI ?? false)) {
        _readerCubit.showUI();
      } else if (!shouldShow && (state.showUI ?? false)) {
        _readerCubit.hideUI();
      }
    });
  }

  /// Called when an [ExtendedImageReaderWidget] at an early page detects a
  /// heavy animated WebP (\u2265 2 MB) while in continuous-scroll mode.
  ///
  /// Automatically disables continuous-scroll and switches to single-page
  /// mode so only one animation is rendered at a time, eliminating
  /// concurrent-decode frame drops.
  void _onHeavyImageDetected() {
    if (!mounted) return;
    final sourceId = _readerCubit.state.content?.sourceId;
    if (ReaderScreen.shouldSkipHeavyImageAutoSwitchForSource(sourceId)) {
      return;
    }

    final contentId = widget.contentId;
    if (_autoSwitchedContentIds.contains(contentId)) return;
    _autoSwitchedContentIds.add(contentId);

    // Force to single-page mode.
    _readerCubit.changeReadingMode(
      ReadingMode.singlePage,
      persistPreference: false,
      resetWebtoonDetection: false,
    );

    // Inform user that continuous mode is disabled for this content.
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.readerContinuousDisabledHeavyImage),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _flushReaderProgressBeforeDispose();

    // 🚀 REMOVED: Old scroll listener (now using NotificationListener)
    // _scrollController.removeListener(_onScrollChanged);
    _pageController.dispose();
    _verticalPageController.dispose();
    _scrollController.dispose();

    // 🚀 OPTIMIZATION: Cancel debounce timers
    _saveDebounceTimer?.cancel();
    _pageUpdateTimer?.cancel();
    _uiToggleDebounceTimer?.cancel();
    _scrollIndicatorTimer?.cancel();
    _visiblePageNotifier.dispose();
    _scrollingNotifier.dispose();

    // 🎬 Restore system UI when leaving reader
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  void _flushReaderProgressBeforeDispose() {
    final state = _readerCubit.state;
    final content = state.content;
    if (content == null || content.pageCount <= 0) return;

    var pageToSave = state.currentPage ?? widget.initialPage;
    final visiblePage = _visiblePageNotifier.value;
    if (visiblePage > pageToSave) {
      pageToSave = visiblePage;
    }

    final validPage = pageToSave.clamp(1, content.pageCount);
    if (state.readingMode == ReadingMode.continuousScroll) {
      _readerCubit.updateCurrentPageSilent(validPage);
    } else {
      _readerCubit.updateCurrentPageFromSwipe(validPage);
    }
  }

  /// 🎬 Toggle immersive mode (hide/show status bar & navigation bar)
  void _toggleImmersiveMode(bool immersive) {
    if (immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  /// Prefetch next few images in background for smoother reading experience
  void _prefetchImages(int currentPage, List<String> imageUrls,
      List<ImageMetadata>? imageMetadata,
      {String? sourceId}) {
    if (imageUrls.isEmpty) return;

    // Throttle: skip prefetch when user is fast-scrolling (2 page changes < 300ms)
    final now = DateTime.now();
    final sinceLast = now.difference(_lastPageChangedAt);
    final sincePrev = now.difference(_prevPageChangedAt);
    _prevPageChangedAt = _lastPageChangedAt;
    _lastPageChangedAt = now;
    if (sinceLast.inMilliseconds < 300 && sincePrev.inMilliseconds < 600) {
      // Two rapid page changes detected — skip this cycle
      return;
    }

    // HentaiNexus: DISABLE prefetch completely (GPU saturation issue)
    if (_isHeavyPrefetchSource(sourceId)) {
      return;
    }

    final prefetchHeaders = sourceId == null
        ? null
        : getIt<ContentSourceRegistry>()
            .getSource(sourceId)
            ?.getImageDownloadHeaders(
              imageUrl:
                  imageUrls[(currentPage - 1).clamp(0, imageUrls.length - 1)],
            );

    // Backward prefetch: 1 page behind
    for (int i = 1; i <= _prefetchBackCount; i++) {
      final targetPage = currentPage - i;
      if (targetPage >= 1 && !_prefetchedPages.contains(targetPage)) {
        _prefetchedPages.add(targetPage);
        final imageUrl = imageUrls[targetPage - 1];
        if (imageUrl.startsWith('http')) {
          LocalImagePreloader.downloadAndCacheImage(
            imageUrl,
            widget.contentId,
            targetPage,
            headers: prefetchHeaders,
          ).catchError((_) {
            _prefetchedPages.remove(targetPage);
            return '';
          });
        }
      }
    }

    // Forward prefetch: _prefetchCount pages ahead
    for (int i = 1; i <= _prefetchCount; i++) {
      final targetPage = currentPage + i;

      // Check bounds and avoid duplicate prefetching
      if (targetPage <= imageUrls.length &&
          !_prefetchedPages.contains(targetPage)) {
        _prefetchedPages.add(targetPage);

        final imageUrl = imageUrls[targetPage - 1]; // Convert to 0-based index

        // EHentai uses /s/... reader pages that are resolved to real image
        // URLs lazily per visible page. Skip image prefetch on reader pages.
        if (_isEhentaiReaderPageUrl(imageUrl, sourceId)) {
          continue;
        }

        // 🚀 OPTIMIZATION: Use metadata lookup instead of URL validation for performance
        bool isValid = true;
        if (imageMetadata != null && imageMetadata.isNotEmpty) {
          // Find metadata for this page
          final metadata = imageMetadata.where((m) {
            return m.pageNumber == targetPage;
          }).firstOrNull;
          if (metadata != null) {
            // Validate using metadata - much faster than URL parsing
            isValid = metadata.imageUrl == imageUrl;
            if (!isValid) {
              _logger.d(
                  '⚠️ METADATA MISMATCH: Page $targetPage metadata URL != actual URL');
              _logger.d('   Metadata URL: ${metadata.imageUrl}');
              _logger.d('   Actual URL: $imageUrl');
            }
          } else {
            // Fallback to URL validation if no metadata found
            // We TRUST the URL list from the source. Removing brittle filename parsing validation.
            // checks that caused false positives (e.g. 0-indexed filenames).
            isValid = true;
          }
        } else {
          // No metadata available. Trust the URL list order.
          isValid = true;
        }

        if (!isValid) {
          // Skip prefetch to prevent wrong caching
          _prefetchedPages.remove(targetPage); // Allow retry later
          return;
        }

        // Skip prefetching if the URL is already a local file path
        if (!imageUrl.startsWith('http') &&
            (imageUrl.startsWith('/') || imageUrl.startsWith('file://'))) {
          // Already local, no need to prefetch
          return;
        }

        // Prefetch in background (non-blocking) - only if validation passes
        LocalImagePreloader.downloadAndCacheImage(
          imageUrl,
          widget.contentId,
          targetPage,
          headers: prefetchHeaders,
        ).then((_) {
          if (mounted) {
            // Log success with validation status
            final status = isValid ? '✅' : '❓';
            _logger.d(
                '📥 $status Prefetched page $targetPage (metadata validated: $isValid)');
          }
        }).catchError((error) {
          // Remove from prefetched set if failed, so it can be retried
          _prefetchedPages.remove(targetPage);
          _logger.d('❌ Failed to prefetch page $targetPage: $error');
        });
      }
    }
  }

  /// Evict image providers for pages that are far from the current reading position.
  ///
  /// Pages outside the window [currentPage - 4, currentPage + 4] are evicted
  /// from the Flutter image cache to reduce memory pressure during long chapters.
  /// Eviction is skipped for offline content (page images are already on disk).
  /// All evictions are queued after the current frame via [WidgetsBinding.instance].
  void _evictDistantPages(int currentPage, List<String> imageUrls,
      {bool isOffline = false}) {
    if (isOffline || imageUrls.isEmpty) return;

    const window = 4;
    final minKeep = (currentPage - window).clamp(1, imageUrls.length);
    final maxKeep = (currentPage + window).clamp(1, imageUrls.length);

    for (int page = 1; page <= imageUrls.length; page++) {
      if (page >= minKeep && page <= maxKeep) continue;
      final url = imageUrls[page - 1];
      if (!url.startsWith('http')) continue; // skip local paths
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NetworkImage(url).evict().catchError((_) => false);
      });
    }
  }

  bool _isEhentaiReaderPageUrl(String url, String? sourceId) {
    if (sourceId != 'ehentai') {
      return false;
    }

    final lowered = url.toLowerCase();
    return lowered.contains('/s/') &&
        (lowered.contains('e-hentai.org') || lowered.contains('exhentai.org'));
  }

  bool _isHeavyPrefetchSource(String? sourceId) {
    return sourceId == 'hentainexus';
  }

  bool _isContinuousScrollDisabledForCurrentContent() {
    return _autoSwitchedContentIds.contains(widget.contentId);
  }

  ReadingMode _getNextReadingMode(
    ReadingMode currentMode, {
    required bool disableContinuousScroll,
  }) {
    if (!disableContinuousScroll) {
      switch (currentMode) {
        case ReadingMode.singlePage:
          return ReadingMode.verticalPage;
        case ReadingMode.verticalPage:
          return ReadingMode.continuousScroll;
        case ReadingMode.continuousScroll:
          return ReadingMode.singlePage;
      }
    }

    // Continuous-scroll is locked for heavy-image content.
    switch (currentMode) {
      case ReadingMode.singlePage:
        return ReadingMode.verticalPage;
      case ReadingMode.verticalPage:
        return ReadingMode.singlePage;
      case ReadingMode.continuousScroll:
        return ReadingMode.singlePage;
    }
  }

  void _syncControllersWithState(ReaderState state) {
    // 🚀 OPTIMIZATION: Skip sync for continuous scroll - let user scroll freely
    // Prevents scroll position reset when readingTimer updates state every second
    if (state.readingMode == ReadingMode.continuousScroll) {
      return;
    }

    final currentPage = state.currentPage ?? 1;
    final targetPageIndex = currentPage - 1;

    // Sync PageController for horizontal single page mode
    if (state.readingMode == ReadingMode.singlePage) {
      if (_pageController.hasClients) {
        final currentPageControllerIndex = _pageController.page?.round();

        // Early return if already in sync - prevents infinite loop
        if (currentPageControllerIndex == targetPageIndex) {
          return;
        }

        final distance =
            ((currentPageControllerIndex ?? 0) - targetPageIndex).abs();

        if (distance > 5) {
          // Use immediate jump for large distances to avoid animation interruption
          _logger.d(
              '🔄 SYNC: Jumping PageController from $currentPageControllerIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _pageController.jumpToPage(targetPageIndex);
          _isProgrammaticAnimation = false;
        } else {
          // Use smooth animation for small distances
          _logger.d(
              '🔄 SYNC: Animating PageController from $currentPageControllerIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _pageController
              .animateToPage(
            targetPageIndex,
            duration: DesignTokens.durationPageTurn,
            curve: Curves.easeOutCubic,
          )
              .then((_) {
            _isProgrammaticAnimation = false;
          });
        }
      }
    }

    // Sync PageController for vertical page mode
    else if (state.readingMode == ReadingMode.verticalPage) {
      if (_verticalPageController.hasClients) {
        final currentVerticalIndex = _verticalPageController.page?.round();

        // Early return if already in sync - prevents infinite loop
        if (currentVerticalIndex == targetPageIndex) {
          return;
        }

        final distance = ((currentVerticalIndex ?? 0) - targetPageIndex).abs();

        if (distance > 5) {
          // Use immediate jump for large distances to avoid animation interruption
          _logger.d(
              '🔄 SYNC: Jumping VerticalPageController from $currentVerticalIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _verticalPageController.jumpToPage(targetPageIndex);
          _isProgrammaticAnimation = false;
        } else {
          // Use smooth animation for small distances
          _logger.d(
              '🔄 SYNC: Animating VerticalPageController from $currentVerticalIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _verticalPageController
              .animateToPage(
            targetPageIndex,
            duration: DesignTokens.durationNormal,
            curve: Curves.easeInOut,
          )
              .then((_) {
            _isProgrammaticAnimation = false;
          });
        }
      }
    }

    // Sync ScrollController for continuous scroll mode
    else if (state.readingMode == ReadingMode.continuousScroll) {
      if (_scrollController.hasClients && state.content != null) {
        // Calculate approximate scroll position based on current page
        final screenHeight = MediaQuery.of(context).size.height;
        final approximateItemHeight =
            screenHeight * 0.9; // Match with scroll detection
        final targetScrollOffset = (currentPage - 1) * approximateItemHeight;

        if ((_scrollController.offset - targetScrollOffset).abs() >
            approximateItemHeight * 0.5) {
          _scrollController.animateTo(
            targetScrollOffset,
            duration: DesignTokens.durationNormal,
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize preloaded content from route extra if not already done
    _initializeFromRouteExtra();

    return BlocProvider<ReaderCubit>(
      create: (context) {
        // 🚀 OPTIMIZATION: Always pass preloaded content (from widget or route extra)
        final effectivePreloadedContent =
            _preloadedContent ?? widget.preloadedContent;
        final effectiveImageMetadata =
            _preloadedImageMetadata ?? widget.imageMetadata;
        final effectiveChapterData =
            _preloadedChapterData ?? widget.chapterData;
        final effectiveParentContent =
            _preloadedParentContent ?? widget.parentContent;
        final effectiveAllChapters =
            _preloadedAllChapters ?? widget.allChapters;
        final effectiveCurrentChapter =
            _preloadedCurrentChapter ?? widget.currentChapter;
        // Always call loadContent with preloaded content if available
        return _readerCubit
          ..loadContent(
            widget.contentId,
            initialPage: widget.initialPage,
            forceStartFromBeginning: widget.forceStartFromBeginning,
            preloadedContent: effectivePreloadedContent,
            imageMetadata: effectiveImageMetadata,
            chapterData: effectiveChapterData,
            parentContent: effectiveParentContent, // Parent series
            allChapters: effectiveAllChapters, // All chapters
            currentChapter: effectiveCurrentChapter, // Current chapter
          );
      },
      child: BlocListener<ReaderCubit, ReaderState>(
        listenWhen: (previous, current) {
          final prevContentId = previous.content?.id;
          final currContentId = current.content?.id;
          final prevImageCount = previous.content?.imageUrls.length ?? 0;
          final currImageCount = current.content?.imageUrls.length ?? 0;

          // Ignore timer-only or unrelated state updates.
          return previous.currentPage != current.currentPage ||
              previous.readingMode != current.readingMode ||
              previous.showUI != current.showUI ||
              prevContentId != currContentId ||
              prevImageCount != currImageCount;
        },
        listener: (context, state) {
          if (_isContinuousScrollDisabledForCurrentContent() &&
              state.readingMode == ReadingMode.continuousScroll) {
            _readerCubit.changeReadingMode(
              ReadingMode.singlePage,
              persistPreference: false,
              resetWebtoonDetection: false,
            );
            return;
          }

          _syncControllersWithState(state);

          // 🎬 Toggle immersive mode based on UI visibility
          _toggleImmersiveMode(!(state.showUI ?? false));

          // Prefetch only when listener-relevant states change.
          if (state.content != null && state.content!.imageUrls.isNotEmpty) {
            final currentPage = state.currentPage ?? widget.initialPage;
            _prefetchImages(
              currentPage,
              state.content!.imageUrls,
              state.imageMetadata,
              sourceId: state.content?.sourceId,
            );
          }
        },
        child: BlocBuilder<ReaderCubit, ReaderState>(
          buildWhen: (previous, current) {
            final prevContentId = previous.content?.id;
            final currContentId = current.content?.id;
            final prevImageCount = previous.content?.imageUrls.length ?? 0;
            final currImageCount = current.content?.imageUrls.length ?? 0;

            final onlyCurrentPageChanged =
                previous.currentPage != current.currentPage &&
                    previous.runtimeType == current.runtimeType &&
                    prevContentId == currContentId &&
                    prevImageCount == currImageCount &&
                    previous.showUI == current.showUI &&
                    previous.readingMode == current.readingMode &&
                    previous.enableZoom == current.enableZoom &&
                    previous.keepScreenOn == current.keepScreenOn &&
                    previous.isOfflineMode == current.isOfflineMode;

            final isContinuousMode =
                current.readingMode == ReadingMode.continuousScroll;

            if (isContinuousMode && onlyCurrentPageChanged) {
              return false;
            }

            // Prevent full-screen rebuild every second from readingTimer.
            return previous.runtimeType != current.runtimeType ||
                prevContentId != currContentId ||
                prevImageCount != currImageCount ||
                previous.currentPage != current.currentPage ||
                previous.showUI != current.showUI ||
                previous.readingMode != current.readingMode ||
                previous.enableZoom != current.enableZoom ||
                previous.keepScreenOn != current.keepScreenOn ||
                previous.isOfflineMode != current.isOfflineMode;
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 50 || constraints.maxHeight < 50) {
                    return const SizedBox.shrink();
                  }
                  return _buildBody(state);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ReaderState state) {
    if (state is ReaderLoading) {
      return Center(
        child: AppProgressIndicator(
          message: AppLocalizations.of(context)?.loadingContent ??
              AppLocalizations.of(context)!.loadingContent,
        ),
      );
    }

    if (state is ReaderError) {
      return Center(
        child: AppErrorWidget(
          title: AppLocalizations.of(context)!.loadingError,
          message: state.message ?? '',
          onRetry: () => _readerCubit.loadContent(
            widget.contentId,
            initialPage: widget.initialPage,
            forceStartFromBeginning: widget.forceStartFromBeginning,
            preloadedContent: widget.preloadedContent,
            imageMetadata: widget.imageMetadata,
            chapterData: widget.chapterData,
            parentContent: widget.parentContent, // Parent series
            allChapters: widget.allChapters, // All chapters
            currentChapter: widget.currentChapter, // Current chapter
          ),
        ),
      );
    }
    return _buildReader(state);
  }

  Widget _buildReader(ReaderState state) {
    // Show chapter open overlay once on first content load
    final showOverlay = !_chapterOverlayShown && (state.content != null);

    return Stack(
      children: [
        // Main reader content
        _buildReaderContent(state),

        // 🎬 Animated UI overlay (always in tree for smooth transitions)
        _buildAnimatedUIOverlay(state),

        _buildMiniChromeToggle(state),

        // 🎯 Floating page indicator for continuous scroll
        if (state.readingMode == ReadingMode.continuousScroll)
          _buildFloatingPageIndicator(state),

        // 📖 Chapter open overlay (auto-dismiss, shown once per session)
        if (showOverlay)
          ChapterOpenOverlay(
            title: state.content!.getDisplayTitle(),
            totalPages: state.content!.pageCount,
            onDismiss: () {
              if (mounted) setState(() => _chapterOverlayShown = true);
            },
          ),
      ],
    );
  }

  Widget _buildReaderContent(ReaderState state) {
    final showNav = _shouldShowNavigationItem(state);

    final content = switch (state.readingMode ?? ReadingMode.singlePage) {
      ReadingMode.singlePage =>
        _buildSinglePageReader(state, showNavigation: showNav),
      ReadingMode.verticalPage =>
        _buildVerticalPageReader(state, showNavigation: showNav),
      ReadingMode.continuousScroll =>
        _buildContinuousReader(state, showNavigation: showNav),
    };

    if ((state.readingMode ?? ReadingMode.singlePage) ==
        ReadingMode.continuousScroll) {
      return content;
    }

    return _buildPaginatedTapListener(state, child: content);
  }

  bool _shouldShowNavigationItem(ReaderState state) {
    if (state.isOfflineMode ?? false) {
      _logger.d('❌ Navigation page disabled: Offline mode');
      return false;
    }
    final hasContent =
        state.content != null && (state.content!.imageUrls.isNotEmpty);
    return hasContent;
  }

  /// Returns true if the tap at [tapX] (horizontal) should navigate to the
  /// next page, respecting the current [tapDirection] setting.
  bool _isNextTap(double tapX, double screenWidth, TapDirection tapDirection) {
    final isRightSide = tapX > screenWidth * 0.7;
    return tapDirection == TapDirection.inverted ? !isRightSide : isRightSide;
  }

  /// Returns true if the tap at [tapX] (horizontal) should navigate to the
  /// previous page, respecting the current [tapDirection] setting.
  bool _isPrevTap(double tapX, double screenWidth, TapDirection tapDirection) {
    final isLeftSide = tapX < screenWidth * 0.3;
    return tapDirection == TapDirection.inverted ? !isLeftSide : isLeftSide;
  }

  Widget _buildPaginatedTapListener(ReaderState state,
      {required Widget child}) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _tapDownPosition = event.position;
        _tapDownTime = DateTime.now();
      },
      onPointerUp: (event) {
        final distance = (event.position - _tapDownPosition).distance;
        final duration = DateTime.now().difference(_tapDownTime);
        if (distance >= 20 || duration.inMilliseconds >= 300) return;

        if ((state.showUI ?? false) && _isTapInsideChrome(event.position)) {
          return;
        }

        _handlePaginatedTap(event.position, state);
      },
      child: child,
    );
  }

  bool _isTapInsideChrome(Offset position) {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return position.dy <= topInset + 64 ||
        position.dy >= size.height - bottomInset - 76;
  }

  void _handlePaginatedTap(Offset position, ReaderState state) {
    final tapDir = state.tapDirection ?? TapDirection.normal;
    final mode = state.readingMode ?? ReadingMode.singlePage;

    if (mode == ReadingMode.verticalPage) {
      final screenHeight = MediaQuery.of(context).size.height;
      final isTopArea = position.dy < screenHeight * 0.3;
      final isBottomArea = position.dy > screenHeight * 0.7;
      final prevArea =
          tapDir == TapDirection.inverted ? isBottomArea : isTopArea;
      final nextArea =
          tapDir == TapDirection.inverted ? isTopArea : isBottomArea;

      if (prevArea) {
        _readerCubit.previousPage();
      } else if (nextArea) {
        _readerCubit.nextPage();
      } else {
        _readerCubit.toggleUI();
      }
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    if (_isPrevTap(position.dx, screenWidth, tapDir)) {
      _readerCubit.previousPage();
    } else if (_isNextTap(position.dx, screenWidth, tapDir)) {
      _readerCubit.nextPage();
    } else {
      _readerCubit.toggleUI();
    }
  }

  Widget _buildChapterNavigationPage(ReaderState state) {
    final bool hasPrevChapter = _readerCubit.hasPreviousChapter;
    final bool hasNextChapter = _readerCubit.hasNextChapter;
    final bool isChapterMode = state.chapterData != null ||
        state.currentChapter != null ||
        hasPrevChapter ||
        hasNextChapter;

    return EndOfChapterOverlay(
      state: state,
      isChapterMode: isChapterMode,
      onBackToDetail: () => context.pop(),
      onPreviousChapter:
          hasPrevChapter ? () => _readerCubit.loadPreviousChapter() : null,
      onNextChapter:
          hasNextChapter ? () => _readerCubit.loadNextChapter() : null,
    );
  }

  Widget _buildSinglePageReader(ReaderState state,
      {bool showNavigation = false}) {
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    _logger.d(
        '📖 SinglePageReader: pageCount=$pageCount, showNavigation=$showNavigation, totalItems=$totalItems');

    return PageView.builder(
      key: const ValueKey('horizontal_page_view'),
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      onPageChanged: (index) {
        // Convert 0-indexed to 1-indexed page number
        // For navigation page (index == pageCount), report pageCount + 1
        final reportPage = index + 1;

        // Update visible page notifier so off-screen animations pause
        _visiblePageNotifier.value = reportPage;

        _logger.d(
            '📖 PageView changed to index=$index (reporting page $reportPage)');

        // Only handle UI tasks, no navigation logic
        final imageUrls = state.content?.imageUrls ?? [];
        // Don't prefetch for navigation page
        if (index < pageCount) {
          _prefetchImages(
            reportPage,
            imageUrls,
            state.imageMetadata,
            sourceId: state.content?.sourceId,
          );
          // LRU eviction: release images far from current position
          _evictDistantPages(reportPage, imageUrls,
              isOffline: state.isOfflineMode ?? false);
        }

        // Update ReaderCubit state
        if (!_isProgrammaticAnimation) {
          _readerCubit.updateCurrentPageFromSwipe(reportPage);
        }
      },
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (showNavigation && index == pageCount) {
          return _buildChapterNavigationPage(state);
        }
        final imageUrl = state.content?.imageUrls[index] ?? '';
        final pageNumber = index + 1;

        return _buildImageViewer(imageUrl, pageNumber);
      },
    );
  }

  Widget _buildVerticalPageReader(ReaderState state,
      {bool showNavigation = false}) {
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    _logger.d(
        '📖 VerticalPageReader: pageCount=$pageCount, showNavigation=$showNavigation, totalItems=$totalItems');

    return PageView.builder(
      key: const ValueKey('vertical_page_view'),
      controller: _verticalPageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        // Convert 0-indexed to 1-indexed page number
        // For navigation page (index == pageCount), report pageCount + 1
        final reportPage = index + 1;

        // Update visible page notifier so off-screen animations pause
        _visiblePageNotifier.value = reportPage;

        _logger.d(
            '📖 Vertical PageView changed to index=$index (reporting page $reportPage)');

        // Only handle UI tasks, no navigation logic
        final imageUrls = state.content?.imageUrls ?? [];
        // Don't prefetch for navigation page
        if (index < pageCount) {
          _prefetchImages(
            reportPage,
            imageUrls,
            state.imageMetadata,
            sourceId: state.content?.sourceId,
          );
          // LRU eviction: release images far from current position
          _evictDistantPages(reportPage, imageUrls,
              isOffline: state.isOfflineMode ?? false);
        }

        // Update ReaderCubit state
        if (!_isProgrammaticAnimation) {
          _readerCubit.updateCurrentPageFromSwipe(reportPage);
        }
      },
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (showNavigation && index == pageCount) {
          return _buildChapterNavigationPage(state);
        }
        final imageUrl = state.content?.imageUrls[index] ?? '';
        return _buildImageViewer(
          imageUrl,
          index + 1,
          sourceId: state.content?.sourceId,
        );
      },
    );
  }

  Widget _buildContinuousReader(ReaderState state,
      {bool showNavigation = false}) {
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    // 🎯 Tap-to-toggle: Use Listener (raw pointer) instead of GestureDetector
    // to avoid competing with ListView's scroll gesture recognizer.
    // Detects quick taps (< 20px movement, < 300ms) in center 60% of screen.

    // 🚀 OPTIMIZATION: Get enableZoom once outside itemBuilder to avoid BlocBuilder in ListView
    final enableZoom = state.enableZoom ?? true;
    final isHeavySource = _isHeavyPrefetchSource(state.content?.sourceId);
    final viewportHeight = MediaQuery.of(context).size.height;

    // 🎯 Wrap in Listener for tap-to-toggle UI (bypasses gesture arena)
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _tapDownPosition = event.position;
        _tapDownTime = DateTime.now();
      },
      onPointerUp: (event) {
        final distance = (event.position - _tapDownPosition).distance;
        final duration = DateTime.now().difference(_tapDownTime);
        // Quick tap with minimal movement = toggle UI
        if (distance < 20 && duration.inMilliseconds < 300) {
          final screenHeight = MediaQuery.of(context).size.height;
          final tapY = event.position.dy;
          // Only in center 60% of screen (avoid accidental taps near edges)
          if (tapY > screenHeight * 0.2 && tapY < screenHeight * 0.8) {
            _readerCubit.toggleUI();
          }
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            _onScrollNotification(notification, state);
          }
          return false; // Allow notification to bubble up
        },
        child: ListView.builder(
          scrollCacheExtent: ScrollCacheExtent.pixels(isHeavySource
              ? viewportHeight *
                  0.25 // 🔥 THERMAL: reduce offscreen builds for heavy sources
              : 2500.0),
          controller: _scrollController,
          physics: isHeavySource
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(), // Keep fewer offscreen pages for heavy sources
          addAutomaticKeepAlives:
              true, // Heavy animated images set wantKeepAlive=true; normal images stay false
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (showNavigation && index == pageCount) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildChapterNavigationPage(state),
              );
            }

            final pageNumber = index + 1;
            final imageUrl = state.content?.imageUrls[index] ?? '';
            return _buildImageViewer(
              imageUrl,
              pageNumber,
              isContinuous: true,
              enableZoom: enableZoom,
              sourceId: state.content?.sourceId,
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl, int pageNumber,
      {bool isContinuous = false, bool? enableZoom, String? sourceId}) {
    // Debug logging removed to reduce log spam during normal scrolling
    // Uncomment below for debugging image viewer builds:
    // _logger.d('🖼️ Building image viewer for page $pageNumber with URL: $imageUrl');

    // 🚀 OPTIMIZATION: For continuous scroll mode, avoid BlocBuilder to prevent re-renders
    // Pass enableZoom as parameter instead of reading from state
    if (isContinuous) {
      final zoom = enableZoom ?? true;
      final canRepairImage = _canRepairBrokenImage(
        imageUrl: imageUrl,
        sourceId: sourceId,
      );
      final canOpenSourcePage = _canOpenSourcePageForRepair(
        imageUrl: imageUrl,
        sourceId: sourceId,
      );
      final headers = sourceId == null
          ? null
          : getIt<ContentSourceRegistry>()
              .getSource(sourceId)
              ?.getImageDownloadHeaders(imageUrl: imageUrl);
      final sourceRawConfig = _getSourceRawConfig(sourceId);
      // 🐛 FIX: Use cached height (or viewport fallback) to prevent scroll
      // jumping when items are rebuilt during scroll-up.
      final resolvedHeight = _resolveContinuousItemHeight(
        pageNumber,
        MediaQuery.of(context).size.height,
      );

      return RepaintBoundary(
        child: SizedBox(
          key: ValueKey(
              'image_viewer_$pageNumber'), // 🐛 FIX: Preserve widget identity to prevent re-loading
          height: resolvedHeight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ExtendedImageReaderWidget(
              imageUrl: imageUrl,
              contentId: widget.contentId,
              pageNumber: pageNumber,
              readingMode: ReadingMode.continuousScroll,
              sourceId: sourceId,
              sourceRawConfig: sourceRawConfig,
              httpHeaders: headers,
              enableZoom: zoom,
              visiblePageNotifier: _visiblePageNotifier,
              onHeavyImageDetected: _onHeavyImageDetected,
              onRepairBrokenImage:
                  canRepairImage ? () => _repairBrokenImage(pageNumber) : null,
              onOpenSourcePageForRepair: canOpenSourcePage
                  ? () => _openSourcePageForRepair(pageNumber)
                  : null,
              onImageLoaded: (int page, Size imageSize) {
                // Cache rendered height: image scaled to screen width
                final screenWidth = MediaQuery.of(context).size.width;
                if (imageSize.width > 0) {
                  final renderedHeight =
                      imageSize.height * (screenWidth / imageSize.width);
                  // Add margin (8.0) to match the padding
                  final totalHeight = renderedHeight + 8.0;
                  if (_cachedImageHeights[page] != totalHeight) {
                    _cachedImageHeights[page] = totalHeight;
                    // Rebuild to apply the accurate height
                    if (mounted) setState(() {});
                  }
                }
                // Forward to cubit for webtoon detection
                _readerCubit.onImageLoaded(page, imageSize);
              },
            ),
          ),
        ),
      );
    }

    // For single page and vertical modes, use BlocBuilder for dynamic updates
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        final zoom = enableZoom ?? state.enableZoom ?? true;
        final resolvedSourceId = sourceId ?? state.content?.sourceId;
        final canRepairImage = _canRepairBrokenImage(
          imageUrl: imageUrl,
          sourceId: resolvedSourceId,
        );
        final canOpenSourcePage = _canOpenSourcePageForRepair(
          imageUrl: imageUrl,
          sourceId: resolvedSourceId,
        );
        final headers = resolvedSourceId == null
            ? null
            : getIt<ContentSourceRegistry>()
                .getSource(resolvedSourceId)
                ?.getImageDownloadHeaders(imageUrl: imageUrl);
        final sourceRawConfig = _getSourceRawConfig(resolvedSourceId);

        // 🚀 FEATURE FLAG: Toggle between ExtendedImage (new) and PhotoView (legacy)
        const bool useExtendedImage = true; // Set to false for rollback

        if (useExtendedImage) {
          // ✨ NEW: Use ExtendedImageReaderWidget for all modes
          return RepaintBoundary(
            child: ExtendedImageReaderWidget(
              imageUrl: imageUrl,
              contentId: widget.contentId,
              pageNumber: pageNumber,
              readingMode: state.readingMode ?? ReadingMode.singlePage,
              sourceId: resolvedSourceId,
              sourceRawConfig: sourceRawConfig,
              httpHeaders: headers,
              enableZoom: zoom,
              visiblePageNotifier: _visiblePageNotifier,
              // Double tap = toggle UI (pinch handles zoom)
              onDoubleTapGesture: () => _readerCubit.toggleUI(),
              onRepairBrokenImage:
                  canRepairImage ? () => _repairBrokenImage(pageNumber) : null,
              onOpenSourcePageForRepair: canOpenSourcePage
                  ? () => _openSourcePageForRepair(pageNumber)
                  : null,
              onImageLoaded:
                  _readerCubit.onImageLoaded, // 🎨 Auto-detect webtoon/manhwa
            ),
          );
        }

        // 📦 LEGACY: PhotoView fallback (for rollback)
      },
    );
  }

  bool _canRepairBrokenImage({
    required String imageUrl,
    required String? sourceId,
  }) {
    if (!_readerCubit.networkCubit.isConnected) {
      return false;
    }

    if (sourceId == null || sourceId.trim().isEmpty) {
      return false;
    }

    if (getIt<ContentSourceRegistry>().getSource(sourceId) == null) {
      return false;
    }

    if (OfflineContentManager.isFailedPagePlaceholder(imageUrl)) {
      final originalUrl =
          OfflineContentManager.extractOriginalUrlFromPlaceholder(imageUrl);
      return originalUrl != null && originalUrl.trim().isNotEmpty;
    }

    if (!imageUrl.startsWith('/') && !imageUrl.startsWith('file://')) {
      return false;
    }

    return isLocalReaderImagePath(normalizeLocalReaderImagePath(imageUrl));
  }

  Map<String, dynamic>? _getSourceRawConfig(String? sourceId) {
    if (sourceId == null || sourceId.trim().isEmpty) {
      return null;
    }
    return getIt<RemoteConfigService>().getRawConfig(sourceId);
  }

  bool _canOpenSourcePageForRepair({
    required String imageUrl,
    required String? sourceId,
  }) {
    if (!_canRepairBrokenImage(imageUrl: imageUrl, sourceId: sourceId)) {
      return false;
    }

    return supportsSourcePageManualRepair(_getSourceRawConfig(sourceId));
  }

  Future<bool> _repairBrokenImage(int pageNumber) async {
    final result = await _readerCubit.repairBrokenImage(pageNumber);
    if (!mounted) {
      return result.success;
    }

    _showRepairSnackBar(pageNumber, result);

    return result.success;
  }

  Future<bool> _openSourcePageForRepair(int pageNumber) async {
    final manualContext = await _readerCubit.prepareManualRepairContext(
      pageNumber,
    );
    if (manualContext == null) {
      if (mounted) {
        _showRepairSnackBar(
          pageNumber,
          (success: false, reason: 'remote_unavailable', statusCode: null),
        );
      }
      return false;
    }

    final sourceRules = resolveSourceImageResolutionRules(
      _getSourceRawConfig(manualContext.sourceId),
    );
    final webViewResult = await KuronNative.instance.showLoginWebView(
      url: manualContext.sourcePageUrl,
      successUrlFilters: const <String>[],
      initialCookie: manualContext.initialCookie,
      userAgent: null,
      domImageSelectors: sourceRules.imageSelectors,
      domImageAttributes: sourceRules.imageAttributes,
      domLinkSelectors: sourceRules.linkSelectors,
      clearCookies: false,
    );

    if (!mounted) {
      return false;
    }

    final launched = (webViewResult?['success'] as bool?) == true;
    if (!launched) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final l10n = AppLocalizations.of(context)!;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.failedToOpenBrowser),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }

    final rawCookies =
        (webViewResult?['cookies'] as List<dynamic>?)?.cast<String>() ??
            const <String>[];
    final userAgent = webViewResult?['userAgent'] as String?;
    final sessionUrl = webViewResult?['currentUrl'] as String?;
    final resolvedImageUrl = webViewResult?['resolvedImageUrl'] as String?;

    final result = await _readerCubit.retryRepairAfterManualSession(
      pageNumber: pageNumber,
      sourcePageUrl: manualContext.sourcePageUrl,
      sessionUrl: sessionUrl,
      resolvedImageUrl: resolvedImageUrl,
      rawCookies: rawCookies,
      userAgent: userAgent,
    );

    if (mounted) {
      _showRepairSnackBar(pageNumber, result);
    }

    return result.success;
  }

  void _showRepairSnackBar(int pageNumber, ReaderImageRepairResult result) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context)!;

    final message = switch (result.reason) {
      'success' => l10n.readerImageRepairSuccess(pageNumber),
      'no_connection' => l10n.noInternetConnection,
      'http_status' => l10n.readerImageRepairHttpStatus(
          pageNumber,
          result.statusCode ?? 0,
        ),
      'invalid_image' => l10n.readerImageRepairInvalidImage(pageNumber),
      'provider_unavailable' ||
      'remote_unavailable' ||
      'page_unavailable' ||
      'content_unavailable' =>
        l10n.readerImageRepairUnavailable(pageNumber),
      _ => l10n.readerImageRepairFailed(pageNumber),
    };

    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// 🎬 Animated UI overlay — always in widget tree for smooth fade/slide transitions
  Widget _buildAnimatedUIOverlay(ReaderState state) {
    final isVisible = state.showUI ?? false;

    return IgnorePointer(
      ignoring: !isVisible,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar — slides down from top
            AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _buildTopBar(state),
              ),
            ),

            const Spacer(),

            // Bottom bar — slides up from bottom (paginated modes only)
            if (state.readingMode != ReadingMode.continuousScroll)
              AnimatedSlide(
                offset: isVisible ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: _buildBottomBar(state),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Floating page indicator pill for continuous scroll mode
  /// Uses ValueNotifiers to avoid full-screen rebuilds during scroll.
  Widget _buildFloatingPageIndicator(ReaderState state) {
    final totalPages = state.content?.pageCount ?? 0;
    if (totalPages == 0) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: _scrollingNotifier,
          builder: (context, isScrolling, _) {
            return AnimatedOpacity(
              opacity: isScrolling ? 1.0 : 0.0,
              duration: Duration(milliseconds: isScrolling ? 200 : 600),
              curve: Curves.easeOut,
              child: ValueListenableBuilder<int>(
                valueListenable: _visiblePageNotifier,
                builder: (context, page, _) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .inverseSurface
                          .withValues(alpha: 0.85),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radius2xl),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$page / $totalPages',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniChromeToggle(ReaderState state) {
    final isVisible = state.showUI ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final defaultOffset = Offset(
      mediaQuery.size.width - _miniChromeToggleSize - 12,
      mediaQuery.padding.top + 82,
    );
    final offset = _clampMiniChromeToggleOffset(
      _miniChromeToggleOffset ?? defaultOffset,
      mediaQuery,
    );

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            final currentOffset = _miniChromeToggleOffset ?? offset;
            _miniChromeToggleOffset = _clampMiniChromeToggleOffset(
              currentOffset + details.delta,
              MediaQuery.of(context),
            );
          });
        },
        child: AnimatedOpacity(
          opacity: isVisible ? 0.55 : 0.9,
          duration: const Duration(milliseconds: 180),
          child: Material(
            color: Colors.transparent,
            child: Tooltip(
              message: isVisible ? 'Hide controls' : 'Show controls',
              child: InkWell(
                borderRadius: BorderRadius.circular(_miniChromeToggleSize / 2),
                onTap: _readerCubit.toggleUI,
                child: Container(
                  width: _miniChromeToggleSize,
                  height: _miniChromeToggleSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.inverseSurface.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          colorScheme.onInverseSurface.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isVisible
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.more_horiz_rounded,
                    size: 22,
                    color: colorScheme.onInverseSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _miniChromeToggleSize = 40;

  Offset _clampMiniChromeToggleOffset(
    Offset offset,
    MediaQueryData mediaQuery,
  ) {
    const margin = 8.0;
    const minX = margin;
    final maxX = mediaQuery.size.width - _miniChromeToggleSize - margin;
    final minY = mediaQuery.padding.top + margin;
    final maxY = mediaQuery.size.height -
        mediaQuery.padding.bottom -
        _miniChromeToggleSize -
        margin;

    return Offset(
      offset.dx.clamp(minX, maxX),
      offset.dy.clamp(minY, maxY),
    );
  }

  Widget _buildTopBar(ReaderState state) {
    final kuron = Theme.of(context).extension<KuronColors>();
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final glassBg =
        kuron?.readerBg.withValues(alpha: 0.88) ?? const Color(0x8C000000);
    final iconColor = isDark ? Colors.white : const Color(0xFF2E2722);
    final textColor = isDark ? Colors.white : const Color(0xFF2E2722);
    final subColor = isDark ? Colors.white60 : const Color(0xFF7A6E66);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, color: iconColor),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
              ),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.content?.getDisplayTitle() ??
                                AppLocalizations.of(context)?.loading ??
                                '',
                            style: TextStyleConst.headingMedium.copyWith(
                              color: textColor,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Offline indicator
                        if (state.isOfflineMode ?? false) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_bolt,
                                    size: 11, color: subColor),
                                const SizedBox(width: 2),
                                Text('offline',
                                    style: TextStyle(
                                        color: subColor, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Page counter (paginated modes only)
                    if (state.readingMode != ReadingMode.continuousScroll)
                      Text(
                        (state.currentPage ?? 1) >
                                (state.content?.pageCount ?? 1)
                            ? (AppLocalizations.of(context)?.chapterComplete ??
                                '')
                            : (AppLocalizations.of(context)?.pageOfPages(
                                    state.currentPage ?? 1,
                                    state.content?.pageCount ?? 1) ??
                                AppLocalizations.of(context)!.pageOfContent(
                                    state.currentPage ?? 1,
                                    state.content?.pageCount ?? 1)),
                        style: TextStyle(color: subColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Keep screen on toggle (compact)
              IconButton(
                onPressed: () => _readerCubit.toggleKeepScreenOn(),
                icon: Icon(
                  (state.keepScreenOn ?? false)
                      ? Icons.screen_lock_portrait
                      : Icons.screen_lock_portrait_outlined,
                  color: (state.keepScreenOn ?? false)
                      ? Colors.amberAccent
                      : subColor,
                ),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),

              // Settings button
              IconButton(
                onPressed: () => _showReaderSettingsEntity(state),
                icon: Icon(Icons.settings, color: subColor),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ReaderState state) {
    // Clamp display values for navigation page
    final isOnNavigationPage =
        (state.currentPage ?? 1) > (state.content?.pageCount ?? 1);
    final totalPages = state.content?.pageCount ?? 1;
    final currentPage = isOnNavigationPage
        ? totalPages
        : (state.currentPage ?? 1).clamp(1, totalPages);
    final sliderValue = (_sliderPreviewValue ?? currentPage.toDouble())
        .clamp(1.0, totalPages.toDouble())
        .toDouble();
    final displayPage = sliderValue.round().clamp(1, totalPages);
    final kuron = Theme.of(context).extension<KuronColors>();
    final glassBg =
        kuron?.readerBg.withValues(alpha: 0.88) ?? const Color(0x8C000000);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              // Prev button
              IconButton(
                onPressed: state.isFirstPage
                    ? null
                    : () => _readerCubit.previousPage(),
                icon: Icon(
                  Icons.navigate_before,
                  color: state.isFirstPage
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white,
                ),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
              ),

              // Slider + label
              Expanded(
                child: isOnNavigationPage
                    ? Center(
                        child: Text(
                          '$totalPages / $totalPages',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      )
                    : Row(
                        children: [
                          // Page label
                          Text(
                            '$displayPage',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          // Slider
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                                trackHeight: 2.5,
                                activeTrackColor: Colors.white,
                                inactiveTrackColor:
                                    Colors.white.withValues(alpha: 0.25),
                                thumbColor: Colors.white,
                                overlayColor:
                                    Colors.white.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: sliderValue,
                                min: 1,
                                max: totalPages
                                    .toDouble()
                                    .clamp(1, double.infinity),
                                onChanged: (v) {
                                  if (_sliderPreviewValue == v) {
                                    return;
                                  }
                                  setState(() {
                                    _sliderPreviewValue = v;
                                  });
                                },
                                onChangeEnd: (v) {
                                  final targetPage =
                                      v.round().clamp(1, totalPages);
                                  setState(() {
                                    _sliderPreviewValue = null;
                                  });

                                  if (targetPage != currentPage) {
                                    _readerCubit.jumpToPage(targetPage);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Total label
                          Text(
                            '$totalPages',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
              ),

              // Next button
              IconButton(
                onPressed: () => _readerCubit.nextPage(),
                icon: const Icon(Icons.navigate_next, color: Colors.white),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
              ),

              // Mode toggle icon
              IconButton(
                onPressed: () {
                  final newMode = _getNextReadingMode(
                    state.readingMode ?? ReadingMode.singlePage,
                    disableContinuousScroll:
                        _isContinuousScrollDisabledForCurrentContent(),
                  );
                  _readerCubit.changeReadingMode(newMode);
                },
                icon: Icon(
                  _getReadingModeIcon(
                      state.readingMode ?? ReadingMode.singlePage),
                  color: Colors.white,
                ),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // DELETED: _buildEndOfChapterOverlay (moved to extra page in builder)

  // DISABLED: Jump to page feature temporarily disabled to prevent navigation bugs
  // Users should focus on sequential reading for better experience
  /*
  void _showPageJumpDialog(ReaderState state) {
    final controller =
        TextEditingController(text: (state.currentPage ?? 1).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          AppLocalizations.of(context)!.jumpToPage,
          style: TextStyleConst.headingMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyleConst.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.pageInputLabel(state.content?.pageCount ?? 1),
            labelStyle: TextStyleConst.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyleConst.buttonMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              final page = int.tryParse(controller.text);
              if (page != null &&
                  page >= 1 &&
                  page <= (state.content?.pageCount ?? 1)) {
                
                _logger.d('🎯 JUMP DEBUG: User requested page $page');
                
                // Let ReaderCubit handle all navigation via BlocListener → _syncControllersWithState()
                // This prevents race condition between manual PageController animation and automatic sync
                _readerCubit.jumpToPage(page);
              }
            },
            child: Text(
              AppLocalizations.of(context)!.jump,
              style: TextStyleConst.buttonMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  */

  void _showReaderSettingsEntity(ReaderState state) {
    final kuron = Theme.of(context).extension<KuronColors>();
    final glassBg = kuron?.readerBg.withValues(alpha: 0.92) ??
        Theme.of(context).colorScheme.surfaceContainer;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlocBuilder<ReaderCubit, ReaderState>(
        bloc: _readerCubit,
        builder: (context, currentState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: glassBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: kuron?.cardBorder.withValues(alpha: 0.3) ??
                        Colors.white12,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: glassBg.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Text(
                    AppLocalizations.of(context)?.readerSettings ??
                        AppLocalizations.of(context)!.readerSettings,
                    style: TextStyleConst.headingMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Reading mode
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.readingMode,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _isContinuousScrollDisabledForCurrentContent()
                          ? '${_getReadingModeLabel(currentState.readingMode ?? ReadingMode.singlePage)} • ${AppLocalizations.of(context)!.readerContinuousOffHeavyImage}'
                          : _getReadingModeLabel(currentState.readingMode ??
                              ReadingMode.singlePage),
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        final currentMode =
                            currentState.readingMode ?? ReadingMode.singlePage;
                        final newMode = _getNextReadingMode(
                          currentMode,
                          disableContinuousScroll:
                              _isContinuousScrollDisabledForCurrentContent(),
                        );

                        _readerCubit.changeReadingMode(newMode);
                      },
                      icon: Icon(
                        _getReadingModeIcon(
                            currentState.readingMode ?? ReadingMode.singlePage),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  // Tap Direction (only for non-continuous-scroll modes)
                  if (currentState.readingMode !=
                      ReadingMode.continuousScroll) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.readerTapDirectionLabel,
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        _getTapDirectionDescription(
                          currentState.tapDirection ?? TapDirection.normal,
                        ),
                        style: TextStyleConst.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: SegmentedButton<TapDirection>(
                        segments: [
                          ButtonSegment(
                            value: TapDirection.normal,
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(
                              AppLocalizations.of(context)!
                                  .readerTapDirectionNormal,
                            ),
                          ),
                          ButtonSegment(
                            value: TapDirection.inverted,
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: Text(
                              AppLocalizations.of(context)!
                                  .readerTapDirectionInverted,
                            ),
                          ),
                        ],
                        selected: {
                          currentState.tapDirection ?? TapDirection.normal
                        },
                        onSelectionChanged: (s) =>
                            _readerCubit.setTapDirection(s.first),
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],

                  // Chapter Selector (only in chapter mode)
                  if (currentState.chapterData != null ||
                      currentState.currentChapter != null) ...[
                    const Divider(height: 32),
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.chapterLabel,
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        currentState.currentChapter?.title ??
                            currentState.content?.title.split(' - ').last ??
                            AppLocalizations.of(context)!.noChapterSelected,
                        style: TextStyleConst.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.list,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () {
                        // Show chapter list in a dialog
                        context.pop(); // Close settings
                        _showChapterSelector(currentState);
                      },
                    ),
                  ],

                  // Keep screen on
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.keepScreenOn,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.keepScreenOnDescription,
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Switch(
                      value: currentState.keepScreenOn ?? false,
                      onChanged: (_) => _readerCubit.toggleKeepScreenOn(),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Clear image cache button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearReaderImageCache,
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.readerClearImageCache,
                        style: TextStyleConst.buttonMedium.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Reset settings button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showResetConfirmationDialog(),
                      icon: Icon(
                        Icons.restore,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.resetToDefaults,
                        style: TextStyleConst.buttonMedium.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getReadingModeIcon(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.singlePage:
        return Icons.view_carousel; // Horizontal pages
      case ReadingMode.verticalPage:
        return Icons.view_agenda; // Vertical pages
      case ReadingMode.continuousScroll:
        return Icons.view_stream; // Continuous scroll
    }
  }

  String _getReadingModeLabel(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.singlePage:
        return AppLocalizations.of(context)!.horizontalPages;
      case ReadingMode.verticalPage:
        return AppLocalizations.of(context)!.verticalPages;
      case ReadingMode.continuousScroll:
        return AppLocalizations.of(context)!.continuousScroll;
    }
  }

  String _getTapDirectionDescription(TapDirection direction) {
    switch (direction) {
      case TapDirection.normal:
        return AppLocalizations.of(context)!
            .readerTapDirectionNormalDescription;
      case TapDirection.inverted:
        return AppLocalizations.of(context)!
            .readerTapDirectionInvertedDescription;
    }
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          AppLocalizations.of(context)!.resetReaderSettings,
          style: TextStyleConst.headingMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          '${AppLocalizations.of(context)!.resetReaderSettingsConfirmation}'
          '• ${AppLocalizations.of(context)!.readingModeLabel}\n'
          '• ${AppLocalizations.of(context)!.keepScreenOnLabel}\n'
          '• ${AppLocalizations.of(context)!.showUILabel}\n\n'
          '${AppLocalizations.of(context)!.areYouSure}',
          style: TextStyleConst.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyleConst.buttonMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              _resetReaderSettings();
            },
            child: Text(
              AppLocalizations.of(context)!.reset,
              style: TextStyleConst.buttonMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChapterSelector(ReaderState state) {
    if (_readerCubit.allChapters == null || _readerCubit.allChapters!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noChaptersAvailable),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final allChapters = _readerCubit.allChapters!;
    final activeLanguage = _normalizeLanguageForFilter(
      state.currentChapter?.language ??
          _preloadedActiveChapterLanguage ??
          widget.activeChapterLanguage,
    );

    final chapters = activeLanguage == null
        ? allChapters
        : allChapters.where((chapter) {
            final chapterLanguage =
                _normalizeLanguageForFilter(chapter.language);
            return chapterLanguage == activeLanguage;
          }).toList();

    final effectiveChapters = chapters.isNotEmpty ? chapters : allChapters;

    int currentIndex = -1;
    for (int i = 0; i < effectiveChapters.length; i++) {
      final isMatch = state.currentChapter != null
          ? effectiveChapters[i].id == state.currentChapter!.id
          : effectiveChapters[i].id == state.content?.id;
      if (isMatch) {
        currentIndex = i;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (currentIndex > 0 && scrollController.hasClients) {
                final targetOffset = currentIndex * 72.0 - 100;
                if (targetOffset > 0) {
                  scrollController.animateTo(
                    targetOffset,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                }
              }
            });

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.chapters,
                                    style: TextStyleConst.headingSmall.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    activeLanguage != null &&
                                            effectiveChapters.isNotEmpty
                                        ? '${AppLocalizations.of(context)!.nChapters(effectiveChapters.length)} • ${activeLanguage.toUpperCase()}'
                                        : AppLocalizations.of(context)!
                                            .nChapters(
                                                effectiveChapters.length),
                                    style: TextStyleConst.bodySmall.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => sheetContext.pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: effectiveChapters.length,
                      itemBuilder: (_, index) {
                        final chapter = effectiveChapters[index];
                        final isCurrent = index == currentIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Material(
                            color: isCurrent
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.4)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusLg),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusLg),
                              onTap: () {
                                sheetContext.pop();
                                if (!isCurrent) {
                                  _readerCubit.loadChapter(chapter.id);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: isCurrent
                                            ? LinearGradient(
                                                colors: [
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ],
                                              )
                                            : null,
                                        color: isCurrent
                                            ? null
                                            : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: isCurrent
                                            ? Icon(
                                                Icons.play_arrow_rounded,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                size: 20,
                                              )
                                            : Text(
                                                '${index + 1}',
                                                style: TextStyleConst
                                                    .labelMedium
                                                    .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chapter.title,
                                            style: TextStyleConst.bodyMedium
                                                .copyWith(
                                              color: isCurrent
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              fontWeight: isCurrent
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (chapter.uploadDate != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatChapterDate(
                                                  chapter.uploadDate!),
                                              style: TextStyleConst.bodySmall
                                                  .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius: BorderRadius.circular(
                                              DesignTokens.radiusMd),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .chapterCurrentBadge,
                                          style: TextStyleConst.labelSmall
                                              .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _normalizeLanguageForFilter(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return ChapterLanguagePresenter.normalize(value);
  }

  String _formatChapterDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return AppLocalizations.of(context)!.today;
    if (diff.inDays == 1) return AppLocalizations.of(context)!.yesterday;
    if (diff.inDays < 7) {
      return AppLocalizations.of(context)!.readerDaysAgoShort(diff.inDays);
    }
    if (diff.inDays < 30) {
      return AppLocalizations.of(context)!
          .readerWeeksAgoShort((diff.inDays / 7).floor());
    }
    if (diff.inDays < 365) {
      return AppLocalizations.of(context)!
          .readerMonthsAgoShort((diff.inDays / 30).floor());
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _clearReaderImageCache() async {
    context.pop(); // close settings sheet
    await ExtendedImageReaderWidget.clearNativeAnimatedCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.readerImageCacheCleared),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetReaderSettings() async {
    try {
      // Close the settings modal first
      context.pop();

      // Reset the settings
      await _readerCubit.resetReaderSettings();

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.readerSettingsResetSuccess ??
                  AppLocalizations.of(context)!.readerSettingsResetSuccess,
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle reset errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                      ?.failedToResetSettings(e.toString()) ??
                  AppLocalizations.of(context)!
                      .failedToResetSettings(e.toString()),
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _resetReaderSettings(),
            ),
          ),
        );
      }
    }
  }
}
