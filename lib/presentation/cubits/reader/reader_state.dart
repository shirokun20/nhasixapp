part of 'reader_cubit.dart';

/// Base state for reader screen
class ReaderState extends Equatable {
  const ReaderState({
    this.content,
    this.currentPage,
    this.readingMode,
    this.showUI,
    this.keepScreenOn,
    this.enableZoom,
    this.readingTimer,
    this.message,
    this.isOfflineMode,
    this.imageMetadata,
  });

  final Content? content;
  final int? currentPage;
  final ReadingMode? readingMode;
  final bool? showUI;
  final bool? keepScreenOn;
  final bool? enableZoom;
  final Duration? readingTimer;
  final String? message;
  final bool? isOfflineMode;
  final List<ImageMetadata>? imageMetadata;

  @override
  List<Object?> get props => [
        content,
        currentPage,
        readingMode,
        showUI,
        keepScreenOn,
        enableZoom,
        readingTimer,
        message,
        isOfflineMode,
        imageMetadata,
      ];

  static const _undefined = Object();

  ReaderState copyWith({
    Content? content,
    Object? currentPage = _undefined,
    ReadingMode? readingMode,
    Object? showUI = _undefined,
    Object? keepScreenOn = _undefined,
    Object? enableZoom = _undefined,
    Duration? readingTimer,
    Object? message = _undefined,
    Object? isOfflineMode = _undefined,
    List<ImageMetadata>? imageMetadata,
  }) {
    return ReaderState(
      content: content ?? this.content,
      currentPage:
          currentPage == _undefined ? this.currentPage : currentPage as int?,
      readingMode: readingMode ?? this.readingMode,
      showUI: showUI == _undefined ? this.showUI : showUI as bool?,
      keepScreenOn: keepScreenOn == _undefined
          ? this.keepScreenOn
          : keepScreenOn as bool?,
      enableZoom:
          enableZoom == _undefined ? this.enableZoom : enableZoom as bool?,
      readingTimer: readingTimer ?? this.readingTimer,
      message: message == _undefined ? this.message : message as String?,
      isOfflineMode: isOfflineMode == _undefined
          ? this.isOfflineMode
          : isOfflineMode as bool?,
      imageMetadata: imageMetadata ?? this.imageMetadata,
    );
  }

  /// Get reading progress as percentage (0.0 to 1.0)
  double get progress {
    if (content?.pageCount == null || content!.pageCount == 0) return 0.0;
    return (currentPage ?? 1) / content!.pageCount;
  }

  /// Get reading progress as percentage (0 to 100)
  int get progressPercentage {
    return (progress * 100).round();
  }

  /// Check if this is the first page
  bool get isFirstPage => (currentPage ?? 1) <= 1;

  /// Check if this is the last page
  bool get isLastPage => (currentPage ?? 1) >= (content?.pageCount ?? 1);

  /// Get current chapter index (if chapters available)
  int get currentChapterIndex {
    if (content?.chapters == null || content!.chapters!.isEmpty) return 0;

    // Find chapter containing current page
    // For now, assume each chapter is a separate content
    // This logic may need adjustment based on actual data structure
    return 0;
  }

  /// Check if has previous chapter
  bool get hasPreviousChapter {
    if (content?.chapters == null || content!.chapters!.isEmpty) return false;
    return currentChapterIndex > 0;
  }

  /// Check if has next chapter
  bool get hasNextChapter {
    if (content?.chapters == null || content!.chapters!.isEmpty) return false;
    return currentChapterIndex < content!.chapters!.length - 1;
  }

  /// Get current chapter
  Chapter? get currentChapter {
    if (content?.chapters == null || content!.chapters!.isEmpty) return null;
    final index = currentChapterIndex;
    if (index >= 0 && index < content!.chapters!.length) {
      return content!.chapters![index];
    }
    return null;
  }

  /// Get previous chapter
  Chapter? get previousChapter {
    if (!hasPreviousChapter) return null;
    return content!.chapters![currentChapterIndex - 1];
  }

  /// Get next chapter
  Chapter? get nextChapter {
    if (!hasNextChapter) return null;
    return content!.chapters![currentChapterIndex + 1];
  }

  /// Get current image URL
  String get currentImageUrl {
    if (content == null ||
        currentPage == null ||
        currentPage! <= 0 ||
        currentPage! > content!.imageUrls.length) {
      return content?.coverUrl ?? '';
    }
    return content!.imageUrls[currentPage! - 1];
  }
}

/// Initial state
class ReaderInitial extends ReaderState {
  const ReaderInitial();
}

/// Loading state
class ReaderLoading extends ReaderState {
  ReaderLoading(ReaderState prevState)
      : super(
          content: prevState.content,
          currentPage: prevState.currentPage,
          readingMode: prevState.readingMode,
          showUI: prevState.showUI,
          keepScreenOn: prevState.keepScreenOn,
          enableZoom: prevState.enableZoom,
          readingTimer: prevState.readingTimer,
          message: prevState.message,
          isOfflineMode: prevState.isOfflineMode,
          imageMetadata: prevState.imageMetadata,
        );
}

/// Loaded state with content and basic reading functionality
class ReaderLoaded extends ReaderState {
  ReaderLoaded(ReaderState prevState)
      : super(
          content: prevState.content,
          currentPage: prevState.currentPage ?? 1,
          readingMode: prevState.readingMode ?? ReadingMode.singlePage,
          showUI: prevState.showUI ?? true,
          keepScreenOn: prevState.keepScreenOn ?? false,
          enableZoom: prevState.enableZoom ?? true,
          readingTimer: prevState.readingTimer ?? Duration.zero,
          message: prevState.message,
          isOfflineMode: prevState.isOfflineMode ?? false,
          imageMetadata: prevState.imageMetadata,
        );
}

/// Error state
class ReaderError extends ReaderState {
  ReaderError(ReaderState prevState)
      : super(
          content: prevState.content,
          currentPage: prevState.currentPage,
          readingMode: prevState.readingMode,
          showUI: prevState.showUI,
          keepScreenOn: prevState.keepScreenOn,
          enableZoom: prevState.enableZoom,
          readingTimer: prevState.readingTimer,
          message: prevState.message,
          isOfflineMode: prevState.isOfflineMode,
          imageMetadata: prevState.imageMetadata,
        );
}
