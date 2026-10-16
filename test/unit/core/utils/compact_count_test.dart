import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/compact_count.dart';

void main() {
  group('formatCompactCount', () {
    test('shows plain integers below 1000', () {
      expect(formatCompactCount(0), '0');
      expect(formatCompactCount(1), '1');
      expect(formatCompactCount(642), '642');
      expect(formatCompactCount(999), '999');
    });

    test('compacts thousands with one decimal, trimming trailing .0', () {
      expect(formatCompactCount(1000), '1k');
      expect(formatCompactCount(1284), '1.3k');
      expect(formatCompactCount(2148), '2.1k');
      expect(formatCompactCount(9999), '10k');
    });

    test('compacts millions', () {
      expect(formatCompactCount(1000000), '1M');
      expect(formatCompactCount(1500000), '1.5M');
    });
  });
}
