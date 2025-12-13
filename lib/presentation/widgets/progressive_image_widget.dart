import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:logger/logger.dart';

import '../../core/constants/text_style_const.dart';
import '../../l10n/app_localizations.dart';
import '../../services/image_cache_service.dart';
import '../../services/local_image_preloader.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/di/service_locator.dart';

/// Progressive Image Widget with enhanced local file priority
///
/// Loading priority:
/// 1. Downloaded content (nhasix/[id]/images/)
/// 2. Local cache
/// 3. Network with placeholder/error handling
///
/// Features:
/// - Fast local file detection
/// - Shimmer placeholder
/// - Error state handling
/// - Memory optimization
/// - Support for both page images and thumbnails
class ProgressiveImageWidget extends StatefulWidget {
  const ProgressiveImageWidget({
    super.key,
    required this.networkUrl,
    this.contentId,
    this.pageNumber,
    this.isThumbnail = false,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
  });

  final String networkUrl;
  final String? contentId;
  final int? pageNumber;
  final bool isThumbnail;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  @override
  State<ProgressiveImageWidget> createState() => _ProgressiveImageWidgetState();
}

class _ProgressiveImageWidgetState extends State<ProgressiveImageWidget> {
  static final Logger _logger = Logger();
  static final Map<String, String?> _pathCache =
      {}; // ✅ Cache for resolved paths

  String? _cachedLocalPath;
  bool _isLocalPathResolved = false;

  @override
  void initState() {
    super.initState();
    _resolveLocalPath();
  }

  @override
  void didUpdateWidget(ProgressiveImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-resolve if content or page changed
    if (oldWidget.contentId != widget.contentId ||
        oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.isThumbnail != widget.isThumbnail) {
      _cachedLocalPath = null;
      _isLocalPathResolved = false;
      _resolveLocalPath();
    }
  }

  Future<void> _resolveLocalPath() async {
    if (widget.contentId == null) {
      if (mounted) {
        setState(() {
          _isLocalPathResolved = true;
        });
      }
      return;
    }

    // ✅ Check cache first to avoid repeated calls
    final cacheKey =
        '${widget.contentId}_${widget.pageNumber}_${widget.isThumbnail}';
    if (_pathCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _cachedLocalPath = _pathCache[cacheKey];
          _isLocalPathResolved = true;
        });
      }
      return;
    }

    if (kDebugMode) {
      _logger.d(
          '🔍 Resolving local path for contentId: ${widget.contentId}, pageNumber: ${widget.pageNumber}, isThumbnail: ${widget.isThumbnail}');
    }

    // ✅ Track performance of local path resolution
    final result = await PerformanceMonitor.timeOperation(
      'image_local_path_resolution',
      () async {
        final localPath = await _getLocalImagePath();
        return localPath;
      },
      metadata: {
        'content_id': widget.contentId,
        'page_number': widget.pageNumber,
        'is_thumbnail': widget.isThumbnail,
      },
    );

    // ✅ Cache the result
    _pathCache[cacheKey] = result;

    if (kDebugMode && result != null) {
      _logger.d('✅ Local path resolved: $result');
    }

    if (mounted) {
      setState(() {
        _cachedLocalPath = result;
        _isLocalPathResolved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no contentId provided, fallback to network only
    if (widget.contentId == null) {
      return _buildNetworkImage();
    }

    // Show placeholder while resolving local path
    if (!_isLocalPathResolved) {
      return _buildPlaceholder();
    }

    // Use cached local path if available
    if (_cachedLocalPath != null) {
      return _buildLocalImage(_cachedLocalPath!);
    }

    // Fallback to network
    return _buildNetworkImage();
  }

  /// Get local image path based on type (thumbnail or page)
  Future<String?> _getLocalImagePath() async {
    if (widget.contentId == null) return null;

    String? localPath;

    if (widget.isThumbnail) {
      localPath =
          await LocalImagePreloader.getLocalThumbnailPath(widget.contentId!);
      if (kDebugMode && localPath != null) {
        _logger.d('🖼️ Thumbnail found for ${widget.contentId}: $localPath');
      }
    } else if (widget.pageNumber != null) {
      localPath = await LocalImagePreloader.getLocalImagePath(
          widget.contentId!, widget.pageNumber!);
      if (kDebugMode && localPath != null) {
        _logger.d(
            '📄 Page image found for ${widget.contentId} page ${widget.pageNumber}: $localPath');
      }
    }

    return localPath;
  }

  /// Build local file image
  Widget _buildLocalImage(String localPath) {
    if (kDebugMode) {
      _logger.d('📸 Using local image: $localPath');
    }

    Widget imageWidget = Image.file(
      File(localPath),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          _logger.e('❌ Error loading local image from $localPath: $error');
        }
        // If local file fails, fallback to network
        return _buildNetworkImage();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildPlaceholder();
      },
    );

    // Apply border radius if specified
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Build network image with caching
  Widget _buildNetworkImage() {
    if (kDebugMode) {
      _logger.d('📡 Loading network image: ${widget.networkUrl}');
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: widget.networkUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth ?? (widget.isThumbnail ? 400 : 800),
      memCacheHeight:
          widget.memCacheHeight ?? (widget.isThumbnail ? 600 : 1200),
      placeholder: (context, url) => widget.placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) =>
          widget.errorWidget ?? _buildErrorWidget(),
      fadeInDuration: widget.fadeInDuration,
      fadeOutDuration: widget.fadeOutDuration,
    );

    // Apply border radius if specified
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Build shimmer placeholder
  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.8),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: widget.borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: widget.isThumbnail ? 24 : 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          if (!widget.isThumbnail) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)?.imageNotAvailable ??
                  'Image not available',
              style: TextStyleConst.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Specialized Progressive Image Widget for Reader Screen
