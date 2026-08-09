import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/polygon_geometry.dart';

void main() {
  group('isRectLikePolygon', () {
    test('true for a perfect axis-aligned rectangle', () {
      const pts = [
        Offset(0, 0),
        Offset(60, 0),
        Offset(60, 40),
        Offset(0, 40),
      ];
      expect(isRectLikePolygon(pts), isTrue);
    });

    test('true for a rectangle with approxPolyDP corner noise', () {
      // Octagon approximating a 60×40 frame — corners flattened by the
      // contour simplification (~0.995 area fill).
      const pts = [
        Offset(2, 0),
        Offset(58, 0),
        Offset(60, 3),
        Offset(60, 37),
        Offset(58, 40),
        Offset(2, 40),
        Offset(0, 37),
        Offset(0, 3),
      ];
      expect(isRectLikePolygon(pts), isTrue);
    });

    test('true for a narration-box hexagon (overlay test polygon)', () {
      const pts = [
        Offset(0, 0),
        Offset(60, 0),
        Offset(55, 20),
        Offset(60, 40),
        Offset(0, 40),
      ];
      expect(isRectLikePolygon(pts), isTrue);
    });

    test('false for an oval polygon (bubble shape)', () {
      // Ellipse 60×40 sampled with 32 points → area ≈ π/4 of the bbox.
      final pts = List.generate(32, (i) {
        final t = 2 * math.pi * i / 32;
        return Offset(30 + 30 * math.cos(t), 20 + 20 * math.sin(t));
      });
      expect(isRectLikePolygon(pts), isFalse);
    });

    test('false for a diamond (rotated square)', () {
      const pts = [
        Offset(30, 0),
        Offset(60, 20),
        Offset(30, 40),
        Offset(0, 20),
      ];
      expect(isRectLikePolygon(pts), isFalse);
    });

    test('false for a triangle', () {
      const pts = [Offset(0, 0), Offset(60, 0), Offset(30, 40)];
      expect(isRectLikePolygon(pts), isFalse);
    });

    test('false for degenerate polygons (fewer than 3 points)', () {
      expect(isRectLikePolygon(const [Offset(0, 0), Offset(10, 10)]), isFalse);
      expect(isRectLikePolygon(const []), isFalse);
    });
  });
}
