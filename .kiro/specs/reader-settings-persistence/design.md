# Design Document

## Overview

Reader Settings Persistence adalah sistem yang mengelola penyimpanan dan pengambilan preferensi pengguna untuk reader mode. Sistem ini menggunakan SharedPreferences untuk menyimpan data secara persisten dan terintegrasi dengan ReaderCubit untuk state management. Design ini memastikan pengalaman pengguna yang konsisten dengan preferensi yang tersimpan antar sesi aplikasi.

## Architecture

### Component Overview

```
┌─────────────────────────────────────────┐
│            Presentation                 │
│  ┌─────────────────────────────────────┐│
│  │         ReaderScreen                ││
│  │    (UI + Settings Modal)            ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│           State Management              │
│  ┌─────────────────────────────────────┐│
│  │         ReaderCubit                 ││
│  │   (Business Logic + State)          ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  ┌─────────────────────────────────────┐│
│  │    ReaderSettingsRepository         ││
│  │      (Data Management)              ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│           Storage Layer                 │
│  ┌─────────────────────────────────────┐│
│  │      SharedPreferences              ││
│  │    (Persistent Storage)             ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Data Models

```dart
class ReaderSettings {
  final ReadingMode readingMode;
  final bool keepScreenOn;
  final bool showUI;
  
  const ReaderSettings({
    this.readingMode = ReadingMode.singlePage,
    this.keepScreenOn = false,
    this.showUI = true,
  });
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'readingMode': readingMode.name,
    'keepScreenOn': keepScreenOn,
    'showUI': showUI,
  };
  
  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
    readingMode: ReadingMode.values.firstWhere(
      (mode) => mode.name == json['readingMode'],
      orElse: () => ReadingMode.singlePage,
    ),
    keepScreenOn: json['keepScreenOn'] ?? false,
    showUI: json['showUI'] ?? true,
  );
  
  ReaderSettings copyWith({
    ReadingMode? readingMode,
    bool? keepScreenOn,
    bool? showUI,
  }) => ReaderSettings(
    readingMode: readingMode ?? this.readingMode,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    showUI: showUI ?? this.showUI,
  );
}

enum ReadingMode {
  singlePage,        // Horizontal PageView
  verticalPage,      // Vertical PageView  
  continuousScroll,  // Vertical ListView
}
```

### 2. Repository Interface

```dart
abstract class ReaderSettingsRepository {
  Future<ReaderSettings> getReaderSettings();
  Future<void> saveReaderSettings(ReaderSettings settings);
  Future<void> saveReadingMode(ReadingMode mode);
  Future<void> saveKeepScreenOn(bool keepScreenOn);
  Future<void> saveShowUI(bool showUI);
  Future<void> resetToDefaults();
}

class ReaderSettingsRepositoryImpl implements ReaderSettingsRepository {
  final SharedPreferences _prefs;
  static const String _keyReaderSettings = 'reader_settings';
  static const String _keyReadingMode = 'reading_mode';
  static const String _keyKeepScreenOn = 'keep_screen_on';
  static const String _keyShowUI = 'show_ui';
  
  const ReaderSettingsRepositoryImpl(this._prefs);
  
