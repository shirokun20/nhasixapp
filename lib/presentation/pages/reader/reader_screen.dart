import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/constants/colors_const.dart';
import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/reader_settings_model.dart';
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
      create: (context) => _readerCubit
        ..loadContent(
          widget.contentId,
          initialPage: widget.initialPage,
        ),
      child: BlocListener<ReaderCubit, ReaderState>(
        listener: (context, state) {
          _syncControllersWithState(state);
        },
        child: BlocBuilder<ReaderCubit, ReaderState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: ColorsConst.darkBackground,
              body: _buildBody(state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ReaderState state) {
    if (state is ReaderLoading) {
      return const Center(
        child: AppProgressIndicator(
          message: 'Loading content...',
        ),
      );
    }

    if (state is ReaderError) {
      return Center(
        child: AppErrorWidget(
          title: 'Loading Error',
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
              backgroundDecoration: const BoxDecoration(
                color: ColorsConst.darkBackground,
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
              backgroundDecoration: const BoxDecoration(
                color: ColorsConst.darkBackground,
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
        color: ColorsConst.darkSurface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back,
                color: ColorsConst.darkTextPrimary),
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
                        state.content?.getDisplayTitle() ?? 'Loading...',
                        style: TextStyleConst.headingMedium.copyWith(
                          color: ColorsConst.darkTextPrimary,
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
                          color: ColorsConst.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: ColorsConst.accentGreen, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.offline_bolt,
                              size: 12,
                              color: ColorsConst.accentGreen,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'OFFLINE',
                              style: TextStyleConst.bodySmall.copyWith(
                                color: ColorsConst.accentGreen,
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
                      'Page ${state.currentPage ?? 1} of ${state.content?.pageCount ?? 1}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.darkTextSecondary,
                      ),
                    ),
                    // Show progress bar in continuous scroll mode
                    if (state.readingMode == ReadingMode.continuousScroll) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${state.progressPercentage}%)',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: ColorsConst.accentBlue,
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
                      backgroundColor: ColorsConst.borderMuted,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          ColorsConst.accentBlue),
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
              color: ColorsConst.darkTextPrimary,
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
                  ? ColorsConst.accentBlue
                  : ColorsConst.darkTextPrimary,
            ),
          ),

          // Settings button
          IconButton(
            onPressed: () => _showReaderSettings(state),
            icon:
                const Icon(Icons.settings, color: ColorsConst.darkTextPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ReaderState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.darkSurface.withValues(alpha: 0.9),
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
                  color: ColorsConst.darkTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: ColorsConst.borderMuted,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      ColorsConst.accentBlue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.content?.pageCount ?? 1}',
                style: TextStyleConst.bodySmall.copyWith(
                  color: ColorsConst.darkTextSecondary,
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
                      ? ColorsConst.darkTextTertiary
                      : ColorsConst.darkTextPrimary,
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
                        color: ColorsConst.accentBlue,
                      ),
                    ),
                  ),
                  Text(
                    '${(state.readingTimer ?? Duration.zero).inMinutes}m',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: ColorsConst.darkTextSecondary,
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
                      ? ColorsConst.darkTextTertiary
                      : ColorsConst.darkTextPrimary,
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
        backgroundColor: ColorsConst.darkSurface,
        title: Text(
          'Jump to Page',
          style: TextStyleConst.headingMedium.copyWith(
            color: ColorsConst.darkTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyleConst.bodyMedium.copyWith(
            color: ColorsConst.darkTextPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Page (1-${state.content?.pageCount ?? 1})',
            labelStyle: TextStyleConst.bodyMedium.copyWith(
              color: ColorsConst.darkTextSecondary,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: ColorsConst.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ColorsConst.accentBlue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyleConst.buttonMedium.copyWith(
                color: ColorsConst.darkTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
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
                Navigator.of(context).pop();
              }
            },
            child: Text(
              'Jump',
              style: TextStyleConst.buttonMedium.copyWith(
                color: ColorsConst.accentBlue,
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
      backgroundColor: ColorsConst.darkSurface,
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
                  color: ColorsConst.darkTextTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                'Reader Settings',
                style: TextStyleConst.headingMedium.copyWith(
                  color: ColorsConst.darkTextPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // Reading mode
              ListTile(
                title: Text(
                  'Reading Mode',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                ),
                subtitle: Text(
                  _getReadingModeLabel(
                      currentState.readingMode ?? ReadingMode.singlePage),
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextSecondary,
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
                    color: ColorsConst.accentBlue,
                  ),
                ),
              ),

              // Keep screen on
              ListTile(
                title: Text(
                  'Keep Screen On',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                ),
                subtitle: Text(
                  'Prevent screen from turning off while reading',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextSecondary,
                  ),
                ),
                trailing: Switch(
                  value: currentState.keepScreenOn ?? false,
                  onChanged: (_) => _readerCubit.toggleKeepScreenOn(),
                  activeThumbColor: ColorsConst.accentBlue,
                ),
              ),

              const SizedBox(height: 24),

              // Reset settings button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showResetConfirmationDialog(),
                  icon: const Icon(
                    Icons.restore,
                    color: ColorsConst.accentRed,
                  ),
                  label: Text(
                    'Reset to Defaults',
                    style: TextStyleConst.buttonMedium.copyWith(
                      color: ColorsConst.accentRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ColorsConst.accentRed),
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
        return 'Horizontal Pages';
      case ReadingMode.verticalPage:
        return 'Vertical Pages';
      case ReadingMode.continuousScroll:
        return 'Continuous Scroll';
    }
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsConst.darkSurface,
        title: Text(
          'Reset Reader Settings',
          style: TextStyleConst.headingMedium.copyWith(
            color: ColorsConst.darkTextPrimary,
          ),
        ),
        content: Text(
          'This will reset all reader settings to their default values:\n\n'
          '• Reading Mode: Horizontal Pages\n'
          '• Keep Screen On: Off\n'
          '• Show UI: On\n\n'
          'Are you sure you want to continue?',
          style: TextStyleConst.bodyMedium.copyWith(
            color: ColorsConst.darkTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyleConst.buttonMedium.copyWith(
                color: ColorsConst.darkTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetReaderSettings();
            },
            child: Text(
              'Reset',
              style: TextStyleConst.buttonMedium.copyWith(
                color: ColorsConst.accentRed,
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
              'Reader settings have been reset to defaults',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextPrimary,
              ),
            ),
            backgroundColor: ColorsConst.accentGreen,
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
              'Failed to reset settings: ${e.toString()}',
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextPrimary,
              ),
            ),
            backgroundColor: ColorsConst.accentRed,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: ColorsConst.darkTextPrimary,
              onPressed: () => _resetReaderSettings(),
            ),
          ),
        );
      }
    }
  }
}
