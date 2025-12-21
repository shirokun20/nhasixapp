import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadAppVersion();
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

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}';
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

    // Glassmorphism Drawer Design
    return Drawer(
      backgroundColor: Colors.transparent, // Important for glass effect
      width: 300,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: Border(
            right: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Column(
            children: [
              // 1. Premium Header
              _buildDrawerHeader(theme, l10n),

              // 2. Scrollable Navigation Items
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_rounded,
                      label: l10n.home,
                      route: AppRoute.home,
                      isSelected: isSelected(AppRoute.home),
                      theme: theme,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.download_rounded,
                      label: l10n.downloadedGalleries,
                      route: AppRoute.downloads,
                      isSelected: isSelected(AppRoute.downloads),
                      theme: theme,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.offline_bolt_rounded,
                      label: l10n.offlineContent,
                      route: AppRoute.offline,
                      isSelected: isSelected(AppRoute.offline),
                      theme: theme,
                    ),
                    if (!_isOffline) ...[
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Divider(height: 1),
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.shuffle_rounded,
                        label: l10n.randomGallery,
                        route: AppRoute.random,
                        isSelected: isSelected(AppRoute.random),
                        theme: theme,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.favorite_rounded,
                        label: l10n.favoriteGalleries,
                        route: AppRoute.favorites,
                        isSelected: isSelected(AppRoute.favorites),
                        theme: theme,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.history_rounded,
                        label: l10n.viewHistory,
                        route: AppRoute.history,
                        isSelected: isSelected(AppRoute.history),
                        theme: theme,
                      ),
                    ],
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Divider(height: 1),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_rounded,
                      label: l10n.settings,
                      route: AppRoute.settings,
                      isSelected: isSelected(AppRoute.settings),
                      theme: theme,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: l10n.about,
                      route: AppRoute.about,
                      isSelected: isSelected(AppRoute.about),
                      theme: theme,
                    ),
                  ],
                ),
              ),

              // 3. Footer (Version Info)
              _buildDrawerFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.black, // Fallback/Border inside
              child: CircleAvatar(
                radius: 38,
                backgroundImage: AssetImage('assets/icons/logo_app.png'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            style: TextStyleConst.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.appSubtitleDescription,
              style: TextStyleConst.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNavigation(context, route),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? colorScheme.primary
                      : theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyleConst.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        _appVersion,
        style: TextStyleConst.caption.copyWith(
          color: theme.disabledColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
