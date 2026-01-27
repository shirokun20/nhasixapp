import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/native_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativePdfService', () {
    late NativePdfService service;

    setUp(() {
      service = NativePdfService();
    });

    test('service can be instantiated', () {
      expect(service, isNotNull);
    });
  });
}
