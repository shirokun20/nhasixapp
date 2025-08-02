import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/blocs/splash/splash_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewBsWidget extends StatefulWidget {
  const WebviewBsWidget({super.key});

  @override
  State<WebviewBsWidget> createState() => _WebviewBsWidgetState();
}

class _WebviewBsWidgetState extends State<WebviewBsWidget> {
  late WebViewController _controller;
  final Logger _logger = Logger();
  bool _isProcessing = false;
  String _statusMessage = 'Loading nhentai.net...';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onHttpError: _onHttpError,
          onWebResourceError: _onWebResourceError,
        ),
      )
      ..loadRequest(Uri.parse('https://nhentai.net'));
  }

  void _onPageStarted(String url) {
    if (mounted) {
      setState(() {
        _statusMessage = 'Loading $url...';
      });
    }
    _logger.d('WebView: Page started loading: $url');
  }

  void _onPageFinished(String url) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _logger.d('WebView: Page finished loading: $url');

      if (mounted) {
        setState(() {
          _statusMessage = 'Checking Cloudflare status...';
        });
      }

      // Wait a bit for JavaScript to execute
      await Future.delayed(const Duration(seconds: 2));

      bool isSuccess = false;

      // Check if the URL contains nhentai.net and Cloudflare is bypassed
      if (url.contains('nhentai.net') && await _isCloudflareBypassed()) {
        isSuccess = true;
        if (mounted) {
          setState(() {
            _statusMessage = 'Successfully bypassed Cloudflare!';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = 'Still processing Cloudflare challenge...';
          });
        }

        // If not successful, wait and try again
        await Future.delayed(const Duration(seconds: 3));
        if (mounted && await _isCloudflareBypassed()) {
          isSuccess = true;
          if (mounted) {
            setState(() {
              _statusMessage = 'Successfully bypassed Cloudflare!';
            });
          }
        }
      }

      // Send result to BLoC after a short delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        _logger.i('WebView: Cloudflare bypass result: $isSuccess');
        context.read<SplashBloc>().add(
              SplashCFBypassEvent(status: isSuccess ? "success" : "error"),
            );
        context.pop();
      }
    } catch (e) {
      _logger.e('WebView: Error in page finished handler: $e');
      if (mounted) {
        context.read<SplashBloc>().add(SplashCFBypassEvent(status: "error"));
        context.pop();
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _onHttpError(HttpResponseError error) {
    _logger.w('WebView: HTTP error: ${error.response?.statusCode}');

    if (mounted) {
      setState(() {
        _statusMessage = 'HTTP error occurred, retrying...';
      });
    }

    // Don't immediately fail on HTTP errors, they might be temporary
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isProcessing) {
        context.read<SplashBloc>().add(SplashCFBypassEvent(status: "error"));
        context.pop();
      }
    });
  }

  void _onWebResourceError(WebResourceError error) {
    _logger.w('WebView: Resource error: ${error.description}');
    // Don't fail immediately on resource errors, they might be temporary
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: ColorsConst.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: ColorsConst.primaryTextColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ColorsConst.primaryTextColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // Status text
                Text(
                  'Bypassing Cloudflare Protection',
                  style: TextStyleConst.styleBold(
                    size: 18,
                    textColor: ColorsConst.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Dynamic status message
                Text(
                  _statusMessage,
                  style: TextStyleConst.styleRegular(
                    size: 14,
                    textColor:
                        ColorsConst.primaryTextColor.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Progress indicator
                LinearProgressIndicator(
                  backgroundColor:
                      ColorsConst.primaryTextColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsConst.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // WebView
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: WebViewWidget(
                controller: _controller,
              ),
            ),
          ),

          // Footer with info
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: ColorsConst.primaryTextColor.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: ColorsConst.primaryTextColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This process may take up to 2 minutes. Please be patient.',
                    style: TextStyleConst.styleRegular(
                      size: 12,
                      textColor:
                          ColorsConst.primaryTextColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if Cloudflare is bypassed by examining cookies and page content
  Future<bool> _isCloudflareBypassed() async {
    try {
      // Check cookies first
      final cookies =
          await _controller.runJavaScriptReturningResult('document.cookie;');
      final cookieString = cookies.toString();

      // Look for Cloudflare clearance cookie
      if (cookieString.contains('cf_clearance')) {
        _logger.d('WebView: Found cf_clearance cookie');
        return true;
      }

      // Look for nhentai-specific cookies
      if (cookieString.contains('csrftoken') ||
          cookieString.contains('sessionid')) {
        _logger.d('WebView: Found nhentai session cookies');
        return true;
      }

      // Check page content for nhentai-specific elements
      final pageContent = await _controller
          .runJavaScriptReturningResult('document.documentElement.outerHTML');
      final htmlContent = pageContent.toString().toLowerCase();

      // Check if we're still on a Cloudflare challenge page
      final cloudflareIndicators = [
        'checking your browser',
        'ddos protection by cloudflare',
        'cf-browser-verification',
        'cf-challenge-form',
        'ray-id',
      ];

      for (final indicator in cloudflareIndicators) {
        if (htmlContent.contains(indicator)) {
          _logger.d('WebView: Still on Cloudflare challenge page');
          return false;
        }
      }

      // Check for nhentai-specific content
      final nhentaiIndicators = [
        'nhentai',
        'doujinshi',
        'manga',
        'popular',
        'search',
      ];

      for (final indicator in nhentaiIndicators) {
        if (htmlContent.contains(indicator)) {
          _logger.d('WebView: Found nhentai content, bypass successful');
          return true;
        }
      }

      _logger.d('WebView: No clear indication of bypass success');
      return false;
    } catch (e) {
      _logger.w('WebView: Error checking bypass status: $e');
      return false;
    }
  }
}
