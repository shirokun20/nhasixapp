import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:kuron_native/kuron_native_platform_interface.dart';
import 'package:kuron_native/kuron_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKuronNativePlatform
    with MockPlatformInterfaceMixin
    implements KuronNativePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> startDownload({
    required String url,
    required String fileName,
    String? destinationDir,
    String? title,
    String? description,
    String? mimeType,
    String? cookie,
    String? userAgent,
  }) async {
    return 'mock_download_id';
  }

  @override
  Future<Map<String, dynamic>?> convertImagesToPdf({
    required List<String> imagePaths,
    required String outputPath,
    Function(int progress, String message)? onProgress,
  }) async {
    return {'success': true, 'pdfPath': outputPath};
  }

  @override
  Future<void> openWebView({
    required String url,
    bool enableJavaScript = true,
  }) async {
    return;
  }

  @override
  Future<void> openPdf({
    required String filePath,
    String? title,
  }) async {
    return;
  }
  @override
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
    String? autoCloseOnCookie,
    bool clearCookies = false,
  }) async {
    return {'success': true, 'cookies': [], 'userAgent': 'MOCK_UA'};
  }

  @override
  Future<void> clearCookies() async {
    return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final KuronNativePlatform initialPlatform = KuronNativePlatform.instance;

  test('$MethodChannelKuronNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKuronNative>());
  });

  test('getPlatformVersion', () async {
    KuronNative kuronNativePlugin = KuronNative();
    MockKuronNativePlatform fakePlatform = MockKuronNativePlatform();
    KuronNativePlatform.instance = fakePlatform;

    expect(await kuronNativePlugin.getPlatformVersion(), '42');
  });
}
