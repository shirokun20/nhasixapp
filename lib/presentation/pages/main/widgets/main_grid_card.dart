import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:nhasixapp/core/constants/colors_const.dart' show AppColors;
import 'package:nhasixapp/core/constants/design_tokens.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/utils/title_parser_utils.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';
import 'package:nhasixapp/presentation/widgets/progressive_image_widget.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:kuron_core/kuron_core.dart';

/// Grid card widget for 2-column layout with ripple effect
class MainGridCard extends StatelessWidget {
  const MainGridCard({
    super.key,
    required this.content,
    required this.onTap,
    this.blurThumbnails = false,
    this.isBlacklisted = false,
  });

  final Content content;
  final VoidCallback onTap;
  final bool blurThumbnails;
  final bool isBlacklisted;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ContentDownloadCache.isDownloaded(
        content.id,
        sourceId: content.sourceId,
        context: context,
      ),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        return FutureBuilder<bool>(
          future: _hasReadContent(),
          builder: (context, readSnapshot) {
            final isRead = readSnapshot.data ?? false;
            final theme = Theme.of(context);
            const readGoldColor = AppColors.readGold;
            const downloadBorderColor = AppColors.success;
            final borderStyle = switch ((isDownloaded, isRead)) {
              (true, true) => (
                  innerColor: downloadBorderColor,
                  innerWidth: 2.5,
                  outerColor: readGoldColor,
                  outerWidth: 2.2,
                  shadowColor: readGoldColor.withValues(alpha: 0.18),
                ),
              (true, false) => (
                  innerColor: downloadBorderColor,
                  innerWidth: 2.5,
                  outerColor: downloadBorderColor,
                  outerWidth: 0.0,
                  shadowColor: downloadBorderColor.withValues(alpha: 0.4),
                ),
              (false, true) => (
                  innerColor: readGoldColor,
                  innerWidth: 2.5,
                  outerColor: readGoldColor,
                  outerWidth: 0.0,
                  shadowColor: readGoldColor.withValues(alpha: 0.4),
                ),
              _ => (
                  innerColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                  innerWidth: 1.0,
                  outerColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                  outerWidth: 0.0,
                  shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
                ),
            };

            final innerCard = AspectRatio(
              aspectRatio: 0.7,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  border: Border.all(
                    color: borderStyle.innerColor,
                    width: borderStyle.innerWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: borderStyle.shadowColor,
                      blurRadius: borderStyle.outerWidth > 0 ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
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
                      if (isBlacklisted) _buildBlacklistedOverlay(context),
                      if (isRead)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: readGoldColor.withValues(alpha: 0.88),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusMd),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'READ',
                                  style: TextStyleConst.overline.copyWith(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
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
                                      borderRadius: BorderRadius.circular(
                                          DesignTokens.radiusSm),
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
                              color: theme.colorScheme.tertiary
                                  .withValues(alpha: 0.9),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusMd),
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
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusLg),
                            splashColor: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            highlightColor: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (borderStyle.outerWidth == 0) {
              return innerCard;
            }

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                border: Border.all(
                  color: borderStyle.outerColor,
                  width: borderStyle.outerWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: borderStyle.outerColor.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.2),
                child: innerCard,
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _hasReadContent() async {
    try {
      final userDataRepository = getIt<UserDataRepository>();
      final history = await userDataRepository.getHistoryEntry(content.id);
      if (history != null && history.progress > 0) {
        return true;
      }

      final chapterHistory =
          await userDataRepository.getAllChapterHistory(content.id);
      if (chapterHistory.any((item) => item.progress > 0)) {
        return true;
      }

      final cardBaseTitle =
          TitleParserUtils.getBaseTitle(content.getDisplayTitle())
              .toLowerCase();
      final recentHistory = await userDataRepository.getHistory(limit: 100);
      return recentHistory.any((item) {
        if (item.sourceId.trim().toLowerCase() !=
            content.sourceId.trim().toLowerCase()) {
          return false;
        }

        final historyTitle = item.title?.trim();
        if (historyTitle == null || historyTitle.isEmpty) return false;
        return TitleParserUtils.getBaseTitle(historyTitle).toLowerCase() ==
            cardBaseTitle;
      });
    } catch (_) {
      return false;
    }
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
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
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
    return ProgressiveImageWidget(
      networkUrl: coverUrl,
      httpHeaders: getIt<ContentSourceRegistry>()
          .getSource(content.sourceId)
          ?.getImageDownloadHeaders(imageUrl: coverUrl),
      fit: BoxFit.cover,
      memCacheWidth: 400,
      memCacheHeight: 600,
      placeholder: Container(
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
      errorWidget:
          // Try fallback URL if available
          (fallbackUrl != null && fallbackUrl != coverUrl)
              ? ProgressiveImageWidget(
                  networkUrl: fallbackUrl,
                  httpHeaders: getIt<ContentSourceRegistry>()
                      .getSource(content.sourceId)
                      ?.getImageDownloadHeaders(imageUrl: fallbackUrl),
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  memCacheHeight: 600,
                  placeholder: Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: _buildErrorPlaceholder(context),
                )
              : _buildErrorPlaceholder(context),
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

  Widget _buildBlacklistedOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.64),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_off_rounded,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BLACKLISTED',
                    style: TextStyleConst.labelSmall.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
