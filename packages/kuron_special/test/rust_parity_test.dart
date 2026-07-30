import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/kuron_native.dart';

// ── Test vectors ────────────────────────────────────────────
//
// Each test validates Dart fallback output against known expected values.
// When RustBridge is available (Android/iOS device), also asserts
// Rust output == Dart output for byte-level parity.

void main() {
  final hasRust = RustBridge.instance != null;

  group('Hitomi decode_gallery_ids parity', () {
    test('empty input', () {
      final data = Uint8List(0);
      final dartIds = _dartDecodeGalleryIds(data);
      expect(dartIds, isEmpty);
      if (hasRust) {
        final rustIds = RustBridge.instance!.hitomiDecodeGalleryIds(data);
        expect(rustIds?.toSet(), dartIds);
      }
    });

    test('count zero', () {
      final data = Uint8List.fromList([0, 0, 0, 0]); // count=0 BE
      final dartIds = _dartDecodeGalleryIds(data);
      expect(dartIds, isEmpty);
      if (hasRust) {
        final rustIds = RustBridge.instance!.hitomiDecodeGalleryIds(data);
        expect(rustIds?.toSet(), dartIds);
      }
    });

    test('single id', () {
      final bytes = ByteData(8);
      bytes.setUint32(0, 1, Endian.big); // count=1
      bytes.setUint32(4, 123456, Endian.big); // id=123456
      final data = bytes.buffer.asUint8List();
      final dartIds = _dartDecodeGalleryIds(data);
      expect(dartIds, {123456});
      if (hasRust) {
        final rustIds = RustBridge.instance!.hitomiDecodeGalleryIds(data);
        expect(rustIds?.toSet(), dartIds);
      }
    });

    test('multiple ids', () {
      final bytes = ByteData(16);
      bytes.setUint32(0, 3, Endian.big); // count=3
      bytes.setUint32(4, 100, Endian.big);
      bytes.setUint32(8, 200, Endian.big);
      bytes.setUint32(12, 300, Endian.big);
      final data = bytes.buffer.asUint8List();
      final dartIds = _dartDecodeGalleryIds(data);
      expect(dartIds, {100, 200, 300});
      if (hasRust) {
        final rustIds = RustBridge.instance!.hitomiDecodeGalleryIds(data);
        expect(rustIds?.toSet(), dartIds);
      }
    });
  });

  group('Hitomi decode_nozomi_ids parity', () {
    test('empty input', () {
      final data = Uint8List(0);
      final dartIds = _dartDecodeNozomiIds(data);
      expect(dartIds, isEmpty);
      if (hasRust) {
        final rustIds = RustBridge.instance!.hitomiDecodeNozomiIds(data);
        expect(rustIds, dartIds);
      }
    });

    test('two ids', () {
      final bytes = ByteData(8);
      bytes.setUint32(0, 42, Endian.big);
      bytes.setUint32(4, 99, Endian.big);
      final data = bytes.buffer.asUint8List();
      final dartIds = _dartDecodeNozomiIds(data);
      expect(dartIds, [42, 99]);
      if (hasRust) {
        final rustIds = RustBridge.instance!.hitomiDecodeNozomiIds(data);
        expect(rustIds, dartIds);
      }
    });

    test('trailing partial (length not multiple of 4)', () {
      final bytes = ByteData(9);
      bytes.setUint32(0, 1, Endian.big);
      bytes.setUint32(4, 2, Endian.big);
      final data = bytes.buffer.asUint8List(); // 9 bytes, 1 trailing
      final dartIds = _dartDecodeNozomiIds(data);
      expect(dartIds, [1, 2]);
      if (hasRust) {
        final rustIds = RustBridge.instance!.hitomiDecodeNozomiIds(data);
        expect(rustIds, dartIds);
      }
    });
  });

  group('Hitomi decode_node binary parity', () {
    test('leaf not found', () {
      // Build a minimal node: 0 keys, 0 datas, 17 zero addresses = leaf
      final data = _buildHitomiNode([], [], List.filled(17, 0));
      // When Rust is available, hitomiDecodeNode returns 21-byte binary result
      if (hasRust) {
        final result = RustBridge.instance!.hitomiDecodeNode(data, [1, 2, 3, 4]);
        expect(result, isNotNull);
        expect(result!.length, 21);
        // tag == 0 means not_found_leaf
        expect(result[0], 0);
      }
    });

    test('found with data ref', () {
      final keyBytes = Uint8List.fromList([0x00, 0x00, 0x00, 0x05]);
      // 1 key (4 bytes), 1 data (offset=100, length=50), 17 zero addresses
      final data = _buildHitomiNode(
        [keyBytes],
        [(offset: 100, length: 50)],
        List.filled(17, 0),
      );
      if (hasRust) {
        final result = RustBridge.instance!.hitomiDecodeNode(data, keyBytes);
        expect(result, isNotNull);
        expect(result!.length, 21);
        expect(result[0], 1); // tag == found
        // offset at bytes 1-8 LE = 100
        final offset = _readU64LE(result, 1);
        expect(offset, 100);
        // length at bytes 9-12 LE = 50
        final length = _readU32LE(result, 9);
        expect(length, 50);
      }
    });

    test('recurse to sub node', () {
      final keyBytes = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]);
      final addresses = List<int>.filled(17, 0);
      addresses[0] = 0x1000; // sub_node_addresses[0]
      final data = _buildHitomiNode(
        [Uint8List.fromList([0x00, 0x00, 0x00, 0x01])],
        [],
        addresses,
      );
      if (hasRust) {
        final result = RustBridge.instance!.hitomiDecodeNode(data, keyBytes);
        expect(result, isNotNull);
        expect(result!.length, 21);
        expect(result[0], 2); // tag == recurse
        // next_address at bytes 1-8 LE = 0x1000
        final nextAddr = _readU64LE(result, 1);
        expect(nextAddr, 0x1000);
      }
    });
  });

  group('EHentai extract_urls parity', () {
    test('no links', () {
      const html = 'no links here';
      final dartUrls = _dartExtractUrls(html);
      expect(dartUrls, isEmpty);
      if (hasRust) {
        final rustUrls = RustBridge.instance!.ehentaiExtractUrls(html);
        expect(rustUrls, dartUrls);
      }
    });

    test('single link', () {
      const html = '<a href="/s/abc123/12345-1">link</a>';
      final dartUrls = _dartExtractUrls(html);
      expect(dartUrls.length, 1);
      expect(dartUrls[0].contains('/s/abc123/12345-1'), isTrue);
      if (hasRust) {
        final rustUrls = RustBridge.instance!.ehentaiExtractUrls(html);
        expect(rustUrls, dartUrls);
      }
    });

    test('dedup identical links', () {
      const html =
          '<a href="/s/abc/1-1">a</a><a href="/s/abc/1-1">b</a>';
      final dartUrls = _dartExtractUrls(html);
      expect(dartUrls.length, 1);
      if (hasRust) {
        final rustUrls = RustBridge.instance!.ehentaiExtractUrls(html);
        expect(rustUrls, dartUrls);
      }
    });

    test('backslash normalized', () {
      const html = r'<a href="\/s\/abc123\/12345-1">link<\/a>';
      final dartUrls = _dartExtractUrls(html);
      expect(dartUrls.length, 1);
      if (hasRust) {
        final rustUrls = RustBridge.instance!.ehentaiExtractUrls(html);
        expect(rustUrls, dartUrls);
      }
    });
  });

  group('EHentai extract_tags parity', () {
    test('no tags', () {
      const html = 'no tags here';
      final dartTags = _dartExtractTagStrings(html);
      expect(dartTags, isEmpty);
      if (hasRust) {
        final rustTags = RustBridge.instance!.ehentaiExtractTags(html);
        expect(rustTags, dartTags);
      }
    });

    test('simple language tag', () {
      const html =
          '<div id="td_language:korean" class="gt"><a href="/tag/language:korean">korean</a></div>';
      final dartTags = _dartExtractTagStrings(html);
      expect(dartTags, ['language:korean']);
      if (hasRust) {
        final rustTags = RustBridge.instance!.ehentaiExtractTags(html);
        expect(rustTags, dartTags);
      }
    });

    test('tag with inline HTML elements', () {
      const html =
          '<div id="td_artist:some" class="gt"><a href="/tag/artist:some">some<br>name</a></div>';
      final dartTags = _dartExtractTagStrings(html);
      expect(dartTags, ['artist:somename']);
      if (hasRust) {
        final rustTags = RustBridge.instance!.ehentaiExtractTags(html);
        expect(rustTags, dartTags);
      }
    });

    test('fallback legacy title pattern', () {
      const html =
          '<div class="gt" title="artist:someone">text</div>';
      final dartTags = _dartExtractTagStrings(html);
      expect(dartTags, ['artist:someone']);
      if (hasRust) {
        final rustTags = RustBridge.instance!.ehentaiExtractTags(html);
        expect(rustTags?.toSet(), dartTags.toSet());
      }
    });
  });
}

