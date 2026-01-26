import 'dart:async';
import 'dart:io' as io;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:native_dio_adapter/native_dio_adapter.dart' hide URLRequest; // Removed
import 'package:logger/logger.dart';

/// Cloudflare bypass menggunakan visible InAppWebView dialog
///
/// Menampilkan dialog WebView agar user bisa menyelesaikan Cloudflare challenge.
/// Extract cookies dan inject ke Dio HTTP client.
class CrotpediaCloudflareBypass {
  CrotpediaCloudflareBypass({
    required Dio httpClient,
    required GlobalKey<NavigatorState> navigatorKey,
    Logger? logger,
  })  : _httpClient = httpClient,
        _navigatorKey = navigatorKey,
        _logger = logger ?? Logger();

  final Dio _httpClient;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Logger _logger;
  bool _isRunning = false;
  
  // Store the HTML content from the successful bypass
  String? _lastBypassedHtml;
  String? get lastBypassedHtml => _lastBypassedHtml;

  static const String baseUrl = 'https://crotpedia.net';

  // Dynamic User-Agent fetched from device
  String? _userAgent;

  /// Attempt bypass dengan visible WebView dialog
  Future<bool> attemptBypass({String? targetUrl}) async {
    if (_isRunning) {
      _logger.w('Bypass sudah berjalan');
      return false;
    }

    final context = _navigatorKey.currentContext;
    if (context == null) {
      _logger.e('❌ Context tidak tersedia - app belum siap');
      return false;
    }

    _isRunning = true;

    try {
      if (_userAgent == null) {
        _userAgent = await InAppWebViewController.getDefaultUserAgent();
        _logger.i('📱 Device User-Agent: $_userAgent');
      }

      final urlToLoad = targetUrl ?? baseUrl;
      _logger.i('🚀 Memulai Cloudflare bypass untuk: $urlToLoad');

      final stopwatch = Stopwatch()..start();
      
      if (!context.mounted) return false;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _CloudflareBypassDialog(
          baseUrl: urlToLoad,
          logger: _logger,
          userAgent: _userAgent!,
          onSuccess: (cookies, hints, html) async {
            _lastBypassedHtml = html;
            
            final cookieHeader =
                cookies.map((c) => '${c.name}=${c.value}').join('; ');

            _logger.i('🍪 cookies extracted: ${cookies.length}');
            if (hints.isNotEmpty) {
               _logger.i('🕵️ Client Hints extracted: ${hints.keys.join(", ")}');
            }

            _applyIdentityToClient(_httpClient, cookieHeader, _userAgent!, hints);

            _verifyCookies(cookieHeader, _userAgent!, hints).then((verified) {
               if (verified) {
                 _logger.i('✅ Dio verification passed');
               } else {
                 _logger.w('⚠️ Dio verification failed - but we have HTML fallback');
               }
            });

            stopwatch.stop();
            _logger.i(
                  '🎉 Bypass berhasil dalam ${stopwatch.elapsed.inSeconds}s');
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop(true);
          },
        ),
      );

      return result ?? false;
    } catch (e, stackTrace) {
      _logger.e('❌ Bypass error: $e', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      _isRunning = false;
    }
  }

  /// Attempt Auto Login via WebView
  Future<List<io.Cookie>?> attemptLogin({
    required String email, 
    required String password
  }) async {
     if (_isRunning) return null;
     
     final context = _navigatorKey.currentContext;
     if (context == null) return null;
     
     _isRunning = true;
     
     try {
       _userAgent ??= await InAppWebViewController.getDefaultUserAgent();
       
       if (!context.mounted) return null;
       
       final result = await showDialog<List<Cookie>>(
         context: context,
         barrierDismissible: false,
         builder: (ctx) => _CloudflareLoginDialog(
            logger: _logger,
            userAgent: _userAgent!,
            email: email,
            password: password,
            onSuccess: (cookies) {
              Navigator.of(ctx).pop(cookies);
            },
         ),
       );
       
       if (result != null) {
         return result.map((c) => io.Cookie(c.name, c.value)
           ..domain = c.domain
           ..path = c.path
           ..secure = c.isSecure ?? false
           ..httpOnly = c.isHttpOnly ?? false
         ).toList();
       }
       
       return null;
     } catch (e) {
       _logger.e('Login bypass failed: $e');
       return null;
     } finally {
       _isRunning = false;
     }
  }
  
