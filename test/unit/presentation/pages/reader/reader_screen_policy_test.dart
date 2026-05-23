import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/presentation/pages/reader/reader_screen.dart';

void main() {
  group('ReaderScreen heavy-image auto-switch policy', () {
    test('skips auto-switch for manga18 source', () {
      expect(
        ReaderScreen.shouldSkipHeavyImageAutoSwitchForSource('manga18.club'),
        isTrue,
      );
      expect(
        ReaderScreen.shouldSkipHeavyImageAutoSwitchForSource('MANGA18.CLUB'),
        isTrue,
      );
    });

    test('keeps auto-switch enabled for other sources', () {
      expect(
        ReaderScreen.shouldSkipHeavyImageAutoSwitchForSource('ehentai'),
        isFalse,
      );
      expect(
        ReaderScreen.shouldSkipHeavyImageAutoSwitchForSource(''),
        isFalse,
      );
      expect(
        ReaderScreen.shouldSkipHeavyImageAutoSwitchForSource(null),
        isFalse,
      );
    });
  });
}
