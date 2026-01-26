import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/utils/directory_utils.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/core/utils/permission_helper.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart'; // NEW: For download screen refresh
import 'package:nhasixapp/services/export_service.dart';
import 'package:nhasixapp/services/notification_service.dart';

/// Mixin providing common offline content management functionality
/// Used by screens that need to import/export/refresh offline content
mixin OfflineManagementMixin<T extends StatefulWidget> on State<T> {
  /// Import content from backup folder to database
  Future<void> importFromBackup(BuildContext context) async {
    // Check permission first
    final hasPermission = await PermissionHelper.hasStoragePermission();
    if (!hasPermission) {
      if (context.mounted) {
        final granted =
            await PermissionHelper.requestStoragePermission(context);
        if (!granted) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.storagePermissionRequired)),
          );
          return;
        }
      }
    }

    // FIXED: Show loading state BEFORE starting sync operation
    // This ensures users see loading shimmer immediately
    if (context.mounted) {
      context.read<OfflineSearchCubit>().setLoadingState();
    }

    // Scan and sync backup folder
    if (context.mounted) {
      await _autoScanBackupFolder(context);
    }

    // Note: forceRefresh() inside _autoScanBackupFolder already reloads from database
  }

  /// Export library with progress dialog
  Future<void> exportLibrary(BuildContext context) async {
    final exportService = getIt<ExportService>();

    // Show progress dialog
    String progressMessage = 'Preparing export...';
    double progressValue = 0.0;

    // Use a reference to the dialog state setter to update progress
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          dialogSetState = setDialogState;
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.exportingLibrary),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progressValue),
                const SizedBox(height: 16),
                Text(progressMessage),
              ],
            ),
          );
        },
      ),
    );

    try {
      final exportPath = await exportService.exportLibrary(
        onProgress: (progress, message) {
          progressValue = progress;
          progressMessage = message;
          // Update dialog if visible
          if (dialogSetState != null && context.mounted) {
            dialogSetState!(() {});
          }
        },
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      // Show success dialog with share option
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.exportComplete),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.libraryExportSuccess),
                const SizedBox(height: 8),
                Text(
                  'Path: $exportPath',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await exportService.shareExport(exportPath);
                },
                icon: const Icon(Icons.share),
                label: Text(AppLocalizations.of(context)!.share),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Internal method to auto scan backup folder
  Future<void> _autoScanBackupFolder(BuildContext context) async {
    debugPrint('OFFLINE_AUTO_SCAN: Starting auto-scan for backup folder...');

    final backupPath = await DirectoryUtils.findNhasixBackupFolder();
    debugPrint(
        'OFFLINE_AUTO_SCAN: DirectoryUtils.findNhasixBackupFolder() returned: $backupPath');

    if (backupPath != null) {
      debugPrint(
          'OFFLINE_AUTO_SCAN: Found backup path: $backupPath, starting sync...');

      // Auto-sync backup content to database
      final offlineManager = getIt<OfflineContentManager>();

      // SHOW SYNC NOTIFICATION
      final notificationService = getIt<NotificationService>();
      await notificationService.showSyncStarted();

      final syncResult = await offlineManager.syncBackupToDatabase(
        backupPath,
        onProgress: (processed, total) {
          final percentage = total > 0 ? ((processed / total) * 100).toInt() : 0;
          notificationService.updateSyncProgress(
            progress: percentage,
            message: AppLocalizations.of(context)!.syncProgressMessage(processed, total),
          );
        },
      );
      final synced = syncResult['synced'] ?? 0;
      final updated = syncResult['updated'] ?? 0;

      // SYNC COMPLETED
      await notificationService.showSyncCompleted(itemCount: synced + updated);

      if (!context.mounted) return;

      if (synced > 0 || updated > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.syncResult(synced, updated)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Force refresh to reload from database AND clear loading state
      // This must run unconditionally to stop the loading shimmer
      context.read<OfflineSearchCubit>().forceRefresh();

      // ✅ NEW: Refresh DownloadBloc to sync Downloads Screen with database
      // This ensures Downloads Screen shows imported content immediately
      // without requiring app restart
      try {
        context.read<DownloadBloc>().add(const DownloadRefreshEvent());
        debugPrint('OFFLINE_AUTO_SCAN: Triggered DownloadBloc refresh after sync');
      } catch (e) {
        // DownloadBloc might not be available in all contexts (e.g., if Downloads Screen hasn't been visited)
        // This is non-critical, so just log and continue
        debugPrint('OFFLINE_AUTO_SCAN: Could not refresh DownloadBloc (not initialized yet): $e');
      }
    } else {
      debugPrint('OFFLINE_AUTO_SCAN: No backup folder found automatically');
    }
  }

}
