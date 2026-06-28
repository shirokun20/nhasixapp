import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';

import '../generic_bypass/generic_bypass_source_factory.dart';
import '../webview_session/webview_session_adapter.dart';

class HentaiReadSourceFactory implements SourceFactory {
  HentaiReadSourceFactory({
    required Dio dio,
    required WebViewSessionAdapter sessionAdapter,
    required Logger logger,
  }) : _delegate = GenericBypassSourceFactory(
          sourceId: 'hentairead',
          dio: dio,
          sessionAdapter: sessionAdapter,
          logger: logger,
        );

  final GenericBypassSourceFactory _delegate;

  static WebViewBypassOptions buildBypassOptions(
    String targetUrl,
    WebViewSessionConfig config,
  ) {
    final isReaderPage = targetUrl.contains('/english/p/');
    return WebViewBypassOptions(
      autoCloseOnCookie:
          config.autoCloseOnCookie.isEmpty ? null : config.autoCloseOnCookie,
      preferCapturedHtml: true,
      preferCapturedImageUrls: isReaderPage,
      captureRequestPatterns: isReaderPage ? const ['henread.xyz/'] : null,
      allowRequestPatterns: isReaderPage
          ? const [
              'hentairead.com',
              'henread.xyz',
              'hencover.xyz',
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

  @override
  String get sourceId => _delegate.sourceId;

  @override
  ContentSource create(Map<String, dynamic> config) => _delegate.create(config);
}
