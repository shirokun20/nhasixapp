import 'package:flutter/material.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/domain/entities/history.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/widgets/kuro_mascot.dart';

const double _fabWidth = 268;
const double _fabHeight = 92;

class ChapterContinueTarget {
  const ChapterContinueTarget({
    required this.chapter,
    required this.page,
    required this.finished,
  });

  final Chapter chapter;
  final int page;
  final bool finished;
}

/// Picks the most recently viewed chapter, skipping chapters that exist in
/// [chapters] but are not readable in-app (external/unavailable sources).
ChapterContinueTarget? resolveChapterContinueTarget({
  required Map<String, History>? chapterHistory,
  required List<Chapter> chapters,
}) {
  if (chapterHistory == null || chapterHistory.isEmpty) return null;

  final byId = {for (final chapter in chapters) chapter.id: chapter};
  final entries = chapterHistory.entries
      .where((entry) => (entry.value.chapterId ?? '').isNotEmpty)
      .toList()
    ..sort((a, b) => b.value.lastViewed.compareTo(a.value.lastViewed));

  for (final entry in entries) {
    final history = entry.value;
    final chapterId = history.chapterId!;
    final known = byId[chapterId];
    if (known != null && !known.isReadableInApp) continue;

    final totalPages = history.totalPages;
    final finished = history.isCompleted ||
        (totalPages > 0 && history.lastPage >= totalPages);
    var page = finished ? 1 : history.lastPage;
    if (totalPages > 0) page = page.clamp(1, totalPages).toInt();
    if (page < 1) page = 1;

    // A finished chapter means restarting the series: the source lists
    // chapters newest-first more often than not, so "first" is decided by the
    // chapter number parsed from its name, never by array position.
    if (finished) {
      final first = _firstChapterByNumber(chapters);
      if (first != null) {
        return ChapterContinueTarget(
          chapter: first,
          page: 1,
          finished: true,
        );
      }
    }

    return ChapterContinueTarget(
      // Synthesized when the reader history outlives the loaded chapter list.
      chapter: known ??
          Chapter(
            id: chapterId,
            title: history.chapterTitle ?? chapterId,
            url: chapterId,
          ),
      page: page,
      finished: finished,
    );
  }

  return null;
}

/// Chapter order as declared by its name: `Chapter 12`, `Bab 12.5`, `Ch. 3`,
/// `第12話`, or a bare leading number. Numeric (`2` < `10`), never lexical.
double? chapterNumberFromName(String name) {
  final keyword = RegExp(
    r'(?:chapter|chap|ch|bab|episode|eps|ep|第)\s*[.\-:]?\s*(\d+(?:[.,]\d+)?)',
    caseSensitive: false,
  ).firstMatch(name);
  final match = keyword ?? RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(name);
  final raw = match?.group(1);
  if (raw == null) return null;
  return double.tryParse(raw.replaceAll(',', '.'));
}

Chapter? _firstChapterByNumber(List<Chapter> chapters) {
  Chapter? first;
  double? firstNumber;
  for (final chapter in chapters) {
    if (!chapter.isReadableInApp) continue;
    final number = chapterNumberFromName(chapter.title) ??
        chapterNumberFromName(chapter.url);
    if (number == null) continue;
    if (firstNumber == null || number < firstNumber) {
      first = chapter;
      firstNumber = number;
    }
  }
  return first;
}

class ChapterContinueFab extends StatefulWidget {
  const ChapterContinueFab({
    super.key,
    required this.target,
    required this.onTap,
  });

  final ChapterContinueTarget target;
  final VoidCallback onTap;

  @override
  State<ChapterContinueFab> createState() => _ChapterContinueFabState();
}

class _ChapterContinueFabState extends State<ChapterContinueFab> {
  Offset? _position;

  Offset _clamp(Offset position, BoxConstraints constraints, EdgeInsets inset) {
    final minLeft = 8.0;
    final maxLeft = (constraints.maxWidth - _fabWidth - 8).clamp(minLeft, double.infinity);
    final minTop = 8.0 + inset.top;
    final maxTop = (constraints.maxHeight - _fabHeight - 8 - inset.bottom)
        .clamp(minTop, double.infinity);
    return Offset(
      position.dx.clamp(minLeft, maxLeft),
      position.dy.clamp(minTop, maxTop),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final target = widget.target;

    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = MediaQuery.paddingOf(context);
        final defaultPosition = Offset(
          constraints.maxWidth - _fabWidth - 16,
          constraints.maxHeight - _fabHeight - 16 - inset.bottom,
        );
        final position = _clamp(_position ?? defaultPosition, constraints, inset);

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onTap: widget.onTap,
                onPanUpdate: (details) => setState(
                  () => _position = _clamp(position + details.delta, constraints, inset),
                ),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: _fabWidth,
                    height: _fabHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          KuroMascot(
                            mood: target.finished ? KuroMood.happy : KuroMood.reader,
                            size: 48,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  target.finished
                                      ? l10n.readerScreenGoToFirstPage
                                      : l10n.continueFromPage(target.page),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  target.finished
                                      ? l10n.chapterContinueFabRestartHint
                                      : l10n.chapterContinueFabResumeHint(target.page),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
