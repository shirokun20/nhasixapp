import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/native_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativePdfService', () {
    late NativePdfService service;

    setUp(() {
      service = NativePdfService();
    });

    test('generatePdf with valid paths returns work ID', () async {
      // Arrange
      const expectedWorkId = 'work-pdf-123';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_conversion'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'generatePdf') {
            return expectedWorkId;
          }
          return null;
        },
      );

      // Act
      final workId = await service.generatePdf(
        contentId: 'content-1',
        imagePaths: ['/path/1.jpg', '/path/2.jpg'],
        maxPagesPerFile: 50,
      );

      // Assert
      expect(workId, expectedWorkId);
    });

    test('generatePdf with empty image paths  returns empty string', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_conversion'),
        (MethodCall methodCall) async {
          return '';
        },
      );

      // Act
      final workId = await service.generatePdf(
        contentId: 'content-1',
        imagePaths: [],
        maxPagesPerFile: 50,
      );

      // Assert
      expect(workId, isEmpty);
    });

    test('handles platform exception in generatePdf', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_conversion'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'PDF_ERROR', message: 'Test error');
        },
      );

      // Act & Assert
      expect(
        () => service.generatePdf(
          contentId: 'content-1',
          imagePaths: ['/path/1.jpg'],
          maxPagesPerFile: 50,
        ),
        throwsA(isA<Exception>()),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/pdf_conversion'),
        null,
      );
    });
  });
}
