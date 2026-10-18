import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/services/header_inspector_service.dart';
import 'package:nhasixapp/core/services/local_image_preloader.dart';
import 'package:nhasixapp/core/utils/header_inspector.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/core/utils/reader_image_repair_utils.dart';
import 'package:nhasixapp/domain/entities/page_image_result.dart';
import 'package:nhasixapp/domain/repositories/reader_image_repository.dart';
import 'remote/ehentai_reader_datasource.dart';

/// Cancellation handle for reader page resolution without exposing Dio types to widgets.
class ReaderImageCancellation {
  ReaderImageCancellation() : _token = CancelToken();

  final CancelToken _token;

  CancelToken get dioToken => _token;

  bool get isCancelled => _token.isCancelled;

  void cancel([String? reason]) {
    if (!_token.isCancelled) {
      _token.cancel(reason);
    }
  }
}

/// Result of processing a local/cached image file through the pipeline.
class ProcessedImageResult {
  const ProcessedImageResult({
    required this.renderPath,
    this.convertedPath,
    this.wasConverted = false,
    this.isHeavy = false,
    this.isConfirmedAnimatedWebP = false,
    this.nativeImageSize,
    this.imageBytes,
    this.shouldBypassLocalDecode = false,
  });

  final String renderPath;
  final String? convertedPath;
  final bool wasConverted;
  final bool isHeavy;
  final bool isConfirmedAnimatedWebP;
  final Size? nativeImageSize;
  final int? imageBytes;
  final bool shouldBypassLocalDecode;
}

/// Pipeline service coordinating reader image resolution, network scraping,
/// in-memory caching, AVIF→WebP conversion, format conflict deletion, and header inspection.
class ReaderImagePipeline {
  ReaderImagePipeline({
    ReaderImageRepository? repository,
    EhentaiReaderDataSource? ehentaiDataSource,
    HeaderInspectorService? headerInspector,
    OfflineContentManager? offlineContentManager,
    Logger? logger,
  })  : _repository = repository,
        _ehentaiDataSource = ehentaiDataSource ?? EhentaiReaderDataSource(),
        _headerInspector = headerInspector,
        _offlineContentManager = offlineContentManager,
        _logger = logger ?? (getIt.isRegistered<Logger>() ? getIt<Logger>() : Logger());

  static ReaderImagePipeline? _instance;
  static ReaderImagePipeline get instance => _instance ??= ReaderImagePipeline();
  @visibleForTesting
  static set instance(ReaderImagePipeline? val) => _instance = val;

  final ReaderImageRepository? _repository;
  final EhentaiReaderDataSource _ehentaiDataSource;
  final HeaderInspectorService? _headerInspector;
  final OfflineContentManager? _offlineContentManager;
  final Logger _logger;

  ReaderImageRepository? get _effectiveRepository {
    if (_repository != null) return _repository;
    if (getIt.isRegistered<ReaderImageRepository>()) {
      return getIt<ReaderImageRepository>();
    }
    return null;
  }

  HeaderInspectorService? get _effectiveHeaderInspector {
    if (_headerInspector != null) return _headerInspector;
    if (getIt.isRegistered<HeaderInspectorService>()) {
      return getIt<HeaderInspectorService>();
    }
    return null;
  }

  OfflineContentManager? get _effectiveOfflineContentManager {
    if (_offlineContentManager != null) return _offlineContentManager;
    if (getIt.isRegistered<OfflineContentManager>()) {
      return getIt<OfflineContentManager>();
    }
    return null;
  }

  ReaderImageCancellation createCancellation() => ReaderImageCancellation();

  // ─────────────────────────────────────────────────────────────────────────
  // E-Hentai Scraping & Token Resolution
  // ─────────────────────────────────────────────────────────────────────────

  bool shouldResolveEhentai(String url, {String? sourceId}) =>
      _ehentaiDataSource.shouldResolve(url, sourceId: sourceId);

  Future<String?> resolveEhentaiImageUrl(
    String readerPageUrl, {
    Map<String, String>? headers,
    Map<String, dynamic>? rawConfig,
  }) =>
      _ehentaiDataSource.resolveImageUrl(
        readerPageUrl,
        headers: headers,
        rawConfig: rawConfig,
      );

  void invalidateEhentaiResolvedImageUrl(String readerPageUrl) =>
      _ehentaiDataSource.invalidate(readerPageUrl);

  // ─────────────────────────────────────────────────────────────────────────
  // MangaFire De-scrambling Binary Resolution
  // ─────────────────────────────────────────────────────────────────────────

  bool shouldResolveMangaFireImageBytes(String url, {String? sourceId}) {
    return sourceId == 'mangafire' && url.contains('#scrambled_');
  }

