
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';
import '../../../services/history_cleanup_service.dart';
import '../../../l10n/app_localizations.dart';
import '../base/base_cubit.dart';
import 'history_state.dart';

/// Cubit for managing history screen state
class HistoryCubit extends BaseCubit<HistoryState> {
  HistoryCubit({
    required this.getHistoryUseCase,
    required this.clearHistoryUseCase,
    required this.removeHistoryItemUseCase,
    required this.getHistoryCountUseCase,
    required this.historyCleanupService,
    required super.logger,
    this.localizations,
  }) : super(
          initialState: const HistoryInitial(),
        );

  final GetHistoryUseCase getHistoryUseCase;
  final ClearHistoryUseCase clearHistoryUseCase;
  final RemoveHistoryItemUseCase removeHistoryItemUseCase;
  final GetHistoryCountUseCase getHistoryCountUseCase;
  final HistoryCleanupService historyCleanupService;
  final AppLocalizations? localizations;

  static const int _pageSize = 50;
  
  /// Load history from the beginning
  Future<void> loadHistory() async {
    try {
      logInfo('Loading history');
      emit(const HistoryLoading());

      final history = await getHistoryUseCase(
        const GetHistoryParams(page: 1, limit: _pageSize),
      );

      if (history.isEmpty) {
        emit(const HistoryEmpty());
        logDebug('No history found');
      } else {
        emit(HistoryLoaded(
          history: history,
          hasReachedMax: history.length < _pageSize,
          currentPage: 1,
        ));
        logDebug('Loaded ${history.length} history entries');
      }
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'load history');
      emit(HistoryError(
        message: localizations?.failedToLoadHistory(e.toString()) ?? 'Failed to load history: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Load more history (pagination)
  Future<void> loadMoreHistory() async {
    final currentState = state;
    if (currentState is! HistoryLoaded || 
        currentState.hasReachedMax || 
        currentState.isLoadingMore) {
      return;
    }

    try {
      logInfo('Loading more history (page ${currentState.currentPage + 1})');
      
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.currentPage + 1;
      final moreHistory = await getHistoryUseCase(
        GetHistoryParams(page: nextPage, limit: _pageSize),
      );

      final updatedHistory = [...currentState.history, ...moreHistory];
      final hasReachedMax = moreHistory.length < _pageSize;

      emit(HistoryLoaded(
        history: updatedHistory,
        hasReachedMax: hasReachedMax,
        currentPage: nextPage,
        isLoadingMore: false,
      ));

      logDebug('Loaded ${moreHistory.length} more entries, total: ${updatedHistory.length}');
    } catch (e, stackTrace) {
      final currentState = state;
      if (currentState is HistoryLoaded) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
      
      handleError(e, stackTrace, 'load more history');
      // Don't emit error state for pagination failures
      // Just log and continue with current state
    }
  }

  /// Refresh history (pull to refresh)
  Future<void> refreshHistory() async {
    try {
      logInfo('Refreshing history');
      
      final history = await getHistoryUseCase(
        const GetHistoryParams(page: 1, limit: _pageSize),
      );

      if (history.isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(HistoryLoaded(
          history: history,
          hasReachedMax: history.length < _pageSize,
          currentPage: 1,
        ));
      }

      logDebug('Refreshed history with ${history.length} entries');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'refresh history');
      emit(HistoryError(
        message: localizations?.failedToRefreshHistory(e.toString()) ?? 'Failed to refresh history: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    try {
      logInfo('Clearing all history');
      emit(const HistoryClearing());

      await clearHistoryUseCase(NoParams());
      
      emit(const HistoryEmpty());
      logDebug('All history cleared');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'clear history');
      emit(HistoryError(
        message: localizations?.failedToClearHistory(e.toString()) ?? 'Failed to clear history: ${e.toString()}',
        canRetry: false,
      ));
    }
  }

  /// Remove specific history item
  Future<void> removeHistoryItem(String contentId) async {
    final currentState = state;
    if (currentState is! HistoryLoaded) return;

    try {
      logInfo('Removing history item: $contentId');
      
      await removeHistoryItemUseCase(
        RemoveHistoryItemParams.fromContentId(contentId),
      );

      final updatedHistory = currentState.history
          .where((item) => item.contentId != contentId)
          .toList();

      if (updatedHistory.isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(currentState.copyWith(history: updatedHistory));
      }

      logDebug('Removed history item: $contentId');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'remove history item');
      emit(HistoryError(
        message: localizations?.failedToRemoveHistoryItem(e.toString()) ?? 'Failed to remove history item: ${e.toString()}',
        canRetry: false,
      ));
    }
  }

  /// Get history count
  Future<int> getHistoryCount() async {
    try {
      return await getHistoryCountUseCase(NoParams());
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get history count');
      return 0;
    }
  }

  /// Get cleanup status
  Future<HistoryCleanupStatus> getCleanupStatus() async {
    try {
      return await historyCleanupService.getCleanupStatus();
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get cleanup status');
      return const HistoryCleanupStatus();
    }
  }

  /// Trigger manual cleanup
  Future<void> performManualCleanup() async {
    try {
      logInfo('Performing manual history cleanup');
      emit(const HistoryClearing());

      await historyCleanupService.performManualCleanup();
      
      // Reload history after cleanup
      await loadHistory();
      
      logDebug('Manual cleanup completed');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'manual cleanup');
      emit(HistoryError(
        message: localizations?.failedToPerformCleanup(e.toString()) ?? 'Failed to perform cleanup: ${e.toString()}',
        canRetry: true,
      ));
    }
  }

  /// Update cleanup settings
  Future<void> updateCleanupSettings(UserPreferences preferences) async {
    try {
      logInfo('Updating cleanup settings');
      await historyCleanupService.updateCleanupSettings(preferences);
      logDebug('Cleanup settings updated');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'update cleanup settings');
      // Don't emit error state for settings update
    }
  }

  /// Check if history item exists
  bool hasHistoryItem(String contentId) {
    final currentState = state;
    if (currentState is HistoryLoaded) {
      return currentState.history.any((item) => item.contentId == contentId);
    }
    return false;
  }

  /// Get history item by content ID
  History? getHistoryItem(String contentId) {
    final currentState = state;
    if (currentState is HistoryLoaded) {
      try {
        return currentState.history.firstWhere(
          (item) => item.contentId == contentId,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get current history count from state
  int get currentHistoryCount {
    final currentState = state;
    if (currentState is HistoryLoaded) {
      return currentState.history.length;
    }
    return 0;
  }

  /// Check if more history can be loaded
  bool get canLoadMore {
    final currentState = state;
    return currentState is HistoryLoaded && 
           !currentState.hasReachedMax && 
           !currentState.isLoadingMore;
  }

  /// Check if history is empty
  bool get isEmpty {
    return state is HistoryEmpty;
  }

  /// Check if history is loading
  bool get isLoading {
    return state is HistoryLoading || state is HistoryClearing;
  }

  /// Check if history has error
  bool get hasError {
    return state is HistoryError;
  }
}
