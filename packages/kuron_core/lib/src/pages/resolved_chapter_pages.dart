import 'package:equatable/equatable.dart';

import '../compat/validation_diagnostic.dart';
import 'resolved_page_request.dart';

/// Canonical resolved pages for a single chapter (or single-gallery content).
///
/// Produced by `PageResolutionPipeline` in `kuron_generic` (Section 5) and
/// consumed by both the reader and the native download payload builder.
/// Chapter-level headers/referer are shared by all pages unless the page
/// declares its own override on [ResolvedPageRequest.perPageHeaders] /
/// [ResolvedPageRequest.referer].
class ResolvedChapterPages extends Equatable {
  ResolvedChapterPages({
    required this.sourceId,
    required this.contentId,
    required List<ResolvedPageRequest> pages,
    this.chapterId,
    Map<String, String>? globalHeaders,
    this.referer,
    this.prevChapterId,
    this.nextChapterId,
    this.prevChapterTitle,
    this.nextChapterTitle,
    this.diagnostics = const <ValidationDiagnostic>[],
  })  : globalHeaders = Map<String, String>.unmodifiable(
            globalHeaders ?? const <String, String>{}),
        pages = List<ResolvedPageRequest>.unmodifiable(pages);

  final String sourceId;
  final String contentId;
  final String? chapterId;

  /// Headers shared by every page in this chapter.
  final Map<String, String> globalHeaders;

  /// Default referer shared by every page in this chapter.
  final String? referer;

  /// Pages in 1-based reading order.
  final List<ResolvedPageRequest> pages;

  final String? prevChapterId;
  final String? nextChapterId;
  final String? prevChapterTitle;
  final String? nextChapterTitle;

  final List<ValidationDiagnostic> diagnostics;

  /// True if every page is download-ready (final image URL known). When
  /// false, the download pipeline must reject the request and surface the
  /// missing-page diagnostics rather than attempting a partial download.
  bool get isDownloadReady =>
      pages.isNotEmpty &&
      pages.every((ResolvedPageRequest p) => p.isDownloadReady);

  /// Pages that still need further resolution (scrape or API hop) before
  /// they can be handed to the native downloader.
  List<ResolvedPageRequest> get unresolvedPages => pages
      .where((ResolvedPageRequest p) => !p.isDownloadReady)
      .toList(growable: false);

  /// Resolved per-page request with the chapter-level headers and referer
  /// merged in. The per-page values win on key collision. The returned
  /// object is a fresh [ResolvedPageRequest] safe to pass to a native
  /// download payload builder.
  ResolvedPageRequest mergedPage(int index) {
    final ResolvedPageRequest page = pages[index];
    final Map<String, String> merged = <String, String>{
      ...globalHeaders,
      ...page.perPageHeaders,
    };
    return page.copyWith(
      perPageHeaders: merged,
      referer: page.referer ?? referer,
    );
  }

  ResolvedChapterPages copyWith({
    String? sourceId,
    String? contentId,
    String? chapterId,
    Map<String, String>? globalHeaders,
    String? referer,
    List<ResolvedPageRequest>? pages,
    String? prevChapterId,
    String? nextChapterId,
    String? prevChapterTitle,
    String? nextChapterTitle,
    List<ValidationDiagnostic>? diagnostics,
  }) {
    return ResolvedChapterPages(
      sourceId: sourceId ?? this.sourceId,
      contentId: contentId ?? this.contentId,
      chapterId: chapterId ?? this.chapterId,
      globalHeaders: globalHeaders ?? this.globalHeaders,
      referer: referer ?? this.referer,
      pages: pages ?? this.pages,
      prevChapterId: prevChapterId ?? this.prevChapterId,
      nextChapterId: nextChapterId ?? this.nextChapterId,
      prevChapterTitle: prevChapterTitle ?? this.prevChapterTitle,
      nextChapterTitle: nextChapterTitle ?? this.nextChapterTitle,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'sourceId': sourceId,
        'contentId': contentId,
        if (chapterId != null) 'chapterId': chapterId,
        if (globalHeaders.isNotEmpty) 'globalHeaders': globalHeaders,
        if (referer != null) 'referer': referer,
        'pages': pages.map((ResolvedPageRequest p) => p.toJson()).toList(
              growable: false,
            ),
        if (prevChapterId != null) 'prevChapterId': prevChapterId,
        if (nextChapterId != null) 'nextChapterId': nextChapterId,
        if (prevChapterTitle != null) 'prevChapterTitle': prevChapterTitle,
        if (nextChapterTitle != null) 'nextChapterTitle': nextChapterTitle,
        if (diagnostics.isNotEmpty)
          'diagnostics':
              diagnostics.map((ValidationDiagnostic d) => d.toJson()).toList(
                    growable: false,
                  ),
      };

  @override
  List<Object?> get props => <Object?>[
        sourceId,
        contentId,
        chapterId,
        globalHeaders,
        referer,
        pages,
        prevChapterId,
        nextChapterId,
        prevChapterTitle,
        nextChapterTitle,
        diagnostics,
      ];
}
