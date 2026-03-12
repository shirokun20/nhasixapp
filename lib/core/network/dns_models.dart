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

  /// Get IP-address-based DoH URL.
  /// Using a numeric IP avoids needing system DNS to reach the DoH server itself,
  /// which solves the bootstrap "chicken-and-egg" problem on blocked networks.
  ///
  /// Notes verified by curl:
  ///   Cloudflare 1.1.1.1 → /dns-query   (JSON API supported) ✅
  ///   Google    8.8.8.8  → /resolve     (NOT /dns-query via IP) ✅
  ///   Quad9     9.9.9.9  → no JSON API via IP (RFC 8484 only) ❌
  String get dohUrlIpBased {
    return switch (this) {
      DnsProvider.cloudflare => 'https://1.1.1.1/dns-query',
      DnsProvider.google =>
        'https://8.8.8.8/resolve', // must use /resolve, not /dns-query
      _ => dohUrl, // quad9/system/custom: fall back to hostname-based URL
    };
  }

  /// IP-based DoH endpoints that actually support JSON API via numeric IP.
  /// Quad9 excluded because it only supports RFC\u20108484 wire format at its IP.
  /// Order: Cloudflare → Google.
  static List<String> get allDohIpUrls => [
        'https://1.1.1.1/dns-query', // Cloudflare ✔️
        'https://8.8.8.8/resolve', // Google ✔️ (/resolve for JSON API)
      ];

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

  /// Default settings — Cloudflare DoH enabled.
  /// Using 1.1.1.1 (IP-based endpoint) means no system DNS is needed to
  /// reach Cloudflare, so this works even on networks that block DNS.
  const DnsSettings.defaultSettings()
      : provider = DnsProvider.cloudflare,
        customDnsServer = null,
        customDohUrl = null,
        enabled = true;

  /// Get effective DoH URL based on provider (hostname-based)
  String get effectiveDohUrl {
    if (provider == DnsProvider.custom && customDohUrl != null) {
      return customDohUrl!;
    }
    return provider.dohUrl;
  }

  /// Get effective IP-based DoH URL (no bootstrap DNS needed)
  String get effectiveDohUrlIpBased {
    if (provider == DnsProvider.custom && customDohUrl != null) {
      return customDohUrl!;
    }
    return provider.dohUrlIpBased;
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
  String toString() =>
      'DnsSettings(provider: ${provider.name}, enabled: $enabled)';
}
