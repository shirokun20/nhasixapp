import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import '../../core/routing/app_route.dart';

class AppDrawerContent extends StatefulWidget {
  const AppDrawerContent({
    super.key,
    this.isDrawer = true,
  });

  final bool isDrawer;

  @override
  State<AppDrawerContent> createState() => _AppDrawerContentState();
}

class _AppDrawerContentState extends State<AppDrawerContent> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });
    }
  }

  void _handleNavigation(BuildContext context, String route) {
    if (widget.isDrawer) {
      Navigator.pop(context); // Close drawer first
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentRoute = GoRouterState.of(context).uri.path;

    bool isSelected(String route) {
      // For home, check exact match or if currentRoute is the home path
      if (route == AppRoute.home) {
        return currentRoute == AppRoute.home ||
            currentRoute == '/' ||
            currentRoute.isEmpty;
      }
      return currentRoute.startsWith(route);
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isDrawer) ...[
                  const SizedBox(height: 16), // Extra safe area for drawer
                ],
                const SizedBox(height: 16),
                const Image(
                  height: 80,
                  width: 80,
                  image: AssetImage('assets/icons/logo_app.png'),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  style: TextStyleConst.headingLarge.copyWith(
                    fontSize: 30,
                    color: theme.textTheme.headlineLarge?.color,
                  ),
                ),
                Text(
                  l10n.appSubtitleDescription,
                  style: TextStyleConst.caption.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.home,
              color: theme.iconTheme.color,
            ),
            title: Text(
              l10n.home,
              style: TextStyleConst.navigationLabel.copyWith(
                color: isSelected(AppRoute.home)
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleMedium?.color,
                fontWeight: isSelected(AppRoute.home) ? FontWeight.bold : null,
              ),
            ),
            selected: isSelected(AppRoute.home),
            selectedTileColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            onTap: () => _handleNavigation(context, AppRoute.home),
          ),
          ListTile(
            leading: Icon(
              Icons.download,
              color: theme.iconTheme.color,
            ),
            title: Text(
              l10n.downloadedGalleries,
              style: TextStyleConst.navigationLabel.copyWith(
                color: isSelected(AppRoute.downloads)
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleMedium?.color,
                fontWeight:
                    isSelected(AppRoute.downloads) ? FontWeight.bold : null,
              ),
            ),
            selected: isSelected(AppRoute.downloads),
            selectedTileColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            onTap: () => _handleNavigation(context, AppRoute.downloads),
          ),
          ListTile(
            leading: Icon(
              Icons.offline_bolt,
              color: theme.iconTheme.color,
            ),
            title: Text(
              l10n.offlineContent,
              style: TextStyleConst.navigationLabel.copyWith(
                color: isSelected(AppRoute.offline)
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleMedium?.color,
                fontWeight:
                    isSelected(AppRoute.offline) ? FontWeight.bold : null,
              ),
            ),
            selected: isSelected(AppRoute.offline),
            selectedTileColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            onTap: () => _handleNavigation(context, AppRoute.offline),
          ),
          if (!_isOffline) ...[
            ListTile(
              leading: Icon(
                Icons.shuffle,
                color: theme.iconTheme.color,
              ),
              title: Text(
                l10n.randomGallery,
                style: TextStyleConst.navigationLabel.copyWith(
                  color: isSelected(AppRoute.random)
                      ? theme.colorScheme.primary
                      : theme.textTheme.titleMedium?.color,
                  fontWeight:
                      isSelected(AppRoute.random) ? FontWeight.bold : null,
                ),
              ),
              selected: isSelected(AppRoute.random),
              selectedTileColor:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              onTap: () => _handleNavigation(context, AppRoute.random),
            ),
            ListTile(
              leading: Icon(
                Icons.favorite,
                color: theme.iconTheme.color,
              ),
              title: Text(
                l10n.favoriteGalleries,
                style: TextStyleConst.navigationLabel.copyWith(
                  color: isSelected(AppRoute.favorites)
                      ? theme.colorScheme.primary
                      : theme.textTheme.titleMedium?.color,
                  fontWeight:
                      isSelected(AppRoute.favorites) ? FontWeight.bold : null,
                ),
              ),
              selected: isSelected(AppRoute.favorites),
              selectedTileColor:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              onTap: () => _handleNavigation(context, AppRoute.favorites),
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: theme.iconTheme.color,
              ),
              title: Text(
                l10n.viewHistory,
                style: TextStyleConst.navigationLabel.copyWith(
                  color: isSelected(AppRoute.history)
                      ? theme.colorScheme.primary
                      : theme.textTheme.titleMedium?.color,
                  fontWeight:
                      isSelected(AppRoute.history) ? FontWeight.bold : null,
                ),
              ),
              selected: isSelected(AppRoute.history),
              selectedTileColor:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              onTap: () => _handleNavigation(context, AppRoute.history),
            ),
          ],
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: theme.iconTheme.color,
            ),
            title: Text(
              l10n.settings,
              style: TextStyleConst.navigationLabel.copyWith(
                color: isSelected(AppRoute.settings)
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleMedium?.color,
                fontWeight:
                    isSelected(AppRoute.settings) ? FontWeight.bold : null,
              ),
            ),
            selected: isSelected(AppRoute.settings),
            selectedTileColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            onTap: () => _handleNavigation(context, AppRoute.settings),
          ),
        ],
      ),
    );
  }
}
