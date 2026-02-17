import 'package:equatable/equatable.dart';

/// Data class to hold chapter images and navigation info
class ChapterData extends Equatable {
  const ChapterData({
    required this.images,
    this.prevChapterId,
    this.nextChapterId,
    this.prevChapterTitle,
    this.nextChapterTitle,
  });

  final List<String> images;
  final String? prevChapterId;
  final String? nextChapterId;
  final String? prevChapterTitle;
  final String? nextChapterTitle;

  @override
  List<Object?> get props => [
        images,
        prevChapterId,
        nextChapterId,
        prevChapterTitle,
        nextChapterTitle,
      ];
}
