import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:get_it/get_it.dart';

import 'pdf_service.dart';
import 'notification_service.dart';
import '../domain/repositories/repositories.dart';

/// Service yang menangani konversi PDF di background dengan fitur splitting dan notifikasi
/// Handles background PDF conversion with splitting, progress tracking, and notifications
class PdfConversionService {
  PdfConversionService({
    required PdfService pdfService,
    required NotificationService notificationService,
    required UserDataRepository userDataRepository,
    Logger? logger,
  })  : _pdfService = pdfService,
        _notificationService = notificationService,
        _userDataRepository = userDataRepository,
        _logger = logger ?? Logger();

  final PdfService _pdfService;
  final NotificationService _notificationService;
  // ignore: unused_field
  final UserDataRepository _userDataRepository;
  final Logger _logger;

  /// File-based debug logging yang persisten di release mode
  /// Persistent file-based debug logging for release mode debugging
  Future<void> _debugLogToFile(String message) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final debugFile = File(path.join(documentsDir.path, 'pdf_conversion_debug.log'));
      
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] $message\n';
      
      // Append to debug file
      await debugFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Ignore file write errors - tidak boleh crash conversion process
      // Ignore file write errors - should not crash conversion process
    }
  }

  /// Read debug log file untuk debugging release mode issues
  /// Read debug log file for debugging release mode issues
  /// 
  /// Returns: String content of debug log file
  Future<String> getDebugLog() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final debugFile = File(path.join(documentsDir.path, 'pdf_conversion_debug.log'));
      
      if (await debugFile.exists()) {
        return await debugFile.readAsString();
      } else {
        return 'Debug log file not found. No PDF conversions attempted yet.';
      }
    } catch (e) {
      return 'Error reading debug log: ${e.toString()}';
    }
  }

  /// Clear debug log file
  /// Clear debug log file for fresh debugging
  Future<void> clearDebugLog() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final debugFile = File(path.join(documentsDir.path, 'pdf_conversion_debug.log'));
      
      if (await debugFile.exists()) {
        await debugFile.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Test method untuk verify apakah notification service bisa menampilkan notification
  /// Test method to verify if notification service can display notifications
  /// 
  /// Returns: true jika test notification berhasil ditampilkan
  Future<bool> testPdfNotification({
    String testContentId = 'test-pdf-123',
    String testTitle = 'PDF Notification Test',
  }) async {
    try {
      await _debugLogToFile('testPdfNotification: STARTING test with contentId=$testContentId');
      
      // Clear previous logs for clean test
      await clearDebugLog();
      await _debugLogToFile('testPdfNotification: Debug log cleared, starting fresh test');
      
      // Test basic notification service first
      await _debugLogToFile('testPdfNotification: Testing basic notification service');
      
      try {
        await _notificationService.showTestActionNotification();
        await _debugLogToFile('testPdfNotification: Basic test notification completed');
      } catch (basicTestError) {
        await _debugLogToFile('testPdfNotification: Basic test FAILED - ${basicTestError.toString()}');
      }
      
      // Ensure service is ready
      await _ensureNotificationServiceReady();
      
      // Check service state
      final isEnabled = _notificationService.isEnabled;
      await _debugLogToFile('testPdfNotification: NotificationService.isEnabled = $isEnabled');
      
      if (!isEnabled) {
        await _debugLogToFile('testPdfNotification: FAILED - NotificationService is not enabled');
        return false;
      }
      
      // Try to show simple PDF notification
      await _debugLogToFile('testPdfNotification: Attempting to show test PDF notification');
      
      await _notificationService.showPdfConversionStarted(
        contentId: testContentId,
        title: testTitle,
      );
      
      await _debugLogToFile('testPdfNotification: Test notification completed successfully');
      
      // Wait a bit then show completion notification
      await Future.delayed(const Duration(seconds: 2));
      
      await _notificationService.showPdfConversionCompleted(
        contentId: testContentId,
        title: testTitle,
        pdfPaths: ['/test/path/test.pdf'],
        partsCount: 1,
      );
      
      await _debugLogToFile('testPdfNotification: Test completion notification sent');
      return true;
      
    } catch (e, stackTrace) {
      await _debugLogToFile('testPdfNotification: EXCEPTION - ${e.toString()}');
      await _debugLogToFile('testPdfNotification: STACKTRACE - ${stackTrace.toString()}');
      return false;
    }
  }

  /// Quick static method untuk test dari UI atau main function
  /// Quick static method for testing from UI or main function
  static Future<void> quickTestPdfNotifications() async {
    try {
      final service = GetIt.instance<PdfConversionService>();
      final result = await service.testPdfNotification();
      
      print('PDF Notification Test Result: $result');
      
      // Also get the debug log
      final debugLog = await service.getDebugLog();
      print('Debug Log:\n$debugLog');
      
    } catch (e) {
      print('Quick test failed: $e');
    }
  }

  /// Ensure notification service is properly initialized before PDF notifications
  /// This fixes the issue where PDF notifications don't appear in release mode
  Future<void> _ensureNotificationServiceReady() async {
    try {
      await _debugLogToFile('_ensureNotificationServiceReady: Starting notification service setup');
      
      // Check initial state
      final initialEnabled = _notificationService.isEnabled;
      await _debugLogToFile('_ensureNotificationServiceReady: Initial isEnabled = $initialEnabled');
      
      // Re-initialize notification service to ensure it's ready for PDF notifications
      // This is especially important in release mode where the service might not be warm
      await _notificationService.initialize();
      
      await _debugLogToFile('_ensureNotificationServiceReady: NotificationService.initialize() completed');
      
      // Check state after first initialization
      final afterInitEnabled = _notificationService.isEnabled;
      await _debugLogToFile('_ensureNotificationServiceReady: After init isEnabled = $afterInitEnabled');
      
      // Additional setup for release mode compatibility
      // Force another initialization to ensure channels are properly registered
      try {
        // Double initialization to ensure proper channel setup
        await _notificationService.initialize();
        
        final finalEnabled = _notificationService.isEnabled;
        await _debugLogToFile('_ensureNotificationServiceReady: After double init isEnabled = $finalEnabled');
        
        if (!finalEnabled) {
          await _debugLogToFile('_ensureNotificationServiceReady: WARNING - Service still not enabled after double init!');
        }
        
      } catch (doubleInitError) {
        await _debugLogToFile('_ensureNotificationServiceReady: Double init error - ${doubleInitError.toString()}');
      }
      
      _logger.d('PdfConversionService: Notification service re-initialized for PDF notifications');
      await _debugLogToFile('_ensureNotificationServiceReady: Setup completed successfully');
      
    } catch (e) {
      _logger.w('PdfConversionService: Failed to re-initialize notification service', error: e);
      await _debugLogToFile('_ensureNotificationServiceReady: FAILED - ${e.toString()}');
    }
  }

  /// Hitung total ukuran file dari daftar path PDF
  /// Calculate total file size from list of PDF paths
  Future<int> _calculateTotalFileSize(List<String> pdfPaths) async {
    int totalSize = 0;
    for (final pdfPath in pdfPaths) {
      try {
        final file = File(pdfPath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      } catch (e) {
        _logger.w('PdfConversionService: Error getting file size for $pdfPath', error: e);
      }
    }
    return totalSize;
  }

  /// Mengkonversi images download menjadi PDF di background dengan splitting otomatis
  /// Converts downloaded images to PDF in background with automatic splitting
  /// 
  /// Parameters:
  /// - contentId: ID konten yang akan dikonversi
  /// - title: Judul konten untuk nama file PDF
  /// - imagePaths: List path gambar yang sudah di-download
  /// - outputDir: Direktori output (optional, default: nhasix-generate/pdf/)
  /// - maxPagesPerFile: Maksimal halaman per file PDF (default: 50)
  Future<void> convertToPdfInBackground({
    required String contentId,
    required String title,
    required List<String> imagePaths,
    String? outputDir,
    int maxPagesPerFile = 50,
  }) async {
    try {
      await _debugLogToFile('convertToPdfInBackground: STARTED for contentId=$contentId, title=$title, images=${imagePaths.length}');
      
      _logger.i('PdfConversionService: Starting background PDF conversion for $contentId');
      
      // Validasi input parameters
      if (imagePaths.isEmpty) {
        throw Exception('No images provided for PDF conversion');
      }

      // Tampilkan notifikasi bahwa konversi PDF dimulai
      // Show notification that PDF conversion has started
      _logger.i('PdfConversionService: About to show PDF conversion started notification');
      await _debugLogToFile('convertToPdfInBackground: About to call showPdfConversionStarted');
      
      // Ensure notification service is ready (especially important for release mode)
      await _ensureNotificationServiceReady();
      
      _notificationService.debugLogState('Before PDF conversion started notification');
      await _debugLogToFile('convertToPdfInBackground: Calling showPdfConversionStarted now');
      
      await _notificationService.showPdfConversionStarted(
        contentId: contentId,
        title: title,
      );
      
      await _debugLogToFile('convertToPdfInBackground: showPdfConversionStarted completed');

      // Buat direktori output untuk PDF
      // Create output directory for PDFs
      final pdfOutputDir = await _createPdfOutputDirectory(outputDir, contentId);
      _logger.d('PdfConversionService: Output directory created: ${pdfOutputDir.path}');

      // Split images jika lebih dari maxPagesPerFile
      // Split images if more than maxPagesPerFile
      final totalPages = imagePaths.length;
      final needsSplitting = totalPages > maxPagesPerFile;
      final pdfPaths = <String>[];
      
      if (needsSplitting) {
        // Proses splitting - buat multiple PDF files
        // Process splitting - create multiple PDF files
        final totalParts = (totalPages / maxPagesPerFile).ceil();
        _logger.i('PdfConversionService: Splitting into $totalParts parts ($totalPages pages)');
        
        for (int part = 1; part <= totalParts; part++) {
          final startIndex = (part - 1) * maxPagesPerFile;
          final endIndex = (startIndex + maxPagesPerFile).clamp(0, totalPages);
          final partImages = imagePaths.sublist(startIndex, endIndex);
          
          // Update progress notification hanya di pertengahan proses (tidak setiap part)
          // Update progress notification only in the middle of process (not every part)
          if (part == 1 || part == (totalParts ~/ 2) || part == totalParts) {
            final progressPercent = ((part - 1) / totalParts * 100).round();
            await _notificationService.updatePdfConversionProgress(
              contentId: contentId,
              progress: progressPercent,
              title: '$title (Part $part/$totalParts)',
            );
          }
          
          // Konversi part ini ke PDF dengan part number di isolate terpisah
          // Convert this part to PDF with part number in separate isolate
          _logger.d('PdfConversionService: Processing part $part in isolate...');
          
          final result = await _pdfService.convertToPdfInIsolate(
            contentId: contentId,
            title: '$title (Part $part)',
            imagePaths: partImages,
            outputDir: pdfOutputDir.path,
            partNumber: part, // Pass part number for unique filename
          );
          
          if (result.success && result.pdfPath != null) {
            pdfPaths.add(result.pdfPath!);
          } else {
            throw Exception('Failed to create PDF part $part: ${result.error}');
          }
        }
      } else {
        // Single PDF file - tidak perlu splitting, gunakan isolate
        // Single PDF file - no splitting needed, use isolate
        await _notificationService.updatePdfConversionProgress(
          contentId: contentId,
          progress: 50,
          title: title,
        );
        
        _logger.d('PdfConversionService: Processing single PDF in isolate...');
        
        final result = await _pdfService.convertToPdfInIsolate(
          contentId: contentId,
          title: title,
          imagePaths: imagePaths,
          outputDir: pdfOutputDir.path,
        );
        
        if (result.success && result.pdfPath != null) {
          pdfPaths.add(result.pdfPath!);
        } else {
          throw Exception('Failed to create PDF: ${result.error}');
        }
      }

      // Konversi berhasil - buat result object untuk tracking
      // Conversion successful - create result object for tracking
      final conversionResult = PdfConversionResult(
        success: true,
        pdfPaths: pdfPaths,
        pageCount: totalPages,
        partsCount: pdfPaths.length,
        fileSize: await _calculateTotalFileSize(pdfPaths),
      );

      // Simpan informasi PDF ke database (optional)
      // Save PDF information to database (optional)
      await _savePdfConversionInfo(contentId, conversionResult);

      // Tampilkan notifikasi sukses dengan informasi file yang dibuat
      // Show success notification with created file information
      _logger.i('PdfConversionService: About to show PDF conversion completed notification');
      await _debugLogToFile('convertToPdfInBackground: About to call showPdfConversionCompleted');
      
      // Ensure notification service is ready (especially important for release mode)
      await _ensureNotificationServiceReady();
      
      _notificationService.debugLogState('Before PDF conversion completed notification');
      await _debugLogToFile('convertToPdfInBackground: Calling showPdfConversionCompleted now');
      
      await _notificationService.showPdfConversionCompleted(
        contentId: contentId,
        title: title,
        pdfPaths: conversionResult.pdfPaths,
        partsCount: conversionResult.partsCount,
      );
      
      await _debugLogToFile('convertToPdfInBackground: showPdfConversionCompleted completed');
      
      _logger.i('PdfConversionService: PDF conversion completed successfully for $contentId');
      _logger.i('PdfConversionService: Created ${conversionResult.partsCount} PDF file(s) with ${conversionResult.pageCount} total pages');

    } catch (e, stackTrace) {
      // Handle unexpected errors selama proses konversi
      // Handle unexpected errors during conversion process
      _logger.e('PdfConversionService: Unexpected error during PDF conversion for $contentId', 
                error: e, stackTrace: stackTrace);
      
      await _debugLogToFile('convertToPdfInBackground: ERROR occurred - ${e.toString()}');
      
      // Ensure notification service is ready for error notification
      await _ensureNotificationServiceReady();
      
      await _debugLogToFile('convertToPdfInBackground: About to call showPdfConversionError');
      
      await _notificationService.showPdfConversionError(
        contentId: contentId,
        title: title,
        error: 'Conversion failed: ${e.toString()}',
      );
      
      await _debugLogToFile('convertToPdfInBackground: showPdfConversionError completed');
    }
  }

  /// Membuat direktori output untuk file PDF
  /// Creates output directory for PDF files
  /// 
  /// Returns: Directory object untuk menyimpan PDF
  Future<Directory> _createPdfOutputDirectory(String? customOutputDir, [String? contentId]) async {
    try {
      Directory outputDir;
      
      if (customOutputDir != null) {
        // Gunakan direktori custom yang diberikan user
        // Use custom directory provided by user
        outputDir = Directory(customOutputDir);
      } else {
        // Gunakan smart Downloads directory detection (sama dengan DownloadService)
        // Use smart Downloads directory detection (same as DownloadService)
        final downloadsPath = await _getDownloadsDirectory();
        
        if (contentId != null) {
          // Simpan PDF di folder konten yang sama dengan images: Downloads/nhasix/[contentId]/pdf/
          // Save PDF in same content folder as images: Downloads/nhasix/[contentId]/pdf/
          outputDir = Directory(path.join(downloadsPath, 'nhasix', contentId, 'pdf'));
        } else {
          // Fallback ke folder umum: Downloads/nhasix-generate/pdf/
          // Fallback to general folder: Downloads/nhasix-generate/pdf/
          outputDir = Directory(path.join(downloadsPath, 'nhasix-generate', 'pdf'));
        }
      }

      // Buat direktori jika belum ada (recursive: true untuk membuat parent dirs)
      // Create directory if it doesn't exist (recursive: true to create parent dirs)
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
        _logger.i('PdfConversionService: Created PDF output directory: ${outputDir.path}');
      }

      return outputDir;
    } catch (e) {
      _logger.e('PdfConversionService: Failed to create PDF output directory', error: e);
      
      // Fallback ke app documents directory jika gagal akses external storage
      // Fallback to app documents directory if external storage access fails
      final documentsDir = await getApplicationDocumentsDirectory();
      final fallbackDir = Directory(path.join(documentsDir.path, 'nhasix-pdf'));
      
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      
      _logger.w('PdfConversionService: Using fallback directory: ${fallbackDir.path}');
      return fallbackDir;
    }
  }

  /// Smart Downloads directory detection (same as DownloadService)
  /// Tries multiple possible Downloads folder names and locations
  Future<String> _getDownloadsDirectory() async {
    try {
      // First, try to get external storage directory
      Directory? externalDir;
      try {
        externalDir = await getExternalStorageDirectory();
      } catch (e) {
        _logger.w('PdfConversionService: Could not get external storage directory: $e');
      }

      if (externalDir != null) {
        // Try to find Downloads folder in external storage root
        final externalRoot = externalDir.path.split('/Android')[0];
        
        // Common Downloads folder names (English, Indonesian, Spanish, etc.)
        final downloadsFolderNames = [
          'Download',     // English (most common)
          'Downloads',    // English alternative
          'Unduhan',      // Indonesian
          'Descargas',    // Spanish
          'Téléchargements', // French
          'Downloads',    // German uses English
          'ダウンロード',     // Japanese
        ];

        // Try each possible Downloads folder
        for (final folderName in downloadsFolderNames) {
          final downloadsDir = Directory(path.join(externalRoot, folderName));
          if (await downloadsDir.exists()) {
            _logger.d('PdfConversionService: Found Downloads directory: ${downloadsDir.path}');
            return downloadsDir.path;
          }
        }

        // If no Downloads folder found, create one in external storage root
        final defaultDownloadsDir = Directory(path.join(externalRoot, 'Download'));
        try {
          if (!await defaultDownloadsDir.exists()) {
            await defaultDownloadsDir.create(recursive: true);
            _logger.i('PdfConversionService: Created Downloads directory: ${defaultDownloadsDir.path}');
          }
          return defaultDownloadsDir.path;
        } catch (e) {
          _logger.w('PdfConversionService: Could not create Downloads directory in external storage: $e');
        }
      }

      // Fallback 1: Try hardcoded common paths
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/emulated/0/Unduhan',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (final commonPath in commonPaths) {
        final dir = Directory(commonPath);
        if (await dir.exists()) {
          _logger.d('PdfConversionService: Found Downloads directory at common path: $commonPath');
          return commonPath;
        }
      }

      // Fallback 2: Use app-specific external storage
      if (externalDir != null) {
        final appDownloadsDir = Directory(path.join(externalDir.path, 'downloads'));
        if (!await appDownloadsDir.exists()) {
          await appDownloadsDir.create(recursive: true);
        }
        _logger.i('PdfConversionService: Using app-specific downloads directory: ${appDownloadsDir.path}');
        return appDownloadsDir.path;
      }

      // Fallback 3: Use application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsDownloadsDir = Directory(path.join(documentsDir.path, 'downloads'));
      if (!await documentsDownloadsDir.exists()) {
        await documentsDownloadsDir.create(recursive: true);
      }
      _logger.i('PdfConversionService: Using app documents downloads directory: ${documentsDownloadsDir.path}');
      return documentsDownloadsDir.path;

    } catch (e) {
      _logger.e('PdfConversionService: Error detecting Downloads directory: $e');
      
      // Emergency fallback: use app documents
      final documentsDir = await getApplicationDocumentsDirectory();
      final emergencyDir = Directory(path.join(documentsDir.path, 'downloads'));
      if (!await emergencyDir.exists()) {
        await emergencyDir.create(recursive: true);
      }
      _logger.w('PdfConversionService: Using emergency fallback directory: ${emergencyDir.path}');
      return emergencyDir.path;
    }
  }

  /// Simpan informasi hasil konversi PDF ke database untuk tracking
  /// Save PDF conversion result information to database for tracking
  /// 
  /// Parameters:
  /// - contentId: ID konten yang dikonversi
  /// - result: Hasil konversi dari PdfService
  Future<void> _savePdfConversionInfo(String contentId, PdfConversionResult result) async {
    try {
      // Implementasi penyimpanan info PDF ke database
      // Ini bisa digunakan untuk:
      // - Track PDF yang sudah dibuat untuk konten tertentu
      // - Menampilkan informasi PDF di UI
      // - Cleanup PDF files yang sudah tidak diperlukan
      
      // Example structure yang bisa disimpan:
      // {
      //   'contentId': contentId,
      //   'pdfPaths': result.pdfPaths,
      //   'partsCount': result.partsCount,
      //   'totalPages': result.pageCount,
      //   'totalFileSize': result.fileSize,
      //   'createdAt': DateTime.now().toIso8601String(),
      // }
      
      _logger.d('PdfConversionService: PDF info saved for $contentId (${result.partsCount} parts, ${result.pageCount} pages)');
    } catch (e) {
      _logger.w('PdfConversionService: Failed to save PDF conversion info', error: e);
      // Non-critical error, tidak perlu throw exception
      // Non-critical error, no need to throw exception
    }
  }

  /// Cek apakah PDF sudah pernah dibuat untuk konten tertentu
  /// Check if PDF has been created for specific content
  /// 
  /// Returns: true jika PDF sudah ada, false jika belum
  Future<bool> isPdfExistForContent(String contentId, {String? outputDir}) async {
    try {
      final pdfDir = await _createPdfOutputDirectory(outputDir, contentId);
      
      // Cek apakah ada file PDF dengan prefix contentId
      // Check if PDF files with contentId prefix exist
      final files = await pdfDir.list().toList();
      final pdfExists = files.any((file) => 
        file is File && 
        path.basename(file.path).startsWith('${contentId}_') &&
        path.extension(file.path).toLowerCase() == '.pdf'
      );
      
      _logger.d('PdfConversionService: PDF exists for $contentId: $pdfExists');
      return pdfExists;
    } catch (e) {
      _logger.e('PdfConversionService: Error checking PDF existence for $contentId', error: e);
      return false;
    }
  }

  /// Dapatkan daftar file PDF untuk konten tertentu
  /// Get list of PDF files for specific content
  /// 
  /// Returns: List path file PDF yang ditemukan
  Future<List<String>> getPdfPathsForContent(String contentId, {String? outputDir}) async {
    try {
      final pdfDir = await _createPdfOutputDirectory(outputDir, contentId);
      final pdfPaths = <String>[];
      
      // Scan direktori untuk file PDF dengan prefix contentId
      // Scan directory for PDF files with contentId prefix
      final files = await pdfDir.list().toList();
      
      for (final file in files) {
        if (file is File && 
            path.basename(file.path).startsWith('${contentId}_') &&
            path.extension(file.path).toLowerCase() == '.pdf') {
          pdfPaths.add(file.path);
        }
      }
      
      // Sort berdasarkan nama file untuk urutan part yang benar
      // Sort by filename for correct part order
      pdfPaths.sort();
      
      _logger.d('PdfConversionService: Found ${pdfPaths.length} PDF file(s) for $contentId');
      return pdfPaths;
    } catch (e) {
      _logger.e('PdfConversionService: Error getting PDF paths for $contentId', error: e);
      return [];
    }
  }

  /// Hapus semua file PDF untuk konten tertentu
  /// Delete all PDF files for specific content
  /// 
  /// Returns: true jika berhasil dihapus, false jika gagal
  Future<bool> deletePdfsForContent(String contentId, {String? outputDir}) async {
    try {
      final pdfPaths = await getPdfPathsForContent(contentId, outputDir: outputDir);
      
      if (pdfPaths.isEmpty) {
        _logger.d('PdfConversionService: No PDF files to delete for $contentId');
        return true;
      }
      
      // Hapus semua file PDF yang ditemukan
      // Delete all found PDF files
      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        if (await file.exists()) {
          await file.delete();
          _logger.d('PdfConversionService: Deleted PDF file: $pdfPath');
        }
      }
      
      _logger.i('PdfConversionService: Successfully deleted ${pdfPaths.length} PDF file(s) for $contentId');
      return true;
    } catch (e) {
      _logger.e('PdfConversionService: Error deleting PDF files for $contentId', error: e);
      return false;
    }
  }

  /// Dapatkan total ukuran file PDF untuk konten tertentu
  /// Get total file size of PDF files for specific content
  /// 
  /// Returns: Total ukuran dalam bytes
  Future<int> getTotalPdfSizeForContent(String contentId, {String? outputDir}) async {
    try {
      final pdfPaths = await getPdfPathsForContent(contentId, outputDir: outputDir);
      int totalSize = 0;
      
      // Hitung total ukuran semua file PDF
      // Calculate total size of all PDF files
      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
      
      _logger.d('PdfConversionService: Total PDF size for $contentId: $totalSize bytes');
      return totalSize;
    } catch (e) {
      _logger.e('PdfConversionService: Error calculating PDF size for $contentId', error: e);
      return 0;
    }
  }

  /// Format ukuran file untuk display ke user
  /// Format file size for user display
  /// 
  /// Parameters:
  /// - bytes: Ukuran dalam bytes
  /// 
  /// Returns: String format yang user-friendly (e.g., "2.5 MB")
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Cleanup file PDF lama berdasarkan umur atau kriteria tertentu
  /// Cleanup old PDF files based on age or specific criteria
  /// 
  /// Parameters:
  /// - maxAge: Umur maksimal file dalam hari (default: 30 hari)
  /// - outputDir: Direktori yang akan dibersihkan (optional)
  /// 
  /// Returns: Jumlah file yang berhasil dihapus
  Future<int> cleanupOldPdfs({int maxAge = 30, String? outputDir}) async {
    try {
      final pdfDir = await _createPdfOutputDirectory(outputDir);
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAge));
      int deletedCount = 0;
      
      _logger.i('PdfConversionService: Starting PDF cleanup, deleting files older than $maxAge days');
      
      // Scan semua file PDF di direktori
      // Scan all PDF files in directory
      final files = await pdfDir.list().toList();
      
      for (final file in files) {
        if (file is File && path.extension(file.path).toLowerCase() == '.pdf') {
          final stat = await file.stat();
          
          // Hapus file jika lebih tua dari cutoff date
          // Delete file if older than cutoff date
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
            _logger.d('PdfConversionService: Deleted old PDF: ${path.basename(file.path)}');
          }
        }
      }
      
      _logger.i('PdfConversionService: Cleanup completed, deleted $deletedCount old PDF files');
      return deletedCount;
    } catch (e) {
      _logger.e('PdfConversionService: Error during PDF cleanup', error: e);
      return 0;
    }
  }

  /// Dapatkan statistik PDF di direktori output
  /// Get PDF statistics in output directory
  /// 
  /// Returns: Map dengan informasi statistik
  Future<Map<String, dynamic>> getPdfStatistics({String? outputDir}) async {
    try {
      final pdfDir = await _createPdfOutputDirectory(outputDir);
      final files = await pdfDir.list().toList();
      
      int totalPdfFiles = 0;
      int totalSize = 0;
      final Map<String, int> contentCounts = {};
      
      // Analisis semua file PDF
      // Analyze all PDF files
      for (final file in files) {
        if (file is File && path.extension(file.path).toLowerCase() == '.pdf') {
          totalPdfFiles++;
          
          final fileSize = await file.length();
          totalSize += fileSize;
          
          // Extract content ID dari nama file
          // Extract content ID from filename
          final fileName = path.basenameWithoutExtension(file.path);
          final parts = fileName.split('_');
          if (parts.isNotEmpty) {
            final contentId = parts[0];
            contentCounts[contentId] = (contentCounts[contentId] ?? 0) + 1;
          }
        }
      }
      
      final statistics = {
        'totalPdfFiles': totalPdfFiles,
        'totalSizeBytes': totalSize,
        'totalSizeFormatted': formatFileSize(totalSize),
        'uniqueContents': contentCounts.length,
        'averageFilesPerContent': contentCounts.isNotEmpty 
            ? (totalPdfFiles / contentCounts.length).round() 
            : 0,
        'directoryPath': pdfDir.path,
      };
      
      _logger.d('PdfConversionService: PDF statistics - $statistics');
      return statistics;
    } catch (e) {
      _logger.e('PdfConversionService: Error getting PDF statistics', error: e);
      return {
        'totalPdfFiles': 0,
        'totalSizeBytes': 0,
        'totalSizeFormatted': '0 B',
        'uniqueContents': 0,
        'averageFilesPerContent': 0,
        'directoryPath': 'Unknown',
      };
    }
  }
}

