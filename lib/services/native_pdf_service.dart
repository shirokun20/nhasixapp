import 'package:logger/logger.dart';
import 'package:kuron_native/kuron_native.dart';

class NativePdfService {
  final Logger _logger = Logger();

  /// Generate PDF using native high-performance implementation
  ///
  /// This is ~5x faster than Flutter for large webtoon sets
  ///
  /// **Parameters**:
  /// - [imagePaths]: List of absolute paths to image files
  /// - [outputPath]: Absolute path where PDF should be saved
  /// - [title]: Title for the PDF
  /// - [onProgress]: Callback for progress updates (progress: 0-100, message: status)
  ///
  /// **Returns**:
  /// - Map with: `success`, `pdfPath`, `pageCount`, `fileSize`
  Future<Map<String, dynamic>> generatePdfNative({
    required List<String> imagePaths,
    required String outputPath,
    required String title,
    required Function(int progress, String message) onProgress,
  }) async {
    try {
      _logger.i('🚀 Calling native PDF generator (via KuronNative)...');
      _logger.i('Images: ${imagePaths.length} files');

      final result = await KuronNative.instance.convertImagesToPdf(
        imagePaths: imagePaths,
        outputPath: outputPath,
        onProgress: onProgress,
      );

      if (result == null) {
        throw Exception('Native PDF generation returned null');
      }

      _logger.i('✅ Native PDF completed: ${result['pageCount']} pages');

      return result;
    } catch (e) {
      _logger.e('Native PDF generation failed: $e');
      throw Exception('Native PDF generation failed: $e');
    }
  }

  /// Open PDF in native high-performance reader (Activity)
  ///
  /// This launches a separate Android Activity for 120Hz smooth reading
  Future<void> openPdf({
    required String path,
    required String title,
    int startPage = 0,
  }) async {
    try {
      await KuronNative.instance.openPdf(
        filePath: path,
        title: title,
      );
    } catch (e) {
      _logger.e('Failed to open PDF via KuronNative: $e');
      throw Exception('Failed to open PDF: $e');
    }
  }
}
