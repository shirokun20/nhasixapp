/// Kind of resolved page request, used by reader and download pipelines to
/// decide how to fetch the actual bytes.
enum PageRequestKind {
  /// Final direct image URL is already known. Native or reader can fetch
  /// the bytes immediately with the resolved headers.
  directImage,

  /// A source page URL is known but the final image URL has to be
  /// resolved by scraping or running a plugin first.
  readerPage,

  /// The payload to send to an API endpoint is known. Used by sources
  /// where the image URL comes from an API response (e.g. a per-page POST).
  apiPayload,
}
