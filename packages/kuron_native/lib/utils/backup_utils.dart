import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('Import Error: $e');
      return null;
    }
  }
}
