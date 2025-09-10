import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../data/models/reader_settings_model.dart';
import '../../../domain/entities/content.dart';
import '../../../services/local_image_preloader.dart';
import '../../cubits/reader/reader_cubit.dart';
// import '../../cubits/reader/reader_state.dart';
import '../../widgets/progress_indicator_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/progressive_image_widget.dart';

/// Simple reader screen for reading manga/doujinshi content
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.contentId,
    this.initialPage = 1,
  });

  final String contentId;
  final int initialPage;

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

  // Prefetching tracking
  static const int _prefetchCount = 5; // Number of pages to prefetch ahead
  final Set<int> _prefetchedPages = {}; // Track which pages have been prefetched

  // 🚀 OPTIMIZATION: Preload content before BlocProvider setup
  Content? _preloadedContent;
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _verticalPageController =
        PageController(initialPage: widget.initialPage - 1);
    _scrollController = ScrollController();
    _readerCubit = getIt<ReaderCubit>();

    // Add scroll listener for continuous mode
    _scrollController.addListener(_onScrollChanged);

    // 🚀 OPTIMIZATION: Start preloading content immediately
    _startPreloading();
  }

  /// 🚀 OPTIMIZATION: Preload content to reduce initial loading time
  Future<void> _startPreloading() async {
    if (_isPreloading) return;

    _isPreloading = true;
    try {
      // Quick offline check first
      final offlineManager = getIt<OfflineContentManager>();
      final isOfflineAvailable = await offlineManager.isContentAvailableOffline(widget.contentId);

      if (isOfflineAvailable) {
        // Preload offline content
        _preloadedContent = await offlineManager.createOfflineContent(widget.contentId);
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
      // Calculate current page based on scroll position
      final screenHeight = MediaQuery.of(context).size.height;
      final approximateItemHeight =
          screenHeight * 0.9; // Slightly larger for better detection
      final currentScrollPage =
          (_scrollController.offset / approximateItemHeight).round() + 1;
      final clampedPage = currentScrollPage.clamp(1, state.content!.pageCount);

      // Only update if page actually changed and different from last reported
      if (clampedPage != _lastReportedPage &&
          clampedPage != (state.currentPage ?? 1)) {
        _lastReportedPage = clampedPage;
        _readerCubit.jumpToPage(clampedPage);
        
        // Trigger prefetching for continuous scroll mode too
        final imageUrls = state.content?.imageUrls ?? [];
        _prefetchImages(clampedPage, imageUrls);
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
  void _prefetchImages(int currentPage, List<String> imageUrls) {
    if (imageUrls.isEmpty) return;
    
    // Prefetch next _prefetchCount pages
    for (int i = 1; i <= _prefetchCount; i++) {
      final targetPage = currentPage + i;
      
      // Check bounds and avoid duplicate prefetching
      if (targetPage <= imageUrls.length && !_prefetchedPages.contains(targetPage)) {
        _prefetchedPages.add(targetPage);
        
        final imageUrl = imageUrls[targetPage - 1]; // Convert to 0-based index
        
        // Prefetch in background (non-blocking)
        LocalImagePreloader.downloadAndCacheImage(
          imageUrl,
          widget.contentId,
          targetPage,
        ).then((_) {
          if (mounted) {
            // Optionally log success for debugging
            debugPrint('📥 Prefetched page $targetPage');
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
    final currentPage = state.currentPage ?? 1;
    final targetPageIndex = currentPage - 1;

    // Sync PageController for horizontal single page mode
    if (state.readingMode == ReadingMode.singlePage) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetPageIndex) {
        _pageController.animateToPage(
          targetPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    // Sync PageController for vertical page mode
    else if (state.readingMode == ReadingMode.verticalPage) {
      if (_verticalPageController.hasClients &&
          _verticalPageController.page?.round() != targetPageIndex) {
        _verticalPageController.animateToPage(
          targetPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
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
    return BlocProvider<ReaderCubit>(
      create: (context) {
        // 🚀 OPTIMIZATION: Use preloaded content if available
        if (_preloadedContent != null) {
          // Create cubit with preloaded content
          final cubit = _readerCubit;
          // Skip full loadContent if we have preloaded content
          Future.microtask(() => _loadWithPreloadedContent(cubit));
          return cubit;
        } else {
          // Normal loading path
          return _readerCubit
            ..loadContent(
              widget.contentId,
              initialPage: widget.initialPage,
            );
        }
      },
      child: BlocListener<ReaderCubit, ReaderState>(
        listener: (context, state) {
          _syncControllersWithState(state);

          // Trigger initial prefetching when content is loaded
          if (state.content != null && state.content!.imageUrls.isNotEmpty) {
            final currentPage = state.currentPage ?? widget.initialPage;
            _prefetchImages(currentPage, state.content!.imageUrls);
          }
        },
        child: BlocBuilder<ReaderCubit, ReaderState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: _buildBody(state),
            );
          },
        ),
      ),
    );
  }

  /// 🚀 OPTIMIZATION: Load content using preloaded data
  Future<void> _loadWithPreloadedContent(ReaderCubit cubit) async {
    try {
      // Use normal loadContent but with preloaded data hint
      // The cubit will detect and use the preloaded content
      await cubit.loadContent(
        widget.contentId,
        initialPage: widget.initialPage,
      );

    } catch (e) {
      // Fallback to normal loading if preload fails
      debugPrint('Preload optimization failed, using normal loading: $e');
      await cubit.loadContent(widget.contentId, initialPage: widget.initialPage);
    }
  }

  Widget _buildBody(ReaderState state) {
    if (state is ReaderLoading) {
      return Center(
        child: AppProgressIndicator(
          message: AppLocalizations.of(context)?.loadingContent ?? 'Loading content...',
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
          _readerCubit.jumpToPage(newPage);
          
          // Trigger prefetching for next pages
          final imageUrls = state.content?.imageUrls ?? [];
          _prefetchImages(newPage, imageUrls);
        },
        itemCount: state.content?.imageUrls.length ?? 0,
        itemBuilder: (context, index) {
          final imageUrl = state.content?.imageUrls[index] ?? '';
          return _buildImageViewer(imageUrl, index + 1);
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
          _readerCubit.jumpToPage(newPage);
          
          // Trigger prefetching for next pages
          final imageUrls = state.content?.imageUrls ?? [];
          _prefetchImages(newPage, imageUrls);
        },
        itemCount: state.content?.imageUrls.length ?? 0,
        itemBuilder: (context, index) {
          final imageUrl = state.content?.imageUrls[index] ?? '';
          return _buildImageViewer(imageUrl, index + 1);
        },
      ),
    );
  }

  Widget _buildContinuousReader(ReaderState state) {
    return GestureDetector(
      onTapUp: (details) {
        _readerCubit.toggleUI();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(), // Smoother scroll
        itemCount: state.content?.imageUrls.length ?? 0,
        itemBuilder: (context, index) {
          final imageUrl = state.content?.imageUrls[index] ?? '';
          return _buildImageViewer(imageUrl, index + 1, isContinuous: true);
        },
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl, int pageNumber,
      {bool isContinuous = false}) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        final isOffline = state.isOfflineMode ?? false;

        if (isContinuous) {
          // For continuous scroll, use a simple image with InteractiveViewer
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: _buildImageWidget(
                imageUrl,
                pageNumber,
                isOffline,
                fit: BoxFit.fitWidth,
                height: MediaQuery.of(context).size.height * 0.8,
              ),
            ),
          );
        } else {
          // For single page, use PhotoView for offline files or CachedNetworkImage for online
          if (isOffline) {
            return PhotoView.customChild(
              backgroundDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
              child: ProgressiveReaderImageWidget(
                key: ValueKey('photo_image_1_${widget.contentId}_$pageNumber'),
                networkUrl: imageUrl,
                contentId: widget.contentId,
                pageNumber: pageNumber,
              ),
            );
          } else {
            return PhotoView.customChild(
              backgroundDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
              child: ProgressiveReaderImageWidget(
                key: ValueKey('photo_image_2_${widget.contentId}_$pageNumber'),
                networkUrl: imageUrl,
                contentId: widget.contentId,
                pageNumber: pageNumber,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildImageWidget(
    String imageUrl,
    int pageNumber,
    bool isOffline, {
    BoxFit? fit,
    double? height,
  }) {
    // Use ProgressiveReaderImageWidget for enhanced local file support
    return ProgressiveReaderImageWidget(
      key: ValueKey('image_${widget.contentId}_$pageNumber'),
      networkUrl: imageUrl,
      contentId: widget.contentId,
      pageNumber: pageNumber,
      fit: fit ?? BoxFit.contain,
      height: height,
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
                        state.content?.getDisplayTitle() ?? AppLocalizations.of(context)?.loading ?? 'Loading...',
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
                              color: Theme.of(context).colorScheme.primary, width: 1),
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
                              (AppLocalizations.of(context)?.offline ?? 'OFFLINE').toUpperCase(),
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
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)?.pageOfPages(state.currentPage ?? 1, state.content?.pageCount ?? 1) ?? 'Page ${state.currentPage ?? 1} of ${state.content?.pageCount ?? 1}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Show progress bar in continuous scroll mode
                    if (state.readingMode == ReadingMode.continuousScroll) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${state.progressPercentage}%)',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                // Progress bar for continuous scroll mode
                if (state.readingMode == ReadingMode.continuousScroll)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary),
                      minHeight: 2,
                    ),
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
            icon:
                Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
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
                  backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),

              // Page info and jump
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _showPageJumpDialog(state),
                    child: Text(
                      '${state.progressPercentage}%',
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${(state.readingTimer ?? Duration.zero).inMinutes}m',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Next page
              IconButton(
                onPressed:
                    state.isLastPage ? null : () => _readerCubit.nextPage(),
                icon: Icon(
                  Icons.skip_next,
                  color: state.isLastPage
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                _readerCubit.jumpToPage(page);
                _pageController.animateToPage(
                  page - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                AppLocalizations.of(context)?.readerSettings ?? 'Reader Settings',
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
                  AppLocalizations.of(context)?.keepScreenOn ?? 'Keep Screen On',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)?.keepScreenOnDescription ?? 'Prevent screen from turning off while reading',
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
                    AppLocalizations.of(context)?.resetToDefaults ?? 'Reset to Defaults',
                    style: TextStyleConst.buttonMedium.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
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
        return AppLocalizations.of(context)?.horizontalPages ?? 'Horizontal Pages';
      case ReadingMode.verticalPage:
        return AppLocalizations.of(context)?.verticalPages ?? 'Vertical Pages';
      case ReadingMode.continuousScroll:
        return AppLocalizations.of(context)?.continuousScroll ?? 'Continuous Scroll';
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
              AppLocalizations.of(context)?.readerSettingsResetSuccess ?? 'Reader settings have been reset to defaults.'  ,
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
              AppLocalizations.of(context)?.failedToResetSettings(e.toString()) ?? 'Failed to reset settings: ${e.toString()}'  ,
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
              label: AppLocalizations.of(context)?.retry ?? 'Retry' ,
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _resetReaderSettings(),
            ),
          ),
        );
      }
    }
  }
}
