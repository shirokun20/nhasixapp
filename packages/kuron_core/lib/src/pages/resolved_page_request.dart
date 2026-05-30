import 'package:equatable/equatable.dart';

import '../compat/validation_diagnostic.dart';
import 'page_request_kind.dart';

/// Canonical page request shared by reader and download pipelines.
///
/// One [ResolvedPageRequest] represents a single page of a chapter or a
/// single-gallery content. It must contain enough information for the
/// native downloader to fetch bytes without re-running selectors or
/// JSONPath. If [kind] is not [PageRequestKind.directImage], the page
/// requires further resolution (typically a scraper hop or an API call)
/// before it can be passed to the native downloader.
class ResolvedPageRequest extends Equatable {
  ResolvedPageRequest({
    required this.pageNumber,
    required this.kind,
    this.finalImageUrl,
    this.sourcePageUrl,
    this.apiPayload,
    Map<String, String>? perPageHeaders,
    this.referer,
    this.filenameHint,
    this.mimeHint,
    this.diagnostics = const <ValidationDiagnostic>[],
  }) : perPageHeaders = Map<String, String>.unmodifiable(
            perPageHeaders ?? const <String, String>{});

  /// 1-based page number.
  final int pageNumber;

  /// What kind of request this is.
  final PageRequestKind kind;

  /// Final image URL. Required when [kind] is [PageRequestKind.directImage].
  final String? finalImageUrl;

  /// Source page URL. Required when [kind] is [PageRequestKind.readerPage]
  /// so the resolver knows where to fetch the per-page HTML/JSON from.
  final String? sourcePageUrl;

  /// API payload. Required when [kind] is [PageRequestKind.apiPayload].
  final Map<String, Object?>? apiPayload;

  /// Headers specific to this page that must override or augment the
  /// chapter-level headers. Use this for tokens/signed URLs that vary
  /// per page (e.g. e-hentai page tokens).
  final Map<String, String> perPageHeaders;

  /// Per-page referer override.
  final String? referer;

  /// Hint for the destination filename (without extension). Native may use
  /// this as a fallback when the URL does not encode a clean filename.
  final String? filenameHint;

  /// MIME type hint (e.g. `image/jpeg`). Optional; native may infer.
  final String? mimeHint;

  /// Per-page diagnostics. Already redacted.
  final List<ValidationDiagnostic> diagnostics;

  /// True when this page can be handed to the native downloader as-is
  /// (direct image with a final URL).
  bool get isDownloadReady =>
      kind == PageRequestKind.directImage &&
      finalImageUrl != null &&
      finalImageUrl!.isNotEmpty;

  ResolvedPageRequest copyWith({
    int? pageNumber,
    PageRequestKind? kind,
    String? finalImageUrl,
    String? sourcePageUrl,
    Map<String, Object?>? apiPayload,
    Map<String, String>? perPageHeaders,
    String? referer,
    String? filenameHint,
    String? mimeHint,
    List<ValidationDiagnostic>? diagnostics,
  }) {
    return ResolvedPageRequest(
      pageNumber: pageNumber ?? this.pageNumber,
      kind: kind ?? this.kind,
      finalImageUrl: finalImageUrl ?? this.finalImageUrl,
      sourcePageUrl: sourcePageUrl ?? this.sourcePageUrl,
      apiPayload: apiPayload ?? this.apiPayload,
      perPageHeaders: perPageHeaders ?? this.perPageHeaders,
      referer: referer ?? this.referer,
      filenameHint: filenameHint ?? this.filenameHint,
      mimeHint: mimeHint ?? this.mimeHint,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'pageNumber': pageNumber,
        'kind': kind.name,
        if (finalImageUrl != null) 'finalImageUrl': finalImageUrl,
        if (sourcePageUrl != null) 'sourcePageUrl': sourcePageUrl,
        if (apiPayload != null) 'apiPayload': apiPayload,
        if (perPageHeaders.isNotEmpty) 'perPageHeaders': perPageHeaders,
        if (referer != null) 'referer': referer,
        if (filenameHint != null) 'filenameHint': filenameHint,
        if (mimeHint != null) 'mimeHint': mimeHint,
        if (diagnostics.isNotEmpty)
          'diagnostics':
              diagnostics.map((ValidationDiagnostic d) => d.toJson()).toList(
                    growable: false,
                  ),
      };

  @override
  List<Object?> get props => <Object?>[
        pageNumber,
        kind,
        finalImageUrl,
        sourcePageUrl,
        apiPayload,
        perPageHeaders,
        referer,
        filenameHint,
        mimeHint,
        diagnostics,
      ];
}
