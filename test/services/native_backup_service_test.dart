import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/native_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeBackupService', () {
    late NativeBackupService service;

    setUp(() {
      service = NativeBackupService();
    });

    test('createBackup returns backup file path', () async {
      // Arrange
      const expectedPath = '/Download/Kuron/settings/backup_123.zip';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/backup'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'createBackup') {
            return expectedPath;
          }
          return null;
        },
      );

      // Act
      final path = await service.createBackup(
        dbPath: '/path/to/db',
        settingsJson: '{"key": "value"}',
      );

      // Assert
      expect(path, expectedPath);
    });

    test('pickBackupFile returns selected file path', () async {
      // Arrange
      const expectedPath = '/Download/Kuron/settings/backup_123.zip';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/backup'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'pickBackupFile') {
            return expectedPath;
          }
          return null;
        },
      );

      // Act
      final path = await service.pickBackupFile();

      // Assert
      expect(path, expectedPath);
    });

    test('extractBackupData returns backup data map', () async {
      // Arrange
      final expectedData = {
        'dbPath': '/temp/db',
        'settingsJson': '{"key": "value"}',
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/backup'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'extractBackupData') {
            return expectedData;
          }
          return null;
        },
      );

      // Act
      final data = await service.extractBackupData('/path/to/backup.zip');

      // Assert
      expect(data, expectedData);
    });

    test('handles platform exception in createBackup', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/backup'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'BACKUP_FAILED',
            message: 'Test error',
          );
        },
      );

      // Act & Assert
      expect(
        () => service.createBackup(
          dbPath: '/path/to/db',
          settingsJson: '{"key": "value"}',
        ),
        throwsA(isA<PlatformException>()),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('id.nhasix.app/backup'),
        null,
      );
    });
  });
}
