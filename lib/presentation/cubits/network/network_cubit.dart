import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import '../base/base_cubit.dart';

part 'network_state.dart';

/// Cubit for tracking network connectivity status
/// Simple state management for connection monitoring
class NetworkCubit extends BaseCubit<NetworkState> {
  NetworkCubit({
    required Connectivity connectivity,
    required Logger logger,
  })  : _connectivity = connectivity,
        super(
          initialState: const NetworkInitial(),
          logger: logger,
        ) {
    _initializeConnectivity();
  }

  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      logInfo('Initializing network connectivity monitoring');

      // Check initial connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResult);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          handleError(error, StackTrace.current, 'connectivity monitoring');
          emit(const NetworkError(
            message: 'Failed to monitor network connectivity',
            errorType: 'connectivity',
          ));
        },
      );
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'initialize connectivity');
      emit(NetworkError(
        message: 'Failed to initialize network monitoring: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    try {
      final isConnected = result != ConnectivityResult.none;

      if (isConnected) {
        final connectionType = _getConnectionType(result);
        logInfo('Network connected: $connectionType');
        emit(NetworkConnected(connectionType: connectionType));
      } else {
        logInfo('Network disconnected');
        emit(const NetworkDisconnected());
      }
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'update connection status');
      emit(NetworkError(
        message: 'Failed to update connection status: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Get connection type from connectivity result
  NetworkConnectionType _getConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkConnectionType.wifi;
      case ConnectivityResult.mobile:
        return NetworkConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkConnectionType.ethernet;
      default:
        return NetworkConnectionType.other;
    }
  }

  /// Manually check connectivity status
  Future<void> checkConnectivity() async {
    try {
      logInfo('Manually checking connectivity');
      emit(const NetworkChecking());

      final connectivityResult = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResult);
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'check connectivity');
      emit(NetworkError(
        message: 'Failed to check connectivity: ${e.toString()}',
        errorType: determineErrorType(e),
      ));
    }
  }

  /// Retry connectivity check after error
  Future<void> retryConnectivity() async {
    logInfo('Retrying connectivity check');
    await checkConnectivity();
  }

  /// Get current connection status
  bool get isConnected => state is NetworkConnected;

  /// Get current connection type
  NetworkConnectionType? get connectionType {
    final currentState = state;
    if (currentState is NetworkConnected) {
      return currentState.connectionType;
    }
    return null;
  }

  /// Check if connection is suitable for heavy operations (downloads, etc.)
  bool get isSuitableForHeavyOperations {
    final currentState = state;
    if (currentState is NetworkConnected) {
      return currentState.connectionType == NetworkConnectionType.wifi ||
          currentState.connectionType == NetworkConnectionType.ethernet;
    }
    return false;
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
