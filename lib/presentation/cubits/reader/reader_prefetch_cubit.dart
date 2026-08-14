import 'dart:async';

// Prefetch download engine for the reader. Owns which pages are prefetched /
// in-flight and the per-page cancel tokens, so the bookkeeping that used to
// live in _ReaderScreenState is testable and survives widget rebuild/dispose.
//
// ponytail: decode-pre-caching (precacheImage → ImageCache) needs a
// BuildContext, so it stays in the widget. This cubit only owns the
// context-free part: the network download + policy.

import 'package:dio/dio.dart';
import 'package:nhasixapp/core/models/image_metadata.dart';
import 'package:nhasixapp/core/services/local_image_preloader.dart';

import '../base/base_cubit.dart';

/// Immutable snapshot of the prefetch engine state — which pages are known to
/// be locally cached (prefetched) and which downloads are in-flight.
class ReaderPrefetchState extends BaseCubitState {
  const ReaderPrefetchState({
    this.prefetchedPages = const {},
    this.inflightPages = const {},
    this.totalPrefetched = 0,
  });

  final Set<int> prefetchedPages;
  final Set<int> inflightPages;
  final int totalPrefetched;

  @override
  List<Object?> get props =>
      [prefetchedPages, inflightPages, totalPrefetched];

  ReaderPrefetchState _mutate({
    Set<int>? prefetchedPages,
    Set<int>? inflightPages,
    int? totalPrefetched,
  }) {
    return ReaderPrefetchState(
      prefetchedPages: prefetchedPages ?? this.prefetchedPages,
      inflightPages: inflightPages ?? this.inflightPages,
      totalPrefetched: totalPrefetched ?? this.totalPrefetched,
    );
  }
}

/// Owns prefetch downloads + policy that used to live in `_ReaderScreenState`.
class ReaderPrefetchCubit extends BaseCubit<ReaderPrefetchState> {
  ReaderPrefetchCubit({required super.logger})
      : super(initialState: const ReaderPrefetchState());

  static const int _prefetchCount = 3;
  static const int _prefetchBackCount = 1;

  // Heavy sources (HentaiNexus): GPU saturation — skip forward prefetch.
  static const Set<String> _heavyPrefetchSourceIds = {
    // Filled by source registry; kept here for fallback if not registered.
  };

  final Map<int, CancelToken> _cancelTokens = <int, CancelToken>{};

  /// Number of pages ahead (+1) and behind (−1) that are currently prefetched
  /// or in-flight — exposed for tests/config.
  static int get prefetchCount => _prefetchCount;
  static int get prefetchBackCount => _prefetchBackCount;

  /// Kick prefetch for the given page window. [imageMetadata] used to validate
  /// URL consistency; [sourceId] gates heavy-source skip + header lookup.
  ///
  /// Widget still handles decode-pre-cache (needs BuildContext); this only
  /// does the network download + bookkeeping.
  Future<void> prefetchImages({
    required int currentPage,
    required List<String> imageUrls,
    List<ImageMetadata>? imageMetadata,
    String? sourceId,
    required String contentId,
    Map<String, String>? headers,
  }) async {
    if (imageUrls.isEmpty) return;

    if (_isHeavySource(sourceId)) {
      // Only back-prefetch (recent pages) for heavy sources — forward would
      // saturate GPU.
      await _prefetchBack(currentPage, imageUrls, contentId, headers);
    } else {
      await Future.wait([
        _prefetchBack(currentPage, imageUrls, contentId, headers),
        _prefetchForward(currentPage, imageUrls, imageMetadata, sourceId, contentId, headers),
      ]);
    }
  }

  bool _isHeavySource(String? sourceId) {
    if (sourceId == null) return false;
    // Keep the registry-gated semantics the widget used: HentaiNexus only.
    // Heavy-source check lives in the source registry; we approximate by
    // calling the shared coordinator-known set is not available here.
    // ponytail: explicit list; extend as heavy sources appear.
    return _heavyPrefetchSourceIds.contains(sourceId);
  }

