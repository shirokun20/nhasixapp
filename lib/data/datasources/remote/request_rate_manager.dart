import 'dart:math';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';

/// Advanced request rate manager for intelligent rate limiting
class RequestRateManager {
  RequestRateManager({
    required this.remoteConfigService,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final RemoteConfigService remoteConfigService;
  final Logger _logger;
  final List<DateTime> _requestHistory = [];
  static const Duration _defaultTimeWindow = Duration(minutes: 1);

  // Dynamic getters from config with fallbacks
  int get _maxRequestsPerWindow =>
      remoteConfigService.getRateLimitConfig('nhentai').requestsPerMinute;
  Duration get _baseDelay => Duration(
      milliseconds:
          remoteConfigService.getRateLimitConfig('nhentai').minDelayMs);

  bool _isInCooldown = false;
  DateTime? _cooldownEndTime;

  /// Check if a request can be made now
  bool canMakeRequest() {
    _cleanupOldRequests();

    // Check if we're in cooldown period
    if (_isInCooldown && _cooldownEndTime != null) {
      if (DateTime.now().isBefore(_cooldownEndTime!)) {
        return false;
      } else {
        _isInCooldown = false;
        _cooldownEndTime = null;
        _logger.i('Cooldown period ended, resuming requests');
      }
    }

    return _requestHistory.length < _maxRequestsPerWindow;
  }

  /// Calculate delay before next request
  Duration calculateDelay() {
    final requestCount = _requestHistory.length;

    // Exponential backoff based on recent request count
    final multiplier = pow(1.5, requestCount ~/ 3)
        .toDouble(); // Increase delay every 3 requests
    final calculatedDelay = Duration(
      milliseconds: (_baseDelay.inMilliseconds * multiplier).round(),
    );

    // Cap at 15 seconds maximum
    const maxDelay = Duration(seconds: 15);
    final finalDelay = Duration(
      milliseconds:
          min(calculatedDelay.inMilliseconds, maxDelay.inMilliseconds),
    );

    // Add random jitter (±20%)
    final jitter = Random().nextDouble() * 0.4 - 0.2; // -20% to +20%
    final jitteredDelay = Duration(
      milliseconds: (finalDelay.inMilliseconds * (1 + jitter)).round(),
    );

    return jitteredDelay;
  }

  /// Record a successful request
  void recordRequest() {
    _requestHistory.add(DateTime.now());
    _cleanupOldRequests();

    _logger.d(
        'Request recorded. Total in window: ${_requestHistory.length}/$_maxRequestsPerWindow');
  }

  /// Trigger cooldown period when rate limit is detected
  void triggerCooldown(
      {Duration cooldownDuration = const Duration(minutes: 2)}) {
    _isInCooldown = true;
    _cooldownEndTime = DateTime.now().add(cooldownDuration);
    _logger.w(
        'Rate limit triggered, entering cooldown for ${cooldownDuration.inMinutes} minutes');

    // Clear request history to start fresh after cooldown
    _requestHistory.clear();
  }

  /// Check if currently in cooldown
  bool get isInCooldown =>
      _isInCooldown &&
      _cooldownEndTime != null &&
      DateTime.now().isBefore(_cooldownEndTime!);

  /// Get remaining cooldown time
  Duration? get remainingCooldown {
    if (!isInCooldown) return null;
    return _cooldownEndTime!.difference(DateTime.now());
  }

  /// Get current request rate statistics
  Map<String, dynamic> getStatistics() {
    _cleanupOldRequests();
    return {
      'requestsInWindow': _requestHistory.length,
      'maxRequestsPerWindow': _maxRequestsPerWindow,
      'isInCooldown': isInCooldown,
      'remainingCooldownSeconds': remainingCooldown?.inSeconds,
      'canMakeRequest': canMakeRequest(),
      'suggestedDelayMs': calculateDelay().inMilliseconds,
    };
  }

  /// Clean up old requests outside the time window
  void _cleanupOldRequests() {
    final now = DateTime.now();
    _requestHistory
        .removeWhere((time) => now.difference(time) > _defaultTimeWindow);
  }

  /// Reset all counters and state
  void reset() {
    _requestHistory.clear();
    _isInCooldown = false;
    _cooldownEndTime = null;
    _logger.i('Request rate manager reset');
  }

  /// Dispose resources
  void dispose() {
    _requestHistory.clear();
    _logger.i('Request rate manager disposed');
  }
}
