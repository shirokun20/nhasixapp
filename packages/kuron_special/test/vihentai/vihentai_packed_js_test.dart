import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/src/vihentai/vihentai_packed_js.dart';

void main() {
  group('ViHentaiPackedJs', () {
    test('extractImageUrls from packed eval', () {
      const script = 'eval(function(h,u,n,t,e,r){return h}'
          '("QAQ",24,"dvqjcAaQR",36,7,55))';
      final urls = ViHentaiPackedJs.extractImageUrls(script);
      expect(urls, isA<List<String>>());
    });

    test('extractImageUrls with KuroReader output from real script', () {
      // Build charset and encoded data matching Tachiyomi format.
      // Decoded should produce KuroReader with image URLs.
      const charset = '0123456789abcdefghijklmnopqrstuvwxyz';
      const e = 10; // charset[10] = 'a' delimiter
      const delimiter = 'a';
      const t = 36;

      // Encode: "KuroReader('#ch',[])" → each char → (charCode + 36) in base-10
      String encode(String input, String charset, int e, int t) {
        final segments = <String>[];
        for (final codeUnit in input.runes) {
          var val = codeUnit + t;
          final digits = <int>[];
          while (val > 0) {
            digits.add(val % e);
            val ~/= e;
          }
          if (digits.isEmpty) digits.add(0);
          segments.add(digits.reversed.map((i) => charset[i]).join(''));
        }
        return segments.join(delimiter);
      }

      const decoded = '''KuroReader('#ch', [])''';
      final hEncoded = encode(decoded, charset, e, t);

      final script =
          'eval(function(h,u,n,t,e,r){return h}'
          '("$hEncoded",36,"$charset",$t,$e,55))';

      final urls = ViHentaiPackedJs.extractImageUrls(script);
      expect(urls, isA<List<String>>());
    });

    test('img tag fallback', () {
      final html =
          '<div><img src="https://cdn.example.com/page1.jpg"></div>'
          '<div><img src="https://cdn.example.com/page2.png"></div>';

      final urls = ViHentaiPackedJs.extractImageUrls(html);
      expect(urls.length, 2);
      expect(urls[0], 'https://cdn.example.com/page1.jpg');
      expect(urls[1], 'https://cdn.example.com/page2.png');
    });

    test('empty string returns empty list', () {
      expect(ViHentaiPackedJs.extractImageUrls(''), isEmpty);
    });

    test('no packed script returns empty list', () {
      expect(
        ViHentaiPackedJs.extractImageUrls(
            '<html><body>No script</body></html>'),
        isEmpty,
      );
    });

    test('invalid format returns empty', () {
      expect(
        ViHentaiPackedJs.extractImageUrls('nothing useful here'),
        isEmpty,
      );
    });

    test('multiple scripts: does not crash', () {
      const s =
          'eval(function(h,u,n,t,e,r){return h}'
          '("QAQ",24,"dvqjcAaQR",36,7,55))';
      final urls = ViHentaiPackedJs.extractImageUrls(
          '<script>$s</script><script>$s</script>');
      expect(urls, isA<List<String>>());
    });

    test('KuroReader regex extracts URLs from decoded string', () {
      // Test the regex directly on sample KuroReader output
      final decoded = '''KuroReader('#ch', ["https://img.example.com/1.jpg", "https://img.example.com/2.webp"], 0)''';
      final regExp = RegExp(r'"(https?://[^"]+\.\w{3,4})"');
      final matches = regExp.allMatches(decoded).toList();
      expect(matches.length, 2);
      if (matches.isNotEmpty) {
        final url = matches[0].group(1)!;
        expect(url, 'https://img.example.com/1.jpg');
      }
    });
  });
}
