import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';

/// Manual bubble drawing mode (spec 9.5): pan-drag → red rectangle.
/// ONNX-detected bubbles shown in BLUE as reference; manual bubbles in RED.
/// Controls: Undo / Clear / Done.
///
/// Repaint is driven by local [setState] — the cubit state is Equatable and
/// emitting identical states is skipped by the bloc, so painter refreshes
/// must not rely on state changes.
class ReaderTranslationDrawMode extends StatefulWidget {
  const ReaderTranslationDrawMode({super.key});

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
            // Drag layer — interactive only in draw mode; otherwise just
            // renders the reference bubbles (locked, non-interactive).
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
                      dragging: _dragging,
                      onnxRects: _onnxRects,
                      manualRects: _manualRects = cubit.manualBubbles
                          .map((b) => Rect.fromLTWH(
                                b.x * scaleX,
                                b.y * scaleY + topOffset,
                                b.w * scaleX,
                                b.h * scaleY,
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            // Controls — draw mode only
            if (drawMode)
              Positioned(
                bottom: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ChipButton(
                        label: '🛰 Detect',
                        onTap: () async {
                          await cubit.detectBubblesOnly();
                          _repaint();
                        },
                      ),
                      const SizedBox(width: 8),
                      _ChipButton(
                        label: 'Undo',
                        onTap: () {
                          cubit.undoLastManual();
                          _repaint();
                        },
                      ),
                      const SizedBox(width: 8),
                      _ChipButton(
                        label: 'Clear',
                        onTap: () {
                          cubit.clearManualBubbles();
                          _repaint();
                        },
                      ),
                      const SizedBox(width: 8),
                      _ChipButton(
                        label: 'Done ✓',
                        onTap: () => cubit.setDrawMode(false),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: const TextStyle(color: Colors.white)),
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
  });

  final Rect? dragging;
  final List<Rect> onnxRects; // ONNX-detected (blue reference)
  final List<Rect> manualRects; // user-drawn (red)

  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.blueAccent;
    for (final r in onnxRects) {
      canvas.drawRect(r, bluePaint);
    }

    final redPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.red;
    for (final r in manualRects) {
      canvas.drawRect(r, redPaint);
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
      !listEquals(oldDelegate.onnxRects, onnxRects) ||
      !listEquals(oldDelegate.manualRects, manualRects);
}