  @override
  Future<ReaderSettings> getReaderSettings() async {
    try {
      // Try to get complete settings first
      final settingsJson = _prefs.getString(_keyReaderSettings);
      if (settingsJson != null) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        return ReaderSettings.fromJson(json);
      }
      
      // Fallback to individual keys for backward compatibility
      final readingModeString = _prefs.getString(_keyReadingMode);
      final keepScreenOn = _prefs.getBool(_keyKeepScreenOn) ?? false;
      final showUI = _prefs.getBool(_keyShowUI) ?? true;
      
      final readingMode = ReadingMode.values.firstWhere(
        (mode) => mode.name == readingModeString,
        orElse: () => ReadingMode.singlePage,
      );
      
      return ReaderSettings(
        readingMode: readingMode,
        keepScreenOn: keepScreenOn,
        showUI: showUI,
      );
    } catch (e) {
      // Return defaults if any error occurs
      return const ReaderSettings();
    }
  }
  
  @override
  Future<void> saveReaderSettings(ReaderSettings settings) async {
    try {
      final settingsJson = jsonEncode(settings.toJson());
      await _prefs.setString(_keyReaderSettings, settingsJson);
      
      // Also save individual keys for backward compatibility
      await _prefs.setString(_keyReadingMode, settings.readingMode.name);
      await _prefs.setBool(_keyKeepScreenOn, settings.keepScreenOn);
      await _prefs.setBool(_keyShowUI, settings.showUI);
    } catch (e) {
      // Log error but don't throw to avoid breaking the app
      print('Error saving reader settings: $e');
    }
  }
  
  @override
  Future<void> saveReadingMode(ReadingMode mode) async {
    try {
      final currentSettings = await getReaderSettings();
      final updatedSettings = currentSettings.copyWith(readingMode: mode);
      await saveReaderSettings(updatedSettings);
    } catch (e) {
      print('Error saving reading mode: $e');
    }
  }
  
  @override
  Future<void> saveKeepScreenOn(bool keepScreenOn) async {
    try {
      final currentSettings = await getReaderSettings();
      final updatedSettings = currentSettings.copyWith(keepScreenOn: keepScreenOn);
      await saveReaderSettings(updatedSettings);
    } catch (e) {
      print('Error saving keep screen on: $e');
    }
  }
  
  @override
  Future<void> saveShowUI(bool showUI) async {
    try {
      final currentSettings = await getReaderSettings();
      final updatedSettings = currentSettings.copyWith(showUI: showUI);
      await saveReaderSettings(updatedSettings);
    } catch (e) {
      print('Error saving show UI: $e');
    }
  }
  
  @override
  Future<void> resetToDefaults() async {
    try {
      await _prefs.remove(_keyReaderSettings);
      await _prefs.remove(_keyReadingMode);
      await _prefs.remove(_keyKeepScreenOn);
      await _prefs.remove(_keyShowUI);
    } catch (e) {
      print('Error resetting reader settings: $e');
    }
  }
}
```

### 3. ReaderCubit Integration

```dart
class ReaderCubit extends Cubit<ReaderState> {
  final GetContentDetailUseCase getContentDetailUseCase;
  final AddToHistoryUseCase addToHistoryUseCase;
  final ReaderSettingsRepository readerSettingsRepository;
  final Logger _logger = Logger();

  Timer? _autoHideTimer;

  ReaderCubit({
    required this.getContentDetailUseCase,
    required this.addToHistoryUseCase,
    required this.readerSettingsRepository,
  }) : super(const ReaderInitial());

  /// Load content with saved settings
  Future<void> loadContent(String contentId, {int initialPage = 1}) async {
    try {
      _stopAutoHideTimer();
      
      emit(ReaderLoading(state));

      // Get content details
      final params = GetContentDetailParams.fromString(contentId);
      final content = await getContentDetailUseCase(params);
      
      // Load saved settings
      final savedSettings = await readerSettingsRepository.getReaderSettings();

      // Emit loaded state with saved settings
      emit(ReaderLoaded(
        state,
        content: content,
        currentPage: initialPage,
        readingMode: savedSettings.readingMode,
        showUI: savedSettings.showUI,
        keepScreenOn: savedSettings.keepScreenOn,
      ));

      // Apply keep screen on setting
      if (savedSettings.keepScreenOn) {
        await WakelockPlus.enable();
      }

      // Save to history
      await _saveToHistory();
    } catch (e, stackTrace) {
      _logger.e("Reader Cubit: $e, $stackTrace");
      _stopAutoHideTimer();
      
      emit(ReaderError(
        state,
        message: 'Failed to load content: ${e.toString()}',
      ));
    }
  }

  /// Change reading mode and save to preferences
  Future<void> changeReadingMode(ReadingMode mode) async {
    if (state is! ReaderLoaded) return;
    
    emit(state.copyWith(readingMode: mode));
    
    // Save to preferences
    await readerSettingsRepository.saveReadingMode(mode);
  }

