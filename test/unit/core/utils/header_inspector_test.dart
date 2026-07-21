import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/header_inspector.dart';

/// Minimal RIFF+WEBP+VP8X header for animated WebP.
/// 1x1 VP8X frame with animation flag.
final _minimalAnimatedWebP = _buildMinimalAnimatedWebP();

Uint8List _buildMinimalAnimatedWebP() {
  // RIFF header
  final riff = Uint8List.fromList([0x52, 0x49, 0x46, 0x46]); // "RIFF"
  final webp = Uint8List.fromList([0x57, 0x45, 0x42, 0x50]); // "WEBP"
  // VP8X chunk — animation flag (bit 1) set
  final vp8xFlags =
      Uint8List.fromList([0x02, 0x00, 0x00, 0x00]); // flags + reserved
  // 24-bit width-1 = 0 → width=1
  // 24-bit height-1 = 0 → height=1
  final width24 = [0x00, 0x00, 0x00];
  final height24 = [0x00, 0x00, 0x00];

  final vp8xContent = Uint8List.fromList([
    ...vp8xFlags,
    ...width24,
    ...height24,
  ]);

  final chunkLen = vp8xContent.length;
  final chunkHdr = Uint8List.fromList([
    // VP8X fourCC
    0x56, 0x50, 0x38, 0x58,
    // chunk size (little-endian)
    chunkLen & 0xFF,
    (chunkLen >> 8) & 0xFF,
    (chunkLen >> 16) & 0xFF,
    (chunkLen >> 24) & 0xFF,
  ]);

  final result = Uint8List(12 + 8 + chunkLen);
  result.setRange(0, 4, riff);
  // file size = total - 8
  final total = result.length;
  result[4] = (total - 8) & 0xFF;
  result[5] = ((total - 8) >> 8) & 0xFF;
  result[6] = ((total - 8) >> 16) & 0xFF;
  result[7] = ((total - 8) >> 24) & 0xFF;
  result.setRange(8, 12, webp);
  result.setRange(12, 20, chunkHdr);
  result.setRange(20, 20 + chunkLen, vp8xContent);
  return result;
}

/// Minimal static JPEG (SOI + APP0 + SOS)
final _minimalJpeg = Uint8List.fromList([
  0xFF, 0xD8, // SOI
  0xFF, 0xE0, // APP0 marker
  0x00, 0x10, // APP0 length
  0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
  0x01, 0x01, // version
  0x00, // units
  0x00, 0x01, 0x00, 0x01, // x/y density
  0x00, 0x00, // thumbnail
  0xFF, 0xD9, // EOI
]);

/// Minimal PNG header
final _minimalPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, // PNG signature
  0x0D, 0x0A, 0x1A, 0x0A, // CR+LF+EOF+LF
  0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
  0x49, 0x48, 0x44, 0x52, // "IHDR"
  0x00, 0x00, 0x00, 0x01, // width=1
  0x00, 0x00, 0x00, 0x01, // height=1
  0x08, // bit depth
  0x02, // color type (RGB)
  0x00, // compression
  0x00, // filter
  0x00, // interlace
  0x00, 0x00, 0x00, 0x00, // CRC
]);

