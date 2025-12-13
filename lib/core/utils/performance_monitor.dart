import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../di/service_locator.dart';
import '../../services/analytics_service.dart';

/// Performance Monitoring Utilities for App Optimization
///
/// Provides easy-to-use wrappers for tracking performance metrics
/// and identifying bottlenecks in the application.
class PerformanceMonitor {
  static final Logger _logger = Logger();
  static AnalyticsService? _analytics;

  /// Initialize performance monitoring (called during app startup)
  static Future<void> initialize() async {
    try {
      _analytics = getIt<AnalyticsService>();
      await _analytics?.initialize();
      _logger.i('Performance monitoring initialized');
    } catch (e) {
      _logger.e('Failed to initialize performance monitoring: $e');
    }
  }

  /// Time an operation and track its performance
  static Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
    bool logResult = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      final duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);

      // Track performance metrics
      await _analytics?.trackPerformance(operationName, duration,
          metadata: metadata);

      if (logResult && kDebugMode) {
        _logger
            .d('⏱️ $operationName completed in ${duration.inMilliseconds}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      final duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);

      // Track failed operations
      await _analytics?.trackPerformance('${operationName}_failed', duration,
          metadata: {...?metadata, 'error': e.toString()});

      if (kDebugMode) {
        _logger.e(
            '❌ $operationName failed after ${duration.inMilliseconds}ms: $e');
      }

      rethrow;
    }
  }

  /// Time a synchronous operation
  static T timeSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
    bool logResult = true,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();

      final duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);

      // Track performance metrics (fire and forget for sync operations)
      _analytics?.trackPerformance(operationName, duration, metadata: metadata);

      if (logResult && kDebugMode) {
        _logger
            .d('⏱️ $operationName completed in ${duration.inMilliseconds}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      final duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);

      // Track failed operations
      _analytics?.trackPerformance('${operationName}_failed', duration,
          metadata: {...?metadata, 'error': e.toString()});

      if (kDebugMode) {
        _logger.e(
            '❌ $operationName failed after ${duration.inMilliseconds}ms: $e');
      }

      rethrow;
    }
  }

  /// Monitor image loading performance
  static Future<void> trackImageLoad(String imageUrl, Duration loadTime,
      {bool success = true}) async {
    await _analytics?.trackPerformance(
      success ? 'image_load_success' : 'image_load_failed',
      loadTime,
      metadata: {
        'image_url_length': imageUrl.length,
        'is_network': imageUrl.startsWith('http'),
        'success': success,
      },
    );
  }

  /// Monitor database operation performance
  static Future<void> trackDatabaseOperation(
      String operation, Duration duration,
      {int? resultCount}) async {
    await _analytics?.trackPerformance(
      'database_$operation',
      duration,
      metadata: {
        'operation': operation,
        'result_count': resultCount,
      },
    );
  }

  /// Monitor network request performance
  static Future<void> trackNetworkRequest(String endpoint, Duration duration,
      {int? statusCode, int? responseSize}) async {
    await _analytics?.trackPerformance(
      'network_request',
      duration,
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'response_size_bytes': responseSize,
        'success': statusCode != null && statusCode >= 200 && statusCode < 300,
      },
    );
  }

  /// Monitor screen rendering performance
  static Future<void> trackScreenRender(
      String screenName, Duration renderTime) async {
    await _analytics?.trackPerformance(
      'screen_render',
      renderTime,
      metadata: {
        'screen_name': screenName,
      },
    );
  }

  /// Monitor memory usage (when available)
  static Future<void> trackMemoryUsage(String context,
      {int? memoryUsageBytes}) async {
    await _analytics?.trackPerformance(
      'memory_usage',
      Duration.zero, // No duration for memory snapshots
      metadata: {
        'context': context,
        'memory_usage_bytes': memoryUsageBytes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Start a performance timer (for manual timing)
  static PerformanceTimer startTimer(String operationName,
      {Map<String, dynamic>? metadata}) {
    return PerformanceTimer._(operationName, metadata);
  }
}

/// Manual performance timer for complex operations
class PerformanceTimer {
  final String operationName;
  final Map<String, dynamic>? metadata;
  final Stopwatch _stopwatch;

  PerformanceTimer._(this.operationName, this.metadata)
      : _stopwatch = Stopwatch()..start();

  /// Stop the timer and record the result
  Future<void> stop({Map<String, dynamic>? additionalMetadata}) async {
    _stopwatch.stop();
    final duration = Duration(milliseconds: _stopwatch.elapsedMilliseconds);

    final combinedMetadata = {
      ...?metadata,
      ...?additionalMetadata,
    };

    await PerformanceMonitor._analytics?.trackPerformance(
      operationName,
      duration,
      metadata: combinedMetadata.isNotEmpty ? combinedMetadata : null,
    );

    if (kDebugMode) {
      PerformanceMonitor._logger
          .d('⏱️ $operationName completed in ${duration.inMilliseconds}ms');
    }
  }

  /// Get elapsed time without stopping
  Duration get elapsed =>
      Duration(milliseconds: _stopwatch.elapsedMilliseconds);

  /// Stop timer and mark as failed
  Future<void> stopWithError(dynamic error) async {
    _stopwatch.stop();
    final duration = Duration(milliseconds: _stopwatch.elapsedMilliseconds);

    await PerformanceMonitor._analytics?.trackPerformance(
      '${operationName}_failed',
      duration,
      metadata: {
        ...?metadata,
        'error': error.toString(),
      },
    );

    if (kDebugMode) {
      PerformanceMonitor._logger.e(
          '❌ $operationName failed after ${duration.inMilliseconds}ms: $error');
    }
  }
}

/// Extension methods for easy performance monitoring
extension PerformanceExtensions on Future {
  /// Monitor this future's performance
  Future<T> withPerformanceTracking<T>(
    String operationName, {
    Map<String, dynamic>? metadata,
    bool logResult = true,
  }) async {
    return PerformanceMonitor.timeOperation<T>(
      operationName,
      () async => await this as T,
      metadata: metadata,
      logResult: logResult,
    );
  }
}

/// Widget performance monitoring mixin
mixin PerformanceMonitoringMixin {
  PerformanceTimer? _buildTimer;

  /// Start monitoring widget build performance
  void startBuildTimer(String widgetName) {
    _buildTimer = PerformanceMonitor.startTimer('widget_build',
        metadata: {'widget_name': widgetName});
  }

  /// Stop monitoring widget build performance
  Future<void> stopBuildTimer() async {
    await _buildTimer?.stop();
    _buildTimer = null;
  }

  /// Monitor a widget operation
  Future<T> monitorWidgetOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    return PerformanceMonitor.timeOperation(
      operationName,
      operation,
      metadata: metadata,
    );
  }
}
