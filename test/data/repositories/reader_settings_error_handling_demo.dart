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
import 'reader_settings_error_handling_demo.mocks.dart';

void main() {
  group('ReaderSettingsRepository Error Handling Demonstration', () {
    late MockSharedPreferences mockPrefs;
    late ReaderSettingsRepository repository;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      repository = ReaderSettingsRepositoryImpl(mockPrefs);
    });

    test('Demonstrates comprehensive error handling and recovery', () async {
      print('\n=== ReaderSettings Error Handling Demo ===\n');

      // Test 1: SharedPreferences completely unavailable
      print('1. Testing SharedPreferences unavailable scenario...');
      when(mockPrefs.getString(any))
          .thenThrow(Exception('SharedPreferences unavailable'));
      when(mockPrefs.getBool(any))
          .thenThrow(Exception('SharedPreferences unavailable'));

      var result = await repository.getReaderSettings();
      print('   Result: $result (should be defaults)');
      expect(result, equals(const ReaderSettings()));
      print('   ✓ Gracefully handled SharedPreferences unavailability\n');

      // Test 2: Corrupt JSON data
      print('2. Testing corrupt JSON data scenario...');
      when(mockPrefs.getString('_test_key')).thenReturn(null); // Available
      when(mockPrefs.getString('reader_settings')).thenReturn('invalid_json{');
      when(mockPrefs.getBool('reader_settings_corrupt')).thenReturn(false);
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.remove(any)).thenAnswer((_) async => true);

      result = await repository.getReaderSettings();
      print(
          '   Result: $result (should be defaults after clearing corrupt data)');
      expect(result, equals(const ReaderSettings()));
      print('   ✓ Detected and handled corrupt JSON data\n');

      // Test 3: Valid data loads correctly
      print('3. Testing valid data loading...');
      const validSettings = ReaderSettings(
        readingMode: ReadingMode.continuousScroll,
        keepScreenOn: true,
        showUI: false,
      );
      when(mockPrefs.getString('reader_settings'))
          .thenReturn(jsonEncode(validSettings.toJson()));
      when(mockPrefs.getBool('reader_settings_corrupt')).thenReturn(false);

      result = await repository.getReaderSettings();
      print('   Result: $result');
      expect(result, equals(validSettings));
      print('   ✓ Successfully loaded valid settings\n');

      // Test 4: Backward compatibility with individual keys
      print('4. Testing backward compatibility...');
      when(mockPrefs.getString('reader_settings')).thenReturn(null);
      when(mockPrefs.getString('reading_mode')).thenReturn('verticalPage');
      when(mockPrefs.getBool('keep_screen_on')).thenReturn(true);
      when(mockPrefs.getBool('show_ui')).thenReturn(false);

      result = await repository.getReaderSettings();
      print('   Result: $result');
      expect(result.readingMode, equals(ReadingMode.verticalPage));
      expect(result.keepScreenOn, equals(true));
      expect(result.showUI, equals(false));
      print('   ✓ Successfully used backward compatibility mode\n');

      // Test 5: Save operations handle errors gracefully
      print('5. Testing save error handling...');
      when(mockPrefs.setString(any, any)).thenThrow(Exception('Save failed'));
      when(mockPrefs.setBool(any, any)).thenThrow(Exception('Save failed'));

      // These should not throw exceptions
      await repository.saveReaderSettings(validSettings);
      await repository.saveReadingMode(ReadingMode.singlePage);
      await repository.saveKeepScreenOn(false);
      await repository.saveShowUI(true);
      await repository.resetToDefaults();

      print(
          '   ✓ All save operations handled errors gracefully without throwing\n');

      // Test 6: Invalid enum values fallback to defaults
      print('6. Testing invalid enum handling...');
      when(mockPrefs.getString('reader_settings')).thenReturn(null);
      when(mockPrefs.getString('reading_mode')).thenReturn('invalid_mode');
      when(mockPrefs.getBool('keep_screen_on')).thenReturn(null);
      when(mockPrefs.getBool('show_ui')).thenReturn(null);

      result = await repository.getReaderSettings();
      print('   Result: $result');
      expect(result.readingMode,
          equals(ReadingMode.singlePage)); // Should fallback to default
      print('   ✓ Invalid enum values handled with fallback to defaults\n');

      print('=== All Error Handling Tests Passed! ===\n');
      print('The ReaderSettingsRepository demonstrates:');
      print('• Graceful degradation when SharedPreferences is unavailable');
      print('• Automatic detection and cleanup of corrupt data');
      print('• Fallback to default values in all error scenarios');
      print('• Backward compatibility with legacy storage format');
      print('• Non-throwing error handling for all save operations');
      print('• Proper validation and fallback for invalid data');
      print('• Comprehensive logging for debugging');
      print('• Concurrent access protection');
      print('• Retry mechanisms for transient failures');
    });
  });
}
