import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/utils/download_storage_utils.dart';
import 'package:nhasixapp/core/services/local_image_preloader.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/core/utils/title_parser_utils.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/usecases/history/get_history_usecase.dart';
import 'package:nhasixapp/domain/usecases/history/get_all_chapter_history_usecase.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';

// Cache for download status to prevent repeated file system checks
// Public class to allow cache invalidation from other components
// FIXED: Use DownloadBloc state as single source of truth to prevent false positives
class ContentDownloadCache {
  static final Map<String, bool> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, Set<String>> _sourceOfflineIdsCache = {};
  static final Map<String, DateTime> _sourceOfflineIdsCacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const String _ehentaiPartPrefix = '__ehpart__:';
  static const String _ehentaiChunkPrefix = '__ehchunk__:';

  static String _buildCacheKey(String contentId, String? sourceId) {
    final normalizedSource = (sourceId ?? '').trim().toLowerCase();
    return '$normalizedSource::$contentId';
  }

  static bool matchesDownload(
    DownloadStatus download,
    String contentId, {
    String? sourceId,
  }) {
    final normalizedSource = (sourceId ?? '').trim().toLowerCase();
    final downloadSource = (download.sourceId ?? '').trim().toLowerCase();

    if (normalizedSource.isNotEmpty && downloadSource != normalizedSource) {
      return false;
    }

    return _matchesDownloadedContentId(
      download.contentId,
      contentId,
    );
  }

  static bool _matchesDownloadedContentId(
    String downloadedContentId,
    String contentId,
  ) {
    final normalizedDownloadId = _normalizeContentId(downloadedContentId);
    final normalizedContentId = _normalizeContentId(contentId);

    if (normalizedDownloadId.isEmpty || normalizedContentId.isEmpty) {
      return false;
    }

    if (normalizedDownloadId == normalizedContentId) {
      return true;
    }

    final ehentaiParentId = _ehentaiParentGalleryId(normalizedDownloadId);
    if (ehentaiParentId != null &&
        _normalizeContentId(ehentaiParentId) == normalizedContentId) {
      return true;
    }

    if (_matchesSlugChapterDownload(
      normalizedDownloadId,
      normalizedContentId,
    )) {
      return true;
    }

    final parentIdFromUrl = _extractParentContentIdFromUrl(downloadedContentId);
    if (parentIdFromUrl != null &&
        _normalizeContentId(parentIdFromUrl) == normalizedContentId) {
      return true;
    }

    // Chapter-based sources keep completed download IDs as composite values
    // like "slug/17". Highlight the parent series card when any descendant
    // chapter under the same source has been downloaded.
    return normalizedDownloadId.startsWith('$normalizedContentId/');
  }

