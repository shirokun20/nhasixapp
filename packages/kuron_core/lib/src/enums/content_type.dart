/// Content type enumeration for multi-source support.
///
/// Maps to Tachiyomi's MangaType enum for cross-source compatibility.
enum ContentType {
  /// Standard Japanese doujinshi / adult comics
  doujinshi,

  /// Standard manga (serialized or oneshot)
  manga,

  /// Chinese comics
  manhua,

  /// Korean comics
  manhwa,

  /// Artist CG / illustration collections
  artistCG,

  /// Game CG / game illustration collections
  gameCG,

  /// Unknown or not specified
  unknown,
}

/// Publication status for chapter-based content.
///
/// Mirrors Tachiyomi's SManga status constants.
enum ContentStatus {
  /// Status not known
  unknown,

  /// Currently being published
  ongoing,

  /// Finished publication
  completed,

  /// Licensed and removed from source
  licensed,

  /// Publisher finished, no more chapters planned
  publishingFinished,

  /// Cancelled before completion
  cancelled,

  /// Temporarily on hold
  onHiatus,
}
