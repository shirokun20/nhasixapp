import 'dart:convert';

import '../../domain/entities/reader_settings_entity.dart';

/// JSON-serializable model for reader settings persistence
class ReaderSettingsEntityModel extends ReaderSettingsEntity {
  const ReaderSettingsEntityModel({
    super.readingMode = ReadingMode.singlePage,
    super.keepScreenOn = false,
    super.showUI = true,
    super.enableZoom = true,
    super.tapDirection = TapDirection.normal,
  });

  /// From domain entity
  factory ReaderSettingsEntityModel.fromEntity(ReaderSettingsEntity entity) {
    return ReaderSettingsEntityModel(
      readingMode: entity.readingMode,
      keepScreenOn: entity.keepScreenOn,
      showUI: entity.showUI,
      enableZoom: entity.enableZoom,
      tapDirection: entity.tapDirection,
    );
  }

  /// Create from JSON string with error handling
  factory ReaderSettingsEntityModel.fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ReaderSettingsEntityModel(
        readingMode: _parseReadingMode(json['readingMode']),
        keepScreenOn: _parseBool(json['keepScreenOn'], false),
        showUI: _parseBool(json['showUI'], true),
        enableZoom: _parseBool(json['enableZoom'], true),
        tapDirection: _parseTapDirection(json['tapDirection']),
      );
    } catch (e) {
      return const ReaderSettingsEntityModel();
    }
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode({
        'readingMode': readingMode.name,
        'keepScreenOn': keepScreenOn,
        'showUI': showUI,
        'enableZoom': enableZoom,
        'tapDirection': tapDirection.name,
      });

  static TapDirection _parseTapDirection(dynamic value) {
    if (value == null || value is! String) return TapDirection.normal;
    return TapDirection.values.firstWhere(
      (d) => d.name == value,
      orElse: () => TapDirection.normal,
    );
  }

  static ReadingMode _parseReadingMode(dynamic value) {
    if (value == null || value is! String) return ReadingMode.singlePage;
    return ReadingMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ReadingMode.singlePage,
    );
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return defaultValue;
  }
}
