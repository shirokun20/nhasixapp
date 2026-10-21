import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/capped_map.dart';

void main() {
  test('CappedMap evicts oldest entry FIFO when capacity exceeded', () {
    final map = CappedMap<String, int>(3);

    map['a'] = 1;
    map['b'] = 2;
    map['c'] = 3;

    expect(map.length, 3);
    expect(map.keys.toList(), ['a', 'b', 'c']);

    // Insert 4th entry - 'a' should be evicted
    map['d'] = 4;
    expect(map.length, 3);
    expect(map.containsKey('a'), isFalse);
    expect(map['a'], isNull);
    expect(map.keys.toList(), ['b', 'c', 'd']);

    // Updating existing key does not evict
    map['b'] = 20;
    expect(map.length, 3);
    expect(map['b'], 20);

    // Insert 5th entry - 'c' should be evicted
    map['e'] = 5;
    expect(map.length, 3);
    expect(map.containsKey('c'), isFalse);
  });
}
