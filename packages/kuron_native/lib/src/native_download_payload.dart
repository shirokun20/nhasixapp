/// Native download payload model (Section 7.1).
///
/// Bridges the canonical [ResolvedChapterPages] (from kuron_generic) to the
/// native WorkManager download worker without requiring kuron_native to depend
/// on kuron_core or kuron_generic.
///
/// ## v2 payload (canonical, per-page headers)
///
/// ```dart
/// final payload = NativeDownloadPayload.fromResolved(
///   contentId: content.id,
///   sourceId: source.id,
///   pages: resolvedPages,
///   destinationPath: destPath,
///   title: content.title,
/// );
/// await NativeDownloadService().startDownloadV2(payload);
/// ```
///
/// ## v1 payload (legacy URL-list, still supported)
///
/// Apps using the old `imageUrls: List<String>` API still work — the native
/// worker parses both formats via the presence of the `perPageHeaders` field.
library;

import 'dart:convert';

/// Per-page item in a v2 download payload.
class NativeDownloadPage {
  const NativeDownloadPage({
    required this.pageNumber,
    required this.url,
    this.headers = const <String, String>{},
    this.referer,
    this.filenameHint,
    this.mimeHint,
  });

  final int pageNumber;
  final String url;
  final Map<String, String> headers;
  final String? referer;
  final String? filenameHint;
  final String? mimeHint;

  Map<String, Object?> toJson() => <String, Object?>{
        'pageNumber': pageNumber,
        'url': url,
        if (headers.isNotEmpty) 'headers': headers,
        if (referer != null) 'referer': referer,
        if (filenameHint != null) 'filenameHint': filenameHint,
        if (mimeHint != null) 'mimeHint': mimeHint,
      };

  factory NativeDownloadPage.fromJson(Map<String, Object?> map) {
    return NativeDownloadPage(
      pageNumber: map['pageNumber'] as int? ?? 0,
      url: map['url']?.toString() ?? '',
      headers: map['headers'] is Map
          ? (map['headers']! as Map).cast<String, String>()
          : const <String, String>{},
      referer: map['referer']?.toString(),
      filenameHint: map['filenameHint']?.toString(),
      mimeHint: map['mimeHint']?.toString(),
    );
  }
}

/// Canonical download payload (v2 — canonical, supports per-page headers).
///
/// Serializes to a JSON map that is accepted by both the Dart
/// [NativeDownloadService] and the Kotlin [DownloadWorker]:
///
/// - New worker reads `perPagePayload` (JSON array of [NativeDownloadPage]).
/// - Old worker falls back to `imageUrls` (plain string list) when
///   `perPagePayload` is absent.
class NativeDownloadPayload {
  const NativeDownloadPayload({
    required this.contentId,
    required this.sourceId,
    required this.destinationPath,
    required this.pages,
    this.globalHeaders = const <String, String>{},
    this.title,
    this.coverUrl,
    this.language,
    this.startPage,
    this.endPage,
    this.totalPages,
    this.enableNotifications = true,
    this.backupFolderName = 'nhasix',
    this.maxParallelImages = 3,
    this.imageTimeoutMs = 60000,
    this.cookies = const <String, String>{},
  });

  final String contentId;
  final String sourceId;
  final String destinationPath;
  final List<NativeDownloadPage> pages;
  final Map<String, String> globalHeaders;

  // Metadata
  final String? title;
  final String? coverUrl;
  final String? language;
  final int? startPage;
  final int? endPage;
  final int? totalPages;
  final bool enableNotifications;
  final String backupFolderName;
  final int maxParallelImages;
  final int imageTimeoutMs;
  final Map<String, String> cookies;

  // ── Convenience getters ────────────────────────────────────────────────────

  /// Legacy flat URL list (v1 compat) — only ready pages, in order.
  List<String> get imageUrls => pages
      .where((NativeDownloadPage p) => p.url.isNotEmpty)
      .map((NativeDownloadPage p) => p.url)
      .toList(growable: false);

  // ── Serialization ──────────────────────────────────────────────────────────

  /// Serialize to the method-channel map sent to native.
  ///
  /// Includes both `imageUrls` (v1 compat) and `perPagePayload` (v2).
  Map<String, Object?> toChannelMap() => <String, Object?>{
        'contentId': contentId,
        'sourceId': sourceId,
        'destinationPath': destinationPath,
        // v1 legacy field — kept for backward compat with old native worker.
        'imageUrls': imageUrls,
        // v2 per-page payload (JSON-encoded for WorkData compatibility).
        'perPagePayload': jsonEncode(
          pages
              .map((NativeDownloadPage p) => p.toJson())
              .toList(growable: false),
        ),
        if (globalHeaders.isNotEmpty) 'headers': jsonEncode(globalHeaders),
        if (cookies.isNotEmpty) 'cookies': jsonEncode(cookies),
        'title': title,
        'coverUrl': coverUrl,
        'language': language,
        'startPage': startPage,
        'endPage': endPage,
        'totalPages': totalPages ?? pages.length,
        'enableNotifications': enableNotifications,
        'backupFolderName': backupFolderName,
        'maxParallelImages': maxParallelImages,
        'imageTimeoutMs': imageTimeoutMs,
      };
}
