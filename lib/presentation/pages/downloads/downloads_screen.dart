import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/text_style_const.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/download/download_bloc.dart';
import '../../widgets/widgets.dart';
import '../../widgets/app_scaffold_with_offline.dart';

/// Screen for managing downloads with status tracking and progress indicators
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Initialize download manager if not already initialized
    final downloadBloc = context.read<DownloadBloc>();
    if (downloadBloc.state is DownloadInitial) {
      downloadBloc.add(const DownloadInitializeEvent());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffoldWithOffline(
      title: AppLocalizations.of(context)!.downloads,
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(), // Use custom AppBar with menu actions
      body: BlocConsumer<DownloadBloc, DownloadBlocState>(
        listener: (context, state) {
          if (state is DownloadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
                action: state.canRetry
                    ? SnackBarAction(
                        label: AppLocalizations.of(context)!.retryAction,
                        textColor: colorScheme.onError,
                        onPressed: () {
                          context
                              .read<DownloadBloc>()
                              .add(const DownloadRefreshEvent());
                        },
                      )
                    : null,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DownloadInitial || state is DownloadInitializing) {
            return Center(
              child: AppProgressIndicator(
                  message: AppLocalizations.of(context)!.initializingDownloads),
            );
          }

          if (state is DownloadError && state.previousState == null) {
            return AppErrorWidget(
              title: AppLocalizations.of(context)!.downloadError,
              message: state.message,
              onRetry: state.canRetry
                  ? () => context
                      .read<DownloadBloc>()
                      .add(const DownloadInitializeEvent())
                  : null,
            );
          }

          if (state is DownloadLoaded) {
            return _buildLoadedContent(state);
          }

          return Center(
            child: AppProgressIndicator(
                message: AppLocalizations.of(context)!.loadingDownloads),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: Text(
        AppLocalizations.of(context)!.downloads,
        style: TextStyleConst.headlineMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        BlocBuilder<DownloadBloc, DownloadBlocState>(
          builder: (context, state) {
            if (state is! DownloadLoaded) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              color: Theme.of(context).colorScheme.surface,
              onSelected: (value) => _handleMenuAction(value, state),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pause_all',
                  enabled: state.activeDownloads.isNotEmpty ||
                      state.queuedDownloads.isNotEmpty,
                  child: Row(
                    children: [
                      Icon(Icons.pause,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.pauseAll,
                          style: TextStyleConst.bodyMedium.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'resume_all',
                  enabled: state.downloads
                      .any((d) => d.state == DownloadState.paused),
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.resumeAll,
                          style: TextStyleConst.bodyMedium.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel_all',
                  enabled: state.downloads.any((d) => d.canCancel),
                  child: Row(
                    children: [
                      Icon(Icons.cancel,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.cancelAll,
                          style: TextStyleConst.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear_completed',
                  enabled: state.completedDownloads.isNotEmpty,
                  child: Row(
                    children: [
                      Icon(Icons.clear_all,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.clearCompleted,
                          style: TextStyleConst.bodyMedium.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cleanup_storage',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.cleanupStorage,
                          style: TextStyleConst.bodyMedium.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.settings,
                          style: TextStyleConst.bodyMedium.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.exportList,
                          style: TextStyleConst.bodyMedium.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: [
          Tab(text: AppLocalizations.of(context)!.all),
          Tab(text: AppLocalizations.of(context)!.active),
          Tab(text: AppLocalizations.of(context)!.queued),
          Tab(text: AppLocalizations.of(context)!.completed),
          Tab(text: AppLocalizations.of(context)!.failed),
        ],
      ),
    );
  }

  Widget _buildLoadedContent(DownloadLoaded state) {
    return Column(
      children: [
        // Download stats
        DownloadStatsWidget(state: state),

        // Downloads list
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDownloadsList(state.downloads,
                  AppLocalizations.of(context)!.noDownloadsYet),
              _buildDownloadsList(state.activeDownloads,
                  AppLocalizations.of(context)!.noActiveDownloads),
              _buildDownloadsList(state.queuedDownloads,
                  AppLocalizations.of(context)!.noQueuedDownloads),
              _buildDownloadsList(state.completedDownloads,
                  AppLocalizations.of(context)!.noCompletedDownloads),
              _buildDownloadsList(state.failedDownloads,
                  AppLocalizations.of(context)!.noFailedDownloads),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadsList(
      List<DownloadStatus> downloads, String emptyMessage) {
    if (downloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyleConst.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DownloadBloc>().add(const DownloadRefreshEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: downloads.length,
        itemBuilder: (context, index) {
          final download = downloads[index];
          return DownloadItemWidget(
            download: download,
            onTap: () => _handleDownloadTap(download),
            onAction: (action) => _handleDownloadAction(action, download),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action, DownloadLoaded state) {
    final downloadBloc = context.read<DownloadBloc>();

    switch (action) {
      case 'pause_all':
        downloadBloc.add(const DownloadPauseAllEvent());
        break;
      case 'resume_all':
        downloadBloc.add(const DownloadResumeAllEvent());
        break;
      case 'cancel_all':
        _showCancelAllDialog();
        break;
      case 'clear_completed':
        downloadBloc.add(const DownloadClearCompletedEvent());
        break;
      case 'cleanup_storage':
        _showCleanupDialog();
        break;
      case 'settings':
        _showSettingsDialog(state.settings);
        break;
      case 'export':
        downloadBloc.add(const DownloadExportEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.downloadListExported)),
        );
        break;
    }
  }

  void _handleDownloadTap(DownloadStatus download) {
    if (download.isCompleted) {
      // Navigate to reader if download is completed
      context.push('/reader/${download.contentId}');
    } else {
      // Show download details
      _showDownloadDetails(download);
    }
  }

  void _handleDownloadAction(String action, DownloadStatus download) {
    final downloadBloc = context.read<DownloadBloc>();

    switch (action) {
      case 'start':
        downloadBloc.add(DownloadStartEvent(download.contentId));
        break;
      case 'pause':
        downloadBloc.add(DownloadPauseEvent(download.contentId));
        break;
      case 'cancel':
        _showCancelDialog(download);
        break;
      case 'retry':
        downloadBloc.add(DownloadRetryEvent(download.contentId));
        break;
      case 'remove':
        _showRemoveDialog(download);
        break;
      case 'details':
        _showDownloadDetails(download);
        break;
      case 'convert_pdf':
        // Handle PDF conversion request
        // This triggers the PDF conversion process in background
        downloadBloc.add(DownloadConvertToPdfEvent(download.contentId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pdfConversionStarted(download.contentId)),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  void _showCancelAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppLocalizations.of(context)!.cancelAllDownloads,
          style: TextStyleConst.headlineSmall
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(context)!.cancelAllConfirmation,
          style: TextStyleConst.bodyMedium
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyleConst.labelLarge),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DownloadBloc>().add(const DownloadCancelAllEvent());
            },
            child: Text(
              AppLocalizations.of(context)!.cancelAll,
              style: TextStyleConst.labelLarge
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(DownloadStatus download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppLocalizations.of(context)!.cancelDownload,
          style: TextStyleConst.headlineSmall
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(context)!.cancelDownloadConfirmation,
          style: TextStyleConst.bodyMedium
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.no,
                style: TextStyleConst.labelLarge),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<DownloadBloc>()
                  .add(DownloadCancelEvent(download.contentId));
            },
            child: Text(
              AppLocalizations.of(context)!.cancelDownload,
              style: TextStyleConst.labelLarge
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(DownloadStatus download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppLocalizations.of(context)!.removeDownload,
          style: TextStyleConst.headlineSmall
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(context)!.removeDownloadConfirmation,
          style: TextStyleConst.bodyMedium
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyleConst.labelLarge),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<DownloadBloc>()
                  .add(DownloadRemoveEvent(download.contentId));
            },
            child: Text(
              AppLocalizations.of(context)!.remove,
              style: TextStyleConst.labelLarge
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppLocalizations.of(context)!.cleanupStorage,
          style: TextStyleConst.headlineSmall
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(context)!.cleanupConfirmation,
          style: TextStyleConst.bodyMedium
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyleConst.labelLarge),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<DownloadBloc>()
                  .add(const DownloadCleanupStorageEvent());
            },
            child: Text(AppLocalizations.of(context)!.cleanup,
                style: TextStyleConst.labelLarge),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(DownloadSettings settings) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: DownloadSettingsWidget(
          settings: settings,
          onSettingsChanged: (newSettings) {
            context.read<DownloadBloc>().add(DownloadSettingsUpdateEvent(
                  maxConcurrentDownloads: newSettings.maxConcurrentDownloads,
                  imageQuality: newSettings.imageQuality,
                  autoRetry: newSettings.autoRetry,
                  retryAttempts: newSettings.retryAttempts,
                  retryDelay: newSettings.retryDelay,
                  timeoutDuration: newSettings.timeoutDuration,
                  enableNotifications: newSettings.enableNotifications,
                  wifiOnly: newSettings.wifiOnly,
                ));
          },
        ),
      ),
    );
  }

  void _showDownloadDetails(DownloadStatus download) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.downloadDetails,
                style: TextStyleConst.headlineSmall
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                  AppLocalizations.of(context)!.status, download.statusText),
              _buildDetailRow(AppLocalizations.of(context)!.progress,
                  _buildProgressText(download)),
              _buildDetailRow(AppLocalizations.of(context)!.progressPercent,
                  '${(download.progressPercentage > 100) ? '100' : download.progressPercentage}%'),
              if (download.speed > 0)
                _buildDetailRow(AppLocalizations.of(context)!.speed,
                    download.formattedSpeed),
              if (download.fileSize > 0)
                _buildDetailRow(AppLocalizations.of(context)!.size,
                    download.formattedFileSize),
              if (download.startTime != null)
                _buildDetailRow(AppLocalizations.of(context)!.started,
                    _formatDateTime(download.startTime!)),
              if (download.endTime != null)
                _buildDetailRow(AppLocalizations.of(context)!.ended,
                    _formatDateTime(download.endTime!)),
              if (download.downloadDuration != null)
                _buildDetailRow(AppLocalizations.of(context)!.duration,
                    _formatDuration(download.downloadDuration!)),
              if (download.estimatedTimeRemaining != null)
                _buildDetailRow(AppLocalizations.of(context)!.eta,
                    _formatDuration(download.estimatedTimeRemaining!)),
              if (download.error != null)
                _buildDetailRow(
                    AppLocalizations.of(context)!.error, download.error!,
                    isError: true),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context)!.close,
                        style: TextStyleConst.labelLarge),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyleConst.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyleConst.bodySmall.copyWith(
                color: isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // Use localized date format
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${AppLocalizations.of(context)!.hours(hours)} ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _buildProgressText(DownloadStatus download) {
    if (download.isRangeDownload) {
      // For range downloads, show: "X/Y pages (Pages A-B of C)"
      final loc = AppLocalizations.of(context)!;
      return '${download.downloadedPages}/${download.pagesToDownload} ${loc.pages} (${loc.rangeLabel} ${download.startPage}-${download.endPage} ${loc.ofWord} ${download.totalPages})';
    } else {
      // For full downloads, show: "X/Y pages"
      final loc = AppLocalizations.of(context)!;
      return '${download.downloadedPages}/${download.totalPages} ${loc.pages}';
    }
  }
}