  void _applyIdentityToClient(Dio client, String cookie, String ua, Map<String, String> hints) {
    client.options.headers['cookie'] = cookie;
    client.options.headers['user-agent'] = ua;
    
    if (hints.isNotEmpty) {
      client.options.headers.addAll(hints);
    }
  }

  Future<bool> _verifyCookies(String cookieHeader, String userAgent, Map<String, String> hints) async {
    try {
      final testDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ));

      _applyIdentityToClient(testDio, cookieHeader, userAgent, hints);

      final response = await testDio.get(baseUrl);

      final html = response.data.toString();
      if (_isCloudflareChallenge(html)) {
        _logger.w('⚠️ Cookies tidak valid, masih ada challenge');
        return false;
      }

      _logger.i('✅ Cookies terverifikasi, status: ${response.statusCode}');
      return true;
    } catch (e, stack) {
      _logger.e('Verifikasi cookie gagal: $e', error: e, stackTrace: stack);
      return false;
    }
  }
  
  String? get currentUserAgent => _userAgent;

  bool _isCloudflareChallenge(String html) {
    final indicators = [
      'Checking your browser before accessing',
      'DDoS protection by Cloudflare',
      'cf-challenge-form',
      'challenge-platform',
      '__cf_chl_',
      'Cloudflare Ray ID',
    ];

    final lowerHtml = html.toLowerCase();
    return indicators.any((i) => lowerHtml.contains(i.toLowerCase()));
  }

  Future<void> clearCookies() async {
    _httpClient.options.headers.remove('cookie');
    await CookieManager.instance().deleteCookies(url: WebUri(baseUrl));
    _logger.i('🧹 Cookies dibersihkan');
  }

  Future<bool> areCookiesValid() async {
    final cookie = _httpClient.options.headers['cookie'];
    if (cookie == null || cookie.isEmpty) return false;

    try {
      final response = await _httpClient.get(
        baseUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return !_isCloudflareChallenge(response.data.toString());
    } catch (e) {
      return false;
    }
  }
}

class _CloudflareBypassDialog extends StatefulWidget {
  const _CloudflareBypassDialog({
    required this.baseUrl,
    required this.logger,
    required this.onSuccess,
    required this.userAgent,
  });

  final String baseUrl;
  final Logger logger;
  final Function(List<Cookie>, Map<String, String>, String?) onSuccess;
  final String userAgent;

  @override
  State<_CloudflareBypassDialog> createState() =>
      _CloudflareBypassDialogState();
}

