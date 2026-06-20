import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/widgets/download_button_widget.dart';
import 'package:nhasixapp/presentation/widgets/progressive_image_widget.dart';
import 'package:kuron_core/kuron_core.dart' show Chapter;

class DetailTitleSection extends StatelessWidget {
  const DetailTitleSection({super.key, required this.content});

  final Content content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: TextStyleConst.headingLarge.copyWith(
            color: colorScheme.onSurface,
            height: 1.3,
          ),
        ),
        if (content.englishTitle != null &&
            content.englishTitle != content.title) ...[
          const SizedBox(height: 8),
          Text(
            content.englishTitle!,
            style: TextStyleConst.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (content.japaneseTitle != null &&
            content.japaneseTitle != content.title) ...[
          const SizedBox(height: 4),
          Text(
            content.japaneseTitle!,
            style: TextStyleConst.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class DetailBlacklistBanner extends StatelessWidget {
  const DetailBlacklistBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.visibility_off_rounded,
            color: colorScheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyleConst.bodySmall.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailBlacklistedCoverOverlay extends StatelessWidget {
  const DetailBlacklistedCoverOverlay({
    super.key,
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.62),
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_off_rounded,
                    size: compact ? 14 : 16,
                    color: colorScheme.error,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      'BLACKLISTED',
                      style: TextStyleConst.labelSmall.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailMetadataSection extends StatelessWidget {
  const DetailMetadataSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<DetailMetadataItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.scrim.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyleConst.headingMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(DetailMetadataRow.new),
        ],
      ),
    );
  }
}

class DetailMetadataItem {
  const DetailMetadataItem({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;
}

class DetailMetadataRow extends StatelessWidget {
  const DetailMetadataRow(this.item, {super.key});

  final DetailMetadataItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 80,
            child: Text(
              item.label,
              style: TextStyleConst.labelMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.value,
              style: TextStyleConst.bodyLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailTagSection extends StatelessWidget {
  const DetailTagSection({
    super.key,
    required this.title,
    required this.tags,
    required this.resolveColor,
    required this.onTagTap,
    required this.formatCount,
  });

  final String title;
  final List<Tag> tags;
  final Color Function(String type) resolveColor;
  final void Function(Tag tag) onTagTap;
  final String Function(int count) formatCount;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyleConst.headingSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final color = resolveColor(tag.type);
            return GestureDetector(
              onTap: () => onTagTap(tag),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag.name,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: color,
                      ),
                    ),
                    if (tag.count > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        formatCount(tag.count),
                        style: TextStyleConst.overline.copyWith(
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class DetailChapterSection extends StatelessWidget {
  const DetailChapterSection({
    super.key,
    required this.content,
    required this.chapterHistory,
    required this.onChapterTap,
    required this.onViewAll,
    required this.formatDate,
    required this.formatLanguageLabel,
    required this.canDownload,
  });

  final Content content;
  final Map<String, History> chapterHistory;
  final ValueChanged<Chapter> onChapterTap;
  final VoidCallback onViewAll;
  final String Function(DateTime date) formatDate;
  final String Function(String languageCode) formatLanguageLabel;
  final bool canDownload;

  @override
  Widget build(BuildContext context) {
    final chapters = content.chapters!;
    final l10n = AppLocalizations.of(context)!;
    final groupedChapters = _groupChaptersByLanguage(chapters);
    final previewEntries = _buildChapterPreviewEntries(
      groupedChapters,
      formatLanguageLabel,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.15),
            colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.15),
                  colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chaptersTitle,
                      style: TextStyleConst.headingMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.chapterCount(chapters.length),
                      style: TextStyleConst.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: previewEntries.length,
            itemBuilder: (context, index) {
              final entry = previewEntries[index];
              if (entry.isHeader) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.translate,
                        size: 14,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.languageLabel ?? l10n.languageLabel,
                        style: TextStyleConst.labelMedium.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final chapter = entry.chapter!;
              final displayIndex = entry.chapterIndex ?? (index + 1);
              final isRead = chapterHistory.containsKey(chapter.id);
              final isCompleted =
                  isRead && chapterHistory[chapter.id]!.isCompleted;
              final progress = isRead
                  ? chapterHistory[chapter.id]!.lastPage /
                      chapterHistory[chapter.id]!.totalPages
                  : 0.0;
              final chapterContent = Content(
                id: chapter.id,
                title: '${content.title} - ${chapter.title}',
                coverUrl: content.coverUrl,
                uploadDate: chapter.uploadDate ?? DateTime.now(),
                language: content.language,
                pageCount: 0,
                imageUrls: const [],
                sourceId: content.sourceId,
                relatedContent: const [],
                tags: content.tags,
                artists: content.artists,
                groups: content.groups,
                characters: content.characters,
                parodies: content.parodies,
                favorites: 0,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted
                        ? colorScheme.tertiary.withValues(alpha: 0.5)
                        : isRead
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : colorScheme.outline.withValues(alpha: 0.2),
                    width: isRead ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCompleted
                          ? colorScheme.tertiary.withValues(alpha: 0.15)
                          : isRead
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChapterTap(chapter),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCompleted
                                        ? [
                                            colorScheme.tertiary,
                                            colorScheme.tertiaryContainer,
                                          ]
                                        : [
                                            colorScheme.primary,
                                            colorScheme.secondary,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isCompleted
                                              ? colorScheme.tertiary
                                              : colorScheme.primary)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? Icon(
                                          Icons.check,
                                          color: colorScheme.onTertiary,
                                          size: 28,
                                        )
                                      : isRead
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Text(
                                                  '$displayIndex',
                                                  style: TextStyleConst
                                                      .headingSmall
                                                      .copyWith(
                                                    color: colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  height: 40,
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: progress,
                                                    strokeWidth: 3,
                                                    backgroundColor: Colors
                                                        .white
                                                        .withValues(alpha: 0.3),
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      Colors.white.withValues(
                                                          alpha: 0.9),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              '$displayIndex',
                                              style: TextStyleConst.headingSmall
                                                  .copyWith(
                                                color: colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                ),
                              ),
                              if (isRead)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? colorScheme.tertiary
                                          : colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      isCompleted
                                          ? Icons.done
                                          : Icons.play_arrow,
                                      size: 8,
                                      color: isCompleted
                                          ? colorScheme.onTertiary
                                          : colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chapter.title,
                                  style: TextStyleConst.bodyLarge.copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isCompleted
                                        ? colorScheme.tertiary
                                        : isRead
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (isRead) ...[
                                      Icon(
                                        isCompleted
                                            ? Icons.check_circle
                                            : Icons.auto_stories,
                                        size: 12,
                                        color: isCompleted
                                            ? colorScheme.tertiary
                                            : colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          isCompleted
                                              ? l10n.chapterCompleted
                                              : l10n.continueFromPage(
                                                  chapterHistory[chapter.id]!
                                                      .lastPage,
                                                ),
                                          style:
                                              TextStyleConst.bodySmall.copyWith(
                                            color: isCompleted
                                                ? colorScheme.tertiary
                                                : colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ] else if (chapter.uploadDate != null) ...[
                                      Icon(
                                        Icons.schedule,
                                        size: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          formatDate(chapter.uploadDate!),
                                          style:
                                              TextStyleConst.bodySmall.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (canDownload) ...[
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: DownloadButtonWidget(
                                    content: chapterContent,
                                    size: DownloadButtonSize.small,
                                    showText: false,
                                    showProgress: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCompleted
                                        ? [
                                            colorScheme.tertiary,
                                            colorScheme.tertiary
                                                .withValues(alpha: 0.8),
                                          ]
                                        : [
                                            colorScheme.primary,
                                            colorScheme.primary
                                                .withValues(alpha: 0.8),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isCompleted)
                                      Icon(
                                        Icons.emoji_events,
                                        size: 16,
                                        color: colorScheme.onTertiary,
                                      )
                                    else if (isRead)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 2,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.3),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Colors.white),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.menu_book,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isCompleted
                                          ? l10n.readAgain
                                          : isRead
                                              ? l10n.continueReading
                                              : l10n.readChapter,
                                      style:
                                          TextStyleConst.labelMedium.copyWith(
                                        color: isCompleted
                                            ? colorScheme.onTertiary
                                            : colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: isCompleted
                                          ? colorScheme.onTertiary
                                          : colorScheme.onPrimary,
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
                ),
              );
            },
          ),
          if (chapters.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.list),
                  label: Text(l10n.viewAllChapters),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

class DetailRelatedSection extends StatelessWidget {
  const DetailRelatedSection({
    super.key,
    required this.title,
    required this.items,
    required this.onTap,
    required this.shouldBlurCover,
    required this.resolveHeaders,
  });

  final String title;
  final List<Content> items;
  final ValueChanged<Content> onTap;
  final bool Function(Content content) shouldBlurCover;
  final Map<String, String>? Function(Content content) resolveHeaders;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyleConst.headingSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final relatedContent = items[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onTap(relatedContent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: colorScheme.surfaceContainer,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ProgressiveImageWidget(
                                networkUrl: relatedContent.coverUrl,
                                contentId: relatedContent.id,
                                isThumbnail: true,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                memCacheWidth: 320,
                                memCacheHeight: 400,
                                httpHeaders: resolveHeaders(relatedContent),
                                placeholder: Container(
                                  color: colorScheme.surfaceContainer,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: Container(
                                  color: colorScheme.surfaceContainer,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 32,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              if (shouldBlurCover(relatedContent))
                                const DetailBlacklistedCoverOverlay(
                                  compact: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        relatedContent.title,
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (relatedContent.artists.isNotEmpty)
                        Text(
                          relatedContent.artists.first,
                          style: TextStyleConst.overline.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Map<String, List<Chapter>> _groupChaptersByLanguage(List<Chapter> chapters) {
  final grouped = <String, List<Chapter>>{};
  for (final chapter in chapters) {
    final key = (chapter.language ?? '').trim().toLowerCase();
    final normalized = key.isEmpty ? 'unknown' : key;
    grouped.putIfAbsent(normalized, () => <Chapter>[]).add(chapter);
  }

  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) {
      if (a == 'unknown') return 1;
      if (b == 'unknown') return -1;
      return a.compareTo(b);
    });

  return {for (final key in sortedKeys) key: grouped[key]!};
}

List<_ChapterListEntry> _buildChapterPreviewEntries(
  Map<String, List<Chapter>> grouped,
  String Function(String languageCode) formatLanguageLabel,
) {
  final entries = <_ChapterListEntry>[];
  var displayIndex = 1;
  var chapterCount = 0;

  for (final language in grouped.keys) {
    final chapters = grouped[language]!;
    entries.add(_ChapterListEntry.header(formatLanguageLabel(language)));

    for (final chapter in chapters) {
      if (chapterCount >= 5) {
        return entries;
      }
      entries.add(_ChapterListEntry.chapter(chapter, displayIndex));
      displayIndex += 1;
      chapterCount += 1;
    }
  }

  return entries;
}

class _ChapterListEntry {
  const _ChapterListEntry._({
    required this.isHeader,
    this.languageLabel,
    this.chapter,
    this.chapterIndex,
  });

  factory _ChapterListEntry.header(String label) =>
      _ChapterListEntry._(isHeader: true, languageLabel: label);

  factory _ChapterListEntry.chapter(Chapter chapter, int chapterIndex) =>
      _ChapterListEntry._(
        isHeader: false,
        chapter: chapter,
        chapterIndex: chapterIndex,
      );

  final bool isHeader;
  final String? languageLabel;
  final Chapter? chapter;
  final int? chapterIndex;
}
