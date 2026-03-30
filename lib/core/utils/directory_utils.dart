import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'package:logger/logger.dart';
import 'package:nhasixapp/core/utils/storage_settings.dart';

/// Utility class for smart directory detection across different Android devices
/// Handles various Download folder names and storage configurations
class DirectoryUtils {
  static final Logger _logger = Logger();

  /// Smart Downloads directory detection
  /// Tries multiple possible Downloads folder names and locations
  /// Handles different Android device configurations and languages
  static Future<String> getDownloadsDirectory() async {
    try {
      // PRIORITY 1: Check custom storage root first
      if (await StorageSettings.hasCustomRoot()) {
        final customPath = await StorageSettings.getCustomRootPath();
        if (customPath != null && customPath.isNotEmpty) {
          final customDir = Directory(customPath);
          // Trust the setting regardless of immediate existence check (similar to DownloadService fix)
          if (!await customDir.exists()) {
            _logger.w(
                'DirectoryUtils: Custom storage root set but does not exist: $customPath. Using it anyway.');
          } else {
            _logger.i('DirectoryUtils: Using custom storage root: $customPath');
          }
          return customPath;
        }
      }

      /*
      // First, try to get external storage directory
      Directory? externalDir;
      try {
        externalDir = await getExternalStorageDirectory();
      } catch (e) {
        _logger
            .w('DirectoryUtils: Could not get external storage directory: $e');
      }

      if (externalDir != null) {
        // Try to find Downloads folder in external storage root
        final externalRoot = externalDir.path.split('/Android')[0];

        // Common Downloads folder names in different languages
        final downloadsFolderNames = [
          'Download', // English (most common)
          'Downloads', // English alternative
          'Unduhan', // Indonesian
          'Descargas', // Spanish
          'Téléchargements', // French
          'Downloads', // German uses English
          'ダウンロード', // Japanese
        ];

        // Try each possible Downloads folder
        for (final folderName in downloadsFolderNames) {
          final downloadsDir = Directory(path.join(externalRoot, folderName));
          if (await downloadsDir.exists()) {
            _logger.d(
                'DirectoryUtils: Found Downloads directory: ${downloadsDir.path}');
            return downloadsDir.path;
          }
        }

        // If no Downloads folder found, create one in external storage root
        final defaultDownloadsDir =
            Directory(path.join(externalRoot, 'Download'));
        try {
          if (!await defaultDownloadsDir.exists()) {
            await defaultDownloadsDir.create(recursive: true);
            _logger.i(
                'DirectoryUtils: Created Downloads directory: ${defaultDownloadsDir.path}');
          }
          return defaultDownloadsDir.path;
        } catch (e) {
          _logger.w(
              'DirectoryUtils: Could not create Downloads directory in external storage: $e');
        }
      }

      // Fallback 1: Try hardcoded common paths
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/emulated/0/Unduhan',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (final commonPath in commonPaths) {
        final dir = Directory(commonPath);
        if (await dir.exists()) {
          _logger.d(
              'DirectoryUtils: Found Downloads directory at common path: $commonPath');
          return commonPath;
        }
      }

      // Fallback 2: Use app-specific external storage
      if (externalDir != null) {
        final appDownloadsDir =
            Directory(path.join(externalDir.path, 'downloads'));
        if (!await appDownloadsDir.exists()) {
          await appDownloadsDir.create(recursive: true);
        }
        _logger.i(
            'DirectoryUtils: Using app-specific downloads directory: ${appDownloadsDir.path}');
        return appDownloadsDir.path;
      }

      // Fallback 3: Use application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsDownloadsDir =
          Directory(path.join(documentsDir.path, 'downloads'));
      if (!await documentsDownloadsDir.exists()) {
        await documentsDownloadsDir.create(recursive: true);
      }
      _logger.i(
          'DirectoryUtils: Using app documents downloads directory: ${documentsDownloadsDir.path}');
      return documentsDownloadsDir.path;
      */
      _logger.e('DirectoryUtils: No custom storage root found!');
      debugPrint(
          '📁 DIRECTORY_UTILS: CRITICAL - No custom storage root selected');
      debugPrint(
          '📁 DIRECTORY_UTILS: This should not happen if user previously set storage location');
      throw Exception(
          'No custom storage root selected. Please select a storage location in settings.');
    } catch (e) {
      _logger.e('DirectoryUtils: Error detecting Downloads directory: $e');

      /*
      // Emergency fallback: use app documents
      final documentsDir = await getApplicationDocumentsDirectory();
      final emergencyDir = Directory(path.join(documentsDir.path, 'downloads'));
      if (!await emergencyDir.exists()) {
        await emergencyDir.create(recursive: true);
      }
      _logger.w(
          'DirectoryUtils: Using emergency fallback directory: ${emergencyDir.path}');
      return emergencyDir.path;
      */
      rethrow;
    }
  }

