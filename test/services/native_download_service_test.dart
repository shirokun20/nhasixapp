import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/native_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeDownloadService', () {
    late NativeDownloadService service;

    setUp(() {
      service = NativeDownloadService();
    });

    test('startDownload returns work ID', () async {
      // Arrange
      const expectedWorkId = 'work-123';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/download'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'startDownload') {
            return expectedWorkId;
          }
          return null;
        },
      );

      // Act
      final workId = await service.startDownload(
        contentId: 'content-1',
        sourceId: 'nhentai',
        imageUrls: ['https://example.com/1.jpg'],
        destinationPath: '/path/to/dest',
      );

      // Assert
      expect(workId, expectedWorkId);
    });

    test('cancelDownload calls method channel', () async {
      // Arrange
      bool called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/download'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'cancelDownload' &&
              methodCall.arguments['contentId'] == 'content-1') {
            called = true;
          }
          return null;
        },
      );

      // Act
      await service.cancelDownload('content-1');

      // Assert
      expect(called, isTrue);
    });

    test('pauseDownload calls method channel', () async {
      // Arrange
      bool called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/download'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'pauseDownload' &&
              methodCall.arguments['contentId'] == 'content-1') {
            called = true;
          }
          return null;
        },
      );

      // Act
      await service.pauseDownload('content-1');

      // Assert
      expect(called, isTrue);
    });

    test('getDownloadStatus returns status map', () async {
      // Arrange
      final expectedStatus = {
        'status': 'RUNNING',
        'downloadedPages': 5,
        'totalPages': 10,
        'contentId': 'content-1',
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/download'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getDownloadStatus') {
            return expectedStatus;
          }
          return null;
        },
      );

      // Act
      final status = await service.getDownloadStatus('content-1');

      // Assert
      expect(status, expectedStatus);
    });

    test('handles platform exception in startDownload', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/download'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        },
      );

      // Act & Assert
      expect(
        () => service.startDownload(
          contentId: 'content-1',
          sourceId: 'nhentai',
          imageUrls: ['https://example.com/1.jpg'],
          destinationPath: '/path/to/dest',
        ),
        throwsA(isA<Exception>()),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/download'),
        null,
      );
    });
  });
}
