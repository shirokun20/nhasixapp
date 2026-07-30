import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// ── Native function C signatures ───────────────────────────

typedef _FreeRustBufferC = Void Function(Pointer<Uint8> ptr, Uint32 len);
typedef _FreeRustBufferDart = void Function(Pointer<Uint8> ptr, int len);

typedef _NexusDecryptC = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Utf8> hostname,
  Pointer<Uint32> outLen,
);
typedef _NexusDecryptDart = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Utf8> hostname,
  Pointer<Uint32> outLen,
);

typedef _VihentaiUnpackC = Pointer<Uint8> Function(
  Pointer<Utf8> script,
  Pointer<Uint32> outLen,
);
typedef _VihentaiUnpackDart = Pointer<Uint8> Function(
  Pointer<Utf8> script,
  Pointer<Uint32> outLen,
);

typedef _ImageProcessSingleC = Pointer<Uint8> Function(
  Pointer<Utf8> path,
  Uint32 maxWidth,
  Uint32 quality,
  Pointer<Uint32> outLen,
);
typedef _ImageProcessSingleDart = Pointer<Uint8> Function(
  Pointer<Utf8> path,
  int maxWidth,
  int quality,
  Pointer<Uint32> outLen,
);

typedef _ImageSplitC = Pointer<Uint8> Function(
  Pointer<Utf8> path,
  Uint32 maxWidth,
  Uint32 maxHeightPerChunk,
  Uint32 quality,
  Pointer<Uint32> outLen,
);
typedef _ImageSplitDart = Pointer<Uint8> Function(
  Pointer<Utf8> path,
  int maxWidth,
  int maxHeightPerChunk,
  int quality,
  Pointer<Uint32> outLen,
);

// ── New: Hitomi FFI signatures ─────────────────────────────

typedef _HitomiDecodeGalleryIdsC = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Uint32> outLen,
);
typedef _HitomiDecodeGalleryIdsDart = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Uint32> outLen,
);

typedef _HitomiDecodeNodeC = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Uint8> key,
  Uint32 keyLen,
  Pointer<Uint32> outLen,
);
typedef _HitomiDecodeNodeDart = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Uint8> key,
  int keyLen,
  Pointer<Uint32> outLen,
);

typedef _HitomiBsetSearchC = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Uint32 target,
  Pointer<Uint32> outLen,
);
typedef _HitomiBsetSearchDart = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  int dataLen,
  int target,
  Pointer<Uint32> outLen,
);

typedef _HitomiDecodeNozomiIdsC = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Uint32> outLen,
);
typedef _HitomiDecodeNozomiIdsDart = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Uint32> outLen,
);

// ── New: EHentai FFI signatures ────────────────────────────

typedef _EhentaiExtractUrlsC = Pointer<Uint8> Function(
  Pointer<Utf8> html,
  Pointer<Uint32> outLen,
);
typedef _EhentaiExtractUrlsDart = Pointer<Uint8> Function(
  Pointer<Utf8> html,
  Pointer<Uint32> outLen,
);

typedef _EhentaiExtractTagsC = Pointer<Uint8> Function(
  Pointer<Utf8> html,
  Pointer<Uint32> outLen,
);
typedef _EhentaiExtractTagsDart = Pointer<Uint8> Function(
  Pointer<Utf8> html,
  Pointer<Uint32> outLen,
);

// ── New: Header inspector FFI signatures ───────────────────

typedef _HeaderInspectC = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Uint32> outLen,
);
typedef _HeaderInspectDart = Pointer<Uint8> Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Uint32> outLen,
);

typedef _HeaderInspectBatchC = Pointer<Uint8> Function(
  Pointer<Pointer<Utf8>> paths,
  Uint32 count,
  Pointer<Uint32> outLen,
);
typedef _HeaderInspectBatchDart = Pointer<Uint8> Function(
  Pointer<Pointer<Utf8>> paths,
  int count,
  Pointer<Uint32> outLen,
);

// ── Bridge singleton ───────────────────────────────────────

/// Bridge to native Rust library via dart:ffi.
///
/// All methods return `null` when the Rust library is unavailable
/// (graceful fallback for development, platforms without .so).
class RustBridge {
  RustBridge._(this._lib);

  static RustBridge? _instance;
  static bool _triedLoad = false;

  static RustBridge? get instance {
    if (!_triedLoad) {
      _instance = _load();
      _triedLoad = true;
    }
    return _instance;
  }

  static bool get isAvailable => instance != null;

