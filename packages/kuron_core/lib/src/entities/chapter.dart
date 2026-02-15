import 'package:equatable/equatable.dart';

/// Entity representing a chapter in a manga/doujinshi
class Chapter extends Equatable {
  const Chapter({
    required this.id,
    required this.title,
    required this.url,
    this.uploadDate,
    this.scanGroup,
  });

  /// Unique identifier (usually slug or ID)
  final String id;

  /// Chapter title (e.g. "Chapter 1")
  final String title;

  /// Chapter URL or Slug for fetching
  final String url;

  /// Upload date
  final DateTime? uploadDate;

  /// Scanlation group (optional)
  final String? scanGroup;

  @override
  List<Object?> get props => [id, title, url, uploadDate, scanGroup];

  Chapter copyWith({
    String? id,
    String? title,
    String? url,
    DateTime? uploadDate,
    String? scanGroup,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      uploadDate: uploadDate ?? this.uploadDate,
      scanGroup: scanGroup ?? this.scanGroup,
    );
  }
}
