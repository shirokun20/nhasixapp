import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/network/dns_models.dart';
import 'package:nhasixapp/core/network/dns_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DnsProvider Tests', () {
    test('Cloudflare provider has correct configuration', () {
      expect(DnsProvider.cloudflare.displayName, 'Cloudflare (1.1.1.1)');
      expect(DnsProvider.cloudflare.dnsServers, ['1.1.1.1', '1.0.0.1']);
      expect(DnsProvider.cloudflare.dohUrl,
          'https://cloudflare-dns.com/dns-query');
    });

    test('Google provider has correct configuration', () {
      expect(DnsProvider.google.displayName, 'Google (8.8.8.8)');
      expect(DnsProvider.google.dnsServers, ['8.8.8.8', '8.8.4.4']);
      expect(DnsProvider.google.dohUrl, 'https://dns.google/dns-query');
    });

    test('Quad9 provider has correct configuration', () {
      expect(DnsProvider.quad9.displayName, 'Quad9 (9.9.9.9)');
      expect(DnsProvider.quad9.dnsServers, ['9.9.9.9', '149.112.112.112']);
      expect(DnsProvider.quad9.dohUrl, 'https://dns.quad9.net/dns-query');
    });

    test('All providers have display names', () {
      for (final provider in DnsProvider.values) {
        expect(provider.displayName, isNotEmpty);
      }
    });
  });

  group('DnsSettings Model Tests', () {
    test('DnsSettings with required provider', () {
      const settings = DnsSettings(provider: DnsProvider.cloudflare);

      expect(settings.provider, DnsProvider.cloudflare);
      expect(settings.enabled, true); // FIXED: Default is true
    });

    test('DnsSettings copyWith works correctly', () {
      const original = DnsSettings(provider: DnsProvider.system);

      final updated = original.copyWith(
        enabled: true,
        provider: DnsProvider.cloudflare,
      );

      expect(updated.enabled, true);
      expect(updated.provider, DnsProvider.cloudflare);
    });

    test('DnsSettings toJson and fromJson round trip', () {
      const original = DnsSettings(
        enabled: true,
        provider: DnsProvider.google,
        customDnsServer: '8.8.8.8',
        customDohUrl: 'https://dns.google/dns-query',
      );

      final json = original.toJson();
      final restored = DnsSettings.fromJson(json);

      expect(restored.enabled, original.enabled);
      expect(restored.provider, original.provider);
      expect(restored.customDnsServer, original.customDnsServer);
      expect(restored.customDohUrl, original.customDohUrl);
    });

    test('Effective DoH URL returns provider URL', () {
      const settings = DnsSettings(
        enabled: true,
        provider: DnsProvider.cloudflare,
      );

      expect(settings.effectiveDohUrl, 'https://cloudflare-dns.com/dns-query');
    });

    test('Effective DoH URL returns custom URL for custom provider', () {
      const settings = DnsSettings(
        enabled: true,
        provider: DnsProvider.custom,
        customDohUrl: 'https://my-dns.com/query',
      );

      expect(settings.effectiveDohUrl, 'https://my-dns.com/query');
    });
  });

  group('DnsSettingsService Tests', () {
    late DnsSettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final logger = Logger(level: Level.off);
      service = DnsSettingsService(prefs: prefs, logger: logger);
    });

    test('Initial settings are default', () {
      expect(service.currentSettings.enabled, false);
      expect(service.currentSettings.provider, DnsProvider.system);
    });

    test('Save and load settings persist correctly', () async {
      const newSettings = DnsSettings(
        enabled: true,
        provider: DnsProvider.cloudflare,
      );

      await service.saveSettings(newSettings);

      expect(service.currentSettings.enabled, true);
      expect(service.currentSettings.provider, DnsProvider.cloudflare);
    });

    test('Update provider changes current settings', () async {
      await service.updateProvider(DnsProvider.quad9);

      expect(service.currentSettings.provider, DnsProvider.quad9);
    });

    test('Set custom DNS updates settings correctly', () async {
      await service.setCustomDns('1.1.1.1', 'https://custom.dns/query');

      expect(service.currentSettings.customDnsServer, '1.1.1.1');
      expect(service.currentSettings.customDohUrl, 'https://custom.dns/query');
    });

    test('Reset to defaults clears all custom settings', () async {
      await service.saveSettings(const DnsSettings(
        enabled: true,
        provider: DnsProvider.cloudflare,
        customDnsServer: '1.1.1.1',
      ));

      await service.resetToDefaults();

      expect(service.currentSettings.enabled, false);
      expect(service.currentSettings.provider, DnsProvider.system);
      expect(service.currentSettings.customDnsServer, null);
    });
  });
}
