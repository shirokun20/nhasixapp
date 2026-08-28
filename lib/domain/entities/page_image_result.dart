// Reader page image resolution result (download-first).
//
// A sealed hierarchy so every call site MUST handle all outcomes exhaustively:
// there is no silent "blank" or implicit network fallback in the render path.
// Widgets render purely from a local file; they never touch the network.
sealed class PageImageResult {
  const PageImageResult();
}

/// Image is already available on disk (offline download / preloader cache /
/// cache-manager legacy / a previous round-trip) and can be rendered directly
/// without any network request.
class ReadyFromDisk extends PageImageResult {
  const ReadyFromDisk({required this.path, this.legacy = false});

  /// Absolute path of the local file to render.
  final String path;

  /// True when the file came from a legacy cache that is being lazily migrated
  /// to the canonical location (i.e. a copy is being written for next time).
  final bool legacy;
}

/// Image was just downloaded (streamed) to its canonical location and is ready
/// to render from that file.
class ReadyFresh extends PageImageResult {
  const ReadyFresh({required this.path});

  /// Absolute path of the freshly downloaded local file.
  final String path;
}

/// Resolution or download failed. Carries the reason and the original URL so
/// the caller can show an explicit retry action (never a silent blank).
class FailedPage extends PageImageResult {
  const FailedPage({required this.reason, this.originalUrl});

  /// Human/typed reason for the failure (e.g. a [DioException]).
  final Object reason;

  /// Original image URL, preserved so a repair/retry flow can be re-attempted.
  final String? originalUrl;
}
