import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:nhasixapp/core/constants/colors_const.dart'
    show AppColors, KuronColors;
import 'package:nhasixapp/presentation/widgets/shimmer_loading_widgets.dart';

import '../../core/constants/text_style_const.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/services/language_service.dart';
import '../../l10n/app_localizations.dart';
import 'progressive_image_widget.dart';
import 'package:nhasixapp/core/constants/design_tokens.dart';

/// Featured content card widget - Full-width horizontal layout
/// Designed to highlight the first/featured item at the top of content lists
class FeaturedContentCard extends StatelessWidget {
  const FeaturedContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.showBadge = true,
    this.blurThumbnails = false,
    this.isBlurred = false,
    this.showDownloadBadge = false,
    this.readProgress,
  });

  final Content content;
  final VoidCallback? onTap;
  final bool showBadge;
  final bool blurThumbnails;
  final bool isBlurred;
  final bool showDownloadBadge;
  final double? readProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final readColor =
        theme.extension<KuronColors>()?.readGold ?? AppColors.readGold;
    final offlineColor = theme.colorScheme.tertiary;
    final isRead = readProgress != null && readProgress! > 0;
    final hasStatusFrame = isRead || showDownloadBadge;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        elevation: DesignTokens.elevationLg,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        child: Stack(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
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
                          _buildCoverImage(context),

                          // Featured badge
                          if (showBadge)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusLg),
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
                                      size: 12,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.featured.toUpperCase(),
                                      style: TextStyleConst.labelSmall.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (showDownloadBadge)
                            Positioned(
                              top: showBadge ? 40 : 8,
                              left: 8,
                              child: _buildStatusPill(
                                context,
                                icon: Icons.offline_bolt_rounded,
                                label: 'OFFLINE',
                                color: offlineColor,
                              ),
                            ),

                          if (isRead)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _buildStatusPill(
                                context,
                                icon: Icons.menu_book_rounded,
                                label: 'READ',
                                color: readColor,
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
                                  borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusMd),
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

                            // Bottom row with language and arrow
                            Row(
                              children: [
                                if (content.language.isNotEmpty)
                                  _buildLanguageFlag(context),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.radius2xl),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.readNow,
                                        style:
                                            TextStyleConst.labelMedium.copyWith(
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
            if (hasStatusFrame)
              Positioned.fill(
                child: IgnorePointer(
                  child: _buildStatusBorderOverlay(
                    readColor: readColor,
                    offlineColor: offlineColor,
                    isRead: isRead,
                    isOffline: showDownloadBadge,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBorderOverlay({
    required Color readColor,
    required Color offlineColor,
    required bool isRead,
    required bool isOffline,
  }) {
    final readLineColor = readColor.withValues(alpha: 0.9);
    final offlineLineColor = offlineColor.withValues(alpha: 0.9);

    if (isRead && isOffline) {
      return _buildSegmentedStatusBorderOverlay(
        radius: DesignTokens.radiusXl,
        strokeWidth: 1.0,
        topColor: readLineColor,
        rightColor: offlineLineColor,
        bottomColor: readLineColor,
        leftColor: offlineLineColor,
      );
    }

    if (isRead) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(
            color: readLineColor,
            width: 1.0,
          ),
        ),
      );
    }

    return _buildSegmentedStatusBorderOverlay(
      radius: DesignTokens.radiusXl,
      strokeWidth: 1.0,
      leftColor: offlineLineColor,
      rightColor: offlineLineColor,
    );
  }

  Widget _buildSegmentedStatusBorderOverlay({
    required double radius,
    required double strokeWidth,
    Color? topColor,
    Color? rightColor,
    Color? bottomColor,
    Color? leftColor,
  }) {
    return CustomPaint(
      painter: _SegmentedStatusBorderPainter(
        radius: radius,
        strokeWidth: strokeWidth,
        topColor: topColor,
        rightColor: rightColor,
        bottomColor: bottomColor,
        leftColor: leftColor,
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildStatusPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyleConst.overline.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return KuronShimmer(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surfaceContainer,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    Widget image = content.coverUrl.isNotEmpty
        ? ProgressiveThumbnailWidget(
            networkUrl: content.coverUrl,
            contentId: content.id,
            aspectRatio: 0.7,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusXl),
              bottomLeft: Radius.circular(DesignTokens.radiusXl),
            ),
            showOfflineIndicator: false,
            httpHeaders: getIt<ContentSourceRegistry>()
                .getSource(content.sourceId)
                ?.getImageDownloadHeaders(imageUrl: content.coverUrl),
          )
        : _buildPlaceholder(context);

    if (blurThumbnails) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: image,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        if (isBlurred) _buildBlacklistedOverlay(context),
      ],
    );
  }

  Widget _buildBlacklistedOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.62),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.9),
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
                    size: 16,
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

  Widget _buildLanguageFlag(BuildContext context) {
    final languageService = getIt<LanguageService>();
    final normalizedLanguage = content.language.toLowerCase().trim();
    final hasLanguage =
        normalizedLanguage.isNotEmpty && normalizedLanguage != 'unknown';
    final flagEmoji =
        hasLanguage ? languageService.flagEmoji(normalizedLanguage) : null;
    final languageBadge = hasLanguage
        ? (normalizedLanguage.length >= 2
            ? normalizedLanguage.substring(0, 2).toUpperCase()
            : normalizedLanguage.toUpperCase())
        : '--';
    final languageLabel = hasLanguage
        ? languageService.displayName(normalizedLanguage)
        : content.language;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${flagEmoji ?? languageBadge} $languageLabel',
          style: TextStyleConst.labelSmall.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SegmentedStatusBorderPainter extends CustomPainter {
  const _SegmentedStatusBorderPainter({
    required this.radius,
    required this.strokeWidth,
    this.topColor,
    this.rightColor,
    this.bottomColor,
    this.leftColor,
  });

  final double radius;
  final double strokeWidth;
  final Color? topColor;
  final Color? rightColor;
  final Color? bottomColor;
  final Color? leftColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final left = inset;
    final top = inset;
    final right = size.width - inset;
    final bottom = size.height - inset;
    final cornerRadius = math.max(0.0, radius - inset);

    Paint paintFor(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    Rect cornerRect(double x, double y) =>
        Rect.fromLTWH(x, y, cornerRadius * 2, cornerRadius * 2);

    void drawLine(Color? color, Offset start, Offset end) {
      if (color == null) return;
      canvas.drawLine(start, end, paintFor(color));
    }

    void drawArc(
        Color? color, Rect rect, double startAngle, double sweepAngle) {
      if (color == null || cornerRadius <= 0) return;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paintFor(color));
    }

    final topLeftRect = cornerRect(left, top);
    final topRightRect = cornerRect(right - cornerRadius * 2, top);
    final bottomRightRect =
        cornerRect(right - cornerRadius * 2, bottom - cornerRadius * 2);
    final bottomLeftRect = cornerRect(left, bottom - cornerRadius * 2);

    drawArc(topColor, topLeftRect, math.pi, -math.pi / 2);
    drawLine(
      topColor,
      Offset(left + cornerRadius, top),
      Offset(right - cornerRadius, top),
    );
    drawArc(topColor, topRightRect, -math.pi / 2, math.pi / 2);

    drawArc(rightColor, topRightRect, -math.pi / 2, math.pi / 2);
    drawLine(
      rightColor,
      Offset(right, top + cornerRadius),
      Offset(right, bottom - cornerRadius),
    );
    drawArc(rightColor, bottomRightRect, 0, math.pi / 2);

    drawArc(bottomColor, bottomRightRect, 0, math.pi / 2);
    drawLine(
      bottomColor,
      Offset(right - cornerRadius, bottom),
      Offset(left + cornerRadius, bottom),
    );
    drawArc(bottomColor, bottomLeftRect, math.pi / 2, math.pi / 2);

    drawArc(leftColor, topLeftRect, -math.pi / 2, -math.pi / 2);
    drawLine(
      leftColor,
      Offset(left, top + cornerRadius),
      Offset(left, bottom - cornerRadius),
    );
    drawArc(leftColor, bottomLeftRect, math.pi, -math.pi / 2);
  }

  @override
  bool shouldRepaint(covariant _SegmentedStatusBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.topColor != topColor ||
        oldDelegate.rightColor != rightColor ||
        oldDelegate.bottomColor != bottomColor ||
        oldDelegate.leftColor != leftColor;
  }
}
