import 'dart:async';
import 'dart:io';

import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'background_download_utils.dart';

/// Download Worker for Background Downloads
///
/// This module handles background download continuation
/// when app is killed or in background.
///
/// Usage:
/// 1. Call `initializeWorkManager()` in main.dart after ensureInitialized()
/// 2. Use `DownloadWorkerManager.scheduleDownload()` to queue downloads
/// 3. App will continue downloads even when closed

/// Task names for background workers
class DownloadWorkerTasks {
  DownloadWorkerTasks._();

  /// Continue downloading content in background
  static const String downloadContent = 'com.nhasixapp.downloadContent';

  /// Resume a paused download
  static const String resumeDownload = 'com.nhasixapp.resumeDownload';

  /// Cleanup temporary/incomplete download files
  static const String cleanupTempFiles = 'com.nhasixapp.cleanupTempFiles';

  /// Sync offline content database with filesystem
  static const String syncOfflineContent = 'com.nhasixapp.syncOfflineContent';

  /// Periodic task to check and resume incomplete downloads
  static const String checkIncompleteDownloads =
      'com.nhasixapp.checkIncompleteDownloads';
}

/// Input data keys for worker tasks
class DownloadWorkerKeys {
  DownloadWorkerKeys._();

  static const String contentId = 'contentId';
  static const String downloadUrl = 'downloadUrl';
  static const String savePath = 'savePath';
  static const String title = 'title';
  static const String totalImages = 'totalImages';
  static const String currentProgress = 'currentProgress';
}

/// Callback dispatcher for WorkManager
///
/// This must be a top-level function (not a method or closure)
/// as it runs in a separate isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case DownloadWorkerTasks.downloadContent:
          return await _handleDownloadContent(inputData);

        case DownloadWorkerTasks.resumeDownload:
          return await _handleResumeDownload(inputData);

        case DownloadWorkerTasks.cleanupTempFiles:
          return await _handleCleanupTempFiles();

        case DownloadWorkerTasks.syncOfflineContent:
          return await _handleSyncOfflineContent();

        case DownloadWorkerTasks.checkIncompleteDownloads:
          return await _handleCheckIncompleteDownloads();

        case Workmanager.iOSBackgroundTask:
          // iOS background fetch - check for incomplete downloads
          return await _handleCheckIncompleteDownloads();

        default:
          return Future.value(false);
      }
    } catch (e) {
      // Log error to shared preferences for debugging
      await _logWorkerError(task, e.toString());
      return Future.value(false);
    }
  });
}

/// Initialize WorkManager with callback dispatcher
///
/// Call this in main.dart after WidgetsFlutterBinding.ensureInitialized()
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await initializeWorkManager();
///   runApp(MyApp());
/// }
/// ```
Future<void> initializeWorkManager({bool isDebugMode = false}) async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: isDebugMode,
  );
}

/// Manager class for scheduling and controlling download workers
class DownloadWorkerManager {
  DownloadWorkerManager._();

