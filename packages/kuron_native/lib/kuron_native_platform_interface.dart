import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';

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

  /// Get System Info (RAM, Storage, Battery)
  Future<Map<Object?, Object?>?> getSystemInfo(String type) {
    throw UnimplementedError('getSystemInfo() has not been implemented.');
  }

  /// Pick local directory with native picker
  Future<String?> pickDirectory() {
    throw UnimplementedError('pickDirectory() has not been implemented.');
  }

  /// Pick a text file and return its content.
  ///
  /// [mimeType] defaults can be provided by caller, e.g. `application/json`.
  Future<String?> pickTextFile({String? mimeType}) {
    throw UnimplementedError('pickTextFile() has not been implemented.');
  }

  /// Pick a binary file and return raw bytes.
  Future<Uint8List?> pickBinaryFile({String? mimeType}) {
    throw UnimplementedError('pickBinaryFile() has not been implemented.');
  }

  /// Pick a ZIP file using native file picker and return content URI.
  Future<String?> pickZipFile() {
    throw UnimplementedError('pickZipFile() has not been implemented.');
  }

  /// Read ZIP file bytes from content URI.
  Future<Uint8List?> readZipBytes(String contentUri) {
    throw UnimplementedError('readZipBytes() has not been implemented.');
  }

  /// Extract ZIP file natively to destination directory with progress notifications.
  /// Returns a map with 'success', 'imageCount', and 'destinationPath'.
  Future<Map<String, dynamic>?> extractZipFile({
    required String contentUri,
    required String destinationPath,
    Function(int processed, int total, int imageCount, String currentFile)?
    onProgress,
  }) {
    throw UnimplementedError('extractZipFile() has not been implemented.');
  }

  /// Start a system download
  Future<String?> startDownload({
    required String url,
    required String fileName,
    String? destinationDir, // Optional: Subdirectory in Downloads
    String? savePath, // Optional: Absolute path
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

  /// Prepare/generate a thumbnail for an animated WebP while optionally
  /// reporting byte-level download progress from the native side.
  Future<Object?> getThumbnailForWebP({
    required String url,
    String? filePath,
    Map<String, String> headers = const {},
    Function(int receivedBytes, int? totalBytes)? onProgress,
  }) {
    throw UnimplementedError('getThumbnailForWebP() has not been implemented.');
  }

  /// Open a PDF file in a native reader/viewer
  Future<void> openPdf({
    required String filePath,
    String? title,
    int? startPage,
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
  // ignore: unintended_html_in_doc_comment
  /// Returns a Map with 'cookies' (List<String>), 'userAgent' (String),
  /// optional DOM-derived fields like `currentUrl` / `resolvedImageUrl`,
  /// and 'success' (bool).
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
    String? autoCloseOnCookie,
    String? ssoRedirectUrl, // NEW
    List<String>? domImageSelectors,
    List<String>? domImageAttributes,
    List<String>? domLinkSelectors,
    bool enableAdBlock = false, // NEW
    bool clearCookies = false,
  }) {
    throw UnimplementedError('showLoginWebView() has not been implemented.');
  }

  /// Open a native WebView Activity for CAPTCHA solving and return token.
  ///
  /// Returns a Map with:
  /// - `success` (bool)
  /// - `token` (String?)
  /// - `errorCode` (String?)
  /// - `errorMessage` (String?)
  Future<Map<String, dynamic>?> showCaptchaWebView({
    required String provider,
    required String siteKey,
    String? baseUrl,
  }) {
    throw UnimplementedError('showCaptchaWebView() has not been implemented.');
  }
}
