import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/entities.dart';
import 'notification_service.dart';

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
  }) async {
    try {
      _logger.i('Starting download for content: ${content.id}');

      // Check permissions
      await _checkPermissions();

      // Create download directory
      final downloadDir = await _createDownloadDirectory(content.id);

      // Show start notification
      await _notificationService.showDownloadStarted(
        contentId: content.id,
        title: content.title,
      );

      final downloadedFiles = <String>[];
      final totalImages = content.imageUrls.length;
      var downloadedCount = 0;

      // Download each image
      for (int i = 0; i < content.imageUrls.length; i++) {
        if (cancelToken?.isCancelled == true) {
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          );
        }

        final imageUrl = content.imageUrls[i];
        final fileName = 'page_${(i + 1).toString().padLeft(3, '0')}.jpg';
        final filePath = path.join(downloadDir.path, fileName);

        try {
          // Download single image
          await _downloadSingleImage(
            imageUrl: imageUrl,
            filePath: filePath,
            cancelToken: cancelToken,
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

          // Update notification progress
          await _notificationService.updateDownloadProgress(
            contentId: content.id,
            progress: (downloadedCount / totalImages * 100).round(),
            title: content.title,
          );

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
  }) async {
    final response = await _httpClient.get<List<int>>(
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

  /// Create download directory structure
  Future<Directory> _createDownloadDirectory(String contentId) async {
    // Use public Downloads directory: /storage/emulated/0/Download/nhasix/
    const publicDownloadsPath = '/storage/emulated/0/Download';
    final nhasixDir = Directory(path.join(publicDownloadsPath, 'nhasix'));
    final contentDir = Directory(path.join(nhasixDir.path, contentId));
    final imagesDir = Directory(path.join(contentDir.path, 'images'));

    // Create directories if they don't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
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
      // Check if we can write to the public Downloads directory

      // Try to create a test directory first
      const publicDownloadsPath = '/storage/emulated/0/Download';
      final testDir = Directory(path.join(publicDownloadsPath, 'nhasix'));

      // Try to create directory - this will fail if no permission
      if (!await testDir.exists()) {
        try {
          await testDir.create(recursive: true);
          _logger.i('Successfully created download directory');
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
      const publicDownloadsPath = '/storage/emulated/0/Download';
      final contentDir = Directory(
        path.join(publicDownloadsPath, 'nhasix', contentId),
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

  /// Check if content is already downloaded
  Future<bool> isContentDownloaded(String contentId) async {
    final downloadPath = await getDownloadPath(contentId);
    if (downloadPath == null) return false;

    final imagesDir = Directory(path.join(downloadPath, 'images'));
    if (!await imagesDir.exists()) return false;

    final files = await imagesDir.list().toList();
    return files.isNotEmpty;
  }

  /// Delete downloaded content
  Future<bool> deleteDownloadedContent(String contentId) async {
    try {
      final downloadPath = await getDownloadPath(contentId);
      if (downloadPath == null) return false;

      final contentDir = Directory(downloadPath).parent;
      if (await contentDir.exists()) {
        await contentDir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Error deleting downloaded content: $e');
      return false;
    }
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
