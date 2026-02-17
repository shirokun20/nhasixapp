import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/shimmer_loading_widgets.dart';

import 'package:kuron_core/kuron_core.dart';
import 'package:logger/web.dart';

import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/responsive_grid_delegate.dart';
import '../../cubits/favorite/favorite_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../widgets/widgets.dart';
import '../../widgets/app_scaffold_with_offline.dart';
import '../../widgets/highlighted_text_widget.dart';

/// Screen for managing user's favorite content
/// Features: favorites list, search, batch operations, export/import
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Selection mode for batch operations
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = <String>{};

  // Cubit instance to avoid context issues
  late FavoriteCubit _favoriteCubit;

  @override
  void initState() {
    super.initState();
    _favoriteCubit = getIt<FavoriteCubit>();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _favoriteCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      _favoriteCubit.loadMoreFavorites();
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String contentId) {
    setState(() {
      if (_selectedItems.contains(contentId)) {
        _selectedItems.remove(contentId);
      } else {
        _selectedItems.add(contentId);
      }
    });
  }

  void _selectAll(List<Map<String, dynamic>> favorites) {
    setState(() {
      _selectedItems.clear();
      _selectedItems.addAll(
        favorites.map((favorite) => favorite['id'].toString()),
      );
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await _showDeleteConfirmation(_selectedItems.length);
    if (!confirmed) return;

    // Store the count before async operations
    final selectedCount = _selectedItems.length;
    final selectedItemsList = _selectedItems.toList();

    try {
      await _favoriteCubit.removeBatchFavorites(selectedItemsList);

      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .removedFavoritesCount(selectedCount),
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      Logger().e('Error removing batch favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .failedToRemoveFavorites(e.toString()),
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            title: Text(
              AppLocalizations.of(context)!.deleteFavorites,
              style: TextStyleConst.withColor(TextStyleConst.headingMedium,
                  Theme.of(context).colorScheme.onSurface),
            ),
            content: Text(
              AppLocalizations.of(context)!
                  .deleteFavoritesConfirmation(count, count > 1 ? 's' : ''),
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyleConst.withColor(TextStyleConst.buttonMedium,
                      Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  AppLocalizations.of(context)!.delete,
                  style: TextStyleConst.withColor(TextStyleConst.buttonMedium,
                      Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showExportDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          AppLocalizations.of(context)!.exportFavorites,
          style: TextStyleConst.withColor(TextStyleConst.headingMedium,
              Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.exportingFavorites,
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    try {
      final exportData = await _favoriteCubit.exportFavorites();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show export result
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            title: Text(
              'Export Complete',
              style: TextStyleConst.withColor(TextStyleConst.headingMedium,
                  Theme.of(context).colorScheme.onSurface),
            ),
            content: Text(
              'Exported ${exportData['total_count']} favorites successfully.',
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.ok,
                  style: TextStyleConst.withColor(TextStyleConst.buttonMedium,
                      Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.exportFailed(e.toString()),
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _favoriteCubit..loadFavorites(),
      child: AppScaffoldWithOffline(
        title: AppLocalizations.of(context)!.favorites,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(),
        drawer: AppMainDrawerWidget(context: context),
        body: BlocBuilder<FavoriteCubit, FavoriteState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildSearchBar(),
                if (_isSelectionMode) _buildSelectionToolbar(state),
                Expanded(child: _buildContent(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 0,
      title: Text(
        _isSelectionMode
            ? AppLocalizations.of(context)!
                .selectedItemsCount(_selectedItems.length)
            : AppLocalizations.of(context)!.favorites,
        style: TextStyleConst.withColor(TextStyleConst.headingMedium,
            Theme.of(context).colorScheme.onSurface),
      ),
      leading: _isSelectionMode
          ? IconButton(
              icon: Icon(Icons.close,
                  color: Theme.of(context).colorScheme.onSurface),
              onPressed: _toggleSelectionMode,
            )
          : null,
      actions: [
        if (!_isSelectionMode) ...[
          IconButton(
            icon: Icon(Icons.select_all,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: _toggleSelectionMode,
            tooltip: AppLocalizations.of(context)!.selectFavoritesTooltip,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurface),
            color: Theme.of(context).colorScheme.surfaceContainer,
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _showExportDialog();
                  break;
                case 'refresh':
                  _favoriteCubit.refresh();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.exportAction,
                      style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                          Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.refreshAction,
                      style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                          Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.error),
              onPressed: _deleteSelected,
              tooltip: AppLocalizations.of(context)!.deleteSelectedTooltip,
            ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: TextField(
        controller: _searchController,
        style: TextStyleConst.withColor(
            TextStyleConst.bodyMedium, Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchFavoritesHint,
          hintStyle: TextStyleConst.withColor(TextStyleConst.bodyMedium,
              Theme.of(context).colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    _favoriteCubit.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (query) {
          _favoriteCubit.searchFavorites(query);
        },
      ),
    );
  }

  Widget _buildSelectionToolbar(FavoriteState state) {
    if (state is! FavoriteLoaded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => _selectAll(state.favorites),
            icon: Icon(Icons.select_all,
                color: Theme.of(context).colorScheme.primary),
            label: Text(
              AppLocalizations.of(context)!.selectAll,
              style: TextStyleConst.withColor(TextStyleConst.buttonMedium,
                  Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _clearSelection,
            icon: Icon(Icons.clear,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            label: Text(
              AppLocalizations.of(context)!.clear,
              style: TextStyleConst.withColor(TextStyleConst.buttonMedium,
                  Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const Spacer(),
          Text(
            '${_selectedItems.length} / ${state.favorites.length}',
            style: TextStyleConst.withColor(TextStyleConst.caption,
                Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FavoriteState state) {
    if (state is FavoriteLoading) {
      return const ListShimmer(itemCount: 8);
    }

    if (state is FavoriteError) {
      return Center(
        child: AppErrorWidget(
          title: AppLocalizations.of(context)!.errorLoadingFavoritesTitle,
          message: state.getUserMessage(AppLocalizations.of(context)),
          onRetry: state.canRetry ? () => _favoriteCubit.retryLoading() : null,
        ),
      );
    }

    if (state is FavoriteLoaded) {
      if (state.isEmpty) {
        return _buildEmptyState(state);
      }

      return _buildFavoritesList(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(FavoriteLoaded state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isSearching ? Icons.search_off : Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.getEmptyMessage(AppLocalizations.of(context)),
              style: TextStyleConst.withColor(TextStyleConst.headingSmall,
                  Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (state.isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _favoriteCubit.clearSearch();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(AppLocalizations.of(context)!.clearSearch),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(FavoriteLoaded state) {
    return RefreshIndicator(
      onRefresh: () => _favoriteCubit.refresh(),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: ResponsiveGridDelegate.createStandardGridDelegate(
              context,
              context.read<SettingsCubit>(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.favorites.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.favorites.length) {
                // Loading more indicator
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              final favorite = state.favorites[index];
              final contentId = favorite['id'].toString();
              final isSelected = _selectedItems.contains(contentId);

              return _buildFavoriteCard(
                  favorite, isSelected, state.searchQuery);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite, bool isSelected,
      [String? searchQuery]) {
    final contentId = favorite['id'].toString();
    final coverUrl = favorite['cover_url']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleItemSelection(contentId);
        } else {
          // Navigate to content detail
          final sourceId = favorite['source_id']?.toString();
          AppRouter.goToContentDetail(context, contentId, sourceId: sourceId);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelectionMode();
          _toggleItemSelection(contentId);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: ContentCard.buildImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      context: context,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source badge + Title row
                      Row(
                        children: [
                          // Source badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getSourceColor(
                                  favorite['source_id']?.toString() ??
                                      SourceType.nhentai.id),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              (favorite['source_id']?.toString() ??
                                      SourceType.nhentai.id)
                                  .toUpperCase(),
                              style: TextStyleConst.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Title (if available)
                          if (favorite['title'] != null)
                            Expanded(
                              child: HighlightedText(
                                text: favorite['title'].toString(),
                                highlight: searchQuery ?? '',
                                style: TextStyleConst.caption.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // ID + Date row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '#$contentId',
                              style: TextStyleConst.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(favorite['added_at']),
                            style: TextStyleConst.caption.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
            if (!_isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.favorite,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () {
                      // Show confirmation dialog before removing
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          title: Text(
                            AppLocalizations.of(context)!.removeFavorite,
                            style: TextStyleConst.withColor(
                                TextStyleConst.headingMedium,
                                Theme.of(context).colorScheme.onSurface),
                          ),
                          content: Text(
                            AppLocalizations.of(context)!
                                .removeFavoriteConfirmation,
                            style: TextStyleConst.withColor(
                                TextStyleConst.bodyMedium,
                                Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                AppLocalizations.of(context)!.cancel,
                                style: TextStyleConst.withColor(
                                    TextStyleConst.buttonMedium,
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _removeFavorite(contentId);
                              },
                              child: Text(
                                AppLocalizations.of(context)!.remove,
                                style: TextStyleConst.withColor(
                                    TextStyleConst.buttonMedium,
                                    Theme.of(context).colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSourceColor(String sourceId) {
    if (sourceId.toLowerCase() == SourceType.nhentai.id) {
      return const Color(0xFFEC2854); // nhentai red
    } else if (sourceId.toLowerCase() == SourceType.crotpedia.id) {
      return const Color(0xFF1E88E5); // crotpedia blue
    } else {
      return Theme.of(context).colorScheme.secondary;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) {
      return AppLocalizations.of(context)?.unknown ?? 'Unknown';
    }

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return AppLocalizations.of(context)?.daysAgo(
                difference.inDays, difference.inDays == 1 ? '' : 's') ??
            '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return AppLocalizations.of(context)?.hoursAgo(
                difference.inHours, difference.inHours == 1 ? '' : 's') ??
            '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return AppLocalizations.of(context)?.minutesAgo(
                difference.inMinutes, difference.inMinutes == 1 ? '' : 's') ??
            '${difference.inMinutes}m ago';
      } else {
        return AppLocalizations.of(context)?.justNow ?? 'Just now';
      }
    } catch (e) {
      return AppLocalizations.of(context)?.unknown ?? 'Unknown';
    }
  }

  Future<void> _removeFavorite(String contentId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.removingFromFavorites,
                style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                    Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          duration:
              const Duration(minutes: 1), // Long duration while processing
        ),
      );

      await _favoriteCubit.removeFromFavorites(contentId);

      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.removedFromFavorites,
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger().e('Error removing content from favorites: $e');
      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show detailed error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                      ?.failedToRemoveFavorite(e.toString()) ??
                  'Failed to remove favorite: ${e.toString()}',
              style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                  Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _removeFavorite(contentId),
            ),
          ),
        );
      }

      // Log error for debugging (use logger instead of print in production)
      // print('Error removing favorite $contentId: $e');
    }
  }
}
