import 'dart:convert';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';

/// Reading modes for the reader
enum ReadingMode {
  singlePage, // Horizontal PageView
  verticalPage, // Vertical PageView
  continuousScroll, // Vertical ListView
}

/// Extension for ReadingMode display names and validation
extension ReadingModeExtension on ReadingMode {
  String get displayName {
    switch (this) {
      case ReadingMode.singlePage:
        return 'Single Page';
      case ReadingMode.verticalPage:
        return 'Vertical Page';
      case ReadingMode.continuousScroll:
        return 'Continuous Scroll';
    }
  }

  String get description {
    switch (this) {
      case ReadingMode.singlePage:
        return 'Horizontal page-by-page reading';
      case ReadingMode.verticalPage:
        return 'Vertical page-by-page reading';
      case ReadingMode.continuousScroll:
        return 'Continuous vertical scrolling';
    }
  }
}

/// Reader settings data model for persistence
class ReaderSettings extends Equatable {
  const ReaderSettings({
    this.readingMode = ReadingMode.singlePage,
    this.keepScreenOn = false,
    this.showUI = true,
    this.enableZoom = true,
  });

  final ReadingMode readingMode;
  final bool keepScreenOn;
  final bool showUI;
  final bool enableZoom;

  @override
  List<Object?> get props => [
        readingMode,
        keepScreenOn,
        showUI,
        enableZoom,
      ];

  /// Create a copy with updated values
  ReaderSettings copyWith({
    ReadingMode? readingMode,
    bool? keepScreenOn,
    bool? showUI,
    bool? enableZoom,
  }) {
    return ReaderSettings(
      readingMode: readingMode ?? this.readingMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      showUI: showUI ?? this.showUI,
      enableZoom: enableZoom ?? this.enableZoom,
    );
  }

  /// Convert to JSON map for persistence
  Map<String, dynamic> toJson() {
    return {
      'readingMode': readingMode.name,
      'keepScreenOn': keepScreenOn,
      'showUI': showUI,
      'enableZoom': enableZoom,
    };
  }

  /// Create from JSON map with validation and fallbacks
  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      readingMode: _parseReadingMode(json['readingMode']),
      keepScreenOn: _parseBool(json['keepScreenOn'], false),
      showUI: _parseBool(json['showUI'], true),
      enableZoom: _parseBool(json['enableZoom'], true),
    );
  }

  /// Parse and validate ReadingMode with fallback to default
  static ReadingMode _parseReadingMode(dynamic value) {
    if (value == null) return ReadingMode.singlePage;

    try {
      if (value is String) {
        return ReadingMode.values.firstWhere(
          (mode) => mode.name == value,
          orElse: () => ReadingMode.singlePage,
        );
      }
    } catch (e) {
      // Log error in debug mode but don't throw
      assert(() {
        developer.log('Invalid ReadingMode value: $value',
            name: 'ReaderSettings');
        return true;
      }());
    }

    return ReadingMode.singlePage;
  }

  /// Parse and validate boolean with fallback to default
  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;

    try {
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is int) {
        return value != 0;
      }
    } catch (e) {
      // Log error in debug mode but don't throw
      assert(() {
        developer.log('Invalid bool value: $value', name: 'ReaderSettings');
        return true;
      }());
    }

    return defaultValue;
  }

  /// Create from JSON string with error handling
  factory ReaderSettings.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return ReaderSettings.fromJson(json);
    } catch (e) {
      // Return default settings if JSON parsing fails
      // Only assert in debug mode, don't fail in production
      assert(() {
        developer.log('Failed to parse ReaderSettings JSON: $e',
            name: 'ReaderSettings');
        return true;
      }());
      return const ReaderSettings();
    }
  }

  /// Convert to JSON string
  String toJsonString() {
    try {
      return jsonEncode(toJson());
    } catch (e) {
      // Return empty JSON object if encoding fails
      // Only assert in debug mode, don't fail in production
      assert(() {
        developer.log('Failed to encode ReaderSettings to JSON: $e',
            name: 'ReaderSettings');
        return true;
      }());
      return '{}';
    }
  }

  /// Check if settings are at default values
  bool get isDefault {
    return readingMode == ReadingMode.singlePage &&
        keepScreenOn == false &&
        showUI == true &&
        enableZoom == true;
  }

  /// Get default settings instance
  static const ReaderSettings defaultSettings = ReaderSettings();

  /// Validate settings and return corrected version if needed
  ReaderSettings validate() {
    // All enum values are already validated in fromJson
    // Boolean values are already validated in _parseBool
    // Return self as all values are guaranteed to be valid
    return this;
  }

  @override
  String toString() {
    return 'ReaderSettings('
        'readingMode: $readingMode, '
        'keepScreenOn: $keepScreenOn, '
        'showUI: $showUI, '
        'enableZoom: $enableZoom'
        ')';
  }
}
