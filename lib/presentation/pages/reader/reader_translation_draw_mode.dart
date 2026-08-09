import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';

/// Manual bubble drawing mode (spec 9.5): pan-drag → red rectangle.
/// ONNX-detected bubbles shown in BLUE as reference; manual bubbles in RED.
/// Controls: Undo / Clear / Done.
///
/// Repaint is driven by local [setState] — the cubit state is Equatable and
/// emitting identical states is skipped by the bloc, so painter refreshes
/// must not rely on state changes.
class ReaderTranslationDrawMode extends StatefulWidget {
  const ReaderTranslationDrawMode({super.key, this.onCaptureNeeded});

  /// Called before running detection when no page is captured yet (lazy
  /// capture). Lets the reader capture the current viewport only on demand,
  /// instead of on every draw-mode entry (which janks on repeated toggles).
  final Future<void> Function()? onCaptureNeeded;

  @override
  State<ReaderTranslationDrawMode> createState() =>
      _ReaderTranslationDrawModeState();
}

class _ReaderTranslationDrawModeState extends State<ReaderTranslationDrawMode> {
  Rect? _dragging;
  List<Rect> _onnxRects = const [];
  List<Rect> _manualRects = const [];

  void _repaint() => setState(() {});

  /// Tap on a bubble removes it — mirrors the example app. Topmost hit wins:
  /// manual bubbles (red) checked before ONNX (blue).
  void _handleTap(
    ReaderTranslationCubit cubit,
    Offset pos,
    double scaleX,
    double scaleY,
    double topOffset,
  ) {
    for (var i = _manualRects.length - 1; i >= 0; i--) {
      if (_manualRects[i].contains(pos)) {
        cubit.removeManualBubble(i);
        _repaint();
        return;
      }
    }
    for (var i = _onnxRects.length - 1; i >= 0; i--) {
      if (_onnxRects[i].contains(pos)) {
        cubit.removeDetectedBubble(i);
        _repaint();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderTranslationCubit, ReaderTranslationState>(
      builder: (context, state) {
        final cubit = context.read<ReaderTranslationCubit>();
        final drawMode = cubit.drawMode;
        // Boxes stay visible in draw mode, while a translate runs, and after
        // Done (draw off, no translate running). They hide ONLY once the
        // translated overlay replaces them.
        final showBoxes = state is! ReaderTranslationTranslated;
        final colorScheme = Theme.of(context).colorScheme;

        final screenSize = MediaQuery.sizeOf(context);
        // Coordinate mapping: image px ↔ screen px — SAME fitWidth math as
        // the translated overlay (image fills width; rendered height derived
        // from aspect ratio; vertical letterbox when shorter than screen).
        // Use the CAPTURED page dimensions (not Translated state): detect
        // runs pre-translate, and the page is always captured on draw entry.
        final imgW = (cubit.pageWidth > 0
            ? cubit.pageWidth.toDouble()
            : screenSize.width);
        final imgH = (cubit.pageHeight > 0
            ? cubit.pageHeight.toDouble()
            : screenSize.height);
        final scaleX = screenSize.width / imgW;
        final renderedH = screenSize.width * (imgH / imgW);
        final scaleY = renderedH / imgH;
        final topOffset = renderedH < screenSize.height
            ? (screenSize.height - renderedH) / 2
            : 0.0;

        // ONNX-detected bubbles (blue reference) — live from cubit so a
        // dedicated "Detect" run renders them pre-translate.
        _onnxRects = cubit.detectedBoxes
            .map((b) => Rect.fromLTWH(
                  b.x * scaleX,
                  b.y * scaleY + topOffset,
                  b.w * scaleX,
                  b.h * scaleY,
                ))
            .toList();

        return Stack(
          children: [
            // Drag layer — interactive only in draw mode. Reference bubbles
            // (ONNX blue / manual red) render while [showBoxes]; otherwise
            // the translated overlay stays clean (no stray boxes over text).
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !drawMode,
                child: GestureDetector(
                  onTapUp: (d) => _handleTap(
                      cubit, d.localPosition, scaleX, scaleY, topOffset),
                  onPanStart: (d) => setState(() => _dragging =
                      Rect.fromPoints(d.localPosition, d.localPosition)),
                  onPanUpdate: (d) => setState(() => _dragging =
                      Rect.fromPoints(_dragging!.topLeft, d.localPosition)),
                  onPanEnd: (_) {
                    if (_dragging != null &&
                        _dragging!.width > 4 &&
                        _dragging!.height > 4) {
                      // Screen space → image space (ONNX bubbles are image px).
                      // Note: renderedH may exceed the screen (tall pages) —
                      // vertical scale is renderedH/imgH, NOT screenH/imgH.
                      cubit.addManualBubble(Rect.fromLTRB(
                        _dragging!.left / scaleX,
                        (_dragging!.top - topOffset) / scaleY,
                        _dragging!.right / scaleX,
                        (_dragging!.bottom - topOffset) / scaleY,
                      ));
                    }
                    setState(() => _dragging = null);
                  },
                  child: CustomPaint(
                    painter: _DrawPainter(
                      dragging: showBoxes ? _dragging : null,
                      onnxColor: colorScheme.tertiary,
                      manualColor: colorScheme.primary,
                      onnxRects: showBoxes ? _onnxRects : const [],
                      manualRects: showBoxes
                          ? (_manualRects = cubit.manualBubbles
                              .map((b) => Rect.fromLTWH(
                                    b.x * scaleX,
                                    b.y * scaleY + topOffset,
                                    b.w * scaleX,
                                    b.h * scaleY,
                                  ))
                              .toList())
                          : const [],
                    ),
                  ),
                ),
              ),
            ),
            // Controls — draw mode only. A small pill that expands into the
            // action panel on tap, so it never blocks the reader chrome or
            // the page below.
            if (drawMode)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: _DrawModeControls(
                    onDetect: () async {
                      // Always capture the CURRENT viewport first — the user may
                      // have scrolled since the last capture, so a stale bitmap
                      // (from another scroll position) would mis-detect bubbles.
                      await widget.onCaptureNeeded?.call();
                      if (!mounted) return;
                      await cubit.detectBubblesOnly();
                      _repaint();
                    },
                    onUndo: () {
                      cubit.undoLastManual();
                      _repaint();
                    },
                    onClear: () {
                      cubit.clearManualBubbles();
                      _repaint();
                    },
                    onDone: () => cubit.setDrawMode(false),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Expandable action pill for draw mode. Collapsed: a single round button.
/// Expanded: Detect / Undo / Clear / Done actions above it.
class _DrawModeControls extends StatefulWidget {
  const _DrawModeControls({
    required this.onDetect,
    required this.onUndo,
    required this.onClear,
    required this.onDone,
  });

  final VoidCallback onDetect;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onDone;

  @override
  State<_DrawModeControls> createState() => _DrawModeControlsState();
}

class _DrawModeControlsState extends State<_DrawModeControls> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Shared pill visuals — matches the mini chrome toggle look.
    final pillDecoration = BoxDecoration(
      color: colorScheme.inverseSurface.withValues(alpha: 0.88),
      shape: BoxShape.circle,
      border: Border.all(
        color: colorScheme.onInverseSurface.withValues(alpha: 0.18),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _expanded
              ? Material(
                  color: colorScheme.inverseSurface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(28),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DrawAction(
                          icon: Icons.radar,
                          tooltip: l10n.aiDrawDetect,
                          onTap: widget.onDetect,
                        ),
                        _DrawAction(
                          icon: Icons.undo,
                          tooltip: l10n.aiDrawUndo,
                          onTap: widget.onUndo,
                        ),
                        _DrawAction(
                          icon: Icons.delete_sweep_outlined,
                          tooltip: l10n.aiDrawClear,
                          onTap: widget.onClear,
                        ),
                        _DrawAction(
                          icon: Icons.check,
                          tooltip: l10n.aiExitDrawMode,
                          onTap: widget.onDone,
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: Tooltip(
            message: _expanded ? l10n.aiCollapseDraw : l10n.aiExpandDraw,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _expanded ? 48 : 56,
                height: _expanded ? 48 : 56,
                decoration: pillDecoration,
                child: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.edit_outlined,
                  size: 24,
                  color: colorScheme.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawAction extends StatelessWidget {
  const _DrawAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: colorScheme.onInverseSurface),
        ),
      ),
    );
  }
}

class _DrawPainter extends CustomPainter {
  const _DrawPainter({
    this.dragging,
    this.onnxRects = const [],
    this.manualRects = const [],
    this.onnxColor = const Color(0xFFFFFFFF),
    this.manualColor = const Color(0xFFFFFFFF),
  });

  final Rect? dragging;
  final List<Rect> onnxRects; // ONNX-detected (reference)
  final List<Rect> manualRects; // user-drawn
  final Color onnxColor;
  final Color manualColor;

  @override
  void paint(Canvas canvas, Size size) {
    final onnxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = onnxColor;
    for (final r in onnxRects) {
      canvas.drawRect(r, onnxPaint);
    }

    final manualPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = manualColor;
    for (final r in manualRects) {
      canvas.drawRect(r, manualPaint);
    }

    if (dragging != null) {
      canvas.drawRect(
        dragging!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_DrawPainter oldDelegate) =>
      oldDelegate.dragging != dragging ||
      oldDelegate.onnxColor != onnxColor ||
      oldDelegate.manualColor != manualColor ||
      !listEquals(oldDelegate.onnxRects, onnxRects) ||
      !listEquals(oldDelegate.manualRects, manualRects);
}
