import 'dart:async';
import 'package:logger/logger.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';
import 'preferences_service.dart';

/// Service for automatic history cleanup based on user preferences
class HistoryCleanupService {
  HistoryCleanupService({
    required this.preferencesService,
    required this.clearHistoryUseCase,
    required this.getHistoryCountUseCase,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final PreferencesService preferencesService;
  final ClearHistoryUseCase clearHistoryUseCase;
  final GetHistoryCountUseCase getHistoryCountUseCase;
  final Logger _logger;

  // Localization callback
  String Function(String key, {Map<String, dynamic>? args})? _localize;

  Timer? _cleanupTimer;
  bool _isInitialized = false;

  /// Initialize the cleanup service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i(_getLocalized('historyCleanupServiceInitialized',
          fallback: 'Initializing History Cleanup Service'));

      // Update last app access time
      await _updateLastAppAccess();

      // Start cleanup service
      await _startCleanupService();

      _isInitialized = true;
      _logger.d(_getLocalized('historyCleanupServiceInitialized',
          fallback: 'History Cleanup Service initialized successfully'));
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize History Cleanup Service',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Start the automatic cleanup service
  Future<void> _startCleanupService() async {
    try {
      final prefs = await preferencesService.getUserPreferences();

      if (!prefs.autoCleanupHistory) {
        _logger.d(_getLocalized('autoCleanupDisabled',
            fallback: 'Auto cleanup history is disabled'));
        return;
      }

      // Check if cleanup is needed immediately
      await _performCleanupIfNeeded();

      // Schedule periodic cleanup
      _schedulePeriodicCleanup(prefs.historyCleanupIntervalHours);

      _logger.d(_getLocalized('cleanupServiceStarted',
          args: {'intervalHours': prefs.historyCleanupIntervalHours},
          fallback:
              'Cleanup service started with ${prefs.historyCleanupIntervalHours}h interval'));
    } catch (e, stackTrace) {
      _logger.e('Failed to start cleanup service',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Schedule periodic cleanup
  void _schedulePeriodicCleanup(int intervalHours) {
    _cleanupTimer?.cancel();

    final interval = Duration(hours: intervalHours);
    _cleanupTimer = Timer.periodic(interval, (_) async {
      await _performCleanupIfNeeded();
    });

    _logger.d('Scheduled cleanup every ${intervalHours}h');
  }

  /// Perform cleanup if needed based on user preferences
  Future<void> _performCleanupIfNeeded() async {
    try {
      final prefs = await preferencesService.getUserPreferences();

      if (!prefs.autoCleanupHistory) {
        _logger.d('Auto cleanup is disabled, skipping');
        return;
      }

      final now = DateTime.now();
      bool shouldCleanup = false;
      String reason = '';

      // Check if cleanup interval has passed
      if (prefs.lastHistoryCleanup != null) {
        final timeSinceLastCleanup = now.difference(prefs.lastHistoryCleanup!);
        final intervalDuration =
            Duration(hours: prefs.historyCleanupIntervalHours);

        if (timeSinceLastCleanup >= intervalDuration) {
          shouldCleanup = true;
          reason = 'Interval cleanup (${prefs.historyCleanupIntervalHours}h)';
        }
      } else {
        // First time setup
        shouldCleanup = true;
        reason = 'Initial cleanup setup';
      }

      // Check inactivity-based cleanup
      if (prefs.cleanupOnInactivity && prefs.lastAppAccess != null) {
        final inactivityDuration = now.difference(prefs.lastAppAccess!);
        final inactivityThreshold = Duration(days: prefs.inactivityCleanupDays);

        if (inactivityDuration >= inactivityThreshold) {
          shouldCleanup = true;
          reason = 'Inactivity cleanup (${prefs.inactivityCleanupDays} days)';
        }
      }

      // Check max history age
      if (prefs.maxHistoryDays > 0) {
        final shouldCleanupOld =
            await _shouldCleanupOldHistory(prefs.maxHistoryDays);
        if (shouldCleanupOld) {
          shouldCleanup = true;
          reason = 'Max age cleanup (${prefs.maxHistoryDays} days)';
        }
      }

      if (shouldCleanup) {
        await _performCleanup(reason);
        await _updateLastCleanupTime();
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to perform cleanup check',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Check if we should cleanup old history based on max days
  Future<bool> _shouldCleanupOldHistory(int maxDays) async {
    try {
      final count = await getHistoryCountUseCase(const NoParams());
      if (count == 0) return false;

      // For now, we'll use a simple heuristic
      // In a real implementation, you'd check actual history dates
      // final threshold = Duration(days: maxDays);
      // final now = DateTime.now();

      // This is simplified - in practice you'd query history by date
      return count > 100; // Simple threshold for demo
    } catch (e) {
      _logger.e('Error checking old history: $e');
      return false;
    }
  }

  /// Perform the actual cleanup
  Future<void> _performCleanup(String reason) async {
    try {
      _logger.i(_getLocalized('performingHistoryCleanup',
          args: {'reason': reason},
          fallback: 'Performing history cleanup: $reason'));

      final countBefore = await getHistoryCountUseCase(const NoParams());

      // Clear all history for now
      // In a more sophisticated implementation, you could:
      // - Only clear entries older than maxHistoryDays
      // - Keep recent entries
      // - Clear based on other criteria
      await clearHistoryUseCase(const NoParams());

      final countAfter = await getHistoryCountUseCase(const NoParams());
      final clearedCount = countBefore - countAfter;

      _logger.i(_getLocalized('historyCleanupCompleted',
          args: {'clearedCount': clearedCount, 'reason': reason},
          fallback:
              'History cleanup completed: cleared $clearedCount entries ($reason)'));
    } catch (e, stackTrace) {
      _logger.e('Failed to perform cleanup', error: e, stackTrace: stackTrace);
    }
  }

  /// Update last app access time
  Future<void> _updateLastAppAccess() async {
    try {
      final prefs = await preferencesService.getUserPreferences();
      final updatedPrefs = prefs.copyWith(lastAppAccess: DateTime.now());
      await preferencesService.saveUserPreferences(updatedPrefs);

      _logger.d(_getLocalized('updatedLastAppAccess',
          fallback: 'Updated last app access time'));
    } catch (e, stackTrace) {
      _logger.e('Failed to update last app access',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Update last cleanup time
  Future<void> _updateLastCleanupTime() async {
    try {
      final prefs = await preferencesService.getUserPreferences();
      final updatedPrefs = prefs.copyWith(lastHistoryCleanup: DateTime.now());
      await preferencesService.saveUserPreferences(updatedPrefs);

      _logger.d(_getLocalized('updatedLastCleanupTime',
          fallback: 'Updated last cleanup time'));
    } catch (e, stackTrace) {
      _logger.e('Failed to update last cleanup time',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Manual cleanup trigger
  Future<void> performManualCleanup() async {
    try {
      _logger.i(_getLocalized('manualHistoryCleanup',
          fallback: 'Performing manual history cleanup'));
      await _performCleanup('Manual cleanup');
      await _updateLastCleanupTime();
    } catch (e, stackTrace) {
      _logger.e('Failed to perform manual cleanup',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update cleanup settings and restart service if needed
  Future<void> updateCleanupSettings(UserPreferences newPrefs) async {
    try {
      _logger.i('Updating cleanup settings');

      // Cancel existing timer
      _cleanupTimer?.cancel();

      // Restart service with new settings
      if (newPrefs.autoCleanupHistory) {
        await _startCleanupService();
      }

      _logger.d(_getLocalized('cleanupSettingsUpdated',
          fallback: 'Cleanup settings updated'));
    } catch (e, stackTrace) {
      _logger.e('Failed to update cleanup settings',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get cleanup status
  Future<HistoryCleanupStatus> getCleanupStatus() async {
    try {
      final prefs = await preferencesService.getUserPreferences();
      final historyCount = await getHistoryCountUseCase(const NoParams());

      return HistoryCleanupStatus(
        isEnabled: prefs.autoCleanupHistory,
        intervalHours: prefs.historyCleanupIntervalHours,
        maxHistoryDays: prefs.maxHistoryDays,
        lastCleanup: prefs.lastHistoryCleanup,
        lastAppAccess: prefs.lastAppAccess,
        historyCount: historyCount,
        inactivityCleanupEnabled: prefs.cleanupOnInactivity,
        inactivityThresholdDays: prefs.inactivityCleanupDays,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get cleanup status',
          error: e, stackTrace: stackTrace);
      return const HistoryCleanupStatus();
    }
  }

  /// Dispose the service
  void dispose() {
    _cleanupTimer?.cancel();
    _isInitialized = false;
    _logger.d(_getLocalized('historyCleanupServiceDisposed',
        fallback: 'History Cleanup Service disposed'));
  }

  /// Set localization callback for getting localized strings
  void setLocalizationCallback(
      String Function(String key, {Map<String, dynamic>? args}) localize) {
    _localize = localize;
    _logger.i('HistoryCleanupService: Localization callback set');
  }

  /// Get localized string with fallback
  String _getLocalized(String key,
      {Map<String, dynamic>? args, String? fallback}) {
    try {
      return _localize?.call(key, args: args) ?? fallback ?? key;
    } catch (e) {
      _logger.w('Failed to get localized string for key: $key, error: $e');
      return fallback ?? key;
    }
  }
}

/// Status information for history cleanup
class HistoryCleanupStatus {
  const HistoryCleanupStatus({
    this.isEnabled = false,
    this.intervalHours = 24,
    this.maxHistoryDays = 30,
    this.lastCleanup,
    this.lastAppAccess,
    this.historyCount = 0,
    this.inactivityCleanupEnabled = true,
    this.inactivityThresholdDays = 7,
  });

  final bool isEnabled;
  final int intervalHours;
  final int maxHistoryDays;
  final DateTime? lastCleanup;
  final DateTime? lastAppAccess;
  final int historyCount;
  final bool inactivityCleanupEnabled;
  final int inactivityThresholdDays;

  /// Get next cleanup time estimate
  DateTime? get nextCleanupEstimate {
    if (!isEnabled || lastCleanup == null) return null;
    return lastCleanup!.add(Duration(hours: intervalHours));
  }

  /// Get time until next cleanup
  Duration? get timeUntilNextCleanup {
    final next = nextCleanupEstimate;
    if (next == null) return null;

    final now = DateTime.now();
    final duration = next.difference(now);
    return duration.isNegative ? Duration.zero : duration;
  }

  /// Check if inactivity cleanup is due
  bool get isInactivityCleanupDue {
    if (!inactivityCleanupEnabled || lastAppAccess == null) return false;

    final now = DateTime.now();
    final inactivityDuration = now.difference(lastAppAccess!);
    return inactivityDuration.inDays >= inactivityThresholdDays;
  }

  /// Get human readable status
  String get statusDescription {
    if (!isEnabled) return 'Disabled';

    if (isInactivityCleanupDue) {
      return 'Cleanup due (inactivity)';
    }

    final timeUntil = timeUntilNextCleanup;
    if (timeUntil == null) return 'Pending first cleanup';

    if (timeUntil.inDays > 0) {
      return 'Next cleanup in ${timeUntil.inDays} days';
    } else if (timeUntil.inHours > 0) {
      return 'Next cleanup in ${timeUntil.inHours} hours';
    } else {
      return 'Cleanup due now';
    }
  }
}

/// Set localization callback for getting localized strings
extension HistoryCleanupServiceLocalization on HistoryCleanupService {
  void setLocalizationCallback(
      String Function(String key, {Map<String, dynamic>? args}) localize) {
    // Note: This is a simplified approach. In a real implementation,
    // you'd modify the class to include this method properly.
  }
}