  Future<Uint8List?> resolveMangaFireImageBytes(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      return await KuronNative.instance.downloadBinary(
        url: url,
        headers: headers,
      );
    } catch (e) {
      _logger.w('[ReaderPipeline] Failed to resolve MangaFire bytes: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Download-first Page Image Resolution
  // ─────────────────────────────────────────────────────────────────────────

  Future<PageImageResult?> resolvePageToFile({
    required String url,
    required String contentId,
    required int pageNumber,
    String? sourceId,
    Map<String, String>? headers,
    ReaderImageCancellation? cancellation,
  }) async {
    final repo = _effectiveRepository;
    if (repo == null) return null;

    return repo.resolvePage(
      url: url,
      contentId: contentId,
      pageNumber: pageNumber,
      sourceId: sourceId,
      headers: headers,
      cancelToken: cancellation?.dioToken,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AVIF & Animated WebP Inspection & Conversion
  // ─────────────────────────────────────────────────────────────────────────

  static bool shouldConvertAvifToWebP(
    ({bool isAvif, bool isAvisBrand, int? width, int? height}) avifInfo,
  ) {
    if (!avifInfo.isAvif) {
      return false;
    }
    return avifInfo.isAvisBrand || (avifInfo.height ?? 0) > maxNativeAvifHeight;
  }

  static bool shouldConvertTallAvifFile(
    File file, {
    required bool nativeViewAvailable,
  }) {
    if (!nativeViewAvailable) {
      return false;
    }
    try {
      if (!file.existsSync()) {
        return false;
      }
      final avifInfo = inspectAvifHeaderForRouting(file);
      return avifInfo.isAvif && (avifInfo.height ?? 0) > maxNativeAvifHeight;
    } catch (_) {
      return false;
    }
  }

  static bool shouldMarkConvertedAvifHeavy({
    required bool isAvif,
    required bool isAvisBrand,
    required int? height,
  }) {
    if (!isAvif) {
      return false;
    }
    return isAvisBrand;
  }

  Future<bool> hasInvalidImagePayload(String localPath) async {
    RandomAccessFile? raf;
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return true;
      }
      final length = await file.length();
      if (length <= 0) {
        return true;
      }
      final sampleLength = length < 64 ? length : 64;
      raf = await file.open(mode: FileMode.read);
      final bytes = await raf.read(sampleLength);
      return inferImageExtension(bytes: bytes) == null;
    } catch (e) {
      _logger.w('[ReaderPipeline] Failed to validate local payload $localPath: $e');
      return true;
    } finally {
      try {
        await raf?.close();
      } catch (_) {}
    }
  }

  Future<void> deleteLocalPageFormatConflicts({
    required String currentImagePath,
    required String convertedPath,
  }) async {
    final directory = Directory(path.dirname(currentImagePath));
    if (!await directory.exists()) {
      return;
    }

    final targetBaseName = path.basenameWithoutExtension(currentImagePath);
    final normalizedConvertedPath = path.normalize(convertedPath);
    final tempPath = '$convertedPath.repairing';
    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }

      final normalizedCandidate = path.normalize(entity.path);
      if (normalizedCandidate == normalizedConvertedPath ||
          normalizedCandidate == path.normalize(tempPath)) {
        continue;
      }

      final extension = path.extension(entity.path).toLowerCase();
      if (!kReaderRepairSupportedImageExtensions.contains(extension)) {
        continue;
      }

      if (path.basenameWithoutExtension(entity.path) != targetBaseName) {
        continue;
      }

      try {
        await entity.delete();
      } catch (e) {
        _logger.w(
          '[ReaderPipeline] Failed deleting stale local page ${entity.path}: $e',
        );
      }
    }
  }

  Future<void> syncOfflineMetadataForConvertedLocalPage({
    required String contentId,
    required int pageNumber,
    required String originalLocalPath,
    required String convertedLocalPath,
  }) async {
    try {
      final manager = _effectiveOfflineContentManager;
      if (manager != null) {
        await manager.rewriteMetadataForConvertedLocalPage(
          contentId: contentId,
          pageNumber: pageNumber,
          originalLocalPath: originalLocalPath,
          convertedLocalPath: convertedLocalPath,
        );
      }
    } catch (e) {
      _logger.w(
        '[ReaderPipeline] Failed updating metadata for local conversion '
        'content=$contentId page=$pageNumber: $e',
      );
    }
  }

  Future<FileHeaderResult> inspectHeader(String path) {
    final inspector = _effectiveHeaderInspector;
    if (inspector != null) {
      return inspector.inspect(path);
    }
    return compute(inspectFileHeader, path);
  }

