import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/constants/text_style_const.dart';
import '../../core/utils/offline_content_manager.dart';
import '../../core/constants/design_tokens.dart';
import '../models/content_group.dart';
import 'progressive_image_widget.dart';

class ContentGroupCardWidget extends StatelessWidget {
  const ContentGroupCardWidget({
    super.key,
    required this.contentGroup,
    this.onTap,
    this.onLongPress,
    this.aspectRatio = 0.7,
    this.isListMode = false,
  });

  final ContentGroup contentGroup;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double aspectRatio;
  final bool isListMode;

  @override
  Widget build(BuildContext context) {
    if (isListMode) {
      return _buildListMode(context);
    } else {
      return _buildGridMode(context);
    }
  }

  Widget _buildGridMode(BuildContext context) {
    final representative = contentGroup.representativeContent;
    final totalSizeStr =
        OfflineContentManager.formatStorageSize(contentGroup.totalSize);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: DesignTokens.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Image
              ProgressiveThumbnailWidget(
                networkUrl: representative.coverUrl,
                contentId: representative.id,
                aspectRatio: aspectRatio,
                borderRadius: BorderRadius.zero,
                showOfflineIndicator: false,
              ),

              // Bottom Gradient Overlay for Title
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black87,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contentGroup.baseTitle,
                        style: TextStyleConst.contentTitle.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contentGroup.totalSize > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.storage,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              totalSizeStr,
                              style: TextStyleConst.labelSmall.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Top Badges
              _buildTopOverlay(context),

              // Progress Border
              if (contentGroup.readProgress > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ProgressBorderPainter(
                      progress: contentGroup.readProgress,
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 4.0,
                      borderRadius: 12.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListMode(BuildContext context) {
    final representative = contentGroup.representativeContent;
    final totalSizeStr =
        OfflineContentManager.formatStorageSize(contentGroup.totalSize);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: DesignTokens.elevationMd,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: IntrinsicHeight(
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 100,
                    child: ProgressiveThumbnailWidget(
                      networkUrl: representative.coverUrl,
                      contentId: representative.id,
                      aspectRatio: aspectRatio,
                      borderRadius: BorderRadius.zero,
                      showOfflineIndicator: false,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contentGroup.baseTitle,
                            style: TextStyleConst.contentTitle.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildBadge(
                                context,
                                icon: Icons.library_books,
                                text: '${contentGroup.chapterCount} Ch',
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              _buildBadge(
                                context,
                                text: representative.sourceId.toUpperCase(),
                                color: Theme.of(context).colorScheme.primaryContainer,
                                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              if (contentGroup.totalSize > 0)
                                _buildBadge(
                                  context,
                                  icon: Icons.storage,
                                  text: totalSizeStr,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            ],
                          ),
                          if (contentGroup.readProgress > 0) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                    child: LinearProgressIndicator(
                                      value: contentGroup.readProgress,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      color: Theme.of(context).colorScheme.primary,
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${AppLocalizations.of(context)?.progress ?? 'Progress'}: ${(contentGroup.readProgress * 100).toInt()}%',
                                  style: TextStyleConst.labelSmall.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    IconData? icon,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyleConst.labelSmall.copyWith(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context) {
    return Positioned(
      top: 6,
      left: 6,
      right: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 10,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${contentGroup.chapterCount} Chapter${contentGroup.chapterCount > 1 ? 's' : ''}',
                      style: TextStyleConst.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  ),
                  child: Text(
                    contentGroup.representativeContent.sourceId.toUpperCase(),
                    style: TextStyleConst.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  _ProgressBorderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius - strokeWidth / 2),
    );

    final path = Path()..addRRect(rrect);

    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