  /// Schedule a download to continue in background
  ///
  /// Parameters:
  /// - [contentId]: Unique ID for the content
  /// - [downloadUrl]: Base URL for downloading images
  /// - [savePath]: Local path to save downloaded files
  /// - [title]: Title for notification
  /// - [totalImages]: Total number of images to download
  /// - [currentProgress]: Current download progress (0-100)
  static Future<void> scheduleDownload({
    required String contentId,
    required String downloadUrl,
    required String savePath,
    required String title,
    required int totalImages,
    int currentProgress = 0,
  }) async {
    await Workmanager().registerOneOffTask(
      'download_$contentId',
      DownloadWorkerTasks.downloadContent,
      inputData: {
        DownloadWorkerKeys.contentId: contentId,
        DownloadWorkerKeys.downloadUrl: downloadUrl,
        DownloadWorkerKeys.savePath: savePath,
        DownloadWorkerKeys.title: title,
        DownloadWorkerKeys.totalImages: totalImages,
        DownloadWorkerKeys.currentProgress: currentProgress,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
  }

  /// Schedule periodic check for incomplete downloads
  ///
  /// Runs every 15 minutes (minimum interval on Android)
  static Future<void> schedulePeriodicDownloadCheck() async {
    await Workmanager().registerPeriodicTask(
      'periodic_download_check',
      DownloadWorkerTasks.checkIncompleteDownloads,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// Schedule cleanup of temporary files
  ///
  /// Runs once when conditions are met
  static Future<void> scheduleCleanup() async {
    await Workmanager().registerOneOffTask(
      'cleanup_temp_files',
      DownloadWorkerTasks.cleanupTempFiles,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel a specific download task
  static Future<void> cancelDownload(String contentId) async {
    await Workmanager().cancelByUniqueName('download_$contentId');
  }

  /// Cancel all scheduled download tasks
  static Future<void> cancelAllDownloads() async {
    await Workmanager().cancelAll();
  }
}

// ============================================================================
// Private Task Handlers
// ============================================================================

Future<bool> _handleDownloadContent(Map<String, dynamic>? inputData) async {
  if (inputData == null) return false;

  final contentId = inputData[DownloadWorkerKeys.contentId] as String?;
  final downloadUrl = inputData[DownloadWorkerKeys.downloadUrl] as String?;
  final savePath = inputData[DownloadWorkerKeys.savePath] as String?;
  final title = inputData[DownloadWorkerKeys.title] as String?;
  final totalImages = inputData[DownloadWorkerKeys.totalImages] as int?;
  final startProgress =
      inputData[DownloadWorkerKeys.currentProgress] as int? ?? 0;

  if (contentId == null ||
      downloadUrl == null ||
      savePath == null ||
      totalImages == null ||
      title == null) {
    return false;
  }

  try {
    // Mark as incomplete for resume tracking
    await BackgroundDownloadUtils.markIncomplete(contentId);

    // Save resume state
    await BackgroundDownloadUtils.saveResumeState(
      contentId,
      downloadUrl: downloadUrl,
      savePath: savePath,
      title: title,
      totalImages: totalImages,
    );

    // Create download directory
    final downloadPath =
        await BackgroundDownloadUtils.createContentDirectory(contentId);

    // Generate image URLs based on downloadUrl pattern
    // Format: https://i.nhentai.net/galleries/{galleryId}/{page}.jpg
    final imageUrls = List.generate(
      totalImages,
      (index) => '$downloadUrl/${index + 1}.jpg',
    );

    // Get resume point
    final existingProgress =
        await BackgroundDownloadUtils.getProgress(contentId);
    final startIndex =
        existingProgress > startProgress ? existingProgress : startProgress;

    // Download images with progress tracking
    final successCount = await BackgroundDownloadUtils.downloadImages(
      contentId: contentId,
      imageUrls: imageUrls,
      savePath: downloadPath,
      startIndex: startIndex,
      onProgress: (current, total) {
        // Progress is saved periodically inside downloadImages
      },
    );

    // Save metadata
    await BackgroundDownloadUtils.saveMetadata(
      contentId: contentId,
      title: title,
      totalImages: totalImages,
      savePath: downloadPath,
      extraData: {
        'downloadedCount': successCount,
        'originalUrl': downloadUrl,
      },
    );

    // Mark as complete if all images downloaded
    if (successCount >= totalImages) {
      await BackgroundDownloadUtils.markComplete(contentId);
    }

    return true;
  } catch (e) {
    await _logWorkerError(DownloadWorkerTasks.downloadContent, e.toString());
    return false;
  }
}

Future<bool> _handleResumeDownload(Map<String, dynamic>? inputData) async {
  if (inputData == null) return false;

  final contentId = inputData[DownloadWorkerKeys.contentId] as String?;

  if (contentId == null) {
    return false;
  }

  try {
    // Load saved state
    final resumeState =
        await BackgroundDownloadUtils.loadResumeState(contentId);

    // If state exists, reuse _handleDownloadContent logic
    if (resumeState != null) {
      // Add current progress key if needed, or let handleDownloadContent check storage
      resumeState[DownloadWorkerKeys.currentProgress] =
          await BackgroundDownloadUtils.getProgress(contentId);

      return await _handleDownloadContent(resumeState);
    }

    // If inputData has full info (passed directly), use it
    if (inputData.containsKey(DownloadWorkerKeys.downloadUrl)) {
      return await _handleDownloadContent(inputData);
    }

    return false;
  } catch (e) {
    await _logWorkerError(DownloadWorkerTasks.resumeDownload, e.toString());
    return false;
  }
}

Future<bool> _handleCleanupTempFiles() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/temp_downloads');

    if (await tempDir.exists()) {
      // Delete files older than 24 hours
      final now = DateTime.now();
      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          if (age.inHours > 24) {
            await entity.delete();
          }
        }
      }
    }

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> _handleSyncOfflineContent() async {
  try {
    final removedCount = await BackgroundDownloadUtils.syncDatabaseFilesystem();
    if (removedCount > 0) {
      await _logWorkerError(DownloadWorkerTasks.syncOfflineContent,
          'Removed $removedCount missing entries');
    }
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> _handleCheckIncompleteDownloads() async {
  try {
    final incompleteDownloads =
        await BackgroundDownloadUtils.getIncompleteDownloads();

    if (incompleteDownloads.isEmpty) {
      return true;
    }

    // For each incomplete download, schedule resume check
    // Note: We don't auto-resume everything to save battery,
    // just ensure they are tracked or notify user
    for (final contentId in incompleteDownloads) {
      // Could verify if actually incomplete or just stuck state
      final isComplete = await _verifyCompletion(contentId);
      if (isComplete) {
        await BackgroundDownloadUtils.markComplete(contentId);
      }
    }

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> _verifyCompletion(String contentId) async {
  final state = await BackgroundDownloadUtils.loadResumeState(contentId);
  if (state == null) return false;

  final total = state['totalImages'] as int? ?? 0;
  final progress = await BackgroundDownloadUtils.getProgress(contentId);

  return progress >= total && total > 0;
}

// ============================================================================
// Helper Functions
// ============================================================================

Future<void> _logWorkerError(String task, String error) async {
  final prefs = await SharedPreferences.getInstance();
  final timestamp = DateTime.now().toIso8601String();
  final errorLog = prefs.getStringList('worker_errors') ?? [];
  errorLog.add('[$timestamp] $task: $error');

  // Keep only last 50 errors
  if (errorLog.length > 50) {
    errorLog.removeRange(0, errorLog.length - 50);
  }

  await prefs.setStringList('worker_errors', errorLog);
}
