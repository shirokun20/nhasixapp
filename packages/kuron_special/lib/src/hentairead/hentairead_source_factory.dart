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
      preferCapturedImageUrls: isReaderPage,
      captureRequestPatterns: isReaderPage ? ['$captureHost/'] : null,
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
      skipInitialRequest: isReaderPage,
    );
  }

  static String? _registrableDomainOf(String url) =>
      registrableDomain(Uri.parse(url));

  @override
  String get sourceId => _delegate.sourceId;

  @override
  ContentSource create(Map<String, dynamic> config) => _delegate.create(config);
}
