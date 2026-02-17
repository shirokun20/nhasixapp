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
    this.parentContent,
    this.allChapters,
    this.currentChapter,
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

  final Content? parentContent;
  final List<Chapter>? allChapters;
  final Chapter? currentChapter;

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
        parentContent,
        allChapters,
        currentChapter,
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
    Content? parentContent,
    Object? allChapters = _undefined,
    Object? currentChapter = _undefined,
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
      parentContent: parentContent ?? this.parentContent,
      allChapters: allChapters == _undefined
          ? this.allChapters
          : allChapters as List<Chapter>?,
      currentChapter: currentChapter == _undefined
          ? this.currentChapter
          : currentChapter as Chapter?,
    );
  }

  double get progress {
    if (content?.pageCount == null || content!.pageCount == 0) return 0.0;
    return (currentPage ?? 1) / content!.pageCount;
  }

  int get progressPercentage {
    return (progress * 100).round();
  }

  bool get isFirstPage => (currentPage ?? 1) <= 1;

  bool get isLastPage => (currentPage ?? 1) >= (content?.pageCount ?? 1);

  int get currentChapterIndex {
    if (allChapters == null || allChapters!.isEmpty) return -1;
    if (currentChapter == null) return -1;
    return allChapters!.indexWhere((c) => c.id == currentChapter!.id);
  }

  bool get hasPreviousChapter {
    if (allChapters == null || allChapters!.isEmpty) return false;
    final index = currentChapterIndex;
    return index > 0;
  }

  bool get hasNextChapter {
    if (allChapters == null || allChapters!.isEmpty) return false;
    final index = currentChapterIndex;
    return index >= 0 && index < allChapters!.length - 1;
  }

  Chapter? get previousChapter {
    if (!hasPreviousChapter) return null;
    return allChapters![currentChapterIndex - 1];
  }

  Chapter? get nextChapter {
    if (!hasNextChapter) return null;
    return allChapters![currentChapterIndex + 1];
  }

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

class ReaderInitial extends ReaderState {
  const ReaderInitial();
}

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
          parentContent: prevState.parentContent,
          allChapters: prevState.allChapters,
          currentChapter: prevState.currentChapter,
        );
}

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
          parentContent: prevState.parentContent,
          allChapters: prevState.allChapters,
          currentChapter: prevState.currentChapter,
        );
}

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
          parentContent: prevState.parentContent,
          allChapters: prevState.allChapters,
          currentChapter: prevState.currentChapter,
        );
}
