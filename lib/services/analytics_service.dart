import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive Analytics Service for Local User Behavior Tracking
/// 
/// Features:
/// - Privacy-first: All data stored locally, no external tracking
/// - User consent based: Only tracks with explicit user permission
/// - Performance monitoring: App performance and user experience metrics
/// - Feature usage: Track which features are used most
/// - Error analytics: Track and categorize application errors
/// - Reading patterns: Anonymous reading behavior analysis
class AnalyticsService {
  static final Logger _logger = Logger();
  static const String _analyticsEnabledKey = 'analytics_enabled';
  static const String _analyticsDataKey = 'analytics_data';
  static const String _sessionDataKey = 'session_data';
  
  late final SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _analyticsEnabled = false;
  DateTime? _sessionStartTime;

  // Localization callback
  String Function(String key, {Map<String, dynamic>? args})? _localize;
  
  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _analyticsEnabled = _prefs.getBool(_analyticsEnabledKey) ?? false;
      _sessionStartTime = DateTime.now();
      _isInitialized = true;
      
      if (_analyticsEnabled) {
        await _trackEvent(AnalyticsEvent.appStarted());
        _logger.i(_getLocalized('analyticsServiceInitialized',
          args: {'enabled': 'enabled'},
          fallback: 'Analytics service initialized - tracking enabled'));
      } else {
        _logger.i(_getLocalized('analyticsServiceInitialized',
          args: {'enabled': 'disabled'},
          fallback: 'Analytics service initialized - tracking disabled'));
      }
    } catch (e) {
      _logger.e('Failed to initialize analytics service: $e');
    }
  }
  
  /// Enable or disable analytics tracking with user consent
  Future<void> setAnalyticsEnabled(bool enabled) async {
    if (!_isInitialized) await initialize();
    
    _analyticsEnabled = enabled;
    await _prefs.setBool(_analyticsEnabledKey, enabled);
    
    if (enabled) {
      await _trackEvent(AnalyticsEvent.analyticsEnabled());
      _logger.i(_getLocalized('analyticsTrackingEnabled',
        fallback: 'Analytics tracking enabled by user'));
    } else {
      await _trackEvent(AnalyticsEvent.analyticsDisabled());
      await _clearAnalyticsData();
      _logger.i(_getLocalized('analyticsTrackingDisabled',
        fallback: 'Analytics tracking disabled by user - data cleared'));
    }
  }
  
  /// Check if analytics is enabled
  bool get isAnalyticsEnabled => _analyticsEnabled;
  
  /// Track a custom event
  Future<void> trackEvent(AnalyticsEvent event) async {
    if (!_isInitialized) await initialize();
    if (!_analyticsEnabled) return;
    
    await _trackEvent(event);
  }
  
  /// Track screen view
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {
    await trackEvent(AnalyticsEvent.screenView(screenName, parameters: parameters));
  }
  
  /// Track user action (button tap, menu item selected, etc.)
  Future<void> trackAction(String action, {Map<String, dynamic>? parameters}) async {
    await trackEvent(AnalyticsEvent.userAction(action, parameters: parameters));
  }
  
  /// Track performance metrics
  Future<void> trackPerformance(String operation, Duration duration, {Map<String, dynamic>? metadata}) async {
    await trackEvent(AnalyticsEvent.performance(operation, duration, metadata: metadata));
  }
  
  /// Track application errors
  Future<void> trackError(String errorType, String errorMessage, {StackTrace? stackTrace}) async {
    await trackEvent(AnalyticsEvent.error(errorType, errorMessage, stackTrace: stackTrace));
  }
  
  /// Track feature usage
  Future<void> trackFeatureUsage(String feature, {Map<String, dynamic>? context}) async {
    await trackEvent(AnalyticsEvent.featureUsage(feature, context: context));
  }
  
  /// Track reading session metrics
  Future<void> trackReadingSession(String contentId, Duration readingTime, int pagesRead) async {
    await trackEvent(AnalyticsEvent.readingSession(contentId, readingTime, pagesRead));
  }
  
  /// Get analytics summary for display in settings/debug
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    if (!_isInitialized) await initialize();
    if (!_analyticsEnabled) return {'enabled': false};
    
    try {
      final analyticsData = _prefs.getString(_analyticsDataKey);
      if (analyticsData == null) return {'enabled': true, 'events': 0};
      
      final events = (jsonDecode(analyticsData) as List).cast<Map<String, dynamic>>();
      final now = DateTime.now();
      final sessionTime = _sessionStartTime != null 
          ? now.difference(_sessionStartTime!).inMinutes 
          : 0;
      
      // Calculate metrics
      final totalEvents = events.length;
      final recentEvents = events.where((e) {
        final eventTime = DateTime.parse(e['timestamp']);
        return now.difference(eventTime).inDays <= 7;
      }).length;
      
      final screenViews = events.where((e) => e['eventType'] == 'screen_view').length;
      final actions = events.where((e) => e['eventType'] == 'user_action').length;
      final errors = events.where((e) => e['eventType'] == 'error').length;
      
      return {
        'enabled': true,
        'sessionTimeMinutes': sessionTime,
        'totalEvents': totalEvents,
        'recentEvents': recentEvents,
        'screenViews': screenViews,
        'userActions': actions,
        'errors': errors,
        'dataSize': analyticsData.length,
      };
    } catch (e) {
      _logger.e('Failed to get analytics summary: $e');
      return {'enabled': true, 'error': e.toString()};
    }
  }
  
  /// Export analytics data (for debugging or user data export)
  Future<String?> exportAnalyticsData() async {
    if (!_isInitialized) await initialize();
    if (!_analyticsEnabled) return null;
    
    try {
      final data = _prefs.getString(_analyticsDataKey);
      return data;
    } catch (e) {
      _logger.e('Failed to export analytics data: $e');
      return null;
    }
  }
  
  /// Clear all analytics data
  Future<void> clearAnalyticsData() async {
    if (!_isInitialized) await initialize();
    await _clearAnalyticsData();
    _logger.i(_getLocalized('analyticsDataCleared',
      fallback: 'Analytics data cleared by user request'));
  }
  
  /// Internal method to track events
  Future<void> _trackEvent(AnalyticsEvent event) async {
    try {
      final eventData = event.toJson();
      
      // Get existing events
      final existingData = _prefs.getString(_analyticsDataKey);
      List<Map<String, dynamic>> events = [];
      
      if (existingData != null) {
        events = (jsonDecode(existingData) as List).cast<Map<String, dynamic>>();
      }
      
      // Add new event
      events.add(eventData);
      
      // Keep only last 1000 events to prevent excessive storage
      if (events.length > 1000) {
        events = events.sublist(events.length - 1000);
      }
      
      // Save back to storage
      await _prefs.setString(_analyticsDataKey, jsonEncode(events));
      
      if (kDebugMode) {
        _logger.d(_getLocalized('analyticsEventTracked',
          args: {'eventType': event.eventType, 'eventName': event.eventName},
          fallback: '📊 Analytics: ${event.eventType} - ${event.eventName}'));
      }
    } catch (e) {
      _logger.e('Failed to track analytics event: $e');
    }
  }
  
  /// Clear analytics data from storage
  Future<void> _clearAnalyticsData() async {
    try {
      await _prefs.remove(_analyticsDataKey);
      await _prefs.remove(_sessionDataKey);
    } catch (e) {
      _logger.e('Failed to clear analytics data: $e');
    }
  }
  
  /// Dispose resources and track session end
  Future<void> dispose() async {
    if (_analyticsEnabled && _sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      await _trackEvent(AnalyticsEvent.sessionEnd(sessionDuration));
    }
    _logger.i(_getLocalized('analyticsServiceDisposed',
      fallback: 'Analytics service disposed'));
  }

  /// Set localization callback for getting localized strings
  void setLocalizationCallback(String Function(String key, {Map<String, dynamic>? args}) localize) {
    _localize = localize;
    _logger.i('AnalyticsService: Localization callback set');
  }

  /// Get localized string with fallback
  String _getLocalized(String key, {Map<String, dynamic>? args, String? fallback}) {
    try {
      return _localize?.call(key, args: args) ?? fallback ?? key;
    } catch (e) {
      _logger.w('Failed to get localized string for key: $key, error: $e');
      return fallback ?? key;
    }
  }
}

