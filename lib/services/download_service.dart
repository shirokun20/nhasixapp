import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/entities/entities.dart';
import '../domain/value_objects/image_url.dart' as img;
import 'notification_service.dart';
import 'download_manager.dart';

/// Service untuk handle actual file download
class DownloadService {
  DownloadService({
    required Dio httpClient,
    required NotificationService notificationService,
    Logger? logger,
  })  : _httpClient = httpClient,
        _notificationService = notificationService,
        _logger = logger ?? Logger();

  final Dio _httpClient;
  final NotificationService _notificationService;
  final Logger _logger;

  /// Download content dengan progress tracking dan notification
  Future<DownloadResult> downloadContent({
    required Content content,
    required Function(DownloadProgress) onProgress,
    CancelToken? cancelToken,
    String imageQuality = 'high', // Default to high quality
    Duration? timeoutDuration, // Optional timeout override
  }) async {
    try {
      _logger.i('Starting download for content: ${content.id}');

      // Check permissions
      await _checkPermissions();

      // Create download directory
      final downloadDir = await _createDownloadDirectory(content.id);

      // ✅ FIXED: Check existing downloaded files for proper resume
      final existingFiles = await _getExistingDownloadedFiles(downloadDir);
      final totalImages = content.imageUrls.length;
      var downloadedCount = existingFiles.length; // Start from existing count

      _logger.i('Found ${existingFiles.length} existing files, continuing from page ${downloadedCount + 1}');

      // Show start notification
      await _notificationService.showDownloadStarted(
        contentId: content.id,
        title: content.title,
      );

      final downloadedFiles = List<String>.from(existingFiles); // Include existing files

      // Download each image
      for (int i = 0; i < content.imageUrls.length; i++) {
        // Check for cancellation
        if (cancelToken?.isCancelled == true) {
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          );
        }

        // Check for pause state - wait until resumed or cancelled
        while (DownloadManager().isPaused(content.id)) {
          await Future.delayed(const Duration(seconds: 1));
          // Check if cancelled while paused
          if (DownloadManager().isCancelled(content.id) || 
              cancelToken?.isCancelled == true) {
            throw DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.cancel,
            );
          }
        }

        final imageUrl = content.imageUrls[i];
        
        // Apply image quality setting
        final optimizedImageUrl = _getOptimizedImageUrl(imageUrl, imageQuality);
        
        final fileName = 'page_${(i + 1).toString().padLeft(3, '0')}.jpg';
        final filePath = path.join(downloadDir.path, fileName);

        // ✅ FIXED: Skip if file already exists (for proper resume)
        if (await File(filePath).exists()) {
          _logger.d('Skipping existing file: $fileName');
          continue;
        }

        try {
          // Download single image with optimized URL
          await _downloadSingleImage(
            imageUrl: optimizedImageUrl,
            filePath: filePath,
            cancelToken: cancelToken,
            timeoutDuration: timeoutDuration,
          );

          downloadedFiles.add(filePath);
          downloadedCount++;

          // Update progress
          final progress = DownloadProgress(
            contentId: content.id,
            downloadedPages: downloadedCount,
            totalPages: totalImages,
            currentFileName: fileName,
          );

          onProgress(progress);

          // ✅ REMOVED: Direct notification update to prevent race condition
          // Notification will be updated through DownloadBloc for better synchronization

          _logger.d('Downloaded image ${i + 1}/$totalImages: $fileName');
        } catch (e, stackTrace) {
          _logger.e('Failed to download image ${i + 1}: $e and $stackTrace');
          // Continue with next image instead of failing completely
          continue;
        }
      }

      // Save metadata
      await _saveDownloadMetadata(content, downloadDir, downloadedFiles);

      // Show completion notification
      await _notificationService.showDownloadCompleted(
        contentId: content.id,
        title: content.title,
        downloadPath: downloadDir.path,
      );

      _logger.i('Download completed for content: ${content.id}');

