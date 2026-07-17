/// Backup settings entities
/// Extracted from settings_repository.dart
library;

/// Backup frequency options
enum BackupFrequency {
  daily,
  weekly,
  monthly,
  manual,
}

/// Backup types
enum BackupType {
  manual,
  automatic,
  cloud,
}

/// Backup settings configuration
class BackupSettings {
  const BackupSettings({
    required this.autoBackup,
    required this.backupFrequency,
    required this.includeImages,
    required this.cloudBackup,
    this.maxBackups = 5,
  });

  final bool autoBackup;
  final BackupFrequency backupFrequency;
  final bool includeImages;
  final bool cloudBackup;
  final int maxBackups;
}

/// Backup information
class BackupInfo {
  const BackupInfo({
    required this.id,
    required this.createdAt,
    required this.size,
    required this.type,
    this.description,
  });

  final String id;
  final DateTime createdAt;
  final int size;
  final BackupType type;
  final String? description;
}

/// Backup result
class BackupResult {
  const BackupResult({
    required this.success,
    required this.backupId,
    required this.size,
    this.error,
  });

  final bool success;
  final String? backupId;
  final int size;
  final String? error;
}

/// Restore result
class RestoreResult {
  const RestoreResult({
    required this.success,
    required this.restoredItems,
    this.error,
  });

  final bool success;
  final int restoredItems;
  final String? error;
}
