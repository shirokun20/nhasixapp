import '../../../domain/entities/entities.dart';
import '../base/base_cubit.dart';

/// History screen states
abstract class HistoryState extends BaseCubitState {
  const HistoryState();
}

/// Initial state
class HistoryInitial extends HistoryState {
  const HistoryInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state
class HistoryLoading extends HistoryState {
  const HistoryLoading();

  @override
  List<Object?> get props => [];
}

/// Loaded state with history data
class HistoryLoaded extends HistoryState {
  const HistoryLoaded({
    required this.history,
    required this.hasReachedMax,
    required this.currentPage,
    this.isLoadingMore = false,
  });

  final List<History> history;
  final bool hasReachedMax;
  final int currentPage;
  final bool isLoadingMore;

  @override
  List<Object?> get props => [history, hasReachedMax, currentPage, isLoadingMore];

  HistoryLoaded copyWith({
    List<History>? history,
    bool? hasReachedMax,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return HistoryLoaded(
      history: history ?? this.history,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Error state
class HistoryError extends HistoryState {
  const HistoryError({
    required this.message,
    this.canRetry = true,
  });

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry];
}

/// Empty state (no history)
class HistoryEmpty extends HistoryState {
  const HistoryEmpty();

  @override
  List<Object?> get props => [];
}

/// Clearing state
class HistoryClearing extends HistoryState {
  const HistoryClearing();

  @override
  List<Object?> get props => [];
}

/// Item removed state
class HistoryItemRemoved extends HistoryState {
  const HistoryItemRemoved({
    required this.removedContentId,
    required this.updatedHistory,
  });

  final String removedContentId;
  final List<History> updatedHistory;

  @override
  List<Object?> get props => [removedContentId, updatedHistory];
}
