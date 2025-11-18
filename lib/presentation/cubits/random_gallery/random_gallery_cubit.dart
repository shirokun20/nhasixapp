import '../../../core/di/service_locator.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/content/get_random_content_usecase.dart';
import '../../../domain/usecases/favorites/favorites_usecases.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../services/analytics_service.dart';
import '../../../utils/performance_monitor.dart';
import '../base/base_cubit.dart';

part 'random_gallery_state.dart';

/// Cubit for managing random gallery state
///
/// This cubit handles loading a single random gallery at a time.
/// No preloading to avoid rate limiting and keep the app lightweight.
class RandomGalleryCubit extends BaseCubit<RandomGalleryState> {
  final GetRandomContentUseCase _getRandomContentUseCase;
  final AddToFavoritesUseCase _addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase _removeFromFavoritesUseCase;
  final UserDataRepository _userDataRepository;
  late final AnalyticsService _analyticsService;

  RandomGalleryCubit({
    required GetRandomContentUseCase getRandomContentUseCase,
    required AddToFavoritesUseCase addToFavoritesUseCase,
    required RemoveFromFavoritesUseCase removeFromFavoritesUseCase,
    required UserDataRepository userDataRepository,
    required super.logger,
  })  : _getRandomContentUseCase = getRandomContentUseCase,
        _addToFavoritesUseCase = addToFavoritesUseCase,
        _removeFromFavoritesUseCase = removeFromFavoritesUseCase,
        _userDataRepository = userDataRepository,
        super(
          initialState: const RandomGalleryInitial(),
        ) {
    _analyticsService = getIt<AnalyticsService>();
  }

  /// Initialize the cubit by loading the first random gallery
  Future<void> initialize() async {
    if (state is RandomGalleryInitial) {
      await _analyticsService.trackAction(
        'random_gallery_initialize',
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      );
      await _loadRandomGallery();
    }
  }

  /// Check if can shuffle (always true when not already shuffling)
  bool get canShuffle {
    final currentState = state;
    return currentState is RandomGalleryLoaded && !currentState.isShuffling;
  }

  /// Shuffle to next random gallery
  Future<void> shuffleToNext() async {
    final currentState = state;
    if (currentState is RandomGalleryLoaded && !currentState.isShuffling) {
      await _analyticsService.trackAction(
        'random_gallery_shuffle',
        parameters: {
          'previous_gallery_id': currentState.currentGallery.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (!isClosed) {
        emit(currentState.copyWith(isShuffling: true));
      }
      await _loadRandomGallery();
    }
  }

  /// Toggle favorite status for current gallery
  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is RandomGalleryLoaded && !currentState.isToggling) {
      if (!isClosed) {
        emit(currentState.copyWith(isToggling: true));
      }

      try {
        final gallery = currentState.currentGallery;
        final isFavorite = currentState.isFavorite;

        if (isFavorite) {
          await _removeFromFavoritesUseCase(
            RemoveFromFavoritesParams.fromString(gallery.id),
          );
          await _analyticsService.trackAction(
            'favorite_removed',
            parameters: {
              'gallery_id': gallery.id,
              'source': 'random_gallery',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } else {
          await _addToFavoritesUseCase(
            AddToFavoritesParams.create(gallery),
          );
          await _analyticsService.trackAction(
            'favorite_added',
            parameters: {
              'gallery_id': gallery.id,
              'source': 'random_gallery',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }

        if (!isClosed) {
          emit(currentState.copyWith(
            isFavorite: !isFavorite,
            isToggling: false,
          ));
        }
      } catch (e, stackTrace) {
        await _analyticsService.trackError(
          'favorite_toggle_error',
          e.toString(),
          stackTrace: stackTrace,
        );
        if (!isClosed) {
          emit(RandomGalleryError(
            error: e.toString(),
            stackTrace: stackTrace,
            previousState: currentState.copyWith(isToggling: false),
          ));
        }
      }
    }
  }

  /// Load a single random gallery
  Future<void> _loadRandomGallery() async {
    try {
      if (!isClosed) {
        emit(const RandomGalleryLoading());
      }

      final result = await PerformanceMonitor.timeOperation(
        'random_gallery_load',
        () async {
          // Get random gallery (request 1 item and take the first)
          final galleries = await _getRandomContentUseCase(1);

          if (galleries.isEmpty) {
            throw Exception('No random content available');
          }

          final gallery = galleries.first;

          // Check if it's in favorites
          final isFavorite = await _userDataRepository.isFavorite(gallery.id);

          // Check if it has ignored tags
          final hasIgnoredTags = _hasIgnoredTags(gallery);

          return {
            'gallery': gallery,
            'isFavorite': isFavorite,
            'hasIgnoredTags': hasIgnoredTags,
          };
        },
        metadata: {
          'source': 'random_gallery',
        },
      );

      final gallery = result['gallery'] as Content;
      final isFavorite = result['isFavorite'] as bool;
      final hasIgnoredTags = result['hasIgnoredTags'] as bool;

      if (!isClosed) {
        emit(RandomGalleryLoaded(
          currentGallery: gallery,
          isFavorite: isFavorite,
          hasIgnoredTags: hasIgnoredTags,
          isShuffling: false,
          isToggling: false,
          preloadedCount: 1, // Always 1 since we don't preload
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e, stackTrace) {
      if (!isClosed) {
        emit(RandomGalleryError(
          error: e.toString(),
          stackTrace: stackTrace,
        ));
      }
    }
  }

  /// Check if gallery has ignored tags (simplified implementation)
  bool _hasIgnoredTags(Content content) {
    // This is a simplified implementation
    // In a real app, you'd check against user's ignored tags list
    return false;
  }

  /// Retry loading after error
  Future<void> retry() async {
    final currentState = state;
    if (currentState is RandomGalleryError && currentState.canRetry) {
      if (currentState.previousState != null) {
        if (!isClosed) {
          emit(currentState.previousState!);
        }
      } else {
        await _loadRandomGallery();
      }
    }
  }
}
