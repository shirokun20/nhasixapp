import '../entities/page_image_result.dart';

/// Single resolver for reader page images (download-first).
///
/// Every reader consumer (widget render, prefetch, repair, translation capture)
/// MUST go through this repository so image bytes always come from the same
/// transport (the source's own Dio, with rate-limit/bypass/headers) and are
/// always rendered from a local file — never fetched from the network directly
/// by a widget.
abstract class ReaderImageRepository {
  /// Resolve a reader page image to a local file, downloading it if needed.
  ///
  /// Resolution order (deterministic, mode-agnostic):
  /// offline download -> preloader cache -> cache-manager legacy -> network
  /// (streamed to the canonical location).
  ///
  /// [url] is the page image URL (or local path), [contentId]/[pageNumber]
  /// locate the canonical cache slot, and [sourceId]/[headers] carry the
  /// source-specific transport context for the download path.
  Future<PageImageResult> resolvePage({
    required String url,
    required String contentId,
    required int pageNumber,
    String? sourceId,
    Map<String, String>? headers,
  });
}
