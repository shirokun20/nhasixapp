import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/app_privacy_overlay_service.dart';

void main() {
  group('AppPrivacyOverlayService', () {
    test('starts unobscured', () {
      final service = AppPrivacyOverlayService();

      expect(service.isObscured, isFalse);
      expect(service.lastLifecycleState, isNull);
    });

    test('obscures on inactive and clears on resumed', () {
      final service = AppPrivacyOverlayService();

      service.updateForLifecycleState(AppLifecycleState.inactive);
      expect(service.isObscured, isTrue);
      expect(service.lastLifecycleState, AppLifecycleState.inactive);

      service.updateForLifecycleState(AppLifecycleState.resumed);
      expect(service.isObscured, isFalse);
      expect(service.lastLifecycleState, AppLifecycleState.resumed);
    });

    test('notifies listeners only when visibility changes', () {
      final service = AppPrivacyOverlayService();
      var notifications = 0;
      service.addListener(() {
        notifications += 1;
      });

      service.updateForLifecycleState(AppLifecycleState.inactive);
      service.updateForLifecycleState(AppLifecycleState.paused);
      service.updateForLifecycleState(AppLifecycleState.resumed);
      service.updateForLifecycleState(AppLifecycleState.resumed);

      expect(notifications, 2);
    });
  });
}
