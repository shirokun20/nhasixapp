import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/web.dart';

import '../../../core/constants/colors_const.dart';
import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../cubits/favorite/favorite_cubit.dart';
import '../../widgets/widgets.dart';
import '../../widgets/app_scaffold_with_offline.dart';

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
              'Removed $selectedCount favorites',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextPrimary),
            ),
            backgroundColor: ColorsConst.accentGreen,
          ),
        );
      }
    } catch (e) {
      Logger().e('Error removing batch favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove favorites: ${e.toString()}',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextPrimary),
            ),
            backgroundColor: ColorsConst.accentRed,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ColorsConst.darkCard,
            title: Text(
              'Delete Favorites',
              style: TextStyleConst.withColor(
                  TextStyleConst.headingMedium, ColorsConst.darkTextPrimary),
            ),
            content: Text(
              'Are you sure you want to remove $count favorite${count > 1 ? 's' : ''}?',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyleConst.withColor(TextStyleConst.buttonMedium,
                      ColorsConst.darkTextSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyleConst.withColor(
                      TextStyleConst.buttonMedium, ColorsConst.accentRed),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showExportDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsConst.darkCard,
        title: Text(
          'Export Favorites',
          style: TextStyleConst.withColor(
              TextStyleConst.headingMedium, ColorsConst.darkTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: ColorsConst.accentBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Exporting favorites...',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextSecondary),
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ColorsConst.darkCard,
            title: Text(
              'Export Complete',
              style: TextStyleConst.withColor(
                  TextStyleConst.headingMedium, ColorsConst.darkTextPrimary),
            ),
            content: Text(
              'Exported ${exportData['total_count']} favorites successfully.',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyleConst.withColor(
                      TextStyleConst.buttonMedium, ColorsConst.accentBlue),
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
              'Export failed: ${e.toString()}',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextPrimary),
            ),
            backgroundColor: ColorsConst.accentRed,
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
        title: 'Favorites',
        backgroundColor: ColorsConst.darkBackground,
        appBar: _buildAppBar(),
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
      backgroundColor: ColorsConst.darkSurface,
      elevation: 0,
      title: Text(
        _isSelectionMode ? '${_selectedItems.length} selected' : 'Favorites',
        style: TextStyleConst.withColor(
            TextStyleConst.headingMedium, ColorsConst.darkTextPrimary),
      ),
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close, color: ColorsConst.darkTextPrimary),
              onPressed: _toggleSelectionMode,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: ColorsConst.darkTextPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        if (!_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all,
                color: ColorsConst.darkTextPrimary),
            onPressed: _toggleSelectionMode,
            tooltip: 'Select favorites',
          ),
          PopupMenuButton<String>(
            icon:
                const Icon(Icons.more_vert, color: ColorsConst.darkTextPrimary),
            color: ColorsConst.darkCard,
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
                    const Icon(Icons.download,
                        color: ColorsConst.darkTextSecondary),
                    const SizedBox(width: 12),
                    Text(
                      'Export',
                      style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                          ColorsConst.darkTextPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(Icons.refresh,
                        color: ColorsConst.darkTextSecondary),
                    const SizedBox(width: 12),
                    Text(
                      'Refresh',
                      style: TextStyleConst.withColor(TextStyleConst.bodyMedium,
                          ColorsConst.darkTextPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: ColorsConst.accentRed),
              onPressed: _deleteSelected,
              tooltip: 'Delete selected',
            ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ColorsConst.darkSurface,
      child: TextField(
        controller: _searchController,
        style: TextStyleConst.withColor(
            TextStyleConst.bodyMedium, ColorsConst.darkTextPrimary),
        decoration: InputDecoration(
          hintText: 'Search favorites...',
          hintStyle: TextStyleConst.withColor(
              TextStyleConst.bodyMedium, ColorsConst.darkTextSecondary),
          prefixIcon:
              const Icon(Icons.search, color: ColorsConst.darkTextSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: ColorsConst.darkTextSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _favoriteCubit.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: ColorsConst.darkCard,
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
      color: ColorsConst.darkCard,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => _selectAll(state.favorites),
            icon: const Icon(Icons.select_all, color: ColorsConst.accentBlue),
            label: Text(
              'Select All',
              style: TextStyleConst.withColor(
                  TextStyleConst.buttonMedium, ColorsConst.accentBlue),
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _clearSelection,
            icon: const Icon(Icons.clear, color: ColorsConst.darkTextSecondary),
            label: Text(
              'Clear',
              style: TextStyleConst.withColor(
                  TextStyleConst.buttonMedium, ColorsConst.darkTextSecondary),
            ),
          ),
          const Spacer(),
          Text(
            '${_selectedItems.length} / ${state.favorites.length}',
            style: TextStyleConst.withColor(
                TextStyleConst.caption, ColorsConst.darkTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FavoriteState state) {
    if (state is FavoriteLoading) {
      return const Center(
        child: AppProgressIndicator(
          message: 'Loading favorites...',
        ),
      );
    }

    if (state is FavoriteError) {
      return Center(
        child: AppErrorWidget(
          title: 'Error Loading Favorites',
          message: state.userMessage,
          onRetry: state.canRetry
              ? () => _favoriteCubit.retryLoading()
              : null,
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
              color: ColorsConst.darkTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              state.emptyMessage,
              style: TextStyleConst.withColor(
                  TextStyleConst.headingSmall, ColorsConst.darkTextSecondary),
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
                  backgroundColor: ColorsConst.accentBlue,
                  foregroundColor: ColorsConst.darkTextPrimary,
                ),
                child: const Text('Clear Search'),
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
      color: ColorsConst.accentBlue,
      backgroundColor: ColorsConst.darkSurface,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.favorites.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.favorites.length) {
            // Loading more indicator
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: ColorsConst.accentBlue,
                ),
              ),
            );
          }

          final favorite = state.favorites[index];
          final contentId = favorite['id'].toString();
          final isSelected = _selectedItems.contains(contentId);

          return _buildFavoriteCard(favorite, isSelected);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite, bool isSelected) {
    final contentId = favorite['id'].toString();
    final coverUrl = favorite['cover_url']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleItemSelection(contentId);
        } else {
          // Navigate to content detail
          context.push('/content/$contentId');
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
          color: ColorsConst.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: ColorsConst.accentBlue, width: 2)
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
                      Text(
                        'ID: $contentId',
                        style: TextStyleConst.withColor(TextStyleConst.caption,
                            ColorsConst.darkTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(favorite['added_at']),
                        style: TextStyleConst.withColor(TextStyleConst.caption,
                            ColorsConst.darkTextTertiary),
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
                        ? ColorsConst.accentBlue
                        : ColorsConst.darkSurface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? ColorsConst.darkTextPrimary
                        : ColorsConst.darkTextSecondary,
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
                    color: ColorsConst.darkSurface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.favorite,
                        color: ColorsConst.accentRed),
                    onPressed: () {
                      // Show confirmation dialog before removing
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: ColorsConst.darkCard,
                          title: Text(
                            'Remove Favorite',
                            style: TextStyleConst.withColor(
                                TextStyleConst.headingMedium, 
                                ColorsConst.darkTextPrimary),
                          ),
                          content: Text(
                            'Are you sure you want to remove this content from favorites?',
                            style: TextStyleConst.withColor(
                                TextStyleConst.bodyMedium, 
                                ColorsConst.darkTextSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyleConst.withColor(
                                    TextStyleConst.buttonMedium,
                                    ColorsConst.darkTextSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _removeFavorite(contentId);
                              },
                              child: Text(
                                'Remove',
                                style: TextStyleConst.withColor(
                                    TextStyleConst.buttonMedium, 
                                    ColorsConst.accentRed),
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
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
                'Removing from favorites...',
                style: TextStyleConst.withColor(
                    TextStyleConst.bodyMedium, ColorsConst.darkTextPrimary),
              ),
            ],
          ),
          backgroundColor: ColorsConst.darkCard,
          duration: const Duration(minutes: 1), // Long duration while processing
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
              'Removed from favorites',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextPrimary),
            ),
            backgroundColor: ColorsConst.accentGreen,
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
              'Failed to remove favorite: ${e.toString()}',
              style: TextStyleConst.withColor(
                  TextStyleConst.bodyMedium, ColorsConst.darkTextPrimary),
            ),
            backgroundColor: ColorsConst.accentRed,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: ColorsConst.darkTextPrimary,
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
