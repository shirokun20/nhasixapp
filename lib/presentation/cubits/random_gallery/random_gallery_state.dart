part of 'random_gallery_cubit.dart';

/// Base state for RandomGalleryCubit
abstract class RandomGalleryState extends BaseCubitState {
  const RandomGalleryState();
}

/// Initial state before loading random gallery
class RandomGalleryInitial extends RandomGalleryState {
  const RandomGalleryInitial();

  @override
  List<Object?> get props => [];
}

/// State when loading random gallery
class RandomGalleryLoading extends RandomGalleryState {
  const RandomGalleryLoading({
    this.message = 'Loading random gallery...',
  });

  final String message;

  @override
  List<Object?> get props => [message];
}

/// State when random gallery is loaded successfully
class RandomGalleryLoaded extends RandomGalleryState {
  const RandomGalleryLoaded({
    required this.currentGallery,
    required this.isFavorite,
    required this.hasIgnoredTags,
    required this.preloadedCount,
    required this.lastUpdated,
    this.isShuffling = false,
    this.isToggling = false,
  });

  final Content currentGallery;
  final bool isFavorite;
  final bool hasIgnoredTags;
  final int preloadedCount;
  final bool isShuffling;
  final bool isToggling;
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [
        currentGallery,
        isFavorite,
        hasIgnoredTags,
        preloadedCount,
        isShuffling,
        isToggling,
        lastUpdated,
      ];

  /// Create a copy with updated properties
  RandomGalleryLoaded copyWith({
    Content? currentGallery,
    bool? isFavorite,
    bool? hasIgnoredTags,
    int? preloadedCount,
    bool? isShuffling,
    bool? isToggling,
    DateTime? lastUpdated,
  }) {
    return RandomGalleryLoaded(
      currentGallery: currentGallery ?? this.currentGallery,
      isFavorite: isFavorite ?? this.isFavorite,
      hasIgnoredTags: hasIgnoredTags ?? this.hasIgnoredTags,
      preloadedCount: preloadedCount ?? this.preloadedCount,
      isShuffling: isShuffling ?? this.isShuffling,
      isToggling: isToggling ?? this.isToggling,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if we have enough preloaded galleries for smooth experience
  bool get hasEnoughPreloaded => preloadedCount >= 2;

  /// Check if preloading is needed (always false in single-gallery mode)
  bool get needsPreloading => false;
}

/// Error state when failed to load random gallery
class RandomGalleryError extends RandomGalleryState {
  const RandomGalleryError({
    required this.error,
    required this.stackTrace,
    this.previousState,
  });

  final String error;
  final StackTrace stackTrace;
  final RandomGalleryState? previousState;

  @override
  List<Object?> get props => [error, stackTrace, previousState];

  /// Get user-friendly error message
  String get userMessage {
    if (error.contains('network') || error.contains('internet')) {
      return 'No internet connection. Please check your network.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('server')) {
      return 'Server error. Please try again later.';
    }
    return 'Failed to load random gallery. Please try again.';
  }

  /// Check if can retry
  bool get canRetry => !error.contains('server') || previousState != null;
}
