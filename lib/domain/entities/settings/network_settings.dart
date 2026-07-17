/// Network settings entities
/// Extracted from settings_repository.dart
library;

/// Network settings configuration
class NetworkSettings {
  const NetworkSettings({
    required this.connectionTimeout,
    required this.readTimeout,
    required this.maxRetries,
    required this.useProxy,
    this.userAgent,
  });

  final int connectionTimeout;
  final int readTimeout;
  final int maxRetries;
  final bool useProxy;
  final String? userAgent;
}

/// Network status information
class NetworkStatus {
  const NetworkStatus({
    required this.isConnected,
    required this.connectionType,
    required this.responseTime,
    this.error,
  });

  final bool isConnected;
  final String connectionType;
  final int responseTime;
  final String? error;
}

/// Proxy settings configuration
class ProxySettings {
  const ProxySettings({
    required this.enabled,
    this.host,
    this.port,
    this.username,
    this.password,
    this.type = 'HTTP',
  });

  final bool enabled;
  final String? host;
  final int? port;
  final String? username;
  final String? password;
  final String type;

  bool get isConfigured => enabled && host != null && port != null;
}
