import 'dart:io';

import 'package:logger/logger.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;

import 'package:nhasixapp/core/services/local_image_preloader.dart';
import 'package:nhasixapp/core/services/request_deduplication_service.dart';
import 'package:nhasixapp/domain/entities/page_image_result.dart';
import 'package:nhasixapp/domain/repositories/reader_image_repository.dart';

/// Signature for a streaming network image download that returns the canonical
/// local path on success, or null on failure/cancellation.
typedef ReaderImageNetworkDownload = Future<String?> Function({
  required String url,
  required String contentId,
  required int pageNumber,
  Map<String, String>? headers,
});

/// Signature for a legacy-cache lookup that returns a file path or null.
typedef ReaderImageLegacyLookup = Future<String?> Function(String url);

/// Default streaming download implementation — writes to the canonical cache
/// slot (same location [LocalImagePreloader.getLocalImagePath] scans), so the
/// very next pass reads from disk with zero network.
Future<String?> _defaultStreamingDownload({
  required String url,
  required String contentId,
  required int pageNumber,
  Map<String, String>? headers,
}) {
  return LocalImagePreloader.downloadAndCacheImageStreaming(
    url,
    contentId,
    pageNumber,
    headers: headers,
  );
}

/// Default legacy lookup — reads the old flutter_cache_manager cache (kept for
/// lazy migration so users do not lose their existing cache after an update).
Future<String?> _defaultLegacyLookup(String url) async {
  try {
    final file = await DefaultCacheManager().getSingleFile(url);
    if (file.existsSync()) return file.path;
  } catch (_) {}
  return null;
}
/// Download-first resolver for reader page images.
///
/// Deterministic resolution order (mode-agnostic, no cross-session in-memory
/// routing state):
///   1. offline download / preloader cache
///   2. cache-manager legacy (lazily migrated to the canonical location)
///   3. network download, streamed straight to the canonical location
/// Plus a per-URL in-flight dedup gate shared across all subsystems.
class ReaderImageRepositoryImpl implements ReaderImageRepository {
  ReaderImageRepositoryImpl({
    required Logger logger,
    RequestDeduplicationService? dedup,
    ReaderImageNetworkDownload? networkDownload,
    ReaderImageLegacyLookup? legacyLookup,
  })  : _logger = logger,
        _dedup = dedup ?? RequestDeduplicationService(),
        _networkDownload = networkDownload ?? _defaultStreamingDownload,
        _legacyLookup = legacyLookup ?? _defaultLegacyLookup;

  final Logger _logger;
  final RequestDeduplicationService _dedup;
  final ReaderImageNetworkDownload _networkDownload;
  final ReaderImageLegacyLookup _legacyLookup;

  @override
  Future<PageImageResult> resolvePage({
    required String url,
    required String contentId,
    required int pageNumber,
    String? sourceId,
    Map<String, String>? headers,
  }) async {
    // 0) The URL is already a local file path — nothing to resolve.
    if (!url.startsWith('http') &&
        (url.startsWith('/') || url.startsWith('file://'))) {
      final localPath = url.replaceFirst('file://', '');
      final file = File(localPath);
      if (await _fileExists(file)) {
        return ReadyFromDisk(path: localPath);
      }
      return FailedPage(
          reason: 'local file not found: $localPath', originalUrl: url);
    }

    // 1) Offline download / preloader cache.
    try {
      final localPath =
          await LocalImagePreloader.getLocalImagePath(contentId, pageNumber);
      if (localPath != null && await _fileExists(File(localPath))) {
        _logger.i(
            '[ReaderImage] disk hit content=$contentId page=$pageNumber -> $localPath');
        return ReadyFromDisk(path: localPath);
      }
    } catch (e) {
      _logger.w('[ReaderImage] preloader lookup failed: $e');
    }

    // 2) Legacy cache manager (lazy migration).
    try {
      final legacyPath = await _legacyLookup(url);
      if (legacyPath != null && await _fileExists(File(legacyPath))) {
        final migrated = await _migrateToCanonical(
          legacyPath: legacyPath,
          contentId: contentId,
          pageNumber: pageNumber,
        );
        _logger.i('[ReaderImage] legacy migrated -> ${migrated ?? legacyPath}');
        return ReadyFromDisk(path: migrated ?? legacyPath, legacy: true);
      }
    } catch (e) {
      _logger.w('[ReaderImage] legacy lookup failed: $e');
    }

    // 3) Network download (deduped + streamed to canonical).
    final requestKey = 'pageimg:$url';
    final deduped = _dedup.deduplicate<String?>(requestKey, () {
      return _networkDownload(
        url: url,
        contentId: contentId,
        pageNumber: pageNumber,
        headers: headers,
      );
    });

    try {
      final path = await deduped.timeout(const Duration(seconds: 45));
      if (path != null && await _fileExists(File(path))) {
        _logger.i('[ReaderImage] network OK -> $path');
        return ReadyFresh(path: path);
      }
      return FailedPage(
          reason: 'download produced no file for $url', originalUrl: url);
    } catch (e) {
      _logger.w('[ReaderImage] network fail $url: $e');
      return FailedPage(reason: e, originalUrl: url);
    }
  }

  /// Copies a legacy cache file into the canonical cache slot so the next
  /// resolution is a disk hit. Non-fatal on any copy error.
  Future<String?> _migrateToCanonical({
    required String legacyPath,
    required String contentId,
    required int pageNumber,
  }) async {
    try {
      final imagesDir =
          Directory(await LocalImagePreloader.getImagesFolderPath(contentId));
      await imagesDir.create(recursive: true);
      final extension = p.extension(legacyPath);
      final target = '${imagesDir.path}/page_$pageNumber$extension';
      if (legacyPath != target && !await _fileExists(File(target))) {
        await File(legacyPath).copy(target);
      }
      return await _fileExists(File(target)) ? target : null;
    } catch (e) {
      _logger.w('[ReaderImage] lazy migration failed: $e');
      return null;
    }
  }
}

/// Async file-existence helper (keeps the resolver free of repeated try/catch).
Future<bool> _fileExists(File file) async {
  try {
    return await file.exists();
  } catch (_) {
    return false;
  }
}