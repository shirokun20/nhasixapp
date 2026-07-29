import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

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

  static RustBridge? _load() {
    final DynamicLibrary lib;
    try {
      if (Platform.isAndroid) {
        lib = DynamicLibrary.open('libkuron_rust.so');
        debugPrint('[RustBridge] libkuron_rust.so loaded on Android');
      } else if (Platform.isIOS) {
        lib = DynamicLibrary.process();
        debugPrint('[RustBridge] using DynamicLibrary.process() on iOS');
      } else {
        debugPrint(
            '[RustBridge] unsupported platform: ${Platform.operatingSystem}');
        return null;
      }
    } catch (e) {
      debugPrint('[RustBridge] FAILED to load native library: $e');
      return null;
    }

    try {
      final bridge = RustBridge._(lib);
      bridge._lookupFunctions();
      debugPrint('[RustBridge] all function symbols resolved OK');
      return bridge;
    } catch (e) {
      debugPrint('[RustBridge] symbol lookup FAILED: $e');
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
  }

  // ── Public API ───────────────────────────────────────────

  /// Decrypt HentaiNexus content. Returns UTF-8 string, or null.
  String? hentaiNexusDecrypt(Uint8List encrypted, String hostname) {
    debugPrint('[RustBridge] hentaiNexusDecrypt(${encrypted.length} bytes)');
    final dataPtr = malloc<Uint8>(encrypted.length);
    dataPtr.asTypedList(encrypted.length).setAll(0, encrypted);

    final hostnamePtr = hostname.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _nexusDecrypt(dataPtr, encrypted.length, hostnamePtr, outLen);
    malloc.free(hostnamePtr);
    malloc.free(dataPtr);

    if (ptr == nullptr) {
      debugPrint('[RustBridge] hentaiNexusDecrypt: Rust returned null');
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = String.fromCharCodes(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    debugPrint('[RustBridge] hentaiNexusDecrypt: $len chars decrypted');
    return result;
  }

  /// Unpack ViHentai packed-JS script. Returns decoded string, or null.
  String? vihentaiUnpack(String script) {
    debugPrint('[RustBridge] vihentaiUnpack(${script.length} chars)');
    final scriptPtr = script.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _vihentaiUnpack(scriptPtr, outLen);
    malloc.free(scriptPtr);

    if (ptr == nullptr) {
      debugPrint('[RustBridge] vihentaiUnpack: Rust returned null');
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = String.fromCharCodes(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    debugPrint('[RustBridge] vihentaiUnpack: $len chars decoded');
    return result;
  }

  /// Process single image: decode → resize → encode JPEG. Returns JPEG bytes, or null.
  Uint8List? imageProcessSingle(String path,
      {int maxWidth = 1200, int quality = 90}) {
    debugPrint(
        '[RustBridge] imageProcessSingle($path, w=$maxWidth, q=$quality)');
    final pathPtr = path.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr = _imageProcessSingle(pathPtr, maxWidth, quality, outLen);
    malloc.free(pathPtr);

    if (ptr == nullptr) {
      debugPrint('[RustBridge] imageProcessSingle: Rust returned null');
      malloc.free(outLen);
      return null;
    }

    final len = outLen.value;
    final result = Uint8List.fromList(ptr.asTypedList(len));
    _freeBuffer(ptr, len);
    malloc.free(outLen);
    debugPrint('[RustBridge] imageProcessSingle: $len bytes JPEG');
    return result;
  }

  /// Split webtoon image. Returns list of JPEG byte chunks, or null.
  List<Uint8List>? imageSplit(
    String path, {
    int maxWidth = 1200,
    int maxHeightPerChunk = 3000,
    int quality = 90,
  }) {
    debugPrint(
        '[RustBridge] imageSplit($path, w=$maxWidth, chunk=$maxHeightPerChunk, q=$quality)');
    final pathPtr = path.toNativeUtf8();
    final outLen = malloc<Uint32>();

    final ptr =
        _imageSplit(pathPtr, maxWidth, maxHeightPerChunk, quality, outLen);
    malloc.free(pathPtr);

    if (ptr == nullptr) {
      debugPrint('[RustBridge] imageSplit: Rust returned null');
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
    debugPrint('[RustBridge] imageSplit: $count chunks, $totalLen total bytes');
    return chunks;
  }

  static int _readLeUint32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }
}
