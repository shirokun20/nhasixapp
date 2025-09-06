import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/text_style_const.dart';
import '../../domain/entities/content.dart';
import '../../l10n/app_localizations.dart';
import 'progressive_image_widget.dart';

/// Enhanced content card widget with image caching and improved UI
///
/// Usage:
/// - Main screen: showUploadDate = false (default) - matches nhentai main page
/// - Search/Browse: showUploadDate = true - shows when content was uploaded
/// - Detail views: Can show tags, upload date, and other metadata
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.onLongPress,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.showDownloadStatus = false,
    this.downloadProgress,
    this.aspectRatio = 0.7,
    this.showPageCount = true,
    this.showLanguageFlag = true,
    this.showTags = false,
    this.showUploadDate = false, // Hidden by default for main screen
    this.maxTagsToShow = 3,
    this.showOfflineIndicator = false,
    this.isHighlighted = false, // NEW: for highlight matching content
    this.highlightReason, // NEW: reason for highlight
    this.isBlurred = false, // NEW: for blur excluded content
  });

  final Content content;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool showDownloadStatus;
  final double? downloadProgress; // 0.0 to 1.0
  final double aspectRatio;
  final bool showPageCount;
  final bool showLanguageFlag;
  final bool showTags;
  final bool showUploadDate;
  final int maxTagsToShow;
  final bool showOfflineIndicator;
  final bool isHighlighted; // NEW: for highlight matching content
  final String? highlightReason; // NEW: reason for highlight
  final bool isBlurred; // NEW: for blur excluded content

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final cardWidget = Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: isHighlighted ? 6 : 2,
      shadowColor: isHighlighted 
          ? (isDarkMode 
              ? const Color(0xFF00FF88).withValues(alpha: 0.5) // Neon green for dark mode
              : const Color(0xFF2E7D32).withValues(alpha: 0.5)) // Dark green for light mode
          : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? BorderSide(
                color: isDarkMode 
                    ? const Color(0xFF00FF88) // Neon green for dark mode
                    : const Color(0xFF2E7D32), // Dark green for light mode
                width: 2.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image with overlay elements
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Main cover image
                    _buildCoverImage(),

                    // Download progress overlay
                    if (showDownloadStatus && downloadProgress != null)
                      _buildDownloadProgressOverlay(),

                    // Top overlay with favorite button and page count
                    if (content.pageCount > 0 || showOfflineIndicator)
                      _buildTopOverlay(),

                    // Highlight indicator overlay
                    if (isHighlighted) _buildHighlightOverlay(),

                    // Bottom gradient overlay for better text readability
                    _buildBottomGradientOverlay(),
                  ],
                ),
              ),

              // Content info section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildTitle(),

                      const SizedBox(height: 4),

                      // Artist
                      if (content.artists.isNotEmpty) _buildArtist(),

                      // Tags (if enabled)
                      if (showTags && content.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildTags(),
                      ],

                      const Spacer(),

                      // Bottom row with language flag and metadata
                      _buildBottomRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Apply additional highlight effect untuk downloaded content
    if (isHighlighted) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode 
                  ? const Color(0xFF00FF88) // Neon green for dark mode
                  : const Color(0xFF2E7D32)) // Dark green for light mode
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: cardWidget,
      );
    }

    // Apply blur effect if content is excluded
    if (isBlurred) {
      return Stack(
        children: [
          // Blurred content
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              BlendMode.saturation,
            ),
            child: Opacity(
              opacity: 0.5,
              child: cardWidget,
            ),
          ),
          // Overlay to indicate excluded content
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
              ),
              child: Center(
                child: Icon(
                  Icons.visibility_off,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return cardWidget;
  }

  /// Build highlight overlay indicator for downloaded content
  Widget _buildHighlightOverlay() {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF00FF88) // Neon green for dark mode
                  : const Color(0xFF2E7D32), // Dark green for light mode
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_done,
                  color: Theme.of(context).colorScheme.onSecondary,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  (AppLocalizations.of(context)?.offline ?? 'OFFLINE').toUpperCase(),
                  style: TextStyleConst.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverImage() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: content.coverUrl.isNotEmpty
            ? ProgressiveThumbnailWidget(
                networkUrl: content.coverUrl,
                contentId: content.id,
                aspectRatio: aspectRatio,
                borderRadius: BorderRadius.zero, // No border radius, handled by parent
                showOfflineIndicator: showOfflineIndicator,
              )
            : _buildImageError(),
      ),
    );
  }

  Widget _buildImageError() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)?.imageNotAvailable ?? 'Image not available',
              style: TextStyleConst.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgressOverlay() {
    return Positioned.fill(
      child: Builder(
        builder: (context) => Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: downloadProgress,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.outline,
                strokeWidth: 3,
              ),
              const SizedBox(height: 8),
              Text(
                '${(downloadProgress! * 100).toInt()}%',
                style: TextStyleConst.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Builder(
        builder: (context) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side badges
            Row(
              children: [
                // Page count badge
                if (showPageCount && content.pageCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${content.pageCount}p',
                      style: TextStyleConst.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                // Offline indicator badge
                if (showOfflineIndicator) ...[
                  if (showPageCount && content.pageCount > 0)
                    const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.offline_bolt,
                          size: 10,
                          color: Theme.of(context).colorScheme.onTertiary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (AppLocalizations.of(context)?.offline ?? 'OFFLINE').toUpperCase(),
                          style: TextStyleConst.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.onTertiary,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Favorite button
            if (showFavoriteButton)
              GestureDetector(
                onTap: onFavoriteToggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFavorite
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 40,
      child: Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Builder(
      builder: (context) => Text(
        content.getDisplayTitle(),
        style: TextStyleConst.contentTitle.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 13,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildArtist() {
    return Builder(
      builder: (context) => Text(
        content.artists.take(2).join(', '),
        style: TextStyleConst.contentSubtitle.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTags() {
    final visibleTags = content.tags.take(maxTagsToShow).toList();

    return Builder(
      builder: (context) => Wrap(
        spacing: 4,
        runSpacing: 2,
        children: visibleTags
            .map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getTagColor(context, tag.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getTagColor(context, tag.type).withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tag.name,
                    style: TextStyleConst.contentTag.copyWith(
                      color: _getTagColor(context, tag.type),
                      fontSize: 9,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// Helper method to get tag color based on theme
  Color _getTagColor(BuildContext context, String tagType) {
    switch (tagType.toLowerCase()) {
      case 'artist':
        return Theme.of(context).colorScheme.primary;
      case 'character':
        return Theme.of(context).colorScheme.secondary;
      case 'parody':
        return Theme.of(context).colorScheme.tertiary;
      case 'group':
        return Theme.of(context).colorScheme.error;
      case 'language':
        return Theme.of(context).colorScheme.inversePrimary;
      case 'category':
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildBottomRow() {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Row(
          children: [
            // Upload date (only show if enabled)
            if (showUploadDate)
              Text(
                _formatUploadDate(content.uploadDate),
                style: TextStyleConst.caption.copyWith(
                  fontSize: 10,
                ),
              ),

            const Spacer(),

            // Downloaded indicator icon
            if (isHighlighted) ...[
              Icon(
                Icons.offline_pin,
                size: 14,
                color: isDarkMode 
                    ? const Color(0xFF00FF88) // Neon green for dark mode
                    : const Color(0xFF2E7D32), // Dark green for light mode
              ),
              const SizedBox(width: 4),
            ],

            // Language flag
            if (showLanguageFlag && content.language.isNotEmpty)
              _buildLanguageFlag(),
          ],
        );
      },
    );
  }

  Widget _buildLanguageFlag() {
    return Builder(
      builder: (context) => Container(
        width: 24,
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.asset(
            'assets/images/${content.language.toLowerCase()}.gif',
            width: 24,
            height: 16,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    content.language.substring(0, 2).toUpperCase(),
                    style: TextStyleConst.labelSmall.copyWith(
                      fontSize: 8,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatUploadDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return 'now';
    }
  }

  /// Static method to build image widget for reuse in other components
  static Widget buildImage({
    required String imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    int? memCacheWidth,
    int? memCacheHeight,
    required BuildContext context,
  }) {
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)?.noImage ?? 'No image',
              style: TextStyleConst.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? 400,
      memCacheHeight: memCacheHeight ?? 600,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.failedToLoad,
              style: TextStyleConst.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}

/// Compact content card for list views
class CompactContentCard extends StatelessWidget {
  const CompactContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Content content;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: content.coverUrl,
                    fit: BoxFit.cover,
                    width: 60,
                    height: 80,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    memCacheWidth: 120,
                    memCacheHeight: 160,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Content info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.getDisplayTitle(),
                      style: TextStyleConst.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (content.artists.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        content.artists.join(', '),
                        style: TextStyleConst.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${content.pageCount} pages',
                          style: TextStyleConst.caption.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (content.language.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              content.language.toUpperCase(),
                              style: TextStyleConst.labelSmall.copyWith(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite button
              if (showFavoriteButton)
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
