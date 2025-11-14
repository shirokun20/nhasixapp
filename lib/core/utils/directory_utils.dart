import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// Utility class for smart directory detection across different Android devices
/// Handles various Download folder names and storage configurations
class DirectoryUtils {
  static final Logger _logger = Logger();

  /// Smart Downloads directory detection
  /// Tries multiple possible Downloads folder names and locations
  /// Handles different Android device configurations and languages
  static Future<String> getDownloadsDirectory() async {
    try {
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
    } catch (e) {
      _logger.e('DirectoryUtils: Error detecting Downloads directory: $e');

      // Emergency fallback: use app documents
      final documentsDir = await getApplicationDocumentsDirectory();
      final emergencyDir = Directory(path.join(documentsDir.path, 'downloads'));
      if (!await emergencyDir.exists()) {
        await emergencyDir.create(recursive: true);
      }
      _logger.w(
          'DirectoryUtils: Using emergency fallback directory: ${emergencyDir.path}');
      return emergencyDir.path;
    }
  }

  /// Find nhasix backup folder automatically in Downloads directory
  /// Used by offline content screen for automatic backup detection
  static Future<String?> findNhasixBackupFolder() async {
    try {
      debugPrint('DIRECTORY_UTILS: Starting findNhasixBackupFolder...');
      final downloadsPath = await getDownloadsDirectory();
      debugPrint(
          'DIRECTORY_UTILS: getDownloadsDirectory() returned: $downloadsPath');

      final nhasixPath = path.join(downloadsPath, 'nhasix');
      debugPrint('DIRECTORY_UTILS: Looking for nhasix folder at: $nhasixPath');

      final nhasixDir = Directory(nhasixPath);
      final exists = await nhasixDir.exists();
      debugPrint('DIRECTORY_UTILS: nhasix directory exists: $exists');

      if (exists) {
        _logger.d('DirectoryUtils: Found nhasix backup folder: $nhasixPath');
        debugPrint('DIRECTORY_UTILS: Found nhasix backup folder: $nhasixPath');
        return nhasixPath;
      }

      debugPrint(
          'DIRECTORY_UTILS: nhasix backup folder not found in Downloads');
      _logger.d('DirectoryUtils: nhasix backup folder not found in Downloads');
      return null;
    } catch (e) {
      debugPrint('DIRECTORY_UTILS: Error finding nhasix backup folder: $e');
      _logger.w('DirectoryUtils: Error finding nhasix backup folder: $e');
      return null;
    }
  }
}
