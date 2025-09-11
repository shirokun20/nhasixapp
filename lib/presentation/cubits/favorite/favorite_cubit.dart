
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/favorites/favorites_usecases.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../l10n/app_localizations.dart';
import '../base/base_cubit.dart';

part 'favorite_state.dart';

/// Cubit for managing favorites with simple CRUD operations
/// Handles favorites list, categories, and batch operations
class FavoriteCubit extends BaseCubit<FavoriteState> {
  FavoriteCubit({
    required AddToFavoritesUseCase addToFavoritesUseCase,
    required GetFavoritesUseCase getFavoritesUseCase,
    required RemoveFromFavoritesUseCase removeFromFavoritesUseCase,
    required UserDataRepository userDataRepository,
    required super.logger,
    this.localizations,
  })  : _addToFavoritesUseCase = addToFavoritesUseCase,
        _getFavoritesUseCase = getFavoritesUseCase,
        _removeFromFavoritesUseCase = removeFromFavoritesUseCase,
        _userDataRepository = userDataRepository,
        super(
          initialState: const FavoriteInitial(),
        );

  final AddToFavoritesUseCase _addToFavoritesUseCase;
  final GetFavoritesUseCase _getFavoritesUseCase;
  final RemoveFromFavoritesUseCase _removeFromFavoritesUseCase;
  final UserDataRepository _userDataRepository;
  final AppLocalizations? localizations;

  // Current page for pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 20;

  /// Load favorites list
  Future<void> loadFavorites({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        logInfo('Refreshing favorites list');
        emit(const FavoriteLoading());
      } else if (state is FavoriteInitial) {
        logInfo('Loading favorites list');
        emit(const FavoriteLoading());
      }

      final params =
          GetFavoritesParams.page(_currentPage, limit: _itemsPerPage);
      final favorites = await _getFavoritesUseCase(params);
      final totalCount = await _userDataRepository.getFavoritesCount();

      final hasMore = favorites.length == _itemsPerPage;

      emit(FavoriteLoaded(
        favorites: favorites,
        currentPage: _currentPage,
        hasMore: hasMore,
        totalCount: totalCount,
        lastUpdated: DateTime.now(),
      ));

      logInfo(
          'Successfully loaded ${favorites.length} favorites (page $_currentPage)');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'load favorites');

