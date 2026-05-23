import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/uri_component_utils.dart';

void main() {
  group('UriComponentUtils.safeDecode', () {
    test('returns empty string unchanged', () {
      expect(UriComponentUtils.safeDecode(''), isEmpty);
    });

    test('returns raw unicode slug unchanged', () {
      expect(
        UriComponentUtils.safeDecode('komik-\u301c-special-\u30fc'),
        'komik-\u301c-special-\u30fc',
      );
    });

    test('decodes valid percent-encoded unicode slug', () {
      expect(
        UriComponentUtils.safeDecode('komik-%E3%80%9C-special'),
        'komik-\u301c-special',
      );
    });

    test('decodes mixed encoded and raw unicode slug', () {
      expect(
        UriComponentUtils.safeDecode('komik-%E3%80%9C-special-\u30fc'),
        'komik-\u301c-special-\u30fc',
      );
    });

    test('preserves malformed percent encoding', () {
      expect(
        UriComponentUtils.safeDecode('komik-%E3%80%9C-special-%ZZ'),
        'komik-%E3%80%9C-special-%ZZ',
      );
    });

    test('preserves literal percent characters', () {
      expect(
        UriComponentUtils.safeDecode('100%-real-content'),
        '100%-real-content',
      );
    });

    test('decodes E-Hentai virtual part identifier safely', () {
      expect(
        UriComponentUtils.safeDecode('__ehpart__%3A3906586%3A971a6d4051%3A2'),
        '__ehpart__:3906586:971a6d4051:2',
      );
    });

    test('preserves malformed E-Hentai internal identifier', () {
      expect(
        UriComponentUtils.safeDecode('__ehchunk__:%ZZ:bad'),
        '__ehchunk__:%ZZ:bad',
      );
    });
  });
}
