
import 'kuron_native_platform_interface.dart';

class KuronNative {
  /// Singleton instance
  static final KuronNative instance = KuronNative();
  
  Future<String?> getPlatformVersion() {
    return KuronNativePlatform.instance.getPlatformVersion();
  }

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
    return KuronNativePlatform.instance.startDownload(
      url: url,
      fileName: fileName,
      destinationDir: destinationDir,
      title: title,
      description: description,
      mimeType: mimeType,
      cookie: cookie,
      userAgent: userAgent,
    );
  }

  Future<Map<String, dynamic>?> convertImagesToPdf({
    required List<String> imagePaths,
    required String outputPath,
    Function(int progress, String message)? onProgress,
  }) {
    return KuronNativePlatform.instance.convertImagesToPdf(
      imagePaths: imagePaths,
      outputPath: outputPath,
      onProgress: onProgress,
    );
  }

  Future<void> openWebView({
    required String url,
    bool enableJavaScript = true,
  }) {
    return KuronNativePlatform.instance.openWebView(
      url: url,
      enableJavaScript: enableJavaScript,
    );
  }

  /// Clears all cookies from the native WebView storage.
  /// Useful for logout.
  Future<void> clearCookies() {
    return KuronNativePlatform.instance.clearCookies();
  }

  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
    String? autoCloseOnCookie,
    bool clearCookies = false,
  }) {
    return KuronNativePlatform.instance.showLoginWebView(
        url: url,
        successUrlFilters: successUrlFilters,
        initialCookie: initialCookie,
        userAgent: userAgent,
        autoCloseOnCookie: autoCloseOnCookie,
        clearCookies: clearCookies);
  }

  Future<void> openPdf({
    required String filePath,
    String? title,
  }) {
    return KuronNativePlatform.instance.openPdf(
      filePath: filePath,
      title: title,
    );
  }
}