class _CloudflareBypassDialogState extends State<_CloudflareBypassDialog> {
  double _progress = 0.0;
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloudflare Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Checking browser security...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_isVerifying)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.orange),
                    ),
                  ),
              ],
            ),
          ),

          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation(Colors.orange),
            ),

          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.baseUrl)),
              initialSettings: InAppWebViewSettings( 
                javaScriptEnabled: true,
                userAgent: widget.userAgent, 
                cacheEnabled: true,
                clearCache: false,
                useHybridComposition: true,
                domStorageEnabled: true, 
              ),
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onLoadStop: (controller, url) async {
                widget.logger.d('Loading selesai: $url');

                final html = await controller.getHtml();
                if (html != null) {
                  final isCrotpediaPage = _isCrotpediaPage(html);
                  final hasChallenge = _isCloudflareChallenge(html);

                  widget.logger.d(
                      'isCrotpediaPage: $isCrotpediaPage, hasChallenge: $hasChallenge');

                  if (isCrotpediaPage && !hasChallenge) {
                    widget.logger.i('✅ Challenge berhasil diselesaikan!');

                    setState(() {
                      _isVerifying = true;
                    });

                    await _extractData(controller, url, html);
                  }
                }
              },
            ),
          ),

          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please wait while we verify your session.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCloudflareChallenge(String html) {
    final indicators = [
      'Checking your browser before accessing',
      'cf-challenge-form',
      'challenge-platform',
      '__cf_chl_',
    ];

    final lowerHtml = html.toLowerCase();
    return indicators.any((i) => lowerHtml.contains(i.toLowerCase()));
  }

  bool _isCrotpediaPage(String html) {
    final indicators = [
      'crotpedia',
      'doujinshi',
      'hentai manga',
      'genre',
      'latest update',
    ];

    final lowerHtml = html.toLowerCase();
    final matchCount = indicators.where((i) => lowerHtml.contains(i)).length;
    return matchCount >= 2;
  }

  Future<void> _extractData(InAppWebViewController controller, WebUri? url, String? html) async {
    try {
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(
        url: url ?? WebUri(widget.baseUrl),
      );

      if (cookies.isEmpty) {
        widget.logger.w('Cookies tidak ditemukan');
        return;
      }
      
      final hints = <String, String>{};
      try {
        final jsResult = await controller.evaluateJavascript(source: """
          (async function() {
            if (navigator.userAgentData) {
              const result = {
                mobile: navigator.userAgentData.mobile,
                brands: navigator.userAgentData.brands,
                platform: navigator.userAgentData.platform
              };
              
              try {
                 const highEntropy = await navigator.userAgentData.getHighEntropyValues([
                    'architecture', 
                    'bitness', 
                    'model', 
                    'platformVersion',
                    'fullVersionList'
                 ]);
                 Object.assign(result, highEntropy);
              } catch(e) {}
              
              return JSON.stringify(result);
            }
            return "{}";
          })();
        """);
        
        if (jsResult != null && jsResult is String) {
          final data = jsonDecode(jsResult) as Map<String, dynamic>;
          if (data.isNotEmpty) {
             if (data['fullVersionList'] != null) {
                final list = data['fullVersionList'] as List;
                final headerVal = list.map((e) => '"${e['brand']}?v=${e['version']}"').join(', ');
                hints['sec-ch-ua-full-version-list'] = headerVal;
             }
             if (data['brands'] != null) {
               final list = data['brands'] as List;
               final headerVal = list.map((e) => '"${e['brand']}";v="${e['version']}"').join(', ');
               hints['sec-ch-ua'] = headerVal;
             }
             if (data['mobile'] != null) hints['sec-ch-ua-mobile'] = data['mobile'] == true ? '?1' : '?0';
             if (data['platform'] != null) hints['sec-ch-ua-platform'] = '"${data['platform']}"';
             if (data['model'] != null) hints['sec-ch-ua-model'] = '"${data['model']}"';
             if (data['architecture'] != null) hints['sec-ch-ua-arch'] = '"${data['architecture']}"';
             if (data['bitness'] != null) hints['sec-ch-ua-bitness'] = '"${data['bitness']}"';
             if (data['platformVersion'] != null) hints['sec-ch-ua-platform-version'] = '"${data['platformVersion']}"';
          }
        }
      } catch (e) {
        // 
      }
      
      widget.onSuccess(cookies, hints, html);
    } catch (e) {
      widget.logger.e('Gagal extract cookies: $e');
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }
}

class _CloudflareLoginDialog extends StatefulWidget {
  const _CloudflareLoginDialog({
    required this.logger,
    required this.userAgent,
    required this.email,
    required this.password,
    required this.onSuccess,
  });
  
  final Logger logger;
  final String userAgent;
  final String email;
  final String password;
  final Function(List<Cookie>) onSuccess;