/// Analytics Event Model
class AnalyticsEvent {
  final String eventType;
  final String eventName;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  
  AnalyticsEvent._({
    required this.eventType,
    required this.eventName,
    required this.parameters,
    required this.timestamp,
  });
  
  // App lifecycle events
  factory AnalyticsEvent.appStarted() => AnalyticsEvent._(
    eventType: 'app_lifecycle',
    eventName: 'app_started',
    parameters: {},
    timestamp: DateTime.now(),
  );
  
  factory AnalyticsEvent.sessionEnd(Duration sessionDuration) => AnalyticsEvent._(
    eventType: 'app_lifecycle',
    eventName: 'session_end',
    parameters: {'session_duration_minutes': sessionDuration.inMinutes},
    timestamp: DateTime.now(),
  );
  
  factory AnalyticsEvent.analyticsEnabled() => AnalyticsEvent._(
    eventType: 'settings',
    eventName: 'analytics_enabled',
    parameters: {},
    timestamp: DateTime.now(),
  );
  
  factory AnalyticsEvent.analyticsDisabled() => AnalyticsEvent._(
    eventType: 'settings',
    eventName: 'analytics_disabled',
    parameters: {},
    timestamp: DateTime.now(),
  );
  
  // Screen tracking
  factory AnalyticsEvent.screenView(String screenName, {Map<String, dynamic>? parameters}) => AnalyticsEvent._(
    eventType: 'screen_view',
    eventName: 'screen_viewed',
    parameters: {'screen_name': screenName, ...?parameters},
    timestamp: DateTime.now(),
  );
  
