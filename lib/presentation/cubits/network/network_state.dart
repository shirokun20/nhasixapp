part of 'network_cubit.dart';

/// Network connection types
enum NetworkConnectionType {
  wifi,
  mobile,
  ethernet,
  other,
}

/// Base state for NetworkCubit
abstract class NetworkState extends BaseCubitState {
  const NetworkState();
}

/// Initial state before connectivity check
class NetworkInitial extends NetworkState {
  const NetworkInitial();

  @override
  List<Object?> get props => [];
}

/// State when checking connectivity
class NetworkChecking extends NetworkState {
  const NetworkChecking();

  @override
  List<Object?> get props => [];
}

/// State when network is connected
class NetworkConnected extends NetworkState {
  const NetworkConnected({
    required this.connectionType,
  });

  final NetworkConnectionType connectionType;

  @override
  List<Object?> get props => [connectionType];

  /// Get connection type display name
  String get connectionTypeDisplayName {
    switch (connectionType) {
      case NetworkConnectionType.wifi:
        return 'WiFi';
      case NetworkConnectionType.mobile:
        return 'Mobile Data';
      case NetworkConnectionType.ethernet:
        return 'Ethernet';
      case NetworkConnectionType.other:
        return 'Other';
    }
  }

  /// Check if connection is metered (mobile data)
  bool get isMetered => connectionType == NetworkConnectionType.mobile;

  /// Check if connection is fast (WiFi or Ethernet)
  bool get isFastConnection =>
      connectionType == NetworkConnectionType.wifi ||
      connectionType == NetworkConnectionType.ethernet;
}

/// State when network is disconnected
class NetworkDisconnected extends NetworkState {
  const NetworkDisconnected();

  @override
  List<Object?> get props => [];
}

/// State when there's an error with network monitoring
class NetworkError extends NetworkState {
  const NetworkError({
    required this.message,
    required this.errorType,
  });

  final String message;
  final String errorType;

  @override
  List<Object?> get props => [message, errorType];

  /// Check if error is retryable
  bool get canRetry => errorType == 'network' || errorType == 'connectivity';
}