/// Minimal static WebP (lossy, VP8 key frame) — NOT animated.
final _minimalStaticWebP = Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, // RIFF
  0x2E, 0x00, 0x00, 0x00, // file size (46)
  0x57, 0x45, 0x42, 0x50, // WEBP
  // VP8  chunk (lossy)
  0x56, 0x50, 0x38, 0x20, // "VP8 "
  0x1E, 0x00, 0x00, 0x00, // chunk size
  // VP8 frame header (incomplete but parser only checks top bytes)
  0x9D, 0x01, 0x2A, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('header_inspector_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('inspectFileHeader', () {
    test('returns empty for non-existent file', () {
      final result = inspectFileHeader('/nonexistent/path.webp');
      expect(result.format, isNull);
      expect(result.width, isNull);
      expect(result.height, isNull);
    });

    test('returns empty for file < 16 bytes', () {
      final f = File('${tempDir.path}/small.bin')
        ..writeAsBytesSync([0x00, 0x01]);
      final result = inspectFileHeader(f.path);
      expect(result.format, isNull);
    });

    test('detects animated WebP from VP8X', () {
      final f = File('${tempDir.path}/animated.webp')
        ..writeAsBytesSync(_minimalAnimatedWebP);
      final result = inspectFileHeader(f.path);
      expect(result.format, 'webp');
      expect(result.width, 1);
      expect(result.height, 1);
    });

    test('returns format:null for static WebP (no ANIM/VP8X flag)', () {
      final f = File('${tempDir.path}/static.webp')
        ..writeAsBytesSync(_minimalStaticWebP);
      final result = inspectFileHeader(f.path);
      // static WebP: parser asks for VP8X animation flag — VP8 chunk has none
      expect(result.format, isNull);
    });

    test('returns empty for JPEG (not webp/avif)', () {
      final f = File('${tempDir.path}/test.jpg')
        ..writeAsBytesSync(_minimalJpeg);
      final result = inspectFileHeader(f.path);
      expect(result.format, isNull);
    });

    test('returns empty for PNG', () {
      final f = File('${tempDir.path}/test.png')..writeAsBytesSync(_minimalPng);
      final result = inspectFileHeader(f.path);
      expect(result.format, isNull);
    });

    test('handles empty file gracefully', () {
      final f = File('${tempDir.path}/empty.bin')..writeAsBytesSync([]);
      final result = inspectFileHeader(f.path);
      expect(result.format, isNull);
    });
  });

  group('batchInspectHeaders', () {
    test('returns empty list for empty input', () {
      expect(batchInspectHeaders([]), isEmpty);
    });

    test('inspects multiple files', () {
      final paths = <String>[];
      for (int i = 0; i < 5; i++) {
        final f = File('${tempDir.path}/batch_$i.webp')
          ..writeAsBytesSync(_minimalAnimatedWebP);
        paths.add(f.path);
      }
      final results = batchInspectHeaders(paths);
      expect(results.length, 5);
      for (final r in results) {
        expect(r.format, 'webp');
      }
    });

    test('mixed animated/non-animated files', () {
      final animated = File('${tempDir.path}/mix_anim.webp')
        ..writeAsBytesSync(_minimalAnimatedWebP);
      final static = File('${tempDir.path}/mix_static.webp')
        ..writeAsBytesSync(_minimalStaticWebP);
      final jpg = File('${tempDir.path}/mix.jpg')
        ..writeAsBytesSync(_minimalJpeg);

      final results = batchInspectHeaders([
        animated.path,
        static.path,
        jpg.path,
      ]);
      expect(results[0].format, 'webp'); // animated
      expect(results[1].format, isNull); // static
      expect(results[2].format, isNull); // jpeg
    });
  });

  group('helper functions', () {
    test('looksLikeAnimatedWebPHeader detects VP8X+ANIM', () {
      expect(looksLikeAnimatedWebPHeader(_minimalAnimatedWebP), true);
      expect(looksLikeAnimatedWebPHeader(_minimalStaticWebP), false);
      expect(looksLikeAnimatedWebPHeader(_minimalJpeg), false);
    });

    test('matchesBytes matches at offset', () {
      final bytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      expect(matchesBytes(bytes, 0, [0x00, 0x01]), true);
      expect(matchesBytes(bytes, 2, [0x02, 0x03]), true);
      expect(matchesBytes(bytes, 0, [0x00, 0x99]), false);
    });

    test('matchesBytes returns false past buffer', () {
      final bytes = Uint8List.fromList([0x00]);
      expect(matchesBytes(bytes, 0, [0x00, 0x01]), false);
    });

    test('containsBytes finds needle', () {
      final bytes = Uint8List.fromList([0x41, 0x4E, 0x49, 0x4D]); // "ANIM"
      expect(containsBytes(bytes, [0x41, 0x4E]), true);
      expect(containsBytes(bytes, [0x4E, 0x49]), true);
      expect(containsBytes(bytes, [0x58, 0x58]), false);
    });
  });

  group('compute() batch integration', () {
    test('batchInspectHeaders via compute returns correct count', () async {
      final paths = <String>[];
      for (int i = 0; i < 12; i++) {
        final f = File('${tempDir.path}/compute_batch_$i.webp')
          ..writeAsBytesSync(_minimalAnimatedWebP);
        paths.add(f.path);
      }
      final results = await compute(batchInspectHeaders, paths);
      expect(results.length, 12);
      for (final r in results) {
        expect(r.format, 'webp');
      }
    });

    test('compute with mixed formats works', () async {
      final anim = File('${tempDir.path}/compute_anim.webp')
        ..writeAsBytesSync(_minimalAnimatedWebP);
      final jpg = File('${tempDir.path}/compute_test.jpg')
        ..writeAsBytesSync(_minimalJpeg);
      final results = await compute(batchInspectHeaders, [anim.path, jpg.path]);
      expect(results[0].format, 'webp');
      expect(results[1].format, isNull);
    });
  });
}
