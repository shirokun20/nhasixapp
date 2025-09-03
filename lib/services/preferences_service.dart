import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/user_preferences.dart';

/// Service for handling app preferences using SharedPreferences
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // Setting keys
  static const String _keyAutoCleanupHistory = 'auto_cleanup_history';
  static const String _keyHistoryCleanupInterval = 'history_cleanup_interval_hours';
  static const String _keyMaxHistoryDays = 'max_history_days';
  static const String _keyCleanupOnInactivity = 'cleanup_on_inactivity';
  static const String _keyInactivityCleanupDays = 'inactivity_cleanup_days';
  static const String _keyLastHistoryCleanup = 'last_history_cleanup';
  static const String _keyLastAppAccess = 'last_app_access';
  
  // Other settings
  static const String _keyTheme = 'theme';
  static const String _keyDefaultLanguage = 'default_language';
  static const String _keyShowNsfwContent = 'show_nsfw_content';
  static const String _keyImageQuality = 'image_quality';

  /// Get all user preferences
  Future<UserPreferences> getUserPreferences() async {
    return UserPreferences(
      theme: _prefs.getString(_keyTheme) ?? 'dark',
      defaultLanguage: _prefs.getString(_keyDefaultLanguage) ?? 'english',
      showNsfwContent: _prefs.getBool(_keyShowNsfwContent) ?? true,
      imageQuality: _prefs.getString(_keyImageQuality) ?? 'high',
      
      // History cleanup settings
      autoCleanupHistory: _prefs.getBool(_keyAutoCleanupHistory) ?? false,
      historyCleanupIntervalHours: _prefs.getInt(_keyHistoryCleanupInterval) ?? 24,
      maxHistoryDays: _prefs.getInt(_keyMaxHistoryDays) ?? 30,
      cleanupOnInactivity: _prefs.getBool(_keyCleanupOnInactivity) ?? true,
      inactivityCleanupDays: _prefs.getInt(_keyInactivityCleanupDays) ?? 7,
      
      // Timestamps
      lastHistoryCleanup: _getDateTime(_keyLastHistoryCleanup),
      lastAppAccess: _getDateTime(_keyLastAppAccess),
    );
  }

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await Future.wait([
      _prefs.setString(_keyTheme, preferences.theme),
      _prefs.setString(_keyDefaultLanguage, preferences.defaultLanguage),
      _prefs.setBool(_keyShowNsfwContent, preferences.showNsfwContent),
      _prefs.setString(_keyImageQuality, preferences.imageQuality),
      
      // History cleanup settings
      _prefs.setBool(_keyAutoCleanupHistory, preferences.autoCleanupHistory),
      _prefs.setInt(_keyHistoryCleanupInterval, preferences.historyCleanupIntervalHours),
      _prefs.setInt(_keyMaxHistoryDays, preferences.maxHistoryDays),
      _prefs.setBool(_keyCleanupOnInactivity, preferences.cleanupOnInactivity),
      _prefs.setInt(_keyInactivityCleanupDays, preferences.inactivityCleanupDays),
      
      // Timestamps
      if (preferences.lastHistoryCleanup != null) 
        _prefs.setString(_keyLastHistoryCleanup, preferences.lastHistoryCleanup!.toIso8601String()),
      if (preferences.lastAppAccess != null) 
        _prefs.setString(_keyLastAppAccess, preferences.lastAppAccess!.toIso8601String()),
    ]);
  }

  /// Get specific setting
  Future<T?> getSetting<T>(String key, T? defaultValue) async {
    switch (T) {
      case const (String):
        return _prefs.getString(key) as T? ?? defaultValue;
      case const (bool):
        return _prefs.getBool(key) as T? ?? defaultValue;
      case const (int):
        return _prefs.getInt(key) as T? ?? defaultValue;
      case const (double):
        return _prefs.getDouble(key) as T? ?? defaultValue;
      default:
        return defaultValue;
    }
  }

  /// Set specific setting
  Future<void> setSetting<T>(String key, T value) async {
    switch (T) {
      case const (String):
        await _prefs.setString(key, value as String);
        break;
      case const (bool):
        await _prefs.setBool(key, value as bool);
        break;
      case const (int):
        await _prefs.setInt(key, value as int);
        break;
      case const (double):
        await _prefs.setDouble(key, value as double);
        break;
      default:
        throw UnsupportedError('Type $T is not supported');
    }
  }

  // Individual getters for commonly used settings
  bool get autoCleanupHistory => _prefs.getBool(_keyAutoCleanupHistory) ?? false;
  int get historyCleanupIntervalHours => _prefs.getInt(_keyHistoryCleanupInterval) ?? 24;
  int get maxHistoryDays => _prefs.getInt(_keyMaxHistoryDays) ?? 30;
  bool get cleanupOnInactivity => _prefs.getBool(_keyCleanupOnInactivity) ?? true;
  int get inactivityCleanupDays => _prefs.getInt(_keyInactivityCleanupDays) ?? 7;
  DateTime? get lastHistoryCleanup => _getDateTime(_keyLastHistoryCleanup);
  DateTime? get lastAppAccess => _getDateTime(_keyLastAppAccess);

  // Individual setters
  Future<void> setAutoCleanupHistory(bool value) => _prefs.setBool(_keyAutoCleanupHistory, value);
  Future<void> setHistoryCleanupIntervalHours(int value) => _prefs.setInt(_keyHistoryCleanupInterval, value);
  Future<void> setMaxHistoryDays(int value) => _prefs.setInt(_keyMaxHistoryDays, value);
  Future<void> setCleanupOnInactivity(bool value) => _prefs.setBool(_keyCleanupOnInactivity, value);
  Future<void> setInactivityCleanupDays(int value) => _prefs.setInt(_keyInactivityCleanupDays, value);
  Future<void> setLastHistoryCleanup(DateTime? value) => 
    value != null ? _prefs.setString(_keyLastHistoryCleanup, value.toIso8601String()) : _prefs.remove(_keyLastHistoryCleanup);
  Future<void> setLastAppAccess(DateTime? value) => 
    value != null ? _prefs.setString(_keyLastAppAccess, value.toIso8601String()) : _prefs.remove(_keyLastAppAccess);

  /// Helper method to get DateTime from preferences
  DateTime? _getDateTime(String key) {
    final dateString = _prefs.getString(key);
    if (dateString == null) return null;
    
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Clear all preferences
  Future<void> clear() async {
    await _prefs.clear();
  }

  /// Update last app access timestamp
  Future<void> updateLastAppAccess() async {
    await setLastAppAccess(DateTime.now());
  }
}
