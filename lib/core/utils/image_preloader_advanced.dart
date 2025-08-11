import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Advanced image preloader for smooth reading experience
class AdvancedImagePreloader {
  static final Map<String, Completer<void>> _preloadingImages = {};
  static final Set<String> _preloadedImages = {};
  static final Map<String, DateTime> _preloadTimestamps = {};

  // Memory management settings
  static const int _maxPreloadedImages = 20;
  static const Duration _preloadExpiry = Duration(minutes: 10);

  /// Preload a single image with enhanced error handling
  static Future<void> preloadImage(String imageUrl) async {
    if (_preloadedImages.contains(imageUrl)) {
      // Update timestamp for recently accessed image
      _preloadTimestamps[imageUrl] = DateTime.now();
      return; // Already preloaded
    }

    if (_preloadingImages.containsKey(imageUrl)) {
      return _preloadingImages[imageUrl]!.future; // Already preloading
    }

    final completer = Completer<void>();
    _preloadingImages[imageUrl] = completer;

    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final completerLocal = Completer<void>();

      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          _preloadedImages.add(imageUrl);
          _preloadTimestamps[imageUrl] = DateTime.now();
          completerLocal.complete();
        },
        onError: (exception, stackTrace) {
          completerLocal.completeError(exception);
        },
      );

      imageStream.addListener(listener);

      // Add timeout to prevent hanging
      await completerLocal.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          imageStream.removeListener(listener);
          throw TimeoutException(
              'Image preload timeout', const Duration(seconds: 30));
        },
      );

      completer.complete();

      // Clean up old preloaded images if we have too many
      _cleanupOldImages();
    } catch (e) {
      completer.completeError(e);
    } finally {
      _preloadingImages.remove(imageUrl);
    }
  }

  /// Preload multiple images concurrently with priority
  static Future<void> preloadImages(List<String> imageUrls,
      {int maxConcurrent = 3, bool highPriority = false}) async {
    if (imageUrls.isEmpty) return;

    // Sort URLs by priority (already preloaded images first to update timestamps)
    final sortedUrls = List<String>.from(imageUrls);
    if (highPriority) {
      sortedUrls.sort((a, b) {
        final aPreloaded = _preloadedImages.contains(a);
        final bPreloaded = _preloadedImages.contains(b);
        if (aPreloaded && !bPreloaded) return -1;
        if (!aPreloaded && bPreloaded) return 1;
        return 0;
      });
    }

    // Process in batches to avoid overwhelming the system
    for (int i = 0; i < sortedUrls.length; i += maxConcurrent) {
      final batch = sortedUrls.skip(i).take(maxConcurrent);
      final batchFutures = batch.map((url) => preloadImage(url).catchError((e) {
            // Log error but don't fail the entire batch
            // TODO: Use proper logging
            return null;
          }));

      // Wait for current batch before starting next
      await Future.wait(batchFutures, eagerError: false);
    }
  }

  /// Check if image is preloaded and still valid
  static bool isImagePreloaded(String imageUrl) {
    if (!_preloadedImages.contains(imageUrl)) return false;

    // Check if image is still valid (not expired)
    final timestamp = _preloadTimestamps[imageUrl];
    if (timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age > _preloadExpiry) {
        // Remove expired image
        _preloadedImages.remove(imageUrl);
        _preloadTimestamps.remove(imageUrl);
        return false;
      }
    }

    return true;
  }

  /// Clear specific image from cache
  static void clearSpecificImage(String imageUrl) {
    _preloadedImages.remove(imageUrl);
    _preloadTimestamps.remove(imageUrl);
  }

  /// Clear preloaded images cache
  static void clearCache() {
    _preloadedImages.clear();
    _preloadingImages.clear();
    _preloadTimestamps.clear();
  }

  /// Clean up old preloaded images to manage memory
  static void _cleanupOldImages() {
    if (_preloadedImages.length <= _maxPreloadedImages) return;

    // Sort by timestamp (oldest first)
    final sortedEntries = _preloadTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest images until we're under the limit
    final toRemove = _preloadedImages.length - _maxPreloadedImages;
    for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
      final imageUrl = sortedEntries[i].key;
      _preloadedImages.remove(imageUrl);
      _preloadTimestamps.remove(imageUrl);
    }
  }

  /// Get preloaded images count
  static int get preloadedCount => _preloadedImages.length;

  /// Get currently preloading images count
  static int get preloadingCount => _preloadingImages.length;

  /// Get memory usage statistics
  static Map<String, dynamic> getStats() {
    return {
      'preloadedCount': preloadedCount,
      'preloadingCount': preloadingCount,
      'oldestPreload': _preloadTimestamps.values.isEmpty
          ? null
          : _preloadTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b),
      'newestPreload': _preloadTimestamps.values.isEmpty
          ? null
          : _preloadTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }
}

/// Preloader widget for displaying preload status
class PreloadIndicator extends StatelessWidget {
  const PreloadIndicator({
    super.key,
    required this.imageUrl,
    this.size = 16,
    this.color,
  });

  final String imageUrl;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isPreloaded = AdvancedImagePreloader.isImagePreloaded(imageUrl);

    if (!isPreloaded) {
      return SizedBox(width: size, height: size);
    }

    return Icon(
      Icons.cached,
      size: size,
      color: color ?? Theme.of(context).primaryColor,
    );
  }
}
