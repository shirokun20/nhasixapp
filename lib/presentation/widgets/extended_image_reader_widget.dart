import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:logger/logger.dart';
import 'package:kuron_native/kuron_native.dart';
// import '../../core/utils/webtoon_detector.dart';
import '../../core/utils/reader_image_repair_utils.dart';
import '../../data/models/reader_settings_model.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';

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
    this.sourceId,
    this.sourceRawConfig,
    this.httpHeaders,
    this.enableZoom = true,
    this.onLoadError,
    this.onImageLoaded,
    this.visiblePageNotifier,
    this.onHeavyImageDetected,
    this.onRepairBrokenImage,
    this.onOpenSourcePageForRepair,
  });

  final String imageUrl;
  final String contentId;
  final int pageNumber;
  final ReadingMode readingMode;
  final String? sourceId;
  final Map<String, dynamic>? sourceRawConfig;
  final Map<String, String>? httpHeaders;
  final bool enableZoom;
  final VoidCallback? onLoadError;
  final Future<bool> Function()? onRepairBrokenImage;
  final Future<bool> Function()? onOpenSourcePageForRepair;

  /// 🎯 PHASE 1: Callback when image loads with actual dimensions
  final Function(int pageNumber, Size imageSize)? onImageLoaded;

  /// Called once (per content ID) when this page is identified as a heavy
  /// animated WebP (≥ 2 MB) while in continuous-scroll mode.
  ///
  /// The parent can use this to switch to single-page mode so that only one
  /// animation is rendered at a time, eliminating concurrent-decode jank.
  final VoidCallback? onHeavyImageDetected;

  /// Notifier that emits the currently visible page number.
  /// Forwarded to [AnimatedWebPView] to auto-pause off-screen animations.
  final ValueNotifier<int>? visiblePageNotifier;

  @override
  State<ExtendedImageReaderWidget> createState() =>
      _ExtendedImageReaderWidgetState();

  // ── Testing helpers ────────────────────────────────────────────────────────

  /// Directly adds a URL to the heavy-image static set.
  /// Only use in tests via `@visibleForTesting`.
  @visibleForTesting
  static void addHeavyUrlForTesting(String url) =>
      _ExtendedImageReaderWidgetState._heavyImageUrls.add(url);

  /// Returns whether [url] is currently in the heavy-image set.
  @visibleForTesting
  static bool isHeavyUrlForTesting(String url) =>
      _ExtendedImageReaderWidgetState._heavyImageUrls.contains(url);

  /// Clears the heavy-image set. Call in [tearDown] to isolate tests.
  @visibleForTesting
  static void clearHeavyUrlsForTesting() =>
      _ExtendedImageReaderWidgetState._heavyImageUrls.clear();

  /// Exposes the threshold constant for assertion in tests.
  @visibleForTesting
  static int get heavyImageThresholdBytesForTesting =>
      _ExtendedImageReaderWidgetState._heavyImageThresholdBytes;

  /// Exposes the ultra-heavy threshold used for more aggressive native
  /// animated-WebP downsampling.
  @visibleForTesting
  static int get ultraHeavyAnimatedImageThresholdBytesForTesting =>
      _ExtendedImageReaderWidgetState._ultraHeavyAnimatedImageThresholdBytes;

  /// Exposes the `_isLikelyAnimatedWebP` heuristic for unit testing
  /// without needing to build a full widget tree.
  @visibleForTesting
  static bool isLikelyAnimatedWebPForTesting({
    required String url,
    required bool isHeavy,
  }) {
    if (!isHeavy) return false;
    return _looksLikeAnimatedWebPUrl(url);
  }

  @visibleForTesting
  static bool shouldUseNativeAnimatedViewForTesting({
    required String url,
    required bool isHeavy,
    required bool nativeViewAvailable,
    bool confirmedAnimatedWebP = false,
  }) {
    if (!nativeViewAvailable || !isHeavy) return false;
    return confirmedAnimatedWebP || _looksLikeAnimatedWebPUrl(url);
  }

  @visibleForTesting
  static bool shouldAutoPlayAnimatedViewForTesting({
    required int pageNumber,
    int? visiblePageNumber,
  }) {
    return visiblePageNumber == null || visiblePageNumber == pageNumber;
  }

  @visibleForTesting
  static bool shouldKeepAliveForTesting({
    required ReadingMode readingMode,
    required bool isHeavy,
  }) {
    return readingMode != ReadingMode.continuousScroll || isHeavy;
  }

  @visibleForTesting
  static bool shouldClearMemoryCacheOnDisposeForTesting({
    required ReadingMode readingMode,
    required bool isHeavy,
    required bool isHeavyReaderSource,
  }) {
    return readingMode == ReadingMode.continuousScroll &&
        !(isHeavy || isHeavyReaderSource);
  }

  @visibleForTesting
  static int resolveNativeAnimatedDecodeWidthForTesting({
    required double logicalWidth,
    required double devicePixelRatio,
    int? imageBytes,
  }) {
    final viewportPx = logicalWidth * devicePixelRatio;
    final isUltraHeavy = imageBytes != null &&
        imageBytes >=
            _ExtendedImageReaderWidgetState
                ._ultraHeavyAnimatedImageThresholdBytes;
    final factor = isUltraHeavy ? 0.58 : 0.78;
    final capPx = isUltraHeavy ? 720.0 : 900.0;
    final minPx = viewportPx < 360.0 ? viewportPx : 360.0;
    final maxPx = viewportPx < capPx ? viewportPx : capPx;
    return (viewportPx * factor).clamp(minPx, maxPx).round();
  }

  static bool _looksLikeAnimatedWebPUrl(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.webp') || path.contains('-wbp');
  }

  @visibleForTesting
  static bool isAnimatedWebPHeaderForTesting(Uint8List bytes) =>
      _ExtendedImageReaderWidgetState._looksLikeAnimatedWebPHeader(bytes);

  @visibleForTesting
  static bool isSupportedImageHeaderForTesting(Uint8List bytes) =>
      inferImageExtension(bytes: bytes) != null;
}

