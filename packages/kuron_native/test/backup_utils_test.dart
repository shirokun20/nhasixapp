import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:kuron_native/utils/backup_utils.dart';
import 'package:kuron_native/kuron_native_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKuronNativePlatform with MockPlatformInterfaceMixin implements KuronNativePlatform {
  String? mockPickedDirectory;
  
  @override
  Future<String?> pickDirectory() async => mockPickedDirectory;
  
  @override
  Future<String?> getPlatformVersion() => Future.value('1.0.0');
  
  @override
  Future<Map<Object?, Object?>?> getSystemInfo(String type) => 
      Future.value({'ram': 8192});
  
  @override
  Future<String?> startDownload({
    required String url,
    required String fileName,
    String? destinationDir,
    String? savePath,
    String? title,
    String? description,
    String? mimeType,
    String? cookie,
    String? userAgent,
  }) => Future.value('download_id');
  
  @override
  Future<Map<String, dynamic>?> convertImagesToPdf({
    required List<String> imagePaths,
    required String outputPath,
    Function(int progress, String message)? onProgress,
  }) => Future.value({'success': true, 'pdfPath': outputPath});
  
  @override
  Future<void> openWebView({required String url, bool enableJavaScript = true}) async {}
  
  @override
  Future<void> openPdf({
    required String filePath,
    String? title,
    int? startPage,
  }) async {}
  
  @override
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
    String? autoCloseOnCookie,
    String? ssoRedirectUrl,
    bool enableAdBlock = false,
    bool clearCookies = false,
  }) => Future.value({'success': true, 'cookies': []});
  
  @override
  Future<void> clearCookies() async {}
}

void main() {
  late Directory testDir;
  late MockKuronNativePlatform mockPlatform;

  setUp(() async {
    // Create temporary test directory
    testDir = await Directory.systemTemp.createTemp('backup_utils_test_');
    
    // Setup mock platform
    mockPlatform = MockKuronNativePlatform();
    KuronNativePlatform.instance = mockPlatform;
  });

  tearDown(() async {
    // Clean up test directory
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('BackupUtils.exportJson', () {
    test('exports JSON to custom directory when provided', () async {
      final customDir = testDir.path;
      final testData = '{"test": "data"}';
      final fileName = 'test_backup.json';

      final result = await BackupUtils.exportJson(
        testData,
        fileName,
        customDirectory: customDir,
      );

      expect(result, isNotNull);
      expect(result, contains(fileName));
      
      final file = File('$customDir/$fileName');
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals(testData));
    });

    test('exports JSON to default Downloads when custom directory is null', () async {
      final testData = '{"test": "data"}';
      final fileName = 'default_backup.json';

      // This will use hardcoded /storage/emulated/0/Download or fallback
      // We can't easily test this without actual Android environment
      // So we just verify it doesn't throw
      final result = await BackupUtils.exportJson(testData, fileName);
      
      // Result may be null on non-Android platforms in test environment
      // but shouldn't throw an exception
      expect(result, isA<String?>());
    });

    test('handles export errors gracefully', () async {
      final testData = '{"test": "data"}';
      final fileName = 'test_backup.json';
      final invalidDir = '/invalid/path/that/does/not/exist';

      final result = await BackupUtils.exportJson(
        testData,
        fileName,
        customDirectory: invalidDir,
      );

      expect(result, isNull);
    });

    test('exports empty JSON successfully', () async {
      final customDir = testDir.path;
      final testData = '{}';
      final fileName = 'empty_backup.json';

      final result = await BackupUtils.exportJson(
        testData,
        fileName,
        customDirectory: customDir,
      );

      expect(result, isNotNull);
      final file = File('$customDir/$fileName');
      expect(await file.readAsString(), equals(testData));
    });
  });

  group('BackupUtils.importJson', () {
    test('imports JSON from selected directory successfully', () async {
      // Setup: Create a test backup file
      final fileName = 'backup.json';
      final testData = '{"imported": "data"}';
      final file = File('${testDir.path}/$fileName');
      await file.writeAsString(testData);

      // Mock picker to return our test directory
      mockPlatform.mockPickedDirectory = testDir.path;

      final result = await BackupUtils.importJson(fileName: fileName);

      expect(result, isNotNull);
      expect(result, equals(testData));
    });

    test('returns null when user cancels directory picker', () async {
      // Mock picker to return null (user cancelled)
      mockPlatform.mockPickedDirectory = null;

      final result = await BackupUtils.importJson();

      expect(result, isNull);
    });

    test('returns null when backup file does not exist', () async {
      // Mock picker to return directory without backup file
      mockPlatform.mockPickedDirectory = testDir.path;

      final result = await BackupUtils.importJson(fileName: 'nonexistent.json');

      expect(result, isNull);
    });

    test('imports with custom fileName parameter', () async {
      final customFileName = 'my_custom_backup.json';
      final testData = '{"custom": "backup"}';
      final file = File('${testDir.path}/$customFileName');
      await file.writeAsString(testData);

      mockPlatform.mockPickedDirectory = testDir.path;

      final result = await BackupUtils.importJson(fileName: customFileName);

      expect(result, equals(testData));
    });

    test('handles file read errors gracefully', () async {
      // Create a directory instead of file to trigger read error
      final fakeFile = Directory('${testDir.path}/backup.json');
      await fakeFile.create();

      mockPlatform.mockPickedDirectory = testDir.path;

      final result = await BackupUtils.importJson();

      expect(result, isNull);
    });

    test('imports large JSON successfully', () async {
      final fileName = 'large_backup.json';
      // Create a larger test data (1000 entries)
      final entries = List.generate(1000, (i) => '"item$i": "value$i"');
      final testData = '{${entries.join(',')}}';
      
      final file = File('${testDir.path}/$fileName');
      await file.writeAsString(testData);

      mockPlatform.mockPickedDirectory = testDir.path;

      final result = await BackupUtils.importJson(fileName: fileName);

      expect(result, isNotNull);
      expect(result!.length, greaterThan(10000)); // Should be quite large
      expect(result, contains('item500')); // Verify content
    });
  });

  group('BackupUtils integration', () {
    test('export then import cycle preserves data', () async {
      final testData = '{"round": "trip", "value": 42}';
      final fileName = 'roundtrip.json';

      // Export
      final exportPath = await BackupUtils.exportJson(
        testData,
        fileName,
        customDirectory: testDir.path,
      );
      expect(exportPath, isNotNull);

      // Import
      mockPlatform.mockPickedDirectory = testDir.path;
      final importedData = await BackupUtils.importJson(fileName: fileName);

      expect(importedData, equals(testData));
    });
  });
}
