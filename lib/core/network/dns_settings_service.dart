import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dns_models.dart';

/// Service for managing DNS settings persistence and state
class DnsSettingsService {
  static const String _settingsKey = 'dns_settings_v1';

  final SharedPreferences _prefs;
  final Logger _logger;

  /// Stream controller for DNS settings changes
  final _settingsController = StreamController<DnsSettings>.broadcast();

  /// Stream of DNS settings changes
  Stream<DnsSettings> get settingsStream => _settingsController.stream;

  /// Current DNS settings (cached)
  DnsSettings _currentSettings = const DnsSettings.defaultSettings();

  /// Get current DNS settings
  DnsSettings get currentSettings => _currentSettings;

  DnsSettingsService({
    required SharedPreferences prefs,
    required Logger logger,
  })  : _prefs = prefs,
        _logger = logger;

  /// Initialize service and load settings from storage
  Future<void> initialize() async {
    try {
      _currentSettings = await loadSettings();
      _logger.i(
          'DnsSettingsService initialized: ${_currentSettings.provider.name}');
    } catch (e) {
      _logger.e('Failed to initialize DNS settings', error: e);
      _currentSettings = const DnsSettings.defaultSettings();
    }
  }

  /// Load DNS settings from SharedPreferences.
  /// If no settings are saved, or the saved settings match the old default
  /// (system DNS + disabled), migrates automatically to Cloudflare DoH.
  Future<DnsSettings> loadSettings() async {
    try {
      final jsonString = _prefs.getString(_settingsKey);

      if (jsonString == null || jsonString.isEmpty) {
        _logger.d('No saved DNS settings, using Cloudflare DoH default');
        return const DnsSettings.defaultSettings();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = DnsSettings.fromJson(json);

      // Migration: old default was system+disabled → upgrade to Cloudflare DoH
      if (settings.provider == DnsProvider.system && !settings.enabled) {
        _logger
            .i('DnsSettingsService: Migrating DNS settings to Cloudflare DoH '
                'for better connectivity on restricted networks');
        final migrated = const DnsSettings.defaultSettings();
        // Persist migration without broadcasting (service may not be fully inited yet)
        final jsonStr = jsonEncode(migrated.toJson());
        await _prefs.setString(_settingsKey, jsonStr);
        return migrated;
      }

      _logger.d('Loaded DNS settings: ${settings.provider.name}');
      return settings;
    } catch (e) {
      _logger.e('Failed to load DNS settings, using defaults', error: e);
      return const DnsSettings.defaultSettings();
    }
  }

  /// Save DNS settings to SharedPreferences
  Future<void> saveSettings(DnsSettings settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      await _prefs.setString(_settingsKey, jsonString);

      _currentSettings = settings;
      _settingsController.add(settings);

      _logger.i(
        'DNS settings saved: ${settings.provider.name} (enabled: ${settings.enabled})',
      );
    } catch (e) {
      _logger.e('Failed to save DNS settings', error: e);
      rethrow;
    }
  }

  /// Update DNS provider
  Future<void> updateProvider(DnsProvider provider) async {
    final updatedSettings = _currentSettings.copyWith(provider: provider);
    await saveSettings(updatedSettings);
  }

  /// Enable or disable DNS-over-HTTPS
  Future<void> setEnabled(bool enabled) async {
    final updatedSettings = _currentSettings.copyWith(enabled: enabled);
    await saveSettings(updatedSettings);
  }

  /// Set custom DNS server (for custom provider)
  Future<void> setCustomDns(String? server, String? dohUrl) async {
    final updatedSettings = _currentSettings.copyWith(
      customDnsServer: server,
      customDohUrl: dohUrl,
    );
    await saveSettings(updatedSettings);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await saveSettings(const DnsSettings.defaultSettings());
    _logger.i('DNS settings reset to defaults');
  }

  /// Dispose resources
  void dispose() {
    _settingsController.close();
  }
}
