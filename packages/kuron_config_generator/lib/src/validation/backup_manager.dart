import 'dart:io';

/// Manages config file backup and restore operations.
///
/// Creates a backup of the config at `{configPath}.original.json` on first
/// entry and never overwrites an existing backup (R8.3).
class BackupManager {
  /// Creates a backup of [configPath] at `{configPath}.original.json`.
  ///
  /// - R8.1: Creates backup on first entry only.
  /// - R8.2: Backup path = `{configPath}.original.json`.
  /// - R8.3: Never overwrites an existing backup.
  /// - R8.4: Handles errors gracefully (no crash).
  static Future<void> createBackup(String configPath) async {
    final backupPath = '$configPath.original.json';
    final backupFile = File(backupPath);
    if (await backupFile.exists()) return; // R8.3

    try {
      await File(configPath).copy(backupPath);
    } catch (e) {
      stderr.writeln('Warning: Could not create backup: $e'); // R8.4
    }
  }

  /// Restores the config file from `{configPath}.original.json`.
  ///
  /// Returns `true` if restore succeeded, `false` if no backup exists or
  /// an error occurred.
  static Future<bool> restoreBackup(String configPath) async {
    final backupPath = '$configPath.original.json';
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) return false;

    try {
      await backupFile.copy(configPath);
      await backupFile.delete();
      return true;
    } catch (e) {
      stderr.writeln('Warning: Could not restore backup: $e');
      return false;
    }
  }
}
