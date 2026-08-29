import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/services/header_inspector_service.dart';

void main() {
  group('HeaderInspectorService central dedup (3.1/3.2)', () {
    test('3 concurrent same path → underlying compute only 1 call (dedup)',
        () async {
      int computeCalls = 0;
      final service = HeaderInspectorService(
        inspectImpl: (path) async {
          computeCalls++;
          // simulate small async work
          await Future.delayed(const Duration(milliseconds: 10));
          return (format: 'webp', width: 800, height: 1200);
        },
      );

      final f1 = service.inspect('/tmp/a.webp');
      final f2 = service.inspect('/tmp/a.webp');
      final f3 = service.inspect('/tmp/a.webp');

      final results = await Future.wait([f1, f2, f3]);
      expect(results[0].format, 'webp');
      expect(results[1].format, 'webp');
      expect(results[2].format, 'webp');
      expect(computeCalls, 1, reason: 'dedup should share single future');
      expect(service.inFlightCount, 0);
      expect(service.cacheSize, 1);
    });

    test('cache hit second time → 0 compute calls (no regression)', () async {
      int calls = 0;
      final service = HeaderInspectorService(
        inspectImpl: (p) async {
          calls++;
          return (format: 'avif', width: 600, height: 800);
        },
      );
      final r1 = await service.inspect('/tmp/b.avif');
      expect(calls, 1);
      final r2 = await service.inspect('/tmp/b.avif');
      expect(calls, 1, reason: 'second hit should be cached');
      expect(r1.format, r2.format);
    });

    test('different paths → 2 compute calls, not deduped', () async {
      int calls = 0;
      final service = HeaderInspectorService(
        inspectImpl: (p) async {
          calls++;
          return (format: null, width: null, height: null);
        },
      );
      await Future.wait([
        service.inspect('/tmp/c1.webp'),
        service.inspect('/tmp/c2.webp'),
      ]);
      expect(calls, 2);
    });

    test('bounded cache evicts oldest (100 entries)', () async {
      final service = HeaderInspectorService(
        maxCacheSize: 3,
        inspectImpl: (p) async => (format: null, width: null, height: null),
      );
      await service.inspect('/a');
      await service.inspect('/b');
      await service.inspect('/c');
      expect(service.cacheSize, 3);
      await service.inspect('/d');
      expect(service.cacheSize, 3);
      // /a should be evicted, re-inspect triggers new compute
      int calls = 0;
      final service2 = HeaderInspectorService(
        maxCacheSize: 2,
        inspectImpl: (p) async {
          calls++;
          return (format: null, width: null, height: null);
        },
      );
      await service2.inspect('/x');
      await service2.inspect('/y');
      await service2.inspect('/z'); // evicts /x
      calls = 0;
      await service2.inspect('/x'); // miss
      expect(calls, 1);
    });
  });
}
