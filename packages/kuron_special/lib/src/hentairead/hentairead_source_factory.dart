import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';

import '../generic_bypass/generic_bypass_source_factory.dart';
import '../webview_session/webview_session_adapter.dart';

/// Bypass factory for sources whose reader pages lazy-load images from a
/// sibling CDN host through blob URLs (HentaiRead, ManhwaRead).
///
/// The WebView capture pass records the CDN image requests
/// (`captureRequestPatterns`) and serves them back without network I/O
/// (`preferCapturedImageUrls`), which is how the CDN's Cloudflare
/// protection is sidestepped for the reader.
class WebViewReaderSourceFactory implements SourceFactory {
  WebViewReaderSourceFactory({
    required String sourceId,
    required Dio dio,
    required WebViewSessionAdapter sessionAdapter,
    required Logger logger,
  }) : _delegate = GenericBypassSourceFactory(
          sourceId: sourceId,
          dio: dio,
          sessionAdapter: sessionAdapter,
          logger: logger,
        );

  final GenericBypassSourceFactory _delegate;

  static WebViewBypassOptions buildBypassOptions(
    String targetUrl,
    WebViewSessionConfig config, {
    required String readerPagePattern,
    required String captureHost,
    required String previewHost,
  }) {
    final isReaderPage = targetUrl.contains(readerPagePattern);
    final registrable = _registrableDomainOf(targetUrl);
    return WebViewBypassOptions(
      autoCloseOnCookie:
          config.autoCloseOnCookie.isEmpty ? null : config.autoCloseOnCookie,
      preferCapturedHtml: true,
      // NOTE: preferCapturedImageUrls deliberately NOT set — WebView closes as
      // soon as the title resolves (jsd oneshot), but reader images are blob
      // lazy-load: CDN requests only fire as the user scrolls, so capture
      // returns only the first ~3 viewport images. The captured HTML contains
      // the chapterData script with ALL image URLs (base64), and
      // chapterDataScript mode extracts them — always prefer HTML.
      // captureRequestPatterns likewise unused for readers. Re-enable capture
      // only if a site's chapterData script ever goes away.
      allowRequestPatterns: isReaderPage && registrable != null
          ? [
              registrable,
              captureHost,
              previewHost,
              'cloudflare.com',
              'challenge-platform',
              '.js',
              '.css',
              '.jpg',
              '.jpeg',
              '.png',
              '.webp',
              'fonts.gstatic',
              'googleapis',
              'gstatic',
            ]
          : null,
      // NOTE: skipInitialRequest deliberately NOT set — HTTP probe first.
      // Sites serve content without CF challenge (verified: both detail and
      // reader pages return 200, CDN open). WebView only launches on 403.
      // Setting skipInitialRequest:true would launch WebView on EVERY reader
      // page load — slow + spammy.
      // Auto-close: CF jsd oneshot challenge (no cf_clearance cookie) finishes
      // when page title changes from "Just a moment..." — poll via
      // pageFinishedScript, close + harvest cookies when title is real.
      pageFinishedScript: '''
        (function() {
          var t = document.title;
          var lower = t.toLowerCase();
          if (lower.indexOf('just a moment') >= 0 ||
              lower.indexOf('attention required') >= 0 ||
              lower.indexOf('checking your browser') >= 0 ||
              lower.indexOf('security check') >= 0 ||
              lower.indexOf('verifying you') >= 0) {
            return '';
          }
          return t;
        })()
      ''',
    );
  }

  static String? _registrableDomainOf(String url) =>
      registrableDomain(Uri.parse(url));

  @override
  String get sourceId => _delegate.sourceId;

  @override
  ContentSource create(Map<String, dynamic> config) => _delegate.create(config);
}
