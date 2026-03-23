import 'dart:convert';

class HentaiNexusDecryptor {
  static const List<int> _primeNumbers = <int>[2, 3, 5, 7, 11, 13, 17, 19];

  static List<int> _firstPrimes(int count) {
    final primes = <int>[];
    var n = 2;

    while (primes.length < count) {
      var isPrime = true;
      for (var i = 2; i * i <= n; i++) {
        if (n % i == 0) {
          isPrime = false;
          break;
        }
      }
      if (isPrime) {
        primes.add(n);
      }
      n++;
    }

    return primes;
  }

  /// Mirrors the site reader algorithm from `reader.min.js` initReader().
  static String decrypt({
    required String encrypted,
    String hostname = 'hentainexus.com',
  }) {
    final data = base64Decode(encrypted);
    if (data.length <= 64) {
      throw const FormatException('HentaiNexus seed payload is too short');
    }

    final hostCodes = hostname.codeUnits;
    final xorLen =
        hostCodes.length < data.length ? hostCodes.length : data.length;
    for (var i = 0; i < xorLen; i++) {
      data[i] = data[i] ^ hostCodes[i];
    }

    final keyStream = data.sublist(0, 64);
    final ciphertext = data.sublist(64);
    final digest = List<int>.generate(256, (i) => i);

    var primeIdx = 0;
    for (var i = 0; i < 64; i++) {
      primeIdx ^= keyStream[i];
      for (var j = 0; j < 8; j++) {
        if ((primeIdx & 1) != 0) {
          primeIdx = (primeIdx >> 1) ^ 12;
        } else {
          primeIdx = primeIdx >> 1;
        }
      }
    }
    primeIdx &= 7;

    var key = 0;
    for (var i = 0; i < 256; i++) {
      key = (key + digest[i] + keyStream[i % 64]) % 256;
      final temp = digest[i];
      digest[i] = digest[key];
      digest[key] = temp;
    }

    final q = _primeNumbers[primeIdx];
    var k = 0;
    var n = 0;
    var p = 0;
    var xorKey = 0;

    final outCodes = <int>[];
    for (var i = 0; i < ciphertext.length; i++) {
      k = (k + q) % 256;
      n = (p + digest[(n + digest[k]) % 256]) % 256;
      p = (p + k + digest[k]) % 256;

      final temp = digest[k];
      digest[k] = digest[n];
      digest[n] = temp;

      xorKey =
          digest[(n + digest[(k + digest[(xorKey + p) % 256]) % 256]) % 256];
      outCodes.add(ciphertext[i] ^ xorKey);
    }

    return String.fromCharCodes(outCodes);
  }

  // Kept for future experiments with alternative server variants.
  static List<int> firstPrimesForDebug(int count) {
    return _firstPrimes(count);
  }

  static List<String> extractImageUrls(String decryptedJson) {
    final decoded = jsonDecode(decryptedJson);
    if (decoded is! List) {
      return const [];
    }

    final urls = <String>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final type = item['type'] as String?;

      if (type == 'image') {
        final image = item['image'] as String?;
        if (image != null && image.isNotEmpty) {
          urls.add(image);
        }
        continue;
      }

      // Backward-compat support for older local payload assumptions.
      if (type == 'url') {
        final url = item['url'] as String?;
        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      } else if (type == 'spread') {
        final left = item['url'] as String?;
        final right = item['nextLink'] as String?;
        if (left != null && left.isNotEmpty) {
          urls.add(left);
        }
        if (right != null && right.isNotEmpty) {
          urls.add(right);
        }
      }
    }

    return urls;
  }
}
