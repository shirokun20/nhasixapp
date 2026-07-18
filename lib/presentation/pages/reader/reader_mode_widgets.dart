part of 'reader_screen.dart';

// ───── _PaginatedTapWrapper ─────

class _PaginatedTapWrapper extends StatefulWidget {
  const _PaginatedTapWrapper({
    required this.child,
    required this.state,
    required this.cubit,
  });

  final Widget child;
  final ReaderState state;
  final ReaderCubit cubit;

  @override
  State<_PaginatedTapWrapper> createState() => _PaginatedTapWrapperState();
}

class _PaginatedTapWrapperState extends State<_PaginatedTapWrapper> {
  Offset _tapDownPosition = Offset.zero;
  DateTime _tapDownTime = DateTime.now();

  bool _isNextTap(double tapX, double screenWidth, TapDirection tapDirection) {
    final isRightSide = tapX > screenWidth * 0.7;
    return tapDirection == TapDirection.inverted ? !isRightSide : isRightSide;
  }

  bool _isPrevTap(double tapX, double screenWidth, TapDirection tapDirection) {
    final isLeftSide = tapX < screenWidth * 0.3;
    return tapDirection == TapDirection.inverted ? !isLeftSide : isLeftSide;
  }

  bool _isTapInsideChrome(Offset position) {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return position.dy <= topInset + 64 ||
        position.dy >= size.height - bottomInset - 76;
  }

  void _handlePaginatedTap(Offset position) {
    final state = widget.state;
    final cubit = widget.cubit;
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
        cubit.previousPage();
      } else if (nextArea) {
        cubit.nextPage();
      } else {
        cubit.toggleUI();
      }
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    if (_isPrevTap(position.dx, screenWidth, tapDir)) {
      cubit.previousPage();
    } else if (_isNextTap(position.dx, screenWidth, tapDir)) {
      cubit.nextPage();
    } else {
      cubit.toggleUI();
    }
  }

  @override
  Widget build(BuildContext context) {
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

        if ((widget.state.showUI ?? false) &&
            _isTapInsideChrome(event.position)) {
          return;
        }

        _handlePaginatedTap(event.position);
      },
      child: widget.child,
    );
  }
}

// ───── _ReaderContentWidget ─────

class _ReaderContentWidget extends StatefulWidget {
  const _ReaderContentWidget({
    required this.state,
    required this.cubit,
    required this.pageController,
    required this.verticalPageController,
    required this.scrollController,
    required this.visiblePageNotifier,
    required this.animatedPauseNotifier,
    required this.scrollingNotifier,
    required this.contentId,
    required this.chapterOverlayShown,
    required this.isProgrammaticAnimation,
    required this.logger,
    required this.onHeavyImageDetected,
    required this.onContinuousImageLoaded,
    required this.onRepairBrokenImage,
    required this.onOpenSourcePageForRepair,
    required this.onScrollNotification,
    required this.onShowSettings,
    required this.onDismissChapterOverlay,
    required this.prefetchImages,
    required this.evictDistantPages,
    required this.resolveContinuousItemHeight,
    required this.isHeavyPrefetchSource,
    required this.isContinuousScrollDisabled,
    required this.getNextReadingMode,
  });

  final ReaderState state;
  final ReaderCubit cubit;
  final PageController pageController;
  final PageController verticalPageController;
  final ScrollController scrollController;
  final ValueNotifier<int> visiblePageNotifier;
  final ValueNotifier<int> animatedPauseNotifier;
  final ValueNotifier<bool> scrollingNotifier;
  final String contentId;
  final bool chapterOverlayShown;
  final bool isProgrammaticAnimation;
  final Logger logger;
  final VoidCallback onHeavyImageDetected;
  final void Function(int, Size) onContinuousImageLoaded;
  final Future<bool> Function(int) onRepairBrokenImage;
  final Future<bool> Function(int) onOpenSourcePageForRepair;
  final void Function(ScrollUpdateNotification, ReaderState)
      onScrollNotification;
  final void Function(ReaderState) onShowSettings;
  final VoidCallback onDismissChapterOverlay;
  final void Function(int, List<String>, List<ImageMetadata>?,
      {String? sourceId}) prefetchImages;
  final void Function(int, List<String>, {bool isOffline}) evictDistantPages;
  final double Function(int, double) resolveContinuousItemHeight;
  final bool Function(String?) isHeavyPrefetchSource;
  final bool Function() isContinuousScrollDisabled;
  final ReadingMode Function(ReadingMode,
      {required bool disableContinuousScroll}) getNextReadingMode;

  @override
  State<_ReaderContentWidget> createState() => _ReaderContentWidgetState();
}

class _ReaderContentWidgetState extends State<_ReaderContentWidget> {
  Offset _tapDownPosition = Offset.zero;
  DateTime _tapDownTime = DateTime.now();

