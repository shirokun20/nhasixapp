import 'dart:async';
import 'package:logger/logger.dart';

import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../../../services/download_service.dart';
import '../../../services/pdf_service.dart';

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
      );

      await _userDataRepository.saveDownloadStatus(downloadStatus);

      // Start actual download if not just queuing
      if (params.startImmediately) {
        downloadStatus =
            await _performActualDownload(params.content, downloadStatus);
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
        onProgress: (progress) async {
          // Update download status with progress
          currentStatus = currentStatus.copyWith(
            downloadedPages: progress.downloadedPages,
          );
          await _userDataRepository.saveDownloadStatus(currentStatus);
        },
      );

      if (downloadResult.success) {
        // Update status to completed
        currentStatus = currentStatus.copyWith(
          state: DownloadState.completed,
          endTime: DateTime.now(),
          downloadedPages: content.pageCount,
          downloadPath: downloadResult.downloadPath,
        );

        // Convert to PDF if requested
        // if (downloadResult.downloadPath != null) {
        //   await _convertToPdfIfRequested(content, downloadResult.downloadPath!);
        // }
      } else {
        // Update status to failed
        currentStatus = currentStatus.copyWith(
          state: DownloadState.failed,
          endTime: DateTime.now(),
          error: downloadResult.error ?? 'Unknown download error',
        );
      }

      await _userDataRepository.saveDownloadStatus(currentStatus);
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
  /// Hide dulu karena nanti di implementasi pas button
  Future<void> _convertToPdfIfRequested(
      Content content, String downloadPath) async {
    try {
      // Get downloaded image files
      final imageFiles = await _downloadService.getDownloadedFiles(content.id);
      if (imageFiles.isEmpty) return;

      // Convert to PDF
      final pdfResult = await _pdfService.convertToPdf(
        contentId: content.id,
        title: content.title,
        imagePaths: imageFiles,
        outputDir: downloadPath,
      );

      if (pdfResult.success) {
        _logger.i('PDF created successfully for content: ${content.id}');
      } else {
        _logger.w(
            'PDF conversion failed for content: ${content.id} - ${pdfResult.error}');
      }
    } catch (e) {
      _logger.e('Error during PDF conversion: $e');
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
  });

  final Content content;
  final int priority;
  final bool checkExisting;
  final bool throwIfExists;
  final bool startImmediately;
  final bool convertToPdf;

  @override
  List<Object> get props => [
        content,
        priority,
        checkExisting,
        throwIfExists,
        startImmediately,
        convertToPdf,
      ];

  DownloadContentParams copyWith({
    Content? content,
    int? priority,
    bool? checkExisting,
    bool? throwIfExists,
    bool? startImmediately,
    bool? convertToPdf,
  }) {
    return DownloadContentParams(
      content: content ?? this.content,
      priority: priority ?? this.priority,
      checkExisting: checkExisting ?? this.checkExisting,
      throwIfExists: throwIfExists ?? this.throwIfExists,
      startImmediately: startImmediately ?? this.startImmediately,
      convertToPdf: convertToPdf ?? this.convertToPdf,
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
      {bool convertToPdf = false}) {
    return DownloadContentParams(
      content: content,
      priority: 5,
      startImmediately: true,
      convertToPdf: convertToPdf,
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
