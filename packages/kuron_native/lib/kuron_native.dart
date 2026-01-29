
import 'kuron_native_platform_interface.dart';


export 'utils/backup_utils.dart'; // Export for users
export 'widgets/kuron_widgets.dart'; // Export Widgets

class KuronNative {
  /// Singleton instance
  static final KuronNative instance = KuronNative();
  
  Future<String?> getPlatformVersion() {
    return KuronNativePlatform.instance.getPlatformVersion();
  }

  /// Get System Info. Types: 'ram', 'storage', 'battery'
  Future<Map<Object?, Object?>?> getSystemInfo(String type) {
    return KuronNativePlatform.instance.getSystemInfo(type);
  }

  /// Pick a directory using the native system picker.
  /// Returns the path if selected, or null if cancelled.
  Future<String?> pickDirectory() {
    return KuronNativePlatform.instance.pickDirectory();
  }

  Future<String?> startDownload({
    required String url,
    required String fileName,
    String? destinationDir, // Optional: Subdirectory in Downloads
    String? savePath,
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
      savePath: savePath,
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
    String? ssoRedirectUrl,
    bool enableAdBlock = false,
    bool clearCookies = false,
  }) {
    return KuronNativePlatform.instance.showLoginWebView(
        url: url,
        successUrlFilters: successUrlFilters,
        initialCookie: initialCookie,
        userAgent: userAgent,
        autoCloseOnCookie: autoCloseOnCookie,
        ssoRedirectUrl: ssoRedirectUrl,
        enableAdBlock: enableAdBlock,
        clearCookies: clearCookies);
  }

  Future<void> openPdf({
    required String filePath,
    String? title,
    int? startPage,
  }) {
    return KuronNativePlatform.instance.openPdf(
      filePath: filePath,
      title: title,
      startPage: startPage,
    );
  }
}
