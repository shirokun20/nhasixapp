import 'dart:io';

import 'package:test/test.dart';

import 'package:kuron_config_generator/src/validation/backup_manager.dart';

void main() {
  late Directory tmpDir;
  late String configPath;
  late String backupPath;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('backup_test_');
    configPath = '${tmpDir.path}/test-config.json';
    backupPath = '$configPath.original.json';
    File(configPath).writeAsStringSync('{"sourceId": "test", "version": "1"}');
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('BackupManager.createBackup (R8.1–R8.4)', () {
    test('creates backup at {configPath}.original.json (R8.2)', () async {
      await BackupManager.createBackup(configPath);

      expect(File(backupPath).existsSync(), isTrue);
      expect(
        File(backupPath).readAsStringSync(),
        '{"sourceId": "test", "version": "1"}',
      );
    });

    test('does not overwrite existing backup (R8.3)', () async {
      // Create initial backup
      await BackupManager.createBackup(configPath);

      // Modify original config
      File(configPath).writeAsStringSync('{"sourceId": "modified"}');

      // Try backup again
      await BackupManager.createBackup(configPath);

      // Backup should still be original content
      expect(
        File(backupPath).readAsStringSync(),
        '{"sourceId": "test", "version": "1"}',
      );
    });

    test('handles missing config file gracefully (R8.4)', () async {
      final missingPath = '${tmpDir.path}/nonexistent.json';
      // Should not throw
      await BackupManager.createBackup(missingPath);
      // Should not create backup file either
      expect(File('$missingPath.original.json').existsSync(), isFalse);
    });

    test('handles errors gracefully without crashing (R8.4)', () async {
      // Invalid path with null bytes
      await BackupManager.createBackup('/dev/null/test.json');
      // Should not throw
    });
  });

  group('BackupManager.restoreBackup', () {
    test('restores config from backup', () async {
      await BackupManager.createBackup(configPath);

      // Modify original
      File(configPath).writeAsStringSync('{"sourceId": "corrupted"}');

      // Restore
      final restored = await BackupManager.restoreBackup(configPath);
      expect(restored, isTrue);

      // Original should be back
      expect(
        File(configPath).readAsStringSync(),
        '{"sourceId": "test", "version": "1"}',
      );
    });

    test('returns false if no backup exists', () async {
      final result = await BackupManager.restoreBackup(
        '${tmpDir.path}/no-backup.json',
      );
      expect(result, isFalse);
    });

    test('deletes backup after successful restore', () async {
      await BackupManager.createBackup(configPath);
      expect(File(backupPath).existsSync(), isTrue);

      await BackupManager.restoreBackup(configPath);
      expect(File(backupPath).existsSync(), isFalse);
    });
  });
}
