import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuron_native/kuron_native.dart';


class StorageSettings {
  static const String _prefKey = 'custom_storage_root';

  /// Pick a custom folder and save it.
  /// Returns the path if successful, null otherwise.
  /// 
  /// Note: Uses SAF (Storage Access Framework) which doesn't require storage permissions.
  /// The native picker handles all security and access control.
  static Future<String?> pickAndSaveCustomRoot(BuildContext context) async {
    // Pick Directory using Native Plugin (SAF)
    // SAF (Storage Access Framework) handles its own security and doesn't need runtime permissions
    final String? selectedDirectory = await KuronNative.instance.pickDirectory();

    if (selectedDirectory == null) {
      return null; // User canceled
    }

    // Verify access (Basic check)
    try {
      final dir = Directory(selectedDirectory);
      if (!await dir.exists()) {
        // Trust the native picker granted access (SAF)
        // Directory might not "exist" in traditional sense but SAF grants access
      }
    } catch (e) {
      // Ignore - SAF handles access control
    }

    // Save to Preferences
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
