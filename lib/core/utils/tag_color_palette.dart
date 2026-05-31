import 'package:flutter/material.dart';

/// Resolves neon tag colors for UI chips and labels.
///
/// Known tag types use fixed accent colors.
/// Unknown tag types are mapped deterministically into a neon fallback palette
/// so they stay visually distinct without collapsing into a dark default.
class TagColorPalette {
  static const Map<String, Color> _fixedColors = <String, Color>{
    'artist': Color(0xFFFF4D8D),
    'character': Color(0xFF00E5FF),
    'parody': Color(0xFFB388FF),
    'group': Color(0xFF39FF14),
    'language': Color(0xFFFFD54F),
    'category': Color(0xFFFF9100),
    'uploader': Color(0xFFFF6D00),
    'female': Color(0xFFFF2AA1),
    'male': Color(0xFF40C4FF),
    'other': Color(0xFF00F5D4),
    'misc': Color(0xFFC6FF00),
    'tag': Color(0xFF18FFFF),
  };

  static const List<Color> _fallbackColors = <Color>[
    Color(0xFF00E5FF),
    Color(0xFFFF4D8D),
    Color(0xFFC6FF00),
    Color(0xFFB388FF),
    Color(0xFFFFB300),
    Color(0xFF40C4FF),
    Color(0xFF00E676),
    Color(0xFFFF9100),
  ];

  static Color resolve(String tagType) {
    final normalized = tagType.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _fallbackColors.first;
    }

    final fixed = _fixedColors[normalized];
    if (fixed != null) {
      return fixed;
    }

    final index = _stableHash(normalized) % _fallbackColors.length;
    return _fallbackColors[index];
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((hash & 0x0007ffff) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((hash & 0x03ffffff) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((hash & 0x00003fff) << 15));
    return hash;
  }
}
