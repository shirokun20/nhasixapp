import 'package:flutter/widgets.dart';

import '../workers/download_worker.dart';

/// Mixin to handle app lifecycle for background download scheduling
///
/// Usage:
/// 1. Add this mixin to your main widget state
/// 2. Call [scheduleActiveDownloadsForBackground] when app goes to background
/// 3. Call [cancelBackgroundDownloadSchedule] when app resumes
///
/// Example:
/// ```dart
/// class _MyAppState extends State<MyApp>
///     with WidgetsBindingObserver, DownloadLifecycleMixin {
///
///   @override
///   void didChangeAppLifecycleState(AppLifecycleState state) {
///     handleLifecycleChange(state, getActiveDownloads());
///   }
/// }
/// ```
mixin DownloadLifecycleMixin<T extends StatefulWidget> on State<T> {
  /// Handle app lifecycle changes for download scheduling
  ///
  /// Call this from [didChangeAppLifecycleState] with current downloads
  Future<void> handleLifecycleChange(
    AppLifecycleState state,
    List<ActiveDownloadInfo> activeDownloads,
  ) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App going to background - schedule downloads
        await scheduleActiveDownloadsForBackground(activeDownloads);
        break;

      case AppLifecycleState.resumed:
        // App returning to foreground - cancel background schedules
        // The app will handle downloads directly now
        await cancelBackgroundDownloadSchedule(activeDownloads);
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Don't do anything for these states
        break;
    }
  }

  /// Schedule all active downloads to continue in background
  Future<void> scheduleActiveDownloadsForBackground(
    List<ActiveDownloadInfo> activeDownloads,
  ) async {
    for (final download in activeDownloads) {
      if (download.isInProgress) {
        await DownloadWorkerManager.scheduleDownload(
          contentId: download.contentId,
          downloadUrl: download.downloadUrl,
          savePath: download.savePath,
          title: download.title,
          totalImages: download.totalImages,
          currentProgress: download.currentProgress,
        );
      }
    }
  }

  /// Cancel background download schedules when app resumes
  Future<void> cancelBackgroundDownloadSchedule(
    List<ActiveDownloadInfo> activeDownloads,
  ) async {
    for (final download in activeDownloads) {
      await DownloadWorkerManager.cancelDownload(download.contentId);
    }
  }
}

/// Information about an active download for background scheduling
class ActiveDownloadInfo {
  final String contentId;
  final String downloadUrl;
  final String savePath;
  final String title;
  final int totalImages;
  final int currentProgress;
  final bool isInProgress;

  const ActiveDownloadInfo({
    required this.contentId,
    required this.downloadUrl,
    required this.savePath,
    required this.title,
    required this.totalImages,
    required this.currentProgress,
    required this.isInProgress,
  });
}
