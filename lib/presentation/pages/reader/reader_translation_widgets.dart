import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/glossary.dart';
import 'package:nhasixapp/domain/entities/reader_settings_entity.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';

import '../../../domain/entities/ai_translation.dart';

/// Toolbar button group for AI translation: ✨ translate, then overlay toggle.
class ReaderTranslationToolbar extends StatelessWidget {
  const ReaderTranslationToolbar({
    super.key,
    required this.readingMode,
    required this.onTranslate,
  });

  final ReadingMode readingMode;
  final VoidCallback onTranslate;

  @override
  Widget build(BuildContext context) {
    // Translate + draw stay enabled in continuous scroll. The cubit gates
    // translate on the fetched page's aspect ratio (webtoon); draw/detect
    // work on the visible page (captured on entry). Nothing is disabled in CS.
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ReaderTranslationCubit, ReaderTranslationState>(
      builder: (context, state) {
        final cubit = context.read<ReaderTranslationCubit>();
        final active =
            state is ReaderTranslationTranslated && cubit.overlayVisible;
        final busy = state is ReaderTranslationDetecting ||
            state is ReaderTranslationBuildingMosaic ||
            state is ReaderTranslationTranslating ||
            state is ReaderTranslationTranslatingBubble;
        final shouldRefreshViewport =
            readingMode == ReadingMode.continuousScroll;
        final activeColor = Theme.of(context).colorScheme.primary;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: (active
                  ? l10n.aiHideTranslation
                  : busy
                      ? l10n.aiTranslating
                      : l10n.aiTranslatePage),
              onPressed: busy
                  ? null
                  : () {
                      if (state is ReaderTranslationTranslated &&
                          !shouldRefreshViewport) {
                        cubit.toggleOverlay();
                      } else {
                        onTranslate();
                      }
                    },
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      active ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                      color: active ? activeColor : null,
                    ),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
            // Reset translate result + reference bubbles
            if (state is ReaderTranslationTranslated ||
                cubit.detectedBoxes.isNotEmpty ||
                cubit.manualBubbles.isNotEmpty)
              IconButton(
                tooltip: l10n.aiClearTranslateBubbles,
                onPressed: cubit.resetPage,
                icon: const Icon(Icons.delete_sweep_outlined,
                    size: 20, color: Colors.redAccent),
                visualDensity: VisualDensity.compact,
              ),
            // Manual bubble drawing toggle (9.5)
            IconButton(
              tooltip:
                  cubit.drawMode ? l10n.aiExitDrawMode : l10n.aiDrawBubbles,
              onPressed: () {
                if (cubit.drawMode) {
                  cubit.setDrawMode(false);
                } else {
                  cubit.setDrawMode(true);
                }
              },
              icon: Icon(
                Icons.draw_outlined,
                color: cubit.drawMode ? activeColor : null,
              ),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          ],
        );
      },
    );
  }
}

/// Overlay layer: positions translated bubbles over the reader image.
///
/// The reader renders the page with `BoxFit.fitWidth`, so bubble rects in
/// ORIGINAL-image pixel space are mapped to screen space by scaling with
/// `screenW / imageW` (X) and `screenH / imageH` (Y). Vertical alignment:
/// image height = `screenW * imgH / imgW`, letterboxed/centered vertically
/// if the image is shorter than the viewport.
class ReaderTranslationOverlay extends StatelessWidget {
  const ReaderTranslationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return BlocBuilder<ReaderTranslationCubit, ReaderTranslationState>(
      buildWhen: (prev, curr) =>
          curr is ReaderTranslationTranslated ||
          curr is ReaderTranslationTranslatingBubble ||
          curr is ReaderTranslationTranslating ||
          curr is ReaderTranslationIdle, // reset clears the overlay
      builder: (context, state) {
        if (state is! ReaderTranslationTranslated) {
          return const SizedBox.shrink();
        }
        final result = state.result;
        final imgW = state.imageWidth.toDouble();
        final imgH = state.imageHeight.toDouble();
        if (imgW <= 0 || imgH <= 0) return const SizedBox.shrink();

        // fitWidth scale: image fills screen width; height derived from AR.
        final scaleX = screenSize.width / imgW;
        final renderedH = screenSize.width * (imgH / imgW);
        final scaleY = renderedH / imgH;
        // Vertical letterbox offset (image centered when shorter than screen)
        final topOffset = renderedH < screenSize.height
            ? (screenSize.height - renderedH) / 2
            : 0.0;

        return Stack(
          children: [
            for (var i = 0; i < result.bubbles.length; i++)
              _positionedBubble(result.bubbles[i], scaleX, scaleY, topOffset, i),
          ],
        );
      },
    );
  }
}

