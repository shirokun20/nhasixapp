import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:kuron_native/kuron_native.dart';

/// Compresses a full page image to max 1280px longest side, JPEG 85%,
/// for the no-bubble fallback path. Providers map percentage coordinates
/// back to original pixel space using the ORIGINAL page dimensions.
/// Rust FFI (`image_ops_compress_page`) when available, else pure Dart.
class FallbackImageHandler {
  FallbackImageHandler();

  static const int maxDimension = 1280;

  Uint8List compressPage(Uint8List image) {
    final bridge = RustBridge.instance;
    if (bridge != null && bridge.imageOpsAvailable) {
      try {
        final native = bridge.imageOpsCompressPage(image);
        if (native != null) return native;
      } catch (_) {
        // fall through to Dart
      }
    }
    final decoded = img.decodeImage(image);
    if (decoded == null) return image;

    img.Image scaled = decoded;
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest > maxDimension) {
      final ratio = maxDimension / longest;
      scaled = img.copyResize(
        decoded,
        width: (decoded.width * ratio).round(),
        height: (decoded.height * ratio).round(),
        interpolation: img.Interpolation.linear,
      );
    }
    return img.encodeJpg(scaled, quality: 85);
  }
}
