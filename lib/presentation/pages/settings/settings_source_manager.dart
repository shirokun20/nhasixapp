part of 'settings_screen.dart';

/// Dedicated screen for installed content sources: install, health-check,
/// activate, and uninstall — moved out of the main settings list so a large
/// catalog doesn't stretch the settings screen.
class SourceManagerScreen extends StatefulWidget {
  const SourceManagerScreen({super.key});

  @override
  State<SourceManagerScreen> createState() => _SourceManagerScreenState();
}

class _SourceManagerScreenState extends State<SourceManagerScreen>
    with WidgetsBindingObserver {
  final SourceHealthMonitor _healthMonitor = getIt<SourceHealthMonitor>();
  Map<String, SourceHealthStatus> _sourceHealthStatuses = {};
  StreamSubscription<Map<String, SourceHealthStatus>>? _healthSub;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runHealthCheck();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _healthSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) _runHealthCheck();
  }

  void _runHealthCheck() {
    _healthSub?.cancel();
    _healthSub = _healthMonitor.healthStream.listen((statuses) {
      if (mounted) setState(() => _sourceHealthStatuses = statuses);
    });
    unawaited(_healthMonitor.checkAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(l10n.availableSources),
              floating: true,
              snap: true,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SourceSearchHeaderDelegate(
                theme: theme,
                l10n: l10n,
                searchQuery: _searchQuery,
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSourceInstallCard(theme, l10n, context),
                  const SizedBox(height: 12),
                  _buildInstalledSourcesList(
                    theme,
                    l10n,
                    context,
                    _sourceHealthStatuses,
                    _runHealthCheck,
                    _searchQuery,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned search bar that stays visible under the app bar while the
/// source list scrolls.
class _SourceSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SourceSearchHeaderDelegate({
    required this.theme,
    required this.l10n,
    required this.searchQuery,
    required this.controller,
    required this.onChanged,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final String searchQuery;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = theme.colorScheme;
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyleConst.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: l10n.sourceSelectorSearchHint,
            hintStyle: TextStyleConst.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SourceSearchHeaderDelegate oldDelegate) {
    return oldDelegate.searchQuery != searchQuery ||
        oldDelegate.theme != theme ||
        oldDelegate.l10n != l10n;
  }
}