  Future<ProcessedImageResult> processImageFile({
    required String filePath,
    required String contentId,
    required int pageNumber,
    bool checkInvalidPayload = false,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProcessedImageResult(renderPath: filePath);
      }

      final fileSize = await file.length();
      if (fileSize <= 0) {
        return ProcessedImageResult(
          renderPath: filePath,
          shouldBypassLocalDecode: true,
        );
      }

      if (checkInvalidPayload && await hasInvalidImagePayload(filePath)) {
        return ProcessedImageResult(
          renderPath: filePath,
          shouldBypassLocalDecode: true,
        );
      }

      // Background / service header inspection
      inspectHeader(filePath);
      final avifInfo = inspectAvifHeaderForRouting(file);
      final shouldConvert = shouldConvertAvifToWebP(avifInfo);

      if (shouldConvert) {
        _logger.i(
          '[ReaderPipeline] Animated/tall AVIF detected. Converting to WebP '
          'page=$pageNumber height=${avifInfo.height}',
        );
        final outputPath = buildReplacementImagePath(
          currentImagePath: filePath,
          extension: 'webp',
        );
        final convertedPath = await KuronNative.instance.convertAvifToWebP(
          inputPath: filePath,
          outputPath: outputPath,
        );

        if (convertedPath != null) {
          final convertedFile = File(convertedPath);
          if (await convertedFile.exists() && await convertedFile.length() > 0) {
            await deleteLocalPageFormatConflicts(
              currentImagePath: filePath,
              convertedPath: convertedPath,
            );
            await syncOfflineMetadataForConvertedLocalPage(
              contentId: contentId,
              pageNumber: pageNumber,
              originalLocalPath: filePath,
              convertedLocalPath: convertedPath,
            );

            final markHeavy = shouldMarkConvertedAvifHeavy(
              isAvif: avifInfo.isAvif,
              isAvisBrand: avifInfo.isAvisBrand,
              height: avifInfo.height,
            );

            final webpHeader = inspectFileHeader(convertedPath);
            final nativeSize = (webpHeader.width != null && webpHeader.height != null)
                ? Size(webpHeader.width!.toDouble(), webpHeader.height!.toDouble())
                : (avifInfo.width != null && avifInfo.height != null)
                    ? Size(avifInfo.width!.toDouble(), avifInfo.height!.toDouble())
                    : null;

            final convertedLength = await convertedFile.length();
            _logger.i(
              '[ReaderPipeline] AVIF converted to WebP page=$pageNumber '
              'src=${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB '
              'out=${(convertedLength / 1024 / 1024).toStringAsFixed(1)} MB',
            );

            return ProcessedImageResult(
              renderPath: convertedPath,
              convertedPath: convertedPath,
              wasConverted: true,
              isHeavy: markHeavy,
              isConfirmedAnimatedWebP: markHeavy,
              nativeImageSize: nativeSize,
              imageBytes: convertedLength,
            );
          }
        }

        _logger.w('[ReaderPipeline] AVIF conversion failed page=$pageNumber');
        return ProcessedImageResult(renderPath: filePath);
      }

      // Check for animated WebP
      final header = inspectFileHeader(filePath);
      if (header.format != null) {
        final nativeSize = (header.width != null && header.height != null)
            ? Size(header.width!.toDouble(), header.height!.toDouble())
            : null;
        return ProcessedImageResult(
          renderPath: filePath,
          isHeavy: true,
          isConfirmedAnimatedWebP: true,
          nativeImageSize: nativeSize,
          imageBytes: fileSize,
        );
      }

      return ProcessedImageResult(
        renderPath: filePath,
        imageBytes: fileSize,
      );
    } catch (e) {
      _logger.w('[ReaderPipeline] Error processing $filePath: $e');
      return ProcessedImageResult(renderPath: filePath);
    }
  }

  Future<ProcessedImageResult?> preCheckDiskCache({
    required String imageUrl,
    required String contentId,
    required int pageNumber,
  }) async {
    try {
      final legacyFile = await DefaultCacheManager().getFileFromCache(imageUrl);
      if (legacyFile != null && await legacyFile.file.exists()) {
        return await processImageFile(
          filePath: legacyFile.file.path,
          contentId: contentId,
          pageNumber: pageNumber,
        );
      }

      final localPath = await LocalImagePreloader.getLocalImagePath(contentId, pageNumber);
      if (localPath != null) {
        final f = File(localPath);
        if (await f.exists() && await f.length() > 0) {
          return await processImageFile(
            filePath: localPath,
            contentId: contentId,
            pageNumber: pageNumber,
          );
        }
      }
    } catch (e) {
      _logger.w('[ReaderPipeline] Pre-check disk cache error: $e');
    }
    return null;
  }
}
