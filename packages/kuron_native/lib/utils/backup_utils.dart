import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class BackupUtils {
  /// Save JSON string to a file in the user's Downloads or Documents directory.
  /// Returns the path if successful, null otherwise.
  static Future<String?> exportJson(String jsonContent, String fileName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        // Fallback if Download folder is not accessible (though typically it is)
        if (!directory.existsSync()) {
             directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final path = '${directory?.path}/$fileName';
      final file = File(path);
      await file.writeAsString(jsonContent);
      return path;
    } catch (e) {
      debugPrint('Export Error: $e');
      return null;
    }
  }

  /// Pick a JSON file and return its content.
  static Future<String?> importJson() async {
    // Deprecated: Moving to native picker or KuronNative based implementation.
    // FilePicker dependency has been removed.
    debugPrint('BackupUtils.importJson is deprecated and non-functional without file_picker.');
    return null;
  }
}
