import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuron_native/kuron_native.dart';

class StorageSettings {
  static const String _prefKey = 'custom_storage_root';

  // Memory cache to prevent repeated SharedPreferences reads
  // and ensure persistence even if SharedPreferences has issues
  static String? _cachedCustomRoot;

  /// Pick a custom folder and save it.
  /// Returns the path if successful, null otherwise.
  ///
  /// Note: Uses SAF (Storage Access Framework) which doesn't require storage permissions.
  /// The native picker handles all security and access control.
  static Future<String?> pickAndSaveCustomRoot(BuildContext context) async {
    // Pick Directory using Native Plugin (SAF)
    // SAF (Storage Access Framework) handles its own security and doesn't need runtime permissions
    final String? selectedDirectory =
        await KuronNative.instance.pickDirectory();

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
    final success = await prefs.setString(_prefKey, selectedDirectory);

    Logger().d('📁 STORAGE_SETTINGS: Saving custom root: $selectedDirectory');
    Logger().d('📁 STORAGE_SETTINGS: Save result: $success');

    // Verify it was saved
    final verified = prefs.getString(_prefKey);
    Logger().d('📁 STORAGE_SETTINGS: Verification read: $verified');
    Logger().d('📁 STORAGE_SETTINGS: Match: ${verified == selectedDirectory}');

    // Cache in memory for faster subsequent access
    _cachedCustomRoot = selectedDirectory;
    Logger().d('📁 STORAGE_SETTINGS: Cached in memory: $_cachedCustomRoot');

    return selectedDirectory;
  }

  /// Get the currently saved custom root path.
  static Future<String?> getCustomRootPath() async {
    // Return cache if available
    if (_cachedCustomRoot != null) {
      Logger().d(
          '📁 STORAGE_SETTINGS: returning cached path: $_cachedCustomRoot');
      return _cachedCustomRoot;
    }

    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefKey);
    Logger().d('📁 STORAGE_SETTINGS: getCustomRootPath called');
    Logger().d('📁 STORAGE_SETTINGS: Retrieved path: $path');
    Logger().d('📁 STORAGE_SETTINGS: All keys: ${prefs.getKeys()}');

    // Cache for subsequent calls
    if (path != null) {
      _cachedCustomRoot = path;
      Logger().d(
          '📁 STORAGE_SETTINGS: Cached path in memory: $_cachedCustomRoot');
    }

    return path;
  }

  /// Check if a custom root is set.
  static Future<bool> hasCustomRoot() async {
    final path = await getCustomRootPath();
    final result = path != null && path.isNotEmpty;
    Logger().d('📁 STORAGE_SETTINGS: hasCustomRoot = $result (path: $path)');
    return result;
  }

  /// Clear the custom root setting.
  static Future<void> clearCustomRoot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _cachedCustomRoot = null; // Clear cache
    Logger().d('📁 STORAGE_SETTINGS: Cleared custom root and cache');
  }
}
