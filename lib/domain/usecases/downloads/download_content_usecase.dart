import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../../../services/download_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/download_manager.dart';

/// Use case for downloading content for offline reading
class DownloadContentUseCase
    extends UseCase<DownloadStatus, DownloadContentParams> {
  DownloadContentUseCase(
    this._userDataRepository,
    this._downloadService,
    this._pdfService, {
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final UserDataRepository _userDataRepository;
  final DownloadService _downloadService;
  final PdfService _pdfService;
  final Logger _logger;

  @override
  Future<DownloadStatus> call(DownloadContentParams params) async {
    try {
      // Validate parameters
      if (params.content.id.isEmpty) {
        throw const ValidationException('Content ID cannot be empty');
      }

      if (params.content.imageUrls.isEmpty) {
        throw const ValidationException('Content has no images to download');
      }

      if (params.priority < 0 || params.priority > 10) {
        throw const ValidationException('Priority must be between 0 and 10');
      }

      // Check if already downloaded (optional)
      if (params.checkExisting) {
        final existingStatus = await _userDataRepository.getDownloadStatus(
          params.content.id,
        );

        if (existingStatus != null && existingStatus.isCompleted) {
          if (params.throwIfExists) {
            throw const ValidationException('Content is already downloaded');
          } else {
            // Return existing download status
            return existingStatus;
          }
        }
      }

      // Create initial download status and save it
      var downloadStatus = DownloadStatus.initial(
        params.content.id,
        params.content.pageCount,
        startPage: params.startPage,
        endPage: params.endPage,
        title: params.content.title,
        sourceId: params.content.sourceId,
        coverUrl: params.content.coverUrl,
      );

      await _userDataRepository.saveDownloadStatus(downloadStatus);

      // Start actual download if not just queuing
      if (params.startImmediately) {
        downloadStatus = await _performActualDownload(
          params.content,
          downloadStatus,
          params.convertToPdf,
          params.imageQuality,
          params.timeoutDuration,
          params.startPage,
          params.endPage,
          params.cookies,  // NEW
        );
      }

      return downloadStatus;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to queue download: ${e.toString()}');
    }
  }

  // make features for delete folder by content id
  Future<void> deleteCall(String contentId) async {
    try {
      // Remove download status from repository
      await _userDataRepository.deleteDownloadStatus(contentId);

      // Remove downloaded files from storage
      await _downloadService.deleteDownloadedContent(contentId);
    } catch (e) {
      _logger.e('Failed to delete downloaded content: $contentId', error: e);
    }
  }

  /// Perform the actual download process
  Future<DownloadStatus> _performActualDownload(
    Content content,
    DownloadStatus initialStatus,
    bool convertToPdf,
    String imageQuality,
    Duration? timeoutDuration,
    int? startPage,
    int? endPage,
    Map<String, String>? cookies,  // NEW
  ) async {
    var currentStatus = initialStatus;

    try {
      // Update status to downloading
      currentStatus = currentStatus.copyWith(
        state: DownloadState.downloading,
        startTime: DateTime.now(),
      );
      await _userDataRepository.saveDownloadStatus(currentStatus);

      // Convert thumbnail URLs to full image URLs
      final fullImageUrls = content.imageUrls.map((url) => url).toList();
      final contentWithFullUrls = content.copyWith(imageUrls: fullImageUrls);

      // Perform download with progress tracking
      final downloadResult = await _downloadService.downloadContent(
        content: contentWithFullUrls,
        imageQuality: imageQuality,
        timeoutDuration: timeoutDuration,
        startPage: startPage,
        endPage: endPage,
        cookies: cookies,  // NEW: Use local parameter
        onProgress: (progress) async {
          // ✅ FIXED: Only emit to stream, let DownloadBloc handle database saves
          // This prevents race condition between multiple save operations
          DownloadManager().emitProgress(DownloadProgressUpdate(
            contentId: content.id,
            downloadedPages: progress.downloadedPages,
            totalPages: progress.totalPages,
            downloadSpeed: progress.speed,
            estimatedTimeRemaining: progress.estimatedTimeRemaining,
          ));
        },
      );

      if (downloadResult.success) {
        // VERIFICATION PHASE: 90% → 100%
        // This phase calculates file size and verifies integrity before marking as complete
        _logger.i('Starting verification phase for ${content.id}');
        
        // Emit 90% progress (download complete, starting verification)
        DownloadManager().emitProgress(DownloadProgressUpdate(
          contentId: content.id,
          downloadedPages: 90,
          totalPages: 100,
          downloadSpeed: 0.0,
          estimatedTimeRemaining: const Duration(seconds: 5),
        ));

        int totalFileSize = 0;
        int verifiedFiles = 0;
        
        if (downloadResult.downloadPath != null) {
          try {
            // Get all downloaded files for verification
            final downloadedFiles = await _downloadService.getDownloadedFiles(content.id);
            final totalFilesToVerify = downloadedFiles.length;
            
            _logger.i('Verifying $totalFilesToVerify files for ${content.id}');
            
            // Verify each file and calculate size
            for (int i = 0; i < downloadedFiles.length; i++) {
              final filePath = downloadedFiles[i];
              final file = File(filePath);
              
              if (await file.exists()) {
                final fileSize = await file.length();
                totalFileSize += fileSize;
                verifiedFiles++;
                
                // Update verification progress (90% to 100%)
                // Progress = 90 + (verifiedFiles / totalFiles * 10)
                final verificationProgress = 90 + ((verifiedFiles / totalFilesToVerify) * 10).toInt();
                
                DownloadManager().emitProgress(DownloadProgressUpdate(
                  contentId: content.id,
                  downloadedPages: verificationProgress,
                  totalPages: 100,
                  downloadSpeed: 0.0,
                  estimatedTimeRemaining: Duration(
                    seconds: ((totalFilesToVerify - verifiedFiles) * 0.1).ceil(),
                  ),
                ));
              } else {
                _logger.w('File not found during verification: $filePath');
              }
            }
            
            _logger.i('Verification complete for ${content.id}: '
                '$verifiedFiles files verified, total size: $totalFileSize bytes');
          } catch (e) {
            _logger.w('Failed to calculate file size during verification for ${content.id}: $e');
            // Continue with fileSize = 0 instead of failing the download
          }
        }

        // Emit 100% completion
        DownloadManager().emitProgress(DownloadProgressUpdate(
          contentId: content.id,
          downloadedPages: 100,
          totalPages: 100,
          downloadSpeed: 0.0,
          estimatedTimeRemaining: Duration.zero,
        ));

        // Update status to completed with calculated file size
        currentStatus = currentStatus.copyWith(
          state: DownloadState.completed,
          endTime: DateTime.now(),
          downloadedPages: content.pageCount,
          downloadPath: downloadResult.downloadPath,
          fileSize: totalFileSize,  // Set the calculated file size
        );

        // Convert to PDF if requested
        if (downloadResult.downloadPath != null && convertToPdf) {
          _logger.i('Starting PDF conversion for content: ${content.id}');

          // Notify about PDF conversion start
          DownloadManager().emitProgress(DownloadProgressUpdate(
            contentId: content.id,
            downloadedPages: content.pageCount,
            totalPages: content.pageCount,
            downloadSpeed: 0.0, // PDF conversion doesn't have speed
            estimatedTimeRemaining: const Duration(seconds: 30), // Estimated
          ));

          await _convertToPdfIfRequested(content, downloadResult.downloadPath!);
        }
      } else {
        // Update status to failed
        currentStatus = currentStatus.copyWith(
          state: DownloadState.failed,
          endTime: DateTime.now(),
          error: downloadResult.error ?? 'Unknown download error',
        );
      }

      await _userDataRepository.saveDownloadStatus(currentStatus);

      // ✅ FIXED: Emit completion event to notify DownloadBloc to refresh
      // This ensures UI updates immediately when download completes
      if (currentStatus.isCompleted || currentStatus.isFailed) {
        DownloadManager().emitCompletion(content.id, currentStatus.state);
      }

      return currentStatus;
    } catch (e) {
      _logger.e('Download failed for content: ${content.id}', error: e);

      // Update status to failed
      currentStatus = currentStatus.copyWith(
        state: DownloadState.failed,
        endTime: DateTime.now(),
        error: e.toString(),
      );
      await _userDataRepository.saveDownloadStatus(currentStatus);

      return currentStatus;
    }
  }

  /// Convert downloaded images to PDF if requested
  /// Enhanced with progress reporting via DownloadManager
  /// PDF disimpan di folder khusus: nhasix-generate/pdf/
  Future<void> _convertToPdfIfRequested(
      Content content, String downloadPath) async {
    try {
      _logger.i('Starting PDF conversion for content: ${content.id}');

      // Get downloaded image files
      final imageFiles = await _downloadService.getDownloadedFiles(content.id);
      if (imageFiles.isEmpty) {
        _logger.w('No images found for PDF conversion: ${content.id}');
        return;
      }

      _logger.i(
          'Converting ${imageFiles.length} images to PDF for: ${content.id}');

      // Create PDF folder: nhasix/{source}/{contentId}/pdf/
      final pdfOutputPath = await _getOrCreatePdfOutputPath(content.id);

      // Emit progress for PDF conversion start
      DownloadManager().emitProgress(DownloadProgressUpdate(
        contentId: content.id,
        downloadedPages: content.pageCount,
        totalPages: content.pageCount,
        downloadSpeed: 0.0,
        estimatedTimeRemaining:
            Duration(seconds: imageFiles.length * 2), // Estimate 2s per image
      ));

      // Convert to PDF with custom output path
      final pdfResult = await _pdfService.convertToPdf(
        contentId: content.id,
        title: content.title,
        imagePaths: imageFiles,
        outputDir: pdfOutputPath, // Use PDF folder instead of download folder
      );

      if (pdfResult.success) {
        _logger.i(
            'PDF created successfully for content: ${content.id} at: $pdfOutputPath');

        // Emit final progress for PDF completion
        DownloadManager().emitProgress(DownloadProgressUpdate(
          contentId: content.id,
          downloadedPages: content.pageCount,
          totalPages: content.pageCount,
          downloadSpeed: 0.0,
          estimatedTimeRemaining: Duration.zero,
        ));
      } else {
        _logger.w(
            'PDF conversion failed for content: ${content.id} - ${pdfResult.error}');
      }
    } catch (e) {
      _logger.e('Error during PDF conversion: $e');
    }
  }

  /// Create PDF output path in nhasix/{source}/{contentId}/pdf/ folder
  Future<String> _getOrCreatePdfOutputPath(String contentId) async {
    try {
      // Get content download path (nhasix/{source}/{contentId})
      final contentPath = await _downloadService.getDownloadPath(contentId);

      if (contentPath == null) {
        // Fallback to documents directory if path not found
        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory(
            path.join(appDocDir.path, 'nhasix-fallback', contentId, 'pdf'));
        _logger.w(
            'Content path not found, using fallback for PDF: ${fallbackDir.path}');

        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir.path;
      }

      // Create pdf folder inside content folder
      final pdfFolder = Directory(path.join(contentPath, 'pdf'));

      if (!await pdfFolder.exists()) {
        await pdfFolder.create(recursive: true);
        _logger.i('Created PDF folder: ${pdfFolder.path}');
      }

      return pdfFolder.path;
    } catch (e) {
      _logger.e('Error creating PDF folder: $e');
      rethrow;
    }
  }
}

/// Parameters for DownloadContentUseCase
class DownloadContentParams extends UseCaseParams {
  const DownloadContentParams({
    required this.content,
    this.priority = 0,
    this.checkExisting = true,
    this.throwIfExists = false,
    this.startImmediately = false,
    this.convertToPdf = false,
    this.imageQuality = 'high',
    this.timeoutDuration,
    this.startPage, // NEW: Start page for range download
    this.endPage, // NEW: End page for range download
    this.cookies,  // NEW: Cookies for authentication
  });

  final Content content;
  final int priority;
  final bool checkExisting;
  final bool throwIfExists;
  final bool startImmediately;
  final bool convertToPdf;
  final String imageQuality;
  final Duration? timeoutDuration;
  final int? startPage; // NEW: Start page for range download (1-based)
  final int? endPage; // NEW: End page for range download (1-based)
  final Map<String, String>? cookies;  // NEW: Cookies for authentication

  /// Check if this is a range download
  bool get isRangeDownload => startPage != null || endPage != null;

  /// Get effective start page (1 if not specified)
  int get effectiveStartPage => startPage ?? 1;

  /// Get effective end page (total pages if not specified)
  int get effectiveEndPage => endPage ?? content.pageCount;

  @override
  List<Object?> get props => [
        content,
        priority,
        checkExisting,
        throwIfExists,
        startImmediately,
        convertToPdf,
        imageQuality,
        timeoutDuration,
        startPage,
        endPage,
        cookies,  // NEW
      ];

  DownloadContentParams copyWith({
    Content? content,
    int? priority,
    bool? checkExisting,
    bool? throwIfExists,
    bool? startImmediately,
    bool? convertToPdf,
    String? imageQuality,
    Duration? timeoutDuration,
    int? startPage,
    int? endPage,
    Map<String, String>? cookies,  // NEW
  }) {
    return DownloadContentParams(
      content: content ?? this.content,
      priority: priority ?? this.priority,
      checkExisting: checkExisting ?? this.checkExisting,
      throwIfExists: throwIfExists ?? this.throwIfExists,
      startImmediately: startImmediately ?? this.startImmediately,
      convertToPdf: convertToPdf ?? this.convertToPdf,
      imageQuality: imageQuality ?? this.imageQuality,
      timeoutDuration: timeoutDuration ?? this.timeoutDuration,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      cookies: cookies ?? this.cookies,  // NEW
    );
  }

  /// Create params with normal priority
  factory DownloadContentParams.normal(Content content) {
    return DownloadContentParams(content: content, priority: 0);
  }

  /// Create params with high priority
  factory DownloadContentParams.highPriority(Content content) {
    return DownloadContentParams(content: content, priority: 5);
  }

  /// Create params with maximum priority
  factory DownloadContentParams.urgent(Content content) {
    return DownloadContentParams(content: content, priority: 10);
  }

  /// Create params with existing check disabled
  factory DownloadContentParams.force(Content content, {int priority = 0}) {
    return DownloadContentParams(
      content: content,
      priority: priority,
      checkExisting: false,
    );
  }

  /// Create params for batch download
  factory DownloadContentParams.batch(Content content, int batchPriority) {
    return DownloadContentParams(
      content: content,
      priority: batchPriority,
      checkExisting: true,
      throwIfExists: false, // Don't throw for batch operations
    );
  }

  /// Create params for immediate download with images
  factory DownloadContentParams.immediate(Content content,
      {bool convertToPdf = false,
      String imageQuality = 'high',
      Duration? timeoutDuration,
      int? startPage,
      int? endPage,
      Map<String, String>? cookies}) {  // NEW
    return DownloadContentParams(
      content: content,
      priority: 5,
      startImmediately: true,
      convertToPdf: convertToPdf,
      imageQuality: imageQuality,
      timeoutDuration: timeoutDuration,
      startPage: startPage,
      endPage: endPage,
      cookies: cookies,  // NEW
    );
  }

  /// Create params for PDF download
  factory DownloadContentParams.pdf(Content content) {
    return DownloadContentParams(
      content: content,
      priority: 3,
      startImmediately: true,
      convertToPdf: true,
    );
  }
}
