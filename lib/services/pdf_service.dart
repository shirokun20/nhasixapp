import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

/// Service untuk convert downloaded images ke PDF
class PdfService {
  PdfService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  /// Convert downloaded images to PDF
  Future<PdfResult> convertToPdf({
    required String contentId,
    required String title,
    required List<String> imagePaths,
    required String outputDir,
    int? maxWidth,
    int? quality,
  }) async {
    try {
      _logger.i('Starting PDF conversion for content: $contentId');

      if (imagePaths.isEmpty) {
        throw Exception('No images to convert to PDF');
      }

      // Create safe filename
      final safeTitle = _createSafeFilename(title);
      final pdfFileName = '${contentId}_$safeTitle.pdf';
      final pdfPath = path.join(outputDir, pdfFileName);

      // Process images and create PDF
      final processedImages = <Uint8List>[];

      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        _logger.d(
            'Processing image ${i + 1}/${imagePaths.length}: ${path.basename(imagePath)}');

        try {
          final imageBytes = await _processImage(
            imagePath,
            maxWidth: maxWidth ?? 1200,
            quality: quality ?? 85,
          );

          if (imageBytes != null) {
            processedImages.add(imageBytes);
          }
        } catch (e) {
          _logger.w('Failed to process image $imagePath: $e');
          // Continue with other images
          continue;
        }
      }

      if (processedImages.isEmpty) {
        throw Exception('No images could be processed for PDF');
      }

      // Create PDF
      await _createPdf(
        processedImages,
        pdfPath,
        title: title,
        contentId: contentId,
      );

      final pdfFile = File(pdfPath);
      final fileSize = await pdfFile.length();

      _logger.i(
          'PDF created successfully: $pdfPath (${_formatFileSize(fileSize)})');

      return PdfResult(
        success: true,
        pdfPath: pdfPath,
        fileSize: fileSize,
        pageCount: processedImages.length,
      );
    } catch (e) {
      _logger.e('PDF conversion failed for content: $contentId', error: e);

      return PdfResult(
        success: false,
        error: e.toString(),
        pdfPath: null,
        fileSize: 0,
        pageCount: 0,
      );
    }
  }

  /// Process single image (resize, compress, optimize)
  Future<Uint8List?> _processImage(String imagePath,
      {required int maxWidth, required int quality}) async {
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
      _logger.e('Error processing image $imagePath: $e');
      return null;
    }
  }

  /// Create PDF from processed images
  Future<void> _createPdf(List<Uint8List> images, String outputPath,
      {required String title, required String contentId}) async {
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

      // Save PDF to file
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());

      _logger.d('PDF created with ${images.length} pages');
    } catch (e) {
      _logger.e('Error creating PDF: $e');
      rethrow;
    }
  }

  /// Create safe filename from title
  String _createSafeFilename(String title) {
    // Remove or replace invalid characters
    String safe = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    // Limit length
    if (safe.length > 50) {
      safe = safe.substring(0, 50);
    }

    // Remove trailing underscore
    safe = safe.replaceAll(RegExp(r'_+$'), '');

    return safe.isEmpty ? 'untitled' : safe;
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if PDF exists for content
  Future<bool> pdfExists(String contentId, String outputDir) async {
    try {
      final directory = Directory(outputDir);
      if (!await directory.exists()) return false;

      final files = await directory.list().toList();
      return files.any((file) =>
          file is File &&
          path.basename(file.path).startsWith('${contentId}_') &&
          path.extension(file.path).toLowerCase() == '.pdf');
    } catch (e) {
      _logger.e('Error checking PDF existence: $e');
      return false;
    }
  }

  /// Get PDF path for content
  Future<String?> getPdfPath(String contentId, String outputDir) async {
    try {
      final directory = Directory(outputDir);
      if (!await directory.exists()) return null;

      final files = await directory.list().toList();
      final pdfFile = files.firstWhere(
        (file) =>
            file is File &&
            path.basename(file.path).startsWith('${contentId}_') &&
            path.extension(file.path).toLowerCase() == '.pdf',
        orElse: () => throw StateError('PDF not found'),
      );

      return (pdfFile as File).path;
    } catch (e) {
      _logger.d('PDF not found for content: $contentId');
      return null;
    }
  }

  /// Delete PDF for content
  Future<bool> deletePdf(String contentId, String outputDir) async {
    try {
      final pdfPath = await getPdfPath(contentId, outputDir);
      if (pdfPath == null) return false;

      final file = File(pdfPath);
      if (await file.exists()) {
        await file.delete();
        _logger.d('PDF deleted: $pdfPath');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Error deleting PDF: $e');
      return false;
    }
  }

  /// Get PDF file size
  Future<int> getPdfSize(String contentId, String outputDir) async {
    try {
      final pdfPath = await getPdfPath(contentId, outputDir);
      if (pdfPath == null) return 0;

      final file = File(pdfPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      _logger.e('Error getting PDF size: $e');
      return 0;
    }
  }
}

/// Result of PDF conversion
class PdfResult {
  const PdfResult({
    required this.success,
    required this.pageCount,
    required this.fileSize,
    this.pdfPath,
    this.error,
  });

  final bool success;
  final String? pdfPath;
  final int pageCount;
  final int fileSize;
  final String? error;
}

/// PDF conversion options
class PdfOptions {
  const PdfOptions({
    this.maxWidth = 1200,
    this.quality = 85,
    this.pageFormat = PdfPageFormat.a4,
    this.fitMode = PdfFitMode.contain,
  });

  final int maxWidth;
  final int quality;
  final PdfPageFormat pageFormat;
  final PdfFitMode fitMode;
}

/// PDF page format options
enum PdfPageFormat {
  a4,
  a5,
  letter,
  legal,
}

/// PDF fit mode options
enum PdfFitMode {
  contain,
  cover,
  fill,
  fitWidth,
  fitHeight,
}
