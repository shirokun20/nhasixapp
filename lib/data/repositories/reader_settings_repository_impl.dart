import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/reader_settings_repository.dart';
import '../models/reader_settings_model.dart';

/// Implementation of ReaderSettingsRepository using SharedPreferences
/// with comprehensive error handling and edge case management
class ReaderSettingsRepositoryImpl implements ReaderSettingsRepository {
  const ReaderSettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  // Storage keys
  static const String _keyReaderSettings = 'reader_settings';
  static const String _keyReadingMode = 'reading_mode';
  static const String _keyKeepScreenOn = 'keep_screen_on';
  static const String _keyShowUI = 'show_ui';
  static const String _keyCorruptDataFlag = 'reader_settings_corrupt';

  // Error handling constants
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(milliseconds: 100);
  static const Duration _operationTimeout = Duration(seconds: 5);

  // Concurrent access protection
  static final Map<String, Completer<void>> _operationLocks = {};

  /// Log error with consistent formatting and context
  void _logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    developer.log(
      'ReaderSettingsRepository.$operation failed: $error',
      name: 'ReaderSettingsRepository',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Error level
    );
  }

  /// Log warning with consistent formatting
  void _logWarning(String operation, String message) {
    developer.log(
      'ReaderSettingsRepository.$operation warning: $message',
      name: 'ReaderSettingsRepository',
      level: 900, // Warning level
    );
  }

  /// Log info for debugging
  void _logInfo(String operation, String message) {
    developer.log(
      'ReaderSettingsRepository.$operation: $message',
      name: 'ReaderSettingsRepository',
      level: 800, // Info level
    );
  }

  /// Execute operation with concurrent access protection
  Future<T> _withLock<T>(String lockKey, Future<T> Function() operation) async {
    // Check if operation is already in progress
    if (_operationLocks.containsKey(lockKey)) {
      _logInfo(
          'getReaderSettings', 'Waiting for concurrent operation to complete');
      await _operationLocks[lockKey]!.future;
    }

    // Create new lock for this operation
    final completer = Completer<void>();
    _operationLocks[lockKey] = completer;

    try {
      final result = await operation().timeout(_operationTimeout);
      return result;
    } finally {
      // Always release the lock
      _operationLocks.remove(lockKey);
      completer.complete();
    }
  }

  /// Check if SharedPreferences is available and accessible
  Future<bool> _isSharedPreferencesAvailable() async {
    try {
      // Try a simple read operation to test availability
      _prefs.getString('_test_key');
      return true;
    } catch (e) {
      _logError('isSharedPreferencesAvailable', e);
      return false;
    }
  }

  /// Detect and handle corrupt data
  Future<bool> _isDataCorrupt() async {
    try {
      // Check if we've previously detected corrupt data
      final corruptFlag = _prefs.getBool(_keyCorruptDataFlag) ?? false;
      if (corruptFlag) {
        _logWarning(
            'isDataCorrupt', 'Previously detected corrupt data flag is set');
        return true;
      }

      // Try to parse the main settings JSON if it exists
      final settingsJson = _prefs.getString(_keyReaderSettings);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        try {
          ReaderSettings.fromJsonString(settingsJson);
          return false; // Data is valid
        } catch (e) {
          _logError('isDataCorrupt',
              'Failed to parse settings JSON: $settingsJson', null);
          await _markDataAsCorrupt();
          return true;
        }
      }

      // No JSON data found, not necessarily corrupt
      return false;
    } catch (e) {
      _logError('isDataCorrupt', e);
      return false; // Don't assume corrupt if we can't check properly
    }
  }

  /// Mark data as corrupt and clear it
  Future<void> _markDataAsCorrupt() async {
    try {
      await _prefs.setBool(_keyCorruptDataFlag, true);
      _logWarning('markDataAsCorrupt', 'Marked settings data as corrupt');
    } catch (e) {
      _logError('markDataAsCorrupt', e);
    }
  }



  /// Retry operation with exponential backoff
  Future<T> _retryOperation<T>(
    String operationName,
    Future<T> Function() operation,
    T fallbackValue,
  ) async {
    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        _logError('$operationName (attempt $attempt)', e);

        if (attempt == _maxRetryAttempts) {
          _logError('$operationName (final attempt)',
              'All retry attempts failed, using fallback');
          return fallbackValue;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(_retryDelay * attempt);
      }
    }

    return fallbackValue; // Should never reach here, but just in case
  }

  @override
  Future<ReaderSettings> getReaderSettings() async {
    // 🚀 OPTIMIZATION: Simplified fast path for reader loading
    try {
      // Try to get complete settings first (new format)
      final settingsJson = _prefs.getString(_keyReaderSettings);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        final settings = ReaderSettings.fromJsonString(settingsJson);
        return settings.validate();
      }

      // Fallback to individual keys for backward compatibility (old format)
      final readingModeString = _prefs.getString(_keyReadingMode);
      final keepScreenOn = _prefs.getBool(_keyKeepScreenOn);
      final showUI = _prefs.getBool(_keyShowUI);

      // Parse reading mode with fallback to default
      ReadingMode readingMode = ReadingMode.singlePage;
      if (readingModeString != null) {
        readingMode = ReadingMode.values.firstWhere(
          (mode) => mode.name == readingModeString,
          orElse: () => ReadingMode.singlePage,
        );
      }

      return ReaderSettings(
        readingMode: readingMode,
        keepScreenOn: keepScreenOn ?? false,
        showUI: showUI ?? true,
      );
    } catch (e) {
      // 🚀 OPTIMIZATION: Fast fallback to defaults on any error
      _logWarning('getReaderSettings', 'Using defaults due to error: $e');
      return const ReaderSettings();
    }
  }

  @override
  Future<void> saveReaderSettings(ReaderSettings settings) async {
    await _withLock('saveReaderSettings', () async {
      await _retryOperation(
        'saveReaderSettings',
        () async {
          _logInfo('saveReaderSettings', 'Saving reader settings: $settings');

          // Check if SharedPreferences is available
          if (!await _isSharedPreferencesAvailable()) {
            throw Exception('SharedPreferences is not available');
          }

          // Validate settings before saving
          final validatedSettings = settings.validate();
          if (validatedSettings != settings) {
            _logWarning('saveReaderSettings',
                'Settings were corrected during validation');
          }

          try {
            // Save as complete JSON object (new format)
            final settingsJson = validatedSettings.toJsonString();
            if (settingsJson.isEmpty || settingsJson == '{}') {
              throw Exception('Failed to serialize settings to JSON');
            }

            // Use atomic operations where possible
            final futures = <Future<bool>>[
              _prefs.setString(_keyReaderSettings, settingsJson),
              _prefs.setString(
                  _keyReadingMode, validatedSettings.readingMode.name),
              _prefs.setBool(_keyKeepScreenOn, validatedSettings.keepScreenOn),
              _prefs.setBool(_keyShowUI, validatedSettings.showUI),
            ];

            // Clear corrupt flag if it was set
            if (_prefs.getBool(_keyCorruptDataFlag) == true) {
              futures.add(_prefs.remove(_keyCorruptDataFlag));
            }

            final results = await Future.wait(futures);

            // Check if all operations succeeded
            if (results.any((result) => result != true)) {
              throw Exception('Some save operations failed');
            }

            _logInfo(
                'saveReaderSettings', 'Successfully saved reader settings');
          } catch (e, stackTrace) {
            _logError('saveReaderSettings', e, stackTrace);

            // Check for specific error types
            if (e is FileSystemException) {
              _logError('saveReaderSettings',
                  'File system error - possibly low storage space');
            } else if (e is TimeoutException) {
              _logError('saveReaderSettings', 'Operation timed out');
            }

            rethrow; // Re-throw to trigger retry mechanism
          }
        },
        null, // No meaningful fallback for save operations
      );
    });
  }

  @override
  Future<void> saveReadingMode(ReadingMode mode) async {
    await _withLock('saveReadingMode', () async {
      await _retryOperation(
        'saveReadingMode',
        () async {
          _logInfo('saveReadingMode', 'Saving reading mode: ${mode.name}');

          try {
            // Get current settings and update only reading mode
            final currentSettings = await getReaderSettings();
            final updatedSettings = currentSettings.copyWith(readingMode: mode);
            await saveReaderSettings(updatedSettings);

            _logInfo('saveReadingMode', 'Successfully saved reading mode');
          } catch (e, stackTrace) {
            _logError('saveReadingMode', e, stackTrace);
            rethrow; // Re-throw to trigger retry mechanism
          }
        },
        null, // No meaningful fallback for save operations
      );
    });
  }

  @override
  Future<void> saveKeepScreenOn(bool keepScreenOn) async {
    await _withLock('saveKeepScreenOn', () async {
      await _retryOperation(
        'saveKeepScreenOn',
        () async {
          _logInfo('saveKeepScreenOn', 'Saving keep screen on: $keepScreenOn');

          try {
            // Get current settings and update only keep screen on
            final currentSettings = await getReaderSettings();
            final updatedSettings =
                currentSettings.copyWith(keepScreenOn: keepScreenOn);
            await saveReaderSettings(updatedSettings);

            _logInfo('saveKeepScreenOn',
                'Successfully saved keep screen on setting');
          } catch (e, stackTrace) {
            _logError('saveKeepScreenOn', e, stackTrace);
            rethrow; // Re-throw to trigger retry mechanism
          }
        },
        null, // No meaningful fallback for save operations
      );
    });
  }

  @override
  Future<void> saveShowUI(bool showUI) async {
    await _withLock('saveShowUI', () async {
      await _retryOperation(
        'saveShowUI',
        () async {
          _logInfo('saveShowUI', 'Saving show UI: $showUI');

          try {
            // Get current settings and update only show UI
            final currentSettings = await getReaderSettings();
            final updatedSettings = currentSettings.copyWith(showUI: showUI);
            await saveReaderSettings(updatedSettings);

            _logInfo('saveShowUI', 'Successfully saved show UI setting');
          } catch (e, stackTrace) {
            _logError('saveShowUI', e, stackTrace);
            rethrow; // Re-throw to trigger retry mechanism
          }
        },
        null, // No meaningful fallback for save operations
      );
    });
  }

  @override
  Future<void> resetToDefaults() async {
    await _withLock('resetToDefaults', () async {
      await _retryOperation(
        'resetToDefaults',
        () async {
          _logInfo('resetToDefaults', 'Resetting reader settings to defaults');

          // Check if SharedPreferences is available
          if (!await _isSharedPreferencesAvailable()) {
            throw Exception('SharedPreferences is not available');
          }

          try {
            // Remove all reader settings keys including corrupt flag
            final futures = [
              _prefs.remove(_keyReaderSettings),
              _prefs.remove(_keyReadingMode),
              _prefs.remove(_keyKeepScreenOn),
              _prefs.remove(_keyShowUI),
              _prefs.remove(_keyCorruptDataFlag),
            ];

            await Future.wait(futures);

            _logInfo('resetToDefaults',
                'Successfully reset reader settings to defaults');
          } catch (e, stackTrace) {
            _logError('resetToDefaults', e, stackTrace);

            // Check for specific error types
            if (e is FileSystemException) {
              _logError('resetToDefaults', 'File system error during reset');
            } else if (e is TimeoutException) {
              _logError('resetToDefaults', 'Reset operation timed out');
            }

            rethrow; // Re-throw to trigger retry mechanism
          }
        },
        null, // No meaningful fallback for reset operations
      );
    });
  }

  /// Get diagnostic information about the repository state
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final isAvailable = await _isSharedPreferencesAvailable();
      final isCorrupt = await _isDataCorrupt();
      final hasSettings = _prefs.containsKey(_keyReaderSettings);
      final hasLegacyKeys = _prefs.containsKey(_keyReadingMode) ||
          _prefs.containsKey(_keyKeepScreenOn) ||
          _prefs.containsKey(_keyShowUI);

      return {
        'isSharedPreferencesAvailable': isAvailable,
        'isDataCorrupt': isCorrupt,
        'hasSettings': hasSettings,
        'hasLegacyKeys': hasLegacyKeys,
        'activeLocks': _operationLocks.keys.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logError('getDiagnosticInfo', e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
