import '../webview_session/webview_session_adapter.dart';

/// E-Hentai specific session adapter that extends the shared WebView flow.
class EHentaiSessionAdapter extends WebViewSessionAdapter {
  final String primaryBaseUrl;
  final bool useExhentai;
  final String exBaseUrl;

  EHentaiSessionAdapter({
    required super.dio,
    required super.cookieJar,
    required super.config,
    required super.baseUrl,
    this.primaryBaseUrl = 'https://e-hentai.org',
    this.useExhentai = false,
    this.exBaseUrl = 'https://exhentai.org',
    super.secureStorage,
    super.logger,
  });

  String get effectiveBaseUrl => useExhentai ? exBaseUrl : primaryBaseUrl;

  /// ExHentai access is only considered active when igneous exists and is not
  /// the "mystery" placeholder value.
  Future<bool> hasIgneousCookie() async {
    final cookies = await getCookiesForDomain(effectiveBaseUrl);
    final igneous = cookies['igneous'];
    return igneous != null && igneous.isNotEmpty && igneous != 'mystery';
  }

  /// Tries to trigger the `nw=1` cookie set flow for content warning bypass.
  Future<void> setContentWarningBypass() async {
    await requestWithBypass('$effectiveBaseUrl/?nw=session');
  }
}
