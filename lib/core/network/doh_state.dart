/// Shared state for DNS-over-HTTPS hostname mapping.
///
/// When [DnsInterceptor] replaces a URL hostname with the resolved IP address,
/// TLS certificate validation would normally fail because the cert is issued for
/// the domain name (e.g. "komiktap.info"), not the IP address.
///
/// [DohState] stores a mapping of IP:port → original hostname so that
/// [HttpClientManager]'s validateCertificate callback can validate the cert
/// against the real domain, not the numeric IP.
class DohState {
  /// IP:port → original hostname mapping
  /// Key example: "104.21.10.5:443"
  final Map<String, String> _ipToHostname = {};

  /// Maximum number of entries to keep (prevents unbounded memory growth)
  static const int _maxEntries = 200;

  /// Register a resolved IP → original hostname mapping.
  /// Called by [DnsInterceptor] after a successful DoH lookup.
  void register(String ip, int port, String originalHostname) {
    // Simple FIFO eviction when over limit
    if (_ipToHostname.length >= _maxEntries) {
      final toRemove = _ipToHostname.keys.take(20).toList();
      for (final key in toRemove) {
        _ipToHostname.remove(key);
      }
    }
    _ipToHostname['$ip:$port'] = originalHostname;
  }

  /// Look up the original hostname for a given IP and port.
  /// Returns [null] if the address was not resolved via DoH (e.g. direct IP).
  String? lookup(String ip, int port) => _ipToHostname['$ip:$port'];

  /// Remove all entries.
  void clear() => _ipToHostname.clear();

  int get size => _ipToHostname.length;
}