  final DynamicLibrary _lib;
  late final _FreeRustBufferDart _freeBuffer;
  late final _NexusDecryptDart _nexusDecrypt;
  late final _VihentaiUnpackDart _vihentaiUnpack;
  late final _ImageProcessSingleDart _imageProcessSingle;
  late final _ImageSplitDart _imageSplit;

  // New lookups
  late final _HitomiDecodeGalleryIdsDart _hitomiDecodeGalleryIds;
  late final _HitomiDecodeNodeDart _hitomiDecodeNode;
  late final _HitomiBsetSearchDart _hitomiBsetSearch;
  late final _HitomiDecodeNozomiIdsDart _hitomiDecodeNozomiIds;
  late final _EhentaiExtractUrlsDart _ehentaiExtractUrls;
  late final _EhentaiExtractTagsDart _ehentaiExtractTags;
  late final _HeaderInspectDart _headerInspect;
  late final _HeaderInspectBatchDart _headerInspectBatch;

  static RustBridge? _load() {
    final DynamicLibrary lib;
    try {
      if (Platform.isAndroid) {
        lib = DynamicLibrary.open('libkuron_rust.so');
      } else if (Platform.isIOS) {
        lib = DynamicLibrary.process();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }

    try {
      final bridge = RustBridge._(lib);
      bridge._lookupFunctions();
      return bridge;
    } catch (e) {
      return null;
    }
  }

  void _lookupFunctions() {
    _freeBuffer = _lib.lookupFunction<_FreeRustBufferC, _FreeRustBufferDart>(
        'free_rust_buffer');
    _nexusDecrypt =
        _lib.lookupFunction<_NexusDecryptC, _NexusDecryptDart>('nexus_decrypt');
    _vihentaiUnpack =
        _lib.lookupFunction<_VihentaiUnpackC, _VihentaiUnpackDart>(
            'vihentai_unpack');
    _imageProcessSingle =
        _lib.lookupFunction<_ImageProcessSingleC, _ImageProcessSingleDart>(
            'image_process_single');
    _imageSplit =
        _lib.lookupFunction<_ImageSplitC, _ImageSplitDart>('image_split');

    // New lookups
    _hitomiDecodeGalleryIds = _lib.lookupFunction<
        _HitomiDecodeGalleryIdsC, _HitomiDecodeGalleryIdsDart>(
        'hitomi_decode_gallery_ids');
    _hitomiDecodeNode = _lib.lookupFunction<_HitomiDecodeNodeC,
        _HitomiDecodeNodeDart>('hitomi_decode_node');
    _hitomiBsetSearch = _lib.lookupFunction<_HitomiBsetSearchC,
        _HitomiBsetSearchDart>('hitomi_bset_search');
    _hitomiDecodeNozomiIds = _lib.lookupFunction<
        _HitomiDecodeNozomiIdsC, _HitomiDecodeNozomiIdsDart>(
        'hitomi_decode_nozomi_ids');
    _ehentaiExtractUrls = _lib.lookupFunction<_EhentaiExtractUrlsC,
        _EhentaiExtractUrlsDart>('ehentai_extract_urls');
    _ehentaiExtractTags = _lib.lookupFunction<_EhentaiExtractTagsC,
        _EhentaiExtractTagsDart>('ehentai_extract_tags');
    _headerInspect = _lib.lookupFunction<_HeaderInspectC, _HeaderInspectDart>(
        'header_inspect');
    _headerInspectBatch = _lib.lookupFunction<_HeaderInspectBatchC,
        _HeaderInspectBatchDart>('header_inspect_batch');
  }

  // ── Public API ───────────────────────────────────────────

  /// Decrypt HentaiNexus content. Returns UTF-8 string, or null.
  String? hentaiNexusDecrypt(Uint8List encrypted, String hostname) {
    final dataPtr = malloc<Uint8>(encrypted.length);
    dataPtr.asTypedList(encrypted.length).setAll(0, encrypted);

    final hostnamePtr = hostname.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _nexusDecrypt(dataPtr, encrypted.length, hostnamePtr, outLen);
    malloc.free(hostnamePtr);
    malloc.free(dataPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = String.fromCharCodes(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    return result;
  }

  /// Unpack ViHentai packed-JS script. Returns decoded string, or null.
  String? vihentaiUnpack(String script) {
    final scriptPtr = script.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _vihentaiUnpack(scriptPtr, outLen);
    malloc.free(scriptPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = String.fromCharCodes(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    return result;
  }

  /// Process single image: decode → resize → encode JPEG. Returns JPEG bytes, or null.
  Uint8List? imageProcessSingle(String path,
      {int maxWidth = 1200, int quality = 90}) {
    final pathPtr = path.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _imageProcessSingle(pathPtr, maxWidth, quality, outLen);
    malloc.free(pathPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = Uint8List.fromList(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    return result;
  }

  /// Split webtoon image. Returns list of JPEG byte chunks, or null.
  List<Uint8List>? imageSplit(
    String path, {
    int maxWidth = 1200,
    int maxHeightPerChunk = 3000,
    int quality = 90,
  }) {
    final pathPtr = path.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr =
        _imageSplit(pathPtr, maxWidth, maxHeightPerChunk, quality, outLen);
    malloc.free(pathPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final totalLen = outLen.value;
    final allBytes = ptr.asTypedList(totalLen);

    // Parse flat buffer: [count:u32][len0:u32][data0]...[lenN:u32][dataN]
    final count = _readLeUint32(allBytes, 0);
    final chunks = <Uint8List>[];
    var offset = 4;

    for (var i = 0; i < count; i++) {
      final chunkLen = _readLeUint32(allBytes, offset);
      offset += 4;
      chunks.add(allBytes.sublist(offset, offset + chunkLen));
      offset += chunkLen;
    }

    _freeBuffer(ptr, totalLen);
    malloc.free(outLen);
    return chunks;
  }

  // ── New: Hitomi methods ──────────────────────────────────

  /// Decode gallery IDs from Hitomi binary data.
  /// Returns list of gallery IDs, or null on error.
  List<int>? hitomiDecodeGalleryIds(Uint8List data) {
    final dataPtr = malloc<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    final outLen = malloc<Uint32>();

    final ptr = _hitomiDecodeGalleryIds(dataPtr, data.length, outLen);
    malloc.free(dataPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final totalLen = outLen.value;
    final allBytes = ptr.asTypedList(totalLen);
    final count = _readLeUint32(allBytes, 0);
    final ids = <int>[];
    for (var i = 0; i < count; i++) {
      ids.add(_readLeInt32(allBytes, 4 + i * 4));
    }
    _freeBuffer(ptr, totalLen);
    malloc.free(outLen);
    return ids;
  }

  /// Decode a Hitomi binary node with a key. Returns 21-byte search result, or null.
  Uint8List? hitomiDecodeNode(Uint8List data, List<int> key) {
    final dataPtr = malloc<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    final keyPtr = malloc<Uint8>(key.length);
    keyPtr.asTypedList(key.length).setAll(0, key);
    final outLen = malloc<Uint32>();

    final ptr = _hitomiDecodeNode(dataPtr, data.length, keyPtr, key.length, outLen);
    malloc.free(dataPtr);
    malloc.free(keyPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = Uint8List.fromList(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    return result;
  }

  /// B-tree search in Hitomi binary index. Returns 21-byte search result, or null.
  Uint8List? hitomiBsetSearch(Uint8List data, int target) {
    final dataPtr = malloc<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    final outLen = malloc<Uint32>();

    final ptr = _hitomiBsetSearch(dataPtr, data.length, target, outLen);
    malloc.free(dataPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = Uint8List.fromList(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    return result;
  }

  /// Decode nozomi IDs from binary data. Returns list of IDs, or null.
  List<int>? hitomiDecodeNozomiIds(Uint8List data) {
    final dataPtr = malloc<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    final outLen = malloc<Uint32>();

    final ptr = _hitomiDecodeNozomiIds(dataPtr, data.length, outLen);
    malloc.free(dataPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final totalLen = outLen.value;
    final allBytes = ptr.asTypedList(totalLen);
    final count = _readLeUint32(allBytes, 0);
    final ids = <int>[];
    for (var i = 0; i < count; i++) {
      ids.add(_readLeInt32(allBytes, 4 + i * 4));
    }
    _freeBuffer(ptr, totalLen);
    malloc.free(outLen);
    return ids;
  }

  // ── New: EHentai methods ─────────────────────────────────

  /// Extract reader URLs from EHentai HTML. Returns list of URLs, or null.
  List<String>? ehentaiExtractUrls(String html) {
    final htmlPtr = html.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _ehentaiExtractUrls(htmlPtr, outLen);
    malloc.free(htmlPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = String.fromCharCodes(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);

    if (result.isEmpty) return const <String>[];
    return result.split('\n');
  }

  /// Extract tags from EHentai HTML. Returns list of tag strings, or null.
  List<String>? ehentaiExtractTags(String html) {
    final htmlPtr = html.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _ehentaiExtractTags(htmlPtr, outLen);
    malloc.free(htmlPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final utf8Json = ptr.asTypedList(len);
    final text = String.fromCharCodes(utf8Json);
    _freeBuffer(ptr, len);
    malloc.free(outLen);

    // Parse JSON array of strings
    if (text.length < 2) return const <String>[];
    final inner = text.substring(1, text.length - 1); // strip [ ]
    if (inner.isEmpty) return const <String>[];

    // Simple JSON array parser for strings
    final tags = <String>[];
    var i = 0;
    while (i < inner.length) {
      if (inner[i] == '"') {
        final sb = StringBuffer();
        i++;
        while (i < inner.length) {
          if (inner[i] == '\\') {
            i++;
            if (i < inner.length) {
              sb.write(inner[i]);
              i++;
            }
          } else if (inner[i] == '"') {
            break;
          } else {
            sb.write(inner[i]);
            i++;
          }
        }
        tags.add(sb.toString());
      }
      i++;
    }
    return tags;
  }

  // ── New: Header inspector methods ────────────────────────

  /// Inspect file header from raw bytes. Returns parsed JSON map, or null.
  Map<String, dynamic>? headerInspect(Uint8List data) {
    final dataPtr = malloc<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    final outLen = malloc<Uint32>();

    final ptr = _headerInspect(dataPtr, data.length, outLen);
    malloc.free(dataPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final json = String.fromCharCodes(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);

    try {
      return _parseHeaderJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Batch inspect file headers from file paths. Returns list of results, or null.
  List<Map<String, dynamic>>? headerInspectBatch(List<String> paths) {
    final outLen = malloc<Uint32>();
    final ptrs = paths.map((p) => p.toNativeUtf8()).toList();
    final pathsPtr = malloc<Pointer<Utf8>>(paths.length);
    for (var i = 0; i < paths.length; i++) {
      pathsPtr[i] = ptrs[i];
    }

    final ptr = _headerInspectBatch(pathsPtr, paths.length, outLen);
    for (final p in ptrs) {
      malloc.free(p);
    }
    malloc.free(pathsPtr);

    if (ptr == nullptr) {
      malloc.free(outLen);
      return null;
    }

    final totalLen = outLen.value;
    final json = String.fromCharCodes(ptr.asTypedList(totalLen));
    _freeBuffer(ptr, totalLen);
    malloc.free(outLen);

    try {
      return _parseHeaderArrayJson(json);
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  static int _readLeUint32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  static int _readLeInt32(Uint8List bytes, int offset) {
    final val = _readLeUint32(bytes, offset);
    return val >= 0x80000000 ? val - 0x100000000 : val;
  }

  static Map<String, dynamic> _parseHeaderJson(String json) {
    final result = <String, dynamic>{};
    // Minimal JSON object parser for {"format":...,"width":...,"height":...}
    for (final key in ['format', 'width', 'height']) {
      final idx = json.indexOf('"$key"');
      if (idx < 0) continue;
      final colon = json.indexOf(':', idx + key.length + 2);
      if (colon < 0) continue;
      var start = colon + 1;
      while (start < json.length && json[start] == ' ') {
        start++;
      }
      if (start >= json.length) continue;
      if (json[start] == '"') {
        // String value
        var end = start + 1;
        while (end < json.length && json[end] != '"') {
          if (json[end] == '\\') end++;
          end++;
        }
        result[key] = json.substring(start + 1, end);
      } else if (json[start] == 'n') {
        result[key] = null;
      } else {
        // Number value
        var end = start;
        while (end < json.length && ((json.codeUnitAt(end) >= 0x30 && json.codeUnitAt(end) <= 0x39) || json[end] == '-')) {
          end++;
        }
        result[key] = int.tryParse(json.substring(start, end));
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> _parseHeaderArrayJson(String json) {
    final results = <Map<String, dynamic>>[];
    // Parse JSON array of objects: [{...},{...}]
    var i = 1; // skip [
    while (i < json.length - 1) {
      if (json[i] == '{') {
        var depth = 0;
        var start = i;
        while (i < json.length) {
          if (json[i] == '{') depth++;
          if (json[i] == '}') {
            depth--;
            if (depth == 0) break;
          }
          i++;
        }
        results.add(_parseHeaderJson(json.substring(start, i + 1)));
      }
      i++;
    }
    return results;
  }
}
