import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import '../../core/routing/app_route.dart';

class AppDrawerContent extends StatelessWidget {
  const AppDrawerContent({
    super.key,
    this.isDrawer = true,
  });

  final bool isDrawer;

  void _handleNavigation(BuildContext context, String route) {
    if (isDrawer) {
      Navigator.pop(context); // Close drawer first
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                if (isDrawer) ...[
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
              l10n.home, // Ensure 'home' exists in l10n or use hardcoded/mainTitle
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
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
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
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
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () => _handleNavigation(context, AppRoute.offline),
          ),
          ListTile(
            leading: Icon(
              Icons.shuffle,
              color: theme.iconTheme.color,
            ),
            title: Text(
              l10n.randomGallery,
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
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
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
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
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () => _handleNavigation(context, AppRoute.history),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: theme.iconTheme.color,
            ),
            title: Text(
              l10n.settings,
              style: TextStyleConst.navigationLabel.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            onTap: () => _handleNavigation(context, AppRoute.settings),
          ),
        ],
      ),
    );
  }
}
