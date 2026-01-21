import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

import 'pdf_isolate_worker.dart';
import '../core/utils/image_splitter.dart';

/// Service untuk convert downloaded images ke PDF
class PdfService {
  PdfService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  /// Static function untuk compute() - berjalan di isolate terpisah
  /// Static function for compute() - runs in separate isolate
  static Future<PdfProcessingResult> _processPdfTask(PdfProcessingTask task) async {
    try {
      final processedImages = <Uint8List>[];
      
      // Process each image (with auto-split for webtoons)
      for (int i = 0; i < task.imagePaths.length; i++) {
        final imagePath = task.imagePaths[i];
        
        try {
          // ✅ NEW: Auto-split webtoon images into chunks
          final imageChunks = await ImageSplitter.splitImage(imagePath);
          
          // Process each chunk
          for (final chunkBytes in imageChunks) {
            try {
              // Process chunk (resize if needed)
              final processedBytes = await _processImageBytesStatic(
                chunkBytes,
                maxWidth: task.maxWidth,
                quality: task.quality,
              );
              
              if (processedBytes != null) {
                processedImages.add(processedBytes);
              }
            } catch (e) {
              // Skip failed chunk, continue with others
              debugPrint('Failed to process chunk for image $imagePath: $e');
              continue;
            }
          }
        } catch (e) {
          // Skip failed images, continue processing
          debugPrint('Failed to process image $imagePath: $e');
          continue;
        }
      }
      
      if (processedImages.isEmpty) {
        throw Exception('No images could be processed for PDF');
      }
      
      // Create PDF
      final pdfBytes = await _createPdfStatic(processedImages, task.title);
      
      // Save PDF file
      final pdfFile = File(task.outputPath);
      await pdfFile.writeAsBytes(pdfBytes);
      
      final fileSize = await pdfFile.length();
      
      return PdfProcessingResult.success(
        pdfPath: task.outputPath,
        fileSize: fileSize,
        pageCount: processedImages.length,
      );
    } catch (e, stackTrace) {
      return PdfProcessingResult.error(
        error: e.toString(),
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// Static image processing function for isolate (processes bytes directly)
  static Future<Uint8List?> _processImageBytesStatic(
    Uint8List imageBytes, {
    required int maxWidth,
    required int quality,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Could not decode image bytes');
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
      debugPrint('Error processing image bytes: $e');
      return null;
    }
  }

  /// Static PDF creation function for isolate
  static Future<Uint8List> _createPdfStatic(
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

  /// Convert downloaded images to PDF using compute() for background processing
  Future<PdfResult> convertToPdfInIsolate({
    required String contentId,
    required String title,
    required List<String> imagePaths,
    required String outputDir,
    int? maxWidth,
    int? quality,
    int? partNumber,
  }) async {
    try {
      _logger.i('========================================');
      _logger.i('PDF GENERATION STARTED');
      _logger.i('Content ID: $contentId');
      _logger.i('Title: $title');
      _logger.i('Images: ${imagePaths.length} files');
      _logger.i('Part: ${partNumber ?? "Single file"}');
      _logger.i('========================================');

      if (imagePaths.isEmpty) {
        throw Exception('No images to convert to PDF');
      }

      // Estimate processing time (rough: 0.5s per image)
      final estimatedSeconds = (imagePaths.length * 0.5).round();
      _logger.i('⏱️  Estimated processing time: ~$estimatedSeconds seconds');
      _logger.i('📊 Processing in isolate (compute)...');
      _logger.i('🎯 This may take a while, please wait...');

      // Create safe filename with part number support
      final safeTitle = _createSafeFilename(title);
      final pdfFileName = partNumber != null 
          ? '${contentId}_${safeTitle}_part$partNumber.pdf'
          : '${contentId}_$safeTitle.pdf';
      final pdfPath = path.join(outputDir, pdfFileName);

      // Create task for compute
      final task = PdfProcessingTask(
        imagePaths: imagePaths,
        outputPath: pdfPath,
        title: title,
        maxWidth: maxWidth ?? 1200,
        quality: quality ?? 85,
      );

      // Use compute() to run heavy processing in isolate
      _logger.i('🚀 Starting compute() for ${imagePaths.length} images...');
      final stopwatch = Stopwatch()..start();
      
      final result = await compute(_processPdfTask, task);
      
      stopwatch.stop();
      _logger.i('✅ compute() completed in ${stopwatch.elapsed.inSeconds}s');
      _logger.i('📄 Pages generated: ${result.pageCount ?? 0}');

      if (result.success) {
        _logger.i('========================================');
        _logger.i('✨ PDF GENERATION SUCCESS!');
        _logger.i('📁 Path: ${result.pdfPath}');
        _logger.i('💾 Size: ${_formatFileSize(result.fileSize!)}');
        _logger.i('📄 Pages: ${result.pageCount}');
        _logger.i('⏱️  Total time: ${stopwatch.elapsed.inSeconds}s');
        _logger.i('========================================');

        return PdfResult(
          success: true,
          pdfPath: result.pdfPath!,
          fileSize: result.fileSize!,
          pageCount: result.pageCount!,
        );
      } else {
        throw Exception(result.error ?? 'Unknown error in compute processing');
      }

    } catch (e) {
      _logger.e('PDF conversion failed using compute() for content: $contentId', error: e);

      return PdfResult(
        success: false,
        error: e.toString(),
        pdfPath: null,
        fileSize: 0,
        pageCount: 0,
      );
    }
  }

  /// Convert downloaded images to PDF
  Future<PdfResult> convertToPdf({
    required String contentId,
    required String title,
    required List<String> imagePaths,
    required String outputDir,
    int? maxWidth,
    int? quality,
    int? partNumber, // NEW: Part number for multi-part PDFs
  }) async {
    try {
      _logger.i('Starting PDF conversion for content: $contentId');

      if (imagePaths.isEmpty) {
        throw Exception('No images to convert to PDF');
      }

      // Create safe filename with part number support
      final safeTitle = _createSafeFilename(title);
      final pdfFileName = partNumber != null 
          ? '${contentId}_${safeTitle}_part$partNumber.pdf'
          : '${contentId}_$safeTitle.pdf';
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
    // Remove or replace invalid characters including special symbols
    String safe = title
        .replaceAll(RegExp(r'[<>:"/\\|?*!@#$%^&()]'), '_')
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
  Future<bool> pdfExists(String contentId, String outputDir, {int? partNumber}) async {
    try {
      final directory = Directory(outputDir);
      if (!await directory.exists()) return false;

      final files = await directory.list().toList();
      
      if (partNumber != null) {
        // Check for specific part
        return files.any((file) =>
            file is File &&
            path.basename(file.path).startsWith('${contentId}_') &&
            path.basename(file.path).contains('_part$partNumber') &&
            path.extension(file.path).toLowerCase() == '.pdf');
      } else {
        // Check for any PDF with this contentId
        return files.any((file) =>
            file is File &&
            path.basename(file.path).startsWith('${contentId}_') &&
            path.extension(file.path).toLowerCase() == '.pdf');
      }
    } catch (e) {
      _logger.e('Error checking PDF existence: $e');
      return false;
    }
  }

  /// Get PDF path for content (returns first found PDF or specific part)
  Future<String?> getPdfPath(String contentId, String outputDir, {int? partNumber}) async {
    try {
      final directory = Directory(outputDir);
      if (!await directory.exists()) return null;

      final files = await directory.list().toList();
      
      if (partNumber != null) {
        // Look for specific part
        final pdfFile = files.firstWhere(
          (file) =>
              file is File &&
              path.basename(file.path).startsWith('${contentId}_') &&
              path.basename(file.path).contains('_part$partNumber') &&
              path.extension(file.path).toLowerCase() == '.pdf',
          orElse: () => throw StateError('PDF part $partNumber not found'),
        );
        return (pdfFile as File).path;
      } else {
        // Look for any PDF with this contentId (returns first found)
        final pdfFile = files.firstWhere(
          (file) =>
              file is File &&
              path.basename(file.path).startsWith('${contentId}_') &&
              path.extension(file.path).toLowerCase() == '.pdf',
          orElse: () => throw StateError('PDF not found'),
        );
        return (pdfFile as File).path;
      }
    } catch (e) {
      _logger.d('PDF not found for content: $contentId${partNumber != null ? ' part $partNumber' : ''}');
      return null;
    }
  }

  /// Delete PDF for content (all parts or specific part)
  Future<bool> deletePdf(String contentId, String outputDir, {int? partNumber}) async {
    try {
      final directory = Directory(outputDir);
      if (!await directory.exists()) return false;

      final files = await directory.list().toList();
      bool deleted = false;

      for (final file in files) {
        if (file is File &&
            path.basename(file.path).startsWith('${contentId}_') &&
            path.extension(file.path).toLowerCase() == '.pdf') {
          
          if (partNumber != null) {
            // Delete specific part only
            if (path.basename(file.path).contains('_part$partNumber')) {
              await file.delete();
              _logger.d('PDF part $partNumber deleted: ${file.path}');
              deleted = true;
            }
          } else {
            // Delete all PDF files for this content
            await file.delete();
            _logger.d('PDF deleted: ${file.path}');
            deleted = true;
          }
        }
      }

      return deleted;
    } catch (e) {
      _logger.e('Error deleting PDF: $e');
      return false;
    }
  }

  /// Get all PDF paths for content (useful for multi-part PDFs)
  Future<List<String>> getAllPdfPaths(String contentId, String outputDir) async {
    try {
      final directory = Directory(outputDir);
      if (!await directory.exists()) return [];

      final files = await directory.list().toList();
      final pdfPaths = <String>[];

      for (final file in files) {
        if (file is File &&
            path.basename(file.path).startsWith('${contentId}_') &&
            path.extension(file.path).toLowerCase() == '.pdf') {
          pdfPaths.add(file.path);
        }
      }

      // Sort paths to ensure correct part order (part1, part2, etc.)
      pdfPaths.sort();
      
      _logger.d('Found ${pdfPaths.length} PDF file(s) for content: $contentId');
      return pdfPaths;
    } catch (e) {
      _logger.e('Error getting all PDF paths: $e');
      return [];
    }
  }

  /// Get total PDF file size for content (all parts combined)
  Future<int> getPdfSize(String contentId, String outputDir) async {
    try {
      final directory = Directory(outputDir);
      if (!await directory.exists()) return 0;

      final files = await directory.list().toList();
      int totalSize = 0;

      for (final file in files) {
        if (file is File &&
            path.basename(file.path).startsWith('${contentId}_') &&
            path.extension(file.path).toLowerCase() == '.pdf') {
          totalSize += await file.length();
        }
      }

      return totalSize;
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
