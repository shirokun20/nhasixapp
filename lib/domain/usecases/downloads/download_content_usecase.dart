import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;


import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../../repositories/user_data_repository.dart';
import '../../../services/native_download_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/download_manager.dart';

/// Use case for downloading content for offline reading
class DownloadContentUseCase
    extends UseCase<DownloadStatus, DownloadContentParams> {
  DownloadContentUseCase(
    this._userDataRepository,
    this._nativeDownloadService,
    this._pdfService, {
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final UserDataRepository _userDataRepository;
  final NativeDownloadService _nativeDownloadService;
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
      
      // STORAGE VALIDATION: Custom Storage Root is MANDATORY
      // Use provided savePath or fallback to global setting
      // We must resolve this BEFORE starting download
      String effectiveSavePath = params.savePath ?? '';
      if (effectiveSavePath.isEmpty) {
         // Import StorageSettings if not already imported, or fetch from repository if available.
         // Since we don't have StorageSettings imported here, we'll try to rely on UserDataRepository or assume params MUST have it.
         // However, the user asked to check "flutter.custom_storage_root".
         // Let's check UserPreferences via repository.
         final prefs = await _userDataRepository.getUserPreferences();
         if (prefs.customStorageRoot.isNotEmpty) {
           effectiveSavePath = prefs.customStorageRoot;
         }
      }
      
      if (effectiveSavePath.isEmpty) {
         throw const ValidationException('Custom storage root is required. Please set a download location in settings.');
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
          params.cookies,
          effectiveSavePath,
          // STRICTLY DISABLE NATIVE NOTIFICATIONS
          // Hardcoded to false to ensure native notifications are NEVER shown,
          // regardless of what might be passed in params.
          false, 
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
  Future<void> deleteCall(String contentId, {String? dirPath}) async {
    try {
      // Remove download status from repository
      await _userDataRepository.deleteDownloadStatus(contentId);

      // Remove downloaded files from storage
      await _nativeDownloadService.deleteDownloadedContent(contentId, dirPath: dirPath);
    } catch (e) {
      _logger.e('Failed to delete downloaded content: $contentId', error: e);
    }
  }

  /// Perform the actual download process using NativeDownloadService
  ///
  /// REVAMP: This method is now "Fire-and-Forget". 
  /// It starts the native download and returns immediately.
  /// Progress and completion are handled globally by DownloadManager listening to NativeDownloadService.
  Future<DownloadStatus> _performActualDownload(
    Content content,
    DownloadStatus initialStatus,
    bool convertToPdf,
    String imageQuality,
    Duration? timeoutDuration,
    int? startPage,
    int? endPage,
    Map<String, String>? cookies,
    String? savePath,
    bool enableNotifications, // Replaced by strict false in call()
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
      
      String destination = savePath ?? '';

      // Start Native Download (Fire and Forget)
      await _nativeDownloadService.startDownload(
        contentId: content.id,
        sourceId: content.sourceId,
        imageUrls: fullImageUrls,
        destinationPath: destination,
        cookies: cookies,
        title: content.title,
        url: content.url,
        coverUrl: content.coverUrl,
        language: content.language,
        enableNotifications: enableNotifications, // This will now be false
      );

      // We do NOT wait for completion here anymore. 
      // The NativeService emits events to the EventChannel, which DownloadManager picks up.
      // DownloadBloc listens to DownloadManager and updates state accordingly.

      _logger.i('Native download started for ${content.id}');

      // Note: If PDF conversion is requested, we need a way to trigger it AFTER download completes.
      // Since we are not waiting here, the PDF conversion logic must be moved 
      // to where the 'COMPLETED' event is handled (likely in DownloadBloc._onProgressUpdate).
      // For now, we'll note this limitation or handle it in Bloc.
      
      return currentStatus;

    } catch (e) {
      _logger.e('Failed to start download for content: ${content.id}', error: e);
      
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
  Future<void> convertToPdfIfRequested(Content content) async {
    try {
      _logger.i('Starting PDF conversion for content: ${content.id}');

      // Get downloaded image files
      final imageFiles =
          await _nativeDownloadService.getDownloadedFiles(content.id);
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
      final contentPath = await _nativeDownloadService.getDownloadPath(contentId);

      if (contentPath == null) {
        throw Exception('Content path not found');
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
    this.cookies, // NEW: Cookies for authentication
    this.savePath, // NEW: Custom save path
    this.enableNotifications = true, // NEW
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
  final Map<String, String>? cookies; // NEW: Cookies for authentication
  final String? savePath; // NEW: Custom save path
  final bool enableNotifications; // NEW

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
        cookies, // NEW
        savePath, // NEW
        enableNotifications, // NEW
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
    Map<String, String>? cookies, // NEW
    String? savePath, // NEW
    bool? enableNotifications, // NEW
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
      cookies: cookies ?? this.cookies, // NEW
      savePath: savePath ?? this.savePath, // NEW
      enableNotifications: enableNotifications ?? this.enableNotifications, // NEW
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
      // NEW
      int? endPage,
      Map<String, String>? cookies,
      String? savePath,
      bool enableNotifications = true, // NEW
      }) {
    return DownloadContentParams(
      content: content,
      priority: 5,
      startImmediately: true,
      convertToPdf: convertToPdf,
      imageQuality: imageQuality,
      timeoutDuration: timeoutDuration,
      startPage: startPage,
      endPage: endPage,
      cookies: cookies, // NEW
      savePath: savePath, // NEW
      enableNotifications: enableNotifications, // NEW
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
