import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';

/// Grid card widget for 2-column layout with ripple effect
class MainGridCard extends StatelessWidget {
  const MainGridCard({
    super.key,
    required this.content,
    required this.onTap,
    this.blurThumbnails = false,
  });

  final Content content;
  final VoidCallback onTap;
  final bool blurThumbnails;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ContentDownloadCache.isDownloaded(content.id, context),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return AspectRatio(
          aspectRatio: 0.7,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isDownloaded
                  ? Border.all(
                      color: isDarkMode
                          ? const Color(0xFF00FF88)
                          : const Color(0xFF2E7D32),
                      width: 2.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isDownloaded
                      ? (isDarkMode
                          ? const Color(0xFF00FF88).withValues(alpha: 0.4)
                          : const Color(0xFF2E7D32).withValues(alpha: 0.4))
                      : theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: isDownloaded ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image with fallback to page 1 and optional blur
                  _buildImageWithBlur(
                    context: context,
                    coverUrl: content.coverUrl,
                    fallbackUrl: content.imageUrls.isNotEmpty
                        ? content.imageUrls.first
                        : null,
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Content info at bottom
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          content.getDisplayTitle(),
                          style: TextStyleConst.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Subtitle (Chapter info)
                        if (content.subTitle != null &&
                            content.subTitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            content.subTitle!,
                            style: TextStyleConst.overline.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (content.pageCount > 1) ...[
                              Icon(
                                Icons.menu_book,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${content.pageCount}',
                                style: TextStyleConst.overline.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (content.language.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  content.language.toUpperCase(),
                                  style: TextStyleConst.overline.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // OFFLINE badge for downloaded items
                  if (isDownloaded)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.tertiary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.offline_bolt,
                              size: 12,
                              color: theme.colorScheme.onTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'OFFLINE',
                              style: TextStyleConst.overline.copyWith(
                                color: theme.colorScheme.onTertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Ripple effect overlay (on top of everything)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(12),
                        splashColor:
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                        highlightColor:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build image with optional blur effect
  Widget _buildImageWithBlur({
    required BuildContext context,
    required String coverUrl,
    String? fallbackUrl,
  }) {
    final image = _buildCachedImage(
      context: context,
      coverUrl: coverUrl,
      fallbackUrl: fallbackUrl,
    );

    if (blurThumbnails) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: image,
        ),
      );
    }

    return image;
  }

  /// Build cached image with fallback to first page if cover fails
  Widget _buildCachedImage({
    required BuildContext context,
    required String coverUrl,
    String? fallbackUrl,
  }) {
    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      memCacheHeight: 600,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 40,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // Try fallback URL if available
        if (fallbackUrl != null && fallbackUrl != coverUrl) {
          return CachedNetworkImage(
            imageUrl: fallbackUrl,
            fit: BoxFit.cover,
            memCacheWidth: 400,
            memCacheHeight: 600,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) =>
                _buildErrorPlaceholder(context),
          );
        }
        return _buildErrorPlaceholder(context);
      },
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
