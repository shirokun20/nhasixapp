import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Clear SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  for (final key in keys) {
    if (key.startsWith('config_version_') ||
        key == 'config_manifest_version' ||
        key == 'installed_source_ids') {
      await prefs.remove(key);
      if (kDebugMode) {
        print('Removed SharedPreferences key: $key');
      }
    }
  }

  // 2. Clear AppDocDir/configs
  final dir = await getApplicationDocumentsDirectory();
  final configsDir = Directory('${dir.path}/configs');
  if (await configsDir.exists()) {
    await configsDir.delete(recursive: true);
    if (kDebugMode) {
      print('Deleted configs directory at: ${configsDir.path}');
    }
  } else {
    if (kDebugMode) {
      print('No configs directory found at: ${configsDir.path}');
    }
  }

  if (kDebugMode) {
    print('Config cache cleared successfully.');
  }
}
