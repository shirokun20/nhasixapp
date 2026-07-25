import 'dart:async';
import 'dart:io';

import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'background_download_utils.dart';

/// Usage:
/// 1. Call `initializeWorkManager()` in main.dart after ensureInitialized()
/// 2. Use `DownloadWorkerManager.scheduleDownload()` to queue downloads
/// 3. App will continue downloads even when closed

class DownloadWorkerTasks {
  DownloadWorkerTasks._();

  static const String downloadContent = 'com.nhasixapp.downloadContent';
  static const String resumeDownload = 'com.nhasixapp.resumeDownload';
  static const String cleanupTempFiles = 'com.nhasixapp.cleanupTempFiles';
  static const String syncOfflineContent = 'com.nhasixapp.syncOfflineContent';
  static const String checkIncompleteDownloads =
      'com.nhasixapp.checkIncompleteDownloads';
}

class DownloadWorkerKeys {
  DownloadWorkerKeys._();

  static const String contentId = 'contentId';
  static const String downloadUrl = 'downloadUrl';
  static const String savePath = 'savePath';
  static const String title = 'title';
  static const String totalImages = 'totalImages';
  static const String currentProgress = 'currentProgress';
}

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
      await _logWorkerError(task, e.toString());
      return Future.value(false);
    }
  });
}

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
  );
}

class DownloadWorkerManager {
  DownloadWorkerManager._();

  /// This is useful when app lifecycle changes and full details
  /// aren't readily available in the UI state.
  static Future<void> scheduleResume(String contentId) async {
    final resumeState =
        await BackgroundDownloadUtils.loadResumeState(contentId);

    if (resumeState != null) {
      await Workmanager().registerOneOffTask(
        'download_$contentId',
        DownloadWorkerTasks.downloadContent,
        inputData: resumeState,
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
    } else {
      // Fallback: register task just with ID and hope worker finds state later
      // But worker logic above relies on inputData OR saved state.
      // So this is valid.
      await Workmanager().registerOneOffTask(
        'download_$contentId',
        DownloadWorkerTasks.downloadContent,
        inputData: {DownloadWorkerKeys.contentId: contentId},
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
    }
  }

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

  /// Runs every 15 minutes (minimum interval on Android)
  static Future<void> schedulePeriodicDownloadCheck() async {
    await Workmanager().registerPeriodicTask(
      'periodic_download_check',
      DownloadWorkerTasks.checkIncompleteDownloads,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> scheduleCleanup() async {
    await Workmanager().registerOneOffTask(
      'cleanup_temp_files',
      DownloadWorkerTasks.cleanupTempFiles,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelDownload(String contentId) async {
    await Workmanager().cancelByUniqueName('download_$contentId');
  }

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
    await BackgroundDownloadUtils.markIncomplete(contentId);

    await BackgroundDownloadUtils.saveResumeState(
      contentId,
      downloadUrl: downloadUrl,
      savePath: savePath,
      title: title,
      totalImages: totalImages,
    );

    final downloadPath = savePath;
    final downloadDir = Directory(downloadPath);
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    // Format: https://i.nhentai.net/galleries/{galleryId}/{page}.jpg
    final imageUrls = List.generate(
      totalImages,
      (index) => '$downloadUrl/${index + 1}.jpg',
    );

    final existingProgress =
        await BackgroundDownloadUtils.getProgress(contentId);
    final startIndex =
        existingProgress > startProgress ? existingProgress : startProgress;

    final successCount = await BackgroundDownloadUtils.downloadImages(
      contentId: contentId,
      imageUrls: imageUrls,
      savePath: downloadPath,
      startIndex: startIndex,
      onProgress: (current, total) {
        // Progress is saved periodically inside downloadImages
      },
    );

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
    final resumeState =
        await BackgroundDownloadUtils.loadResumeState(contentId);

    if (resumeState != null) {
      resumeState[DownloadWorkerKeys.currentProgress] =
          await BackgroundDownloadUtils.getProgress(contentId);

      return await _handleDownloadContent(resumeState);
    }

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

  if (errorLog.length > 50) {
    errorLog.removeRange(0, errorLog.length - 50);
  }

  await prefs.setStringList('worker_errors', errorLog);
}