  static String _normalizeContentId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'^/+|/+$'), '');
  }

  static String? _ehentaiParentGalleryId(String contentId) {
    if (!contentId.startsWith(_ehentaiPartPrefix) &&
        !contentId.startsWith(_ehentaiChunkPrefix)) {
      return null;
    }

    final parts = contentId.split(':');
    if (parts.length < 3 || parts[1].isEmpty || parts[2].isEmpty) {
      return null;
    }

    return '${parts[1]}/${parts[2]}';
  }

  static bool _matchesSlugChapterDownload(
    String downloadContentId,
    String contentId,
  ) {
    final normalizedDownloadId = downloadContentId.trim().toLowerCase();
    final normalizedContentId = contentId.trim().toLowerCase();
    if (normalizedDownloadId.isEmpty || normalizedContentId.isEmpty) {
      return false;
    }

    final pattern = RegExp(
      '^${RegExp.escape(normalizedContentId)}-(?:chapter|ch)-.+\$',
    );
    return pattern.hasMatch(normalizedDownloadId);
  }

  static String? _extractParentContentIdFromUrl(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return null;
    }

    List<String> segments;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      final uri = Uri.tryParse(normalized);
      if (uri == null) {
        return null;
      }
      segments =
          uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    } else {
      segments = normalized
          .replaceFirst(RegExp(r'^/+'), '')
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
    }

    if (segments.length >= 2 && segments.first == 'read') {
      return segments[1];
    }
    if (segments.length >= 2 && segments.first == 'manga') {
      return segments[1];
    }
    if (segments.length >= 2 && segments.first == 'title') {
      return segments[1];
    }
    return null;
  }

  static Future<bool> isDownloaded(
    String contentId, {
    String? sourceId,
    bool allowFilesystemFallback = true,
    BuildContext? context,
  }) async {
    final cacheKey = _buildCacheKey(contentId, sourceId);

    // Priority 1 - Read DownloadBloc state when available.
    if (context != null && context.mounted) {
      try {
        final downloadState = context.read<DownloadBloc>().state;
        if (downloadState is DownloadLoaded) {
          final isDownloaded = downloadState.downloads.any(
            (download) =>
                download.state == DownloadState.completed &&
                matchesDownload(
                  download,
                  contentId,
                  sourceId: sourceId,
                ),
          );

          if (isDownloaded) {
            _cache[cacheKey] = true;
            _cacheTime[cacheKey] = DateTime.now();
            return true;
          }

          if (!allowFilesystemFallback) {
            _cache[cacheKey] = false;
            _cacheTime[cacheKey] = DateTime.now();
            return false;
          }
        } else if (!allowFilesystemFallback) {
          if (_cache.containsKey(cacheKey)) {
            final cacheTime = _cacheTime[cacheKey];
            if (cacheTime != null &&
                DateTime.now().difference(cacheTime) < _cacheExpiry) {
              return _cache[cacheKey]!;
            }
          }
          return false;
        }
      } catch (e) {
        Logger().w(
          'Failed to read DownloadBloc state, falling back to cached/filesystem check: $e',
        );
      }
    }

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final cacheTime = _cacheTime[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _cache[cacheKey]!;
      }
    }

    bool isDownloaded = false;

    // Priority 2 - Fallback to filesystem check only when DownloadBloc is not reachable.
    try {
      isDownloaded = await LocalImagePreloader.isContentDownloaded(contentId);

      if (allowFilesystemFallback &&
          !isDownloaded &&
          sourceId != null &&
          sourceId.trim().isNotEmpty) {
        final offlineIds = await _getOfflineContentIdsForSource(sourceId);
        isDownloaded = offlineIds.any(
          (offlineId) => _matchesDownloadedContentId(offlineId, contentId),
        );
      }

      _cache[cacheKey] = isDownloaded;
      _cacheTime[cacheKey] = DateTime.now();

      return isDownloaded;
    } catch (e) {
      _cache[cacheKey] = false;
      _cacheTime[cacheKey] = DateTime.now();
      return false;
    }
  }

  // Invalidate cache for specific content to force refresh
  static void invalidateCache(String contentId, {String? sourceId}) {
    if (sourceId != null) {
      final cacheKey = _buildCacheKey(contentId, sourceId);
      _cache.remove(cacheKey);
      _cacheTime.remove(cacheKey);
      _sourceOfflineIdsCache.remove(sourceId.trim().toLowerCase());
      _sourceOfflineIdsCacheTime.remove(sourceId.trim().toLowerCase());
      return;
    }

    final suffix = '::$contentId';
    final keysToRemove =
        _cache.keys.where((key) => key.endsWith(suffix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTime.remove(key);
    }
    _sourceOfflineIdsCache.clear();
    _sourceOfflineIdsCacheTime.clear();
  }

  // Clear all cache entries
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    _sourceOfflineIdsCache.clear();
    _sourceOfflineIdsCacheTime.clear();
  }

  static Future<Set<String>> _getOfflineContentIdsForSource(
    String sourceId,
  ) async {
    final normalizedSource = sourceId.trim().toLowerCase();
    if (normalizedSource.isEmpty) {
      return const <String>{};
    }

    final cachedAt = _sourceOfflineIdsCacheTime[normalizedSource];
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheExpiry &&
        _sourceOfflineIdsCache.containsKey(normalizedSource)) {
      return _sourceOfflineIdsCache[normalizedSource]!;
    }

    try {
      final sourceDirectory =
          await DownloadStorageUtils.getSourceDirectory(sourceId: sourceId);
      final offlineContents = await getIt<OfflineContentManager>()
          .scanBackupFolder(sourceDirectory);
      final ids = offlineContents
          .where((content) =>
              content.sourceId.trim().toLowerCase() == normalizedSource)
          .map((content) => content.id)
          .toSet();
      _sourceOfflineIdsCache[normalizedSource] = ids;
      _sourceOfflineIdsCacheTime[normalizedSource] = DateTime.now();
      return ids;
    } catch (_) {
      return const <String>{};
    }
  }
}

