import 'package:flutter/material.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';

import '../../core/constants/text_style_const.dart';
import '../../core/routing/app_router.dart';

class AppMainHeaderWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const AppMainHeaderWidget({
    super.key,
    required this.context,
    this.onSearchPressed,
    this.onOpenBrowser,
    this.onDownloadAll,
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
      actions: [
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
          icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
          onSelected: (String item) {
            // Handle item selection
            switch (item) {
              case 'opob':
                if (onOpenBrowser != null) {
                  onOpenBrowser!();
                }
                break;
              case 'download-all':
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
              PopupMenuItem<String>(
                value: 'download-all',
                child: Text(
                  l10n.downloadAllGalleries,
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
        l10n.appTitle,
        style: TextStyleConst.headingMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
