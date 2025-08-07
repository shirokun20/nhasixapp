import 'package:logger/logger.dart';
import '../../domain/entities/content.dart';
import 'image_preloader.dart';
import 'image_cache_manager.dart';

/// Content-specific image preloader
///
/// Features:
/// - Preload content images based on user behavior
/// - Smart preloading for next/previous content
/// - Reader mode preloading
/// - Memory-aware preloading
class ContentImagePreloader {
  static ContentImagePreloader? _instance;
  static ContentImagePreloader get instance =>
      _instance ??= ContentImagePreloader._();

  ContentImagePreloader._();

  final Logger _logger = Logger();
  final ImagePreloader _imagePreloader = ImagePreloader.instance;
  final ImageCacheManager _cacheManager = ImageCacheManager.instance;

  // Preloading configuration
  static const int _maxPreloadDistance =
      5; // How many items ahead/behind to preload
  static const int _readerPreloadRange =
      3; // How many pages ahead/behind in reader
  static const Duration _preloadDelay = Duration(milliseconds: 500);

  /// Preload images for content list
  Future<void> preloadContentList(
    List<Content> contents, {
    int currentIndex = 0,
    bool preloadThumbnails = true,
    bool preloadCompressed = false,
  }) async {
    try {
      // Calculate preload range
      final startIndex =
          (currentIndex - _maxPreloadDistance).clamp(0, contents.length - 1);
      final endIndex =
          (currentIndex + _maxPreloadDistance).clamp(0, contents.length - 1);

      final contentsToPreload = contents.sublist(startIndex, endIndex + 1);

      await _imagePreloader.preloadContentImages(
        contentsToPreload,
        priority: _getPreloadPriority(currentIndex, startIndex, endIndex),
        includeThumbnails: preloadThumbnails,
        includeCompressed: preloadCompressed,
        includeFullImages: false, // Don't preload full images for list view
      );

      _logger.d('Preloaded images for ${contentsToPreload.length} contents');
    } catch (e) {
      _logger.w('Failed to preload content list images', error: e);
    }
  }

  /// Preload images for content detail view
  Future<void> preloadContentDetail(
    Content content, {
    List<Content>? relatedContents,
  }) async {
    try {
      // Preload main content images
      await _imagePreloader.preloadContentImages(
        [content],
        priority: PreloadPriority.high,
        includeThumbnails: true,
        includeCompressed: true,
        includeFullImages: true,
      );

      // Preload related content thumbnails
      if (relatedContents != null && relatedContents.isNotEmpty) {
        await _imagePreloader.preloadContentImages(
          relatedContents.take(10).toList(), // Limit to first 10 related items
          priority: PreloadPriority.low,
          includeThumbnails: true,
          includeCompressed: false,
          includeFullImages: false,
        );
      }

      _logger.d('Preloaded detail images for content ${content.id}');
    } catch (e) {
      _logger.w('Failed to preload content detail images', error: e);
    }
  }

  /// Preload images for reader mode
  Future<void> preloadReaderImages(
    List<String> imageUrls, {
    int currentPage = 0,
  }) async {
    try {
      await _imagePreloader.preloadReaderImages(
        imageUrls,
        currentPage: currentPage,
        preloadRange: _readerPreloadRange,
      );

      _logger.d('Preloaded reader images around page $currentPage');
    } catch (e) {
      _logger.w('Failed to preload reader images', error: e);
    }
  }

  /// Preload images when user scrolls
  Future<void> onContentListScroll(
    List<Content> contents,
    int visibleStartIndex,
    int visibleEndIndex,
  ) async {
    // Add delay to avoid excessive preloading during fast scrolling
    await Future.delayed(_preloadDelay);

    try {
      // Calculate extended preload range
      final preloadStart = (visibleStartIndex - _maxPreloadDistance)
          .clamp(0, contents.length - 1);
      final preloadEnd =
          (visibleEndIndex + _maxPreloadDistance).clamp(0, contents.length - 1);

      final contentsToPreload = contents.sublist(preloadStart, preloadEnd + 1);

      await _imagePreloader.preloadContentImages(
        contentsToPreload,
        priority: PreloadPriority.normal,
        includeThumbnails: true,
        includeCompressed: true,
        includeFullImages: false,
      );

      _logger.d('Preloaded images for scroll range $preloadStart-$preloadEnd');
    } catch (e) {
      _logger.w('Failed to preload images on scroll', error: e);
    }
  }

