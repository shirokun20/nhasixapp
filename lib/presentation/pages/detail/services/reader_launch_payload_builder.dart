import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/models/image_metadata.dart';

typedef ReaderLaunchPayload = ({
  Content? content,
  List<ImageMetadata>? imageMetadata,
  ChapterData? chapterData,
  Content? parentContent,
  List<Chapter>? allChapters,
  Chapter? currentChapter,
});

class ReaderLaunchPayloadBuilder {
  const ReaderLaunchPayloadBuilder._();

  static ReaderLaunchPayload build({
    required Content content,
    List<ImageMetadata>? imageMetadata,
    ChapterData? chapterData,
    Content? parentContent,
    Chapter? currentChapter,
  }) {
    final availableChapters = parentContent?.chapters ?? content.chapters;
    final effectiveParentContent = parentContent ??
        (availableChapters?.isNotEmpty == true ? content : null);
    final resolvedCurrentChapter = currentChapter ??
        _inferCurrentChapter(
          content: content,
          availableChapters: availableChapters,
        );

    return (
      content: content.imageUrls.isNotEmpty ? content : null,
      imageMetadata: imageMetadata,
      chapterData: chapterData,
      parentContent: effectiveParentContent,
      allChapters: availableChapters,
      currentChapter: resolvedCurrentChapter,
    );
  }

  static Chapter? _inferCurrentChapter({
    required Content content,
    required List<Chapter>? availableChapters,
  }) {
    if (availableChapters == null || availableChapters.isEmpty) {
      return null;
    }

    for (final chapter in availableChapters) {
      if (chapter.id == content.id) {
        return chapter;
      }
    }

    // Gallery-level launches start on the first part even before images are
    // fetched, so keep navigation anchored to the first virtual part.
    if (content.imageUrls.isEmpty) {
      return availableChapters.first;
    }

    return null;
  }
}
