import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:kuron_native/kuron_native.dart';
import 'package:nhasixapp/core/utils/native_theme_helper.dart';
// import '../../core/utils/webtoon_detector.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/offline_content_manager.dart';
import '../../core/utils/reader_image_repair_utils.dart';
import '../../../domain/entities/reader_settings_entity.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/constants/design_tokens.dart';

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
    this.onDoubleTapGesture,
    this.grayscale = false,
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

  /// If set, double-tap calls this instead of the built-in zoom animation.
  /// Use to toggle reader UI from a parent (e.g. `_readerCubit.toggleUI()`).
  final VoidCallback? onDoubleTapGesture;

  /// Called once (per content ID) when this page is identified as a heavy
  /// animated WebP (≥ 2 MB) while in continuous-scroll mode.
  final VoidCallback? onHeavyImageDetected;

  /// Notifier that emits the currently visible page number.
  /// Forwarded to [AnimatedWebPView] to auto-pause off-screen animations.
  final ValueNotifier<int>? visiblePageNotifier;

  /// Whether the image should be forced to grayscale (Note theme).
  final bool grayscale;

  /// Callback when a heavy image (requires native rendering) is detected.;

  @override
  State<ExtendedImageReaderWidget> createState() =>
      _ExtendedImageReaderWidgetState();

  @visibleForTesting
  static void addHeavyUrlForTesting(String url) =>
      _ExtendedImageReaderWidgetState._heavyImageUrls.add(url);

  @visibleForTesting
  static bool isHeavyUrlForTesting(String url) =>
      _ExtendedImageReaderWidgetState._heavyImageUrls.contains(url);

  static Future<void> clearNativeAnimatedCache() async {
    _ExtendedImageReaderWidgetState._heavyImageUrls.clear();
    _ExtendedImageReaderWidgetState._confirmedAnimatedWebPUrls.clear();
    _ExtendedImageReaderWidgetState._nonNativeAnimatedUrls.clear();
    _ExtendedImageReaderWidgetState._cachedFilePathByUrl.clear();
    _ExtendedImageReaderWidgetState._knownBrokenLocalAvifPaths.clear();
    await clearDiskCachedImages();
  }

  @visibleForTesting
  static void clearHeavyUrlsForTesting() =>
      _ExtendedImageReaderWidgetState._heavyImageUrls.clear();

  @visibleForTesting
  static int get heavyImageThresholdBytesForTesting =>
      _ExtendedImageReaderWidgetState._heavyImageThresholdBytes;

  @visibleForTesting
  static int get ultraHeavyAnimatedImageThresholdBytesForTesting =>
      _ExtendedImageReaderWidgetState._ultraHeavyAnimatedImageThresholdBytes;

  @visibleForTesting
  static bool isLikelyAnimatedWebPForTesting({
    required String url,
    required bool isHeavy,
  }) {
    if (!isHeavy) return false;
    return _looksLikeNativeAnimatedCapableUrl(url);
  }

  @visibleForTesting
  static bool shouldUseNativeAnimatedViewForTesting({
    required String url,
    required bool isHeavy,
    required bool nativeViewAvailable,
    bool confirmedAnimatedWebP = false,
  }) {
    if (!nativeViewAvailable || !isHeavy) return false;
    return confirmedAnimatedWebP || _looksLikeNativeAnimatedCapableUrl(url);
  }

  @visibleForTesting
  static bool shouldNotifyHeavyImageDetectedForTesting({
    required ReadingMode readingMode,
    required bool confirmedAnimatedWebP,
    required bool hasCallback,
    required bool alreadyNotified,
  }) {
    if (!hasCallback) return false;
    if (readingMode != ReadingMode.continuousScroll) return false;
    if (!confirmedAnimatedWebP) return false;
    if (alreadyNotified) return false;
    return true;
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

  static bool _looksLikeNativeAnimatedCapableUrl(String url) {
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
  static Logger get _logger => getIt<Logger>();
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
  static final Set<String> _knownBrokenLocalAvifPaths = <String>{};
  static final Set<String> _heavyImageUrls = <String>{};
  static final Set<String> _notifiedHeavyContentIds = <String>{};
  static final Map<String, String> _cachedFilePathByUrl = <String, String>{};
  static final Set<String> _confirmedAnimatedWebPUrls = <String>{};
  static final Set<String> _nonNativeAnimatedUrls = <String>{};
  static const int _heavyImageThresholdBytes = 2 * 1024 * 1024; // 2 MB

  /// Files ≥ 10 MB get a more aggressive native target width because the
  /// offline reader otherwise pays twice: thumbnail prep + animated playback.
  static const int _ultraHeavyAnimatedImageThresholdBytes =
      10 * 1024 * 1024; // 10 MB
  static const int _maxNativeAvifHeight = 4096;

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  late AnimationController _pinchHintController;
  final GlobalKey<ExtendedImageGestureState> _gestureKey = GlobalKey();
  Future<String?>? _ehentaiResolvedImageFuture;
  Future<Uint8List?>? _mangaFireResolvedImageFuture;

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

  /// Image dimensions parsed from the file header (e.g., `ispe` box for AVIF).
  /// Used to set correct [AspectRatio] in webtoon/continuous-scroll mode so the
  /// ListView item has the right height rather than collapsing to zero.
  Size? _nativeImageSize;

  // 🔄 AUTO-RETRY: Track retry attempts for timeout/network errors
  int _imageLoadRetries = 0;
  static const int _maxImageLoadRetries = 3;
  int _ehentaiResolveRetries = 0;
  static const int _maxEhentaiResolveRetries = 2;
  Timer? _autoRetryTimer;
  bool _isRepairingBrokenImage = false;
  bool _isOpeningSourcePage = false;
  bool _shouldBypassLocalDecode = false;

  /// Whether the one-shot AVIF-decode-failure async re-check has already run.
  /// Prevents an infinite loop: on the second decode failure for the same
  /// widget instance we give up and show the error widget instead of retrying.
  bool _avifDecodeRetried = false;

  /// potentially-animated AVIF URL. Prevents ExtendedImage from attempting
  /// to decode the file before we have a chance to route it to the native
  /// view, which avoids the "getPixels failed with error invalid input" crash
  /// from Android's ImageDecoder attempting to decode an avis sequence.
  bool _awaitingNativeCheck = false;

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
      duration: DesignTokens.durationPageTurn,
      vsync: this,
    );
    // Initialize with dummy animation (will be replaced on double-tap)
    _zoomAnimation = _zoomController.drive(Tween<double>(begin: 1.0, end: 1.0));

    // Brief pinch-to-zoom hint (shown once per page, only when double-tap-zoom is disabled)
    _pinchHintController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    if (widget.onDoubleTapGesture != null && widget.enableZoom) {
      // Delay so the image has time to load first
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _pinchHintController.forward();
      });
    }

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
      final isKnownBrokenAvif = localPath.toLowerCase().endsWith('.avif') &&
          _knownBrokenLocalAvifPaths.contains(localPath);
      _shouldBypassLocalDecode =
          isKnownBrokenAvif || _hasInvalidLocalImagePayloadSync(localPath);
      if (!_shouldBypassLocalDecode) {
        _awaitingNativeCheck = _shouldConvertTallAvisLocalFile(localPath);
        _preCheckLocalFileForHeavy(localPath);
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
      // For AVIF URLs: block ExtendedImage from rendering until we know
      // whether the cached file is animated (→ native) or static (→ Flutter).
      // This prevents Android's ImageDecoder from attempting avis sequences.
      if (widget.imageUrl.toLowerCase().split('?').first.endsWith('.avif')) {
        _awaitingNativeCheck = true;
      }
      _preCheckDiskCacheForHeavy();
    }

    _prepareEhentaiResolveFuture();
    _prepareMangaFireImageFuture();
  }

  /// Async disk-cache check: if a cached .webp file ≥ threshold exists,
  /// seed the static maps and trigger a rebuild to route straight to native.
  void _preCheckDiskCacheForHeavy() {
    getCachedImageFile(widget.imageUrl).then((file) async {
      if (file == null) return;
      final size = file.lengthSync();
      final avifInfo = _inspectAvifHeaderForRouting(file);
      final shouldConvertTallAvis = avifInfo.isAvif &&
          avifInfo.isAvisBrand &&
          (avifInfo.height ?? 0) > _maxNativeAvifHeight;

      if (shouldConvertTallAvis) {
        _logger.i(
          '[NativeWebP] Tall avis detected. Converting to WebP '
          'page=${widget.pageNumber} height=${avifInfo.height}',
        );
        final convertedPath = await KuronNative.instance.convertAvifToWebP(
          inputPath: file.path,
        );
        if (convertedPath != null) {
          final convertedFile = File(convertedPath);
          final convertedExists = convertedFile.existsSync();
          final convertedSize =
              convertedExists ? convertedFile.lengthSync() : 0;
          if (convertedExists && convertedSize > 0) {
            _markHeavyNativeAnimatedImage(
              cacheKey: widget.imageUrl,
              cachedFilePath: convertedPath,
              confirmedAnimatedWebP: true,
            );
            if (!mounted) return;
            final webpInfo =
                _inferNativeAnimatedCapableExtensionFromFileSync(convertedFile);
            final nativeSize =
                (webpInfo.width != null && webpInfo.height != null)
                    ? Size(
                        webpInfo.width!.toDouble(),
                        webpInfo.height!.toDouble(),
                      )
                    : (avifInfo.width != null && avifInfo.height != null)
                        ? Size(
                            avifInfo.width!.toDouble(),
                            avifInfo.height!.toDouble(),
                          )
                        : null;
            setState(() {
              _isHeavyImage = true;
              _isConfirmedAnimatedWebP = true;
              _cachedFilePath = convertedPath;
              _awaitingNativeCheck = false;
              if (nativeSize != null) _nativeImageSize = nativeSize;
            });
            updateKeepAlive();
            _maybeNotifyHeavyImageDetected();
            if (nativeSize != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widget.onImageLoaded?.call(widget.pageNumber, nativeSize);
                }
              });
            }
            _logger.i(
              '[NativeWebP] Tall avis converted to WebP '
              'page=${widget.pageNumber} '
              'src=${(size / 1024 / 1024).toStringAsFixed(1)} MB '
              'out=${(convertedSize / 1024 / 1024).toStringAsFixed(1)} MB',
            );
            return;
          }
        }
        _logger.w(
          '[NativeWebP] Tall avis conversion failed, keep existing fallback path '
          'page=${widget.pageNumber}',
        );
        return;
      }

      final (:format, :width, :height) =
          _inferNativeAnimatedCapableExtensionFromFileSync(file);
      if (format != null) {
        _markHeavyNativeAnimatedImage(
          cacheKey: widget.imageUrl,
          cachedFilePath: file.path,
          confirmedAnimatedWebP: true,
        );
        if (!mounted) return;
        final nativeSize = (width != null && height != null)
            ? Size(width.toDouble(), height.toDouble())
            : null;
        setState(() {
          _isHeavyImage = true;
          _isConfirmedAnimatedWebP = true;
          _cachedFilePath = file.path;
          _awaitingNativeCheck = false;
          if (nativeSize != null) _nativeImageSize = nativeSize;
        });
        updateKeepAlive();
        _logger.i(
          '[NativeWebP] Pre-check HIT: heavy $format from disk cache '
          'page=${widget.pageNumber} '
          'size=${(size / 1024 / 1024).toStringAsFixed(1)} MB',
        );
        _maybeNotifyHeavyImageDetected();
        if (nativeSize != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onImageLoaded?.call(widget.pageNumber, nativeSize);
            }
          });
        }
      }
    }).catchError((Object e) {
      _logger.w('[NativeWebP] Pre-check error: $e');
    }).whenComplete(() {
      // Always unblock the render, whether the file was found, not found,
      // or not animated. ExtendedImage will take over for static AVIF.
      if (mounted && _awaitingNativeCheck) {
        setState(() => _awaitingNativeCheck = false);
      }
    });
  }

  bool _shouldConvertTallAvisLocalFile(String localPath) {
    if (!AnimatedWebPView.isAvailable) {
      return false;
    }

    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        return false;
      }

      final avifInfo = _inspectAvifHeaderForRouting(file);
      return avifInfo.isAvif &&
          avifInfo.isAvisBrand &&
          (avifInfo.height ?? 0) > _maxNativeAvifHeight;
    } catch (_) {
      return false;
    }
  }

  /// Pre-check for offline/local files so heavy animated pages can route
  /// directly to native view on first build. When a tall avis AVIF file is
  /// detected, the file is converted in-place to WebP and metadata is updated.
  Future<void> _preCheckLocalFileForHeavy(String localPath) async {
    if (!AnimatedWebPView.isAvailable) {
      return;
    }

    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        if (_awaitingNativeCheck) {
          setState(() => _awaitingNativeCheck = false);
        }
        return;
      }

      final fileSize = file.lengthSync();
      final avifInfo = _inspectAvifHeaderForRouting(file);
      final shouldConvertTallAvis = avifInfo.isAvif &&
          avifInfo.isAvisBrand &&
          (avifInfo.height ?? 0) > _maxNativeAvifHeight;

      if (shouldConvertTallAvis) {
        _logger.i(
          '[NativeWebP] Local tall avis detected. Converting to WebP '
          'page=${widget.pageNumber} height=${avifInfo.height}',
        );
        final outputPath = buildReplacementImagePath(
          currentImagePath: localPath,
          extension: 'webp',
        );
        final convertedPath = await KuronNative.instance.convertAvifToWebP(
          inputPath: localPath,
          outputPath: outputPath,
        );

        if (convertedPath != null) {
          final convertedFile = File(convertedPath);
          if (convertedFile.existsSync() && convertedFile.lengthSync() > 0) {
            await _deleteLocalPageFormatConflicts(
              currentImagePath: localPath,
              convertedPath: convertedPath,
            );
            await _syncOfflineMetadataForConvertedLocalPage(
              originalLocalPath: localPath,
              convertedLocalPath: convertedPath,
            );

            _markHeavyNativeAnimatedImage(
              cacheKey: widget.imageUrl,
              cachedFilePath: convertedPath,
              confirmedAnimatedWebP: true,
            );
            final webpInfo =
                _inferNativeAnimatedCapableExtensionFromFileSync(convertedFile);
            final nativeSize =
                (webpInfo.width != null && webpInfo.height != null)
                    ? Size(
                        webpInfo.width!.toDouble(),
                        webpInfo.height!.toDouble(),
                      )
                    : (avifInfo.width != null && avifInfo.height != null)
                        ? Size(
                            avifInfo.width!.toDouble(),
                            avifInfo.height!.toDouble(),
                          )
                        : null;

            if (!mounted) {
              _isHeavyImage = true;
              _isConfirmedAnimatedWebP = true;
              _cachedFilePath = convertedPath;
              _awaitingNativeCheck = false;
              if (nativeSize != null) {
                _nativeImageSize = nativeSize;
              }
              return;
            }

            setState(() {
              _isHeavyImage = true;
              _isConfirmedAnimatedWebP = true;
              _cachedFilePath = convertedPath;
              _awaitingNativeCheck = false;
              if (nativeSize != null) {
                _nativeImageSize = nativeSize;
              }
            });
            updateKeepAlive();
            _maybeNotifyHeavyImageDetected();
            if (nativeSize != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widget.onImageLoaded?.call(widget.pageNumber, nativeSize);
                }
              });
            }
            _logger.i(
              '[NativeWebP] Local tall avis converted to WebP '
              'page=${widget.pageNumber} '
              'src=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB '
              'path=$convertedPath',
            );
            return;
          }
        }

        _logger.w(
          '[NativeWebP] Local tall avis conversion failed '
          'page=${widget.pageNumber}',
        );
        if (mounted && _awaitingNativeCheck) {
          setState(() => _awaitingNativeCheck = false);
        } else {
          _awaitingNativeCheck = false;
        }
        return;
      }

      final (:format, :width, :height) =
          _inferNativeAnimatedCapableExtensionFromFileSync(file);
      if (format == null) {
        if (mounted && _awaitingNativeCheck) {
          setState(() => _awaitingNativeCheck = false);
        } else {
          _awaitingNativeCheck = false;
        }
        return;
      }

      _markHeavyNativeAnimatedImage(
        cacheKey: widget.imageUrl,
        cachedFilePath: localPath,
        confirmedAnimatedWebP:
            true, // true for both webp and avif native formats
      );
      _isHeavyImage = true;
      _isConfirmedAnimatedWebP = true;
      _cachedFilePath = localPath;
      _awaitingNativeCheck = false;
      if (width != null && height != null) {
        _nativeImageSize = Size(width.toDouble(), height.toDouble());
      }
      _logger.i(
        '[NativeWebP] Local pre-check HIT: heavy $format '
        'page=${widget.pageNumber} '
        'size=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
      );
      _maybeNotifyHeavyImageDetected();
      if (width != null && height != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onImageLoaded?.call(
              widget.pageNumber,
              Size(width.toDouble(), height.toDouble()),
            );
          }
        });
      }
    } catch (e) {
      _logger.w('[NativeWebP] Local pre-check error: $e');
    } finally {
      if (mounted && _awaitingNativeCheck) {
        setState(() => _awaitingNativeCheck = false);
      } else if (_awaitingNativeCheck) {
        _awaitingNativeCheck = false;
      }
    }
  }

  Future<void> _deleteLocalPageFormatConflicts({
    required String currentImagePath,
    required String convertedPath,
  }) async {
    final directory = Directory(path.dirname(currentImagePath));
    if (!await directory.exists()) {
      return;
    }

    final targetBaseName = path.basenameWithoutExtension(currentImagePath);
    final normalizedConvertedPath = path.normalize(convertedPath);
    final tempPath = '$convertedPath.repairing';
    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }

      final normalizedCandidate = path.normalize(entity.path);
      if (normalizedCandidate == normalizedConvertedPath ||
          normalizedCandidate == path.normalize(tempPath)) {
        continue;
      }

      final extension = path.extension(entity.path).toLowerCase();
      if (!kReaderRepairSupportedImageExtensions.contains(extension)) {
        continue;
      }

      if (path.basenameWithoutExtension(entity.path) != targetBaseName) {
        continue;
      }

      try {
        await entity.delete();
      } catch (e) {
        _logger.w(
          '[NativeWebP] Failed deleting stale local page ${entity.path}: $e',
        );
      }
    }
  }

  Future<void> _syncOfflineMetadataForConvertedLocalPage({
    required String originalLocalPath,
    required String convertedLocalPath,
  }) async {
    try {
      await getIt<OfflineContentManager>().rewriteMetadataForConvertedLocalPage(
        contentId: widget.contentId,
        pageNumber: widget.pageNumber,
        originalLocalPath: originalLocalPath,
        convertedLocalPath: convertedLocalPath,
      );
    } catch (e) {
      _logger.w(
        '[NativeWebP] Failed updating metadata for local conversion '
        'content=${widget.contentId} page=${widget.pageNumber}: $e',
      );
    }
  }

  /// Fire [widget.onHeavyImageDetected] at most once per content ID.
  /// Relevant for continuous-scroll mode regardless of page index.
  void _maybeNotifyHeavyImageDetected() {
    if (!ExtendedImageReaderWidget.shouldNotifyHeavyImageDetectedForTesting(
      readingMode: widget.readingMode,
      confirmedAnimatedWebP: _isConfirmedAnimatedWebP,
      hasCallback: widget.onHeavyImageDetected != null,
      alreadyNotified: _notifiedHeavyContentIds.contains(widget.contentId),
    )) {
      return;
    }
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

  bool _isAvifSource(String source) {
    return source.toLowerCase().split('?').first.endsWith('.avif');
  }

  Future<void> _openFailedAvifExternally(String source) async {
    try {
      if (_isLocalFilePath(source)) {
        await KuronNative.instance.openAvif(
          filePath: _normalizeLocalPath(source),
        );
        return;
      }

      await KuronNative.instance.openWebView(
        url: source,
        backgroundColor: NativeThemeHelper.backgroundColorHex,
        textColor: NativeThemeHelper.textColorHex,
      );
    } catch (e) {
      _logger.w('[AVIF] Failed to open external fallback: $e');
    }
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

  bool _tryNativeAnimatedFallback(String failedUrl) {
    if (!AnimatedWebPView.isAvailable) {
      return false;
    }

    if (!_isLocalFilePath(failedUrl) &&
        failedUrl.toLowerCase().split('?').first.endsWith('.avif')) {
      if (_avifDecodeRetried) {
        return false;
      }
      _avifDecodeRetried = true;
      _logger.w(
        '[NativeWebP] AVIF decode failed, re-inspecting cache: '
        'page=${widget.pageNumber}',
      );
      clearMemoryImageCache(failedUrl);
      _awaitingNativeCheck = true;
      _preCheckDiskCacheForHeavy();
      return true;
    }

    if (!ExtendedImageReaderWidget._looksLikeNativeAnimatedCapableUrl(
      failedUrl,
    )) {
      return false;
    }

    _logger.w(
      '[NativeWebP] Fallback to native animated view after decode failure: '
      'page=${widget.pageNumber}, url=$failedUrl',
    );

    if (!_isLocalFilePath(failedUrl)) {
      clearMemoryImageCache(failedUrl);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _preSeedHeavyImageUrl();
        _isHeavyImage = true;
        _cachedFilePath =
            _cachedFilePathByUrl[widget.imageUrl] ?? _cachedFilePath;
      });
      updateKeepAlive();
      _maybeNotifyHeavyImageDetected();
    });
    return true;
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
      _ehentaiResolveRetries = 0;
      _prepareEhentaiResolveFuture();
      _prepareMangaFireImageFuture();

      if (_isLocalFilePath(widget.imageUrl)) {
        final localPath = _normalizeLocalPath(widget.imageUrl);
        _cachedFilePath = localPath;
        _cachedFilePathByUrl[widget.imageUrl] = localPath;
        final isKnownBrokenAvif = localPath.toLowerCase().endsWith('.avif') &&
            _knownBrokenLocalAvifPaths.contains(localPath);
        _shouldBypassLocalDecode =
            isKnownBrokenAvif || _hasInvalidLocalImagePayloadSync(localPath);
        if (!_shouldBypassLocalDecode) {
          _awaitingNativeCheck = _shouldConvertTallAvisLocalFile(localPath);
          _preCheckLocalFileForHeavy(localPath);
        }
      } else {
        _shouldBypassLocalDecode = false;
        _awaitingNativeCheck = false;
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
    if (localPath.toLowerCase().endsWith('.avif')) {
      _knownBrokenLocalAvifPaths.remove(localPath);
    }
    final shouldBypass = _hasInvalidLocalImagePayloadSync(localPath);

    if (!mounted) {
      _shouldBypassLocalDecode = shouldBypass;
      return;
    }

    setState(() {
      _shouldBypassLocalDecode = shouldBypass;
    });

    if (!shouldBypass) {
      _awaitingNativeCheck = _shouldConvertTallAvisLocalFile(localPath);
      _preCheckLocalFileForHeavy(localPath);
    }
  }

  @override
  void dispose() {
    _pinchHintController.dispose();
    _zoomController.dispose();
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  /// Adaptive BoxFit based on reading mode and image type for optimal reading comfort.
  ///
  /// 🎯 PHASE 2: Automatically detects webtoon images and applies BoxFit.fitWidth
  /// for better vertical scrolling experience.
  BoxFit _getAdaptiveBoxFit() {
    // Use fitWidth for all modes so the image always fills the screen width.
    // This ensures:
    // - Paginated (single/vertical): image fills full width; zooming expands
    //   BEYOND screen in all directions → free pan (no boxed feel)
    // - continuousScroll: standard fill-width behaviour
    // minScale < 1.0 in GestureConfig lets users pinch-out to see wide/landscape
    // images in full if needed.
    return BoxFit.fitWidth;
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

    // 🐛 FIX: Failed-page placeholder — page was skipped during download.
    // Show the repair/redownload card immediately without attempting to load.
    if (widget.imageUrl.startsWith('__failed__:')) {
      return _buildFailedPagePlaceholderWidget(context);
    }

    final normalizedLocalPath = _normalizeLocalPath(widget.imageUrl);
    final effectiveLocalPath = normalizedLocalPath;

    // Check if imageUrl is a local file path
    final isLocalFile = _isLocalFilePath(widget.imageUrl);

    if (isLocalFile) {
      if (_shouldBypassLocalDecode) {
        return _buildErrorWidget(
          context,
          failedSource: effectiveLocalPath,
          onRetry: _retryBrokenLocalImage,
        );
      }

      if (_awaitingNativeCheck) {
        return _buildLoadingIndicator(context);
      }

      if (_shouldUseNativeAnimatedView(effectiveLocalPath)) {
        return _buildNativeAnimatedWebP(
          effectiveLocalPath,
          const {},
          filePathOverride: _cachedFilePath ?? effectiveLocalPath,
        );
      }

      // ponytail: ExtendedImage.file with cacheWidth — pre-decode via
      // precacheImage already populated ImageCache at display resolution.
      // ExtendedImage.file reads from disk + decodes at cacheWidth → fast.

      // Legacy: ExtendedImage.file for local files
      // Without cacheWidth, offline images decode at full resolution (4000px+).
      return ExtendedImage.file(
        File(effectiveLocalPath),
        key:
            ValueKey('extended_image_${widget.contentId}_${widget.pageNumber}'),
        fit: _getAdaptiveBoxFit(),
        cacheWidth: _targetDecodeWidth(context),
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
            // Allow pinch-out to see wide/landscape images, and plenty of
            // pinch-in headroom for reading small text.
            minScale: 0.5,
            maxScale: 5.0,
            animationMinScale: 0.4,
            animationMaxScale: 5.5,
            speed: 1.0,
            inertialSpeed: 100.0,
            initialScale: 1.0,
            inPageView: widget.readingMode != ReadingMode.continuousScroll,
            cacheGesture: false,
            initialAlignment: InitialAlignment.center,
          );
        },
        onDoubleTap: widget.enableZoom
            ? (ExtendedImageGestureState gestureState) {
                if (widget.onDoubleTapGesture != null) {
                  widget.onDoubleTapGesture!();
                } else {
                  _handleDoubleTap(gestureState);
                }
              }
            : null,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              if (!_isLocalFilePath(normalizedLocalPath)) {
                return _buildLoadingIndicator(context, state: state);
              }
              return null; // no loading indicator for local files
            case LoadState.failed:
              if (_tryNativeAnimatedFallback(normalizedLocalPath)) {
                return _buildLoadingIndicator(context);
              }
              _markLocalDecodeAsBroken();
              return _buildErrorWidget(
                context,
                failedSource: effectiveLocalPath,
                onRetry: _retryBrokenLocalImage,
              );
            case LoadState.completed:
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
                  final file = File(effectiveLocalPath);
                  if (file.existsSync()) {
                    final fileSize = file.lengthSync();
                    final (:format, :width, :height) =
                        _inferNativeAnimatedCapableExtensionFromFileSync(file);
                    if (format != null) {
                      _markHeavyNativeAnimatedImage(
                        cacheKey: widget.imageUrl,
                        cachedFilePath: effectiveLocalPath,
                        confirmedAnimatedWebP: true,
                      );
                      final nativeSize = (width != null && height != null)
                          ? Size(width.toDouble(), height.toDouble())
                          : null;
                      setState(() {
                        _isHeavyImage = true;
                        _isConfirmedAnimatedWebP = true;
                        _cachedFilePath = effectiveLocalPath;
                        if (nativeSize != null) _nativeImageSize = nativeSize;
                      });
                      updateKeepAlive();
                      _maybeNotifyHeavyImageDetected();
                      if (nativeSize != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            widget.onImageLoaded
                                ?.call(widget.pageNumber, nativeSize);
                          }
                        });
                      }
                      _logger.i(
                        '[NativeWebP] Local complete => native ($format) '
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
      final effectiveImageUrl = widget.imageUrl;
      final isEhentaiReaderUrl =
          _shouldResolveEhentaiImageUrl(effectiveImageUrl);
      if (!isEhentaiReaderUrl) {
        final headers = widget.sourceId == 'hentainexus'
            ? _buildHentainexusImageHeaders(effectiveImageUrl)
            : widget.httpHeaders;

        // ponytail: ExtendedImage.network handles caching + cacheWidth.
        // Pre-decode via precacheImage already populated ImageCache → instant.
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

  void _prepareMangaFireImageFuture() {
    if (_shouldResolveMangaFireImageBytes(widget.imageUrl)) {
      _mangaFireResolvedImageFuture =
          _resolveMangaFireImageBytes(widget.imageUrl);
      return;
    }

    _mangaFireResolvedImageFuture = null;
  }

  Widget _buildNetworkImage(
    BuildContext context,
    String rawUrl, {
    Map<String, String>? headers,
    String? forceUrl,
  }) {
    final targetUrl = forceUrl ?? rawUrl;
    final urlParts = targetUrl.split('|');
    final url = urlParts[0];
    final fallbackUrl = urlParts.length > 1 ? urlParts[1] : null;

    if (_shouldResolveMangaFireImageBytes(url)) {
      return FutureBuilder<Uint8List?>(
        future: _mangaFireResolvedImageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoadingIndicator(context);
          }

          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return _buildStandardNetworkImage(context, rawUrl, url, fallbackUrl,
                headers: headers);
          }

          return _buildMemoryImage(context, bytes);
        },
      );
    }

    return _buildStandardNetworkImage(context, rawUrl, url, fallbackUrl,
        headers: headers);
  }

  Widget _buildStandardNetworkImage(
    BuildContext context,
    String rawUrl,
    String url,
    String? fallbackUrl, {
    Map<String, String>? headers,
  }) {
    // Only route to the native animated view after this URL has actually been
    // identified as a heavy animated WebP. Small/normal .webp images should
    // continue through ExtendedImage.network.
    final isLikelyAnimatedUrl = _isLikelyAnimatedUrl(url);
    if (_shouldUseNativeAnimatedView(url)) {
      return _buildNativeAnimatedWebP(url, headers);
    }

    // Block ExtendedImage from decoding while the async native-format check
    // is in flight. Prevents "getPixels failed: invalid input" when Android's
    // ImageDecoder encounters an avis animated-AVIF sequence.
    if (_awaitingNativeCheck) {
      return _buildLoadingIndicator(context);
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
      // ponytail: ALL static images use FilterQuality.low (bilinear) —
      // cacheWidth at display size makes nearest-neighbor (none) acceptable.
      // Animated WebP uses FilterQuality.none (fastest per-frame).
      filterQuality:
          isLikelyAnimatedUrl ? FilterQuality.none : FilterQuality.low,
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
          minScale: 0.5,
          maxScale: 5.0,
          animationMinScale: 0.4,
          animationMaxScale: 5.5,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: 1.0,
          inPageView: widget.readingMode != ReadingMode.continuousScroll,
          cacheGesture: false,
          initialAlignment: InitialAlignment.center,
        );
      },
      onDoubleTap: widget.enableZoom
          ? (ExtendedImageGestureState gestureState) {
              if (widget.onDoubleTapGesture != null) {
                widget.onDoubleTapGesture!();
              } else {
                _handleDoubleTap(gestureState);
              }
            }
          : null,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
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
              } catch (e) {
                _logger.w('Heavy image detection failed', error: e);
              }
            }

            return _buildLoadingIndicator(context, state: state);
          case LoadState.failed:
            if (_tryRefreshEhentaiResolvedImageUrl(url)) {
              return _buildLoadingIndicator(context);
            }
            if (_tryNativeAnimatedFallback(url)) {
              return _buildLoadingIndicator(context);
            }
            if (fallbackUrl != null) {
              _logger.w(
                  '🔄 Reader falling back to secondary network URL: $fallbackUrl');
              return _buildNetworkImage(context, rawUrl,
                  headers: headers, forceUrl: fallbackUrl);
            }
            // 🔄 AUTO-RETRY: Check if should auto-retry (timeout/network error)
            if (_shouldAutoRetryImage(state) &&
                _imageLoadRetries < _maxImageLoadRetries) {
              _scheduleAutoRetry(state);
            }
            return _buildErrorWidget(
              context,
              state: state,
              failedSource: url,
            );
          case LoadState.completed:
            _imageLoadRetries = 0; // Reset retries on success
            _ehentaiResolveRetries = 0;
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
                  'page=${widget.pageNumber}',
                );
                final (:format, :width, :height) =
                    _inferNativeAnimatedCapableExtensionFromFileSync(cacheFile);
                if (format != null) {
                  _markHeavyNativeAnimatedImage(
                    cacheKey: url,
                    cachedFilePath: cacheFile.path,
                    confirmedAnimatedWebP: true,
                  );

                  // 🔥 Evict from ExtendedImage memory cache so Flutter's
                  // MultiFrameImageStreamCompleter stops decoding animated
                  // frames on the raster thread. The native view takes over.
                  clearMemoryImageCache(url);

                  if (!mounted) return;
                  final nativeSize = (width != null && height != null)
                      ? Size(width.toDouble(), height.toDouble())
                      : null;
                  setState(() {
                    _isHeavyImage = true;
                    _isConfirmedAnimatedWebP = true; // stops re-inspection loop
                    _cachedFilePath = cacheFile.path;
                    if (nativeSize != null) _nativeImageSize = nativeSize;
                  });
                  updateKeepAlive();
                  _maybeNotifyHeavyImageDetected();
                  if (nativeSize != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        widget.onImageLoaded
                            ?.call(widget.pageNumber, nativeSize);
                      }
                    });
                  }
                  _logger.i(
                    '[NativeWebP] => AnimatedImageDrawable ($format): '
                    'page=${widget.pageNumber} size=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB'
                    ' path=${cacheFile.path}',
                  );
                } else {
                  _nonNativeAnimatedUrls.add(url);
                  _logger.d(
                    '[NativeWebP] Not a native-animated candidate '
                    '(${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB), '
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
  ///
  /// In continuous-scroll (webtoon) mode, the ListView item has no intrinsic
  /// height because [SizedBox.expand] inside [AnimatedWebPView] has none.
  /// When [_nativeImageSize] is known we wrap the view with [AspectRatio] so
  /// the ListView gives it the correct proportional height.
  Widget _buildNativeAnimatedWebP(
    String url,
    Map<String, String>? headers, {
    String? filePathOverride,
  }) {
    final resolvedFilePath = filePathOverride ?? _cachedFilePath;
    final playInlineInContinuousScroll =
        widget.readingMode == ReadingMode.continuousScroll;

    Widget nativeView = RepaintBoundary(
      child: AnimatedWebPView(
        key: ValueKey('native_webp_${widget.contentId}_${widget.pageNumber}'),
        url: url,
        filePath: resolvedFilePath,
        headers: headers ?? const {},
        targetWidth: _nativeDecodeWidth(context),
        autoPlay: playInlineInContinuousScroll || _shouldAutoPlayAnimatedView,
        pageNumber: widget.pageNumber,
        visiblePageNotifier: widget.visiblePageNotifier,
        grayscale: widget.grayscale,
        loadingBuilder: (context, receivedBytes, totalBytes) =>
            _buildLoadingIndicator(
          context,
          loadedBytesOverride: receivedBytes,
          totalBytesOverride: totalBytes,
        ),
        fallback: _buildLoadingIndicator(context),
      ),
    );

    // In webtoon/continuous-scroll mode, ListView items have no intrinsic
    // height so SizedBox.expand inside AnimatedWebPView collapses to zero.
    // Apply AspectRatio so the list item gets the correct proportional height.
    if (widget.readingMode == ReadingMode.continuousScroll &&
        _nativeImageSize != null &&
        _nativeImageSize!.width > 0 &&
        _nativeImageSize!.height > 0) {
      nativeView = AspectRatio(
        aspectRatio: _nativeImageSize!.width / _nativeImageSize!.height,
        child: nativeView,
      );
    }

    return nativeView;
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

  bool _isHeavyReaderSource() {
    switch (widget.sourceId?.toLowerCase()) {
      case 'hentainexus':
      case 'ehentai':
        return true;
      default:
        return false;
    }
  }

  bool _shouldInspectCachedFileForAnimatedWebP(String url) {
    if (_nonNativeAnimatedUrls.contains(url)) {
      return false;
    }

    // Always inspect AVIF files after download — brand (avis vs avif/mif1)
    // and image height (≤ 4096 vs > 4096) cannot be determined from the URL.
    // _inferNativeAnimatedCapableExtensionFromFileSync handles the precise check.
    final path = url.toLowerCase().split('?').first;
    return (widget.sourceId ?? '').toLowerCase() == 'ehentai' ||
        ExtendedImageReaderWidget._looksLikeNativeAnimatedCapableUrl(url) ||
        path.endsWith('.avif');
  }

  void _markHeavyNativeAnimatedImage({
    required String cacheKey,
    required String cachedFilePath,
    required bool confirmedAnimatedWebP,
  }) {
    _heavyImageUrls.add(cacheKey);
    _cachedFilePathByUrl[cacheKey] = cachedFilePath;
    if (confirmedAnimatedWebP) {
      _confirmedAnimatedWebPUrls.add(cacheKey);
    }
  }

  static ({bool isAvif, bool isAvisBrand, int? width, int? height})
      _inspectAvifHeaderForRouting(File file) {
    const empty = (
      isAvif: false,
      isAvisBrand: false,
      width: null,
      height: null,
    );
    RandomAccessFile? raf;
    try {
      raf = file.openSync(mode: FileMode.read);
      final length = raf.lengthSync();
      if (length < 16) {
        return empty;
      }

      final sampleLength = length < 4096 ? length : 4096;
      final bytes = raf.readSync(sampleLength);
      if (inferImageExtension(bytes: bytes) != 'avif') {
        return empty;
      }

      var isAvisBrand = false;
      if (bytes.length >= 12) {
        const int kAvis0 = 0x61, kAvis1 = 0x76, kAvis2 = 0x69, kAvis3 = 0x73;
        isAvisBrand = bytes[8] == kAvis0 &&
            bytes[9] == kAvis1 &&
            bytes[10] == kAvis2 &&
            bytes[11] == kAvis3;
      }

      int? parsedWidth;
      int? parsedHeight;
      const kIspe = <int>[0x69, 0x73, 0x70, 0x65]; // 'ispe'
      for (int i = 0; i <= bytes.length - 16; i++) {
        if (_matchesBytes(bytes, i, kIspe)) {
          final width = ((bytes[i + 8] & 0xFF) << 24) |
              ((bytes[i + 9] & 0xFF) << 16) |
              ((bytes[i + 10] & 0xFF) << 8) |
              (bytes[i + 11] & 0xFF);
          final height = ((bytes[i + 12] & 0xFF) << 24) |
              ((bytes[i + 13] & 0xFF) << 16) |
              ((bytes[i + 14] & 0xFF) << 8) |
              (bytes[i + 15] & 0xFF);
          parsedWidth = width > 0 ? width : null;
          parsedHeight = height > 0 ? height : null;
          break;
        }
      }

      return (
        isAvif: true,
        isAvisBrand: isAvisBrand,
        width: parsedWidth,
        height: parsedHeight,
      );
    } catch (_) {
      return empty;
    } finally {
      raf?.closeSync();
    }
  }

  /// Returns `(format, width, height)` if the file is a native-renderable
  /// animated image, or `(null, null, null)` if Flutter codec should be used.
  ///
  /// `width` and `height` are extracted from the `ispe` box for AVIF files so
  /// the caller can compute the correct aspect ratio for webtoon/scroll layout.
  /// For WebP, dimensions are not parsed (returns `null` for width/height).
  static ({String? format, int? width, int? height})
      _inferNativeAnimatedCapableExtensionFromFileSync(File file) {
    const empty = (format: null, width: null, height: null);
    RandomAccessFile? raf;
    try {
      raf = file.openSync(mode: FileMode.read);
      final length = raf.lengthSync();
      if (length < 16) {
        return empty;
      }

      // Read a wider AVIF header window so `ispe` is still found when the box
      // is pushed back by extra metadata. Without width/height we cannot apply
      // the native AspectRatio wrapper, which makes some AVIF pages appear not
      // to fill the reader width.
      final sampleLength = length < 4096 ? length : 4096;
      final bytes = raf.readSync(sampleLength);
      final ext = inferImageExtension(bytes: bytes);
      if (ext == 'webp') {
        // Only route to native AnimatedWebPView if the header confirms animation.
        // Static WebP files (thumbnails, cover images, etc.) must stay on the
        // Flutter codec path — returning non-null here marks the image as heavy
        // which prevents normal keep-alive recycling and forces native rendering.
        if (!_looksLikeAnimatedWebPHeader(bytes)) return empty;

        int? width;
        int? height;
        int offset = 12;
        while (offset + 8 <= bytes.length) {
          final chunkType =
              String.fromCharCodes(bytes.sublist(offset, offset + 4));
          final chunkSize = bytes[offset + 4] |
              (bytes[offset + 5] << 8) |
              (bytes[offset + 6] << 16) |
              (bytes[offset + 7] << 24);

          if (chunkType == 'VP8X' &&
              chunkSize >= 10 &&
              offset + 18 <= bytes.length) {
            width = 1 +
                (bytes[offset + 12] |
                    (bytes[offset + 13] << 8) |
                    (bytes[offset + 14] << 16));
            height = 1 +
                (bytes[offset + 15] |
                    (bytes[offset + 16] << 8) |
                    (bytes[offset + 17] << 16));
            break;
          }

          offset += 8 + chunkSize;
          if (chunkSize % 2 != 0) offset++;
        }

        return (format: 'webp', width: width, height: height);
      }
      if (ext == 'avif') {
        // Route to native AnimatedWebPView only for avis-brand AVIF within the
        // hardware AV1 decoder's dimension limit.
        //
        // Background:
        //   manga18.club encodes manga pages as tiled AVIF sequences (brand:
        //   avis + msf1). Both working and failing files share identical ftyp
        //   brands — the only discriminator is image HEIGHT.
        //
        //   MIUI HeifDecoderImpl uses a hardware AV1 decoder capped at ~4096px.
        //   Images taller than that crash with "videoFrame is a nullptr".
        //   Flutter's libavif uses software AV1 (dav1d/aom) with no size limit.
        //
        //   Verified:
        //     04.avif  1440×3444  (≤ 4096) → native  ✓ works
        //     26.avif  1440×5044  (> 4096) → Flutter ✓ works
        //
        // Step 1: check major brand — only avis targets native view.
        if (bytes.length < 12) return empty;
        const int kAvis0 = 0x61, kAvis1 = 0x76, kAvis2 = 0x69, kAvis3 = 0x73;
        if (bytes[8] != kAvis0 ||
            bytes[9] != kAvis1 ||
            bytes[10] != kAvis2 ||
            bytes[11] != kAvis3) {
          return empty; // avif / mif1 brand → Flutter codec
        }

        // Step 2: parse the ispe (image spatial extents) box for image dimensions.
        //
        // ispe box layout:
        //   [4B box-size][4B 'ispe'][4B version+flags][4B width][4B height]
        //    ^box_start  ^i         i+4                i+8       i+12
        //
        // The ispe box for manga18.club AVIF files often sits near byte ~203,
        // but some files place it later. Search the wider sample and read the
        // dimensions so scroll layout can reserve full-width height correctly.
        const kIspe = <int>[0x69, 0x73, 0x70, 0x65]; // 'ispe'

        for (int i = 0; i <= bytes.length - 16; i++) {
          if (_matchesBytes(bytes, i, kIspe)) {
            final int width = ((bytes[i + 8] & 0xFF) << 24) |
                ((bytes[i + 9] & 0xFF) << 16) |
                ((bytes[i + 10] & 0xFF) << 8) |
                (bytes[i + 11] & 0xFF);
            final int height = ((bytes[i + 12] & 0xFF) << 24) |
                ((bytes[i + 13] & 0xFF) << 16) |
                ((bytes[i + 14] & 0xFF) << 8) |
                (bytes[i + 15] & 0xFF);
            if (height > _maxNativeAvifHeight) {
              return empty; // too tall for hardware AV1 decoder → Flutter
            }
            // avis + height ≤ 4096 → native AnimatedWebPView
            return (
              format: 'avif',
              width: width > 0 ? width : null,
              height: height > 0 ? height : null,
            );
          }
        }

        // Keep AVIF on the Flutter codec path when dimensions are unknown.
        // The native view needs a known aspect ratio to reserve the correct
        // full-width layout in the reader.
        return empty;
      }
      return empty;
    } catch (_) {
      return empty;
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
    // ponytail: decode at display resolution for ALL modes — 25× less GPU
    // texture upload. Non-CS pages change via swipe which is a full rebuild;
    // decoding full-res 4000px images every swipe causes visible jank.
    // Pinch-zoom: ExtendedImage reloads from disk/memory cache when needed.
    if (!(_isHeavyReaderSource() || _isHeavyImage)) {
      // Non-heavy, non-animated: decode at exact display width — no waste.
      final mediaQuery = MediaQuery.of(context);
      return (mediaQuery.size.width * mediaQuery.devicePixelRatio).round();
    }

    final mediaQuery = MediaQuery.of(context);
    // Animated WebP: 40% — each frame of a 45-frame 1416×1608 animation at
    // 75% would still be ~2.5 MB raw; at 40% it drops to ~700 KB per frame,
    // bringing the total decoded footprint from ~112 MB to ~31 MB.
    // Static heavy: 75% — keeps text/detail readable.
    // Normal images: 100% width × DPR — exact display size, 0 waste.
    final bool animatedImage = isLikelyAnimatedUrl ??
        _isLikelyAnimatedUrl(imageUrl ?? widget.imageUrl);
    final bool heavyImage = _isHeavyReaderSource() || _isHeavyImage;
    final double factor = animatedImage ? 0.40 : (heavyImage ? 0.75 : 1.0);
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

  Widget _buildMemoryImage(BuildContext context, Uint8List bytes) {
    final decodeWidth = _targetDecodeWidth(
      context,
      imageUrl: widget.imageUrl,
      isLikelyAnimatedUrl: false,
    );

    return ExtendedImage.memory(
      bytes,
      key: ValueKey('extended_memory_${widget.contentId}_${widget.pageNumber}'),
      fit: _getAdaptiveBoxFit(),
      filterQuality: FilterQuality.low,
      mode: widget.enableZoom &&
              widget.readingMode != ReadingMode.continuousScroll
          ? ExtendedImageMode.gesture
          : ExtendedImageMode.none,
      clearMemoryCacheWhenDispose:
          ExtendedImageReaderWidget.shouldClearMemoryCacheOnDisposeForTesting(
        readingMode: widget.readingMode,
        isHeavy: _isHeavyImage,
        isHeavyReaderSource: _isHeavyReaderSource(),
      ),
      cacheWidth: decodeWidth,
      extendedImageGestureKey: _gestureKey,
      initGestureConfigHandler: (state) {
        return GestureConfig(
          minScale: 0.5,
          maxScale: 5.0,
          animationMinScale: 0.4,
          animationMaxScale: 5.5,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: 1.0,
          inPageView: widget.readingMode != ReadingMode.continuousScroll,
          initialAlignment: InitialAlignment.center,
        );
      },
      onDoubleTap: widget.onDoubleTapGesture != null
          ? null
          : (state) => _handleDoubleTap(state),
    );
  }

  bool _shouldResolveMangaFireImageBytes(String url) {
    return widget.sourceId == 'mangafire' && url.contains('#scrambled_');
  }

  Future<Uint8List?> _resolveMangaFireImageBytes(String url) async {
    try {
      return await KuronNative.instance.downloadBinary(
        url: url,
        headers: widget.httpHeaders ?? const <String, String>{},
      );
    } catch (e) {
      _logger.w('Failed to resolve MangaFire image bytes: $e');
      return null;
    }
  }

  /// Build a card for a page that was skipped during download (timeout/error).
  /// Shows the page number and a "Download page" button that calls [onRepairBrokenImage].
  Widget _buildFailedPagePlaceholderWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasRepair = widget.onRepairBrokenImage != null;
    final bool hasSourcePageFallback = widget.onOpenSourcePageForRepair != null;
    final isRepairing = _isRepairingBrokenImage;
    final isOpeningSourcePage = _isOpeningSourcePage;
    final isActionBusy = isRepairing || isOpeningSourcePage;

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_download_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.readerPageNotDownloaded(widget.pageNumber),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.readerPageSkippedDuringDownload,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              if (hasSourcePageFallback) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isActionBusy
                        ? null
                        : () async {
                            setState(() {
                              _isOpeningSourcePage = true;
                            });

                            try {
                              await widget.onOpenSourcePageForRepair!.call();
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isOpeningSourcePage = false;
                                });
                              }
                            }
                          },
                    icon: isOpeningSourcePage
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
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
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusLg),
                      ),
                    ),
                  ),
                ),
              ],
              if (hasRepair) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isActionBusy
                        ? null
                        : () async {
                            setState(() {
                              _isRepairingBrokenImage = true;
                            });

                            try {
                              await widget.onRepairBrokenImage!.call();
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isRepairingBrokenImage = false;
                                });
                              }
                            }
                          },
                    icon: isRepairing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.download_outlined, size: 18),
                    label: Text(
                      isRepairing
                          ? l10n.readerRepairingImage
                          : l10n.readerRedownloadImage,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
    // final double previewHeight = isContinuousScroll ? 150 : 170;

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
    } catch (_) {}

    final bool hasKnownTotal = totalBytes != null && totalBytes > 0;
    final bool hasRealByteCount = loadedBytes > 0;
    final int resolvedTotalBytes = totalBytes ?? 0;
    final bool isConvertingBadAvif = _awaitingNativeCheck;
    final String headlineText = isConvertingBadAvif
        ? l10n.processing
        : hasKnownTotal
            ? '$progressPercent%'
            : hasRealByteCount
                ? _formatByteSize(loadedBytes)
                : l10n.loading;
    final String detailText = isConvertingBadAvif
        ? l10n.processingBadAvifToWebp
        : hasKnownTotal
            ? '${_formatByteSize(loadedBytes)} / ${_formatByteSize(resolvedTotalBytes)}'
            : hasRealByteCount
                ? l10n.downloaded(_formatByteSize(loadedBytes))
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
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
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
    String? failedSource,
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
    final resolvedFailedSource = failedSource ?? widget.imageUrl;
    final canOpenLocalAvif = _isLocalFilePath(resolvedFailedSource) &&
        _isAvifSource(resolvedFailedSource);
    final canOpenRemoteAvif = !_isLocalFilePath(resolvedFailedSource) &&
        _isAvifSource(resolvedFailedSource);
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
                          image: AssetImage('assets/icons/frame.webp'),
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
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusLg),
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
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusLg),
                        ),
                      ),
                    ),
                  ),

                if (!isRetrying && widget.onRepairBrokenImage != null)
                  const SizedBox(height: 8),

                if (!isRetrying && canOpenLocalAvif) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isActionBusy
                          ? null
                          : () =>
                              _openFailedAvifExternally(resolvedFailedSource),
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: Text(l10n.readerOpenInGallery),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusLg),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

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
                        elevation: DesignTokens.elevationMd,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusLg),
                        ),
                      ),
                    ),
                  ),

                if (!isRetrying && canOpenRemoteAvif) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isActionBusy
                          ? null
                          : () =>
                              _openFailedAvifExternally(resolvedFailedSource),
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: Text(l10n.openInBrowser),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusLg),
                        ),
                      ),
                    ),
                  ),
                ],
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
    final isLikelyAnimatedImage =
        _isLikelyAnimatedUrl(imageUrl ?? widget.imageUrl);
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
      animation: Listenable.merge([_zoomController, _pinchHintController]),
      builder: (context, child) {
        final gestureState = _gestureKey.currentState;
        final currentScale = gestureState?.gestureDetails?.totalScale ?? 1.0;
        final isZoomed = currentScale > 1.2;
        // Pinch hint: fade in then out during _pinchHintController lifetime
        final hintOpacity = _pinchHintController.value < 0.2
            ? _pinchHintController.value / 0.2
            : _pinchHintController.value > 0.7
                ? (1.0 - _pinchHintController.value) / 0.3
                : 1.0;
        final showHint = widget.onDoubleTapGesture != null &&
            _pinchHintController.isAnimating &&
            !isZoomed;

        return Stack(
          alignment: Alignment.center,
          children: [
            Center(child: imageWidget),
            // Zoom level indicator (shown when zoomed in)
            if (isZoomed && widget.readingMode != ReadingMode.continuousScroll)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
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
            // Pinch-to-zoom hint (shown briefly on page first open)
            if (showHint)
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: hintOpacity.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radius2xl),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pinch,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.readerPinchToZoom,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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

    _logger.i(
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
