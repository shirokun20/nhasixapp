import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuron_native/kuron_native.dart';
import 'permission_helper.dart';

class StorageSettings {
  static const String _prefKey = 'custom_storage_root';

  // Memory cache to prevent repeated SharedPreferences reads
  // and ensure persistence even if SharedPreferences has issues
  static String? _cachedCustomRoot;

  // Pick a custom folder and save it.
  // Returns the path if successful, null otherwise.
  ///
  // Note: Uses SAF (Storage Access Framework) which doesn't require storage permissions.
  // The native picker handles all security and access control.
  static Future<String?> pickAndSaveCustomRoot(BuildContext context) async {
    // 1. Ensure storage permission granted first (MANAGE_EXTERNAL_STORAGE)
    //    SAF picker needs it to resolve content URI to an accessible path.
    final hasPermission =
        await PermissionHelper.requestStoragePermission(context);
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Storage permission required to select a download folder.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return null;
    }

    // 2. Pick Directory using Native Plugin (SAF)
    final String? selectedDirectory =
        await KuronNative.instance.pickDirectory();

    if (selectedDirectory == null) {
      return null; // User canceled
    }

    // 3. If native returned sentinel, use in-app directory picker
    String? resolvedPath;
    if (!context.mounted) return null;
    if (selectedDirectory == '__HSH_PICKER__') {
      resolvedPath = await _showDirectoryPicker(context);
    } else {
      resolvedPath = _resolveContentUri(selectedDirectory);
    }

    if (resolvedPath == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please select a subfolder (e.g. "Download"), not the root directory.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return null;
    }

    // 4. Verify we can actually access this path
    try {
      final dir = Directory(resolvedPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      Logger().w('📁 STORAGE_SETTINGS: Cannot access selected path: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cannot access this folder. Please grant storage permission first, then try again.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      _cachedCustomRoot = null;
      return null;
    }

    // Save resolved path to Preferences
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_prefKey, resolvedPath);

    Logger().d('📁 STORAGE_SETTINGS: Saving custom root: $resolvedPath');
    Logger().d('📁 STORAGE_SETTINGS: Save result: $success');

    // Verify it was saved
    final verified = prefs.getString(_prefKey);
    Logger().d('📁 STORAGE_SETTINGS: Verification read: $verified');
    Logger().d('📁 STORAGE_SETTINGS: Match: ${verified == resolvedPath}');

    // Cache in memory for faster subsequent access
    _cachedCustomRoot = resolvedPath;
    Logger().d('📁 STORAGE_SETTINGS: Cached in memory: $_cachedCustomRoot');

    return resolvedPath;
  }

  // Get the currently saved custom root path.
  static Future<String?> getCustomRootPath() async {
    // Return cache if available
    if (_cachedCustomRoot != null) {
      Logger()
          .d('📁 STORAGE_SETTINGS: returning cached path: $_cachedCustomRoot');
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
      Logger()
          .d('📁 STORAGE_SETTINGS: Cached path in memory: $_cachedCustomRoot');
    }

    return path;
  }

  // Check if a custom root is set.
  static Future<bool> hasCustomRoot() async {
    final path = await getCustomRootPath();
    final result = path != null && path.isNotEmpty;
    Logger().d('📁 STORAGE_SETTINGS: hasCustomRoot = $result (path: $path)');
    return result;
  }

  // Clear the custom root setting.
  static Future<void> clearCustomRoot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _cachedCustomRoot = null; // Clear cache
    Logger().d('📁 STORAGE_SETTINGS: Cleared custom root and cache');
  }

  /// Show in-app directory picker (when MANAGE_EXTERNAL_STORAGE is granted).
  /// Lets user browse filesystem and pick any writable folder.
  static Future<String?> _showDirectoryPicker(BuildContext context) async {
    // Start from /storage/emulated/0/
    return _showDirPickerRecursive(context, '/storage/emulated/0');
  }

  static Future<String?> _showDirPickerRecursive(
    BuildContext context,
    String currentPath,
  ) async {
    if (!context.mounted) return null;

    final dir = Directory(currentPath);
    List<FileSystemEntity> entries;
    try {
      entries = await dir.list().toList();
    } catch (_) {
      return null;
    }

    final subdirs = <Directory>[];
    for (final entry in entries) {
      if (entry is Directory && !entry.path.startsWith('.')) {
        try {
          final stat = await entry.stat();
          if (stat.type == FileSystemEntityType.directory) {
            subdirs.add(entry);
          }
        } catch (_) {}
      }
    }
    subdirs.sort((a, b) => a.path.compareTo(b.path));

    if (!context.mounted) return null;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pick folder:\n$currentPath',
            style: const TextStyle(fontSize: 14)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: subdirs.isEmpty
              ? const Center(child: Text('No subfolders'))
              : ListView.builder(
                  itemCount: subdirs.length,
                  itemBuilder: (ctx, i) {
                    final sub = subdirs[i];
                    final name = sub.path.split('/').last;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder, size: 20),
                      title: Text(name, style: const TextStyle(fontSize: 14)),
                      onTap: () => Navigator.of(ctx).pop(sub.path),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('__UP__'),
            child: const Text('⬆ Go up'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(currentPath),
            child: const Text('Select this folder'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == null) return null; // cancelled
    if (result == '__UP__') {
      // Go to parent
      if (!context.mounted) return null;
      final parent = Directory(currentPath).parent.path;
      if (parent == currentPath) return null;
      return _showDirPickerRecursive(context, parent);
    }
    if (result == currentPath) return currentPath; // selected this folder
    if (!context.mounted) return null;
    // Navigate into subdirectory
    return _showDirPickerRecursive(context, result);
  }

  // Convert content:// URI to a usable filesystem path.
  // Android SAF returns content:// URIs; we need a real path for Directory/File ops.
  static String? _resolveContentUri(String uriString) {
    if (!uriString.startsWith('content://')) {
      return uriString; // Already a filesystem path
    }

    // Parse content URI path: content://com.android.../tree/primary:Download/Kuron
    // Extract the part after "primary:" or "primary%3A"
    try {
      final uri = Uri.parse(uriString);
      final path = uri.path;

      String? resolved;
      if (path.contains('primary:')) {
        resolved =
            '/storage/emulated/0/${path.substring(path.indexOf('primary:') + 8)}';
      } else if (path.contains('primary%3A')) {
        resolved =
            '/storage/emulated/0/${path.substring(path.indexOf('primary%3A') + 10)}';
      }

      if (resolved != null) {
        // Clean trailing slashes
        resolved = resolved.replaceAll(RegExp(r'/+$'), '');
        return resolved;
      }
    } catch (_) {}

    Logger()
        .w('📁 STORAGE_SETTINGS: Could not resolve content URI: $uriString');
    return null;
  }
}
