/// Enum for different content list types
enum ContentListType {
  manga,
  manhua,
  manhwa,
  project,
  az,
  genre,
}

extension ContentListTypeExtension on ContentListType {
  /// Get base URL path for this list type
  String get basePath {
    switch (this) {
      case ContentListType.manga:
        return '/list-manga/';
      case ContentListType.manhua:
        return '/list-manhua/';
      case ContentListType.manhwa:
        return '/list-manhwa/';
      case ContentListType.project:
        return '/project/';
      case ContentListType.az:
        return '/a-z-list/';
      case ContentListType.genre:
        return '/genres/';
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case ContentListType.manga:
        return 'Manga';
      case ContentListType.manhua:
        return 'Manhua';
      case ContentListType.manhwa:
        return 'Manhwa';
      case ContentListType.project:
        return 'Project';
      case ContentListType.az:
        return 'A-Z List';
      case ContentListType.genre:
        return 'Genres';
    }
  }

  /// Whether this list type supports pagination
  bool get hasPagination {
    return this != ContentListType.genre;
  }

  /// Whether this list type has alphabet filter (A-Z list)
  bool get hasAlphabetFilter {
    return this == ContentListType.az;
  }
}