// ── Dart fallback implementations (identical to production fallback) ──

Set<int> _dartDecodeGalleryIds(Uint8List inbuf) {
  if (inbuf.length < 4) return const <int>{};
  final buffer = ByteData.sublistView(inbuf);
  final count = buffer.getUint32(0, Endian.big);
  final expectedLen = count * 4 + 4;
  if (count == 0 || inbuf.length < expectedLen) return const <int>{};
  final ids = <int>{};
  var offset = 4;
  for (var i = 0; i < count; i++) {
    ids.add(buffer.getUint32(offset, Endian.big));
    offset += 4;
  }
  return ids;
}

List<int> _dartDecodeNozomiIds(Uint8List bytes) {
  if (bytes.length < 4) return const <int>[];
  final usable = bytes.length - (bytes.length % 4);
  final data = ByteData.sublistView(bytes, 0, usable);
  final ids = <int>[];
  for (var i = 0; i < usable; i += 4) {
    ids.add(data.getUint32(i, Endian.big));
  }
  return ids;
}

List<String> _dartExtractUrls(String html) {
  final normalizedHtml = html.replaceAll(r'\/', '/');
  final urlPattern = RegExp(
    r'((?:https?:)?//(?:e-hentai|exhentai)\.org)?/s/[A-Za-z0-9_-]+/[0-9]+-[0-9]+',
    caseSensitive: false,
  );
  final seen = <String>{};
  final links = <String>[];
  for (final match in urlPattern.allMatches(normalizedHtml)) {
    final link = match.group(0)!;
    if (seen.add(link)) {
      links.add(link);
    }
  }
  return links;
}

