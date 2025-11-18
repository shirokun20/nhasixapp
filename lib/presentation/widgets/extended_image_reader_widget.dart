import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import '../../data/models/reader_settings_model.dart';

/// Enhanced image viewer widget optimized for manga/comic reading
/// with adaptive fitting and zoom-on-demand functionality.
///
/// Features:
/// - Adaptive BoxFit based on reading mode (fitWidth/fitHeight)
/// - Double-tap to zoom with smooth animation
/// - Visual zoom indicator when zoomed in
/// - No accidental zoom during page navigation
/// - Memory-efficient caching with Extended Image
class ExtendedImageReaderWidget extends StatefulWidget {
  const ExtendedImageReaderWidget({
    super.key,
    required this.imageUrl,
    required this.contentId,
    required this.pageNumber,
    required this.readingMode,
    this.enableZoom = true,
    this.onLoadError,
  });

  final String imageUrl;
  final String contentId;
  final int pageNumber;
  final ReadingMode readingMode;
  final bool enableZoom;
  final VoidCallback? onLoadError;

  @override
  State<ExtendedImageReaderWidget> createState() =>
      _ExtendedImageReaderWidgetState();
}

class _ExtendedImageReaderWidgetState extends State<ExtendedImageReaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  final GlobalKey<ExtendedImageGestureState> _gestureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // Initialize with dummy animation (will be replaced on double-tap)
    _zoomAnimation = _zoomController.drive(Tween<double>(begin: 1.0, end: 1.0));
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  /// Adaptive BoxFit based on reading mode for optimal reading comfort
  BoxFit _getAdaptiveBoxFit() {
    // Use BoxFit.contain for all modes to ensure proper centering
    // BoxFit.contain will:
    // 1. Fit the entire image within bounds
    // 2. Maintain aspect ratio
    // 3. Auto-center the image (critical for PageView)
    //
    // Note: fitWidth/fitHeight don't auto-center in PageView context,
    // causing images to stick to top-left corner
    return BoxFit.contain;

    /* Original adaptive strategy (caused centering issues):
    switch (widget.readingMode) {
      case ReadingMode.singlePage:
        return BoxFit.fitWidth; // Fill width, height auto (horizontal scroll)
      case ReadingMode.verticalPage:
        return BoxFit.fitHeight; // Fill height, width auto (vertical page)
      case ReadingMode.continuousScroll:
        return BoxFit.fitWidth; // Fill width for vertical scroll
    }
    */
  }

  /// Handle double-tap zoom gesture with smooth animation
  void _handleDoubleTap(ExtendedImageGestureState state) {
    if (!widget.enableZoom) return;

    final pointerDownPosition = state.pointerDownPosition;
    final double begin = state.gestureDetails!.totalScale!;
    final double end = begin > 1.5 ? 1.0 : 2.0; // Toggle between 1x and 2x

    // Remove old animation listener
    _zoomAnimation.removeListener(() {});

    // Stop and reset controller
    _zoomController.stop();
    _zoomController.reset();

    // Create new animation
    _zoomAnimation = _zoomController.drive(
      Tween<double>(begin: begin, end: end),
    );

    // Add listener for zoom animation
    void animationListener() {
      state.handleDoubleTap(
        scale: _zoomAnimation.value,
        doubleTapPosition: pointerDownPosition,
      );
    }

    _zoomAnimation.addListener(animationListener);

    // Start animation
    _zoomController.forward().then((_) {
      _zoomAnimation.removeListener(animationListener);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.imageUrl,
      key: ValueKey('extended_image_${widget.contentId}_${widget.pageNumber}'),
      fit: _getAdaptiveBoxFit(),
      mode: widget.enableZoom
          ? ExtendedImageMode.gesture
          : ExtendedImageMode.none,
      enableMemoryCache: true,
      clearMemoryCacheWhenDispose: false,
      cache: true,
      enableLoadState: true,
      extendedImageGestureKey: _gestureKey,
      initGestureConfigHandler: (state) {
        return GestureConfig(
          minScale: 1.0, // No zoom out - always at fit scale
          maxScale: 3.0, // Max 3x zoom for reading small text
          animationMinScale: 0.9, // Smooth bounce back animation
          animationMaxScale: 3.5,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: 1.0, // Start at fit scale (no zoom)
          inPageView: true, // Optimize for PageView usage
          cacheGesture: false, // Don't cache zoom state between pages
          initialAlignment: InitialAlignment.center,
        );
      },
      onDoubleTap: widget.enableZoom
          ? (ExtendedImageGestureState state) => _handleDoubleTap(state)
          : null,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return _buildLoadingIndicator(context);
          case LoadState.failed:
            return _buildErrorWidget(context, state);
          case LoadState.completed:
            return _buildCompletedImage(context, state);
        }
      },
    );
  }

  /// Build loading indicator with page number
  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading page ${widget.pageNumber}...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget with retry option
  Widget _buildErrorWidget(BuildContext context, ExtendedImageState state) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load page ${widget.pageNumber}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                state.reLoadImage();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build completed image with zoom indicator
  Widget _buildCompletedImage(BuildContext context, ExtendedImageState state) {
    // For gesture mode, use completedWidget which includes gesture handling
    // For non-gesture mode, use ExtendedRawImage directly
    final Widget imageWidget = widget.enableZoom
        ? state.completedWidget
        : ExtendedRawImage(
            image: state.extendedImageInfo?.image,
            fit: _getAdaptiveBoxFit(),
            alignment:
                Alignment.center, // Center the image vertically & horizontally
          );

    // Add zoom indicator overlay for gesture mode
    if (!widget.enableZoom) {
      return imageWidget;
    }

    // For gesture mode, wrap with listener to detect zoom level
    return AnimatedBuilder(
      animation: _zoomController,
      builder: (context, child) {
        // Try to get gesture state from the global key
        final gestureState = _gestureKey.currentState;
        final currentScale = gestureState?.gestureDetails?.totalScale ?? 1.0;
        final isZoomed = currentScale > 1.2;

        return Stack(
          alignment:
              Alignment.center, // Center all children (image + zoom indicator)
          children: [
            // Main image with gesture - wrap with Center for proper vertical alignment
            Center(child: imageWidget),

            // Zoom indicator (only show when zoomed AND not in continuous scroll mode)
            // In continuous scroll, per-image zoom is not relevant as multiple pages are visible
            if (isZoomed && widget.readingMode != ReadingMode.continuousScroll)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(currentScale * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
