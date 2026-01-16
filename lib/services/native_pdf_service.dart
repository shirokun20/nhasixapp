import 'package:flutter/services.dart';

class NativePdfService {
  static const MethodChannel _channel = MethodChannel('id.nhasix.app/pdf_conversion');

  /// Start PDF generation via native layer
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
}
