import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';


import '../constants/app_constants.dart';
import 'package:kuron_core/kuron_core.dart'; // Import ContentMetadata
import 'storage_settings.dart';

/// Utility class for download-related storage operations
///
/// Extracted from DownloadBloc to reduce complexity and promote reusability.
/// Contains methods for directory detection, file management, and metadata reading.
class DownloadStorageUtils {
  DownloadStorageUtils._();

  static final Logger _logger = Logger();

  /// Smart Downloads directory detection
  /// Priority:
  /// 1. Check custom storage root (from StorageSettings) first
  /// 2. Fallback to Downloads folder detection for backward compatibility
  /// Tries multiple possible Downloads folder names and locations
  static Future<String> getDownloadsDirectory() async {
    try {
      // PRIORITY 1: Check custom storage root first
      final customRoot = await StorageSettings.getCustomRootPath();
      if (customRoot != null && customRoot.isNotEmpty) {
        final customDir = Directory(customRoot);
        if (await customDir.exists()) {
          _logger.d('Using custom storage root: $customRoot');
          return customRoot;
        } else {
          _logger.w('Custom storage root set but does not exist: $customRoot, falling back to Downloads');
        }
      }
      
      /*
      // PRIORITY 2: Fallback to Downloads folder for backward compatibility
      // First, try to get external storage directory
      Directory? externalDir;
      try {
        externalDir = await getExternalStorageDirectory();
      } catch (e) {
        _logger.w('Could not get external storage directory: $e');
      }

      if (externalDir != null) {
        // Try to find Downloads folder in external storage root
        final externalRoot = externalDir.path.split('/Android')[0];

        // Common Downloads folder names (English, Indonesian, Spanish, etc.)
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
            _logger.d('Found Downloads directory: ${downloadsDir.path}');
            return downloadsDir.path;
          }
        }

        // If no Downloads folder found, check for app-specific external storage
        final appDownloadsDir =
            Directory(path.join(externalDir.path, 'downloads'));
        if (await appDownloadsDir.exists()) {
          _logger.d(
              'Using app-specific downloads directory: ${appDownloadsDir.path}');
          return appDownloadsDir.path;
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
          _logger.d('Found Downloads directory at common path: $commonPath');
          return commonPath;
        }
      }

      // Fallback 2: Use application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsDownloadsDir =
          Directory(path.join(documentsDir.path, 'downloads'));
      _logger.d(
          'Using app documents downloads directory: ${documentsDownloadsDir.path}');
      return documentsDownloadsDir.path;
      */
      throw Exception('No custom storage root selected. Please select a storage location in settings.');
    } catch (e) {
      _logger.e('Error detecting Downloads directory: $e');

      /*
      // Emergency fallback: use app documents
      final documentsDir = await getApplicationDocumentsDirectory();
      final emergencyDir = Directory(path.join(documentsDir.path, 'downloads'));
      _logger.w('Using emergency fallback directory: ${emergencyDir.path}');
      return emergencyDir.path;
      */
      rethrow;
    }
  }


