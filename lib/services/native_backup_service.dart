import 'package:flutter/services.dart';

class NativeBackupService {
  static const MethodChannel _channel = MethodChannel('id.nhasix.app/backup');

  /// Creates a backup zip file containing the database and settings.
  /// 
  /// Returns the absolute path to the created zip file.
  Future<String> createBackup({
    required String dbPath,
    required String settingsJson,
  }) async {
    final result = await _channel.invokeMethod<String>('createBackup', {
      'dbPath': dbPath,
      'settingsJson': settingsJson,
    });
    return result ?? '';
  }

  /// RESTORE FLOW:
  /// 1. Call `pickBackupFile()` to let user select a file.
  /// 2. Get the URI string.
  /// 3. Call `extractBackupData(uri)` to process it.

  /// Launches the native file picker to select a backup file (zip).
  /// 
  /// Returns the content URI of the selected file.
  Future<String?> pickBackupFile() async {
    final result = await _channel.invokeMethod<String>('pickBackupFile');
    return result;
  }

  /// Extracts the backup file and returns the paths/content.
  /// 
  /// Returns a map containing:
  /// - `settingsJson`: The content of the settings.json file.
  /// - `dbPath`: The path to the extracted database file (in cache).
  Future<Map<String, dynamic>> extractBackupData(String contentUri) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('extractBackupData', {
      'contentUri': contentUri,
    });
    
    if (result == null) return {};
    
    return result.cast<String, dynamic>();
  }
}
