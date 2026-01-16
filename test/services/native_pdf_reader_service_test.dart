import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/native_pdf_reader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativePdfReaderService', () {
    late NativePdfReaderService service;

    setUp(() {
      service = NativePdfReaderService();
    });

    test('openPdf with valid file path succeeds', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_reader'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'openPdf') {
            return null; // Success
          }
          return null;
        },
      );

      // Act & Assert
      await expectLater(
        service.openPdf('/path/to/file.pdf'),
        completes,
      );
    });

    test('openPdf with title and startPage parameters', () async {
      // Arrange
      Map<String, dynamic>? receivedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_reader'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'openPdf') {
            receivedArgs = Map<String, dynamic>.from(methodCall.arguments);
            return null;
          }
          return null;
        },
      );

      // Act
      await service.openPdf(
        '/path/to/file.pdf',
        title: 'Test PDF',
        startPage: 5,
      );

      // Assert
      expect(receivedArgs?['filePath'], '/path/to/file.pdf');
      expect(receivedArgs?['title'], 'Test PDF');
      expect(receivedArgs?['startPage'], 5);
    });

    test('handles platform exception in openPdf', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_reader'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'PDF_OPEN_FAILED',
            message: 'Test error',
          );
        },
      );

      // Act & Assert
      expect(
        () => service.openPdf('/path/to/file.pdf'),
        throwsA(isA<PlatformException>()),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_reader'),
        null,
      );
    });
  });
}
