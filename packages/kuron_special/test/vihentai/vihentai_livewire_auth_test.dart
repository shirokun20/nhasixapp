import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/src/vihentai/vihentai_livewire_auth.dart';

void main() {
  group('ViHentaiLivewireAuth', () {
    test('needsPassword returns true when gate present', () {
      final html = '<div wire:initial-data="{}">enter-secret form</div>';
      expect(ViHentaiLivewireAuth.needsPassword(html), isTrue);
    });

    test('needsPassword returns false when no gate', () {
      final html = '<div>normal content</div>';
      expect(ViHentaiLivewireAuth.needsPassword(html), isFalse);
    });

    test('needsPassword returns false when only one signal present', () {
      final html1 = '<div wire:initial-data="{}">no secret here</div>';
      expect(ViHentaiLivewireAuth.needsPassword(html1), isFalse);

      final html2 = '<div>enter-secret without wire data</div>';
      expect(ViHentaiLivewireAuth.needsPassword(html2), isFalse);
    });

    test('extractAuthData extracts password, csrf token, wire data', () {
      final html = '''
        <html>
        <head><meta name="action_token" content="abc123token"></head>
        <body>
          <div wire:id="wire123" wire:initial-data="&quot;{\\&quot;fingerprint\\&quot;:{\\&quot;id\\&quot;:\\&quot;abc\\&quot;},\\&quot;serverMemo\\&quot;:{}}&quot;">
            <input type="password" required>
            <script>input.value = 'lothanhchiton'</script>
          </div>
        </body>
        </html>
      ''';

      final authData = ViHentaiLivewireAuth.extractAuthData(html);
      expect(authData.password, 'lothanhchiton');
      expect(authData.csrfToken, 'abc123token');
      expect(authData.wireId, 'wire123');
      expect(authData.wireInitialDataJson, isNotEmpty);
    });

    test('extractAuthData throws ViHentaiPasswordNotFoundException when no password', () {
      final html = '''
        <html>
        <div wire:id="w1" wire:initial-data="{}">enter-secret</div>
        </html>
      ''';

      expect(
        () => ViHentaiLivewireAuth.extractAuthData(html),
        throwsA(isA<ViHentaiPasswordNotFoundException>()),
      );
    });

    test('extractAuthData extracts csrf from window.livewire_token', () {
      final html = '''
        <html>
        <script>window.livewire_token = 'tokensecret123';</script>
        <div wire:id="w1" wire:initial-data="{}">
          enter-secret
        </div>
        <script>input.value = 'lothanhchiton'</script>
        </html>
      ''';

      final authData = ViHentaiLivewireAuth.extractAuthData(html);
      expect(authData.csrfToken, 'tokensecret123');
    });

    test('extractAuthData reads wire:initial-data in reversed attr order', () {
      final html = '''
        <html>
        <div wire:initial-data="&quot;{\\&quot;fingerprint\\&quot;:{\\&quot;id\\&quot;:\\&quot;rev\\&quot;}}&quot;" wire:id="revWire">
          enter-secret
        </div>
        <script>input.value = 'lothanhchiton'</script>
        </html>
      ''';

      final authData = ViHentaiLivewireAuth.extractAuthData(html);
      expect(authData.wireId, 'revWire');
      expect(authData.wireInitialDataJson, contains('rev'));
    });

    test('extractAuthData falls back to meta csrf-token', () {
      final html = '''
        <html>
        <head><meta name="csrf-token" content="csrffallback"></head>
        <div wire:id="w1" wire:initial-data="{}">
          enter-secret
        </div>
        <script>input.value = 'mypassword'</script>
        </html>
      ''';

      final authData = ViHentaiLivewireAuth.extractAuthData(html);
      expect(authData.csrfToken, 'csrffallback');
    });
  });
}