  Widget _buildChapterNavigationPage({VoidCallback? onGoToFirstPage}) {
    final hasPrevChapter = widget.cubit.hasPreviousChapter;
    final hasNextChapter = widget.cubit.hasNextChapter;
    final isChapterMode = widget.state.chapterData != null ||
        widget.state.currentChapter != null ||
        hasPrevChapter ||
        hasNextChapter;

    return EndOfChapterOverlay(
      state: widget.state,
      isChapterMode: isChapterMode,
      isOfflineMode: widget.state.isOfflineMode ?? false,
      onBackToDetail: () => context.pop(),
      onPreviousChapter:
          hasPrevChapter ? () => widget.cubit.loadPreviousChapter() : null,
      onNextChapter:
          hasNextChapter ? () => widget.cubit.loadNextChapter() : null,
      onGoToFirstPage: onGoToFirstPage,
    );
  }

  Widget _buildSinglePageReader({bool showNavigation = false}) {
    final state = widget.state;
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    widget.logger.d(
        '📖 SinglePageReader: pageCount=$pageCount, showNavigation=$showNavigation, totalItems=$totalItems');

    return PageView.builder(
      key: const ValueKey('horizontal_page_view'),
      controller: widget.pageController,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      onPageChanged: (index) {
        final reportPage = index + 1;
        widget.visiblePageNotifier.value = reportPage;
        widget.animatedPauseNotifier.value = reportPage;

        widget.logger.d(
            '📖 VerticalPageView changed to index=$index (reporting page $reportPage)');

        final imageUrls = state.content?.imageUrls ?? [];
        if (index < pageCount) {
          if (state.readingMode != ReadingMode.singlePage &&
              state.readingMode != ReadingMode.verticalPage) {
            widget.prefetchImages(reportPage, imageUrls, state.imageMetadata,
                sourceId: state.content?.sourceId);
          }
        }

        widget.cubit.updateCurrentPageFromSwipe(reportPage);
      },
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (showNavigation && index == pageCount) {
          return _buildChapterNavigationPage();
        }
        final imageUrl = state.content?.imageUrls[index] ?? '';
        final pageNumber = index + 1;

        return _ReaderImageViewer(
          imageUrl: imageUrl,
          pageNumber: pageNumber,
          contentId: widget.contentId,
          visiblePageNotifier: widget.animatedPauseNotifier,
          cubit: widget.cubit,
          onHeavyImageDetected: widget.onHeavyImageDetected,
          onRepairBrokenImage: widget.onRepairBrokenImage,
          onOpenSourcePageForRepair: widget.onOpenSourcePageForRepair,
        );
      },
    );
  }

  Widget _buildVerticalPageReader({bool showNavigation = false}) {
    final state = widget.state;
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    widget.logger.d(
        '📖 VerticalPageReader: pageCount=$pageCount, showNavigation=$showNavigation, totalItems=$totalItems');

    return PageView.builder(
      key: const ValueKey('vertical_page_view'),
      controller: widget.verticalPageController,
      scrollDirection: Axis.vertical,
      clipBehavior: Clip.none,
      onPageChanged: (index) {
        final reportPage = index + 1;
        widget.visiblePageNotifier.value = reportPage;
        widget.animatedPauseNotifier.value = reportPage;

        widget.logger.d(
            '📖 Vertical PageView changed to index=$index (reporting page $reportPage)');

        final imageUrls = state.content?.imageUrls ?? [];
        if (index < pageCount) {
          widget.prefetchImages(reportPage, imageUrls, state.imageMetadata,
              sourceId: state.content?.sourceId);
          widget.evictDistantPages(reportPage, imageUrls,
              isOffline: state.isOfflineMode ?? false);
        }

        if (!widget.isProgrammaticAnimation) {
          widget.cubit.updateCurrentPageFromSwipe(reportPage);
        }
      },
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (showNavigation && index == pageCount) {
          return _buildChapterNavigationPage();
        }
        final imageUrl = state.content?.imageUrls[index] ?? '';
        final pageNumber = index + 1;
        return _ReaderImageViewer(
          imageUrl: imageUrl,
          pageNumber: pageNumber,
          contentId: widget.contentId,
          visiblePageNotifier: widget.animatedPauseNotifier,
          cubit: widget.cubit,
          sourceId: state.content?.sourceId,
          onHeavyImageDetected: widget.onHeavyImageDetected,
          onRepairBrokenImage: widget.onRepairBrokenImage,
          onOpenSourcePageForRepair: widget.onOpenSourcePageForRepair,
        );
      },
    );
  }

  Widget _buildContinuousReader({bool showNavigation = false}) {
    final state = widget.state;
    final pageCount = state.content?.imageUrls.length ?? 0;
    final totalItems = showNavigation ? pageCount + 1 : pageCount;

    final enableZoom = state.enableZoom ?? true;
    final isHeavySource = widget.isHeavyPrefetchSource(state.content?.sourceId);
    final viewportHeight = MediaQuery.of(context).size.height;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _tapDownPosition = event.position;
        _tapDownTime = DateTime.now();
      },
      onPointerUp: (event) {
        final distance = (event.position - _tapDownPosition).distance;
        final duration = DateTime.now().difference(_tapDownTime);
        if (distance < 20 && duration.inMilliseconds < 300) {
          final screenHeight = MediaQuery.of(context).size.height;
          final tapY = event.position.dy;
          if (tapY > screenHeight * 0.2 && tapY < screenHeight * 0.8) {
            widget.cubit.toggleUI();
          }
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            widget.onScrollNotification(notification, state);
          }
          return false;
        },
        child: ListView.builder(
          scrollCacheExtent: ScrollCacheExtent.pixels(
              isHeavySource ? viewportHeight * 0.25 : 2500.0),
          controller: widget.scrollController,
          physics: isHeavySource
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          addAutomaticKeepAlives: true,
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (showNavigation && index == pageCount) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildChapterNavigationPage(
                  onGoToFirstPage: () => widget.scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                ),
              );
            }

            final pageNumber = index + 1;
            final imageUrl = state.content?.imageUrls[index] ?? '';
            final resolvedHeight = widget.resolveContinuousItemHeight(
              pageNumber,
              viewportHeight,
            );
            return _ReaderImageViewer(
              imageUrl: imageUrl,
              pageNumber: pageNumber,
              contentId: widget.contentId,
              visiblePageNotifier: widget.animatedPauseNotifier,
              cubit: widget.cubit,
              isContinuous: true,
              enableZoom: enableZoom,
              sourceId: state.content?.sourceId,
              resolvedHeight: resolvedHeight,
              onHeavyImageDetected: widget.onHeavyImageDetected,
              onContinuousImageLoaded: widget.onContinuousImageLoaded,
              onRepairBrokenImage: widget.onRepairBrokenImage,
              onOpenSourcePageForRepair: widget.onOpenSourcePageForRepair,
            );
          },
        ),
      ),
    );
  }

  Widget _buildReaderContent() {
    final state = widget.state;
    final showNav =
        state.content != null && state.content!.imageUrls.isNotEmpty;

    final content = switch (state.readingMode ?? ReadingMode.singlePage) {
      ReadingMode.singlePage => _buildSinglePageReader(showNavigation: showNav),
      ReadingMode.verticalPage =>
        _buildVerticalPageReader(showNavigation: showNav),
      ReadingMode.continuousScroll =>
        _buildContinuousReader(showNavigation: showNav),
    };

    if ((state.readingMode ?? ReadingMode.singlePage) ==
        ReadingMode.continuousScroll) {
      return content;
    }

    return _PaginatedTapWrapper(
      state: state,
      cubit: widget.cubit,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final showOverlay = !widget.chapterOverlayShown && (state.content != null);

    return Stack(
      children: [
        _buildReaderContent(),
        _ReaderUIOverlay(
          isVisible: state.showUI ?? false,
          topBar: _ReaderTopBar(
            state: state,
            onBack: () => context.pop(),
            onToggleKeepScreenOn: widget.cubit.toggleKeepScreenOn,
            onOpenSettings: () => widget.onShowSettings(state),
          ),
          bottomBar: state.readingMode != ReadingMode.continuousScroll
              ? _ReaderBottomBar(
                  state: state,
                  onPrevPage: widget.cubit.previousPage,
                  onNextPage: widget.cubit.nextPage,
                  onJumpToPage: widget.cubit.jumpToPage,
                  onChangeReadingMode: () {
                    final newMode = widget.getNextReadingMode(
                      state.readingMode ?? ReadingMode.singlePage,
                      disableContinuousScroll:
                          widget.isContinuousScrollDisabled(),
                    );
                    widget.cubit.changeReadingMode(newMode);
                  },
                  disableContinuousScroll: widget.isContinuousScrollDisabled(),
                )
              : null,
        ),
        _ReaderMiniChromeToggle(
          isVisible: state.showUI ?? false,
          onToggle: widget.cubit.toggleUI,
        ),
        if (state.readingMode == ReadingMode.continuousScroll)
          _ReaderFloatingPageIndicator(
            scrollingNotifier: widget.scrollingNotifier,
            visiblePageNotifier: widget.visiblePageNotifier,
            totalPages: state.content?.pageCount ?? 0,
          ),
        if (showOverlay)
          ChapterOpenOverlay(
            title: state.content!.getDisplayTitle(),
            totalPages: state.content!.pageCount,
            onDismiss: widget.onDismissChapterOverlay,
          ),
      ],
    );
  }
}
