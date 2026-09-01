import 'package:equatable/equatable.dart';

// Entity representing a chapter in a manga/doujinshi
class Chapter extends Equatable {
  const Chapter({
    required this.id,
    required this.title,
    required this.url,
    this.uploadDate,
    this.scanGroup,
    this.language,
    this.externalUrl,
    this.pages,
    this.isUnavailable = false,
  });

  // Unique identifier (usually slug or ID)
  final String id;

  // Chapter title (e.g. "Chapter 1")
  final String title;

  // Chapter URL or Slug for fetching
  final String url;

  // Upload date
  final DateTime? uploadDate;

  // Scanlation group (optional)
  final String? scanGroup;

  // Chapter translation language code (optional, e.g. "en", "id", "ja")
  final String? language;

  // External URL when the chapter is hosted on a third-party site
  // (e.g. MangaDex chapters that redirect to comikey.com). When set,
  // [isExternal] is true and the chapter is not readable in-app.
  final String? externalUrl;

  // Declared page count from the source (e.g. MangaDex `attributes.pages`).
  // 0 or null for external chapters; used to determine in-app readability.
  final int? pages;

  // Source-declared unavailability flag (e.g. MangaDex `isUnavailable`).
  final bool isUnavailable;

  /// True when the chapter is hosted on a third-party site and the app
  /// must redirect via [externalUrl] instead of fetching images.
  bool get isExternal => externalUrl != null && externalUrl!.trim().isNotEmpty;

  /// True when the chapter can be read in-app (not external, not
  /// unavailable, and declared page count > 0 when known).
  bool get isReadableInApp =>
      !isExternal && !isUnavailable && (pages == null || pages! > 0);

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        uploadDate,
        scanGroup,
        language,
        externalUrl,
        pages,
        isUnavailable,
      ];

  Chapter copyWith({
    String? id,
    String? title,
    String? url,
    DateTime? uploadDate,
    String? scanGroup,
    String? language,
    String? externalUrl,
    int? pages,
    bool? isUnavailable,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      uploadDate: uploadDate ?? this.uploadDate,
      scanGroup: scanGroup ?? this.scanGroup,
      language: language ?? this.language,
      externalUrl: externalUrl ?? this.externalUrl,
      pages: pages ?? this.pages,
      isUnavailable: isUnavailable ?? this.isUnavailable,
    );
  }
}
