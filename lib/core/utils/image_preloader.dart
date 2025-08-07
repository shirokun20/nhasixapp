import 'dart:async';
import 'package:logger/logger.dart';
import '../../domain/entities/content.dart';
import 'image_cache_manager.dart';

/// Image preloader for better user experience
///
/// Features:
/// - Preload images in background
/// - Priority-based loading
/// - Batch processing
/// - Memory management
/// - Progress tracking
class ImagePreloader {
  static ImagePreloader? _instance;
  static ImagePreloader get instance => _instance ??= ImagePreloader._();

  ImagePreloader._();

  final Logger _logger = Logger();
  final ImageCacheManager _cacheManager = ImageCacheManager.instance;

  // Preloading queues
  final List<PreloadTask> _highPriorityQueue = [];
  final List<PreloadTask> _normalPriorityQueue = [];
  final List<PreloadTask> _lowPriorityQueue = [];

  // Active preloading tasks
  final Set<String> _activePreloads = {};
  final Map<String, Completer<void>> _preloadCompleters = {};

  // Configuration
  static const int _maxConcurrentPreloads = 3;
  static const int _maxPreloadQueueSize = 50;
  static const Duration _preloadTimeout = Duration(seconds: 30);

  bool _isPreloading = false;
  int _completedPreloads = 0;
  int _totalPreloads = 0;

  /// Preload content images with priority
  Future<void> preloadContentImages(
    List<Content> contents, {
    PreloadPriority priority = PreloadPriority.normal,
    bool includeThumbnails = true,
    bool includeCompressed = true,
    bool includeFullImages = false,
  }) async {
    final tasks = <PreloadTask>[];

    for (final content in contents) {
      if (content.coverUrl.isNotEmpty) {
        if (includeThumbnails) {
          tasks.add(PreloadTask(
            url: content.coverUrl,
            type: PreloadType.thumbnail,
            priority: priority,
            contentId: content.id,
          ));
        }

        if (includeCompressed) {
          tasks.add(PreloadTask(
            url: content.coverUrl,
            type: PreloadType.compressed,
            priority: priority,
            contentId: content.id,
          ));
        }

        if (includeFullImages) {
          tasks.add(PreloadTask(
            url: content.coverUrl,
            type: PreloadType.fullImage,
            priority: priority,
            contentId: content.id,
          ));
        }
      }

      // Preload page images if available
      if (includeFullImages && content.imageUrls.isNotEmpty) {
        // Only preload first few pages to avoid excessive memory usage
        final pagesToPreload = content.imageUrls.take(5);
        for (final imageUrl in pagesToPreload) {
          tasks.add(PreloadTask(
            url: imageUrl,
            type: PreloadType.fullImage,
            priority: PreloadPriority.low, // Lower priority for page images
            contentId: content.id,
          ));
        }
      }
    }

    await addPreloadTasks(tasks);
  }

  /// Add preload tasks to queue
  Future<void> addPreloadTasks(List<PreloadTask> tasks) async {
    for (final task in tasks) {
      // Skip if already preloading or preloaded
      if (_activePreloads.contains(task.cacheKey)) {
        continue;
      }

      // Add to appropriate queue based on priority
      switch (task.priority) {
        case PreloadPriority.high:
          if (_highPriorityQueue.length < _maxPreloadQueueSize) {
            _highPriorityQueue.add(task);
          }
          break;
        case PreloadPriority.normal:
          if (_normalPriorityQueue.length < _maxPreloadQueueSize) {
            _normalPriorityQueue.add(task);
          }
          break;
        case PreloadPriority.low:
          if (_lowPriorityQueue.length < _maxPreloadQueueSize) {
            _lowPriorityQueue.add(task);
          }
          break;
      }
    }

    _totalPreloads = _highPriorityQueue.length +
        _normalPriorityQueue.length +
        _lowPriorityQueue.length;

    // Start preloading if not already running
    if (!_isPreloading) {
      _startPreloading();
    }
  }

  /// Start preloading process
  void _startPreloading() {
    if (_isPreloading) return;

    _isPreloading = true;
    _completedPreloads = 0;

    // Start concurrent preload workers
    for (int i = 0; i < _maxConcurrentPreloads; i++) {
      _preloadWorker();
    }
  }

  /// Preload worker that processes tasks from queues
  Future<void> _preloadWorker() async {
    while (_isPreloading && _hasTasksInQueue()) {
      final task = _getNextTask();
      if (task == null) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      await _processPreloadTask(task);
    }

    // Check if all workers are done
    if (!_hasTasksInQueue() && _activePreloads.isEmpty) {
      _isPreloading = false;
      _logger.i('Image preloading completed. Total: $_completedPreloads');
    }
  }

  /// Get next task from priority queues
  PreloadTask? _getNextTask() {
    // High priority first
    if (_highPriorityQueue.isNotEmpty) {
      return _highPriorityQueue.removeAt(0);
    }

    // Normal priority second
    if (_normalPriorityQueue.isNotEmpty) {
      return _normalPriorityQueue.removeAt(0);
    }

    // Low priority last
    if (_lowPriorityQueue.isNotEmpty) {
      return _lowPriorityQueue.removeAt(0);
    }

    return null;
  }

  /// Check if there are tasks in any queue
  bool _hasTasksInQueue() {
    return _highPriorityQueue.isNotEmpty ||
        _normalPriorityQueue.isNotEmpty ||
        _lowPriorityQueue.isNotEmpty;
  }

