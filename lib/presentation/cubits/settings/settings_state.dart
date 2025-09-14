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
    this.isUpdatingDisguiseMode = false,
  });

  final UserPreferences preferences;
  final DateTime lastUpdated;
  final bool isUpdatingDisguiseMode;

  @override
  List<Object?> get props => [preferences, lastUpdated, isUpdatingDisguiseMode];

  /// Create a copy with updated properties
  SettingsLoaded copyWith({
    UserPreferences? preferences,
    DateTime? lastUpdated,
    bool? isUpdatingDisguiseMode,
  }) {
    return SettingsLoaded(
      preferences: preferences ?? this.preferences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isUpdatingDisguiseMode: isUpdatingDisguiseMode ?? this.isUpdatingDisguiseMode,
    );
  }

  /// Get theme display name
  String getThemeDisplayName(AppLocalizations? localizations) {
    if (localizations == null) {
      return _getFallbackThemeDisplayName();
    }
    
    switch (preferences.theme) {
      case 'light':
        return localizations.lightTheme;
      case 'dark':
        return localizations.darkTheme;
      case 'amoled':
        return localizations.amoledTheme;
      default:
        return localizations.darkTheme;
    }
  }

  String _getFallbackThemeDisplayName() {
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
  String getImageQualityDisplayName(AppLocalizations? localizations) {
    if (localizations == null) {
      return _getFallbackImageQualityDisplayName();
    }
    
    switch (preferences.imageQuality) {
      case 'low':
        return localizations.lowQuality;
      case 'medium':
        return localizations.mediumQuality;
      case 'high':
        return localizations.highQuality;
      case 'original':
        return localizations.originalQuality;
      default:
        return localizations.highQuality;
    }
  }

  String _getFallbackImageQualityDisplayName() {
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
  String getReadingDirectionDisplayName(AppLocalizations? localizations) {
    if (localizations == null) {
      return _getFallbackReadingDirectionDisplayName();
    }
    
    switch (preferences.readingDirection) {
      case ReadingDirection.leftToRight:
        return localizations.horizontalPages;
      case ReadingDirection.rightToLeft:
        return 'Right to Left'; // Fallback since no specific key exists
      case ReadingDirection.vertical:
        return localizations.verticalPages;
    }
  }

  String _getFallbackReadingDirectionDisplayName() {
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
  String getDefaultLanguageDisplayName(AppLocalizations? localizations) {
    if (localizations == null) {
      return _getFallbackDefaultLanguageDisplayName();
    }
    
    switch (preferences.defaultLanguage.toLowerCase()) {
      case 'english':
        return localizations.english;
      case 'japanese':
        return localizations.japanese;
      case 'indonesian':
        return localizations.indonesian;
      case 'chinese':
        return 'Chinese'; // Fallback since no specific key exists
      case 'korean':
        return 'Korean'; // Fallback since no specific key exists
      default:
        return preferences.defaultLanguage;
    }
  }

  String _getFallbackDefaultLanguageDisplayName() {
    switch (preferences.defaultLanguage.toLowerCase()) {
      case 'english':
        return 'English';
      case 'japanese':
        return 'Japanese';
      case 'indonesian':
        return 'Indonesian';
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
  String getUserFriendlyMessage(AppLocalizations? localizations) {
    if (localizations == null) {
      return _getFallbackUserFriendlyMessage();
    }
    
    switch (errorType) {
      case 'network':
        return localizations.unableToSyncSettings;
      case 'storage':
        return localizations.unableToSaveSettings;
      default:
        return localizations.failedToUpdateSettings;
    }
  }

  String _getFallbackUserFriendlyMessage() {
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