/// Maps a bubble to its screen rect, inflating tiny bubbles (below the 44px
/// touch target) outward from center so short text still fits and remains
/// tappable. Expansion keeps the bubble visually anchored to its position.
Widget _positionedBubble(
  BubbleTranslation bubble,
  double scaleX,
  double scaleY,
  double topOffset,
  int index,
) {
  const minDim = 44.0;
  var rect = Rect.fromLTWH(
    bubble.rect.left * scaleX,
    bubble.rect.top * scaleY + topOffset,
    bubble.rect.width * scaleX,
    bubble.rect.height * scaleY,
  );
  var inflate = 0.0;
  if (rect.width < minDim || rect.height < minDim) {
    inflate = (minDim - rect.shortestSide).clamp(0.0, 24.0);
    rect = rect.inflate(inflate);
  }
  return Positioned.fromRect(
    rect: rect,
    child: ReaderTranslatedBubble(bubble: bubble, index: index),
  );
}

class ReaderTranslatedBubble extends StatelessWidget {
  const ReaderTranslatedBubble({super.key, required this.bubble, required this.index});

  final BubbleTranslation bubble;
  final int index;

  /// Manga font pick: Komika Axis (Latin) vs KosugiMaru (CJK/Korean/Unicode).
  static final _cjk = RegExp(r'[぀-ゟ゠-ヿ一-鿿가-힯]');
  String get _fontFamily =>
      _cjk.hasMatch(bubble.translated) ? 'KosugiMaru' : 'Komika';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEditSheet(context),
      onLongPress: () => _showSaveToGlossarySheet(context),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final box = Size(constraints.maxWidth, constraints.maxHeight);
            return Text(
              bubble.translated,
              textAlign: TextAlign.center,
              style: _fitText(bubble.translated, box, _fontFamily),
            );
          },
        ),
      ),
    );
  }

  /// Tap → edit translation bottom sheet (spec 9.2).
  void _showEditSheet(BuildContext context) {
    final controller = TextEditingController(text: bubble.translated);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(sheetContext)!.aiEditTranslation,
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(sheetContext)!.aiTranslation,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context
                    .read<ReaderTranslationCubit>()
                    .editBubbleTranslation(index, controller.text.trim());
                Navigator.pop(sheetContext);
              },
              child: Text(AppLocalizations.of(sheetContext)!.aiSave),
            ),
          ],
        ),
      ),
    );
  }

  /// Long-press → "Save to Glossary" action sheet (spec 7.1).
  void _showSaveToGlossarySheet(BuildContext context) {
    final state = context.read<ReaderTranslationCubit>().state;
    final contentId =
        state is ReaderTranslationTranslated ? state.contentId : '';
    final pageIndex =
        state is ReaderTranslationTranslated ? state.pageIndex : 0;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(bubble.translated),
              subtitle: Text(bubble.original.isEmpty
                  ? AppLocalizations.of(sheetContext)!.aiSaveToGlossaryHint
                  : bubble.original),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined),
              title: Text(AppLocalizations.of(sheetContext)!.aiSaveToGlossary),
              onTap: () async {
                getIt<Logger>().d(
                    'Glossary: saving "${bubble.translated}" from page $pageIndex');
                try {
                  await getIt<GlossaryRepository>().save(GlossaryEntry(
                    id: 'gl_${DateTime.now().millisecondsSinceEpoch}_${bubble.rect.hashCode}',
                    sourceText: bubble.original,
                    translatedText: bubble.translated,
                    reading: bubble.reading,
                    contentId: contentId,
                    pageIndex: pageIndex,
                    timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  ));
                  getIt<Logger>().i('Glossary saved OK');
                } catch (e) {
                  getIt<Logger>().e('Glossary save FAILED: $e');
                }
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            AppLocalizations.of(context)!.aiSavedToGlossary)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Font-fit: largest size (descending) whose wrapped text fits the bubble.
/// Mirrors cypy `tulis_teks_di_balon` — score `size*10 + fillRatio`; pick
/// first size that fits (descending order makes it the max).
TextStyle _fitText(String text, Size box, String fontFamily) {
  // Base range [8,50], scaled down proportionally for small bubbles so the
  // text shrinks instead of overflowing. Bounded ≤ ~40 layout iterations.
  final shortSide = box.shortestSide < 40.0 ? box.shortestSide / 40.0 : 1.0;
  final maxSize = (42.0 * shortSide).clamp(6.0, 42.0);
  final minSize = (7.0 * shortSide).clamp(4.0, 7.0);
  final maxW = box.width * 0.8;
  final maxH = box.height * 0.8;

  for (var size = maxSize; size >= minSize; size -= 1) {
    final style = TextStyle(
      fontSize: size,
      color: Colors.black,
      fontWeight: FontWeight.w600,
      fontFamily: fontFamily,
      height: 1.15,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxW);
    if (painter.height <= maxH && painter.width <= maxW) return style;
  }
  return TextStyle(
    fontSize: minSize,
    color: Colors.black,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    height: 1.15,
  );
}
