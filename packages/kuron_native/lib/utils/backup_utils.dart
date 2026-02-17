import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../kuron_native.dart'; // Access KuronNative singleton

class BackupUtils {
  /// Save JSON string to a file in the specified directory or user's Downloads.
  /// Returns the path if successful, null otherwise.
  ///
  /// [jsonContent] - The JSON string to save
  /// [fileName] - Name of the file to create
  /// [customDirectory] - Optional custom directory path. If null, uses default Downloads folder
  static Future<String?> exportJson(
    String jsonContent,
    String fileName, {
    String? customDirectory,
  }) async {
    try {
      Directory? directory;

      if (customDirectory != null && customDirectory.isNotEmpty) {
        // Use custom directory if provided (e.g., from StorageSettings)
        directory = Directory(customDirectory);
      } else if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final path = '${directory?.path}/$fileName';
      final file = File(path);
      await file.writeAsString(jsonContent);
      debugPrint('Export Success: Saved $fileName to ${directory?.path}');
      return path;
    } catch (e) {
      debugPrint('Export Error: $e');
      return null;
    }
  }

  /// Pick a directory using native picker and read a JSON backup file from it.
  /// Returns the JSON content as string if successful, null otherwise.
  ///
  /// [fileName] - Name of the backup file to read (default: 'backup.json')
  static Future<String?> importJson({String fileName = 'backup.json'}) async {
    try {
      // Use native directory picker (Android SAF compatible)
      final directoryPath = await KuronNative.instance.pickDirectory();

      if (directoryPath == null) {
        debugPrint('Import cancelled by user');
        return null;
      }

      // Read the backup file from selected directory
      final file = File('$directoryPath/$fileName');

      if (!await file.exists()) {
        debugPrint('Import Error: $fileName not found in selected directory');
        return null;
      }

      final content = await file.readAsString();
      debugPrint('Import Success: Read $fileName from $directoryPath');
      return content;
    } catch (e) {
      debugPrint('Import Error: $e');
      return null;
    }
  }
}
