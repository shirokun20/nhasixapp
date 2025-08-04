part of 'settings_cubit.dart';

/// Base state for SettingsCubit
abstract class SettingsState extends BaseCubitState {
  const SettingsState();
}

/// Initial state before loading settings
class SettingsInitial extends SettingsState {
  const SettingsInitial();

  @override
  List<Object?> get props => [];
}

/// State when settings are loaded successfully
class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.preferences,
    required this.lastUpdated,
  });

  final UserPreferences preferences;
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [preferences, lastUpdated];

  /// Create a copy with updated properties
  SettingsLoaded copyWith({
    UserPreferences? preferences,
    DateTime? lastUpdated,
  }) {
    return SettingsLoaded(
      preferences: preferences ?? this.preferences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get theme display name
  String get themeDisplayName {
    switch (preferences.theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'amoled':
        return 'AMOLED Black';
      default:
        return 'Dark';
    }
  }

  /// Get image quality display name
  String get imageQualityDisplayName {
    switch (preferences.imageQuality) {
      case 'low':
        return 'Low (Faster loading)';
      case 'medium':
        return 'Medium (Balanced)';
      case 'high':
        return 'High (Best quality)';
      case 'original':
        return 'Original (Largest size)';
      default:
        return 'High';
    }
  }

  /// Get reading direction display name
  String get readingDirectionDisplayName {
    switch (preferences.readingDirection) {
      case ReadingDirection.leftToRight:
        return 'Left to Right';
      case ReadingDirection.rightToLeft:
        return 'Right to Left';
      case ReadingDirection.vertical:
        return 'Vertical';
    }
  }

  /// Get default language display name
  String get defaultLanguageDisplayName {
    switch (preferences.defaultLanguage.toLowerCase()) {
      case 'english':
        return 'English';
      case 'japanese':
        return 'Japanese';
      case 'chinese':
        return 'Chinese';
      case 'korean':
        return 'Korean';
      default:
        return preferences.defaultLanguage;
    }
  }

  /// Check if settings have been modified recently
  bool get isRecentlyUpdated {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inSeconds < 5;
  }

  /// Get grid layout summary
  String get gridLayoutSummary {
    return '${preferences.columnsPortrait} columns (Portrait), '
        '${preferences.columnsLandscape} columns (Landscape)';
  }

  /// Get reader settings summary
  String get readerSettingsSummary {
    final features = <String>[];

    if (preferences.useVolumeKeys) {
      features.add('Volume keys');
    }
    if (preferences.keepScreenOn) {
      features.add('Keep screen on');
    }
    if (!preferences.showSystemUI) {
      features.add('Hide system UI');
    }

    return features.isEmpty ? 'Default settings' : features.join(', ');
  }

  /// Get display settings summary
  String get displaySettingsSummary {
    final features = <String>[];

    if (!preferences.showTitles) {
      features.add('Hide titles');
    }
    if (preferences.blurThumbnails) {
      features.add('Blur thumbnails');
    }
    if (preferences.usePagination) {
      features.add('Pagination enabled');
    } else {
      features.add('Infinite scroll');
    }

    return features.isEmpty ? 'Default display' : features.join(', ');
  }
}

/// State when there's an error with settings
class SettingsError extends SettingsState {
  const SettingsError({
    required this.message,
    required this.errorType,
  });

  final String message;
  final String errorType;

  @override
  List<Object?> get props => [message, errorType];

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (errorType) {
      case 'network':
        return 'Unable to sync settings. Changes will be saved locally.';
      case 'storage':
        return 'Unable to save settings. Please check device storage.';
      default:
        return 'Failed to update settings. Please try again.';
    }
  }

  /// Check if error is recoverable
  bool get isRecoverable => errorType != 'storage';
}