      final errorType = determineErrorType(e);
      emit(FavoriteError(
        message: localizations?.failedToLoadFavorites(e.toString()) ?? 'Failed to load favorites: ${e.toString()}',
        errorType: errorType,
        canRetry: isRetryableError(errorType),
      ));
    }
  }

  /// Load more favorites (pagination)
  Future<void> loadMoreFavorites() async {
    final currentState = state;
    if (currentState is! FavoriteLoaded || !currentState.hasMore) {
      return;
    }

    try {
      logInfo('Loading more favorites (page ${_currentPage + 1})');
      emit(currentState.copyWith(isLoadingMore: true));

      _currentPage++;
      final params =
          GetFavoritesParams.page(_currentPage, limit: _itemsPerPage);
      final newFavorites = await _getFavoritesUseCase(params);

      final allFavorites = [...currentState.favorites, ...newFavorites];
      final hasMore = newFavorites.length == _itemsPerPage;

      emit(currentState.copyWith(
        favorites: allFavorites,
        currentPage: _currentPage,
        hasMore: hasMore,
        isLoadingMore: false,
        lastUpdated: DateTime.now(),
      ));

      logInfo('Successfully loaded ${newFavorites.length} more favorites');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'load more favorites');

      // Revert page increment on error
      _currentPage--;

      final currentState = state;
      if (currentState is FavoriteLoaded) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  /// Add content to favorites
  Future<void> addToFavorites(Content content) async {
    try {
      logInfo('Adding content to favorites: ${content.title}');

      final params = AddToFavoritesParams.create(content);
      await _addToFavoritesUseCase(params);

      // Update current state if loaded
      final currentState = state;
      if (currentState is FavoriteLoaded) {
        // Add to beginning of list
        final newFavorite = {
          'id': content.id,
          'cover_url': content.coverUrl,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        };

        final updatedFavorites = [newFavorite, ...currentState.favorites];

        emit(currentState.copyWith(
          favorites: updatedFavorites,
          totalCount: currentState.totalCount + 1,
          lastUpdated: DateTime.now(),
        ));
      }

      logInfo('Successfully added to favorites: ${content.title}');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'add to favorites');
      rethrow; // Let the calling widget handle the error
    }
  }

  /// Remove content from favorites
  Future<void> removeFromFavorites(String contentId) async {
    try {
      logInfo('Starting removal of content from favorites: $contentId');

      // First check if content exists in favorites
      final isFavorite = await _userDataRepository.isFavorite(contentId);
      if (!isFavorite) {
        logWarning('Content $contentId is not in favorites, skipping removal');
        return;
      }

      final params = RemoveFromFavoritesParams.fromString(contentId);
      logInfo('Calling removeFromFavoritesUseCase with params: $params');
      
      await _removeFromFavoritesUseCase(params);
      logInfo('Successfully called removeFromFavoritesUseCase');

      // Update current state if loaded
      final currentState = state;
      if (currentState is FavoriteLoaded) {
        logInfo('Updating favorites list in state, removing contentId: $contentId');
        
        final beforeCount = currentState.favorites.length;
        final updatedFavorites = currentState.favorites
            .where((favorite) => favorite['id'] != contentId)
            .toList();
        final afterCount = updatedFavorites.length;
        
        logInfo('Favorites count: before=$beforeCount, after=$afterCount');

        emit(currentState.copyWith(
          favorites: updatedFavorites,
          totalCount: currentState.totalCount - 1,
          lastUpdated: DateTime.now(),
        ));
        
        logInfo('State updated successfully');
      } else {
        logWarning('Current state is not FavoriteLoaded, state type: ${state.runtimeType}');
      }

      logInfo('Successfully removed from favorites: $contentId');
    } catch (e, stackTrace) {
      logWarning('Error removing content $contentId from favorites: $e');
      handleError(e, stackTrace, 'remove from favorites');
      rethrow; // Let the calling widget handle the error
    }
  }

  /// Check if content is favorited
  Future<bool> isFavorited(String contentId) async {
    try {
      return await _userDataRepository.isFavorite(contentId);
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'check if favorited');
      return false;
    }
  }

  /// Remove multiple favorites (batch operation)
  Future<void> removeBatchFavorites(List<String> contentIds) async {
    if (contentIds.isEmpty) return;

    try {
      logInfo('Removing ${contentIds.length} favorites in batch');

      // Show loading state
      final currentState = state;
      if (currentState is FavoriteLoaded) {
        emit(currentState.copyWith(isBatchOperating: true));
      }

      // Remove each favorite
      for (final contentId in contentIds) {
        final params = RemoveFromFavoritesParams.fromString(contentId);
        await _removeFromFavoritesUseCase(params);
      }

      // Update current state if loaded
      if (currentState is FavoriteLoaded) {
        final updatedFavorites = currentState.favorites
            .where((favorite) => !contentIds.contains(favorite['id']))
            .toList();

        emit(currentState.copyWith(
          favorites: updatedFavorites,
          totalCount: currentState.totalCount - contentIds.length,
          isBatchOperating: false,
          lastUpdated: DateTime.now(),
        ));
      }

      logInfo('Successfully removed ${contentIds.length} favorites in batch');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'batch remove favorites');

      // Reset batch operating state
      final currentState = state;
      if (currentState is FavoriteLoaded) {
        emit(currentState.copyWith(isBatchOperating: false));
      }

      rethrow;
    }
  }

  /// Search within favorites
  Future<void> searchFavorites(String query) async {
    final currentState = state;
    if (currentState is! FavoriteLoaded) {
      return;
    }

    try {
      logInfo('Searching favorites with query: $query');

      if (query.isEmpty) {
        // Reset to show all favorites
        await loadFavorites(refresh: true);
        return;
      }

      // Filter current favorites by query (simple text search)
      final filteredFavorites = currentState.favorites.where((favorite) {
        final id = favorite['id']?.toString().toLowerCase() ?? '';
        return id.contains(query.toLowerCase());
      }).toList();

      emit(currentState.copyWith(
        favorites: filteredFavorites,
        searchQuery: query,
        lastUpdated: DateTime.now(),
      ));

      logInfo('Found ${filteredFavorites.length} favorites matching query');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'search favorites');
    }
  }

  /// Clear search and show all favorites
  Future<void> clearSearch() async {
    logInfo('Clearing favorites search');
    await loadFavorites(refresh: true);
  }

  /// Export favorites data
  Future<Map<String, dynamic>> exportFavorites() async {
    try {
      logInfo('Exporting favorites data');

      final allFavorites = <Map<String, dynamic>>[];
      int page = 1;
      bool hasMore = true;

      // Get all favorites
      while (hasMore) {
        final params = GetFavoritesParams.page(page, limit: 100);
        final favorites = await _getFavoritesUseCase(params);

        allFavorites.addAll(favorites);
        hasMore = favorites.length == 100;
        page++;
      }

      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'total_count': allFavorites.length,
        'favorites': allFavorites,
      };

      logInfo('Successfully exported ${allFavorites.length} favorites');
      return exportData;
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'export favorites');
      rethrow;
    }
  }

  /// Import favorites data
  Future<void> importFavorites(Map<String, dynamic> data) async {
    try {
      logInfo('Importing favorites data');

      final favorites = data['favorites'] as List<dynamic>? ?? [];
      int importedCount = 0;

      for (final favoriteData in favorites) {
        try {
          final id = favoriteData['id']?.toString();
          final coverUrl = favoriteData['cover_url']?.toString();

          if (id != null && coverUrl != null) {
            await _userDataRepository.addToFavorites(
              id: id,
              coverUrl: coverUrl,
            );
            importedCount++;
          }
        } catch (e) {
          logWarning('Failed to import favorite: $e');
          // Continue with next favorite
        }
      }

      // Refresh favorites list
      await loadFavorites(refresh: true);

      logInfo('Successfully imported $importedCount favorites');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'import favorites');
      rethrow;
    }
  }

  /// Get favorites statistics
  Future<Map<String, int>> getFavoritesStats() async {
    try {
      final totalCount = await _userDataRepository.getFavoritesCount();

      return {
        'total_favorites': totalCount,
        'current_page': _currentPage,
        'items_per_page': _itemsPerPage,
      };
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get favorites stats');
      return {};
    }
  }

  /// Retry loading after error
  Future<void> retryLoading() async {
    logInfo('Retrying favorites loading');
    await loadFavorites(refresh: true);
  }

  /// Refresh favorites
  Future<void> refresh() async {
    logInfo('Refreshing favorites');
    await loadFavorites(refresh: true);
  }

  /// Get current favorites list
  List<Map<String, dynamic>> get currentFavorites {
    final currentState = state;
    if (currentState is FavoriteLoaded) {
      return currentState.favorites;
    }
    return [];
  }

  /// Get current favorites count
  int get favoritesCount {
    final currentState = state;
    if (currentState is FavoriteLoaded) {
      return currentState.totalCount;
    }
    return 0;
  }

  /// Check if has more favorites to load
  bool get hasMoreFavorites {
    final currentState = state;
    if (currentState is FavoriteLoaded) {
      return currentState.hasMore;
    }
    return false;
  }

  /// Check if currently loading more
  bool get isLoadingMore {
    final currentState = state;
    if (currentState is FavoriteLoaded) {
      return currentState.isLoadingMore;
    }
    return false;
  }

  /// Check if currently performing batch operation
  bool get isBatchOperating {
    final currentState = state;
    if (currentState is FavoriteLoaded) {
      return currentState.isBatchOperating;
    }
    return false;
  }

  /// Get current search query
  String? get currentSearchQuery {
    final currentState = state;
    if (currentState is FavoriteLoaded) {
      return currentState.searchQuery;
    }
    return null;
  }
}
