import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/text_style_const.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import '../../l10n/app_localizations.dart';
import 'progressive_image_widget.dart';

/// Featured content card widget - Full-width horizontal layout
/// Designed to highlight the first/featured item at the top of content lists
class FeaturedContentCard extends StatelessWidget {
  const FeaturedContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.showBadge = true,
  });

  final Content content;
  final VoidCallback? onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: Row(
              children: [
                // Cover Image (Left side - 40% width)
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      content.coverUrl.isNotEmpty
                          ? ProgressiveThumbnailWidget(
                              networkUrl: content.coverUrl,
                              contentId: content.id,
                              aspectRatio: 0.7,
                              borderRadius: BorderRadius.zero,
                              showOfflineIndicator: false,
                              httpHeaders: getIt<ContentSourceRegistry>()
                                  .getSource(content.sourceId)
                                  ?.getImageDownloadHeaders(
                                      imageUrl: content.coverUrl),
                            )
                          : _buildPlaceholder(context),

                      // Featured badge
                      if (showBadge)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.featured.toUpperCase(),
                                  style: TextStyleConst.labelSmall.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 12,
                                  color: theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${content.pageCount}',
                                  style: TextStyleConst.labelSmall.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
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
                    padding: const EdgeInsets.all(16),
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
                            fontSize: 16,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

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
                                  style: TextStyleConst.bodyMedium.copyWith(
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

                        // Tags preview
                        if (content.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: content.tags.take(4).map((tag) {
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
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Bottom row with language and arrow
                        Row(
                          children: [
                            // Language flag
                            if (content.language.isNotEmpty)
                              _buildLanguageFlag(context),

                            const Spacer(),

                            // Read now button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.readNow,
                                    style: TextStyleConst.labelMedium.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surfaceContainer,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildLanguageFlag(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SvgPicture.asset(
              'assets/images/flags/${content.language.toLowerCase()}.svg',
              width: 28,
              height: 18,
              fit: BoxFit.cover,
              placeholderBuilder: (context) {
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
        const SizedBox(width: 6),
        Text(
          content.language.length > 1 
              ? '${content.language[0].toUpperCase()}${content.language.substring(1)}'
              : content.language.toUpperCase(),
          style: TextStyleConst.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