// Cache for read status to avoid repeated history lookups per card build.
class ContentReadCache {
  static final Map<String, double?> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static Future<List<History>>? _recentHistoryFuture;
  static DateTime? _recentHistoryCacheTime;

  static String _buildCacheKey(String contentId, String? sourceId) {
    final normalizedSource = (sourceId ?? '').trim().toLowerCase();
    return '$normalizedSource::$contentId';
  }

  static bool _isValidProgress(History history, String? sourceId) {
    if (sourceId != null &&
        sourceId.trim().isNotEmpty &&
        history.sourceId.trim().toLowerCase() !=
            sourceId.trim().toLowerCase()) {
      return false;
    }
    return history.isCompleted || history.progress > 0;
  }

  static double _normalizeProgress(History history) {
    if (history.isCompleted) return 1.0;
    return history.progress.clamp(0.0, 1.0);
  }

  static Future<double?> readProgress(
    Content content,
  ) async {
    final contentId = content.id;
    final sourceId = content.sourceId;
    final cacheKey = _buildCacheKey(contentId, sourceId);

    if (_cache.containsKey(cacheKey)) {
      final cacheTime = _cacheTime[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _cache[cacheKey];
      }
    }

    try {
      final getHistoryUseCase = getIt<GetHistoryUseCase>();
      final getAllChapterHistory = getIt<GetAllChapterHistoryUseCase>();

      List<History> recentHistory;
      if (_recentHistoryFuture != null &&
          _recentHistoryCacheTime != null &&
          DateTime.now().difference(_recentHistoryCacheTime!) <
              const Duration(seconds: 10)) {
        recentHistory = await _recentHistoryFuture!;
      } else {
        _recentHistoryFuture = getHistoryUseCase(GetHistoryParams(limit: 100));
        _recentHistoryCacheTime = DateTime.now();
        recentHistory = await _recentHistoryFuture!;
      }

      History? matchedHistory;
      for (final item in recentHistory) {
        if (item.contentId == contentId && _isValidProgress(item, sourceId)) {
          matchedHistory = item;
          break;
        }
      }

      if (matchedHistory != null) {
        final progress = _normalizeProgress(matchedHistory);
        _cache[cacheKey] = progress;
        _cacheTime[cacheKey] = DateTime.now();
        return progress;
      }

      final cardBaseTitle =
          TitleParserUtils.getBaseTitle(content.getDisplayTitle())
              .toLowerCase();

      for (final item in recentHistory) {
        if (sourceId.isNotEmpty &&
            item.sourceId.trim().toLowerCase() != sourceId.toLowerCase()) {
          continue;
        }

        final historyTitle = item.title?.trim();
        if (historyTitle == null || historyTitle.isEmpty) continue;
        if (TitleParserUtils.getBaseTitle(historyTitle).toLowerCase() ==
            cardBaseTitle) {
          matchedHistory = item;
          break;
        }
      }
      if (matchedHistory != null &&
          _isValidProgress(matchedHistory, sourceId)) {
        final progress = _normalizeProgress(matchedHistory);
        _cache[cacheKey] = progress;
        _cacheTime[cacheKey] = DateTime.now();
        return progress;
      }

      final chapterHistory = await getAllChapterHistory(contentId);
      final chapterProgress = chapterHistory
          .where((item) => _isValidProgress(item, sourceId))
          .map(_normalizeProgress)
          .fold<double?>(null, (previous, value) {
        if (previous == null || value > previous) return value;
        return previous;
      });
      if (chapterProgress != null) {
        _cache[cacheKey] = chapterProgress;
        _cacheTime[cacheKey] = DateTime.now();
        return chapterProgress;
      }
    } catch (e) {
      Logger().w('Failed to resolve read progress for $contentId: $e');
    }

    _cache[cacheKey] = null;
    _cacheTime[cacheKey] = DateTime.now();
    return null;
  }

  static void invalidateCache(String contentId, {String? sourceId}) {
    if (sourceId != null) {
      final cacheKey = _buildCacheKey(contentId, sourceId);
      _cache.remove(cacheKey);
      _cacheTime.remove(cacheKey);
      return;
    }

    final suffix = '::$contentId';
    final keysToRemove =
        _cache.keys.where((key) => key.endsWith(suffix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTime.remove(key);
    }
  }

  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }
}