  /// Find nhasix backup folder automatically
  /// Priority:
  /// 1. Check custom storage root (from StorageSettings) first
  /// 2. Fallback to Downloads/nhasix for backward compatibility
  /// Used by offline content screen for automatic backup detection
  static Future<String?> findNhasixBackupFolder() async {
    try {
      debugPrint('DIRECTORY_UTILS: Starting findNhasixBackupFolder...');

      // PRIORITY 1: Check custom storage root first
      final customRoot = await StorageSettings.getCustomRootPath();
      if (customRoot != null && customRoot.isNotEmpty) {
        debugPrint('DIRECTORY_UTILS: Found custom storage root: $customRoot');
        final customDir = Directory(customRoot);
        final customExists = await customDir.exists();
        debugPrint('DIRECTORY_UTILS: Custom storage exists: $customExists');

        if (customExists) {
          // Check if 'nhasix' subfolder exists inside custom root (Standard structure)
          final nhasixInCustom = Directory(path.join(customRoot, 'nhasix'));
          if (await nhasixInCustom.exists()) {
            _logger.d(
                'DirectoryUtils: Found nhasix folder in custom root: ${nhasixInCustom.path}');
            debugPrint(
                'DIRECTORY_UTILS: Found nhasix folder in custom root: ${nhasixInCustom.path}');
            return nhasixInCustom.path;
          }

          // If 'nhasix' subfolder doesn't exist, assume custom root IS the backup folder (User selected the 'nhasix' folder itself or a custom named folder)
          _logger.d(
              'DirectoryUtils: nhasix subfolder not found, using custom root as base: $customRoot');
          debugPrint(
              'DIRECTORY_UTILS: nhasix subfolder not found, using custom root as base: $customRoot');
          return customRoot;
        } else {
          debugPrint(
              'DIRECTORY_UTILS: Custom storage root does not exist, falling back to Downloads/nhasix');
        }
      } else {
        debugPrint(
            'DIRECTORY_UTILS: No custom storage root set, checking Downloads/nhasix');
      }

      // PRIORITY 2: Fallback to Downloads/nhasix for backward compatibility
      final downloadsPath = await getDownloadsDirectory();
      debugPrint(
          'DIRECTORY_UTILS: getDownloadsDirectory() returned: $downloadsPath');

      final nhasixPath = path.join(downloadsPath, 'nhasix');
      debugPrint('DIRECTORY_UTILS: Looking for nhasix folder at: $nhasixPath');

      final nhasixDir = Directory(nhasixPath);
      final exists = await nhasixDir.exists();
      debugPrint('DIRECTORY_UTILS: Downloads/nhasix directory exists: $exists');

      if (exists) {
        _logger.d(
            'DirectoryUtils: Found nhasix backup folder in Downloads: $nhasixPath');
        debugPrint(
            'DIRECTORY_UTILS: Found nhasix backup folder in Downloads: $nhasixPath');
        return nhasixPath;
      }

      debugPrint('DIRECTORY_UTILS: nhasix backup folder not found anywhere');
      _logger.d('DirectoryUtils: nhasix backup folder not found');
      return null;
    } catch (e) {
      debugPrint('DIRECTORY_UTILS: Error finding nhasix backup folder: $e');
      _logger.w('DirectoryUtils: Error finding nhasix backup folder: $e');
      return null;
    }
  }
}
