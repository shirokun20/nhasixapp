import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

/// Isolate worker untuk PDF processing
/// Isolate worker for PDF processing
class PdfIsolateWorker {
  /// Main entry point for isolate worker
  static void isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is PdfProcessingTask) {
        try {
          final result = await _processPdfInIsolate(message);
          sendPort.send(PdfProcessingResult.success(
            pdfPath: result.pdfPath,
            fileSize: result.fileSize,
            pageCount: result.pageCount,
          ));
        } catch (e, stackTrace) {
          sendPort.send(PdfProcessingResult.error(
            error: e.toString(),
            stackTrace: stackTrace.toString(),
          ));
        }
      }
    });
  }

  /// Process PDF creation in isolate
  static Future<_PdfResult> _processPdfInIsolate(PdfProcessingTask task) async {
    final processedImages = <Uint8List>[];

    // Process each image
    for (int i = 0; i < task.imagePaths.length; i++) {
      final imagePath = task.imagePaths[i];

      try {
        final imageBytes = await _processImageInIsolate(
          imagePath,
          maxWidth: task.maxWidth,
          quality: task.quality,
        );

        if (imageBytes != null) {
          processedImages.add(imageBytes);
        }
      } catch (e) {
        // Skip failed images, continue processing
        // Use proper logging instead of print in production
        // print('Failed to process image $imagePath: $e');
        continue;
      }
    }

    if (processedImages.isEmpty) {
      throw Exception('No images could be processed for PDF');
    }

    // Create PDF
    final pdfBytes = await _createPdfInIsolate(processedImages, task.title);

    // Save PDF file
    final pdfFile = File(task.outputPath);
    await pdfFile.writeAsBytes(pdfBytes);

    final fileSize = await pdfFile.length();

    return _PdfResult(
      pdfPath: task.outputPath,
      fileSize: fileSize,
      pageCount: processedImages.length,
    );
  }

  /// Process single image in isolate
  static Future<Uint8List?> _processImageInIsolate(
    String imagePath, {
    required int maxWidth,
    required int quality,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Could not decode image: $imagePath');
      }

      // Resize image if needed
      img.Image processedImage = image;
      if (image.width > maxWidth) {
        final aspectRatio = image.height / image.width;
        final newHeight = (maxWidth * aspectRatio).round();

        processedImage = img.copyResize(
          image,
          width: maxWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with specified quality
      final compressedBytes = img.encodeJpg(processedImage, quality: quality);

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      // Use proper logging instead of print in production
      // print('Error processing image $imagePath: $e');
      return null;
    }
  }

  /// Create PDF bytes in isolate
  static Future<Uint8List> _createPdfInIsolate(
    List<Uint8List> images,
    String title,
  ) async {
    try {
      final pdf = pw.Document();

      // Add each image as a page
      for (final imageBytes in images) {
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(0),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      // Generate PDF bytes
      return await pdf.save();
    } catch (e) {
      throw Exception('Error creating PDF: $e');
    }
  }
}

/// Task untuk isolate processing
/// Task for isolate processing
class PdfProcessingTask {
  const PdfProcessingTask({
    required this.imagePaths,
    required this.outputPath,
    required this.title,
    required this.maxWidth,
    required this.quality,
  });

  final List<String> imagePaths;
  final String outputPath;
  final String title;
  final int maxWidth;
  final int quality;
}

/// Result dari isolate processing
/// Result from isolate processing
class PdfProcessingResult {
  const PdfProcessingResult({
    required this.success,
    this.pdfPath,
    this.fileSize,
    this.pageCount,
    this.error,
    this.stackTrace,
  });

  final bool success;
  final String? pdfPath;
  final int? fileSize;
  final int? pageCount;
  final String? error;
  final String? stackTrace;

  factory PdfProcessingResult.success({
    required String pdfPath,
    required int fileSize,
    required int pageCount,
  }) {
    return PdfProcessingResult(
      success: true,
      pdfPath: pdfPath,
      fileSize: fileSize,
      pageCount: pageCount,
    );
  }

  factory PdfProcessingResult.error({
    required String error,
    String? stackTrace,
  }) {
    return PdfProcessingResult(
      success: false,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Internal result class for isolate
class _PdfResult {
  const _PdfResult({
    required this.pdfPath,
    required this.fileSize,
    required this.pageCount,
  });

  final String pdfPath;
  final int fileSize;
  final int pageCount;
}
