import '../user_preferences.dart';

/// Reader settings entities
/// Extracted from settings_repository.dart

/// Page transition types
enum PageTransition {
  slide,
  fade,
  curl,
  none,
}

/// Image fit modes
enum FitMode {
  fitWidth,
  fitHeight,
  fitScreen,
  originalSize,
  smartFit,
}

/// Tap zones configuration
class TapZones {
  const TapZones({
    required this.leftZone,
    required this.rightZone,
    required this.centerZone,
  });

  final bool leftZone;
  final bool rightZone;
  final bool centerZone;
}

/// Reader settings configuration
class ReaderSettingsEntity {
  const ReaderSettingsEntity({
    required this.readingDirection,
    required this.pageTransition,
    required this.fitMode,
    required this.keepScreenOn,
    required this.showSystemUI,
    required this.useVolumeKeys,
    required this.tapZones,
    this.brightness,
    this.preloadPages = 3,
  });

  final ReadingDirection readingDirection;
  final PageTransition pageTransition;
  final FitMode fitMode;
  final bool keepScreenOn;
  final bool showSystemUI;
  final bool useVolumeKeys;
  final TapZones tapZones;
  final double? brightness;
  final int preloadPages;
}
