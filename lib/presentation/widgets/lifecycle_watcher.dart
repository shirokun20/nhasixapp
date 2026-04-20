import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/services/app_privacy_overlay_service.dart';
import '../../services/workers/download_lifecycle_mixin.dart';
import '../blocs/download/download_bloc.dart';

/// Monitors app lifecycle and interacts with DownloadBloc to handle
/// background downloads.
class LifecycleWatcher extends StatefulWidget {
  final Widget child;

  const LifecycleWatcher({
    required this.child,
    super.key,
  });

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher>
    with WidgetsBindingObserver, DownloadLifecycleMixin {
  late final AppPrivacyOverlayService _privacyOverlayService;

  @override
  void initState() {
    super.initState();
    _privacyOverlayService = getIt<AppPrivacyOverlayService>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    _privacyOverlayService.updateForLifecycleState(state);

    // Get current download state
    final downloadState = context.read<DownloadBloc>().state;

    if (downloadState is DownloadLoaded) {
      // Map to ActiveDownloadInfo
      final activeDownloads = downloadState.activeDownloads.map((download) {
        return ActiveDownloadInfo(
          contentId: download.contentId,
          isInProgress: true, // Only active ones are here
          currentProgress: download.progressPercentage,
          totalImages: download.totalPages,
          // Native WorkManager already owns active downloads in background.
          // We intentionally avoid reconstructing legacy resume payloads here.
        );
      }).toList();

      handleLifecycleChange(state, activeDownloads);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
