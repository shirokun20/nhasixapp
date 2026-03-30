import 'package:logger/logger.dart';
import 'package:kuron_native/kuron_native.dart';

/// Service for opening PDFs using native Android PDF reader
/// Now wraps KuronNative plugin for compatibility
class NativePdfReaderService {
  final Logger _logger;

  NativePdfReaderService({Logger? logger}) : _logger = logger ?? Logger();

  /// Open PDF file in native reader
  ///
  /// [filePath] - Absolute path to PDF file
  /// [title] - Optional title for the reader
  /// [startPage] - Optional starting page number (NOT SUPPORTED by current KuronNative but kept for API compatibility)
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
      );

      _logger.i('✅ PDF opened successfully');
    } catch (e) {
      _logger.e('❌ Unexpected error opening PDF: $e', error: e);
      rethrow;
    }
  }

  /// Close PDF reader (if needed)
  /// Note: PDF reader auto-closes when user presses back
  Future<void> closePdf() async {
    // Current native implementation doesn't expose closePdf
    // but the reader is managed by a separate Activity that closes on back press
    _logger.d('closePdf called (no action needed for KuronNative reader)');
  }
}