      return DownloadResult(
        success: true,
        downloadPath: downloadDir.path,
        downloadedFiles: downloadedFiles,
        totalFiles: downloadedFiles.length,
      );
    } catch (e) {
      _logger.e('Download failed for content: ${content.id}', error: e);

      // Show error notification
      await _notificationService.showDownloadError(
        contentId: content.id,
        title: content.title,
        error: e.toString(),
      );

      return DownloadResult(
        success: false,
        error: e.toString(),
        downloadPath: null,
        downloadedFiles: [],
        totalFiles: 0,
      );
    }
  }

  /// Download single image file
  Future<void> _downloadSingleImage({
    required String imageUrl,
    required String filePath,
    CancelToken? cancelToken,
    Duration? timeoutDuration,
  }) async {
    // Create dio instance with custom timeout if provided
    final dio = timeoutDuration != null 
      ? Dio(BaseOptions(
          connectTimeout: timeoutDuration,
          receiveTimeout: timeoutDuration,
          sendTimeout: timeoutDuration,
        ))
      : _httpClient;
    
    final response = await dio.get<List<int>>(
      imageUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'User-Agent': 'AppleWebKit/537.36',
          'Referer': 'https://nhentai.net/',
        },
      ),
      cancelToken: cancelToken,
    );

    if (response.data != null) {
      final file = File(filePath);
      await file.writeAsBytes(response.data!);
    } else {
      throw Exception('No data received for image: $imageUrl');
    }
  }

  /// ✅ NEW: Get existing downloaded files for proper resume
  Future<List<String>> _getExistingDownloadedFiles(Directory downloadDir) async {
    try {
      if (!await downloadDir.exists()) {
        return [];
      }

      final files = await downloadDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.jpg'))
          .cast<File>()
          .toList();

      // Sort files by name to maintain page order
      files.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

      final filePaths = files.map((f) => f.path).toList();
      _logger.d('Found ${filePaths.length} existing downloaded files');
      
      return filePaths;
    } catch (e) {
      _logger.w('Error checking existing files: $e');
      return [];
    }
  }

  /// Create download directory structure
  Future<Directory> _createDownloadDirectory(String contentId) async {
    // Use smart Downloads directory detection
    final downloadsPath = await _getDownloadsDirectory();
    final nhasixDir = Directory(path.join(downloadsPath, 'nhasix'));
    final contentDir = Directory(path.join(nhasixDir.path, contentId));
    final imagesDir = Directory(path.join(contentDir.path, 'images'));

    // Create directories if they don't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  /// Smart Downloads directory detection
  /// Tries multiple possible Downloads folder names and locations
  Future<String> _getDownloadsDirectory() async {
    try {
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
          'Download',     // English (most common)
          'Downloads',    // English alternative
          'Unduhan',      // Indonesian
          'Descargas',    // Spanish
          'Téléchargements', // French
          'Downloads',    // German uses English
          'ダウンロード',     // Japanese
        ];

        // Try each possible Downloads folder
        for (final folderName in downloadsFolderNames) {
          final downloadsDir = Directory(path.join(externalRoot, folderName));
          if (await downloadsDir.exists()) {
            _logger.i('Found Downloads directory: ${downloadsDir.path}');
            return downloadsDir.path;
          }
        }

        // If no Downloads folder found, create one in external storage root
        final defaultDownloadsDir = Directory(path.join(externalRoot, 'Download'));
        try {
          if (!await defaultDownloadsDir.exists()) {
            await defaultDownloadsDir.create(recursive: true);
            _logger.i('Created Downloads directory: ${defaultDownloadsDir.path}');
          }
          return defaultDownloadsDir.path;
        } catch (e) {
          _logger.w('Could not create Downloads directory in external storage: $e');
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
          _logger.i('Found Downloads directory at common path: $commonPath');
          return commonPath;
        }
      }

      // Fallback 2: Use app-specific external storage
      if (externalDir != null) {
        final appDownloadsDir = Directory(path.join(externalDir.path, 'downloads'));
        if (!await appDownloadsDir.exists()) {
          await appDownloadsDir.create(recursive: true);
        }
        _logger.i('Using app-specific downloads directory: ${appDownloadsDir.path}');
        return appDownloadsDir.path;
      }

      // Fallback 3: Use application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsDownloadsDir = Directory(path.join(documentsDir.path, 'downloads'));
      if (!await documentsDownloadsDir.exists()) {
        await documentsDownloadsDir.create(recursive: true);
      }
      _logger.i('Using app documents downloads directory: ${documentsDownloadsDir.path}');
      return documentsDownloadsDir.path;

    } catch (e) {
      _logger.e('Error detecting Downloads directory: $e');
      
      // Emergency fallback: use app documents
      final documentsDir = await getApplicationDocumentsDirectory();
      final emergencyDir = Directory(path.join(documentsDir.path, 'downloads'));
      if (!await emergencyDir.exists()) {
        await emergencyDir.create(recursive: true);
      }
      _logger.w('Using emergency fallback directory: ${emergencyDir.path}');
      return emergencyDir.path;
    }
  }

  /// Save download metadata
  Future<void> _saveDownloadMetadata(
    Content content,
    Directory downloadDir,
    List<String> downloadedFiles,
  ) async {
    final metadata = {
      'content_id': content.id,
      'title': content.title,
      'download_date': DateTime.now().toIso8601String(),
      'total_pages': content.pageCount,
      'downloaded_files': downloadedFiles.length,
      'files': downloadedFiles.map((f) => path.basename(f)).toList(),
      'tags': content.tags.map((t) => t.name).toList(),
      'artists': content.artists,
      'language': content.language,
      'cover_url': content.coverUrl,
    };

    final metadataFile =
        File(path.join(downloadDir.parent.path, 'metadata.json'));
    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );
  }

  /// Check and request necessary permissions
  Future<void> _checkPermissions() async {
    try {
      // For Android 13+ (API 33+), we need different permissions
      // Check if we can write to the Downloads directory

      // Get the Downloads directory path using smart detection
      final downloadsPath = await _getDownloadsDirectory();
      final testDir = Directory(path.join(downloadsPath, 'nhasix'));

      // Try to create directory - this will fail if no permission
      if (!await testDir.exists()) {
        try {
          await testDir.create(recursive: true);
          _logger.i('Successfully created download directory at: ${testDir.path}');
        } catch (e) {
          _logger.e('Failed to create download directory: $e');

          // Try requesting storage permission
          final storagePermission = await Permission.storage.status;
          if (!storagePermission.isGranted) {
            final result = await Permission.storage.request();
            if (!result.isGranted) {
              // Try manage external storage for Android 11+
              final managePermission =
                  await Permission.manageExternalStorage.status;
              if (!managePermission.isGranted) {
                final manageResult =
                    await Permission.manageExternalStorage.request();
                if (!manageResult.isGranted) {
                  throw Exception(
                      'Storage permission is required for downloads. Please grant storage permission in app settings.');
                }
              }
            }
          }

          // Try creating directory again after permission
          await testDir.create(recursive: true);
        }
      }

      _logger.i('Storage permission check completed successfully');
    } catch (e) {
      _logger.e('Permission check failed: $e');
      throw Exception(
          'Storage permission is required for downloads. Error: $e');
    }
  }

  /// Get download directory path for content
  Future<String?> getDownloadPath(String contentId) async {
    try {
      final downloadsPath = await _getDownloadsDirectory();
      final contentDir = Directory(
        path.join(downloadsPath, 'nhasix', contentId),
      );

      if (await contentDir.exists()) {
        return contentDir.path;
      }
      return null;
    } catch (e) {
      _logger.e('Error getting download path: $e');
      return null;
    }
  }

  /// Delete downloaded by content id tapi hanya delete isi dari folder contentid
  Future<void> deleteDownloadedContent(String contentId) async {
    try {
      final downloadPath = await getDownloadPath(contentId);
      if (downloadPath != null) {

        // ini akan muncul path apa? 
        final contentDir = Directory(downloadPath);
        if (await contentDir.exists()) {
          await contentDir.delete(recursive: true);
        }
      }
    } catch (e) {
      _logger.e('Error deleting downloaded content: $e');
    }
  }

  /// Check if content is already downloaded
  Future<bool> isContentDownloaded(String contentId) async {
    final downloadPath = await getDownloadPath(contentId);
    if (downloadPath == null) return false;

    final imagesDir = Directory(path.join(downloadPath, 'images'));
    if (!await imagesDir.exists()) return false;

    final files = await imagesDir.list().toList();
    return files.isNotEmpty;
  }

  /// Get downloaded files for content
  Future<List<String>> getDownloadedFiles(String contentId) async {
    try {
      final downloadPath = await getDownloadPath(contentId);
      if (downloadPath == null) return [];

      final imagesDir = Directory(path.join(downloadPath, 'images'));
      if (!await imagesDir.exists()) return [];

      final files = await imagesDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      // Sort files by name to maintain page order
      files.sort(
          (a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

      return files.map((f) => f.path).toList();
    } catch (e) {
      _logger.e('Error getting downloaded files: $e');
      return [];
    }
  }
  
  /// Get optimized image URL based on quality setting
  String _getOptimizedImageUrl(String originalUrl, String imageQuality) {
    // Convert string quality to ImageQuality enum
    img.ImageQuality quality;
    switch (imageQuality.toLowerCase()) {
      case 'low':
        quality = img.ImageQuality.low;
        break;
      case 'medium':
        quality = img.ImageQuality.medium;
        break;
      case 'high':
        quality = img.ImageQuality.high;
        break;
      case 'original':
        quality = img.ImageQuality.original;
        break;
      default:
        quality = img.ImageQuality.high; // Default to high quality
    }
    
    // Create ImageUrl object and get optimized version
    final imageUrl = img.ImageUrl(originalUrl);
    final optimizedUrl = imageUrl.getOptimized(quality);
    
    return optimizedUrl.value;
  }
}

/// Result of download operation
class DownloadResult {
  const DownloadResult({
    required this.success,
    required this.downloadedFiles,
    required this.totalFiles,
    this.downloadPath,
    this.error,
  });

  final bool success;
  final String? downloadPath;
  final List<String> downloadedFiles;
  final int totalFiles;
  final String? error;
}

/// Progress information for download
class DownloadProgress {
  const DownloadProgress({
    required this.contentId,
    required this.downloadedPages,
    required this.totalPages,
    this.currentFileName,
    this.speed,
    this.estimatedTimeRemaining,
  });

  final String contentId;
  final int downloadedPages;
  final int totalPages;
  final String? currentFileName;
  final double? speed; // bytes per second
  final Duration? estimatedTimeRemaining;

  double get progressPercentage =>
      totalPages > 0 ? (downloadedPages / totalPages * 100) : 0;

  bool get isCompleted => downloadedPages >= totalPages;
}
