import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:kuron_native/kuron_native.dart';

import '../../../domain/entities/ai_translation.dart';

/// Builds a vertical mosaic image of cropped speech bubbles with red numeric
/// labels, for AI vision translation. Rust FFI (`image_ops_build_mosaic`)
/// when available, else pure Dart. Output semantics identical; exact JPEG
/// bytes may differ.
class MosaicBuilder {
  MosaicBuilder();

  /// Crops each bubble (20% extra padding each side), scales 2×, stacks
  /// vertically with 10px gaps, and draws a red numeric label beside each
  /// chip. Returns JPEG 85% bytes, downscaled to stay under 2MB.
  Uint8List buildMosaic(
    Uint8List pageImage,
    List<BubbleBoxLike> bubbles,
  ) {
    final bridge = RustBridge.instance;
    if (bridge != null && bridge.imageOpsAvailable) {
      try {
        final native = bridge.imageOpsBuildMosaic(pageImage, [
          for (final b in bubbles) (x: b.x, y: b.y, w: b.w, h: b.h),
        ]);
        if (native != null) return native;
      } catch (_) {
        // fall through to Dart
      }
    }
    final decoded = img.decodeImage(pageImage);
    if (decoded == null || bubbles.isEmpty) {
      throw ArgumentError('Unable to decode page image or empty bubbles');
    }

    const gap = 10;
    const labelWidth = 56;
    const labelHeight = 40;

    final chips = <img.Image>[];
    for (final box in bubbles) {
      final padX = (box.w * 0.2).round();
      final padY = (box.h * 0.2).round();
      final cropX = (box.x - padX).clamp(0, decoded.width - 1);
      final cropY = (box.y - padY).clamp(0, decoded.height - 1);
      final cropW = (box.w + padX * 2).clamp(1, decoded.width - cropX);
      final cropH = (box.h + padY * 2).clamp(1, decoded.height - cropY);

      final crop = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );
      final scaled = img.copyResize(
        crop,
        width: crop.width * 2,
        height: crop.height * 2,
        interpolation: img.Interpolation.linear,
      );
      chips.add(scaled);
    }

    final totalWidth =
        chips.fold(0, (maxW, c) => c.width > maxW ? c.width : maxW);
    final totalHeight =
        chips.fold(0, (sum, c) => sum + c.height + gap) - gap + labelHeight;

    final mosaic = img.Image(
      width: totalWidth + labelWidth,
      height: totalHeight,
    );
    img.fill(mosaic, color: img.ColorRgb8(255, 255, 255));

    final red = img.ColorRgb8(255, 0, 0);
    var y = 0;
    for (var i = 0; i < chips.length; i++) {
      img.drawString(
        mosaic,
        '${i + 1}',
        font: img.arial48,
        x: 4,
        y: y + 4,
        color: red,
      );
      img.compositeImage(
        mosaic,
        chips[i],
        dstX: labelWidth,
        dstY: y + labelHeight ~/ 2,
      );
      y += chips[i].height + gap;
    }

    // JPEG 85, cap at 2MB (downscale proportionally if over)
    var jpeg = img.encodeJpg(mosaic, quality: 85);
    var width = mosaic.width;
    while (jpeg.length > 2 * 1024 * 1024 && width > 64) {
      width = (width * 0.75).round();
      jpeg = img.encodeJpg(img.copyResize(mosaic, width: width), quality: 85);
    }

    return jpeg;
  }
}