/// Result object untuk tracking hasil konversi PDF dengan multiple parts
/// Result object for tracking PDF conversion result with multiple parts
class PdfConversionResult {
  const PdfConversionResult({
    required this.success,
    required this.pdfPaths,
    required this.pageCount,
    required this.partsCount,
    required this.fileSize,
    this.error,
  });

  /// Apakah konversi berhasil
  /// Whether conversion was successful
  final bool success;
  
  /// List path file PDF yang dibuat (bisa multiple jika di-split)
  /// List of PDF file paths created (can be multiple if split)
  final List<String> pdfPaths;
  
  /// Total jumlah halaman dari semua PDF
  /// Total number of pages across all PDFs
  final int pageCount;
  
  /// Jumlah file PDF yang dibuat (1 untuk single file, >1 untuk split)
  /// Number of PDF files created (1 for single file, >1 for split)
  final int partsCount;
  
  /// Total ukuran file semua PDF dalam bytes
  /// Total file size of all PDFs in bytes
  final int fileSize;
  
  /// Error message jika konversi gagal
  /// Error message if conversion failed
  final String? error;
  
  /// Convenience getter untuk mendapatkan path PDF pertama
  /// Convenience getter to get first PDF path
  String? get pdfPath => pdfPaths.isNotEmpty ? pdfPaths.first : null;
  
  /// Apakah PDF di-split menjadi multiple files
  /// Whether PDF was split into multiple files
  bool get isSplit => partsCount > 1;
}
