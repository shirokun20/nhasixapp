import 'package:kuron_core/kuron_core.dart';
import 'package:test/test.dart';

void main() {
  group('registrableDomain', () {
    test('last two labels for subdomains', () {
      expect(registrableDomain(Uri.parse('https://sub.komiktap.info/x')),
          'komiktap.info');
      expect(registrableDomain(Uri.parse('https://api.schale.network/auth')),
          'schale.network');
    });

    test('single-label hosts returned as-is', () {
      expect(registrableDomain(Uri.parse('http://localhost:8080/')), 'localhost');
    });

    test('empty host returns null', () {
      expect(registrableDomain(Uri.parse('https://')), isNull);
    });
  });
}
