import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/kuron_native.dart';

void main() {
  group('RustBridge null-safe image ops', () {
    test('instance load does not throw', () {
      expect(() => RustBridge.instance, returnsNormally);
    });

    test('image ops availability never throws, callable on null instance',
        () {
      // On host (no .so) instance is null — call sites guard with
      // `bridge != null && bridge.imageOpsAvailable`. This documents that
      // the fallback path is reachable without a native library.
      final bridge = RustBridge.instance;
      if (bridge != null) {
        expect(bridge.imageOpsAvailable, isA<bool>());
      } else {
        // Fallback path: no crash, no native call attempted.
        expect(RustBridge.isAvailable, isFalse);
      }
    });
  });
}
