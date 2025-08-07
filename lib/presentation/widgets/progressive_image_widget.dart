import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/colors_const.dart';
import '../../core/utils/image_cache_manager.dart';

/// Progressive image widget with advanced caching and loading states
///
/// Features:
/// - Progressive loading (thumbnail -> compressed -> full resolution)
/// - Custom cache management
/// - Smooth transitions between loading states
/// - Error handling with fallback options
/// - Memory optimization
class ProgressiveImageWidget extends StatefulWidget {
  const ProgressiveImageWidget({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.memCacheWidth,
    this.memCacheHeight,
    this.enableProgressiveLoading = true,
    this.compressionQuality = 85,
    this.borderRadius,
    this.onImageLoaded,
    this.onImageError,
  });

  final String imageUrl;
  final String? thumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool enableProgressiveLoading;
  final int compressionQuality;
  final BorderRadius? borderRadius;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onImageError;

  @override
  State<ProgressiveImageWidget> createState() => _ProgressiveImageWidgetState();
}

class _ProgressiveImageWidgetState extends State<ProgressiveImageWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  ImageLoadingState _loadingState = ImageLoadingState.loading;
  File? _thumbnailFile;
  File? _compressedFile;
  File? _fullImageFile;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    try {
      setState(() {
        _loadingState = ImageLoadingState.loading;
      });

      final cacheManager = ImageCacheManager.instance;

      if (widget.enableProgressiveLoading) {
        // Step 1: Load thumbnail first (fastest)
        await _loadThumbnail(cacheManager);

        // Step 2: Load compressed version (medium quality, faster than full)
        await _loadCompressedImage(cacheManager);

        // Step 3: Load full resolution (highest quality, slowest)
        await _loadFullImage(cacheManager);
      } else {
        // Direct full image loading
        await _loadFullImage(cacheManager);
      }

      if (mounted) {
        setState(() {
          _loadingState = ImageLoadingState.loaded;
        });
        _fadeController.forward();
        widget.onImageLoaded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState = ImageLoadingState.error;
        });
        widget.onImageError?.call();
      }
    }
  }

  Future<void> _loadThumbnail(ImageCacheManager cacheManager) async {
    if (!mounted) return;

    try {
      final thumbnailFile = await cacheManager.getThumbnail(widget.imageUrl);
      if (mounted && thumbnailFile.existsSync()) {
        setState(() {
          _thumbnailFile = thumbnailFile;
          _loadingState = ImageLoadingState.thumbnail;
        });
        _fadeController.forward();
      }
    } catch (e) {
      // Thumbnail loading failed, continue with other loading steps
    }
  }

  Future<void> _loadCompressedImage(ImageCacheManager cacheManager) async {
    if (!mounted) return;

    try {
      final compressedFile = await cacheManager.getCompressedImage(
        widget.imageUrl,
        quality: widget.compressionQuality,
      );
      if (mounted && compressedFile.existsSync()) {
        setState(() {
          _compressedFile = compressedFile;
          _loadingState = ImageLoadingState.compressed;
        });
      }
    } catch (e) {
      // Compressed loading failed, continue with full image
    }
  }

  Future<void> _loadFullImage(ImageCacheManager cacheManager) async {
    if (!mounted) return;

    try {
      final fullImageFile = await cacheManager.getFullImage(widget.imageUrl);
      if (mounted && fullImageFile.existsSync()) {
        setState(() {
          _fullImageFile = fullImageFile;
          _loadingState = ImageLoadingState.loaded;
        });
      }
    } catch (e) {
      throw Exception('Failed to load full image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildImageContent();

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: imageWidget,
    );
  }

  Widget _buildImageContent() {
    switch (_loadingState) {
      case ImageLoadingState.loading:
        return _buildPlaceholder();

      case ImageLoadingState.thumbnail:
        return _buildProgressiveImage(_thumbnailFile!);

      case ImageLoadingState.compressed:
        return _buildProgressiveImage(_compressedFile!);

      case ImageLoadingState.loaded:
        return _buildProgressiveImage(
            _fullImageFile ?? _compressedFile ?? _thumbnailFile!);

      case ImageLoadingState.error:
        return _buildErrorWidget();
    }
  }

  Widget _buildProgressiveImage(File imageFile) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image.file(
        imageFile,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: widget.memCacheWidth,
        cacheHeight: widget.memCacheHeight,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Shimmer.fromColors(
      baseColor: ColorsConst.darkElevated,
      highlightColor: ColorsConst.darkCard,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: ColorsConst.darkElevated,
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: ColorsConst.darkElevated,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: (widget.height != null && widget.height! < 100) ? 24 : 32,
            color: ColorsConst.darkTextTertiary,
          ),
          if (widget.height == null || widget.height! >= 60) ...[
            const SizedBox(height: 4),
            Text(
              'Image not available',
              style: TextStyle(
                color: ColorsConst.darkTextTertiary,
                fontSize:
                    (widget.height != null && widget.height! < 100) ? 10 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced cached network image with progressive loading fallback
class EnhancedCachedNetworkImage extends StatelessWidget {
  const EnhancedCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.memCacheWidth,
    this.memCacheHeight,
    this.useProgressiveLoading = true,
    this.compressionQuality = 85,
    this.borderRadius,
    this.onImageLoaded,
    this.onImageError,
  });

  final String imageUrl;
  final String? thumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool useProgressiveLoading;
  final int compressionQuality;
  final BorderRadius? borderRadius;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onImageError;

  @override
  Widget build(BuildContext context) {
    // Use progressive loading for better performance
    if (useProgressiveLoading) {
      return ProgressiveImageWidget(
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        compressionQuality: compressionQuality,
        borderRadius: borderRadius,
        onImageLoaded: onImageLoaded,
        onImageError: onImageError,
      );
    }

    // Fallback to standard CachedNetworkImage
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        onImageError?.call();
        return errorWidget ?? _buildDefaultErrorWidget();
      },
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      imageBuilder: (context, imageProvider) {
        onImageLoaded?.call();
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Shimmer.fromColors(
      baseColor: ColorsConst.darkElevated,
      highlightColor: ColorsConst.darkCard,
      child: Container(
        width: width,
        height: height,
        color: ColorsConst.darkElevated,
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: ColorsConst.darkElevated,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: (height != null && height! < 100) ? 24 : 32,
            color: ColorsConst.darkTextTertiary,
          ),
          if (height == null || height! >= 60) ...[
            const SizedBox(height: 4),
            Text(
              'Image not available',
              style: TextStyle(
                color: ColorsConst.darkTextTertiary,
                fontSize: (height != null && height! < 100) ? 10 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Image loading states
enum ImageLoadingState {
  loading,
  thumbnail,
  compressed,
  loaded,
  error,
}

/// Image quality presets
enum ImageQuality {
  low(quality: 60, memCacheWidth: 200, memCacheHeight: 300),
  medium(quality: 75, memCacheWidth: 400, memCacheHeight: 600),
  high(quality: 85, memCacheWidth: 600, memCacheHeight: 900),
  original(quality: 95, memCacheWidth: null, memCacheHeight: null);

  const ImageQuality({
    required this.quality,
    required this.memCacheWidth,
    required this.memCacheHeight,
  });

  final int quality;
  final int? memCacheWidth;
  final int? memCacheHeight;
}
