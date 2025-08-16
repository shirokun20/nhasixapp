part of 'reader_cubit.dart';

/// Base state for reader screen
class ReaderState extends Equatable {
  const ReaderState({
    this.content,
    this.currentPage,
    this.readingMode,
    this.showUI,
    this.keepScreenOn,
    this.readingTimer,
    this.message,
    this.isOfflineMode,
  });

  final Content? content;
  final int? currentPage;
  final ReadingMode? readingMode;
  final bool? showUI;
  final bool? keepScreenOn;
  final Duration? readingTimer;
  final String? message;
  final bool? isOfflineMode;

  @override
  List<Object?> get props => [
        content,
        currentPage,
        readingMode,
        showUI,
        keepScreenOn,
        readingTimer,
        message,
        isOfflineMode,
      ];

  static const _undefined = Object();

  ReaderState copyWith({
    Content? content,
    Object? currentPage = _undefined,
    ReadingMode? readingMode,
    Object? showUI = _undefined,
    Object? keepScreenOn = _undefined,
    Duration? readingTimer,
    Object? message = _undefined,
    Object? isOfflineMode = _undefined,
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
      readingTimer: readingTimer ?? this.readingTimer,
      message: message == _undefined ? this.message : message as String?,
      isOfflineMode: isOfflineMode == _undefined
          ? this.isOfflineMode
          : isOfflineMode as bool?,
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
          readingTimer: prevState.readingTimer,
          message: prevState.message,
          isOfflineMode: prevState.isOfflineMode,
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
          readingTimer: prevState.readingTimer ?? Duration.zero,
          message: prevState.message,
          isOfflineMode: prevState.isOfflineMode ?? false,
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
          readingTimer: prevState.readingTimer,
          message: prevState.message,
          isOfflineMode: prevState.isOfflineMode,
        );
}
