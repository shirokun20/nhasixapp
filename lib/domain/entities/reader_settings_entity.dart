import 'package:equatable/equatable.dart';

/// Reading modes for the reader
enum ReadingMode {
  singlePage, // Horizontal PageView
  verticalPage, // Vertical PageView
  continuousScroll, // Vertical ListView
}

/// Tap direction for page navigation gestures
enum TapDirection {
  normal, // Left = previous, Right = next
  inverted, // Left = next, Right = previous (for RTL manga)
}

/// Reader settings domain entity
class ReaderSettingsEntity extends Equatable {
  const ReaderSettingsEntity({
    this.readingMode = ReadingMode.singlePage,
    this.keepScreenOn = false,
    this.showUI = true,
    this.enableZoom = true,
    this.tapDirection = TapDirection.normal,
  });

  final ReadingMode readingMode;
  final bool keepScreenOn;
  final bool showUI;
  final bool enableZoom;
  final TapDirection tapDirection;

  @override
  List<Object?> get props => [
        readingMode,
        keepScreenOn,
        showUI,
        enableZoom,
        tapDirection,
      ];

  ReaderSettingsEntity copyWith({
    ReadingMode? readingMode,
    bool? keepScreenOn,
    bool? showUI,
    bool? enableZoom,
    TapDirection? tapDirection,
  }) {
    return ReaderSettingsEntity(
      readingMode: readingMode ?? this.readingMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      showUI: showUI ?? this.showUI,
      enableZoom: enableZoom ?? this.enableZoom,
      tapDirection: tapDirection ?? this.tapDirection,
    );
  }

  bool get isDefault =>
      readingMode == ReadingMode.singlePage &&
      keepScreenOn == false &&
      showUI == true &&
      enableZoom == true &&
      tapDirection == TapDirection.normal;

  static const ReaderSettingsEntity defaultSettings = ReaderSettingsEntity();
}