  /// Calculate total size of a directory recursively
  static Future<int> getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      _logger.w('Error calculating directory size: $e');
    }
    return size;
  }

  /// Clean up temporary files in a directory
  /// Deletes files ending with .tmp, .temp, .part, or starting with .
  static Future<void> cleanupTempFiles(Directory directory) async {
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          // Delete temporary files
          if (fileName.endsWith('.tmp') ||
              fileName.endsWith('.temp') ||
              fileName.endsWith('.part') ||
              fileName.startsWith('.')) {
            try {
              await entity.delete();
              _logger.d('Deleted temp file: ${entity.path}');
            } catch (e) {
              _logger
                  .w('Failed to delete temp file: ${entity.path}, error: $e');
            }
          }
        }
      }
    } catch (e) {
      _logger.w('Error cleaning temp files in: ${directory.path}, error: $e');
    }
  }

  /// Read local metadata.json for a content
  /// Returns metadata map if file exists and is valid, null otherwise
  /// [sourceId] - Source identifier (default: 'nhentai')
  static Future<Map<String, dynamic>?> readLocalMetadata(
    String contentId, {
    String? sourceId,
  }) async {
    try {
      _logger.d('Reading local metadata for content: $contentId');

      final downloadsPath = await getDownloadsDirectory();
      final effectiveSourceId = sourceId ?? AppStorage.defaultSourceId;

      // Try new path structure first: nhasix/{source}/{contentId}/
      var metadataFile = File(path.join(
        downloadsPath,
        AppStorage.backupFolderName,
        effectiveSourceId,
        contentId,
        AppStorage.metadataFileName,
      ));

      // Fallback to legacy path: nhasix/{contentId}/ (for backward compatibility)
      if (!await metadataFile.exists()) {
        metadataFile = File(path.join(
          downloadsPath,
          AppStorage.backupFolderName,
          contentId,
          AppStorage.metadataFileName,
        ));
      }

      // Check if metadata file exists
      if (!await metadataFile.exists()) {
        _logger.w('Metadata file does not exist: ${metadataFile.path}');
        return null;
      }

      // Read and parse metadata
      final metadataContent = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;

      _logger.i('Successfully read local metadata for $contentId');
      _logger.d('Metadata title: ${metadata['title']}');

      return metadata;
    } catch (e) {
      _logger.e('Error reading local metadata for $contentId: $e');
      return null;
    }
  }

  /// Get downloaded image paths for a content
  /// Returns sorted list of image file paths from the download directory
  /// [sourceId] - Source identifier (default: 'nhentai')
  static Future<List<String>> getDownloadedImagePaths(
    String contentId, {
    String? sourceId,
  }) async {
    try {
      _logger.d('Getting image paths for content: $contentId');

      final contentDir =
          await getContentDirectory(contentId, sourceId: sourceId);
      final imagesDir =
          Directory(path.join(contentDir, AppStorage.imagesSubfolder));

      // Check if directory exists
      if (!await imagesDir.exists()) {
        _logger.w('Images directory does not exist: ${imagesDir.path}');
        return <String>[];
      }

      // List all files in the images directory
      final files = await imagesDir.list().toList();

      // Filter only image files and sort them
      final imagePaths = files
          .whereType<File>()
          .where((file) {
            final extension = path.extension(file.path).toLowerCase();
            return ['.jpg', '.jpeg', '.png', '.gif', '.webp']
                .contains(extension);
          })
          .map((file) => file.path)
          .toList();

      // Sort by filename to maintain page order
      imagePaths.sort();

      _logger
          .i('Found ${imagePaths.length} image files for content: $contentId');

      if (imagePaths.isEmpty) {
        _logger.w(
            'No downloaded images found for content: $contentId, folder: ${imagesDir.path}');
      } else {
        _logger.d(
            'Image files: ${imagePaths.take(5).join(', ')}${imagePaths.length > 5 ? '...' : ''}');
      }

      return imagePaths;
    } catch (e) {
      _logger.e('Error getting downloaded image paths: $e');
      return <String>[];
    }
  }



  /// Get safe content ID for folder usage
  /// If contentId is too long (> 50 chars), it will return a truncated version with hash
  static String getSafeContentId(String contentId) {
    if (contentId.length <= 50) {
      return contentId;
    }
    
    // Create a safe hash to avoid collisions
    final bytes = utf8.encode(contentId);
    final digest = sha1.convert(bytes);
    final hash = digest.toString().substring(0, 8);
    
    // Truncate to 40 chars and append hash
    // Result length: 40 + 1 + 8 = 49 chars
    return '${contentId.substring(0, 40)}_$hash';
  }

  /// Get content directory
  /// 
  /// This checks both the safe path (new) and legacy path (old)
  /// Returns the path that exists, or the new safe path if neither exists
  static Future<String> getContentDirectory(String contentId, {String? sourceId}) async {
    final downloadsDir = await getDownloadsDirectory();
    final effectiveSourceId = sourceId ?? AppStorage.defaultSourceId;
    
    // 1. Check Safe ID Path (New Standard)
    final safeId = getSafeContentId(contentId);
    final safePath = path.join(downloadsDir, AppStorage.backupFolderName, effectiveSourceId, safeId);
    if (await Directory(safePath).exists()) {
      return safePath;
    }
    
    // 2. Check Original ID Path (Legacy / Standard for short IDs)
    if (safeId != contentId) {
       final originalPath = path.join(downloadsDir, AppStorage.backupFolderName, effectiveSourceId, contentId);
       if (await Directory(originalPath).exists()) {
         return originalPath;
       }
    }

    // 3. Check Legacy Path (No Source ID)
    final legacyPath = path.join(downloadsDir, AppStorage.backupFolderName, safeId);
    if (await Directory(legacyPath).exists()) {
      return legacyPath;
    }
    
    if (safeId != contentId) {
      final legacyOriginalPath = path.join(downloadsDir, AppStorage.backupFolderName, contentId);
      if (await Directory(legacyOriginalPath).exists()) {
        return legacyOriginalPath;
      }
    }

    // Default to the safe path for new content
    return safePath;
  }
  
  /// Get NEW directory for content (always uses safe ID)
  static Future<String> getNewContentDirectory(String contentId, {String? sourceId}) async {
    final downloadsDir = await getDownloadsDirectory();
    final effectiveSourceId = sourceId ?? AppStorage.defaultSourceId;
    final safeId = getSafeContentId(contentId);
    
    return path.join(downloadsDir, AppStorage.backupFolderName, effectiveSourceId, safeId);
  }

  /// Get the source directory path
  /// [sourceId] - Source identifier (default: 'nhentai')
  static Future<String> getSourceDirectory({String? sourceId}) async {
    final downloadsPath = await getDownloadsDirectory();
    final effectiveSourceId = sourceId ?? AppStorage.defaultSourceId;

    return path.join(
      downloadsPath,
      AppStorage.backupFolderName,
      effectiveSourceId,
    );
  }

  /// Check if content is downloaded (has images folder with files)
  /// [sourceId] - Source identifier (default: 'nhentai')
  static Future<bool> isContentDownloaded(
    String contentId, {
    String? sourceId,
  }) async {
    final imagePaths =
        await getDownloadedImagePaths(contentId, sourceId: sourceId);
    return imagePaths.isNotEmpty;
  }

  /// Migrate legacy content folder to new source-based structure
  /// Returns true if migration was performed, false if not needed
  static Future<bool> migrateToSourceFolder(
    String contentId, {
    String sourceId = 'nhentai',
  }) async {
    try {
      final downloadsPath = await getDownloadsDirectory();

      // Check if legacy path exists
      final legacyPath = path.join(
        downloadsPath,
        AppStorage.backupFolderName,
        contentId,
      );
      final legacyDir = Directory(legacyPath);

      if (!await legacyDir.exists()) {
        return false; // Nothing to migrate
      }

      // Check if it's actually a content folder (has metadata.json or images)
      final hasMetadata =
          await File(path.join(legacyPath, AppStorage.metadataFileName))
              .exists();
      final hasImages =
          await Directory(path.join(legacyPath, AppStorage.imagesSubfolder))
              .exists();

      if (!hasMetadata && !hasImages) {
        return false; // Not a content folder (could be source folder)
      }

      // Create source directory if needed
      final sourceDir = Directory(path.join(
        downloadsPath,
        AppStorage.backupFolderName,
        sourceId,
      ));
      if (!await sourceDir.exists()) {
        await sourceDir.create(recursive: true);
      }

      // New path
      final newPath = path.join(
        downloadsPath,
        AppStorage.backupFolderName,
        sourceId,
        contentId,
      );

      // Update metadata.json to v2 if it exists
      final metadataFile =
          File(path.join(legacyPath, AppStorage.metadataFileName));
      if (await metadataFile.exists()) {
        try {
          final metadataContent = await metadataFile.readAsString();
          final jsonMap = jsonDecode(metadataContent) as Map<String, dynamic>;

          // Migrate using ContentMetadata model
          // This automatically handles v1 -> v2 migration (adds source='nhentai', schemaVersion='2.0')
          final metadata = ContentMetadata.fromJson(jsonMap);

          // Force source to be the target sourceId of migration and upgrade schema version
          final updatedMetadata = metadata.copyWith(
            source: sourceId,
            schemaVersion: MetadataVersion.v2,
          );

          // Write back updated metadata
          await metadataFile
              .writeAsString(jsonEncode(updatedMetadata.toJson()));
          _logger.d('Upgraded metadata for $contentId to v2');
        } catch (e) {
          _logger.w('Failed to upgrade metadata for $contentId: $e');
          // Start migration anyway, metadata will be readable as v1 fallback
        }
      }

      // Move folder
      await legacyDir.rename(newPath);
      _logger.i('Migrated content $contentId to $sourceId folder');

      return true;
    } catch (e) {
      _logger.e('Error migrating content $contentId: $e');
      return false;
    }
  }

  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }
}