  // User actions
  factory AnalyticsEvent.userAction(String action, {Map<String, dynamic>? parameters}) => AnalyticsEvent._(
    eventType: 'user_action',
    eventName: action,
    parameters: parameters ?? {},
    timestamp: DateTime.now(),
  );
  
  // Performance monitoring
  factory AnalyticsEvent.performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) => AnalyticsEvent._(
    eventType: 'performance',
    eventName: operation,
    parameters: {
      'duration_ms': duration.inMilliseconds,
      'operation': operation,
      ...?metadata
    },
    timestamp: DateTime.now(),
  );
  
  // Error tracking
  factory AnalyticsEvent.error(String errorType, String errorMessage, {StackTrace? stackTrace}) => AnalyticsEvent._(
    eventType: 'error',
    eventName: errorType,
    parameters: {
      'error_type': errorType,
      'error_message': errorMessage,
      'has_stack_trace': stackTrace != null,
    },
    timestamp: DateTime.now(),
  );
  
  // Feature usage
  factory AnalyticsEvent.featureUsage(String feature, {Map<String, dynamic>? context}) => AnalyticsEvent._(
    eventType: 'feature_usage',
    eventName: feature,
    parameters: {'feature': feature, ...?context},
    timestamp: DateTime.now(),
  );
  
  // Reading sessions
  factory AnalyticsEvent.readingSession(String contentId, Duration readingTime, int pagesRead) => AnalyticsEvent._(
    eventType: 'reading_session',
    eventName: 'reading_completed',
    parameters: {
      'content_id': contentId,
      'reading_time_minutes': readingTime.inMinutes,
      'pages_read': pagesRead,
    },
    timestamp: DateTime.now(),
  );
  
  // Content interaction
  factory AnalyticsEvent.contentInteraction(String interaction, String contentId, {Map<String, dynamic>? metadata}) => AnalyticsEvent._(
    eventType: 'content_interaction',
    eventName: interaction,
    parameters: {
      'interaction': interaction,
      'content_id': contentId,
      ...?metadata
    },
    timestamp: DateTime.now(),
  );
  
  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'eventName': eventName,
    'parameters': parameters,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent._(
    eventType: json['eventType'],
    eventName: json['eventName'],
    parameters: Map<String, dynamic>.from(json['parameters']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}
