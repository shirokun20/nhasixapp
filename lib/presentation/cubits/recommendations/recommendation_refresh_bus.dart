import 'dart:async';

import 'package:nhasixapp/core/di/service_locator.dart';

// Fire-and-forget refresh signal for recommendation sections.
// Producers (reader completion, favorite toggle, download completion,
// dismiss) never await and never fail: a closed/missing bus is a no-op.
// Consumers (RecommendedSection, SimilarContentSection) subscribe and call
// their own cubit's refresh. This keeps trigger sites decoupled from the
// home/detail cubit instances (which are per-screen factories).
class RecommendationRefreshBus {
  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  // Throttle: one signal triggers 2 full recomputes (recommended + similar
  // sections); bursts (fav toggle, 90% crossing, download done) rescanned
  // entire history each time. Max 1 refresh per window; recompute always
  // covers latest state, so dropped intermediate signals are harmless.
  static const _minInterval = Duration(seconds: 3);
  DateTime? _lastEmit;

  void requestRefresh() {
    if (_controller.isClosed) return;
    final now = DateTime.now();
    final last = _lastEmit;
    if (last != null && now.difference(last) < _minInterval) return;
    _lastEmit = now;
    _controller.add(null);
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }

  /// One-line trigger for producers. Never throws: an unregistered bus
  /// (unit tests, partial DI) degrades to a no-op — refresh is best-effort.
  static void requestGlobalRefresh() {
    try {
      getIt<RecommendationRefreshBus>().requestRefresh();
    } catch (_) {
      // Intentionally ignored — see above.
    }
  }
}