  @override
  State<_CloudflareLoginDialog> createState() => _CloudflareLoginDialogState();
}

class _CloudflareLoginDialogState extends State<_CloudflareLoginDialog> {
  double _progress = 0.0;
  bool _isAutoFilling = false;
  String _status = 'Loading login page...';
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
       backgroundColor: Colors.black,
       child: Column(
         children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[900],
               child: Row(
               children: [
                 const Icon(Icons.login, color: Colors.blueAccent),
                 const SizedBox(width: 12),
                 Expanded(child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Secure Auto-Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                   ],
                 )),
                 if (_isAutoFilling) const CircularProgressIndicator(color: Colors.blueAccent)
               ],
             ),
            ),
            if (_progress < 1.0)
               LinearProgressIndicator(value: _progress, color: Colors.blueAccent, backgroundColor: Colors.grey[800]),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri('https://crotpedia.net/login/')),
                initialSettings: InAppWebViewSettings(
                   userAgent: widget.userAgent,
                   javaScriptEnabled: true,
                ),
                onProgressChanged: (_, p) => setState(() => _progress = p / 100),
                onLoadStop: (controller, url) async {
                  widget.logger.d("Login WebView Load: $url");
                  
                  // Check if we are home or dashboard (success!)
                  final urlStr = url.toString();
                  if (urlStr == 'https://crotpedia.net/' || urlStr.contains('/wp-admin') || urlStr.contains('dev.crotpedia.net')) {
                     setState(() {
                       _status = 'Login Success! Extracting session...';
                     });
                     
                     // Helper extraction
                     final cookieManager = CookieManager.instance();
                     final cookies = await cookieManager.getCookies(url: url!);
                     widget.onSuccess(cookies);
                     return;
                  }
                  
                  // If on login page, inject credentials
                  if (urlStr.contains('/login') || urlStr.contains('wp-login')) {
                     setState(() {
                       _status = 'Auto-filling credentials...';
                       _isAutoFilling = true;
                     });

                     // Inject JS with robust retry logic
                     await controller.evaluateJavascript(source: """
                        (function() {
                            var attempts = 0;
                            var maxAttempts = 10;
                            
                            var tryAutoFill = function() {
                                attempts++;
                                
                                // Priority 1: Crotpedia specific fields
                                // Priority 2: Standard WP fields
                                var userField = document.querySelector('input[name="koi_user_login"]') || 
                                                document.getElementById('user_login') || 
                                                document.querySelector('input[name="log"]');
                                                
                                var passField = document.querySelector('input[name="koi_user_pass"]') || 
                                                document.getElementById('user_pass') || 
                                                document.querySelector('input[name="pwd"]');
                                                
                                var submitBtn = document.querySelector('input[name="wp-submit"]') || 
                                                document.getElementById('wp-submit') || 
                                                document.querySelector('input[type="submit"]') ||
                                                document.querySelector('button[type="submit"]');
                                
                                if (userField && passField) {
                                   userField.value = "${widget.email}";
                                   passField.value = "${widget.password}";
                                   
                                   // Dispatch input events
                                   userField.dispatchEvent(new Event('input', { bubbles: true }));
                                   userField.dispatchEvent(new Event('change', { bubbles: true }));
                                   passField.dispatchEvent(new Event('input', { bubbles: true }));
                                   passField.dispatchEvent(new Event('change', { bubbles: true }));
                                   
                                   if (submitBtn) {
                                      submitBtn.click();
                                   } else {
                                      // Fallback: try to submit the form directly
                                      var form = userField.closest('form');
                                      if (form) form.submit();
                                   }
                                   
                                   return true; // Success
                                }
                                
                                if (attempts < maxAttempts) {
                                   setTimeout(tryAutoFill, 500); // Retry every 500ms
                                }
                            };
                            
                            tryAutoFill();
                        })();
                     """);
                  }
                },
              ),
            ),
         ],
       ),
    );
  }
}
