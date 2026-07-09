import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/cubits/detail/detail_cubit.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/services/language_service.dart';
import 'package:nhasixapp/presentation/utils/chapter_language_presenter.dart';
import 'package:nhasixapp/presentation/widgets/download_button_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/constants/design_tokens.dart';
import 'package:nhasixapp/domain/entities/history.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
import 'package:nhasixapp/domain/value_objects/value_objects.dart';

class ChapterListBottomSheet extends StatefulWidget {
  const ChapterListBottomSheet({
    super.key,
    required this.content,
    required this.detailCubit,
    this.initialLanguageKey,
    this.initialScanGroup,
  });

  final Content content;
  final DetailCubit detailCubit;
  final String? initialLanguageKey;
  final String? initialScanGroup;

  @override
  State<ChapterListBottomSheet> createState() => _ChapterListBottomSheetState();
}

class _ChapterListBottomSheetState extends State<ChapterListBottomSheet> {
  late final List<Chapter> _chapters;
  final _contentRepository = getIt<ContentRepository>();
  String? _selectedLanguageKey;
  bool _isLoadingMore = false;
  String? _loadMoreError;
  final Set<String> _fullyLoadedLanguages = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialScanGroup == 'Volume') {
      _chapters = [...?widget.content.chapters];
    } else {
      _chapters = [...?widget.content.chapters]
          .where((c) => c.scanGroup != 'Volume')
          .toList();
    }
    _selectedLanguageKey = widget.initialLanguageKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chapters = _chapters;
    final chapterLanguages = ChapterLanguagePresenter.build(
      chapters,
      selectedKey: _selectedLanguageKey,
      labelForKey: _languageLabel,
    );
    _selectedLanguageKey = chapterLanguages.selectedKey;
    final loadMoreLanguageKey = chapterLanguages.selectedKey ??
        (chapterLanguages.lanes.length == 1
            ? chapterLanguages.lanes.first.key
            : null);
    final canLoadMore = _canLoadMore(loadMoreLanguageKey);
    final entries = chapterLanguages.hasMultipleLanes
        ? _buildGroupedEntries(chapterLanguages.selectedChapters)
        : _buildGroupedEntries(chapters, labelForKey: _languageLabel);
    ChapterLanguageLane? selectedLane;
    for (final lane in chapterLanguages.lanes) {
      if (lane.key == loadMoreLanguageKey) {
        selectedLane = lane;
        break;
      }
    }
    final loadedCount = selectedLane?.chapters.length ?? chapters.length;

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

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.chaptersTitle,
                              style: TextStyleConst.headingMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (selectedLane != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${selectedLane.label} • $loadedCount loaded',
                                style: TextStyleConst.bodySmall.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
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
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radius2xl),
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

                  Divider(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.6),
                  ),

                  if (chapterLanguages.hasMultipleLanes)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainer
                          .withValues(alpha: 0.7),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final lane in chapterLanguages.lanes) ...[
                              _buildLanguageChip(
                                context,
                                lane: lane,
                                selected:
                                    lane.key == chapterLanguages.selectedKey,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),

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
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusLg),
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

                        final subtitleParts = [
                          if ((chapter.scanGroup ?? '').trim().isNotEmpty)
                            chapter.scanGroup!.trim(),
                        ];
                        final hasScanGroup =
                            (chapter.scanGroup ?? '').trim().isNotEmpty;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
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
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusLg),
                            border: Border.all(
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.tertiary
                                  : isRead
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: 0.5),
                              width: isRead ? 1.4 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.pop();
                                widget.detailCubit.openChapter(chapter);
                              },
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusXl),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Number Badge with progress indicator
                                    Stack(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
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
                                            borderRadius: BorderRadius.circular(
                                                DesignTokens.radiusMd),
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
                                          if (subtitleParts.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  hasScanGroup
                                                      ? Icons.groups_2_outlined
                                                      : Icons.schedule,
                                                  size: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    subtitleParts.join(' • '),
                                                    style: TextStyleConst
                                                        .bodySmall
                                                        .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
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
                  if (canLoadMore)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _isLoadingMore
                              ? null
                              : () => _loadMoreChapters(
                                    loadMoreLanguageKey!,
                                  ),
                          icon: _isLoadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(_isLoadingMore
                              ? l10n.loading
                              : _loadMoreError ??
                                  'Load 100 more ${selectedLane?.label ?? 'chapters'}'),
                        ),
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

  bool _canLoadMore(String? key) {
    if (key == null || _fullyLoadedLanguages.contains(key)) return false;
    // Volumes API returns all at once — no pagination to load.
    if (widget.initialScanGroup == 'Volume') return false;
    return widget.content.sourceId == 'mangadex' ||
        widget.content.sourceId == 'mangafire';
  }

  Widget _buildLanguageChip(
    BuildContext context, {
    required ChapterLanguageLane lane,
    required bool selected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: selected ? const Icon(Icons.check, size: 16) : null,
      label: Text('${lane.label}  ${lane.chapters.length}'),
      labelStyle: TextStyleConst.labelMedium.copyWith(
        color:
            selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.6,
      ),
      side: BorderSide(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.55)
            : colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
      onSelected: (_) {
        setState(() {
          _selectedLanguageKey = lane.key;
          _loadMoreError = null;
        });
      },
    );
  }

  int _resolvePageLimit() {
    final cfg = getIt<RemoteConfigService>().getRawConfig(widget.content.sourceId);
    final chapterCfg = (cfg?['api']?['detail']?['chapters'] as Map?)
        ?? (cfg?['api']?['chapters'] as Map?);
    final endpoint = chapterCfg?['endpoint']?.toString() ?? '';
    final match = RegExp(r'limit=(\d+)').firstMatch(endpoint);
    return match != null ? int.parse(match.group(1)!) : 100;
  }

  Future<void> _loadMoreChapters(String languageKey) async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final limit = _resolvePageLimit();
      final loadedForLang = _chapters
          .where((c) =>
              ChapterLanguagePresenter.normalize(c.language) ==
              ChapterLanguagePresenter.normalize(languageKey))
          .length;
      final isPageSource = widget.content.sourceId == 'mangafire';
      final next = await _contentRepository.getContentChapters(
        ContentId(widget.content.id),
        sourceId: widget.content.sourceId,
        language: languageKey,
        page: isPageSource ? (loadedForLang ~/ limit + 1) : null,
        offset: isPageSource ? null : loadedForLang,
        limit: limit,
        scanGroup: widget.initialScanGroup ?? 'Chapter',
      );
      final existingIds = _chapters.map((chapter) => chapter.id).toSet();
      final nextChapters = next
          .where((chapter) => existingIds.add(chapter.id))
          .toList(growable: false);

      setState(() {
        _chapters.addAll(nextChapters);
        if (next.length < limit) {
          _fullyLoadedLanguages.add(languageKey);
        }
      });
    } catch (_) {
      setState(() => _loadMoreError = 'Retry load more');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  List<_GroupedChapterEntry> _buildGroupedEntries(
    List<Chapter> chapters, {
    String Function(String languageCode)? labelForKey,
  }) {
    final entries = <_GroupedChapterEntry>[];
    var index = 1;

    if (labelForKey == null) {
      for (final chapter in chapters) {
        entries.add(_GroupedChapterEntry.chapter(chapter, index));
        index += 1;
      }
      return entries;
    }

    final grouped = ChapterLanguagePresenter.build(
      chapters,
      labelForKey: labelForKey,
    );
    for (final lane in grouped.lanes) {
      entries.add(_GroupedChapterEntry.header(lane.label));
      for (final chapter in lane.chapters) {
        entries.add(_GroupedChapterEntry.chapter(chapter, index));
        index += 1;
      }
    }
    return entries;
  }

  String _languageLabel(String code) {
    final normalized = ChapterLanguagePresenter.normalize(code);
    if (normalized == unknownChapterLanguageKey) {
      return AppLocalizations.of(context)!.languageLabel;
    }
    final languageService = getIt<LanguageService>();
    final displayName = languageService.resolve(normalized)?.displayName ??
        (normalized.contains('-')
            ? languageService.displayName(normalized.split('-').first)
            : languageService.displayName(normalized));
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
