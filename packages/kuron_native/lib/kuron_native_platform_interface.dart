import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kuron_native_method_channel.dart';

abstract class KuronNativePlatform extends PlatformInterface {
  /// Constructs a KuronNativePlatform.
  KuronNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static KuronNativePlatform _instance = MethodChannelKuronNative();

  /// The default instance of [KuronNativePlatform] to use.
  ///
  /// Defaults to [MethodChannelKuronNative].
  static KuronNativePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KuronNativePlatform] when
  /// they register themselves.
  static set instance(KuronNativePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Start a system download
  Future<String?> startDownload({
    required String url,
    required String fileName,
    String? destinationDir, // Optional: Subdirectory in Downloads
    String? title,
    String? description,
    String? mimeType,
    String? cookie,
    String? userAgent,
  }) {
    throw UnimplementedError('startDownload() has not been implemented.');
  }

  /// Convert a list of images to a PDF file natively
  Future<Map<String, dynamic>?> convertImagesToPdf({
    required List<String> imagePaths,
    required String outputPath,
    Function(int progress, String message)? onProgress,
  }) {
    throw UnimplementedError('convertImagesToPdf() has not been implemented.');
  }

  /// Open a URL in a native WebView (Custom Tabs on Android)
  Future<void> openWebView({
    required String url,
    bool enableJavaScript = true,
  }) {
    throw UnimplementedError('openWebView() has not been implemented.');
  }

  /// Clears all cookies from the native WebView.
  Future<void> clearCookies() {
    throw UnimplementedError('clearCookies() has not been implemented.');
  }

  /// Open a PDF file in a native reader/viewer
  Future<void> openPdf({
    required String filePath,
    String? title,
  }) {
    throw UnimplementedError('openPdf() has not been implemented.');
  }
  /// Open a native WebView Activity for login/verification
  ///
  /// [url] The initial URL to load.
  /// [successUrlFilters] List of URL substrings that indicate success.
  /// [initialCookie] Optional initial cookie string to sync session.
  /// [userAgent] Optional user agent string.
  ///
  /// Returns a Map with 'cookies' (List<String>), 'userAgent' (String), and 'success' (bool).
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
  }) {
    throw UnimplementedError('showLoginWebView() has not been implemented.');
  }
}