  /// Toggle keep screen on and save to preferences
  Future<void> toggleKeepScreenOn() async {
    if (state is! ReaderLoaded) return;

    final newKeepScreenOn = !(state.keepScreenOn ?? false);

    if (newKeepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }

    emit(state.copyWith(keepScreenOn: newKeepScreenOn));
    
    // Save to preferences
    await readerSettingsRepository.saveKeepScreenOn(newKeepScreenOn);
  }

  /// Toggle UI visibility and save to preferences
  void toggleUI() {
    if (state is! ReaderLoaded) return;

    final newShowUI = !(state.showUI ?? true);
    emit(state.copyWith(showUI: newShowUI));

    // Save to preferences
    readerSettingsRepository.saveShowUI(newShowUI);

    // Start auto-hide timer if UI is shown
    if (newShowUI) {
      _startAutoHideTimer();
    } else {
      _stopAutoHideTimer();
    }
  }

  /// Reset all reader settings to defaults
  Future<void> resetReaderSettings() async {
    await readerSettingsRepository.resetToDefaults();
    
    if (state is ReaderLoaded) {
      // Apply default settings to current state
      emit(state.copyWith(
        readingMode: ReadingMode.singlePage,
        keepScreenOn: false,
        showUI: true,
      ));
      
      // Disable wakelock
      await WakelockPlus.disable();
    }
  }

  // ... rest of the existing methods remain the same
}
```

### 4. Service Locator Registration

```dart
// In service_locator.dart
void _registerRepositories() {
  // ... existing registrations
  
  getIt.registerLazySingleton<ReaderSettingsRepository>(
    () => ReaderSettingsRepositoryImpl(getIt<SharedPreferences>()),
  );
}

void _registerCubits() {
  // ... existing registrations
  
  getIt.registerFactory<ReaderCubit>(
    () => ReaderCubit(
      getContentDetailUseCase: getIt<GetContentDetailUseCase>(),
      addToHistoryUseCase: getIt<AddToHistoryUseCase>(),
      readerSettingsRepository: getIt<ReaderSettingsRepository>(),
    ),
  );
}
```

## Error Handling

### Error Types and Handling Strategy

```dart
class ReaderSettingsException implements Exception {
  final String message;
  final Exception? originalException;
  
  const ReaderSettingsException(this.message, [this.originalException]);
}

class ReaderSettingsErrorHandler {
  static ReaderSettings handleLoadError(Exception e) {
    // Log error for debugging
    print('Error loading reader settings: $e');
    
    // Return default settings
    return const ReaderSettings();
  }
  
  static void handleSaveError(Exception e) {
    // Log error for debugging
    print('Error saving reader settings: $e');
    
    // Don't throw exception to avoid breaking the app
    // The setting will be applied for current session only
  }
}
```

### Graceful Degradation

1. **Load Failure**: Return default settings and continue with app functionality
2. **Save Failure**: Log error but don't crash, settings apply to current session only
3. **Corrupt Data**: Clear corrupt data and use defaults
4. **SharedPreferences Unavailable**: Use in-memory settings for current session

## Data Migration Strategy

```dart
class ReaderSettingsMigration {
  static const int currentVersion = 1;
  static const String versionKey = 'reader_settings_version';
  
  static Future<void> migrateIfNeeded(SharedPreferences prefs) async {
    final currentStoredVersion = prefs.getInt(versionKey) ?? 0;
    
    if (currentStoredVersion < currentVersion) {
      await _performMigration(prefs, currentStoredVersion, currentVersion);
      await prefs.setInt(versionKey, currentVersion);
    }
  }
  
