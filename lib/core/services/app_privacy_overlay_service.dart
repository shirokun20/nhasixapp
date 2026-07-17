import 'package:flutter/widgets.dart';

/// Controls a lightweight UI-only privacy overlay used to obscure
/// recent-apps snapshots without interrupting background work.
class AppPrivacyOverlayService extends ChangeNotifier {
  bool _isObscured = false;
  AppLifecycleState? _lastLifecycleState;

  bool get isObscured => _isObscured;
  AppLifecycleState? get lastLifecycleState => _lastLifecycleState;

  void updateForLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;

    switch (state) {
      case AppLifecycleState.resumed:
        clearObscured();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        markBackgroundObscured();
        break;
    }
  }

  @visibleForTesting
  void markBackgroundObscured() {
    _setObscured(true);
  }

  @visibleForTesting
  void clearObscured() {
    _setObscured(false);
  }

  void _setObscured(bool value) {
    if (_isObscured == value) {
      return;
    }

    _isObscured = value;
    notifyListeners();
  }
}
