import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'pdf_conversion_service.dart';
import 'notification_service.dart';

/// Manages a queue of PDF conversion tasks to prevent resource contention
/// and provide better user experience with clear progress tracking.
///
/// This manager processes PDF conversions sequentially (one at a time) to:
/// - Avoid overwhelming the native PDF generator
/// - Provide clear progress notifications
/// - Show queue status to users
/// - Handle cancellation gracefully
class PdfConversionQueueManager {
  // Singleton pattern
  static final PdfConversionQueueManager _instance =
      PdfConversionQueueManager._internal();
  factory PdfConversionQueueManager() => _instance;
  PdfConversionQueueManager._internal();

  final Queue<PdfConversionTask> _queue = Queue();
  PdfConversionTask? _currentTask;
  bool _isProcessing = false;
  int _totalProcessed = 0;

  // Dependencies - will be injected via initialize()
  PdfConversionService? _conversionService;
  NotificationService? _notificationService;
  Logger? _logger;

  // Progress tracking
  final StreamController<QueueStatus> _statusController =
      StreamController<QueueStatus>.broadcast();
  Stream<QueueStatus> get statusStream => _statusController.stream;

  /// Initialize the queue manager with required dependencies
  void initialize({
    required PdfConversionService conversionService,
    required NotificationService notificationService,
    required Logger logger,
  }) {
    _conversionService = conversionService;
    _notificationService = notificationService;
    _logger = logger;
    _logger?.i('PdfConversionQueueManager: Initialized');
  }

  /// Add a PDF conversion task to the queue
  Future<void> queueConversion({
    required String contentId,
    required String title,
    required List<String> imagePaths,
    String? sourceId,
  }) async {
    if (_conversionService == null || _notificationService == null) {
      _logger?.e(
          'PdfConversionQueueManager: Not initialized! Call initialize() first.');
      throw StateError('PdfConversionQueueManager not initialized');
    }

    final task = PdfConversionTask(
      contentId: contentId,
      title: title,
      imagePaths: imagePaths,
      sourceId: sourceId,
      queuedAt: DateTime.now(),
    );

    _queue.add(task);
    _logger?.i(
        '📥 Queued PDF conversion: $contentId (Queue size: ${_queue.length})');

    // Broadcast status update
    _broadcastStatus();

    // Update notification for queued items
    await _updateQueueNotification();

    // Start processing if not already running
    if (!_isProcessing) {
      await _processQueue();
    }
  }

  /// Process the queue sequentially
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    _logger?.i('🚀 Starting PDF conversion queue processor');

    while (_queue.isNotEmpty) {
      _currentTask = _queue.removeFirst();
      final position = _totalProcessed + 1;
      final totalItems = position + _queue.length;

      _logger?.i(
          '📄 Processing PDF $position of $totalItems: ${_currentTask!.title}');

      // Broadcast status
      _broadcastStatus();

      try {
        // Show progress notification with queue position
        await _notificationService!.showPdfConversionQueued(
          contentId: _currentTask!.contentId,
          title: _currentTask!.title,
          currentIndex: position,
          totalCount: totalItems,
        );

        // Perform actual conversion with progress tracking
        await _conversionService!.convertToPdfInBackground(
          contentId: _currentTask!.contentId,
          title: _currentTask!.title,
          imagePaths: _currentTask!.imagePaths,
          sourceId: _currentTask!.sourceId,
        );

        _logger?.i('✅ PDF conversion completed: ${_currentTask!.contentId}');
        _totalProcessed++;
      } catch (e, stackTrace) {
        _logger?.e('❌ PDF conversion failed for ${_currentTask!.contentId}',
            error: e, stackTrace: stackTrace);
        // Error notification already handled by PdfConversionService
        // Continue processing queue despite error
      }

      _currentTask = null;
      _broadcastStatus();
      await _updateQueueNotification();
    }

    _isProcessing = false;
    _logger?.i(
        '🏁 PDF conversion queue completed. Total processed: $_totalProcessed');

    // Show summary notification if multiple items were processed
    if (_totalProcessed > 1) {
      await _notificationService!.showPdfBatchCompleted(
        count: _totalProcessed,
      );
      // Reset counter for next batch
      _totalProcessed = 0;
    }

    _broadcastStatus();
  }

  /// Update notification for queued items
  Future<void> _updateQueueNotification() async {
    if (_queue.isEmpty) {
      // Clear queue notification if any
      await _notificationService?.clearPdfQueueNotification();
      return;
    }

    final queuedCount = _queue.length;
    final queuedTitles = _queue.take(3).map((t) => t.title).join(', ');

    await _notificationService?.showPdfQueueStatus(
      queuedCount: queuedCount,
      queuedTitles: queuedTitles,
    );
  }

  /// Broadcast current queue status to listeners
  void _broadcastStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(getStatus());
    }
  }

  /// Cancel all queued conversions (does not cancel current processing)
  Future<void> cancelAll() async {
    _logger?.w('🚫 Cancelling all queued PDF conversions');
    _queue.clear();
    await _notificationService?.clearPdfQueueNotification();
    _broadcastStatus();
  }

  /// Get current queue status
  QueueStatus getStatus() {
    return QueueStatus(
      queuedCount: _queue.length,
      currentTask: _currentTask,
      isProcessing: _isProcessing,
      totalProcessed: _totalProcessed,
    );
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}

/// Represents a single PDF conversion task in the queue
class PdfConversionTask {
  final String contentId;
  final String title;
  final List<String> imagePaths;
  final String? sourceId;
  final DateTime queuedAt;

  PdfConversionTask({
    required this.contentId,
    required this.title,
    required this.imagePaths,
    required this.sourceId,
    required this.queuedAt,
  });

  @override
  String toString() =>
      'PdfConversionTask(contentId: $contentId, title: $title, images: ${imagePaths.length})';
}

/// Represents the current status of the PDF conversion queue
class QueueStatus {
  final int queuedCount;
  final PdfConversionTask? currentTask;
  final bool isProcessing;
  final int totalProcessed;

  QueueStatus({
    required this.queuedCount,
    required this.currentTask,
    required this.isProcessing,
    required this.totalProcessed,
  });

  @override
  String toString() =>
      'QueueStatus(queued: $queuedCount, processing: $isProcessing, current: ${currentTask?.title})';
}
