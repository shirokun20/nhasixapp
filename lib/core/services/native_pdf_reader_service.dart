import 'package:logger/logger.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:nhasixapp/core/utils/native_theme_helper.dart';

class NativePdfReaderService {
  final Logger _logger;

  NativePdfReaderService({Logger? logger}) : _logger = logger ?? Logger();

  // [startPage] is NOT SUPPORTED by current KuronNative but kept for API compatibility
  Future<void> openPdf(
    String filePath, {
    String? title,
    int startPage = 0,
  }) async {
    try {
      _logger.i('📄 Opening PDF with native reader: $filePath');

      await KuronNative.instance.openPdf(
        filePath: filePath,
        title: title ?? '',
        startPage: startPage,
        backgroundColor: NativeThemeHelper.backgroundColorHex,
        textColor: NativeThemeHelper.textColorHex,
      );

      _logger.i('✅ PDF opened successfully');
    } catch (e) {
      _logger.e('❌ Unexpected error opening PDF: $e', error: e);
      rethrow;
    }
  }

  // PDF reader auto-closes when user presses back
  Future<void> closePdf() async {
    // Current native implementation doesn't expose closePdf
    // but the reader is managed by a separate Activity that closes on back press
    _logger.d('closePdf called (no action needed for KuronNative reader)');
  }
}
