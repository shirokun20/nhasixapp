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
import '../../../services/local_image_preloader.dart';
import '../../cubits/reader/reader_cubit.dart';
// import '../../cubits/reader/reader_state.dart';
import '../../widgets/progress_indicator_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/extended_image_reader_widget.dart';
import '../../widgets/reader_navigation_page.dart';
import 'package:nhasixapp/services/ad_service.dart';

/// Simple reader screen for reading manga/doujinshi content
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.contentId,
    this.initialPage = 1,
    this.forceStartFromBeginning = false,
    this.preloadedContent,
    this.imageMetadata,
    this.parentContent,
    this.allChapters,
    this.currentChapter,
    this.onNavigateToChapter,
  });

  final String contentId;
  final int initialPage;
  final bool forceStartFromBeginning;
  final Content? preloadedContent;
  final List<ImageMetadata>? imageMetadata;
  final Content? parentContent;
  final List<Chapter>? allChapters;
  final Chapter? currentChapter;

  /// Callback to navigate to a specific chapter
  /// Used for next/prev chapter navigation
  /// Parameters: chapterId, sourceId
  final void Function(String chapterId, String sourceId)? onNavigateToChapter;

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

  // Prefetch control
  final Set<int> _prefetchedPages = <int>{};
  static const int _prefetchCount = 5;

  // Debounce mechanism to prevent onPageChanged loops
  bool _isProgrammaticAnimation = false;

  // 🚀 OPTIMIZATION: Preload content before BlocProvider setup
  Content? _preloadedContent;
  List<ImageMetadata>? _preloadedImageMetadata;
  bool _isPreloading = false;

  // Chapter navigation parameters
  Content? _parentContent;
  List<Chapter>? _allChapters;
  Chapter? _currentChapter;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _verticalPageController =
        PageController(initialPage: widget.initialPage - 1);
    _scrollController = ScrollController();
    _readerCubit = getIt<ReaderCubit>();

    // 🚀 OPTIMIZATION: Initialize route extra synchronously before build
    _initializeFromRouteExtraSync();

    // Defer GoRouterState access until after widget is mounted (for any additional processing)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start preloading after route extra is processed
      _startPreloading();
    });

    // Add scroll listener for continuous mode
    _scrollController.addListener(_onScrollChanged);

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
    if (routeExtra is Map<String, dynamic>) {
      if (routeExtra['content'] is Content && widget.preloadedContent == null) {
        _preloadedContent = routeExtra['content'] as Content;
      }
      if (routeExtra['imageMetadata'] is List<ImageMetadata> &&
          widget.imageMetadata == null) {
        _preloadedImageMetadata =
            routeExtra['imageMetadata'] as List<ImageMetadata>;
      }
      // Extract chapter navigation parameters
      if (routeExtra['parentContent'] is Content) {
        _parentContent = routeExtra['parentContent'] as Content;
      }
      if (routeExtra['allChapters'] is List<Chapter>) {
        _allChapters = routeExtra['allChapters'] as List<Chapter>;
      }
      if (routeExtra['currentChapter'] is Chapter) {
        _currentChapter = routeExtra['currentChapter'] as Chapter;
      }
    } else if (routeExtra is Content && widget.preloadedContent == null) {
      // Fallback for direct Content object (backward compatibility)
      _preloadedContent = routeExtra;
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

      // Only prefetch when page changes - no state updates, no history saves
      if (clampedPage != _lastReportedPage) {
        _lastReportedPage = clampedPage;
        _prefetchImages(
            clampedPage, state.content!.imageUrls, state.imageMetadata);
      }

      // ✨ NEW: Auto-hide UI on scroll down
      // If scrolling down (user moving finger up) and UI is visible -> hide it
      if (_scrollController.position.userScrollDirection.toString() ==
              'ScrollDirection.reverse' &&
          (state.showUI ?? false)) {
        _readerCubit.hideUI();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _pageController.dispose();
    _verticalPageController.dispose();
    _scrollController.dispose();
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

        // Use chapter navigation parameters from widget or extracted from route extra
        final effectiveParentContent = _parentContent ?? widget.parentContent;
        final effectiveAllChapters = _allChapters ?? widget.allChapters;
        final effectiveCurrentChapter =
            _currentChapter ?? widget.currentChapter;

        // Always call loadContent with preloaded content if available
        return _readerCubit
          ..loadContent(
            widget.contentId,
            initialPage: widget.initialPage,
            forceStartFromBeginning: widget.forceStartFromBeginning,
            preloadedContent: effectivePreloadedContent,
            imageMetadata: effectiveImageMetadata,
            parentContent: effectiveParentContent,
            allChapters: effectiveAllChapters,
            currentChapter: effectiveCurrentChapter,
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
            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  getIt<AdService>().showInterstitial();
                }
              },
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 50 ||
                        constraints.maxHeight < 50) {
                      return const SizedBox.shrink();
                    }
                    return _buildBody(state);
                  },
                ),
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
            parentContent: widget.parentContent,
            allChapters: widget.allChapters,
            currentChapter: widget.currentChapter,
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
    switch (state.readingMode ?? ReadingMode.singlePage) {
      case ReadingMode.singlePage:
        return _buildSinglePageReader(state);
      case ReadingMode.verticalPage:
        return _buildVerticalPageReader(state);
      case ReadingMode.continuousScroll:
        return _buildContinuousReader(state);
    }
  }

  Widget _buildSinglePageReader(ReaderState state) {
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
          final newPage = index + 1;

          debugPrint('� PageView changed to index=$index (page $newPage)');

          // Only handle UI tasks, no navigation logic
          // This prevents recursive loops with jumpToPage
          final imageUrls = state.content?.imageUrls ?? [];
          _prefetchImages(newPage, imageUrls, state.imageMetadata);

          // Update ReaderCubit state to reflect the current page without triggering navigation
          if (!_isProgrammaticAnimation) {
            // Only update state if this was a real user swipe
            _readerCubit.updateCurrentPageFromSwipe(newPage);
          }
        },
        itemCount: (state.content?.imageUrls.length ?? 0) +
            1, // +1 for navigation page
        itemBuilder: (context, index) {
          final imageUrls = state.content?.imageUrls ?? [];

          // If this is the last item, show navigation page
          if (index >= imageUrls.length) {
            return ReaderNavigationPage(
              hasPreviousChapter: state.chapterData?.prevChapterId != null,
              hasNextChapter: state.chapterData?.nextChapterId != null,
              onPreviousChapter: () => _readerCubit.loadPreviousChapter(),
              onNextChapter: () => _readerCubit.loadNextChapter(),
              contentId: state.content?.id,
            );
          }

          final imageUrl = imageUrls[index];
          final pageNumber = index + 1;

          return _buildImageViewer(imageUrl, pageNumber);
        },
      ),
    );
  }

  Widget _buildVerticalPageReader(ReaderState state) {
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
          final newPage = index + 1;

          debugPrint(
              '� Vertical PageView changed to index=$index (page $newPage)');

          // Only handle UI tasks, no navigation logic
          // This prevents recursive loops with jumpToPage
          final imageUrls = state.content?.imageUrls ?? [];
          _prefetchImages(newPage, imageUrls, state.imageMetadata);

          // Update ReaderCubit state to reflect the current page without triggering navigation
          if (!_isProgrammaticAnimation) {
            // Only update state if this was a real user swipe
            _readerCubit.updateCurrentPageFromSwipe(newPage);
          }
        },
        itemCount: (state.content?.imageUrls.length ?? 0) +
            1, // +1 for navigation page
        itemBuilder: (context, index) {
          final imageUrls = state.content?.imageUrls ?? [];

          // If this is the last item, show navigation page
          if (index >= imageUrls.length) {
            return ReaderNavigationPage(
              hasPreviousChapter: state.chapterData?.prevChapterId != null,
              hasNextChapter: state.chapterData?.nextChapterId != null,
              onPreviousChapter: () => _readerCubit.loadPreviousChapter(),
              onNextChapter: () => _readerCubit.loadNextChapter(),
              contentId: state.content?.id,
            );
          }

          final imageUrl = imageUrls[index];
          return _buildImageViewer(imageUrl, index + 1);
        },
      ),
    );
  }

  Widget _buildContinuousReader(ReaderState state) {
    // 🐛 BUG FIX: Remove GestureDetector wrapper to prevent scroll gesture conflicts
    // GestureDetector blocks ListView scroll gestures, causing:
    // 1. Unable to scroll down
    // 2. Unable to scroll back to top from bottom
    // For continuous scroll mode, UI toggle is available via top bar only

    // 🚀 OPTIMIZATION: Get enableZoom once outside itemBuilder to avoid BlocBuilder in ListView
    final enableZoom = state.enableZoom ?? true;

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(), // Smoother scroll
      cacheExtent:
          1000.0, // 🐛 FIX: Keep 1000px of items in memory to prevent re-loading images
      itemCount:
          (state.content?.imageUrls.length ?? 0) + 1, // +1 for navigation page
      itemBuilder: (context, index) {
        final imageUrls = state.content?.imageUrls ?? [];

        // If this is the last item, show navigation page
        if (index >= imageUrls.length) {
          return SizedBox(
            height:
                MediaQuery.of(context).size.height * 0.8, // Give it some height
            child: ReaderNavigationPage(
              hasPreviousChapter: state.chapterData?.prevChapterId != null,
              hasNextChapter: state.chapterData?.nextChapterId != null,
              onPreviousChapter: () => _readerCubit.loadPreviousChapter(),
              onNextChapter: () => _readerCubit.loadNextChapter(),
              contentId: state.content?.id,
            ),
          );
        }

        final imageUrl = imageUrls[index];
        return _buildImageViewer(
          imageUrl,
          index + 1,
          isContinuous: true,
          enableZoom: enableZoom,
        );
      },
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
        // margin: const EdgeInsets.only(bottom: 8.0), // REMOVED GAP
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
                      Text(
                        AppLocalizations.of(context)?.pageOfPages(
                                state.currentPage ?? 1,
                                state.content?.pageCount ?? 1) ??
                            'Page ${state.currentPage ?? 1} of ${state.content?.pageCount ?? 1}',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          Row(
            children: [
              Text(
                '${state.currentPage ?? 1}',
                style: TextStyleConst.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: state.progress,
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
                  Icons.skip_previous,
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
                '${state.progressPercentage}%',
                style: TextStyleConst.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              // Next page
              IconButton(
                onPressed:
                    state.isLastPage ? null : () => _readerCubit.nextPage(),
                icon: Icon(
                  Icons.skip_next,
                  color: state.isLastPage
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.38)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
