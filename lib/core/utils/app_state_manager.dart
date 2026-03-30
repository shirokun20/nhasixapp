// AppStateManager: Global state manager for offline/online mode.
// Provides a stream to listen for offline mode changes across the app.
// Enhanced with offline content tracking and state management.

import 'dart:async';

/// Global application state manager for handling offline/online modes
/// and other app-wide state management needs.
///
/// This singleton class provides centralized state management for:
/// - Offline/online mode tracking
/// - Network connectivity state
/// - Offline content availability and count
/// - App-wide settings that affect multiple screens
///
/// Usage:
/// ```dart
/// // Enable offline mode
/// AppStateManager().enableOfflineMode();
///
/// // Listen to mode changes
/// AppStateManager().offlineModeStream.listen((isOffline) {
///   print('Offline mode: $isOffline');
/// });
///
/// // Check current state
/// bool isOffline = AppStateManager().isOfflineMode;
/// ```
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  // Private state variables
  bool _isOfflineMode = false;
  bool _hasOfflineContent = false;
  int _offlineContentCount = 0;

  // Stream controllers for reactive updates
  final StreamController<bool> _offlineModeController =
      StreamController<bool>.broadcast();
  final StreamController<OfflineStateUpdate> _offlineStateController =
      StreamController<OfflineStateUpdate>.broadcast();

  // Public getters
  bool get isOfflineMode => _isOfflineMode;
  bool get hasOfflineContent => _hasOfflineContent;
  int get offlineContentCount => _offlineContentCount;

  // Public streams
  Stream<bool> get offlineModeStream => _offlineModeController.stream;
  Stream<OfflineStateUpdate> get offlineStateStream =>
      _offlineStateController.stream;

  /// Set the offline mode state and notify listeners
  ///
  /// [offline] - true to enable offline mode, false for online mode
  void setOfflineMode(bool offline) {
    if (_isOfflineMode != offline) {
      _isOfflineMode = offline;
      _offlineModeController.add(offline);

      // Emit state update with additional context
      _offlineStateController.add(OfflineStateUpdate(
        isOfflineMode: offline,
        hasOfflineContent: _hasOfflineContent,
        offlineContentCount: _offlineContentCount,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Enable offline mode
  void enableOfflineMode() => setOfflineMode(true);

  /// Enable online mode
  void enableOnlineMode() => setOfflineMode(false);

  /// Update offline content information
  ///
  /// [hasContent] - whether offline content is available
  /// [contentCount] - number of offline content items
  void updateOfflineContentInfo({
    required bool hasContent,
    required int contentCount,
  }) {
    _hasOfflineContent = hasContent;
    _offlineContentCount = contentCount;

    // Emit updated state
    _offlineStateController.add(OfflineStateUpdate(
      isOfflineMode: _isOfflineMode,
      hasOfflineContent: hasContent,
      offlineContentCount: contentCount,
      timestamp: DateTime.now(),
    ));
  }

  /// Get current offline state as a snapshot
  OfflineStateUpdate getCurrentState() {
    return OfflineStateUpdate(
      isOfflineMode: _isOfflineMode,
      hasOfflineContent: _hasOfflineContent,
      offlineContentCount: _offlineContentCount,
      timestamp: DateTime.now(),
    );
  }

  /// Reset all state to default values
  void reset() {
    _isOfflineMode = false;
    _hasOfflineContent = false;
    _offlineContentCount = 0;

    _offlineModeController.add(false);
    _offlineStateController.add(OfflineStateUpdate(
      isOfflineMode: false,
      hasOfflineContent: false,
      offlineContentCount: 0,
      timestamp: DateTime.now(),
    ));
  }

  /// Dispose of resources when app is closing
  void dispose() {
    _offlineModeController.close();
    _offlineStateController.close();
  }
}

/// Data class containing complete offline state information
class OfflineStateUpdate {
  const OfflineStateUpdate({
    required this.isOfflineMode,
    required this.hasOfflineContent,
    required this.offlineContentCount,
    required this.timestamp,
  });

  final bool isOfflineMode;
  final bool hasOfflineContent;
  final int offlineContentCount;
  final DateTime timestamp;

  @override
  String toString() {
    return 'OfflineStateUpdate(isOfflineMode: $isOfflineMode, '
        'hasOfflineContent: $hasOfflineContent, '
        'offlineContentCount: $offlineContentCount, '
        'timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineStateUpdate &&
        other.isOfflineMode == isOfflineMode &&
        other.hasOfflineContent == hasOfflineContent &&
        other.offlineContentCount == offlineContentCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      isOfflineMode,
      hasOfflineContent,
      offlineContentCount,
    );
  }
}
