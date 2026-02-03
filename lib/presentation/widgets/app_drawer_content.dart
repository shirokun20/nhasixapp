import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/presentation/cubits/source/source_cubit.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_auth/crotpedia_auth_cubit.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import '../../core/routing/app_route.dart';
import 'common/source_selector.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/presentation/widgets/license_check_dialog.dart';
import 'package:nhasixapp/services/license_service.dart';

class AppDrawerContent extends StatefulWidget {
  const AppDrawerContent({
    super.key,
    this.isDrawer = true,
  });

  final bool isDrawer;

  @override
  State<AppDrawerContent> createState() => _AppDrawerContentState();
}

class _AppDrawerContentState extends State<AppDrawerContent>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  String _appVersion = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadAppVersion();

    // Setup pulse animation for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

    if (route == 'license_check') {
      showDialog(
        context: context,
        builder: (context) => const LicenseCheckDialog(),
      ).then((_) {
        // Refresh drawer state (e.g. premium status)
        if (mounted) setState(() {});
      });
      return;
    }

    if (route == AppRoute.crotpediaLogin) {
      context.push(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentRoute = GoRouterState.of(context).uri.path;

    bool isSelected(String route) {
      if (route == AppRoute.home) {
        return currentRoute == AppRoute.home ||
            currentRoute == AppRoute.main ||
            currentRoute == '/' ||
            currentRoute.isEmpty;
      }
      return currentRoute.startsWith(route);
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      width: 300,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: Border(
            right: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
              // 1. Premium Animated Header
              _buildDrawerHeader(theme, l10n),

              // 2. Scrollable Navigation Items
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    const SourceSelector(),
                    const SizedBox(height: 8),

                    // Crotpedia specific actions
                    if (context.watch<SourceCubit>().state.activeSource?.id ==
                        SourceType.crotpedia.id) ...[
                      BlocBuilder<CrotpediaAuthCubit, CrotpediaAuthState>(
                        builder: (context, authState) {
                          final isLoggedIn = authState is CrotpediaAuthSuccess;
                          final label = isLoggedIn
                              ? 'Account (${authState.username})'
                              : 'Login / Account';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('ACCOUNT', theme),
                              const SizedBox(height: 8),
                              _buildNavItem(
                                context,
                                icon: isLoggedIn
                                    ? Icons.verified_user_rounded
                                    : Icons.account_circle_rounded,
                                label: label,
                                route: AppRoute.crotpediaLogin,
                                isSelected: isSelected(AppRoute.crotpediaLogin),
                                theme: theme,
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ],

                    _buildSectionLabel(l10n.home.toUpperCase(), theme),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.home_rounded,
                      label: l10n.home,
                      route: AppRoute.home,
                      isSelected: isSelected(AppRoute.home),
                      theme: theme,
                    ),
                    // Downloaded Galleries
                    Builder(builder: (context) {
                        final sourceId = context
                              .read<SourceCubit>()
                              .state
                              .activeSource
                              ?.id ??
                          'nhentai';
                      final config = getIt<RemoteConfigService>();
                      if (config.isFeatureEnabled(
                          sourceId, (f) => f.download?.enabled ?? false)) {
                        return _buildNavItem(
                          context,
                          icon: Icons.download_rounded,
                          label: l10n.downloadedGalleries,
                          route: AppRoute.downloads,
                          isSelected: isSelected(AppRoute.downloads),
                          theme: theme,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    // Offline Content (Linked to Download feature)
                    Builder(builder: (context) {
                        final sourceId = context
                              .read<SourceCubit>()
                              .state
                              .activeSource
                              ?.id ??
                          'nhentai';
                      final config = getIt<RemoteConfigService>();
                      if (config.isFeatureEnabled(
                          sourceId, (f) => f.download?.enabled ?? false)) {
                        return _buildNavItem(
                          context,
                          icon: Icons.offline_bolt_rounded,
                          label: l10n.offlineContent,
                          route: AppRoute.offline,
                          isSelected: isSelected(AppRoute.offline),
                          theme: theme,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    if (!_isOffline) ...[
                      const SizedBox(height: 16),
                      _buildSectionLabel('EXPLORE', theme),
                      const SizedBox(height: 8),

                      // Random Gallery
                      Builder(builder: (context) {
                        final sourceId = context
                                .read<SourceCubit>()
                                .state
                                .activeSource
                                ?.id ??
                            'nhentai';
                        final config = getIt<RemoteConfigService>();
                        if (config.isFeatureEnabled(
                            sourceId, (f) => f.random?.enabled ?? false)) {
                          return _buildNavItem(
                            context,
                            icon: Icons.shuffle_rounded,
                            label: l10n.randomGallery,
                            route: AppRoute.random,
                            isSelected: isSelected(AppRoute.random),
                            theme: theme,
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Favorite Galleries
                      Builder(builder: (context) {
                        final sourceId = context
                                .read<SourceCubit>()
                                .state
                                .activeSource
                                ?.id ??
                            'nhentai';
                        final config = getIt<RemoteConfigService>();
                        // Favorites page should generally be accessible, but if we want to be strict:
                        // checking if ANY source has favorites enabled?
                        // For now, let's keep Favorites always visible or check current source?
                        // Favorites usually contains mixed content. Let's start with checking current source or just keep it.
                        // User JSON "favorite": true.
                        // If feature disabled, maybe we hide it?
                        // But favorites are local. Even if source disables LOOKING UP favorites, local DB still exists.
                        // Let's safe-guard it anyway with the flag if desired, but primarily Random is the one that breaks if API missing.
                        if (config.isFeatureEnabled(
                            sourceId, (f) => f.favorite?.enabled ?? false)) {
                          return _buildNavItem(
                            context,
                            icon: Icons.favorite_rounded,
                            label: l10n.favoriteGalleries,
                            route: AppRoute.favorites,
                            isSelected: isSelected(AppRoute.favorites),
                            theme: theme,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      _buildNavItem(
                        context,
                        icon: Icons.history_rounded,
                        label: l10n.viewHistory,
                        route: AppRoute.history,
                        isSelected: isSelected(AppRoute.history),
                        theme: theme,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildSectionLabel('MORE', theme),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.verified_user_outlined,
                      label: 'Cek Lisensi',
                      route: 'license_check',
                      isSelected: false,
                      theme: theme,
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

              // 3. Footer Card
              _buildDrawerFooter(theme, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Animated Logo
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(4),
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: theme.colorScheme.surface,
                    child: const CircleAvatar(
                      radius: 38,
                      backgroundImage: AssetImage('assets/icons/komiktap.png'),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // App Name with gradient text effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: Text(
              l10n.appTitle,
              style: TextStyleConst.headingMedium.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),

        // Subtitle / Premium Badge
        Builder(
          builder: (context) {
            final licenseService = getIt<LicenseService>();
            final isPremium = licenseService.isPremiumActive;
            final expiry = licenseService.expiresAt;
            final planName = licenseService.planName ?? 'PREMIUM ACTIVE';

            if (isPremium) {
              final activeDate = expiry != null 
                  ? DateFormat('dd MMM yyyy').format(expiry) 
                  : 'Lifetime';
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFF8E1), // Pale Gold
                      const Color(0xFFFFECB3), // Lighter Orange
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, size: 14, color: Color(0xFFE65100)),
                        const SizedBox(width: 4),
                        Text(
                          planName.toUpperCase(),
                          style: TextStyleConst.bodySmall.copyWith(
                            color: const Color(0xFFE65100),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Masa Aktif: $activeDate',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: const Color(0xFFBF360C),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                l10n.appSubtitleDescription,
                style: TextStyleConst.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
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
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNavigation(context, route),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyleConst.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(ThemeData theme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.verified,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appTitle,
                  style: TextStyleConst.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _appVersion,
                  style: TextStyleConst.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