class _ExtendedImageReaderWidgetState extends State<ExtendedImageReaderWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static final Logger _logger = Logger();
  static final Dio _ehentaiResolverDio = Dio(
    BaseOptions(
      responseType: ResponseType.plain,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  static final Map<String, String> _ehentaiResolvedImageCache =
      <String, String>{};
  static final Map<String, DateTime> _ehentaiResolvedImageCacheTime =
      <String, DateTime>{};
  static final Map<String, Future<String?>> _ehentaiResolveInFlight =
      <String, Future<String?>>{};
  static const Duration _ehentaiResolvedImageCacheTtl = Duration(minutes: 2);
  static final Map<String, double> _syntheticProgressByImageKey =
      <String, double>{};

  /// URLs identified as heavy/animated (large file size ≥ threshold).
  /// Persisted across widget rebuilds so keep-alive activates immediately
  /// when the widget is re-created after a scroll-back.
  static final Set<String> _heavyImageUrls = <String>{};

  /// Content IDs for which [onHeavyImageDetected] has already been fired.
  /// Prevents repeated callbacks when the same chapter is re-opened.
  static final Set<String> _notifiedHeavyContentIds = <String>{};

  /// Maps a heavy image URL → its extended_image disk-cache file path.
  /// Persisted so that when a widget is re-created (scroll-out → scroll-back)
  /// the native [AnimatedWebPView] can load from disk instead of re-downloading.
  static final Map<String, String> _cachedFilePathByUrl = <String, String>{};

  /// URLs confirmed to contain animated WebP bytes.
  /// Separate from [_heavyImageUrls] because some sources can pre-seed "heavy"
  /// based on payload size before the final file format is known.
  static final Set<String> _confirmedAnimatedWebPUrls = <String>{};

  /// Files ≥ 2 MB are treated as heavy (animated WebP, large scans, etc.).
  /// These are kept in memory between scroll-outs to avoid expensive re-decode.
  static const int _heavyImageThresholdBytes = 2 * 1024 * 1024; // 2 MB

  /// Files ≥ 10 MB get a more aggressive native target width because the
  /// offline reader otherwise pays twice: thumbnail prep + animated playback.
  static const int _ultraHeavyAnimatedImageThresholdBytes =
      10 * 1024 * 1024; // 10 MB

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  final GlobalKey<ExtendedImageGestureState> _gestureKey = GlobalKey();
  Future<String?>? _ehentaiResolvedImageFuture;
  String? _hitomiFallbackImageUrl;

  /// Whether this specific image URL has been identified as heavy/animated.
  /// Mirrors the static [_heavyImageUrls] set but as instance flag so that
  /// [wantKeepAlive], [clearMemoryCacheWhenDispose], and native-view routing
  /// are always in sync.
  bool _isHeavyImage = false;

  /// Whether this image was positively identified as animated WebP bytes,
  /// even if the source URL or local filename uses a misleading extension.
  bool _isConfirmedAnimatedWebP = false;

  /// Path to the extended_image disk-cache file for this URL.
  /// Populated after [LoadState.completed] via [getCachedImageFile].
  /// When set, the native [AnimatedWebPView] reads from disk (no re-download).
  String? _cachedFilePath;

  // 🔄 AUTO-RETRY: Track retry attempts for timeout/network errors
  int _imageLoadRetries = 0;
  static const int _maxImageLoadRetries = 3;
  int _ehentaiResolveRetries = 0;
  static const int _maxEhentaiResolveRetries = 2;
  Timer? _autoRetryTimer;
  Timer? _syntheticProgressTimer;
  double _syntheticProgressValue = 0.0;
  bool _isRepairingBrokenImage = false;
  bool _isOpeningSourcePage = false;
  bool _shouldBypassLocalDecode = false;

  String get _imageProgressKey => '${widget.contentId}_${widget.pageNumber}';

  // 🎯 PHASE 2: Cache loaded image size for webtoon detection
  // Size? _loadedImageSize;

  // Keep widget state alive for heavy/native images, but let normal pages in
  // continuous scroll recycle so long chapter scrolling stays lightweight.
  @override
  bool get wantKeepAlive => ExtendedImageReaderWidget.shouldKeepAliveForTesting(
        readingMode: widget.readingMode,
        isHeavy: _isHeavyImage,
      );

  bool _isLocalFilePath(String value) {
    return value.startsWith('/') ||
        value.startsWith('\\') ||
        value.startsWith('file://') ||
        (!value.startsWith('http://') && !value.startsWith('https://'));
  }

  String _normalizeLocalPath(String value) {
    if (value.startsWith('file://')) {
      return value.replaceFirst('file://', '');
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // Initialize with dummy animation (will be replaced on double-tap)
    _zoomAnimation = _zoomController.drive(Tween<double>(begin: 1.0, end: 1.0));

    _syntheticProgressValue =
        _syntheticProgressByImageKey[_imageProgressKey] ?? 0.0;

    // Restore heavy-image state from static maps so keep-alive and native-view
    // routing are applied immediately on the first build — and the native view
    // reads from disk instead of re-downloading on every scroll-back.
    _isHeavyImage = _heavyImageUrls.contains(widget.imageUrl);
    _isConfirmedAnimatedWebP =
        _confirmedAnimatedWebPUrls.contains(widget.imageUrl);
    _cachedFilePath = _cachedFilePathByUrl[widget.imageUrl];

    if (_isLocalFilePath(widget.imageUrl)) {
      final localPath = _normalizeLocalPath(widget.imageUrl);
      _cachedFilePath = localPath;
      _cachedFilePathByUrl[widget.imageUrl] = localPath;
      _shouldBypassLocalDecode = _hasInvalidLocalImagePayloadSync(localPath);
      if (!_shouldBypassLocalDecode) {
        _preCheckLocalFileForHeavySync(localPath);
      }
    }

    // Pre-check: for .webp URLs not yet identified as heavy, query the disk
    // cache BEFORE ExtendedImage gets a chance to decode. This catches images
    // that were downloaded in a previous reading session — we skip Flutter's
    // expensive raster-thread decode entirely and go straight to native view.
    if (!_isHeavyImage &&
        AnimatedWebPView.isAvailable &&
        !_isLocalFilePath(widget.imageUrl) &&
        _shouldInspectCachedFileForAnimatedWebP(widget.imageUrl)) {
      _preCheckDiskCacheForHeavy();
    }

    _prepareEhentaiResolveFuture();
  }

  /// Async disk-cache check: if a cached .webp file ≥ threshold exists,
  /// seed the static maps and trigger a rebuild to route straight to native.
  void _preCheckDiskCacheForHeavy() {
    getCachedImageFile(widget.imageUrl).then((file) {
      if (file == null) return;
      final size = file.lengthSync();
      if (size >= _heavyImageThresholdBytes &&
          _looksLikeAnimatedWebPFileSync(file)) {
        _markConfirmedAnimatedWebP(
          cacheKey: widget.imageUrl,
          cachedFilePath: file.path,
        );
        if (!mounted) return;
        setState(() {
          _isHeavyImage = true;
          _isConfirmedAnimatedWebP = true;
          _cachedFilePath = file.path;
        });
        updateKeepAlive();
        _logger.i(
          '[NativeWebP] Pre-check HIT: heavy WebP from disk cache '
          'page=${widget.pageNumber} '
          'size=${(size / 1024 / 1024).toStringAsFixed(1)} MB',
        );
        _maybeNotifyHeavyImageDetected();
      }
    }).catchError((Object e) {
      _logger.w('[NativeWebP] Pre-check error: $e');
    });
  }

  /// Sync pre-check for offline/local files so heavy animated WebP can route
  /// directly to native view on first build.
  void _preCheckLocalFileForHeavySync(String localPath) {
    if (!AnimatedWebPView.isAvailable) {
      return;
    }

    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        return;
      }

      final fileSize = file.lengthSync();
      if (fileSize < _heavyImageThresholdBytes ||
          !_looksLikeAnimatedWebPFileSync(file)) {
        return;
      }

      _markConfirmedAnimatedWebP(
        cacheKey: widget.imageUrl,
        cachedFilePath: localPath,
      );
      _isHeavyImage = true;
      _isConfirmedAnimatedWebP = true;
      _cachedFilePath = localPath;
      _logger.i(
        '[NativeWebP] Local pre-check HIT: heavy WebP '
        'page=${widget.pageNumber} '
        'size=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
      );
      _maybeNotifyHeavyImageDetected();
    } catch (e) {
      _logger.w('[NativeWebP] Local pre-check error: $e');
    }
  }

  /// Fire [widget.onHeavyImageDetected] at most once per content ID.
  /// Relevant for continuous-scroll mode regardless of page index.
  void _maybeNotifyHeavyImageDetected() {
    if (widget.onHeavyImageDetected == null) return;
    if (widget.readingMode != ReadingMode.continuousScroll) return;
    if (_notifiedHeavyContentIds.contains(widget.contentId)) return;
    _notifiedHeavyContentIds.add(widget.contentId);
    // postFrameCallback so we never call this during a build/layout phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onHeavyImageDetected?.call();
    });
  }

  /// Pre-seed the static set WITHOUT setState so an in-flight ExtendedImage
  /// download is never interrupted mid-way.
  void _preSeedHeavyImageUrl() {
    _heavyImageUrls.add(widget.imageUrl);
  }

  bool _isLikelyAnimatedUrl(String url) {
    if (_isConfirmedAnimatedWebP) {
      return true;
    }
    return ExtendedImageReaderWidget.isLikelyAnimatedWebPForTesting(
      url: url,
      isHeavy: _isHeavyImage,
    );
  }

  bool _shouldUseNativeAnimatedView(String url) {
    return ExtendedImageReaderWidget.shouldUseNativeAnimatedViewForTesting(
      url: url,
      isHeavy: _isHeavyImage,
      nativeViewAvailable: AnimatedWebPView.isAvailable,
      confirmedAnimatedWebP: _isConfirmedAnimatedWebP,
    );
  }

  bool get _shouldAutoPlayAnimatedView {
    return ExtendedImageReaderWidget.shouldAutoPlayAnimatedViewForTesting(
      pageNumber: widget.pageNumber,
      visiblePageNumber: widget.visiblePageNotifier?.value,
    );
  }

  @override
  void didUpdateWidget(covariant ExtendedImageReaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final sourceChanged = oldWidget.sourceId != widget.sourceId;
    final imageChanged = oldWidget.imageUrl != widget.imageUrl;

    if (sourceChanged || imageChanged) {
      _hitomiFallbackImageUrl = null;
      _ehentaiResolveRetries = 0;
      _prepareEhentaiResolveFuture();

      if (_isLocalFilePath(widget.imageUrl)) {
        final localPath = _normalizeLocalPath(widget.imageUrl);
        _cachedFilePath = localPath;
        _cachedFilePathByUrl[widget.imageUrl] = localPath;
        _shouldBypassLocalDecode = _hasInvalidLocalImagePayloadSync(localPath);
        if (!_shouldBypassLocalDecode) {
          _preCheckLocalFileForHeavySync(localPath);
        }
      } else {
        _shouldBypassLocalDecode = false;
      }
    }
  }

  void _markLocalDecodeAsBroken() {
    if (_shouldBypassLocalDecode) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _shouldBypassLocalDecode) {
        return;
      }

      setState(() {
        _shouldBypassLocalDecode = true;
      });
    });
  }

  void _retryBrokenLocalImage() {
    final localPath = _normalizeLocalPath(widget.imageUrl);
    final shouldBypass = _hasInvalidLocalImagePayloadSync(localPath);

    if (!mounted) {
      _shouldBypassLocalDecode = shouldBypass;
      return;
    }

    setState(() {
      _shouldBypassLocalDecode = shouldBypass;
    });

    if (!shouldBypass) {
      _preCheckLocalFileForHeavySync(localPath);
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _autoRetryTimer?.cancel();
    _syntheticProgressTimer?.cancel();
    super.dispose();
  }

  bool _hasRealByteProgress(ExtendedImageState state) {
    try {
      final dynamic progressEvent = (state as dynamic).loadingProgress;
      final dynamic loadedRaw = progressEvent?.cumulativeBytesLoaded;
      return loadedRaw is num && loadedRaw > 0;
    } catch (_) {
      return false;
    }
  }

  void _startSyntheticProgress() {
    if (_syntheticProgressTimer != null) return;

    if (_syntheticProgressValue <= 0.0) {
      _syntheticProgressValue = 0.05;
      _syntheticProgressByImageKey[_imageProgressKey] = _syntheticProgressValue;
    }

    _syntheticProgressTimer =
        Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (!mounted) {
        timer.cancel();
        _syntheticProgressTimer = null;
        return;
      }

      setState(() {
        // Slow down as it approaches completion to look natural.
        final step = _syntheticProgressValue > 0.9 ? 0.006 : 0.015;
        _syntheticProgressValue =
            (_syntheticProgressValue + step).clamp(0.05, 0.99);
        _syntheticProgressByImageKey[_imageProgressKey] =
            _syntheticProgressValue;
      });
    });
  }

  void _stopSyntheticProgress({bool reset = false}) {
    _syntheticProgressTimer?.cancel();
    _syntheticProgressTimer = null;
    if (reset) {
      _syntheticProgressValue = 0.0;
      _syntheticProgressByImageKey.remove(_imageProgressKey);
    } else {
      _syntheticProgressByImageKey[_imageProgressKey] = _syntheticProgressValue;
    }
  }

  /// Adaptive BoxFit based on reading mode and image type for optimal reading comfort.
  ///
  /// 🎯 PHASE 2: Automatically detects webtoon images and applies BoxFit.fitWidth
  /// for better vertical scrolling experience.
  BoxFit _getAdaptiveBoxFit() {
    // Check if image is loaded and detect webtoon
    // if (_loadedImageSize != null) {
    //   final isWebtoon = WebtoonDetector.isWebtoon(_loadedImageSize!);

    //   if (isWebtoon) {
    //     // Webtoon images: Use fitWidth to fill screen width
    //     // This allows full vertical scrolling without horizontal overflow
    //     debugPrint('🎨 Webtoon detected (page ${widget.pageNumber}): '
    //         'AR=${WebtoonDetector.getAspectRatio(_loadedImageSize!)?.toStringAsFixed(2)} '
    //         '→ Using BoxFit.fitWidth');
    //     return BoxFit.fitWidth;
    //   }
    // }

    // Normal images: Use BoxFit.contain for proper centering
    // BoxFit.contain will:
    // 1. Fit the entire image within bounds
    // 2. Maintain aspect ratio
    // 3. Auto-center the image (critical for PageView)
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
    // 🚀 OPTIMIZATION: Call super.build for AutomaticKeepAliveClientMixin
    super.build(context);

    final normalizedLocalPath = _normalizeLocalPath(widget.imageUrl);

    // Check if imageUrl is a local file path
    final isLocalFile = _isLocalFilePath(widget.imageUrl);

    if (isLocalFile) {
      if (_shouldBypassLocalDecode) {
        return _buildErrorWidget(
          context,
          onRetry: _retryBrokenLocalImage,
        );
      }

      if (_shouldUseNativeAnimatedView(normalizedLocalPath)) {
        return _buildNativeAnimatedWebP(
          normalizedLocalPath,
          const {},
          filePathOverride: _cachedFilePath ?? normalizedLocalPath,
        );
      }

      // Use ExtendedImage.file for local files
      return ExtendedImage.file(
        File(normalizedLocalPath),
        key:
            ValueKey('extended_image_${widget.contentId}_${widget.pageNumber}'),
        fit: _getAdaptiveBoxFit(),
        mode: widget.enableZoom &&
                widget.readingMode != ReadingMode.continuousScroll
            ? ExtendedImageMode.gesture
            : ExtendedImageMode.none,
        // Keep heavy/animated local files in memory on dispose so scroll-back
        // does not trigger re-decode.
        clearMemoryCacheWhenDispose:
            ExtendedImageReaderWidget.shouldClearMemoryCacheOnDisposeForTesting(
          readingMode: widget.readingMode,
          isHeavy: _isHeavyImage,
          isHeavyReaderSource: false,
        ),
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
            // 🐛 BUG FIX: Only use PageView optimization for actual PageView modes
            // For continuous scroll (ListView), set to false to avoid gesture conflicts
            inPageView: widget.readingMode != ReadingMode.continuousScroll,
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
              if (_hasRealByteProgress(state)) {
                _stopSyntheticProgress();
              } else {
                _startSyntheticProgress();
              }
              return _buildLoadingIndicator(context, state: state);
            case LoadState.failed:
              _stopSyntheticProgress(reset: true);
              _markLocalDecodeAsBroken();
              return _buildErrorWidget(
                context,
                onRetry: _retryBrokenLocalImage,
              );
            case LoadState.completed:
              _stopSyntheticProgress(reset: true);
              // 🎯 PHASE 1: Report image dimensions when loaded
              if (widget.onImageLoaded != null &&
                  state.extendedImageInfo?.image != null) {
                final image = state.extendedImageInfo!.image;
                final imageSize = Size(
                  image.width.toDouble(),
                  image.height.toDouble(),
                );
                // Call callback on next frame to avoid calling during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onImageLoaded?.call(widget.pageNumber, imageSize);
                });
              }

              if (!_isHeavyImage && AnimatedWebPView.isAvailable) {
                try {
                  final file = File(normalizedLocalPath);
                  if (file.existsSync()) {
                    final fileSize = file.lengthSync();
                    if (fileSize >= _heavyImageThresholdBytes &&
                        _looksLikeAnimatedWebPFileSync(file)) {
                      _markConfirmedAnimatedWebP(
                        cacheKey: widget.imageUrl,
                        cachedFilePath: normalizedLocalPath,
                      );
                      setState(() {
                        _isHeavyImage = true;
                        _isConfirmedAnimatedWebP = true;
                        _cachedFilePath = normalizedLocalPath;
                      });
                      updateKeepAlive();
                      _maybeNotifyHeavyImageDetected();
                      _logger.i(
                        '[NativeWebP] Local complete => native '
                        'page=${widget.pageNumber} '
                        'size=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                      );
                    }
                  }
                } catch (e) {
                  _logger.w('[NativeWebP] Local file stat error: $e');
                }
              }

              return _buildCompletedImage(context, state);
          }
        },
      );
    } else {
      final effectiveImageUrl = _hitomiFallbackImageUrl ?? widget.imageUrl;
      final isEhentaiReaderUrl =
          _shouldResolveEhentaiImageUrl(effectiveImageUrl);
      if (!isEhentaiReaderUrl) {
        final headers = widget.sourceId == 'hentainexus'
            ? _buildHentainexusImageHeaders(effectiveImageUrl)
            : widget.httpHeaders;

        return _buildNetworkImage(
          context,
          effectiveImageUrl,
          headers: headers,
        );
      }

      return FutureBuilder<String?>(
        future: _ehentaiResolvedImageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoadingIndicator(context);
          }

          final resolved = snapshot.data;
          if (resolved == null || resolved.isEmpty) {
            return _buildStandaloneErrorWidget(context);
          }

          return _buildNetworkImage(
            context,
            resolved,
            headers: _buildEhentaiImageHeaders(widget.imageUrl),
          );
        },
      );
    }
  }

  void _prepareEhentaiResolveFuture() {
    if (_shouldResolveEhentaiImageUrl(widget.imageUrl)) {
      _ehentaiResolvedImageFuture = _resolveEhentaiImageUrl(widget.imageUrl);
      return;
    }

    _ehentaiResolvedImageFuture = null;
  }

  Widget _buildNetworkImage(
    BuildContext context,
    String url, {
    Map<String, String>? headers,
  }) {
    // Only route to the native animated view after this URL has actually been
    // identified as a heavy animated WebP. Small/normal .webp images should
    // continue through ExtendedImage.network.
    final isLikelyAnimatedUrl = _isLikelyAnimatedUrl(url);
    if (_shouldUseNativeAnimatedView(url)) {
      return _buildNativeAnimatedWebP(url, headers);
    }

    final decodeWidth = _targetDecodeWidth(
      context,
      imageUrl: url,
      isLikelyAnimatedUrl: isLikelyAnimatedUrl,
    );

    return ExtendedImage.network(
      url,
      key: ValueKey('extended_image_${widget.contentId}_${widget.pageNumber}'),
      headers: headers,
      fit: _getAdaptiveBoxFit(),
      // 🔥 THERMAL / FRAME-RATE:
      // - Animated WebP (≥2MB .webp): FilterQuality.none — fastest per-frame
      //   GPU composite; quality is acceptable at reduced cacheWidth.
      // - Other heavy sources: FilterQuality.low — balanced.
      // - Normal images: FilterQuality.medium — standard quality.
      filterQuality: isLikelyAnimatedUrl
          ? FilterQuality.none
          : (_isHeavyReaderSource() || _isHeavyImage)
              ? FilterQuality.medium
              : FilterQuality.high,
      mode: widget.enableZoom &&
              widget.readingMode != ReadingMode.continuousScroll
          ? ExtendedImageMode.gesture
          : ExtendedImageMode.none,
      // Let ordinary pages in long continuous-scroll sessions recycle their
      // decoded frame buffers, while heavy/native pages stay warm.
      clearMemoryCacheWhenDispose:
          ExtendedImageReaderWidget.shouldClearMemoryCacheOnDisposeForTesting(
        readingMode: widget.readingMode,
        isHeavy: _isHeavyImage,
        isHeavyReaderSource: _isHeavyReaderSource(),
      ),
      cache: true,
      cacheWidth: decodeWidth,
      enableLoadState: true,
      extendedImageGestureKey: _gestureKey,
      initGestureConfigHandler: (state) {
        return GestureConfig(
          minScale: 1.0,
          maxScale: 3.0,
          animationMinScale: 0.9,
          animationMaxScale: 3.5,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: 1.0,
          inPageView: widget.readingMode != ReadingMode.continuousScroll,
          cacheGesture: false,
          initialAlignment: InitialAlignment.center,
        );
      },
      onDoubleTap: widget.enableZoom
          ? (ExtendedImageGestureState state) => _handleDoubleTap(state)
          : null,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            if (_hasRealByteProgress(state)) {
              _stopSyntheticProgress();
            } else {
              _startSyntheticProgress();
            }

            // Optional pre-seed via Content-Length (only if server sends it):
            // servers that skip Content-Length are handled at LoadState.completed.
            if (!_isHeavyImage) {
              try {
                final dynamic prog = (state as dynamic).loadingProgress;
                final total = prog?.expectedTotalBytes;
                if (total is num && total >= _heavyImageThresholdBytes) {
                  _preSeedHeavyImageUrl();
                  // Online large payload detected: lock continuous mode early.
                  _maybeNotifyHeavyImageDetected();
                }
              } catch (_) {}
            }

            return _buildLoadingIndicator(context, state: state);
          case LoadState.failed:
            _stopSyntheticProgress(reset: true);
            if ((widget.sourceId ?? '').toLowerCase() == 'hitomi') {
              _logger.w(
                'Hitomi reader image failed: page=${widget.pageNumber}, url=$url, retries=$_imageLoadRetries, fallback=${_hitomiFallbackImageUrl ?? ''}',
              );
            }
            if (_tryHitomiAvifFallback(url)) {
              return _buildLoadingIndicator(context);
            }
            if (_tryRefreshEhentaiResolvedImageUrl(url)) {
              return _buildLoadingIndicator(context);
            }
            // 🔄 AUTO-RETRY: Check if should auto-retry (timeout/network error)
            if (_shouldAutoRetryImage(state) &&
                _imageLoadRetries < _maxImageLoadRetries) {
              _scheduleAutoRetry(state);
            }
            return _buildErrorWidget(context, state: state);
          case LoadState.completed:
            _stopSyntheticProgress(reset: true);
            _syntheticProgressByImageKey[_imageProgressKey] = 1.0;
            _imageLoadRetries = 0; // Reset retries on success
            _ehentaiResolveRetries = 0;
            if ((widget.sourceId ?? '').toLowerCase() == 'hitomi' &&
                _hitomiFallbackImageUrl != null) {
              _logger.i(
                'Hitomi reader image loaded via fallback: page=${widget.pageNumber}, url=$url',
              );
            }
            if (widget.onImageLoaded != null &&
                state.extendedImageInfo?.image != null) {
              final image = state.extendedImageInfo!.image;
              final imageSize = Size(
                image.width.toDouble(),
                image.height.toDouble(),
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onImageLoaded?.call(widget.pageNumber, imageSize);
              });
            }

            // 🎬 ANIMATED WebP DETECTION (at completion, no Content-Length needed):
            //
            // Many servers (nhentai, HitomiNexus, etc.) skip Content-Length, so
            // expectedTotalBytes is always null and the pre-seed above never fires.
            // At LoadState.completed the file IS on disk — check its actual size.
            //
            // Steps:
            //   1. URL heuristic: ends with .webp or contains -wbp (H@H)
            //   2. getCachedImageFile → stat file size ≥ 2 MB
            //   3. setState → _isHeavyImage = true, _cachedFilePath = path
            //   4. Next build routes straight to AnimatedWebPView (disk read, no re-download)
            if (!_isConfirmedAnimatedWebP &&
                AnimatedWebPView.isAvailable &&
                _shouldInspectCachedFileForAnimatedWebP(url)) {
              getCachedImageFile(url).then((cacheFile) {
                // Check file size BEFORE mounted check so the animated-WebP
                // cache is seeded even if this widget instance is already
                // unmounted (e.g. user switched reading mode mid-download).
                if (cacheFile == null) return;
                final fileSize = cacheFile.lengthSync();
                _logger.d(
                  '[NativeWebP] Cached file=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB '
                  'threshold=${(_heavyImageThresholdBytes / 1024 / 1024).toStringAsFixed(0)} MB '
                  'page=${widget.pageNumber}',
                );
                if (fileSize >= _heavyImageThresholdBytes &&
                    _looksLikeAnimatedWebPFileSync(cacheFile)) {
                  _markConfirmedAnimatedWebP(
                    cacheKey: url,
                    cachedFilePath: cacheFile.path,
                  );

                  // 🔥 Evict from ExtendedImage memory cache so Flutter's
                  // MultiFrameImageStreamCompleter stops decoding animated
                  // frames on the raster thread. The native view takes over.
                  clearMemoryImageCache(url);

                  if (!mounted) return;
                  setState(() {
                    _isHeavyImage = true;
                    _isConfirmedAnimatedWebP = true;
                    _cachedFilePath = cacheFile.path;
                  });
                  updateKeepAlive();
                  _maybeNotifyHeavyImageDetected();
                  _logger.i(
                    '[NativeWebP] => AnimatedImageDrawable: '
                    'page=${widget.pageNumber} size=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB'
                    ' path=${cacheFile.path}',
                  );
                } else if (fileSize >= _heavyImageThresholdBytes) {
                  _logger.d(
                    '[NativeWebP] Heavy file is not animated WebP, '
                    'keep Flutter renderer page=${widget.pageNumber}',
                  );
                } else {
                  _logger.d(
                    '[NativeWebP] File too small for native (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB), '
                    'keep Flutter renderer page=${widget.pageNumber}',
                  );
                }
              }).catchError((Object e) {
                _logger.w('[NativeWebP] getCachedImageFile error: $e');
              });
            }

            return _buildCompletedImage(
              context,
              state,
              imageUrl: url,
            );
        }
      },
    );
  }

  /// Renders an animated WebP using Android's native [AnimatedImageDrawable].
  ///
  /// Wraps [AnimatedWebPView] in a [RepaintBoundary] so the continuously
  /// animating native layer does not invalidate the surrounding Flutter tree.
  Widget _buildNativeAnimatedWebP(
    String url,
    Map<String, String>? headers, {
    String? filePathOverride,
  }) {
    final resolvedFilePath = filePathOverride ?? _cachedFilePath;

    return RepaintBoundary(
      child: AnimatedWebPView(
        key: ValueKey('native_webp_${widget.contentId}_${widget.pageNumber}'),
        url: url,
        filePath: resolvedFilePath,
        headers: headers ?? const {},
        targetWidth: _nativeDecodeWidth(context),
        autoPlay: _shouldAutoPlayAnimatedView,
        pageNumber: widget.pageNumber,
        visiblePageNotifier: widget.visiblePageNotifier,
        loadingBuilder: (context, receivedBytes, totalBytes) =>
            _buildLoadingIndicator(
          context,
          loadedBytesOverride: receivedBytes,
          totalBytesOverride: totalBytes,
        ),
        fallback: _buildLoadingIndicator(context),
      ),
    );
  }

  bool _shouldResolveEhentaiImageUrl(String url) {
    if (widget.sourceId != 'ehentai') {
      return false;
    }

    final lowered = url.toLowerCase();
    if (lowered.startsWith('/s/') || lowered.startsWith('/fullimg/')) {
      return true;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (!(host.contains('e-hentai.org') || host.contains('exhentai.org'))) {
      return false;
    }

    final loweredPath = uri.path.toLowerCase();
    if (loweredPath.contains('/s/') || loweredPath.contains('/fullimg/')) {
      return true;
    }

    return !_looksLikeDirectImagePath(loweredPath);
  }

  bool _looksLikeDirectImagePath(String path) {
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif') ||
        path.endsWith('.avif');
  }

  bool _tryHitomiAvifFallback(String failedUrl) {
    if ((widget.sourceId ?? '').toLowerCase() != 'hitomi') {
      return false;
    }
    if (_hitomiFallbackImageUrl != null) {
      return false;
    }

    final lowered = failedUrl.toLowerCase();
    if (!lowered.contains('gold-usergeneratedcontent.net') ||
        !lowered.contains('.avif')) {
      return false;
    }

    final webpUrl = _toHitomiWebpUrl(failedUrl);
    if (webpUrl == failedUrl) {
      return false;
    }

    _logger.w(
      'Hitomi reader AVIF fallback: page=${widget.pageNumber}, from=$failedUrl, to=$webpUrl',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageLoadRetries = 0;
        _hitomiFallbackImageUrl = webpUrl;
      });
    });
    return true;
  }

  String _toHitomiWebpUrl(String url) {
    final withWebpHost = url.replaceFirstMapped(
      RegExp(r'^(https://)a(\d+)\.gold-usergeneratedcontent\.net',
          caseSensitive: false),
      (match) =>
          '${match.group(1)}w${match.group(2)}.gold-usergeneratedcontent.net',
    );

    return withWebpHost.replaceFirstMapped(
      RegExp(r'\.avif(?=($|[?#]))', caseSensitive: false),
      (_) => '.webp',
    );
  }

  bool _isHeavyReaderSource() {
    return widget.sourceId == 'hentainexus';
  }

  bool _shouldInspectCachedFileForAnimatedWebP(String url) {
    return (widget.sourceId ?? '').toLowerCase() == 'ehentai' ||
        ExtendedImageReaderWidget._looksLikeAnimatedWebPUrl(url);
  }

  void _markConfirmedAnimatedWebP({
    required String cacheKey,
    required String cachedFilePath,
  }) {
    _heavyImageUrls.add(cacheKey);
    _confirmedAnimatedWebPUrls.add(cacheKey);
    _cachedFilePathByUrl[cacheKey] = cachedFilePath;
  }

  static bool _looksLikeAnimatedWebPFileSync(File file) {
    RandomAccessFile? raf;
    try {
      raf = file.openSync(mode: FileMode.read);
      final length = raf.lengthSync();
      if (length < 16) {
        return false;
      }

      final sampleLength = length < 64 ? length : 64;
      final bytes = raf.readSync(sampleLength);
      return _looksLikeAnimatedWebPHeader(bytes);
    } catch (_) {
      return false;
    } finally {
      raf?.closeSync();
    }
  }

  static bool _looksLikeAnimatedWebPHeader(Uint8List bytes) {
    const riff = <int>[0x52, 0x49, 0x46, 0x46];
    const webp = <int>[0x57, 0x45, 0x42, 0x50];
    const vp8x = <int>[0x56, 0x50, 0x38, 0x58];
    const anim = <int>[0x41, 0x4E, 0x49, 0x4D];

    if (!_matchesBytes(bytes, 0, riff) || !_matchesBytes(bytes, 8, webp)) {
      return false;
    }

    if (_matchesBytes(bytes, 12, vp8x) &&
        bytes.length > 20 &&
        (bytes[20] & 0x02) != 0) {
      return true;
    }

    return _containsBytes(bytes, anim);
  }

  static bool _matchesBytes(Uint8List bytes, int offset, List<int> expected) {
    if (bytes.length < offset + expected.length) {
      return false;
    }

    for (var i = 0; i < expected.length; i++) {
      if (bytes[offset + i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _containsBytes(Uint8List bytes, List<int> needle) {
    if (needle.isEmpty || bytes.length < needle.length) {
      return false;
    }

    for (var start = 0; start <= bytes.length - needle.length; start++) {
      if (_matchesBytes(bytes, start, needle)) {
        return true;
      }
    }
    return false;
  }

  bool _hasInvalidLocalImagePayloadSync(String localPath) {
    RandomAccessFile? raf;
    try {
      final file = File(localPath);
      if (!file.existsSync() || file.lengthSync() <= 0) {
        return true;
      }

      final fileLength = file.lengthSync();
      final sampleLength = fileLength < 64 ? fileLength : 64;
      raf = file.openSync(mode: FileMode.read);
      final bytes = raf.readSync(sampleLength);
      return inferImageExtension(bytes: bytes) == null;
    } catch (e) {
      _logger.w('[LocalImage] Failed to validate local payload: $localPath');
      return false;
    } finally {
      raf?.closeSync();
    }
  }

  int? _targetDecodeWidth(
    BuildContext context, {
    String? imageUrl,
    bool? isLikelyAnimatedUrl,
  }) {
    // Apply decode downsampling for heavy sources and known heavy/animated images.
    //
    // Benefits:
    // - Smaller GPU texture upload on each animation frame tick
    // - Reduced memory footprint per decoded frame
    // - On second open within session (_isHeavyImage=true from initState),
    //   cacheWidth is applied from the very first decode request.
    //
    // Note: Android's MediaCodec does NOT hardware-decode animated WebP;
    // libwebp (CPU) is always used. cacheWidth reduces the decode resolution
    // so each frame is cheaper to decode AND cheaper to composite via GPU.
    final bool isHeavyScroll =
        widget.readingMode == ReadingMode.continuousScroll &&
            (_isHeavyReaderSource() || _isHeavyImage);
    if (!isHeavyScroll) return null;

    final mediaQuery = MediaQuery.of(context);
    // Animated WebP: 40% — each frame of a 45-frame 1416×1608 animation at
    // 75% would still be ~2.5 MB raw; at 40% it drops to ~700 KB per frame,
    // bringing the total decoded footprint from ~112 MB to ~31 MB.
    // Static heavy: 75% — keeps text/detail readable.
    final bool animatedImage = isLikelyAnimatedUrl ??
        _isLikelyAnimatedUrl(
          imageUrl ?? _hitomiFallbackImageUrl ?? widget.imageUrl,
        );
    final double factor = animatedImage ? 0.40 : 0.75;
    return ((mediaQuery.size.width * factor) * mediaQuery.devicePixelRatio)
        .round();
  }

  /// Target decode width for the native [AnimatedWebPView] Kotlin renderer.
  ///
  /// Uses a viewport-relative width with caps so very large offline animated
  /// WebP files do not decode close to full-resolution in the native player.
  /// This keeps RenderThread work and transient heap spikes lower on 10-20 MB
  /// files while preserving enough detail for reader usage.
  int _nativeDecodeWidth(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ExtendedImageReaderWidget.resolveNativeAnimatedDecodeWidthForTesting(
      logicalWidth: mq.size.width,
      devicePixelRatio: mq.devicePixelRatio,
      imageBytes: _resolveNativeAnimatedImageBytes(),
    );
  }

  int? _resolveNativeAnimatedImageBytes() {
    final candidates = <String?>[
      _cachedFilePath,
      _isLocalFilePath(widget.imageUrl)
          ? _normalizeLocalPath(widget.imageUrl)
          : null,
    ];

    for (final candidate in candidates) {
      if (candidate == null || candidate.isEmpty) {
        continue;
      }

      try {
        final file = File(candidate);
        if (!file.existsSync()) {
          continue;
        }

        final length = file.lengthSync();
        if (length > 0) {
          return length;
        }
      } catch (_) {
        // Ignore stat failures and fall back to viewport-only sizing.
      }
    }

    return null;
  }

  Map<String, String> _buildEhentaiImageHeaders(String readerPageUrl) {
    final headers = <String, String>{...?widget.httpHeaders};
    headers['Referer'] = readerPageUrl;
    return headers;
  }

  Map<String, String> _buildHentainexusImageHeaders(String imageUrl) {
    final headers = <String, String>{...?widget.httpHeaders};
    headers['Accept'] =
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8';
    headers['Accept-Language'] = 'en-US,en;q=0.6';
    headers['Origin'] = 'https://hentainexus.com';
    headers['Referer'] = 'https://hentainexus.com/';
    return headers;
  }

  Future<String?> _resolveEhentaiImageUrl(String readerPageUrl) async {
    final cached = _ehentaiResolvedImageCache[readerPageUrl];
    final cachedAt = _ehentaiResolvedImageCacheTime[readerPageUrl];
    if (cached != null && cached.isNotEmpty && cachedAt != null) {
      final age = DateTime.now().difference(cachedAt);
      if (age <= _ehentaiResolvedImageCacheTtl) {
        return cached;
      }
      _invalidateEhentaiResolvedImageUrl(readerPageUrl);
    }

    final inFlight = _ehentaiResolveInFlight[readerPageUrl];
    if (inFlight != null) {
      return inFlight;
    }

    final resolver = _resolveEhentaiImageUrlInternal(readerPageUrl);
    _ehentaiResolveInFlight[readerPageUrl] = resolver;
    try {
      return await resolver;
    } finally {
      await _ehentaiResolveInFlight.remove(readerPageUrl);
    }
  }

  Future<String?> _resolveEhentaiImageUrlInternal(String readerPageUrl) async {
    try {
      final response = await _ehentaiResolverDio.get<dynamic>(
        readerPageUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: widget.httpHeaders,
          followRedirects: true,
          validateStatus: (status) => (status ?? 0) < 400,
        ),
      );

      final html = response.data?.toString() ?? '';
      if (html.isEmpty) {
        return null;
      }

      final imageUrl = extractEhentaiImageUrlFromHtml(
        html,
        readerPageUrl,
        rawConfig: widget.sourceRawConfig,
      );
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _ehentaiResolvedImageCache[readerPageUrl] = imageUrl;
        _ehentaiResolvedImageCacheTime[readerPageUrl] = DateTime.now();
      }
      return imageUrl;
    } catch (_) {
      return null;
    }
  }

  void _invalidateEhentaiResolvedImageUrl(String readerPageUrl) {
    _ehentaiResolvedImageCache.remove(readerPageUrl);
    _ehentaiResolvedImageCacheTime.remove(readerPageUrl);
    _ehentaiResolveInFlight.remove(readerPageUrl);
  }

  bool _tryRefreshEhentaiResolvedImageUrl(String failedUrl) {
    if ((widget.sourceId ?? '').toLowerCase() != 'ehentai') {
      return false;
    }

    final readerPageUrl = widget.imageUrl;
    if (!_shouldResolveEhentaiImageUrl(readerPageUrl)) {
      return false;
    }

    if (_ehentaiResolveRetries >= _maxEhentaiResolveRetries) {
      return false;
    }

    _ehentaiResolveRetries++;
    _invalidateEhentaiResolvedImageUrl(readerPageUrl);
    _logger.w(
      'E-Hentai reader image failed, refreshing tokenized URL '
      '(attempt $_ehentaiResolveRetries/$_maxEhentaiResolveRetries). '
      'page=${widget.pageNumber}, failed=$failedUrl',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _ehentaiResolvedImageFuture = _resolveEhentaiImageUrl(readerPageUrl);
      });
    });

    return true;
  }

  String _formatByteSize(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Widget _buildStandaloneErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        AppLocalizations.of(context)!.failedToLoadImage,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build loading indicator with download progress.
  ///
  /// Note: PNG/JPG progressive partial rendering is format/server dependent.
  /// We provide byte-level progress to indicate how close the image is to display.
  Widget _buildLoadingIndicator(BuildContext context,
      {ExtendedImageState? state,
      int? loadedBytesOverride,
      int? totalBytesOverride}) {
    final l10n = AppLocalizations.of(context)!;
    // Responsive sizing based on reading mode
    final bool isContinuousScroll =
        widget.readingMode == ReadingMode.continuousScroll;

    final double cardWidth = isContinuousScroll ? 280 : 240;
    final double previewHeight = isContinuousScroll ? 150 : 170;

    double? progressValue;
    int? progressPercent;
    int loadedBytes = loadedBytesOverride ?? 0;
    int? totalBytes = totalBytesOverride;
    try {
      if (state != null) {
        final dynamic progressEvent = (state as dynamic).loadingProgress;
        final loadedRaw = progressEvent?.cumulativeBytesLoaded;
        final totalRaw = progressEvent?.expectedTotalBytes;

        if (loadedRaw is num) {
          loadedBytes = loadedRaw.toInt();
        }
        if (totalRaw is num) {
          totalBytes = totalRaw.toInt();
        }
      }

      if (totalBytes != null && totalBytes > 0) {
        progressValue = (loadedBytes / totalBytes).clamp(0.0, 1.0);
        progressPercent = (progressValue * 100).floor();
      }

      if (loadedBytes <= 0 &&
          progressValue == null &&
          _syntheticProgressValue > 0) {
        progressValue = _syntheticProgressValue;
      }
    } catch (_) {
      // Keep indicator indeterminate when progress fields are unavailable.
      if (loadedBytes <= 0 && _syntheticProgressValue > 0) {
        progressValue = _syntheticProgressValue;
      }
    }

    final bool hasKnownTotal = totalBytes != null && totalBytes > 0;
    final bool hasRealByteCount = loadedBytes > 0;
    final int resolvedTotalBytes = totalBytes ?? 0;
    final String headlineText = hasKnownTotal
        ? '$progressPercent%'
        : hasRealByteCount
            ? _formatByteSize(loadedBytes)
            : l10n.loading;
    final String detailText = hasKnownTotal
        ? '${_formatByteSize(loadedBytes)} / ${_formatByteSize(resolvedTotalBytes)}'
        : hasRealByteCount
            ? l10n.downloaded(_formatByteSize(loadedBytes))
            : _syntheticProgressValue > 0
                ? l10n.estimatingProgress
                : l10n.downloadingImageData;
    final double? indicatorValue = progressValue;
    final bool showIndeterminateFromRealBytes =
        hasRealByteCount && !hasKnownTotal;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      margin: isContinuousScroll
          ? const EdgeInsets.symmetric(vertical: 20)
          : EdgeInsets.zero,
      child: Center(
        child: Card(
          elevation: 6,
          shadowColor:
              Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: previewHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    headlineText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value:
                        showIndeterminateFromRealBytes ? null : indicatorValue,
                    minHeight: 7,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detailText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build error widget with logo and retry option
  Widget _buildErrorWidget(
    BuildContext context, {
    ExtendedImageState? state,
    VoidCallback? onRetry,
  }) {
    // Responsive sizing based on reading mode
    final bool isContinuousScroll =
        widget.readingMode == ReadingMode.continuousScroll;
    final double cardSize = isContinuousScroll ? 250 : 200;
    final double logoSize = isContinuousScroll ? 100 : 100;
    final double iconSize = isContinuousScroll ? 24 : 32;
    final l10n = AppLocalizations.of(context)!;
    final isRetrying = _autoRetryTimer?.isActive ?? false;
    final isRepairing = _isRepairingBrokenImage;
    final isOpeningSourcePage = _isOpeningSourcePage;
    final isActionBusy = isRepairing || isOpeningSourcePage;
    final retryAction = onRetry ?? state?.reLoadImage;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Card(
          elevation: 8,
          shadowColor:
              Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: cardSize,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with error overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                          image: AssetImage('assets/icons/logo_app.png'),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                    // Error icon overlay
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.8),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onError,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Error message or auto-retry indicator
                Text(
                  isRepairing
                      ? l10n.readerRepairingImage
                      : isOpeningSourcePage
                          ? l10n.readerOpeningSourcePage
                          : (isRetrying ? l10n.retrying : l10n.failedToLoad),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: (isRetrying || isActionBusy)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),

                // Page number and retry count
                Text(
                  isRetrying
                      ? l10n.pageAttempt(
                          widget.pageNumber,
                          _imageLoadRetries,
                          _maxImageLoadRetries,
                        )
                      : l10n.pageNumber(widget.pageNumber),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                if (!isRetrying && widget.onOpenSourcePageForRepair != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isActionBusy
                          ? null
                          : () async {
                              setState(() {
                                _isOpeningSourcePage = true;
                              });

                              bool repaired = false;
                              try {
                                repaired = await widget
                                    .onOpenSourcePageForRepair!
                                    .call();
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isOpeningSourcePage = false;
                                  });
                                }
                              }

                              if (repaired && mounted) {
                                if (state != null) {
                                  state.reLoadImage();
                                } else {
                                  _retryBrokenLocalImage();
                                }
                              }
                            },
                      icon: isOpeningSourcePage
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.language, size: 16),
                      label: Text(
                        isOpeningSourcePage
                            ? l10n.readerOpeningSourcePage
                            : l10n.readerOpenSourcePage,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (!isRetrying && widget.onOpenSourcePageForRepair != null)
                  const SizedBox(height: 8),

                if (!isRetrying && widget.onRepairBrokenImage != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isActionBusy
                          ? null
                          : () async {
                              setState(() {
                                _isRepairingBrokenImage = true;
                              });

                              bool repaired = false;
                              try {
                                repaired =
                                    await widget.onRepairBrokenImage!.call();
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isRepairingBrokenImage = false;
                                  });
                                }
                              }

                              if (repaired && mounted) {
                                if (state != null) {
                                  state.reLoadImage();
                                } else {
                                  _retryBrokenLocalImage();
                                }
                              }
                            },
                      icon: isRepairing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.download_for_offline_outlined,
                              size: 16),
                      label: Text(
                        isRepairing
                            ? l10n.readerRepairingImage
                            : l10n.readerRedownloadImage,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (!isRetrying && widget.onRepairBrokenImage != null)
                  const SizedBox(height: 8),

                // Retry button (hidden if already retrying)
                if (!isRetrying)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isActionBusy ? null : retryAction,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(l10n.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build completed image with zoom indicator.
  ///
  /// Animated images are wrapped in a [RepaintBoundary] so each animation
  /// tick only re-rasterizes the image's own composited layer instead of
  /// invalidating the parent ListView cell and all its siblings.
  /// This is the single most effective fix for animated-WebP frame drops.
  Widget _buildCompletedImage(
    BuildContext context,
    ExtendedImageState state, {
    String? imageUrl,
  }) {
    final isLikelyAnimatedImage = _isLikelyAnimatedUrl(
        imageUrl ?? _hitomiFallbackImageUrl ?? widget.imageUrl);
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
      // Still wrap in RepaintBoundary for animated images displayed without zoom
      // (e.g. continuousScroll mode).
      return isLikelyAnimatedImage
          ? RepaintBoundary(child: imageWidget)
          : imageWidget;
    }

    // For gesture mode, wrap with listener to detect zoom level.
    // RepaintBoundary around gesture mode is important for animated WebP:
    // the zoom/scale AnimatedBuilder triggers rebuilds on every zoom tick;
    // the boundary keeps those repaints isolated from the ListView.
    final Widget gestureWidget = AnimatedBuilder(
      animation: _zoomController,
      builder: (context, child) {
        final gestureState = _gestureKey.currentState;
        final currentScale = gestureState?.gestureDetails?.totalScale ?? 1.0;
        final isZoomed = currentScale > 1.2;

        return Stack(
          alignment: Alignment.center,
          children: [
            Center(child: imageWidget),
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
                      const Icon(Icons.zoom_in, color: Colors.white, size: 16),
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

    return isLikelyAnimatedImage
        ? RepaintBoundary(child: gestureWidget)
        : gestureWidget;
  }

  /// 🔄 AUTO-RETRY: Check if should auto-retry (timeout/network errors)
  ///
  /// HentaiNexus images often timeout on initial load due to:
  /// - Large file sizes (20-40s download)
  /// - Rate limiting (1 req/sec, 2 concurrent max)
  /// - Global 30s timeout threshold
  ///
  /// Auto-retry with exponential backoff helps recover automatically
  /// without requiring user to manually click retry button.
  bool _shouldAutoRetryImage(ExtendedImageState state) {
    if (widget.readingMode != ReadingMode.continuousScroll) {
      return false; // Only auto-retry in continuous scroll (where it matters most)
    }

    // Only auto-retry for HentaiNexus (heavy source known to timeout)
    return false;
  }

  /// 🔄 AUTO-RETRY: Schedule retry with exponential backoff
  ///
  /// Delays increase: 2s, 4s, 8s for retries 1, 2, 3
  /// This gives the network/server time to recover.
  void _scheduleAutoRetry(ExtendedImageState state) {
    _imageLoadRetries++;
    _autoRetryTimer?.cancel();

    // Exponential backoff: 2^retry * 1000ms (2s, 4s, 8s)
    final delayMs = (1000 * (1 << (_imageLoadRetries - 1))).toInt();

    debugPrint(
      '🔄 Auto-retrying HentaiNexus image (page ${widget.pageNumber}): '
      'Attempt $_imageLoadRetries/$_maxImageLoadRetries after ${delayMs}ms',
    );

    _autoRetryTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) {
        state.reLoadImage();
      }
    });
  }
}
