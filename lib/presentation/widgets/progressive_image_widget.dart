import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/colors_const.dart';
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
class ProgressiveImageWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // If no contentId provided, fallback to network only
    if (contentId == null) {
      return _buildNetworkImage();
    }

    return FutureBuilder<String?>(
      future: _getLocalImagePath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        final localPath = snapshot.data;
        
        if (localPath != null) {
          // Show local image first (instant loading)
          return _buildLocalImage(localPath);
        }
        
        // Fallback to network with placeholder
        return _buildNetworkImage();
      },
    );
  }

  /// Get local image path based on type (thumbnail or page)
  Future<String?> _getLocalImagePath() async {
    if (contentId == null) return null;

    if (isThumbnail) {
      return await LocalImagePreloader.getLocalThumbnailPath(contentId!);
    } else if (pageNumber != null) {
      return await LocalImagePreloader.getLocalImagePath(contentId!, pageNumber!);
    }
    
    return null;
  }

  /// Build local file image
  Widget _buildLocalImage(String localPath) {
    Widget imageWidget = Image.file(
      File(localPath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
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
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Build network image with caching
  Widget _buildNetworkImage() {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: networkUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? (isThumbnail ? 400 : 800),
      memCacheHeight: memCacheHeight ?? (isThumbnail ? 600 : 1200),
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Build shimmer placeholder
  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: ColorsConst.darkElevated,
      highlightColor: ColorsConst.darkCard,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ColorsConst.darkElevated,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ColorsConst.darkElevated,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: isThumbnail ? 24 : 32,
            color: ColorsConst.darkTextTertiary,
          ),
          if (!isThumbnail) ...[
            const SizedBox(height: 4),
            Text(
              'Image not available',
              style: TextStyleConst.caption.copyWith(
                color: ColorsConst.darkTextTertiary,
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
class ProgressiveReaderImageWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: LocalImagePreloader.getLocalImagePath(contentId, pageNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          onLoadingStateChange?.call(true);
          return _buildReaderPlaceholder(context);
        }

        final localPath = snapshot.data;
        onLoadingStateChange?.call(false);
        
        if (localPath != null) {
          // Instant loading from local file
          return Image.file(
            File(localPath),
            fit: fit,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to network if local file fails
              return _buildNetworkImage(context);
            },
          );
        }
        
        // Fallback to network
        return _buildNetworkImage(context);
      },
    );
  }

  Widget _buildNetworkImage(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: networkUrl,
      fit: fit,
      height: height,
      memCacheWidth: 800,
      memCacheHeight: 1200,
      placeholder: (context, url) => _buildReaderPlaceholder(context),
      errorWidget: (context, url, error) => _buildReaderErrorWidget(context),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildReaderPlaceholder(BuildContext context) {
    return SizedBox(
      height: height ?? MediaQuery.of(context).size.height * 0.8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: ColorsConst.accentBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading page $pageNumber...',
            style: TextStyleConst.bodyMedium.copyWith(
              color: ColorsConst.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderErrorWidget(BuildContext context) {
    return SizedBox(
      height: height ?? MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image,
            size: 64,
            color: ColorsConst.darkTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load page $pageNumber',
            style: TextStyleConst.bodyLarge.copyWith(
              color: ColorsConst.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your internet connection',
            style: TextStyleConst.bodySmall.copyWith(
              color: ColorsConst.darkTextTertiary,
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
                        color: ColorsConst.accentGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.offline_bolt,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'OFFLINE',
                            style: TextStyleConst.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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