/// Optimized for full-screen reading with enhanced local file support
class ProgressiveReaderImageWidget extends StatefulWidget {
  const ProgressiveReaderImageWidget({
    super.key,
    required this.networkUrl,
    required this.contentId,
    required this.pageNumber,
    this.fit = BoxFit.contain,
    this.height,
    this.onLoadingStateChange,
  });

  final String networkUrl;
  final String contentId;
  final int pageNumber;
  final BoxFit fit;
  final double? height;
  final void Function(bool isLoading)? onLoadingStateChange;

  @override
  State<ProgressiveReaderImageWidget> createState() =>
      _ProgressiveReaderImageWidgetState();
}

class _ProgressiveReaderImageWidgetState
    extends State<ProgressiveReaderImageWidget> {
  static final Logger _logger = Logger();
  late final ImageCacheService _imageCacheService;
  String? _cachedLocalPath;
  bool _isLocalPathResolved = false;
  Size? _imageSize; // Store original image dimensions

  @override
  void initState() {
    super.initState();
    // Get ImageCacheService from service locator
    _imageCacheService = getIt<ImageCacheService>();
    _resolveLocalPath();
  }

  @override
  void didUpdateWidget(ProgressiveReaderImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-resolve if content or page changed
    if (oldWidget.contentId != widget.contentId ||
        oldWidget.pageNumber != widget.pageNumber) {
      _cachedLocalPath = null;
      _isLocalPathResolved = false;
      _resolveLocalPath();
    }
  }

  Future<void> _resolveLocalPath() async {
    widget.onLoadingStateChange?.call(true);

    if (kDebugMode) {
      _logger.i(
          '🖼️ READER IMAGE DEBUG: Resolving contentId: ${widget.contentId}, pageNumber: ${widget.pageNumber}');
      _logger.d('🌐 Network URL: ${widget.networkUrl}');
    }

    // Priority 1: Check ImageCacheService (memory + disk cache with TTL)
    final cachedImage =
        await _imageCacheService.getCachedImage(widget.networkUrl);
    if (cachedImage != null) {
      if (kDebugMode) {
        _logger.d(
            'Reader: ✅ Found cached image in ImageCacheService: ${cachedImage.path}');
      }

      if (mounted) {
        setState(() {
          _cachedLocalPath = cachedImage.path;
          _isLocalPathResolved = true;
        });
        widget.onLoadingStateChange?.call(false);
      }
      return;
    }

    // Priority 2: Check LocalImagePreloader (downloaded content)
    final localPath = await LocalImagePreloader.getLocalImagePath(
      widget.contentId,
      widget.pageNumber,
    );

    if (localPath != null) {
      // Found local image
      if (kDebugMode) {
        _logger.d('Reader: ✅ Found local image at: $localPath');
      }

      if (mounted) {
        setState(() {
          _cachedLocalPath = localPath;
          _isLocalPathResolved = true;
        });
        widget.onLoadingStateChange?.call(false);
      }
      return;
    }

    // Priority 3: Download and cache using LocalImagePreloader
    if (kDebugMode) {
      _logger.d(
          'Reader: 📥 No local image found, downloading and caching: ${widget.networkUrl}');
    }

    final cachedPath = await LocalImagePreloader.downloadAndCacheImage(
      widget.networkUrl,
      widget.contentId,
      widget.pageNumber,
    );

    if (cachedPath != null) {
      if (kDebugMode) {
        _logger.d('Reader: ✅ Successfully cached image at: $cachedPath');
      }

      // Also cache in ImageCacheService for future fast access
      try {
        final imageBytes = await File(cachedPath).readAsBytes();
        await _imageCacheService.cacheImage(widget.networkUrl, imageBytes);
        if (kDebugMode) {
          _logger.d('Reader: ✅ Also cached in ImageCacheService');
        }
      } catch (e) {
        if (kDebugMode) {
          _logger.w('Reader: ⚠️ Failed to cache in ImageCacheService: $e');
        }
      }

      if (mounted) {
        setState(() {
          _cachedLocalPath = cachedPath;
          _isLocalPathResolved = true;
        });
        widget.onLoadingStateChange?.call(false);
      }
    } else {
      // Cache failed, will fallback to network
      if (kDebugMode) {
        _logger.d(
            'Reader: ❌ Failed to cache image, will use network: ${widget.networkUrl}');
      }

      if (mounted) {
        setState(() {
          _cachedLocalPath = null;
          _isLocalPathResolved = true;
        });
        widget.onLoadingStateChange?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show placeholder while resolving local path
    if (!_isLocalPathResolved) {
      return _buildReaderPlaceholder(context);
    }

    // Use cached local path if available
    if (_cachedLocalPath != null) {
      return _buildLocalImageWithDynamicSize(_cachedLocalPath!);
    }

    // Fallback to network
    if (kDebugMode) {
      _logger
          .d('Reader: 📡 Falling back to network image: ${widget.networkUrl}');
    }
    return _buildNetworkImageWithDynamicSize(context);
  }

  /// Build network image with dynamic sizing
  Widget _buildNetworkImageWithDynamicSize(BuildContext context) {
    if (kDebugMode) {
      _logger.d(
          '📡 Loading reader image with dynamic sizing for page ${widget.pageNumber}: ${widget.networkUrl}');
    }

    // Use unique cache key combining contentId and pageNumber to prevent cache collision
    final uniqueCacheKey =
        '${widget.contentId}_page_${widget.pageNumber}_${widget.networkUrl.hashCode}';

    return CachedNetworkImage(
      key: ValueKey(uniqueCacheKey),
      imageUrl: widget.networkUrl,
      cacheKey: uniqueCacheKey, // Force unique cache per page
      fit: BoxFit.none, // Use BoxFit.none for custom sizing
      width: _getDisplaySize().width,
      height: _getDisplaySize().height,
      memCacheWidth: 800,
      memCacheHeight: 1200,
      placeholder: (context, url) => _buildReaderPlaceholder(context),
      errorWidget: (context, url, error) => _buildReaderErrorWidget(context),
      fadeInDuration: const Duration(milliseconds: 200),
      // Cache image in ImageCacheService when loaded
      imageBuilder: (context, imageProvider) {
        // Listen to image stream to get dimensions
        final imageStream = imageProvider.resolve(ImageConfiguration.empty);
        imageStream.addListener(ImageStreamListener(_calculateImageSize));

        // Cache the image data in ImageCacheService for future use
        _cacheNetworkImage(widget.networkUrl);
        return Image(
          image: imageProvider,
          fit: BoxFit.fitWidth,
          width: _getDisplaySize().width,
          height: _getDisplaySize().height,
        );
      },
    );
  }

  /// Build local image with dynamic sizing
  Widget _buildLocalImageWithDynamicSize(String localPath) {
    final imageProvider = FileImage(File(localPath));

    // Listen to image stream to get dimensions
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    imageStream.addListener(ImageStreamListener(_calculateImageSize));

    return Image(
      image: imageProvider,
      fit: BoxFit.fitWidth, // Use BoxFit.none for custom sizing
      width: _getDisplaySize().width,
      height: _getDisplaySize().height,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          _logger
              .e('Reader: ❌ Error loading local image from $localPath: $error');
        }
        // Fallback to network if local file fails
        return _buildNetworkImageWithDynamicSize(context);
      },
    );
  }

  /// Cache network image in ImageCacheService for future fast access
  Future<void> _cacheNetworkImage(String url) async {
    try {
      // Only cache if not already cached
      final isCached = await _imageCacheService.isImageCached(url);
      if (!isCached) {
        // Download and cache the image
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(url));
        request.headers.set('User-Agent', 'AppleWebKit/537.36');
        request.headers.set('Referer', 'https://nhentai.net/');

        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = <int>[];
          await for (var chunk in response) {
            bytes.addAll(chunk);
          }

          await _imageCacheService.cacheImage(url, bytes);
          if (kDebugMode) {
            _logger
                .d('Reader: ✅ Cached network image in ImageCacheService: $url');
          }
        }
        httpClient.close();
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.w('Reader: ⚠️ Failed to cache network image: $e');
      }
    }
  }

  /// Calculate dynamic size for the image based on its dimensions
  void _calculateImageSize(ImageInfo imageInfo, bool synchronousCall) {
    final imageSize = Size(
      imageInfo.image.width.toDouble(),
      imageInfo.image.height.toDouble(),
    );

    if (_imageSize != imageSize) {
      setState(() {
        _imageSize = imageSize;
      });

      if (kDebugMode) {
        _logger.d(
          'Reader: 📏 Image size: ${imageInfo.image.width}x${imageInfo.image.height}, '
          'No scaling applied',
        );
      }
    }
  }

  /// Get the display size for the image
  Size _getDisplaySize() {
    if (_imageSize == null) {
      // Fallback to screen size if dimensions not available
      final screenSize = MediaQuery.of(context).size;
      return Size(screenSize.width, screenSize.height * 0.8);
    }

    return Size(
        _imageSize!.width, _imageSize!.height); // Original size, no scaling
  }

  Widget _buildReaderPlaceholder(BuildContext context) {
    return SizedBox(
      height: widget.height ?? MediaQuery.of(context).size.height * 0.8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.loadingPage(widget.pageNumber) ??
                'Loading page ${widget.pageNumber}...',
            style: TextStyleConst.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderErrorWidget(BuildContext context) {
    return SizedBox(
      height: widget.height ?? MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.failedToLoadPage(widget.pageNumber),
            style: TextStyleConst.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.checkInternetConnection ??
                'Check your internet connection',
            style: TextStyleConst.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Specialized Progressive Image Widget for Thumbnails/Cards
/// Optimized for grid view with enhanced caching
class ProgressiveThumbnailWidget extends StatelessWidget {
  const ProgressiveThumbnailWidget({
    super.key,
    required this.networkUrl,
    this.contentId,
    this.aspectRatio = 0.7,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showOfflineIndicator = false,
  });

  final String networkUrl;
  final String? contentId;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final bool showOfflineIndicator;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          ProgressiveImageWidget(
            networkUrl: networkUrl,
            contentId: contentId,
            isThumbnail: true,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            borderRadius: borderRadius,
            memCacheWidth: 400,
            memCacheHeight: 600,
          ),

          // Offline indicator overlay
          if (showOfflineIndicator && contentId != null)
            FutureBuilder<bool>(
              future: LocalImagePreloader.isContentDownloaded(contentId!),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .scrim
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_bolt,
                            size: 12,
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            (AppLocalizations.of(context)?.offline ?? 'OFFLINE')
                                .toUpperCase(),
                            style: TextStyleConst.overline.copyWith(
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }
}
