import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
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

  // Prefetch control
  final Set<int> _prefetchedPages = <int>{};
  static const int _prefetchCount = 5;

  // Debounce mechanism to prevent onPageChanged loops
  bool _isProgrammaticAnimation = false;

  // 🚀 OPTIMIZATION: Throttle save to DB and UI toggle
  Timer? _saveDebounceTimer;
  Timer? _pageUpdateTimer; // Separate timer for page updates
  Timer? _uiToggleDebounceTimer;
  bool _lastUIVisibleState = true;

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

    // 🐛 CRITICAL: Skip all processing during programmatic scroll
    // This prevents false page saves during initial positioning
    if (_isProgrammaticAnimation) {
      Logger().t(
          '⏭️  Skipping scroll event (programmatic): ${notification.metrics.pixels.toStringAsFixed(0)}px');
      return;
    }

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

      Logger().t('📐 Using fallback estimation (maxScrollExtent not ready)');
    }

    // Debug logging (only when page changes)
    if (estimatedPage != _lastReportedPage) {
      Logger().t(
          '📄 Page: $estimatedPage/$totalPages (scroll: ${metrics.pixels.toStringAsFixed(0)}px / ${metrics.maxScrollExtent.toStringAsFixed(0)}px, center: ${viewportCenter.toStringAsFixed(0)}px)');
    }

    // Update current page for progress bar with debounce
    if (estimatedPage != _lastReportedPage) {
      _lastReportedPage = estimatedPage;

      // 🚀 OPTIMIZATION: Debounce page updates to reduce DB writes
      _debouncePageUpdate(estimatedPage, state);

      // Prefetch next images
      _prefetchImages(
          estimatedPage, state.content!.imageUrls, state.imageMetadata);
    }

    // 🐛 FIX: Check if user truly reached bottom using scroll metrics
    // More reliable than pixel threshold
    final isAtBottom =
        metrics.pixels >= metrics.maxScrollExtent - 50; // 50px threshold

    if (isAtBottom && _lastSavedPage < totalPages) {
      Logger().i('📍 User reached bottom - marking as complete');
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
      _readerCubit.updateCurrentPageFromSwipe(page);
    });
  }

  /// 🚀 OPTIMIZATION: Debounce page updates to reduce DB spam
  void _debouncePageUpdate(int page, ReaderState state) {
    // 🐛 FIX: Only save if progress moves forward (user reads more)
    // Don't save when scrolling back up to re-read
    if (page <= _lastSavedPage) {
      return; // Skip saving if scrolling backwards
    }

    _pageUpdateTimer?.cancel();
    _pageUpdateTimer = Timer(const Duration(milliseconds: 800), () {
      // Save page progress after user stops scrolling for 800ms
      // This prevents DB spam when user scrolls up/down repeatedly
      _lastSavedPage = page; // Update last saved page
      _readerCubit.updateCurrentPageFromSwipe(page);
    });
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

    super.dispose();
  }

  /// Prefetch next few images in background for smoother reading experience
  void _prefetchImages(int currentPage, List<String> imageUrls,
      List<ImageMetadata>? imageMetadata) {
    if (imageUrls.isEmpty) return;

    // Prefetch next _prefetchCount pages
    for (int i = 1; i <= _prefetchCount; i++) {
      final targetPage = currentPage + i;

      // Check bounds and avoid duplicate prefetching
      if (targetPage <= imageUrls.length &&
          !_prefetchedPages.contains(targetPage)) {
        _prefetchedPages.add(targetPage);

        final imageUrl = imageUrls[targetPage - 1]; // Convert to 0-based index

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
        listener: (context, state) {
          _syncControllersWithState(state);

          // Trigger initial prefetching when content is loaded
          if (state.content != null && state.content!.imageUrls.isNotEmpty) {
            final currentPage = state.currentPage ?? widget.initialPage;
            _prefetchImages(
                currentPage, state.content!.imageUrls, state.imageMetadata);
          }
        },
        child: BlocBuilder<ReaderCubit, ReaderState>(
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
              'Loading content...',
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

        // UI overlay
        if (state.showUI ?? false) _buildUIOverlay(state),
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
    final bool isChapterMode =
        state.chapterData != null || state.currentChapter != null;
    final bool hasPrevChapter = state.chapterData?.prevChapterId != null;
    final bool hasNextChapter = state.chapterData?.nextChapterId != null;

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
            _prefetchImages(reportPage, imageUrls, state.imageMetadata);
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
            _prefetchImages(reportPage, imageUrls, state.imageMetadata);
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
          return _buildImageViewer(imageUrl, index + 1);
        },
      ),
    );
  }

  Widget _buildContinuousReader(ReaderState state,
      {bool showNavigation = false}) {
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    // 🐛 BUG FIX: Remove GestureDetector wrapper to prevent scroll gesture conflicts
    // GestureDetector blocks ListView scroll gestures, causing:
    // 1. Unable to scroll down
    // 2. Unable to scroll back to top from bottom
    // For continuous scroll mode, UI toggle is available via top bar only

    // 🚀 OPTIMIZATION: Get enableZoom once outside itemBuilder to avoid BlocBuilder in ListView
    final enableZoom = state.enableZoom ?? true;

    // 🐛 FIX: Wrap ListView with NotificationListener for accurate scroll tracking
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          _onScrollNotification(notification, state);
        }
        return false; // Allow notification to bubble up
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(), // Smoother scroll
        cacheExtent:
            10000.0, // 🚀 OPTIMIZATION: Increased from 1000px to 10000px to keep more images in memory
        addAutomaticKeepAlives:
            true, // Keep widgets alive when scrolled out of view
        itemCount: totalItems,
        itemBuilder: (context, index) {
          if (showNavigation && index == pageCount) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: _buildChapterNavigationPage(state),
            );
          }
          final imageUrl = state.content?.imageUrls[index] ?? '';
          return _buildImageViewer(
            imageUrl,
            index + 1,
            isContinuous: true,
            enableZoom: enableZoom,
          );
        },
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl, int pageNumber,
      {bool isContinuous = false, bool? enableZoom}) {
    // Debug logging removed to reduce log spam during normal scrolling
    // Uncomment below for debugging image viewer builds:
    // debugPrint('🖼️ Building image viewer for page $pageNumber with URL: $imageUrl');

    // 🚀 OPTIMIZATION: For continuous scroll mode, avoid BlocBuilder to prevent re-renders
    // Pass enableZoom as parameter instead of reading from state
    if (isContinuous) {
      final zoom = enableZoom ?? true;
      return Container(
        key: ValueKey(
            'image_viewer_$pageNumber'), // 🐛 FIX: Preserve widget identity to prevent re-loading
        margin: const EdgeInsets.only(bottom: 8.0),
        child: ExtendedImageReaderWidget(
          imageUrl: imageUrl,
          contentId: widget.contentId,
          pageNumber: pageNumber,
          readingMode: ReadingMode.continuousScroll,
          enableZoom: zoom,
          onImageLoaded:
              _readerCubit.onImageLoaded, // 🎨 Auto-detect webtoon/manhwa
        ),
      );
    }

    // For single page and vertical modes, use BlocBuilder for dynamic updates
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        final zoom = enableZoom ?? state.enableZoom ?? true;

        // 🚀 FEATURE FLAG: Toggle between ExtendedImage (new) and PhotoView (legacy)
        const bool useExtendedImage = true; // Set to false for rollback

        if (useExtendedImage) {
          // ✨ NEW: Use ExtendedImageReaderWidget for all modes
          return ExtendedImageReaderWidget(
            imageUrl: imageUrl,
            contentId: widget.contentId,
            pageNumber: pageNumber,
            readingMode: state.readingMode ?? ReadingMode.singlePage,
            enableZoom: zoom,
            onImageLoaded:
                _readerCubit.onImageLoaded, // 🎨 Auto-detect webtoon/manhwa
          );
        }

        // 📦 LEGACY: PhotoView fallback (for rollback)
      },
    );
  }

  Widget _buildUIOverlay(ReaderState state) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          _buildTopBar(state),

          const Spacer(),

          // Bottom bar - hide in continuous scroll mode to avoid blocking
          if (state.readingMode != ReadingMode.continuousScroll)
            _buildBottomBar(state),
        ],
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
                            'Loading...',
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
                          'Chapter Complete',
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
                              'Page ${state.currentPage ?? 1} of ${state.content?.pageCount ?? 1}',
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
                    'Reader Settings',
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
                    'Chapter',
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    currentState.currentChapter?.title ??
                        currentState.content?.title.split(' - ').last ??
                        'No chapter selected',
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
                      'Keep Screen On',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)?.keepScreenOnDescription ??
                      'Prevent screen from turning off while reading',
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
                        'Reset to Defaults',
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
            'Horizontal Pages';
      case ReadingMode.verticalPage:
        return AppLocalizations.of(context)?.verticalPages ?? 'Vertical Pages';
      case ReadingMode.continuousScroll:
        return AppLocalizations.of(context)?.continuousScroll ??
            'Continuous Scroll';
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
          content: const Text('No chapters available'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final chapters = _readerCubit.allChapters!;
    int currentIndex = -1;
    for (int i = 0; i < chapters.length; i++) {
      final isMatch = state.currentChapter != null
          ? chapters[i].id == state.currentChapter!.id
          : chapters[i].id == state.content?.id;
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
                                    'Chapters',
                                    style: TextStyleConst.headingSmall.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${chapters.length} chapters',
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
                      itemCount: chapters.length,
                      itemBuilder: (_, index) {
                        final chapter = chapters[index];
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

  String _formatChapterDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
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
                  'Reader settings have been reset to defaults.',
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
                  'Failed to reset settings: ${e.toString()}',
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
