import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/image_metadata.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../data/models/reader_settings_model.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import '../../../services/local_image_preloader.dart';
import '../../cubits/reader/reader_cubit.dart';
// import '../../cubits/reader/reader_state.dart';
import '../../widgets/progress_indicator_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/extended_image_reader_widget.dart';
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

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
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

  // Throttle expensive continuous-scroll computations.
  // 🔥 THERMAL: Increased from 90ms → 150ms → 200ms to reduce frame pressure
  // More throttling = better GPU utilization, less buffer starvation
  static const Duration _scrollProcessInterval = Duration(milliseconds: 200);
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

  // 🎯 Floating page indicator (ValueNotifiers avoid full-screen rebuild)
  final ValueNotifier<int> _visiblePageNotifier = ValueNotifier<int>(1);
  final ValueNotifier<bool> _scrollingNotifier = ValueNotifier<bool>(false);
  Timer? _scrollIndicatorTimer;

  // 🚀 OPTIMIZATION: Preload content before BlocProvider setup
  Content? _preloadedContent;
  List<ImageMetadata>? _preloadedImageMetadata;
  ChapterData? _preloadedChapterData;
  Content? _preloadedParentContent; // Parent series for chapters
  List<Chapter>? _preloadedAllChapters; // All chapters for navigation
  Chapter? _preloadedCurrentChapter; // Current chapter
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
      Logger().i(
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
            Logger().i(
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
    final routeExtra = GoRouterState.of(context).extra;

    // 🔍 DEBUG LOGGING - What did we receive from router?
    Logger().i('📥 ReaderScreen._initializeFromRouteExtra - Received:');
    Logger().i('  routeExtra type: ${routeExtra.runtimeType}');

    if (routeExtra is Map<String, dynamic>) {
      Logger().i('  Map keys: ${routeExtra.keys.toList()}');

      if (routeExtra['content'] is Content && widget.preloadedContent == null) {
        _preloadedContent = routeExtra['content'] as Content;
        Logger().i('  ✓ content: ${_preloadedContent?.title}');
      }
      if (routeExtra['imageMetadata'] is List<ImageMetadata> &&
          widget.imageMetadata == null) {
        _preloadedImageMetadata =
            routeExtra['imageMetadata'] as List<ImageMetadata>;
        Logger()
            .i('  ✓ imageMetadata: ${_preloadedImageMetadata?.length} items');
      }
      if (routeExtra['chapterData'] is ChapterData &&
          widget.chapterData == null) {
        _preloadedChapterData = routeExtra['chapterData'] as ChapterData;
        Logger().i(
            '  ✓ chapterData: prev=${_preloadedChapterData?.prevChapterId}, next=${_preloadedChapterData?.nextChapterId}');
      }
      if (routeExtra['parentContent'] is Content &&
          widget.parentContent == null) {
        _preloadedParentContent = routeExtra['parentContent'] as Content;
        Logger().i('  ✓ parentContent: ${_preloadedParentContent?.title}');
      }
      if (routeExtra['allChapters'] is List<Chapter> &&
          widget.allChapters == null) {
        _preloadedAllChapters = routeExtra['allChapters'] as List<Chapter>;
        Logger()
            .i('  ✓ allChapters: ${_preloadedAllChapters?.length} chapters');
        if (_preloadedAllChapters != null &&
            _preloadedAllChapters!.isNotEmpty) {
          Logger().i('    First: ${_preloadedAllChapters!.first.title}');
          Logger().i('    Last: ${_preloadedAllChapters!.last.title}');
        }
      } else {
        Logger().e('  ❌ allChapters NOT received or wrong type!');
        Logger().e('    Type: ${routeExtra['allChapters'].runtimeType}');
      }
      if (routeExtra['currentChapter'] is Chapter &&
          widget.currentChapter == null) {
        _preloadedCurrentChapter = routeExtra['currentChapter'] as Chapter;
        Logger().i('  ✓ currentChapter: ${_preloadedCurrentChapter?.title}');
      }
    } else if (routeExtra is Content && widget.preloadedContent == null) {
      // Fallback for direct Content object (backward compatibility)
      _preloadedContent = routeExtra;
      Logger().i('  ✓ Direct Content: ${_preloadedContent?.title}');
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
      debugPrint('Reader preload failed: $e');
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
      Logger().t(
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

    // 🎯 CRITICAL FIX: Use viewport center for page detection
    // This is more accurate than using scroll position directly
    final viewportCenter = metrics.pixels + (screenHeight / 2);

    // 🎯 ADAPTIVE: Calculate average item height based on ACTUAL maxScrollExtent
    // This adapts to webtoon (tall images) vs manga (normal images)
    int estimatedPage;

    if (metrics.maxScrollExtent > 0 && totalPages > 0) {
      // Use actual maxScrollExtent to calculate accurate average height
      final averageItemHeight = metrics.maxScrollExtent / totalPages;

      // Find which page the viewport center is currently viewing
      estimatedPage = (viewportCenter / averageItemHeight)
              .floor()
              .clamp(0, totalPages - 1) +
          1;

      // Logger().t(
      //     '📐 Avg height: ${averageItemHeight.toStringAsFixed(0)}px, viewport center at page $estimatedPage');
    } else {
      // Fallback: Use screen-based estimation (only when maxScrollExtent not ready)
      final estimatedItemHeight = screenHeight * 0.9;
      estimatedPage = ((metrics.pixels / estimatedItemHeight) + 1)
          .round()
          .clamp(1, totalPages);
    }

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

  /// 🚀 OPTIMIZATION: Debounce save to DB to prevent spam
  void _debounceSaveHistory(ReaderState state, int page) {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
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
    _uiToggleDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      _lastUIVisibleState = shouldShow;
      if (shouldShow && !(state.showUI ?? false)) {
        _readerCubit.showUI();
      } else if (!shouldShow && (state.showUI ?? false)) {
        _readerCubit.hideUI();
      }
    });
  }

  @override
  void dispose() {
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

    // HentaiNexus image pages are typically large. Instead of disabling prefetch,
    // use ODD/EVEN batching for pseudo-parallel loading with rate limiting.
    // This allows faster image appearance while respecting server constraints.
    if (_isHeavyPrefetchSource(sourceId)) {
      // 🔴 HentaiNexus: DISABLE prefetch completely
      // Odd/even batching was causing GPU buffer saturation + frame drops
      // Solution: Lazy-on-demand loading when user scrolls (handled by ExtendedImage widget)
      // Result: No competing rendering, smooth continuous scroll, no glitches
      return;
    }

    // Prefetch next _prefetchCount pages (standard for lighter sources)
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
              debugPrint(
                  '⚠️ METADATA MISMATCH: Page $targetPage metadata URL != actual URL');
              debugPrint('   Metadata URL: ${metadata.imageUrl}');
              debugPrint('   Actual URL: $imageUrl');
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
        ).then((_) {
          if (mounted) {
            // Log success with validation status
            final status = isValid ? '✅' : '❓';
            debugPrint(
                '📥 $status Prefetched page $targetPage (metadata validated: $isValid)');
          }
        }).catchError((error) {
          // Remove from prefetched set if failed, so it can be retried
          _prefetchedPages.remove(targetPage);
          debugPrint('❌ Failed to prefetch page $targetPage: $error');
        });
      }
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
          debugPrint(
              '🔄 SYNC: Jumping PageController from $currentPageControllerIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _pageController.jumpToPage(targetPageIndex);
          _isProgrammaticAnimation = false;
        } else {
          // Use smooth animation for small distances
          debugPrint(
              '🔄 SYNC: Animating PageController from $currentPageControllerIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _pageController
              .animateToPage(
            targetPageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
          debugPrint(
              '🔄 SYNC: Jumping VerticalPageController from $currentVerticalIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _verticalPageController.jumpToPage(targetPageIndex);
          _isProgrammaticAnimation = false;
        } else {
          // Use smooth animation for small distances
          debugPrint(
              '🔄 SYNC: Animating VerticalPageController from $currentVerticalIndex to $targetPageIndex (distance: $distance)');
          _isProgrammaticAnimation = true;
          _verticalPageController
              .animateToPage(
            targetPageIndex,
            duration: const Duration(milliseconds: 300),
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
            duration: const Duration(milliseconds: 300),
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
          title: AppLocalizations.of(context)?.loadingError ?? 'Loading Error',
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
    return Stack(
      children: [
        // Main reader content
        _buildReaderContent(state),

        // 🎬 Animated UI overlay (always in tree for smooth transitions)
        _buildAnimatedUIOverlay(state),

        // 🎯 Floating page indicator for continuous scroll
        if (state.readingMode == ReadingMode.continuousScroll)
          _buildFloatingPageIndicator(state),
      ],
    );
  }

  Widget _buildReaderContent(ReaderState state) {
    final showNav = _shouldShowNavigationItem(state);

    switch (state.readingMode ?? ReadingMode.singlePage) {
      case ReadingMode.singlePage:
        return _buildSinglePageReader(state, showNavigation: showNav);
      case ReadingMode.verticalPage:
        return _buildVerticalPageReader(state, showNavigation: showNav);
      case ReadingMode.continuousScroll:
        return _buildContinuousReader(state, showNavigation: showNav);
    }
  }

  bool _shouldShowNavigationItem(ReaderState state) {
    if (state.isOfflineMode ?? false) {
      debugPrint('❌ Navigation page disabled: Offline mode');
      return false;
    }
    final hasContent =
        state.content != null && (state.content!.imageUrls.isNotEmpty);
    return hasContent;
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
      onBackToDetail: () => Navigator.of(context).pop(),
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

    debugPrint(
        '📖 SinglePageReader: pageCount=$pageCount, showNavigation=$showNavigation, totalItems=$totalItems');

    return GestureDetector(
      onTapUp: (details) {
        // Simple tap gesture: center = toggle UI, sides = navigate
        final screenWidth = MediaQuery.of(context).size.width;
        final tapX = details.globalPosition.dx;

        if (tapX < screenWidth * 0.3) {
          // Left side - previous page
          _readerCubit.previousPage();
        } else if (tapX > screenWidth * 0.7) {
          // Right side - next page
          _readerCubit.nextPage();
        } else {
          // Center - toggle UI
          _readerCubit.toggleUI();
        }
      },
      child: PageView.builder(
        key: const ValueKey('horizontal_page_view'),
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        onPageChanged: (index) {
          // Convert 0-indexed to 1-indexed page number
          // For navigation page (index == pageCount), report pageCount + 1
          final reportPage = index + 1;

          debugPrint(
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
      ),
    );
  }

  Widget _buildVerticalPageReader(ReaderState state,
      {bool showNavigation = false}) {
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    debugPrint(
        '📖 VerticalPageReader: pageCount=$pageCount, showNavigation=$showNavigation, totalItems=$totalItems');

    return GestureDetector(
      onTapUp: (details) {
        // Simple tap gesture: center = toggle UI, top/bottom = navigate
        final screenHeight = MediaQuery.of(context).size.height;
        final tapY = details.globalPosition.dy;

        if (tapY < screenHeight * 0.3) {
          // Top area - previous page
          _readerCubit.previousPage();
        } else if (tapY > screenHeight * 0.7) {
          // Bottom area - next page
          _readerCubit.nextPage();
        } else {
          // Center - toggle UI
          _readerCubit.toggleUI();
        }
      },
      child: PageView.builder(
        key: const ValueKey('vertical_page_view'),
        controller: _verticalPageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          // Convert 0-indexed to 1-indexed page number
          // For navigation page (index == pageCount), report pageCount + 1
          final reportPage = index + 1;

          debugPrint(
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
      ),
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
          controller: _scrollController,
          physics: isHeavySource
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          cacheExtent: isHeavySource
              ? viewportHeight *
                  0.25 // 🔥 THERMAL: reduce offscreen builds for heavy sources
              : 2500.0, // Keep fewer offscreen pages for heavy sources
          addAutomaticKeepAlives:
              false, // 🔥 THERMAL: Disabled for all modes to reduce memory
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
    // debugPrint('🖼️ Building image viewer for page $pageNumber with URL: $imageUrl');

    // 🚀 OPTIMIZATION: For continuous scroll mode, avoid BlocBuilder to prevent re-renders
    // Pass enableZoom as parameter instead of reading from state
    if (isContinuous) {
      final zoom = enableZoom ?? true;
      final headers = sourceId == null
          ? null
          : getIt<ContentSourceRegistry>()
              .getSource(sourceId)
              ?.getImageDownloadHeaders(imageUrl: imageUrl);
      // 🐛 FIX: Use cached height (or viewport fallback) to prevent scroll
      // jumping when items are rebuilt during scroll-up.
      final cachedHeight = _cachedImageHeights[pageNumber];
      final fallbackHeight = MediaQuery.of(context).size.height;

      return SizedBox(
        key: ValueKey(
            'image_viewer_$pageNumber'), // 🐛 FIX: Preserve widget identity to prevent re-loading
        height: cachedHeight ?? fallbackHeight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ExtendedImageReaderWidget(
            imageUrl: imageUrl,
            contentId: widget.contentId,
            pageNumber: pageNumber,
            readingMode: ReadingMode.continuousScroll,
            sourceId: sourceId,
            httpHeaders: headers,
            enableZoom: zoom,
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
      );
    }

    // For single page and vertical modes, use BlocBuilder for dynamic updates
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        final zoom = enableZoom ?? state.enableZoom ?? true;
        final resolvedSourceId = sourceId ?? state.content?.sourceId;
        final headers = resolvedSourceId == null
            ? null
            : getIt<ContentSourceRegistry>()
                .getSource(resolvedSourceId)
                ?.getImageDownloadHeaders(imageUrl: imageUrl);

        // 🚀 FEATURE FLAG: Toggle between ExtendedImage (new) and PhotoView (legacy)
        const bool useExtendedImage = true; // Set to false for rollback

        if (useExtendedImage) {
          // ✨ NEW: Use ExtendedImageReaderWidget for all modes
          return ExtendedImageReaderWidget(
            imageUrl: imageUrl,
            contentId: widget.contentId,
            pageNumber: pageNumber,
            readingMode: state.readingMode ?? ReadingMode.singlePage,
            sourceId: resolvedSourceId,
            httpHeaders: headers,
            enableZoom: zoom,
            onImageLoaded:
                _readerCubit.onImageLoaded, // 🎨 Auto-detect webtoon/manhwa
          );
        }

        // 📦 LEGACY: PhotoView fallback (for rollback)
      },
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
                      borderRadius: BorderRadius.circular(20),
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

  Widget _buildTopBar(ReaderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface),
          ),

          const SizedBox(width: 8),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.content?.getDisplayTitle() ??
                            AppLocalizations.of(context)?.loading ??
                            AppLocalizations.of(context)!.loading,
                        style: TextStyleConst.headingMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Offline indicator
                    if (state.isOfflineMode ?? false) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.offline_bolt,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (AppLocalizations.of(context)?.offline ??
                                      'OFFLINE')
                                  .toUpperCase(),
                              style: TextStyleConst.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                // Only show page counter in paginated modes (singlePage, verticalPage)
                // In continuous scroll, page counter is not meaningful as multiple pages are visible
                if (state.readingMode != ReadingMode.continuousScroll)
                  Row(
                    children: [
                      // Check if we're on navigation page
                      if ((state.currentPage ?? 1) >
                          (state.content?.pageCount ?? 1))
                        Text(
                          AppLocalizations.of(context)!.chapterComplete,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          AppLocalizations.of(context)?.pageOfPages(
                                  state.currentPage ?? 1,
                                  state.content?.pageCount ?? 1) ??
                              AppLocalizations.of(context)!.pageOfContent(state.currentPage ?? 1, state.content?.pageCount ?? 1),
                          style: TextStyleConst.bodySmall.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // Reading mode toggle
          IconButton(
            onPressed: () {
              final currentMode = state.readingMode ?? ReadingMode.singlePage;
              ReadingMode newMode;

              switch (currentMode) {
                case ReadingMode.singlePage:
                  newMode = ReadingMode.verticalPage;
                  break;
                case ReadingMode.verticalPage:
                  newMode = ReadingMode.continuousScroll;
                  break;
                case ReadingMode.continuousScroll:
                  newMode = ReadingMode.singlePage;
                  break;
              }

              _readerCubit.changeReadingMode(newMode);
            },
            icon: Icon(
              _getReadingModeIcon(state.readingMode ?? ReadingMode.singlePage),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // Keep screen on toggle
          IconButton(
            onPressed: () => _readerCubit.toggleKeepScreenOn(),
            icon: Icon(
              (state.keepScreenOn ?? false)
                  ? Icons.screen_lock_portrait
                  : Icons.screen_lock_portrait_outlined,
              color: (state.keepScreenOn ?? false)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // Settings button
          IconButton(
            onPressed: () => _showReaderSettings(state),
            icon: Icon(Icons.settings,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ReaderState state) {
    // Clamp display values for navigation page
    final isOnNavigationPage =
        (state.currentPage ?? 1) > (state.content?.pageCount ?? 1);
    final displayPage = isOnNavigationPage
        ? (state.content?.pageCount ?? 1)
        : (state.currentPage ?? 1);
    final displayProgress = isOnNavigationPage ? 1.0 : state.progress;
    final displayPercentage =
        isOnNavigationPage ? 100 : state.progressPercentage;

    debugPrint(
        '🎨 BottomBar: currentPage=${state.currentPage}, pageCount=${state.content?.pageCount}, '
        'isOnNavPage=$isOnNavigationPage, displayProgress=$displayProgress, displayPercentage=$displayPercentage%');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          isOnNavigationPage
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    Text(
                      '$displayPage',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: displayProgress,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${state.content?.pageCount ?? 1}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 16),

          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous page
              IconButton(
                onPressed: state.isFirstPage
                    ? null
                    : () => _readerCubit.previousPage(),
                icon: Icon(
                  Icons.navigate_before,
                  color: state.isFirstPage
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.38)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),

              // Page info and jump
              Text(
                '$displayPercentage%',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              // Next page
              IconButton(
                onPressed: () => _readerCubit
                    .nextPage(), // Always enabled, nextPage() handles limits
                icon: Icon(
                  Icons.navigate_next,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: TextStyleConst.buttonMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final page = int.tryParse(controller.text);
              if (page != null &&
                  page >= 1 &&
                  page <= (state.content?.pageCount ?? 1)) {
                
                debugPrint('🎯 JUMP DEBUG: User requested page $page');
                
                // Let ReaderCubit handle all navigation via BlocListener → _syncControllersWithState()
                // This prevents race condition between manual PageController animation and automatic sync
                _readerCubit.jumpToPage(page);
              }
            },
            child: Text(
              AppLocalizations.of(context)?.jump ?? 'Jump',
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

  void _showReaderSettings(ReaderState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      isScrollControlled: true,
      builder: (context) => BlocBuilder<ReaderCubit, ReaderState>(
        bloc: _readerCubit,
        builder: (context, currentState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.38),
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
                  AppLocalizations.of(context)?.readingMode ?? 'Reading Mode',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  _getReadingModeLabel(
                      currentState.readingMode ?? ReadingMode.singlePage),
                  style: TextStyleConst.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () {
                    final currentMode =
                        currentState.readingMode ?? ReadingMode.singlePage;
                    ReadingMode newMode;

                    switch (currentMode) {
                      case ReadingMode.singlePage:
                        newMode = ReadingMode.verticalPage;
                        break;
                      case ReadingMode.verticalPage:
                        newMode = ReadingMode.continuousScroll;
                        break;
                      case ReadingMode.continuousScroll:
                        newMode = ReadingMode.singlePage;
                        break;
                    }

                    _readerCubit.changeReadingMode(newMode);
                  },
                  icon: Icon(
                    _getReadingModeIcon(
                        currentState.readingMode ?? ReadingMode.singlePage),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

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
                    Navigator.pop(context); // Close settings
                    _showChapterSelector(currentState);
                  },
                ),
              ],

              // Keep screen on
              ListTile(
                title: Text(
                  AppLocalizations.of(context)?.keepScreenOn ??
                      AppLocalizations.of(context)!.keepScreenOn,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)?.keepScreenOnDescription ??
                      AppLocalizations.of(context)!.preventScreenOff,
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
                    AppLocalizations.of(context)?.resetToDefaults ??
                        AppLocalizations.of(context)!.resetToDefaults,
                    style: TextStyleConst.buttonMedium.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
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
        return AppLocalizations.of(context)?.horizontalPages ??
            AppLocalizations.of(context)!.horizontalPages;
      case ReadingMode.verticalPage:
        return AppLocalizations.of(context)?.verticalPages ?? 'Vertical Pages';
      case ReadingMode.continuousScroll:
        return AppLocalizations.of(context)?.continuousScroll ??
            AppLocalizations.of(context)!.continuousScroll;
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyleConst.buttonMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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
      state.currentChapter?.language,
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
                                        ? '${effectiveChapters.length} chapters • ${activeLanguage.toUpperCase()}'
                                        : AppLocalizations.of(context)!.nChapters(effectiveChapters.length),
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
                              onPressed: () => Navigator.pop(sheetContext),
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
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(sheetContext);
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'NOW',
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
    final raw = value?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw.split('-').first;
  }

  String _formatChapterDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return AppLocalizations.of(context)!.today;
    if (diff.inDays == 1) return AppLocalizations.of(context)!.yesterday;
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _resetReaderSettings() async {
    try {
      // Close the settings modal first
      Navigator.of(context).pop();

      // Reset the settings
      await _readerCubit.resetReaderSettings();

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.readerSettingsResetSuccess ??
                  AppLocalizations.of(context)!.readerSettingsReset,
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                  AppLocalizations.of(context)!.failedToResetSettings(e.toString()),
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: AppLocalizations.of(context)?.retry ?? 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _resetReaderSettings(),
            ),
          ),
        );
      }
    }
  }
}
