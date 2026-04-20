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

  /// Progress callback for ZIP extraction
  Function(int processed, int total, int imageCount, String currentFile)?
  _onZipExtractionProgress;

  /// Progress callbacks for native animated-WebP thumbnail preparation.
  final Map<String, Function(int receivedBytes, int? totalBytes)>
  _onWebPThumbnailProgress =
      <String, Function(int receivedBytes, int? totalBytes)>{};
  static int _nextWebPThumbnailRequestId = 0;

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
    } else if (call.method == 'onZipExtractionProgress') {
      if (_onZipExtractionProgress != null) {
        try {
          final args = call.arguments as Map;
          final processed = (args['processed'] as num).toInt();
          final total = (args['total'] as num).toInt();
          final imageCount = (args['imageCount'] as num).toInt();
          final currentFile = args['currentFile'] as String;

          _onZipExtractionProgress!(processed, total, imageCount, currentFile);
        } catch (e) {
          // Silently ignore or log if needed
          // print('Error handling onZipExtractionProgress: $e');
        }
      }
    } else if (call.method == 'onWebPThumbnailProgress') {
      try {
        final args = call.arguments as Map;
        final requestId = args['requestId'] as String?;
        if (requestId == null) return;

        final callback = _onWebPThumbnailProgress[requestId];
        if (callback == null) return;

        final receivedBytes = (args['receivedBytes'] as num?)?.toInt() ?? 0;
        final totalRaw = args['totalBytes'];
        final totalBytes = totalRaw is num && totalRaw > 0
            ? totalRaw.toInt()
            : null;

        callback(receivedBytes, totalBytes);
      } catch (e) {
        // Silently ignore or log if needed
        // print('Error handling onWebPThumbnailProgress: $e');
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
  Future<String?> pickTextFile({String? mimeType}) async {
    final content = await methodChannel.invokeMethod<String>('pickTextFile', {
      'mimeType': mimeType,
    });
    return content;
  }

  @override
  Future<Uint8List?> pickBinaryFile({String? mimeType}) async {
    final bytes = await methodChannel.invokeMethod<Uint8List>(
      'pickBinaryFile',
      {'mimeType': mimeType},
    );
    return bytes;
  }

  @override
  Future<String?> pickZipFile() async {
    final uri = await methodChannel.invokeMethod<String>('pickZipFile');
    return uri;
  }

  @override
  Future<Uint8List?> readZipBytes(String contentUri) async {
    final bytes = await methodChannel.invokeMethod<Uint8List>('readZipBytes', {
      'contentUri': contentUri,
    });
    return bytes;
  }

  @override
  Future<Map<String, dynamic>?> extractZipFile({
    required String contentUri,
    required String destinationPath,
    Function(int processed, int total, int imageCount, String currentFile)?
    onProgress,
  }) async {
    _onZipExtractionProgress = onProgress;
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'extractZipFile',
        {'contentUri': contentUri, 'destinationPath': destinationPath},
      );
      return result;
    } finally {
      _onZipExtractionProgress = null;
    }
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
  Future<Object?> getThumbnailForWebP({
    required String url,
    String? filePath,
    Map<String, String> headers = const {},
    Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final requestId =
        'webp_thumb_${DateTime.now().microsecondsSinceEpoch}_${_nextWebPThumbnailRequestId++}';
    final filePathPayload = filePath != null
        ? <String, Object>{'filePath': filePath}
        : null;

    if (onProgress != null) {
      _onWebPThumbnailProgress[requestId] = onProgress;
    }

    try {
      return await methodChannel.invokeMethod<Object>('getThumbnailForWebP', {
        'url': url,
        ...?filePathPayload,
        if (headers.isNotEmpty) 'headers': headers,
        'requestId': requestId,
      });
    } finally {
      _onWebPThumbnailProgress.remove(requestId);
    }
  }

  @override
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
    String? autoCloseOnCookie,
    String? ssoRedirectUrl,
    List<String>? domImageSelectors,
    List<String>? domImageAttributes,
    List<String>? domLinkSelectors,
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
          'domImageSelectors': domImageSelectors,
          'domImageAttributes': domImageAttributes,
          'domLinkSelectors': domLinkSelectors,
          'enableAdBlock': enableAdBlock,
          'clearCookies': clearCookies,
        });
    return result;
  }

  @override
  Future<Map<String, dynamic>?> showCaptchaWebView({
    required String provider,
    required String siteKey,
    String? baseUrl,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'showCaptchaWebView',
      {'provider': provider, 'siteKey': siteKey, 'baseUrl': baseUrl},
    );
    return result;
  }
}
