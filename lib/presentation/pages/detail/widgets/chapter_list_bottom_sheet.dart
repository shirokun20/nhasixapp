import 'package:flutter/material.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/cubits/detail/detail_cubit.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/services/language_service.dart';
import 'package:nhasixapp/presentation/widgets/download_button_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nhasixapp/domain/entities/history.dart';

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
    final groupedChapters = _groupChaptersByLanguage(chapters);
    final entries = _buildGroupedEntries(groupedChapters);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<DetailCubit, DetailState>(
          bloc: widget.detailCubit,
          builder: (context, state) {
            Map<String, History>? chapterHistory;
            if (state is DetailLoaded) {
              chapterHistory = state.chapterHistory;
            } else if (state is DetailReaderReady) {
              chapterHistory = state.chapterHistory;
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
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
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        if (entry.isHeader) {
                          return Container(
                            margin: const EdgeInsets.fromLTRB(0, 4, 0, 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.translate,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.languageLabel!,
                                  style: TextStyleConst.labelMedium.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final chapter = entry.chapter!;

                        // Check history and calculate progress
                        bool isRead = false;
                        bool isCompleted = false;
                        double progress = 0.0;
                        if (chapterHistory != null) {
                          final history = chapterHistory[chapter.id];
                          isRead = history != null;
                          isCompleted = history?.isCompleted ?? false;
                          if (history != null) {
                            progress = history.lastPage / history.totalPages;
                          }
                        }

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
                            color: isRead
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.5),
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
                                    // Number Badge with progress indicator
                                    Stack(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiaryContainer
                                                : isRead
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: isCompleted
                                                ? Icon(
                                                    Icons.check,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                                    size: 24,
                                                  )
                                                : isRead
                                                    ? Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Text(
                                                            '${entry.chapterIndex ?? (index + 1)}',
                                                            style:
                                                                TextStyleConst
                                                                    .titleMedium
                                                                    .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          // Progress ring for in-progress chapters
                                                          SizedBox(
                                                            width: 36,
                                                            height: 36,
                                                            child:
                                                                CircularProgressIndicator(
                                                              value: progress,
                                                              strokeWidth: 2.5,
                                                              backgroundColor: Theme
                                                                      .of(
                                                                          context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer
                                                                  .withValues(
                                                                      alpha:
                                                                          0.2),
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                      Color>(
                                                                Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary
                                                                    .withValues(
                                                                        alpha:
                                                                            0.9),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        '${entry.chapterIndex ?? (index + 1)}',
                                                        style: TextStyleConst
                                                            .titleMedium
                                                            .copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onPrimaryContainer,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                          ),
                                        ),
                                        // Status dot indicator
                                        if (isRead)
                                          Positioned(
                                            right: -2,
                                            top: -2,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: isCompleted
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .tertiary
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Chapter title
                                          Text(
                                            chapter.title,
                                            style: TextStyleConst.bodyLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isCompleted
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (chapter.uploadDate != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDate(chapter.uploadDate!),
                                              style: TextStyleConst.bodySmall
                                                  .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
                                        if (getIt<RemoteConfigService>()
                                            .isFeatureEnabled(
                                                widget.content.sourceId,
                                                (f) => f.download))
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
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
      },
    );
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

  List<_GroupedChapterEntry> _buildGroupedEntries(
    Map<String, List<Chapter>> grouped,
  ) {
    final entries = <_GroupedChapterEntry>[];
    var index = 1;
    for (final language in grouped.keys) {
      entries.add(_GroupedChapterEntry.header(_languageLabel(language)));
      final chapters = grouped[language]!;
      for (final chapter in chapters) {
        entries.add(_GroupedChapterEntry.chapter(chapter, index));
        index += 1;
      }
    }
    return entries;
  }

  String _languageLabel(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'unknown') {
      return AppLocalizations.of(context)!.languageLabel;
    }
    final languageService = getIt<LanguageService>();
    final displayName = languageService.displayName(normalized);
    return '$displayName (${normalized.toUpperCase()})';
  }
}

class _GroupedChapterEntry {
  const _GroupedChapterEntry._({
    required this.isHeader,
    this.languageLabel,
    this.chapter,
    this.chapterIndex,
  });

  factory _GroupedChapterEntry.header(String label) =>
      _GroupedChapterEntry._(isHeader: true, languageLabel: label);

  factory _GroupedChapterEntry.chapter(Chapter chapter, int index) =>
      _GroupedChapterEntry._(
        isHeader: false,
        chapter: chapter,
        chapterIndex: index,
      );

  final bool isHeader;
  final String? languageLabel;
  final Chapter? chapter;
  final int? chapterIndex;
}
