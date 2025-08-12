import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nhasixapp/data/models/reader_settings_model.dart';
import 'package:nhasixapp/data/repositories/reader_settings_repository_impl.dart';
import 'package:nhasixapp/domain/repositories/reader_settings_repository.dart';

// Generate mocks
@GenerateMocks([SharedPreferences])
import 'reader_settings_error_handling_simple_test.mocks.dart';

void main() {
  group('ReaderSettingsRepository Error Handling - Core Tests', () {
    late MockSharedPreferences mockPrefs;
    late ReaderSettingsRepository repository;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      repository = ReaderSettingsRepositoryImpl(mockPrefs);
    });

    group('Basic Error Handling', () {
      test('should return defaults when SharedPreferences throws exception',
          () async {
        // Arrange
        when(mockPrefs.getString(any))
            .thenThrow(Exception('SharedPreferences error'));
        when(mockPrefs.getBool(any))
            .thenThrow(Exception('SharedPreferences error'));

        // Act
        final result = await repository.getReaderSettings();

        // Assert
        expect(result, equals(const ReaderSettings()));
      });

      test('should handle null values gracefully', () async {
        // Arrange
        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.getBool(any)).thenReturn(null);

        // Act
        final result = await repository.getReaderSettings();

        // Assert
        expect(result, equals(const ReaderSettings()));
      });

      test('should handle invalid JSON gracefully', () async {
        // Arrange
        when(mockPrefs.getString('reader_settings')).thenReturn('invalid_json');
        when(mockPrefs.getBool('reader_settings_corrupt')).thenReturn(false);
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        // Act
        final result = await repository.getReaderSettings();

        // Assert
        expect(result, equals(const ReaderSettings()));
      });

      test('should save settings without throwing on error', () async {
        // Arrange
        const settings = ReaderSettings(readingMode: ReadingMode.verticalPage);
        when(mockPrefs.getString('_test_key')).thenReturn(null); // Available
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Save failed'));
        when(mockPrefs.setBool(any, any)).thenThrow(Exception('Save failed'));

        // Act & Assert - Should not throw
        expect(() => repository.saveReaderSettings(settings), returnsNormally);
      });

      test('should reset settings without throwing on error', () async {
        // Arrange
        when(mockPrefs.getString('_test_key')).thenReturn(null); // Available
        when(mockPrefs.remove(any)).thenThrow(Exception('Remove failed'));

        // Act & Assert - Should not throw
        expect(() => repository.resetToDefaults(), returnsNormally);
      });
    });

    group('Fallback Behavior', () {
      test('should use backward compatibility when new format fails', () async {
        // Arrange
        when(mockPrefs.getString('_test_key'))
            .thenReturn(null); // SharedPreferences available
        when(mockPrefs.getString('reader_settings')).thenReturn(null);
        when(mockPrefs.getString('reading_mode')).thenReturn('verticalPage');
        when(mockPrefs.getBool('keep_screen_on')).thenReturn(true);
        when(mockPrefs.getBool('show_ui')).thenReturn(false);
        when(mockPrefs.getBool('reader_settings_corrupt')).thenReturn(false);

        // Act
        final result = await repository.getReaderSettings();

        // Assert
        expect(result.readingMode,
            equals(ReadingMode.verticalPage)); // Should parse valid enum
        expect(result.keepScreenOn, equals(true));
        expect(result.showUI, equals(false));
      });

      test('should handle invalid enum values with fallback', () async {
        // Arrange
        when(mockPrefs.getString('_test_key'))
            .thenReturn(null); // SharedPreferences available
        when(mockPrefs.getString('reader_settings')).thenReturn(null);
        when(mockPrefs.getString('reading_mode')).thenReturn('invalid_mode');
        when(mockPrefs.getBool('keep_screen_on')).thenReturn(false);
        when(mockPrefs.getBool('show_ui')).thenReturn(true);
        when(mockPrefs.getBool('reader_settings_corrupt')).thenReturn(false);

        // Act
        final result = await repository.getReaderSettings();

        // Assert
        expect(result.readingMode,
            equals(ReadingMode.singlePage)); // Should fallback to default
        expect(result.keepScreenOn, equals(false));
        expect(result.showUI, equals(true));
      });
    });

    group('Individual Save Methods', () {
      test('saveReadingMode should handle errors gracefully', () async {
        // Arrange
        when(mockPrefs.getString(any)).thenThrow(Exception('Failed'));

        // Act & Assert - Should not throw
        expect(() => repository.saveReadingMode(ReadingMode.verticalPage),
            returnsNormally);
      });

      test('saveKeepScreenOn should handle errors gracefully', () async {
        // Arrange
        when(mockPrefs.getString(any)).thenThrow(Exception('Failed'));

        // Act & Assert - Should not throw
        expect(() => repository.saveKeepScreenOn(true), returnsNormally);
      });

      test('saveShowUI should handle errors gracefully', () async {
        // Arrange
        when(mockPrefs.getString(any)).thenThrow(Exception('Failed'));

        // Act & Assert - Should not throw
        expect(() => repository.saveShowUI(false), returnsNormally);
      });
    });

    group('Data Validation', () {
      test('should validate and correct settings on load', () async {
        // Arrange - Valid JSON with all correct values
        const validSettings = ReaderSettings(
          readingMode: ReadingMode.continuousScroll,
          keepScreenOn: true,
          showUI: false,
        );
        when(mockPrefs.getString('_test_key'))
            .thenReturn(null); // SharedPreferences available
        when(mockPrefs.getString('reader_settings'))
            .thenReturn(jsonEncode(validSettings.toJson()));
        when(mockPrefs.getBool('reader_settings_corrupt')).thenReturn(false);

        // Act
        final result = await repository.getReaderSettings();

        // Assert
        expect(result, equals(validSettings));
      });

      test('should handle empty JSON string', () async {
        // Arrange
        when(mockPrefs.getString('_test_key'))
            .thenReturn(null); // SharedPreferences available
        when(mockPrefs.getString('reader_settings')).thenReturn('');
        when(mockPrefs.getBool('reader_settings_corrupt')).thenReturn(false);
        when(mockPrefs.getString('reading_mode')).thenReturn(null);
        when(mockPrefs.getBool('keep_screen_on')).thenReturn(null);
        when(mockPrefs.getBool('show_ui')).thenReturn(null);

        // Act
        final result = await repository.getReaderSettings();

        // Assert
        expect(result, equals(const ReaderSettings()));
      });
    });
  });
}
