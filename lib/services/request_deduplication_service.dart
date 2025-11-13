import 'dart:async';
import 'package:logger/logger.dart';

/// Service for deduplicating concurrent API requests
/// Prevents multiple simultaneous requests for the same resource
class RequestDeduplicationService {
  static const Duration _defaultTimeout = Duration(seconds: 30);

  final Logger _logger = Logger();
  final Map<String, _PendingRequest> _pendingRequests = {};

  /// Execute a request with deduplication
  /// If a request for the same key is already in progress, returns the existing future
  Future<T> deduplicate<T>(
    String requestKey,
    Future<T> Function() requestFunction, {
    Duration? timeout,
  }) async {
    final timeoutDuration = timeout ?? _defaultTimeout;

    // Check if request is already in progress
    if (_pendingRequests.containsKey(requestKey)) {
      final pendingRequest =
          _pendingRequests[requestKey]! as _PendingRequest<T>;

      // Check if the request has timed out
      if (DateTime.now().difference(pendingRequest.startTime) >
          timeoutDuration) {
        _logger
            .w('Request $requestKey timed out, removing from pending requests');
        _pendingRequests.remove(requestKey);
      } else {
        _logger.d(
            'Request $requestKey already in progress, reusing existing future');
        return pendingRequest.completer.future;
      }
    }

    // Create new request
    final completer = Completer<T>();
    final startTime = DateTime.now();

    _pendingRequests[requestKey] = _PendingRequest<T>(
      completer: completer,
      startTime: startTime,
    );

    try {
      _logger.d('Starting new request: $requestKey');
      final result = await requestFunction().timeout(timeoutDuration);

      completer.complete(result);
      _logger.d('Request $requestKey completed successfully');
    } catch (error, stackTrace) {
      _logger.w('Request $requestKey failed: $error');
      completer.completeError(error, stackTrace);
    } finally {
      // Clean up the pending request
      _pendingRequests.remove(requestKey);
    }

    return completer.future;
  }

  /// Check if a request is currently in progress
  bool isRequestInProgress(String requestKey) {
    return _pendingRequests.containsKey(requestKey);
  }

  /// Get the number of currently pending requests
  int get pendingRequestsCount => _pendingRequests.length;

  /// Get statistics about pending requests
  Map<String, dynamic> getPendingRequestsStats() {
    final now = DateTime.now();
    final stats = <String, dynamic>{};

    for (final entry in _pendingRequests.entries) {
      final duration = now.difference(entry.value.startTime);
      stats[entry.key] = {
        'durationMs': duration.inMilliseconds,
        'isCompleted': entry.value.completer.isCompleted,
      };
    }

    return {
      'totalPending': _pendingRequests.length,
      'requests': stats,
    };
  }

  /// Cancel all pending requests
  void cancelAllPendingRequests() {
    for (final entry in _pendingRequests.entries) {
      if (!entry.value.completer.isCompleted) {
        entry.value.completer.completeError(
          Exception('Request cancelled: ${entry.key}'),
        );
      }
    }
    _pendingRequests.clear();
    _logger.i('Cancelled all pending requests');
  }

  /// Clean up timed out requests
  void cleanupTimedOutRequests({Duration? customTimeout}) {
    final timeout = customTimeout ?? _defaultTimeout;
    final now = DateTime.now();
    final timedOutKeys = <String>[];

    for (final entry in _pendingRequests.entries) {
      if (now.difference(entry.value.startTime) > timeout) {
        if (!entry.value.completer.isCompleted) {
          entry.value.completer.completeError(
            TimeoutException('Request timed out: ${entry.key}'),
          );
        }
        timedOutKeys.add(entry.key);
      }
    }

    for (final key in timedOutKeys) {
      _pendingRequests.remove(key);
    }

    if (timedOutKeys.isNotEmpty) {
      _logger.i('Cleaned up ${timedOutKeys.length} timed out requests');
    }
  }
}

/// Internal class to track pending requests
class _PendingRequest<T> {
  _PendingRequest({
    required this.completer,
    required this.startTime,
  });

  final Completer<T> completer;
  final DateTime startTime;
}