  static Future<void> _performMigration(
    SharedPreferences prefs, 
    int fromVersion, 
    int toVersion
  ) async {
    // Future migration logic here
    // For now, no migration needed as this is the first version
  }
}
```

## Testing Strategy

### Unit Tests

```dart
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('ReaderSettingsRepository', () {
    late MockSharedPreferences mockPrefs;
    late ReaderSettingsRepository repository;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      repository = ReaderSettingsRepositoryImpl(mockPrefs);
    });
    
    test('should return default settings when no data stored', () async {
      // Arrange
      when(mockPrefs.getString(any)).thenReturn(null);
      when(mockPrefs.getBool(any)).thenReturn(null);
      
      // Act
      final result = await repository.getReaderSettings();
      
      // Assert
      expect(result.readingMode, ReadingMode.singlePage);
      expect(result.keepScreenOn, false);
      expect(result.showUI, true);
    });
    
    test('should save and retrieve settings correctly', () async {
      // Arrange
      const settings = ReaderSettings(
        readingMode: ReadingMode.verticalPage,
        keepScreenOn: true,
        showUI: false,
      );
      
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.getString('reader_settings'))
          .thenReturn(jsonEncode(settings.toJson()));
      
      // Act
      await repository.saveReaderSettings(settings);
      final result = await repository.getReaderSettings();
      
      // Assert
      expect(result.readingMode, ReadingMode.verticalPage);
      expect(result.keepScreenOn, true);
      expect(result.showUI, false);
    });
    
    test('should handle corrupt data gracefully', () async {
      // Arrange
      when(mockPrefs.getString('reader_settings')).thenReturn('invalid_json');
      
      // Act
      final result = await repository.getReaderSettings();
      
      // Assert
      expect(result, const ReaderSettings()); // Should return defaults
    });
  });
}
```

### Integration Tests

```dart
void main() {
  group('ReaderCubit Integration', () {
    late ReaderCubit cubit;
    late MockReaderSettingsRepository mockRepository;
    
    setUp(() {
      mockRepository = MockReaderSettingsRepository();
      cubit = ReaderCubit(
        getContentDetailUseCase: MockGetContentDetailUseCase(),
        addToHistoryUseCase: MockAddToHistoryUseCase(),
        readerSettingsRepository: mockRepository,
      );
    });
    
    test('should load content with saved settings', () async {
      // Arrange
      const savedSettings = ReaderSettings(
        readingMode: ReadingMode.continuousScroll,
        keepScreenOn: true,
      );
      
      when(mockRepository.getReaderSettings())
          .thenAnswer((_) async => savedSettings);
      
      // Act
      await cubit.loadContent('test_id');
      
      // Assert
      final state = cubit.state as ReaderLoaded;
      expect(state.readingMode, ReadingMode.continuousScroll);
      expect(state.keepScreenOn, true);
    });
    
    test('should save settings when changed', () async {
      // Arrange
      await cubit.loadContent('test_id');
      
      // Act
      await cubit.changeReadingMode(ReadingMode.verticalPage);
      
      // Assert
      verify(mockRepository.saveReadingMode(ReadingMode.verticalPage));
    });
  });
}
```

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading**: Settings loaded only when needed
2. **Caching**: Keep settings in memory after first load
3. **Batch Operations**: Save multiple settings in single operation when possible
4. **Async Operations**: All save operations are non-blocking
5. **Error Isolation**: Settings errors don't affect core app functionality

### Memory Management

```dart
class ReaderSettingsCache {
  static ReaderSettings? _cachedSettings;
  static DateTime? _lastLoaded;
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  static bool get isCacheValid {
    if (_cachedSettings == null || _lastLoaded == null) return false;
    return DateTime.now().difference(_lastLoaded!) < cacheTimeout;
  }
  
  static void updateCache(ReaderSettings settings) {
    _cachedSettings = settings;
    _lastLoaded = DateTime.now();
  }
  
  static ReaderSettings? getCached() {
    return isCacheValid ? _cachedSettings : null;
  }
  
  static void clearCache() {
    _cachedSettings = null;
    _lastLoaded = null;
  }
}
```

## Security Considerations

### Data Protection

1. **No Sensitive Data**: Reader settings don't contain sensitive information
2. **Local Storage Only**: Data stored only on device, not transmitted
3. **Validation**: Input validation for all setting values
4. **Sanitization**: Clean data before storage to prevent injection

### Privacy

1. **No Tracking**: Settings are not used for user tracking
2. **Local Only**: No data sent to external servers
3. **User Control**: Users can reset settings at any time
4. **Transparent**: Clear indication of what settings are saved