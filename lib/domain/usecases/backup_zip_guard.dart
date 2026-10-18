import 'dart:typed_data';

/// Pre-decode ZIP central-directory scan.
///
/// `ZipDecoder().decodeBytes` inflates everything into memory, so a small
/// zip bomb (KBs compressed → GBs inflated) would OOM before any post-decode
/// guard runs. This walks only the central-directory headers (no inflation)
/// and returns entry count + declared uncompressed total so callers can reject
/// early. Returns null when the directory is unreadable — caller then falls
/// back to decode + post-decode checks (never silently skip guards).
({int entries, int uncompressedTotal})? scanZipCentralDirectory(
    Uint8List bytes) {
  const eocdSig = 0x06054b50;
  const centralSig = 0x02014b50;
  if (bytes.length < 22) return null;
  final data = ByteData.sublistView(bytes);
  // EOCD lives in the last 22 + 64KiB (max comment length) bytes.
  final start = bytes.length - 22;
  final end = (bytes.length - 22 - 65536).clamp(0, start);
  var eocd = -1;
  for (var i = start; i >= end; i--) {
    if (data.getUint32(i, Endian.little) == eocdSig) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) return null;
  final totalEntries = data.getUint16(eocd + 10, Endian.little);
  var centralOffset = data.getUint32(eocd + 16, Endian.little);
  if (centralOffset >= bytes.length) return null;
  var entries = 0;
  var uncompressedTotal = 0;
  for (var n = 0; n < totalEntries; n++) {
    if (centralOffset + 46 > bytes.length) return null;
    if (data.getUint32(centralOffset, Endian.little) != centralSig) return null;
    final uncompressedSize = data.getUint32(centralOffset + 24, Endian.little);
    // Zip64 sentinel — sizes live in extra fields; don't guess, let the
    // post-decode check handle it (entry count guard below still applies).
    if (uncompressedSize != 0xFFFFFFFF) {
      uncompressedTotal += uncompressedSize;
    }
    final nameLen = data.getUint16(centralOffset + 28, Endian.little);
    final extraLen = data.getUint16(centralOffset + 30, Endian.little);
    final commentLen = data.getUint16(centralOffset + 32, Endian.little);
    centralOffset += 46 + nameLen + extraLen + commentLen;
    entries++;
  }
  return (entries: entries, uncompressedTotal: uncompressedTotal);
}

/// Throws [FormatException] when the central directory already proves the
/// archive exceeds [maxEntries] entries or [maxUncompressed] declared bytes.
/// No-op when the directory is unreadable — post-decode checks remain as
/// second net. Call BEFORE `ZipDecoder().decodeBytes`.
void throwIfZipBomb(Uint8List bytes,
    {required int maxEntries, required int maxUncompressed}) {
  final scan = scanZipCentralDirectory(bytes);
  if (scan == null) return;
  if (scan.entries > maxEntries) {
    throw FormatException(
        'Archive contains too many entries (exceeds limit of $maxEntries)');
  }
  if (scan.uncompressedTotal > maxUncompressed) {
    throw const FormatException('Archive declares uncompressed contents '
        'exceeding maximum allowed size (central directory pre-scan)');
  }
}
