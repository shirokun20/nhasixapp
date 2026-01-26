import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Service for opening PDFs using native Android PDF reader
class NativePdfReaderService {
  static const MethodChannel _channel = MethodChannel('id.nhasix.app/pdf_reader');
  
  final Logger _logger;

  NativePdfReaderService({Logger? logger}) 
      : _logger = logger ?? Logger();

  /// Open PDF file in native reader
  /// 
  /// [filePath] - Absolute path to PDF file
  /// [title] - Optional title for the reader
  /// [startPage] - Optional starting page number (0-indexed)
  Future<void> openPdf(
    String filePath, {
    String? title,
    int startPage = 0,
  }) async {
    try {
      _logger.i('📄 Opening PDF with native reader: $filePath');
      
      await _channel.invokeMethod('openPdf', {
        'filePath': filePath,
        'title': title ?? '',
        'startPage': startPage,
      });
      
      _logger.i('✅ PDF opened successfully');
    } on PlatformException catch (e) {
      _logger.e('❌ Failed to open PDF: ${e.message}', error: e);
      rethrow;
    } catch (e) {
      _logger.e('❌ Unexpected error opening PDF: $e', error: e);
      rethrow;
    }
  }

  /// Close PDF reader (if needed)
  /// Note: PDF reader auto-closes when user presses back
  Future<void> closePdf() async {
    try {
      await _channel.invokeMethod('closePdf');
    } catch (e) {
      _logger.w('⚠️ Error closing PDF: $e');
    }
  }
}
