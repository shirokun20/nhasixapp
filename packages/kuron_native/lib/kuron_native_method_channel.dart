import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kuron_native_platform_interface.dart';

/// An implementation of [KuronNativePlatform] that uses method channels.
class MethodChannelKuronNative extends KuronNativePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kuron_native');

  /// Progress callback for PDF conversion
  Function(int progress, String message)? _onPdfProgress;

  /// Constructor
  MethodChannelKuronNative() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onProgress') {
      if (_onPdfProgress != null) {
        try {
          final args = call.arguments as Map;
          final progress = (args['progress'] as num).toInt();
          final message = args['message'] as String;

          _onPdfProgress!(progress, message);
        } catch (e) {
          // Silently ignore or log if needed
          // print('Error handling onProgress: $e');
        }
      }
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<Map<Object?, Object?>?> getSystemInfo(String type) async {
    final result = await methodChannel.invokeMethod('getSystemInfo', {
      'type': type,
    });
    return result as Map<Object?, Object?>?;
  }

  @override
  Future<String?> pickDirectory() async {
    final path = await methodChannel.invokeMethod<String>('pickDirectory');
    return path;
  }

  @override
  Future<String?> startDownload({
    required String url,
    required String fileName,
    String? destinationDir,
    String? savePath,
    String? title,
    String? description,
    String? mimeType,
    String? cookie,
    String? userAgent,
  }) async {
    final downloadId = await methodChannel
        .invokeMethod<String>('startDownload', {
          'url': url,
          'fileName': fileName,
          'destinationDir': destinationDir,
          'savePath': savePath,
          'title': title,
          'description': description,
          'mimeType': mimeType,
          'cookie': cookie,
          'userAgent': userAgent,
        });
    return downloadId;
  }

  @override
  Future<Map<String, dynamic>?> convertImagesToPdf({
    required List<String> imagePaths,
    required String outputPath,
    Function(int progress, String message)? onProgress,
  }) async {
    _onPdfProgress = onProgress;
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'convertImagesToPdf',
        {'imagePaths': imagePaths, 'outputPath': outputPath},
      );
      return result;
    } finally {
      _onPdfProgress = null;
    }
  }

  @override
  Future<void> openWebView({
    required String url,
    bool enableJavaScript = true,
  }) async {
    await methodChannel.invokeMethod('openWebView', {
      'url': url,
      'enableJavaScript': enableJavaScript,
    });
  }

  @override
  Future<void> openPdf({
    required String filePath,
    String? title,
    int? startPage,
  }) async {
    await methodChannel.invokeMethod('openPdf', {
      'filePath': filePath,
      'title': title,
      'startPage': startPage,
    });
  }

  @override
  Future<void> clearCookies() async {
    await methodChannel.invokeMethod<void>('clearCookies');
  }

  @override
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
    String? autoCloseOnCookie,
    String? ssoRedirectUrl,
    bool enableAdBlock = false,
    bool clearCookies = false,
  }) async {
    final result = await methodChannel
        .invokeMapMethod<String, dynamic>('showLoginWebView', {
          'url': url,
          'successUrlFilters': successUrlFilters,
          'initialCookie': initialCookie,
          'userAgent': userAgent,
          'autoCloseOnCookie': autoCloseOnCookie,
          'ssoRedirectUrl': ssoRedirectUrl,
          'enableAdBlock': enableAdBlock,
          'clearCookies': clearCookies,
        });
    return result;
  }
}
