import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/kuron_native.dart';

void main() {
  group('AnimatedWebPView.shouldAutoPlayForTesting', () {
    test('falls back to autoPlay when there is no visible-page context', () {
      expect(AnimatedWebPView.shouldAutoPlayForTesting(autoPlay: true), isTrue);

      expect(
        AnimatedWebPView.shouldAutoPlayForTesting(autoPlay: false),
        isFalse,
      );
    });

    test(
      'plays only for the currently visible page when notifier is present',
      () {
        expect(
          AnimatedWebPView.shouldAutoPlayForTesting(
            autoPlay: false,
            pageNumber: 4,
            visiblePageNumber: 4,
          ),
          isTrue,
        );

        expect(
          AnimatedWebPView.shouldAutoPlayForTesting(
            autoPlay: false,
            pageNumber: 4,
            visiblePageNumber: 3,
          ),
          isFalse,
        );
      },
    );

    test('does not stay playing after the page scrolls off-screen', () {
      expect(
        AnimatedWebPView.shouldAutoPlayForTesting(
          autoPlay: true,
          pageNumber: 2,
          visiblePageNumber: 1,
        ),
        isFalse,
      );
    });
  });
}