List<String> _dartExtractTagStrings(String html) {
  final tags = <String>[];
  final tagMatches = RegExp(
    r'<div[^>]*id="td_([^"]+)"[^>]*>[\s\S]*?<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>',
    caseSensitive: false,
  ).allMatches(html);
  for (final match in tagMatches) {
    final tagSpec = (match.group(1) ?? '').trim();
    if (tagSpec.isEmpty || !tagSpec.contains(':')) continue;
    final separatorIndex = tagSpec.indexOf(':');
    final rawType = tagSpec.substring(0, separatorIndex).trim();
    final tagText = _cleanHtmlText(match.group(3) ?? '');
    if (tagText.isEmpty) continue;
    tags.add('$rawType:$tagText');
  }
  if (tags.isEmpty) {
    final matches = RegExp(
      r'<div[^>]*class="[^"]*\bgt\b[^"]*"[^>]*title="([^"]+)"',
    ).allMatches(html);
    for (final match in matches) {
      final name = _cleanHtmlText(match.group(1) ?? '');
      if (name.isNotEmpty) tags.add(name);
    }
  }
  return tags;
}

String _cleanHtmlText(String text) {
  if (text.isEmpty) return '';
  return text
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&#039;', "'")
      .replaceAll('&quot;', '"')
      .trim();
}

// ── Hitomi binary node builder ──────────────────────────────

/// Build a Hitomi binary index node for testing.
/// num_keys, keys, num_datas, datas, 17 sub-node addresses — all BE.
Uint8List _buildHitomiNode(
  List<Uint8List> keys,
  List<({int offset, int length})> datas,
  List<int> subNodeAddresses,
) {
  final buf = BytesBuilder();
  // num_keys: u32 BE
  buf.add(_u32BE(keys.length));
  // keys: (key_size u32 BE, key bytes)
  for (final k in keys) {
    buf.add(_u32BE(k.length));
    buf.add(k);
  }
  // num_datas: u32 BE
  buf.add(_u32BE(datas.length));
  // data refs: (offset u64 BE, length u32 BE)
  for (final d in datas) {
    buf.add(_u64BE(d.offset));
    buf.add(_u32BE(d.length));
  }
  // 17 sub-node addresses: u64 BE each
  for (var i = 0; i < 17; i++) {
    buf.add(_u64BE(i < subNodeAddresses.length ? subNodeAddresses[i] : 0));
  }
  return buf.toBytes();
}

Uint8List _u32BE(int v) {
  final b = ByteData(4)..setUint32(0, v, Endian.big);
  return b.buffer.asUint8List();
}

Uint8List _u64BE(int v) {
  final b = ByteData(8)..setUint64(0, v, Endian.big);
  return b.buffer.asUint8List();
}

int _readU64LE(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24) |
      (bytes[offset + 4] << 32) |
      (bytes[offset + 5] << 40) |
      (bytes[offset + 6] << 48) |
      (bytes[offset + 7] << 56);
}

int _readU32LE(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}
