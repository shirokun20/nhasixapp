import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/src/doujindesuxxx/doujindesuxxx_source_factory.dart';

// Minimal runnable check for the _enc_resp_ decrypt: the encode here is the
// exact inverse of the source's decode, so a round-trip must recover input.
const _salt = 'doujindesu-scrapers-cannot-read-this-super-secret-salt-2026-v2';

int _slot() => DateTime.now().millisecondsSinceEpoch ~/ 3600000;

String _key(int slot) {
  final seed = '${_salt}_$slot';
  var hash = 0;
  for (final c in seed.codeUnits) {
    hash = (((hash << 5) - hash + c) & 0xFFFFFFFF).toSigned(32);
  }
  var m = hash.abs() == 0 ? 123456789 : hash.abs();
  final out = StringBuffer();
  for (var i = 0; i < 32; i++) {
    m = (m * 1664525 + 1013904223) % 4294967296;
    out.writeCharCode(33 + m % 93);
  }
  return out.toString();
}

String _encrypt(String plainAscii, String key) {
  final bytes = latin1.encode(plainAscii);
  final out = StringBuffer();
  var n = 42;
  for (var c = 0; c < bytes.length; c++) {
    final cipher =
        (bytes[c] ^ key.codeUnitAt(c % key.length) ^ (c * 13) ^ n) & 0xFF;
    out.write(cipher.toRadixString(16).padLeft(2, '0'));
    n = (n + cipher) & 0xFF;
  }
  return out.toString();
}

void main() {
  test('round-trip decode recovers plaintext for current hour slot', () {
    final payload = jsonEncode({
      'title': 'Pachi-ya no Idol',
      'items': [1, 2, 3],
    });
    // SPA passes decodeURIComponent output to JSON.parse; mirror with URL-encode.
    final enc = Uri.encodeComponent(payload);
    final hex = _encrypt(enc, _key(_slot()));
    expect(doujinDesuDecrypt(hex), jsonDecode(payload));
  });

  test('garbage ciphertext returns null (decode failure handling)', () {
    expect(doujinDesuDecrypt('zzzz'), isNull);
  });
}
