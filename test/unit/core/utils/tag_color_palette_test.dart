import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/tag_color_palette.dart';

void main() {
  group('TagColorPalette', () {
    test('returns distinct neon colors for known fallback types', () {
      expect(TagColorPalette.resolve('tag'), const Color(0xFF18FFFF));
      expect(TagColorPalette.resolve('other'), const Color(0xFF00F5D4));
      expect(TagColorPalette.resolve('misc'), const Color(0xFFC6FF00));
      expect(TagColorPalette.resolve('tag'),
          isNot(TagColorPalette.resolve('other')));
      expect(TagColorPalette.resolve('other'),
          isNot(TagColorPalette.resolve('misc')));
    });

    test('maps unknown types deterministically into the fallback palette', () {
      final first = TagColorPalette.resolve('unregistered-type-a');
      final second = TagColorPalette.resolve('unregistered-type-a');
      final different = TagColorPalette.resolve('unregistered-type-b');

      expect(first, second);
      expect(first, isNot(const Color(0xFF000000)));
      expect(first, isNot(different));
    });
  });
}
