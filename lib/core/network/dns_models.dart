import 'package:equatable/equatable.dart';

/// DNS Provider options for DNS-over-HTTPS
enum DnsProvider {
  /// Use system default DNS resolver
  system('System Default', [], ''),
  
  /// Cloudflare DNS (1.1.1.1)
  cloudflare(
    'Cloudflare (1.1.1.1)',
    ['1.1.1.1', '1.0.0.1'],
    'https://cloudflare-dns.com/dns-query',
  ),
  
  /// Google Public DNS (8.8.8.8)
  google(
    'Google (8.8.8.8)',
    ['8.8.8.8', '8.8.4.4'],
    'https://dns.google/dns-query',
  ),
  
  /// Quad9 DNS (9.9.9.9)
  quad9(
    'Quad9 (9.9.9.9)',
    ['9.9.9.9', '149.112.112.112'],
    'https://dns.quad9.net/dns-query',
  ),
  
  /// Custom DNS server
  custom('Custom DNS', [], '');

  /// Human-readable display name
  final String displayName;
  
  /// DNS server IP addresses (for bootstrap)
  final List<String> dnsServers;
  
  /// DNS-over-HTTPS URL endpoint
  final String dohUrl;

  const DnsProvider(this.displayName, this.dnsServers, this.dohUrl);

  /// Get provider from name string (for deserialization)
  static DnsProvider fromName(String name) {
    return DnsProvider.values.firstWhere(
      (provider) => provider.name == name,
      orElse: () => DnsProvider.system,
    );
  }
}

/// DNS configuration settings
class DnsSettings extends Equatable {
  /// Selected DNS provider
  final DnsProvider provider;
  
  /// Custom DNS server address (only used when provider is custom)
  final String? customDnsServer;
  
  /// Custom DoH URL (only used when provider is custom)
  final String? customDohUrl;
  
  /// Whether DNS-over-HTTPS is enabled
  final bool enabled;

  const DnsSettings({
    required this.provider,
    this.customDnsServer,
    this.customDohUrl,
    this.enabled = true,
  });

  /// Default settings (system DNS)
  const DnsSettings.defaultSettings()
      : provider = DnsProvider.system,
        customDnsServer = null,
        customDohUrl = null,
        enabled = false;

  /// Get effective DoH URL based on provider
  String get effectiveDohUrl {
    if (provider == DnsProvider.custom && customDohUrl != null) {
      return customDohUrl!;
    }
    return provider.dohUrl;
  }

  /// Get effective DNS servers based on provider
  List<String> get effectiveDnsServers {
    if (provider == DnsProvider.custom && customDnsServer != null) {
      return [customDnsServer!];
    }
    return provider.dnsServers;
  }

  /// Serialize to JSON for persistence
  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'customDnsServer': customDnsServer,
        'customDohUrl': customDohUrl,
        'enabled': enabled,
      };

  /// Deserialize from JSON
  factory DnsSettings.fromJson(Map<String, dynamic> json) {
    return DnsSettings(
      provider: DnsProvider.fromName(json['provider'] as String? ?? 'system'),
      customDnsServer: json['customDnsServer'] as String?,
      customDohUrl: json['customDohUrl'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  /// Create copy with updated fields
  DnsSettings copyWith({
    DnsProvider? provider,
    String? customDnsServer,
    String? customDohUrl,
    bool? enabled,
  }) {
    return DnsSettings(
      provider: provider ?? this.provider,
      customDnsServer: customDnsServer ?? this.customDnsServer,
      customDohUrl: customDohUrl ?? this.customDohUrl,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [provider, customDnsServer, customDohUrl, enabled];

  @override
  String toString() => 'DnsSettings(provider: ${provider.name}, enabled: $enabled)';
}
