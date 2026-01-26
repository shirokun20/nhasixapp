import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class NativePdfService {
  static const MethodChannel _channel = MethodChannel('id.nhasix.app/pdf_conversion');
  static const MethodChannel _readerChannel = MethodChannel('id.nhasix.app/pdf_reader');
  final Logger _logger = Logger();

  /// Start PDF generation via native layer (WorkManager)
  Future<String> generatePdf({
    required String contentId,
    required List<String> imagePaths,
    int maxPagesPerFile = 50,
  }) async {
    try {
      final workId = await _channel.invokeMethod<String>('generatePdf', {
        'contentId': contentId,
        'imagePaths': imagePaths,
        'maxPagesPerFile': maxPagesPerFile,
      });
      return workId ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to start native PDF generation: ${e.message}');
    }
  }

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
    // Setup progress listener
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onProgress') {
        final progress = call.arguments['progress'] as int;
        final message = call.arguments['message'] as String;
        onProgress(progress, message);
      }
    });

    try {
      _logger.i('🚀 Calling native PDF generator (high-performance)...');
      _logger.i('Images: ${imagePaths.length} files');

      final result = await _channel.invokeMethod('generatePdfNative', {
        'imagePaths': imagePaths,
        'outputPath': outputPath,
        'title': title,
      });

      final resultMap = Map<String, dynamic>.from(result as Map);
      
      _logger.i('✅ Native PDF completed: ${resultMap['pageCount']} pages');
      
      return resultMap;
    } on PlatformException catch (e) {
      _logger.e('Native PDF failed: ${e.message}');
      throw Exception('Native PDF generation failed: ${e.message}');
    } finally {
      _channel.setMethodCallHandler(null);
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
      await _readerChannel.invokeMethod('openPdf', {
        'filePath': path,
        'title': title,
        'startPage': startPage,
      });
    } on PlatformException catch (e) {
      _logger.e('Failed to open PDF: ${e.message}');
      throw Exception('Failed to open PDF: ${e.message}');
    }
  }
}