  /// Preload images when user navigates to next/previous content
  Future<void> onContentNavigation(
    List<Content> contents,
    int currentIndex,
    NavigationDirection direction,
  ) async {
    try {
      List<Content> contentsToPreload = [];

      switch (direction) {
        case NavigationDirection.next:
          // Preload next few contents
          final endIndex = (currentIndex + _maxPreloadDistance)
              .clamp(0, contents.length - 1);
          contentsToPreload = contents.sublist(currentIndex, endIndex + 1);
          break;

        case NavigationDirection.previous:
          // Preload previous few contents
          final startIndex = (currentIndex - _maxPreloadDistance)
              .clamp(0, contents.length - 1);
          contentsToPreload = contents.sublist(startIndex, currentIndex + 1);
          break;

        case NavigationDirection.random:
          // For random navigation, preload current content with high priority
          contentsToPreload = [contents[currentIndex]];
          break;
      }

      await _imagePreloader.preloadContentImages(
        contentsToPreload,
        priority: PreloadPriority.high,
        includeThumbnails: true,
        includeCompressed: true,
        includeFullImages: false,
      );

      _logger.d('Preloaded images for ${direction.name} navigation');
    } catch (e) {
      _logger.w('Failed to preload images for navigation', error: e);
    }
  }

  /// Preload images when reader page changes
  Future<void> onReaderPageChange(
    List<String> imageUrls,
    int newPage,
    int previousPage,
  ) async {
    try {
      // Determine preload direction based on page change
      final isForward = newPage > previousPage;

      if (isForward) {
        // Preload pages ahead
        final endPage =
            (newPage + _readerPreloadRange).clamp(0, imageUrls.length - 1);
        for (int i = newPage; i <= endPage; i++) {
          await _cacheManager.getFullImage(imageUrls[i]);
        }
      } else {
        // Preload pages behind
        final startPage =
            (newPage - _readerPreloadRange).clamp(0, imageUrls.length - 1);
        for (int i = startPage; i <= newPage; i++) {
          await _cacheManager.getFullImage(imageUrls[i]);
        }
      }

      _logger.d('Preloaded reader images around page $newPage');
    } catch (e) {
      _logger.w('Failed to preload reader images on page change', error: e);
    }
  }

  /// Smart preloading based on user behavior
  Future<void> smartPreload(
    List<Content> contents,
    UserBehavior behavior,
  ) async {
    try {
      switch (behavior.type) {
        case BehaviorType.browsing:
          await preloadContentList(
            contents,
            currentIndex: behavior.currentIndex,
            preloadThumbnails: true,
            preloadCompressed: behavior.isSlowScrolling,
          );
          break;

        case BehaviorType.searching:
          // Preload only thumbnails for search results
          await _imagePreloader.preloadContentImages(
            contents.take(20).toList(), // Limit search preloading
            priority: PreloadPriority.normal,
            includeThumbnails: true,
            includeCompressed: false,
            includeFullImages: false,
          );
          break;

        case BehaviorType.reading:
          if (behavior.imageUrls != null) {
            await preloadReaderImages(
              behavior.imageUrls!,
              currentPage: behavior.currentIndex,
            );
          }
          break;

        case BehaviorType.favoriting:
          // Preload high-quality images for favorited content
          await _imagePreloader.preloadContentImages(
            contents,
            priority: PreloadPriority.high,
            includeThumbnails: true,
            includeCompressed: true,
            includeFullImages: true,
          );
          break;
      }

      _logger.d('Smart preload completed for ${behavior.type.name}');
    } catch (e) {
      _logger.w('Failed to perform smart preload', error: e);
    }
  }

  /// Get preload priority based on distance from current item
  PreloadPriority _getPreloadPriority(
      int currentIndex, int startIndex, int endIndex) {
    final totalRange = endIndex - startIndex + 1;
    final midPoint = startIndex + (totalRange ~/ 2);

    if (currentIndex == midPoint) {
      return PreloadPriority.high;
    } else if ((currentIndex - midPoint).abs() <= 2) {
      return PreloadPriority.normal;
    } else {
      return PreloadPriority.low;
    }
  }

  /// Clear preload queues
  void clearPreloadQueues() {
    _imagePreloader.clearPreloadQueues();
  }

  /// Stop all preloading
  void stopPreloading() {
    _imagePreloader.stopPreloading();
  }

  /// Get preloading progress
  PreloadProgress getPreloadProgress() {
    return _imagePreloader.getProgress();
  }
}

/// Navigation direction enumeration
enum NavigationDirection {
  next,
  previous,
  random,
}

/// User behavior data class
class UserBehavior {
  final BehaviorType type;
  final int currentIndex;
  final bool isSlowScrolling;
  final List<String>? imageUrls;
  final Duration sessionDuration;

  UserBehavior({
    required this.type,
    required this.currentIndex,
    this.isSlowScrolling = false,
    this.imageUrls,
    this.sessionDuration = Duration.zero,
  });
}

/// Behavior type enumeration
enum BehaviorType {
  browsing,
  searching,
  reading,
  favoriting,
}
