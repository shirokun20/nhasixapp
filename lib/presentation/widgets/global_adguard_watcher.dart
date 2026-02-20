import 'package:flutter/material.dart';
import 'adguard_warning_dialog.dart';

class GlobalAdGuardWatcher extends StatefulWidget {
  final Widget child;

  const GlobalAdGuardWatcher({
    required this.child,
    super.key,
  });

  @override
  State<GlobalAdGuardWatcher> createState() => _GlobalAdGuardWatcherState();
}

class _GlobalAdGuardWatcherState extends State<GlobalAdGuardWatcher>
    with WidgetsBindingObserver {
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAdGuard();
    }
  }

  Future<void> _checkAdGuard() async {
    // Hindari pemanggilan dialog overlap
    if (_isShowingDialog || !mounted) return;

    _isShowingDialog = true;
    await AdGuardWarningDialog.showNonBypassable(context);
    if (mounted) {
      _isShowingDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
