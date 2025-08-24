
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/content/content_usecases.dart';
import '../../../domain/usecases/content/get_content_detail_usecase.dart';
import '../../../domain/usecases/favorites/favorites_usecases.dart';
import '../../../domain/repositories/repositories.dart';
import '../base/base_cubit.dart';

part 'detail_state.dart';

/// Cubit for managing content detail view and favorite toggle
/// Simple state management for detail screen operations
class DetailCubit extends BaseCubit<DetailState> {
  DetailCubit({
    required GetContentDetailUseCase getContentDetailUseCase,
    required AddToFavoritesUseCase addToFavoritesUseCase,
    required RemoveFromFavoritesUseCase removeFromFavoritesUseCase,
    required UserDataRepository userDataRepository,
    required super.logger,
  })  : _getContentDetailUseCase = getContentDetailUseCase,
        _addToFavoritesUseCase = addToFavoritesUseCase,
        _removeFromFavoritesUseCase = removeFromFavoritesUseCase,
        _userDataRepository = userDataRepository,
        super(
          initialState: const DetailInitial(),
        );

  final GetContentDetailUseCase _getContentDetailUseCase;
  final AddToFavoritesUseCase _addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase _removeFromFavoritesUseCase;
  final UserDataRepository _userDataRepository;

  /// Load content detail by ID
  Future<void> loadContentDetail(String contentId) async {
    try {
      logInfo('Loading content detail for ID: $contentId');
      emit(const DetailLoading());

      final params = GetContentDetailParams.fromString(contentId);
      final content = await _getContentDetailUseCase(params);

      // Check if content is favorited (placeholder for now)
      final isFavorited = await _checkIfFavorited(contentId);

      emit(DetailLoaded(
        content: content,
        isFavorited: isFavorited,
        lastUpdated: DateTime.now(),
      ));

      logInfo('Successfully loaded content detail: ${content.title}');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'load content detail');

      final errorType = determineErrorType(e);
      emit(DetailError(
        message: 'Failed to load content detail: ${e.toString()}',
        errorType: errorType,
        canRetry: isRetryableError(errorType),
        contentId: contentId,
      ));
    }
  }

  /// Toggle favorite status of current content
  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! DetailLoaded) {
      logWarning('Cannot toggle favorite: content not loaded');
      return;
    }

    try {
      logInfo('Toggling favorite for content: ${currentState.content.id}');

      // Show optimistic update
      emit(currentState.copyWith(
        isFavorited: !currentState.isFavorited,
        isTogglingFavorite: true,
      ));

      // Perform actual toggle operation
      if (currentState.isFavorited) {
        await _removeFromFavorites(currentState.content.id);
        logInfo('Removed from favorites: ${currentState.content.title}');
      } else {
        await _addToFavorites(currentState.content);
        logInfo('Added to favorites: ${currentState.content.title}');
      }

      // Update state with final result
      emit(currentState.copyWith(
        isFavorited: !currentState.isFavorited,
        isTogglingFavorite: false,
        lastUpdated: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'toggle favorite');

      // Revert optimistic update on error
      emit(currentState.copyWith(
        isFavorited: currentState.isFavorited, // Revert to original state
        isTogglingFavorite: false,
      ));

      // Show error as snackbar or toast (handled by UI)
      logWarning('Failed to toggle favorite: ${e.toString()}');
    }
  }

  /// Refresh content detail
  Future<void> refreshContent() async {
    final currentState = state;
    if (currentState is DetailLoaded) {
      logInfo('Refreshing content detail');
      await loadContentDetail(currentState.content.id);
    }
  }

  /// Retry loading content after error
  Future<void> retryLoading() async {
    final currentState = state;
    if (currentState is DetailError && currentState.contentId != null) {
      logInfo('Retrying content load');
      await loadContentDetail(currentState.contentId!);
    }
  }

  /// Update content in current state (for external updates)
  void updateContent(Content updatedContent) {
    final currentState = state;
    if (currentState is DetailLoaded &&
        currentState.content.id == updatedContent.id) {
      logInfo('Updating content in detail state');
      emit(currentState.copyWith(
        content: updatedContent,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Check if content is favorited
  Future<bool> _checkIfFavorited(String contentId) async {
    try {
      return await _userDataRepository.isFavorite(contentId);
    } catch (e) {
      logWarning('Failed to check favorite status: ${e.toString()}');
      return false;
    }
  }

  /// Add content to favorites
  Future<void> _addToFavorites(Content content) async {
    try {
      final params = AddToFavoritesParams.create(content);
      await _addToFavoritesUseCase(params);
      logDebug('Added to favorites: ${content.title}');
    } catch (e) {
      throw Exception('Failed to add to favorites: ${e.toString()}');
    }
  }

  /// Remove content from favorites
  Future<void> _removeFromFavorites(String contentId) async {
    try {
      final params = RemoveFromFavoritesParams.fromString(contentId);
      await _removeFromFavoritesUseCase(params);
      logDebug('Removed from favorites: $contentId');
    } catch (e) {
      throw Exception('Failed to remove from favorites: ${e.toString()}');
    }
  }

  /// Get current content
  Content? get currentContent {
    final currentState = state;
    if (currentState is DetailLoaded) {
      return currentState.content;
    }
    return null;
  }

  /// Check if current content is favorited
  bool get isFavorited {
    final currentState = state;
    if (currentState is DetailLoaded) {
      return currentState.isFavorited;
    }
    return false;
  }

  /// Check if currently toggling favorite
  bool get isTogglingFavorite {
    final currentState = state;
    if (currentState is DetailLoaded) {
      return currentState.isTogglingFavorite;
    }
    return false;
  }
}
