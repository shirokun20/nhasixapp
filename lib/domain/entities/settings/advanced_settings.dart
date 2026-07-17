/// Advanced settings entities
/// Extracted from settings_repository.dart
library;

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// Advanced settings configuration
class AdvancedSettings {
  const AdvancedSettings({
    required this.enableLogging,
    required this.logLevel,
    required this.crashReporting,
    required this.analyticsEnabled,
    this.maxCacheSize = 500,
    this.maxLogFiles = 10,
  });

  final bool enableLogging;
  final LogLevel logLevel;
  final bool crashReporting;
  final bool analyticsEnabled;
  final int maxCacheSize;
  final int maxLogFiles;
}

/// Debug settings configuration
class DebugSettings {
  const DebugSettings({
    required this.showDebugInfo,
    required this.enableTestMode,
    required this.mockNetworkCalls,
    required this.showPerformanceOverlay,
  });

  final bool showDebugInfo;
  final bool enableTestMode;
  final bool mockNetworkCalls;
  final bool showPerformanceOverlay;
}

/// Clear data result
class ClearDataResult {
  const ClearDataResult({
    required this.success,
    required this.clearedItems,
    required this.freedSpace,
    this.error,
  });

  final bool success;
  final int clearedItems;
  final int freedSpace;
  final String? error;
}

/// Migration status information
class MigrationStatus {
  const MigrationStatus({
    required this.currentVersion,
    required this.targetVersion,
    required this.needsMigration,
    this.migrationSteps,
  });

  final String currentVersion;
  final String targetVersion;
  final bool needsMigration;
  final List<String>? migrationSteps;
}

/// Migration result
class MigrationResult {
  const MigrationResult({
    required this.success,
    required this.migratedSettings,
    this.error,
  });

  final bool success;
  final int migratedSettings;
  final String? error;
}
