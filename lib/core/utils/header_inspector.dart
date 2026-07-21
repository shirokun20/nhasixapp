import 'dart:io';
import 'dart:typed_data';

import 'reader_image_repair_utils.dart';

/// Result from a single file header inspection.
typedef FileHeaderResult = ({
  String? format, // 'webp', 'avif', or null
  int? width,
  int? height,
});

/// Inspect a single file's header for animated WebP/AVIF routing.
///
/// Reads up to 4KB of the file header to determine format and dimensions.
/// Designed to be `compute()`-eligible — top-level function, no closures.
FileHeaderResult inspectFileHeader(String path) {
  const empty = (format: null, width: null, height: null) as FileHeaderResult;
  const int maxNativeAvifHeight = 4096;

  File file;
  RandomAccessFile? raf;
  try {
    file = File(path);
    if (!file.existsSync()) return empty;
    raf = file.openSync(mode: FileMode.read);
    final length = raf.lengthSync();
    if (length < 16) return empty;

    final sampleLength = length < 4096 ? length : 4096;
    final bytes = raf.readSync(sampleLength);
    final ext = inferImageExtension(bytes: bytes);
    if (ext == 'webp') {
      if (!looksLikeAnimatedWebPHeader(bytes)) return empty;
      int? width;
      int? height;
      int offset = 12;
      while (offset + 8 <= bytes.length) {
        final chunkType =
            String.fromCharCodes(bytes.sublist(offset, offset + 4));
        final chunkSize = bytes[offset + 4] |
            (bytes[offset + 5] << 8) |
            (bytes[offset + 6] << 16) |
            (bytes[offset + 7] << 24);

        if (chunkType == 'VP8X' &&
            chunkSize >= 10 &&
            offset + 18 <= bytes.length) {
          width = 1 +
              (bytes[offset + 12] |
                  (bytes[offset + 13] << 8) |
                  (bytes[offset + 14] << 16));
          height = 1 +
              (bytes[offset + 15] |
                  (bytes[offset + 16] << 8) |
                  (bytes[offset + 17] << 16));
          break;
        }
        offset += 8 + chunkSize;
        if (chunkSize % 2 != 0) offset++;
      }
      return (format: 'webp', width: width, height: height);
    }

    if (ext == 'avif') {
      if (bytes.length < 12) return empty;
      const kAvis0 = 0x61; const kAvis1 = 0x76;
      const kAvis2 = 0x69; const kAvis3 = 0x73;
      if (bytes[8] != kAvis0 || bytes[9] != kAvis1 ||
          bytes[10] != kAvis2 || bytes[11] != kAvis3) {
        return empty;
      }
      const kIspe = <int>[0x69, 0x73, 0x70, 0x65];
      for (int i = 0; i <= bytes.length - 16; i++) {
        if (matchesBytes(bytes, i, kIspe)) {
          final w = ((bytes[i + 8] & 0xFF) << 24) |
              ((bytes[i + 9] & 0xFF) << 16) |
              ((bytes[i + 10] & 0xFF) << 8) |
              (bytes[i + 11] & 0xFF);
          final h = ((bytes[i + 12] & 0xFF) << 24) |
              ((bytes[i + 13] & 0xFF) << 16) |
              ((bytes[i + 14] & 0xFF) << 8) |
              (bytes[i + 15] & 0xFF);
          if (h > maxNativeAvifHeight) return empty;
          return (format: 'avif', width: w > 0 ? w : null, height: h > 0 ? h : null);
        }
      }
      return empty;
    }
    return empty;
  } catch (_) {
    return empty;
  } finally {
    raf?.closeSync();
  }
}

/// Batch inspect file headers via [compute] or sync loop.
/// Used when >10 files need inspection.
List<FileHeaderResult> batchInspectHeaders(List<String> paths) {
  return [for (final p in paths) inspectFileHeader(p)];
}

// ─── Static helpers (duplicated from extended_image_reader_widget.dart for
//      compute()-eligibility — top-level functions cannot reference class members) ───

bool looksLikeAnimatedWebPHeader(Uint8List bytes) {
  const riff = <int>[0x52, 0x49, 0x46, 0x46];
  const webp = <int>[0x57, 0x45, 0x42, 0x50];
  const vp8x = <int>[0x56, 0x50, 0x38, 0x58];
  const anim = <int>[0x41, 0x4E, 0x49, 0x4D];

  if (!matchesBytes(bytes, 0, riff) || !matchesBytes(bytes, 8, webp)) {
    return false;
  }
  if (matchesBytes(bytes, 12, vp8x) &&
      bytes.length > 20 &&
      (bytes[20] & 0x02) != 0) {
    return true;
  }
  return containsBytes(bytes, anim);
}

bool matchesBytes(Uint8List bytes, int offset, List<int> expected) {
  if (bytes.length < offset + expected.length) return false;
  for (var i = 0; i < expected.length; i++) {
    if (bytes[offset + i] != expected[i]) return false;
  }
  return true;
}

bool containsBytes(Uint8List bytes, List<int> needle) {
  if (bytes.length < needle.length) return false;
  for (int start = 0; start <= bytes.length - needle.length; start++) {
    if (matchesBytes(bytes, start, needle)) return true;
  }
  return false;
}
