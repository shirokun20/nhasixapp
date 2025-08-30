import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:logger/logger.dart';

import '../../core/constants/text_style_const.dart';
import '../../services/local_image_preloader.dart';

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
  static final Map<String, String?> _pathCache = {}; // ✅ Cache for resolved paths
  
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
    final cacheKey = '${widget.contentId}_${widget.pageNumber}_${widget.isThumbnail}';
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
      _logger.d('🔍 Resolving local path for contentId: ${widget.contentId}, pageNumber: ${widget.pageNumber}, isThumbnail: ${widget.isThumbnail}');
    }
    
    // ✅ REMOVED: _debugFileStructure() - too expensive and spammy
    // Only run debug in extreme debug mode if needed
    // if (kDebugMode) await _debugFileStructure();
    
    final localPath = await _getLocalImagePath();
    
    // ✅ Cache the result
    _pathCache[cacheKey] = localPath;
    
    if (kDebugMode && localPath != null) {
      _logger.d('✅ Local path resolved: $localPath');
    }
    
    if (mounted) {
      setState(() {
        _cachedLocalPath = localPath;
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
      localPath = await LocalImagePreloader.getLocalThumbnailPath(widget.contentId!);
      if (kDebugMode && localPath != null) {
        _logger.d('🖼️ Thumbnail found for ${widget.contentId}: $localPath');
      }
    } else if (widget.pageNumber != null) {
      localPath = await LocalImagePreloader.getLocalImagePath(widget.contentId!, widget.pageNumber!);
      if (kDebugMode && localPath != null) {
        _logger.d('📄 Page image found for ${widget.contentId} page ${widget.pageNumber}: $localPath');
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
      memCacheHeight: widget.memCacheHeight ?? (widget.isThumbnail ? 600 : 1200),
      placeholder: (context, url) => widget.placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => widget.errorWidget ?? _buildErrorWidget(),
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
      baseColor: Theme.of(context).colorScheme.surfaceVariant,
      highlightColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
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
        color: Theme.of(context).colorScheme.surfaceVariant,
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
  State<ProgressiveReaderImageWidget> createState() => _ProgressiveReaderImageWidgetState();
}

class _ProgressiveReaderImageWidgetState extends State<ProgressiveReaderImageWidget> {
  static final Logger _logger = Logger();
  String? _cachedLocalPath;
  bool _isLocalPathResolved = false;

  @override
  void initState() {
    super.initState();
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
      _logger.d('Reader: Resolving local path for contentId: ${widget.contentId}, pageNumber: ${widget.pageNumber}');
    }
    
    // First try to get existing local image
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
    
    // No local image found, try to download and cache
    if (kDebugMode) {
      _logger.d('Reader: 📥 No local image found, downloading and caching: ${widget.networkUrl}');
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
        _logger.d('Reader: ❌ Failed to cache image, will use network: ${widget.networkUrl}');
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
      return Image.file(
        File(_cachedLocalPath!),
        fit: widget.fit,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            _logger.e('Reader: ❌ Error loading local image from $_cachedLocalPath: $error');
          }
          // Fallback to network if local file fails
          return _buildNetworkImage(context);
        },
      );
    }

    // Fallback to network
    if (kDebugMode) {
      _logger.d('Reader: 📡 Falling back to network image: ${widget.networkUrl}');
    }
    return _buildNetworkImage(context);
  }

  Widget _buildNetworkImage(BuildContext context) {
    if (kDebugMode) {
      _logger.d('📡 Loading reader image: ${widget.networkUrl}');
    }
    
    return CachedNetworkImage(
      imageUrl: widget.networkUrl,
      fit: widget.fit,
      height: widget.height,
      memCacheWidth: 800,
      memCacheHeight: 1200,
      placeholder: (context, url) => _buildReaderPlaceholder(context),
      errorWidget: (context, url, error) => _buildReaderErrorWidget(context),
      fadeInDuration: const Duration(milliseconds: 200),
    );
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
            'Failed to load page ${widget.pageNumber}',
            style: TextStyleConst.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.scrim.withOpacity(0.3),
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
                            'OFFLINE',
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
