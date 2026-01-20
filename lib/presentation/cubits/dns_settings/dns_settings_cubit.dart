import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../core/network/dns_models.dart';
import '../../../core/network/dns_settings_service.dart';

/// Cubit for managing DNS settings state
class DnsSettingsCubit extends Cubit<DnsSettings> {
  final DnsSettingsService _settingsService;
  final Logger _logger;

  DnsSettingsCubit({
    required DnsSettingsService settingsService,
    required Logger logger,
  })  : _settingsService = settingsService,
        _logger = logger,
        super(settingsService.currentSettings);

  /// Initialize and load current settings
  Future<void> initialize() async {
    try {
      await _settingsService.initialize();
      emit(_settingsService.currentSettings);
    } catch (e) {
      _logger.e('Failed to initialize DNS settings', error: e);
    }
  }

  /// Update DNS settings
  Future<void> updateSettings(DnsSettings settings) async {
    try {
      await _settingsService.saveSettings(settings);
      emit(settings);
    } catch (e) {
      _logger.e('Failed to update DNS settings', error: e);
    }
  }

  /// Update DNS provider
  Future<void> updateProvider(DnsProvider provider) async {
    final updated = state.copyWith(provider: provider);
    await updateSettings(updated);
  }

  /// Toggle DNS-over-HTTPS enabled/disabled
  Future<void> toggleEnabled(bool enabled) async {
    final updated = state.copyWith(enabled: enabled);
    await updateSettings(updated);
  }

  /// Set custom DNS configuration
  Future<void> setCustomDns(String? server, String? dohUrl) async {
    final updated = state.copyWith(
      customDnsServer: server,
      customDohUrl: dohUrl,
    );
    await updateSettings(updated);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      await _settingsService.resetToDefaults();
      emit(_settingsService.currentSettings);
    } catch (e) {
      _logger.e('Failed to reset DNS settings', error: e);
    }
  }
}