  /// Process individual preload task
  Future<void> _processPreloadTask(PreloadTask task) async {
    final cacheKey = task.cacheKey;

    // Skip if already being processed
    if (_activePreloads.contains(cacheKey)) {
      return;
    }

    _activePreloads.add(cacheKey);
    final completer = Completer<void>();
    _preloadCompleters[cacheKey] = completer;

    try {
      // Check if already cached
      final isCached = await _cacheManager.isImageCached(
        task.url,
        type: _getCacheType(task.type),
      );

      if (!isCached) {
        // Preload with timeout
        await Future.any([
          _preloadImage(task),
          Future.delayed(_preloadTimeout),
        ]);
      }

      _completedPreloads++;
      completer.complete();
    } catch (e) {
      _logger.w('Failed to preload image: ${task.url}', error: e);
      completer.completeError(e);
    } finally {
      _activePreloads.remove(cacheKey);
      _preloadCompleters.remove(cacheKey);
    }
  }

  /// Preload image based on type
  Future<void> _preloadImage(PreloadTask task) async {
    switch (task.type) {
      case PreloadType.thumbnail:
        await _cacheManager.getThumbnail(task.url);
        break;
      case PreloadType.compressed:
        await _cacheManager.getCompressedImage(task.url);
        break;
      case PreloadType.fullImage:
        await _cacheManager.getFullImage(task.url);
        break;
    }
  }

  /// Convert preload type to cache type
  CacheType _getCacheType(PreloadType type) {
    switch (type) {
      case PreloadType.thumbnail:
        return CacheType.thumbnail;
      case PreloadType.compressed:
        return CacheType.compressed;
      case PreloadType.fullImage:
        return CacheType.fullImage;
    }
  }

  /// Preload images for current screen
  Future<void> preloadForCurrentScreen(List<String> imageUrls) async {
    final tasks = imageUrls
        .map((url) => PreloadTask(
              url: url,
              type: PreloadType.thumbnail,
              priority: PreloadPriority.high,
            ))
        .toList();

    await addPreloadTasks(tasks);
  }

  /// Preload images for next screen (lower priority)
  Future<void> preloadForNextScreen(List<String> imageUrls) async {
    final tasks = imageUrls
        .map((url) => PreloadTask(
              url: url,
              type: PreloadType.compressed,
              priority: PreloadPriority.normal,
            ))
        .toList();

    await addPreloadTasks(tasks);
  }

  /// Wait for specific image to be preloaded
  Future<void> waitForPreload(String url, PreloadType type) async {
    final cacheKey = '${url}_${type.name}';
    final completer = _preloadCompleters[cacheKey];

    if (completer != null) {
      await completer.future;
    }
  }

  /// Clear all preload queues
  void clearPreloadQueues() {
    _highPriorityQueue.clear();
    _normalPriorityQueue.clear();
    _lowPriorityQueue.clear();
    _totalPreloads = 0;
    _completedPreloads = 0;
  }

  /// Stop all preloading
  void stopPreloading() {
    _isPreloading = false;
    clearPreloadQueues();
    _activePreloads.clear();

    // Complete all pending completers with error
    for (final completer in _preloadCompleters.values) {
      if (!completer.isCompleted) {
        completer.completeError('Preloading stopped');
      }
    }
    _preloadCompleters.clear();
  }

  /// Get preloading progress
  PreloadProgress getProgress() {
    return PreloadProgress(
      completed: _completedPreloads,
      total: _totalPreloads,
      isActive: _isPreloading,
      queueSizes: QueueSizes(
        high: _highPriorityQueue.length,
        normal: _normalPriorityQueue.length,
        low: _lowPriorityQueue.length,
      ),
    );
  }

  /// Preload images for reader mode
  Future<void> preloadReaderImages(
    List<String> imageUrls, {
    int currentPage = 0,
    int preloadRange = 3,
  }) async {
    final tasks = <PreloadTask>[];

    // Calculate preload range
    final startIndex =
        (currentPage - preloadRange).clamp(0, imageUrls.length - 1);
    final endIndex =
        (currentPage + preloadRange).clamp(0, imageUrls.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      final priority = i == currentPage
          ? PreloadPriority.high
          : (i - currentPage).abs() <= 1
              ? PreloadPriority.normal
              : PreloadPriority.low;

      tasks.add(PreloadTask(
        url: imageUrls[i],
        type: PreloadType.fullImage,
        priority: priority,
      ));
    }

    await addPreloadTasks(tasks);
  }
}

/// Preload task data class
class PreloadTask {
  final String url;
  final PreloadType type;
  final PreloadPriority priority;
  final String? contentId;

  PreloadTask({
    required this.url,
    required this.type,
    required this.priority,
    this.contentId,
  });

  String get cacheKey => '${url}_${type.name}';
}

/// Preload type enumeration
enum PreloadType {
  thumbnail,
  compressed,
  fullImage,
}

/// Preload priority enumeration
enum PreloadPriority {
  high,
  normal,
  low,
}

/// Preload progress data class
class PreloadProgress {
  final int completed;
  final int total;
  final bool isActive;
  final QueueSizes queueSizes;

  PreloadProgress({
    required this.completed,
    required this.total,
    required this.isActive,
    required this.queueSizes,
  });

  double get percentage => total > 0 ? completed / total : 0.0;
}

/// Queue sizes data class
class QueueSizes {
  final int high;
  final int normal;
  final int low;

  QueueSizes({
    required this.high,
    required this.normal,
    required this.low,
  });

  int get total => high + normal + low;
}
