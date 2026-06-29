/// Domain service for app initialization and Cloudflare bypass.
///
/// Provides a clean domain-layer abstraction over initialization logic
/// originally hosted in RemoteDataSource.
abstract class AppInitializer {
  /// Perform one-time initialization (anti-detection, HTTP client setup)
  Future<bool> initialize();

  /// Check if Cloudflare protection is currently active
  Future<bool> checkCloudflareStatus();

  /// Attempt to bypass Cloudflare protection
  Future<bool> bypassCloudflare();
}
