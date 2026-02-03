import 'package:flutter/material.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';

import '../../core/constants/text_style_const.dart';
import '../../core/config/remote_config_service.dart';
import '../../core/di/service_locator.dart';
import '../../core/routing/app_router.dart';

class AppMainHeaderWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isOffline;
  final VoidCallback? onRefresh;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final Future<Map<String, dynamic>>? offlineStats;
  final String? title;
  final String? sourceId;  // For feature flag checking

  const AppMainHeaderWidget({
    super.key,
    required this.context,
    this.onSearchPressed,
    this.onOpenBrowser,
    this.onDownloadAll,
    this.isOffline = false,
    this.onRefresh,
    this.onImport,
    this.onExport,
    this.offlineStats,
    this.title,
    this.sourceId,  // Optional sourceId for feature checking
  });

  final BuildContext context;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onOpenBrowser;
  final VoidCallback? onDownloadAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      leading: Builder(builder: (context) {
        return IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          color: Theme.of(context).colorScheme.onSurface,
          icon: const Icon(
            Icons.menu,
          ),
        );
      }),
      actions: isOffline
          ? [
              // Offline Stats
              if (offlineStats != null)
                FutureBuilder<Map<String, dynamic>>(
                  future: offlineStats,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final stats = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${stats['totalContent']} items',
                                style: TextStyleConst.bodySmall.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                stats['formattedSize'] ?? '',
                                style: TextStyleConst.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              // Refresh Button
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.sync,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  tooltip: 'Sync/Refresh',
                ),
              // Import Button
              if (onImport != null)
                IconButton(
                  onPressed: onImport,
                  icon: Icon(
                    Icons.create_new_folder_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  tooltip: 'Import from Backup',
                ),
              // Export Button
              if (onExport != null)
                IconButton(
                  onPressed: onExport,
                  icon: Icon(
                    Icons.file_upload,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  tooltip: 'Export Library',
                ),
            ]
          : [
              IconButton(
                onPressed: onSearchPressed ??
                    () {
                      // Navigate to dedicated SearchScreen
                      AppRouter.goToSearch(context);
                    },
                color: Theme.of(context).colorScheme.onSurface,
                icon: const Icon(
                  Icons.search,
                ),
                tooltip: l10n.search,
              ),
              PopupMenuButton<String>(
                color: Theme.of(context).colorScheme.surfaceContainer,
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface),
                onSelected: (String item) {
                  switch (item) {
                    case 'opob':
                      if (onOpenBrowser != null) {
                        onOpenBrowser!();
                      }
                      break;
                    case 'download-all':
                      // Check feature flag before downloading
                      if (sourceId != null) {
                        final remoteConfig = getIt<RemoteConfigService>();
                        if (!remoteConfig.isContentFeatureAccessible(sourceId!, 'download')) {
                          _showFeatureDisabledDialog(context);
                          return;
                        }
                      }
                      if (onDownloadAll != null) {
                        onDownloadAll!();
                      }
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'opob',
                      child: Text(
                        l10n.openInBrowser,
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ],
      title: Text(
        title ?? l10n.appTitle,
        style: TextStyleConst.headingMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  void _showFeatureDisabledDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.featureDisabledTitle),
        content: Text(l10n.downloadFeatureDisabled),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
