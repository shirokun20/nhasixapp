/// DNS over HTTPS provider constants
class DohProvider {
  /// Disabled (use system DNS)
  static const int disabled = -1;

  /// Cloudflare DNS (1.1.1.1)
  static const int cloudflare = 1;

  /// Google DNS (8.8.8.8)
  static const int google = 2;

  /// AdGuard DNS (unfiltered)
  static const int adguard = 3;

  /// Quad9 DNS (9.9.9.9)
  static const int quad9 = 4;

  /// Get provider name
  static String getName(int provider) {
    switch (provider) {
      case cloudflare:
        return 'Cloudflare';
      case google:
        return 'Google';
      case adguard:
        return 'AdGuard';
      case quad9:
        return 'Quad9';
      case disabled:
      default:
        return 'Disabled';
    }
  }

  /// Get all available providers
  static List<int> get all => [disabled, cloudflare, google, adguard, quad9];
}