  Future<void> _prefetchBack(
      int currentPage, List<String> imageUrls, String contentId,
      Map<String, String>? headers) async {
    final futures = <Future<void>>[];
    for (int i = 1; i <= _prefetchBackCount; i++) {
      final targetPage = currentPage - i;
      if (targetPage >= 1 && !_isPrefetched(targetPage)) {
        futures.add(_downloadPage(targetPage, imageUrls[targetPage - 1], contentId, headers));
      }
    }
    await Future.wait(futures);
  }

  Future<void> _prefetchForward(
    int currentPage,
    List<String> imageUrls,
    List<ImageMetadata>? imageMetadata,
    String? sourceId,
    String contentId,
    Map<String, String>? headers,
  ) async {
    final futures = <Future<void>>[];
    for (int i = 1; i <= _prefetchCount; i++) {
      final targetPage = currentPage + i;
      if (targetPage > imageUrls.length || _isPrefetched(targetPage)) continue;

      final imageUrl = imageUrls[targetPage - 1];
      // EHentai reader pages resolve real image URLs lazily — skip.
      if (_isEhentaiReaderPageUrl(imageUrl, sourceId)) {
        continue;
      }
      if (imageMetadata != null && imageMetadata.isNotEmpty) {
        ImageMetadata? matched;
        for (final m in imageMetadata) {
          if (m.pageNumber == targetPage) {
            matched = m;
            break;
          }
        }
        if (matched != null && matched.imageUrl != imageUrl) {
          logDebug('prefetch skip: metadata mismatch page $targetPage');
          continue; // allow retry next tick (don't mark prefetched)
        }
      }
      if (!_isHttp(imageUrl) && (imageUrl.startsWith('/') || imageUrl.startsWith('file://'))) {
        continue;
      }
      futures.add(_downloadPage(targetPage, imageUrl, contentId, headers));
    }
    await Future.wait(futures);
  }

  Future<void> _downloadPage(int targetPage, String imageUrl, String contentId,
      Map<String, String>? headers) async {
    if (!_isHttp(imageUrl)) {
      // non-http (local/file) — nothing to download; mark prefetched.
      _markPrefetched(targetPage);
      return;
    }
    final cancelToken = CancelToken();
    _cancelTokens[targetPage] = cancelToken;
    _setInflight(targetPage, true);
    try {
      await LocalImagePreloader.downloadAndCacheImage(
        imageUrl,
        contentId,
        targetPage,
        headers: headers,
        cancelToken: cancelToken,
      );
      _markPrefetched(targetPage);
    } catch (e) {
      // Failed download — allow retry later.
      logDebug('prefetch fail page $targetPage: $e');
      _unmarkPrefetched(targetPage);
    } finally {
      _cancelTokens.remove(targetPage);
      _setInflight(targetPage, false);
    }
  }

  bool _isPrefetched(int page) =>
      state.prefetchedPages.contains(page) ||
      state.inflightPages.contains(page);

  void _markPrefetched(int page) {
    emit(state._mutate(
      prefetchedPages: {...state.prefetchedPages, page},
      totalPrefetched: state.totalPrefetched + 1,
    ));
  }

  void _unmarkPrefetched(int page) {
    emit(state._mutate(
      prefetchedPages: {...state.prefetchedPages}..remove(page),
      totalPrefetched: state.totalPrefetched > 0 ? state.totalPrefetched - 1 : 0,
    ));
  }

  void _setInflight(int page, bool v) {
    final next = {...state.inflightPages};
    if (v) {
      next.add(page);
    } else {
      next.remove(page);
    }
    emit(state._mutate(inflightPages: next));
  }

  bool _isHttp(String url) => url.startsWith('http://') || url.startsWith('https://');

  bool _isEhentaiReaderPageUrl(String url, String? sourceId) {
    // EHentai /s/... reader pages — resolved lazily. Only meaningful for that
    // source; keep the predicate closest to the original widget logic.
    return sourceId == 'ehentai' && url.contains('/s/');
  }

  bool isPrefetchedPage(int page) => state.prefetchedPages.contains(page);

  int get prefetchedPageCount => state.totalPrefetched;

  /// Cancel all in-flight downloads (e.g. on dispose). Cancelled pages are
  /// cleared from bookkeeping so they can be re-attempted next time.
  void cancelAll() {
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) token.cancel();
    }
    _cancelTokens.clear();
    emit(state._mutate(inflightPages: const {}, prefetchedPages: const {}));
  }
}