import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/src/mangafire/mangafire_vrf_cache.dart';

void main() {
  group('MangaFireVRFCache', () {
    late MangaFireVRFCache cache;

    setUp(() {
      cache = MangaFireVRFCache(maxEntries: 3, ttlSeconds: 300);
    });

    group('set/getEntry', () {
      test('stores and retrieves captured URL', () {
        cache.set('/api/titles',
            'https://mangafire.to/api/titles?page=1&sort=desc&vrf=abc123');
        final entry = cache.getEntry('/api/titles');
        expect(
            entry,
            equals(
                'https://mangafire.to/api/titles?page=1&sort=desc&vrf=abc123'));
      });

      test('returns null for missing key', () {
        expect(cache.getEntry('/nonexistent'), isNull);
      });

      test('evicts LRU when at capacity', () {
        cache.set('a', 'url_a');
        cache.set('b', 'url_b');
        cache.set('c', 'url_c');
        cache.set('d', 'url_d');
        expect(cache.getEntry('a'), isNull);
        expect(cache.getEntry('b'), isNotNull);
      });

      test('updates existing key without eviction', () {
        cache.set('a', 'url_1');
        cache.set('b', 'url_2');
        cache.set('c', 'url_3');
        cache.set('a', 'url_updated');
        expect(cache.size, equals(3));
        expect(cache.getEntry('a'), equals('url_updated'));
      });
    });

    group('TTL expiry', () {
      test('returns null after TTL', () {
        final short = MangaFireVRFCache(maxEntries: 5, ttlSeconds: -1);
        short.set('/api/titles', 'https://example.com/api/titles?vrf=old');
        expect(short.getEntry('/api/titles'), isNull);
      });
    });

    group('invalidate', () {
      test('removes specific entry', () {
        cache.set('a', 'url_a');
        cache.invalidate('a');
        expect(cache.getEntry('a'), isNull);
        expect(cache.size, equals(0));
      });
    });

    test('clear removes all entries', () {
      cache.set('a', 'url_a');
      cache.set('b', 'url_b');
      cache.clear();
      expect(cache.size, equals(0));
    });
  });
}
