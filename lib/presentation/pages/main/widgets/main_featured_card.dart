import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';

/// Horizontal featured card widget: Image left (40%), Content info right (60%)
class MainFeaturedCard extends StatelessWidget {
  const MainFeaturedCard({
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

        return Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainer,
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
                        ? const Color(0xFF00FF88).withValues(alpha: 0.3)
                        : const Color(0xFF2E7D32).withValues(alpha: 0.3))
                    : theme.colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Main content Row
                Row(
                  children: [
                    // Cover Image (Left side - 40% width)
                    Expanded(
                      flex: 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImageWithBlur(
                            context: context,
                            coverUrl: content.coverUrl,
                            fallbackUrl: content.imageUrls.isNotEmpty
                                ? content.imageUrls.first
                                : null,
                          ),
                          // Page count badge
                          if (content.pageCount > 0)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library_outlined,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${content.pageCount}',
                                      style: TextStyleConst.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // OFFLINE badge
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
                                  color: theme.colorScheme.tertiary
                                      .withValues(alpha: 0.9),
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
                        ],
                      ),
                    ),
                    // Content Info (Right side - 60% width)
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.surfaceContainer,
                              theme.colorScheme.surfaceContainerHighest,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              content.getDisplayTitle(),
                              style: TextStyleConst.headingSmall.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 15,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Subtitle (Chapter info)
                            if (content.subTitle != null &&
                                content.subTitle!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                content.subTitle!,
                                style: TextStyleConst.labelSmall.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Artists
                            if (content.artists.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.brush_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      content.artists.take(2).join(', '),
                                      style: TextStyleConst.bodySmall.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const Spacer(),
                            // Genre/Tags preview
                            if (content.tags.isNotEmpty) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: content.tags.take(3).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      tag.name,
                                      style: TextStyleConst.labelSmall.copyWith(
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Language flag
                            Row(
                              children: [
                                if (content.language.isNotEmpty)
                                  Container(
                                    width: 28,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withValues(alpha: 0.5),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: Image.asset(
                                        'assets/images/${content.language.toLowerCase()}.gif',
                                        width: 28,
                                        height: 18,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            child: Center(
                                              child: Text(
                                                content.language
                                                    .substring(0, 2)
                                                    .toUpperCase(),
                                                style: TextStyleConst.labelSmall
                                                    .copyWith(
                                                  fontSize: 8,
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (content.language.isNotEmpty)
                                  Text(
                                    content.language.toUpperCase(),
                                    style: TextStyleConst.labelSmall.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Ripple effect overlay (on top of everything)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(16),
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
