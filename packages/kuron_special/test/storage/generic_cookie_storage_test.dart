import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/src/storage/generic_cookie_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GenericCookieStorage (secure storage backed)', () {
    test('read/write/delete delegate to FlutterSecureStorage', () async {
      FlutterSecureStorage.setMockInitialValues({});

      final storage = GenericCookieStorage('crotpedia');

      expect(await storage.read('alpha'), isNull);

      await storage.write('alpha', 'session=abc123');
      expect(await storage.read('alpha'), 'session=abc123');

      await storage.delete('alpha');
      expect(await storage.read('alpha'), isNull);
    });

    test('keys are namespaced per source id', () async {
      FlutterSecureStorage.setMockInitialValues({});

      final a = GenericCookieStorage('source_a');
      final b = GenericCookieStorage('source_b');

      await a.write('cookie', 'value-a');
      await b.write('cookie', 'value-b');

      expect(await a.read('cookie'), 'value-a');
      expect(await b.read('cookie'), 'value-b');
    });
  });
}
