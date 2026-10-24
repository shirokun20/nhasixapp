import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/user_preferences.dart';

void main() {
  group('UserPreferences.hasSeenReaderKeyboardHint', () {
    test('defaults to false', () {
      expect(UserPreferences().hasSeenReaderKeyboardHint, isFalse);
    });

    test('survives json round-trip', () {
      const prefs = UserPreferences(hasSeenReaderKeyboardHint: true);
      final revived = UserPreferences.fromJson(prefs.toJson());

      expect(revived.hasSeenReaderKeyboardHint, isTrue);
    });

    test('copyWith sets the flag', () {
      const prefs = UserPreferences();

      expect(
        prefs.copyWith(hasSeenReaderKeyboardHint: true)
            .hasSeenReaderKeyboardHint,
        isTrue,
      );
    });
  });
}
