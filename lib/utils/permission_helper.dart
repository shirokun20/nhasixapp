import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

/// Helper class untuk handle permissions dengan user-friendly approach
class PermissionHelper {
  static final Logger _logger = Logger();

  /// Request storage permission dengan user guidance
  static Future<bool> requestStoragePermission(BuildContext? context) async {
    try {
      _logger.i('Requesting storage permission...');

      // Check current permission status
      final storageStatus = await Permission.storage.status;
      final manageStatus = await Permission.manageExternalStorage.status;

      _logger.i('Storage permission status: $storageStatus');
      _logger.i('Manage external storage status: $manageStatus');

      // If already granted, return true
      if (storageStatus.isGranted || manageStatus.isGranted) {
        _logger.i('Storage permission already granted');
        return true;
      }

      // Show explanation dialog if context is available
      if (context != null && context.mounted) {
        final shouldRequest = await _showPermissionDialog(context);
        if (!shouldRequest) {
          _logger.i('User declined permission request');
          return false;
        }
      }

      // Request storage permission first
      if (!storageStatus.isGranted) {
        _logger.i('Requesting storage permission...');
        final result = await Permission.storage.request();

        if (result.isGranted) {
          _logger.i('Storage permission granted');
          return true;
        }

        _logger.w('Storage permission denied: $result');
      }

      // For Android 11+ (API 30+), try manage external storage
      if (Platform.isAndroid) {
        _logger.i('Requesting manage external storage permission...');
        final manageResult = await Permission.manageExternalStorage.request();

        if (manageResult.isGranted) {
          _logger.i('Manage external storage permission granted');
          return true;
        }

        _logger.w('Manage external storage permission denied: $manageResult');
      }

      // If all failed, show settings dialog
      if (context != null && context.mounted) {
        await _showSettingsDialog(context);
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Show permission explanation dialog
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to download files to your device. '
              'Files will be saved to the Downloads/nhasix folder.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show settings dialog when permission is permanently denied
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to download files. '
          'Please grant storage permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    try {
      final storageStatus = await Permission.storage.status;
      final manageStatus = await Permission.manageExternalStorage.status;

      return storageStatus.isGranted || manageStatus.isGranted;
    } catch (e) {
      _logger.e('Error checking storage permission: $e');
      return false;
    }
  }

  /// Test if we can actually write to storage
  static Future<bool> canWriteToStorage() async {
    try {
      const testPath = '/storage/emulated/0/Download/nhasix';
      final testDir = Directory(testPath);

      // Try to create test directory
      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }

      // Try to create test file
      final testFile = File('$testPath/test.txt');
      await testFile.writeAsString('test');

      // Clean up test file
      if (await testFile.exists()) {
        await testFile.delete();
      }

      _logger.i('Storage write test successful');
      return true;
    } catch (e) {
      _logger.e('Storage write test failed: $e');
      return false;
    }
  }
}
