import 'package:flutter/material.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/cubits/detail/detail_cubit.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/presentation/widgets/download_button_widget.dart';
import 'package:intl/intl.dart';

class ChapterListBottomSheet extends StatefulWidget {
  final Content content;
  final DetailCubit detailCubit;

  const ChapterListBottomSheet({
    super.key,
    required this.content,
    required this.detailCubit,
  });

  @override
  State<ChapterListBottomSheet> createState() => _ChapterListBottomSheetState();
}

class _ChapterListBottomSheetState extends State<ChapterListBottomSheet> {
  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chapters = widget.content.chapters ?? [];
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.chaptersTitle,
                      style: TextStyleConst.headingMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.chapterCount(chapters.length),
                        style: TextStyleConst.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    // Find original index for display number
                    final originalIndex = index;
                    
                    // Create Content object for download widget (reusing from DetailScreen logic)
                    final chapterContent = Content(
                      id: chapter.id,
                      title: '${widget.content.title} - ${chapter.title}',
                      coverUrl: widget.content.coverUrl,
                      uploadDate: chapter.uploadDate ?? DateTime.now(),
                      language: widget.content.language,
                      pageCount: 0,
                      imageUrls: const [],
                      sourceId: widget.content.sourceId,
                      relatedContent: const [],
                      tags: widget.content.tags,
                      artists: widget.content.artists,
                      groups: widget.content.groups,
                      characters: widget.content.characters,
                      parodies: widget.content.parodies,
                      favorites: 0,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            widget.detailCubit.openChapter(chapter);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Number Badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${originalIndex + 1}',
                                      style: TextStyleConst.titleMedium.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chapter.title,
                                        style: TextStyleConst.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (chapter.uploadDate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(chapter.uploadDate!),
                                          style: TextStyleConst.bodySmall.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Actions
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (getIt<RemoteConfigService>().isFeatureEnabled(
                                        widget.content.sourceId, (f) => f.download))
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: DownloadButtonWidget(
                                          content: chapterContent,
                                          size: DownloadButtonSize.small,
                                          showText: false,
                                          showProgress: true,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
