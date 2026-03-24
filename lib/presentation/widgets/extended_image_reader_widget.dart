import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
// import '../../core/utils/webtoon_detector.dart';
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
    this.httpHeaders,
    this.enableZoom = true,
    this.onLoadError,
    this.onImageLoaded,
  });

  final String imageUrl;
  final String contentId;
  final int pageNumber;
  final ReadingMode readingMode;
  final String? sourceId;
  final Map<String, String>? httpHeaders;
  final bool enableZoom;
  final VoidCallback? onLoadError;

  /// 🎯 PHASE 1: Callback when image loads with actual dimensions
  final Function(int pageNumber, Size imageSize)? onImageLoaded;

  @override
  State<ExtendedImageReaderWidget> createState() =>
      _ExtendedImageReaderWidgetState();
}

class _ExtendedImageReaderWidgetState extends State<ExtendedImageReaderWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
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
  static final Map<String, Future<String?>> _ehentaiResolveInFlight =
      <String, Future<String?>>{};
  static final Map<String, double> _syntheticProgressByImageKey =
      <String, double>{};

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  final GlobalKey<ExtendedImageGestureState> _gestureKey = GlobalKey();
  Future<String?>? _ehentaiResolvedImageFuture;
  String? _hitomiFallbackImageUrl;

  // 🔄 AUTO-RETRY: Track retry attempts for timeout/network errors
  int _imageLoadRetries = 0;
  static const int _maxImageLoadRetries = 3;
  Timer? _autoRetryTimer;
  Timer? _syntheticProgressTimer;
  double _syntheticProgressValue = 0.0;

  String get _imageProgressKey => '${widget.contentId}_${widget.pageNumber}';

  // 🎯 PHASE 2: Cache loaded image size for webtoon detection
  // Size? _loadedImageSize;

  // 🚀 OPTIMIZATION: Keep widget alive in ListView to prevent reload
  @override
  bool get wantKeepAlive => widget.readingMode != ReadingMode.continuousScroll;

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

    _prepareEhentaiResolveFuture();
  }

  @override
  void didUpdateWidget(covariant ExtendedImageReaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final sourceChanged = oldWidget.sourceId != widget.sourceId;
    final imageChanged = oldWidget.imageUrl != widget.imageUrl;

    if (sourceChanged || imageChanged) {
      _hitomiFallbackImageUrl = null;
      _prepareEhentaiResolveFuture();
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

    // Check if imageUrl is a local file path
    final isLocalFile = widget.imageUrl.startsWith('/') ||
        widget.imageUrl.startsWith('\\') ||
        (!widget.imageUrl.startsWith('http://') &&
            !widget.imageUrl.startsWith('https://') &&
            !widget.imageUrl.startsWith('file://'));

    if (isLocalFile) {
      // Use ExtendedImage.file for local files
      return ExtendedImage.file(
        File(widget.imageUrl),
        key:
            ValueKey('extended_image_${widget.contentId}_${widget.pageNumber}'),
        fit: _getAdaptiveBoxFit(),
        mode: widget.enableZoom &&
                widget.readingMode != ReadingMode.continuousScroll
            ? ExtendedImageMode.gesture
            : ExtendedImageMode.none,
        clearMemoryCacheWhenDispose:
            widget.readingMode == ReadingMode.continuousScroll,
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
              return _buildErrorWidget(context, state);
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
              return _buildCompletedImage(context, state);
          }
        },
      );
    } else {
      final effectiveImageUrl = _hitomiFallbackImageUrl ?? widget.imageUrl;
      final isEhentaiReaderUrl = _isEhentaiReaderPageUrl(effectiveImageUrl);
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
    if (_isEhentaiReaderPageUrl(widget.imageUrl)) {
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
    final decodeWidth = _targetDecodeWidth(context);

    return ExtendedImage.network(
      url,
      key: ValueKey('extended_image_${widget.contentId}_${widget.pageNumber}'),
      headers: headers,
      fit: _getAdaptiveBoxFit(),
      // 🔥 THERMAL: Use none for HentaiNexus; medium for others. Skips quality downsampling.
      filterQuality: _isHeavyReaderSource() &&
              widget.readingMode == ReadingMode.continuousScroll
          ? FilterQuality.low
          : (_isHeavyReaderSource() ? FilterQuality.low : FilterQuality.medium),
      mode: widget.enableZoom &&
              widget.readingMode != ReadingMode.continuousScroll
          ? ExtendedImageMode.gesture
          : ExtendedImageMode.none,
      // Keep RAM cache for heavy sources so scrolling back to older pages
      // does not trigger full reload/decode again.
      clearMemoryCacheWhenDispose:
          widget.readingMode == ReadingMode.continuousScroll &&
              !_isHeavyReaderSource(),
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
            return _buildLoadingIndicator(context, state: state);
          case LoadState.failed:
            _stopSyntheticProgress(reset: true);
            if (_tryHitomiAvifFallback(url)) {
              return _buildLoadingIndicator(context);
            }
            // 🔄 AUTO-RETRY: Check if should auto-retry (timeout/network error)
            if (_shouldAutoRetryImage(state) &&
                _imageLoadRetries < _maxImageLoadRetries) {
              _scheduleAutoRetry(state);
            }
            return _buildErrorWidget(context, state);
          case LoadState.completed:
            _stopSyntheticProgress(reset: true);
            _syntheticProgressByImageKey[_imageProgressKey] = 1.0;
            _imageLoadRetries = 0; // Reset retries on success
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
            return _buildCompletedImage(context, state);
        }
      },
    );
  }

  bool _isEhentaiReaderPageUrl(String url) {
    if (widget.sourceId != 'ehentai') {
      return false;
    }

    final lowered = url.toLowerCase();
    return lowered.contains('/s/') &&
        (lowered.contains('e-hentai.org') || lowered.contains('exhentai.org'));
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

  int? _targetDecodeWidth(BuildContext context) {
    if (!_isHeavyReaderSource() ||
        widget.readingMode != ReadingMode.continuousScroll) {
      return null;
    }

    final mediaQuery = MediaQuery.of(context);
    // Use 75% width to keep text/details sharp while still limiting decoder load.
    return ((mediaQuery.size.width * 0.75) * mediaQuery.devicePixelRatio)
        .round();
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
    if (cached != null && cached.isNotEmpty) {
      return cached;
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

      final imageUrl = _extractEhentaiImageUrl(html, readerPageUrl);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _ehentaiResolvedImageCache[readerPageUrl] = imageUrl;
      }
      return imageUrl;
    } catch (_) {
      return null;
    }
  }

  String? _extractEhentaiImageUrl(String html, String baseUrl) {
    final srcOrDataSrc = RegExp(
      '<img[^>]*id=["\']img["\'][^>]*(?:src|data-src)=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);

    if (srcOrDataSrc != null && srcOrDataSrc.trim().isNotEmpty) {
      return _toAbsoluteUrl(srcOrDataSrc.trim(), baseUrl);
    }

    final srcSet = RegExp(
      '<img[^>]*id=["\']img["\'][^>]*srcset=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    if (srcSet != null && srcSet.trim().isNotEmpty) {
      final first = srcSet.split(',').first.trim().split(' ').first.trim();
      if (first.isNotEmpty) {
        return _toAbsoluteUrl(first, baseUrl);
      }
    }

    return null;
  }

  String _toAbsoluteUrl(String value, String baseUrl) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('//')) {
      return 'https:$value';
    }

    try {
      return Uri.parse(baseUrl).resolve(value).toString();
    } catch (_) {
      return value;
    }
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
        'Failed to load image',
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
      {ExtendedImageState? state}) {
    // Responsive sizing based on reading mode
    final bool isContinuousScroll =
        widget.readingMode == ReadingMode.continuousScroll;

    final double cardWidth = isContinuousScroll ? 280 : 240;
    final double previewHeight = isContinuousScroll ? 150 : 170;

    double? progressValue;
    int? progressPercent;
    int loadedBytes = 0;
    int? totalBytes;
    try {
      final dynamic progressEvent = (state as dynamic).loadingProgress;
      final loadedRaw = progressEvent?.cumulativeBytesLoaded;
      final totalRaw = progressEvent?.expectedTotalBytes;

      if (loadedRaw is num) {
        loadedBytes = loadedRaw.toInt();
      }
      if (totalRaw is num) {
        totalBytes = totalRaw.toInt();
      }

      if (totalBytes != null && totalBytes > 0) {
        progressValue = (loadedBytes / totalBytes).clamp(0.0, 1.0);
        progressPercent = (progressValue * 100).floor();
      } else if (loadedBytes > 0) {
        // Fallback estimate when server does not send total bytes.
        // Smoothly approaches 95% and avoids a flat indeterminate loader.
        final estimated = 1 - math.exp(-(loadedBytes / (320 * 1024)));
        progressValue = estimated.clamp(0.02, 0.95);
        progressPercent = (progressValue * 100).floor();
      }

      if (progressValue == null && _syntheticProgressValue > 0) {
        progressValue = _syntheticProgressValue;
        progressPercent = (progressValue * 100).floor();
      }
    } catch (_) {
      // Keep indicator indeterminate when progress fields are unavailable.
      if (_syntheticProgressValue > 0) {
        progressValue = _syntheticProgressValue;
        progressPercent = (progressValue * 100).floor();
      }
    }

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
                    progressPercent != null
                        ? '$progressPercent%'
                        : 'Loading...',
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
                    value: progressValue,
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
                  totalBytes != null && totalBytes > 0
                      ? '${_formatByteSize(loadedBytes)} / ${_formatByteSize(totalBytes)}'
                      : progressPercent != null
                          ? (loadedBytes > 0
                              ? '${_formatByteSize(loadedBytes)} downloaded'
                              : 'Estimating progress...')
                          : 'Downloading image data...',
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
  Widget _buildErrorWidget(BuildContext context, ExtendedImageState state) {
    // Responsive sizing based on reading mode
    final bool isContinuousScroll =
        widget.readingMode == ReadingMode.continuousScroll;
    final double cardSize = isContinuousScroll ? 250 : 200;
    final double logoSize = isContinuousScroll ? 100 : 100;
    final double iconSize = isContinuousScroll ? 24 : 32;

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
                  (_autoRetryTimer?.isActive ?? false)
                      ? 'Retrying...'
                      : 'Failed to load',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: (_autoRetryTimer?.isActive ?? false)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),

                // Page number and retry count
                Text(
                  (_autoRetryTimer?.isActive ?? false)
                      ? 'Page ${widget.pageNumber} • Attempt $_imageLoadRetries/$_maxImageLoadRetries'
                      : 'Page ${widget.pageNumber}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Retry button (hidden if already retrying)
                if (!(_autoRetryTimer?.isActive ?? false))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        state.reLoadImage();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(AppLocalizations.of(context)!.retry),
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
