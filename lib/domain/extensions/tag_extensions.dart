import 'package:kuron_core/kuron_core.dart';

/// App-specific extension methods for kuron_core Tag entity.
extension TagAppExtensions on Tag {
  /// Get tag color based on type (for UI display)
  String get colorHex {
    switch (type.toLowerCase()) {
      case 'artist':
        return '#FF6B6B'; // Red
      case 'character':
        return '#4ECDC4'; // Teal
      case 'parody':
        return '#45B7D1'; // Blue
      case 'group':
        return '#96CEB4'; // Green
      case 'language':
        return '#FFEAA7'; // Yellow
      case 'category':
        return '#DDA0DD'; // Plum
      default:
        return '#74B9FF'; // Default blue
    }
  }

  /// Get popularity level
  TagPopularity get popularity {
    if (count > 10000) return TagPopularity.veryHigh;
    if (count > 5000) return TagPopularity.high;
    if (count > 1000) return TagPopularity.medium;
    if (count > 100) return TagPopularity.low;
    return TagPopularity.veryLow;
  }
}

/// Tag popularity levels
enum TagPopularity {
  veryLow,
  low,
  medium,
  high,
  veryHigh,
}
