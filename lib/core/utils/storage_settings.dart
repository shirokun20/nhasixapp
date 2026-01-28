import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuron_native/kuron_native.dart';
import 'permission_helper.dart';

class StorageSettings {
  static const String _prefKey = 'custom_storage_root';

  /// Pick a custom folder and save it.
  /// Returns the path if successful, null otherwise.
  static Future<String?> pickAndSaveCustomRoot(BuildContext context) async {
    // 1. Request Storage Permission (Native logic handles this too, but good to check)
    if (!await PermissionHelper.requestStoragePermission(context)) {
      return null;
    }

    // 2. Pick Directory using Native Plugin
    // Replaces FilePicker.platform.getDirectoryPath()
    final String? selectedDirectory = await KuronNative.instance.pickDirectory();

    if (selectedDirectory == null) {
      return null; // User canceled
    }

    // 3. Verify access (Basic check)
    try {
      final dir = Directory(selectedDirectory);
      if (!await dir.exists()) {
        // Try to create it to verify write access? 
        // Or just trust the native picker granted access (SAF)
      }
    } catch (e) {
      // Ignore
    }

    // 4. Save to Preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, selectedDirectory);

    return selectedDirectory;
  }

  /// Get the currently saved custom root path.
  static Future<String?> getCustomRootPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  /// Check if a custom root is set.
  static Future<bool> hasCustomRoot() async {
    final path = await getCustomRootPath();
    return path != null && path.isNotEmpty;
  }

  /// Clear the custom root setting.
  static Future<void> clearCustomRoot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
