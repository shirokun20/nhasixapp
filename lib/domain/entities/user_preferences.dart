import 'package:equatable/equatable.dart';

/// User preferences entity for app customization
class UserPreferences extends Equatable {
  const UserPreferences({
    this.theme = 'dark',
    this.defaultLanguage = 'english',
    this.imageQuality = 'high',
    this.autoDownload = false,
    this.showTitles = true,
    this.blurThumbnails = false,
    this.infiniteScroll = true,
    this.columnsPortrait = 2,
    this.columnsLandscape = 3,
    this.useVolumeKeys = false,
    this.readingDirection = ReadingDirection.leftToRight,
    this.keepScreenOn = false,
    this.showSystemUI = true,
    this.downloadPath,
    this.maxConcurrentDownloads = 3,
    this.autoBackup = false,
    this.showNsfwContent = true,
    this.blacklistedTags = const [],
    this.favoriteCategories = const [],
  });

  final String theme; // light, dark, amoled
  final String defaultLanguage;
  final String imageQuality; // low, medium, high, original
  final bool autoDownload;
  final bool showTitles; // Show titles on cards
  final bool blurThumbnails; // Blur NSFW thumbnails
  final bool infiniteScroll;
  final int columnsPortrait;
  final int columnsLandscape;
  final bool useVolumeKeys; // For reader navigation
  final ReadingDirection readingDirection;
  final bool keepScreenOn;
  final bool showSystemUI; // In reader mode
  final String? downloadPath;
  final int maxConcurrentDownloads;
  final bool autoBackup;
  final bool showNsfwContent;
  final List<String> blacklistedTags;
  final List<String> favoriteCategories;

  @override
  List<Object?> get props => [
        theme,
        defaultLanguage,
        imageQuality,
        autoDownload,
        showTitles,
        blurThumbnails,
        infiniteScroll,
        columnsPortrait,
        columnsLandscape,
        useVolumeKeys,
        readingDirection,
        keepScreenOn,
        showSystemUI,
        downloadPath,
        maxConcurrentDownloads,
        autoBackup,
        showNsfwContent,
        blacklistedTags,
        favoriteCategories,
      ];

  UserPreferences copyWith({
    String? theme,
    String? defaultLanguage,
    String? imageQuality,
    bool? autoDownload,
    bool? showTitles,
    bool? blurThumbnails,
    bool? infiniteScroll,
    int? columnsPortrait,
    int? columnsLandscape,
    bool? useVolumeKeys,
    ReadingDirection? readingDirection,
    bool? keepScreenOn,
    bool? showSystemUI,
    String? downloadPath,
    int? maxConcurrentDownloads,
    bool? autoBackup,
    bool? showNsfwContent,
    List<String>? blacklistedTags,
    List<String>? favoriteCategories,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      imageQuality: imageQuality ?? this.imageQuality,
      autoDownload: autoDownload ?? this.autoDownload,
      showTitles: showTitles ?? this.showTitles,
      blurThumbnails: blurThumbnails ?? this.blurThumbnails,
      infiniteScroll: infiniteScroll ?? this.infiniteScroll,
      columnsPortrait: columnsPortrait ?? this.columnsPortrait,
      columnsLandscape: columnsLandscape ?? this.columnsLandscape,
      useVolumeKeys: useVolumeKeys ?? this.useVolumeKeys,
      readingDirection: readingDirection ?? this.readingDirection,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      showSystemUI: showSystemUI ?? this.showSystemUI,
      downloadPath: downloadPath ?? this.downloadPath,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      autoBackup: autoBackup ?? this.autoBackup,
      showNsfwContent: showNsfwContent ?? this.showNsfwContent,
      blacklistedTags: blacklistedTags ?? this.blacklistedTags,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
    );
  }

  /// Check if theme is dark
  bool get isDarkTheme => theme == 'dark' || theme == 'amoled';

  /// Check if theme is AMOLED
  bool get isAmoledTheme => theme == 'amoled';

  /// Check if theme is light
  bool get isLightTheme => theme == 'light';

  /// Get columns for current orientation
  int getColumnsForOrientation(bool isPortrait) {
    return isPortrait ? columnsPortrait : columnsLandscape;
  }

  /// Check if tag is blacklisted
  bool isTagBlacklisted(String tagName) {
    return blacklistedTags
        .any((tag) => tag.toLowerCase() == tagName.toLowerCase());
  }

  /// Add tag to blacklist
  UserPreferences addBlacklistedTag(String tagName) {
    if (isTagBlacklisted(tagName)) return this;
    return copyWith(blacklistedTags: [...blacklistedTags, tagName]);
  }

  /// Remove tag from blacklist
  UserPreferences removeBlacklistedTag(String tagName) {
    return copyWith(
      blacklistedTags: blacklistedTags
          .where((tag) => tag.toLowerCase() != tagName.toLowerCase())
          .toList(),
    );
  }

  /// Add favorite category
  UserPreferences addFavoriteCategory(String category) {
    if (favoriteCategories.contains(category)) return this;
    return copyWith(favoriteCategories: [...favoriteCategories, category]);
  }

  /// Remove favorite category
  UserPreferences removeFavoriteCategory(String category) {
    return copyWith(
      favoriteCategories:
          favoriteCategories.where((c) => c != category).toList(),
    );
  }

  /// Get image quality as percentage
  double get imageQualityPercentage {
    switch (imageQuality.toLowerCase()) {
      case 'low':
        return 0.5;
      case 'medium':
        return 0.75;
      case 'high':
        return 0.9;
      case 'original':
        return 1.0;
      default:
        return 0.9;
    }
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'defaultLanguage': defaultLanguage,
      'imageQuality': imageQuality,
      'autoDownload': autoDownload,
      'showTitles': showTitles,
      'blurThumbnails': blurThumbnails,
      'infiniteScroll': infiniteScroll,
      'columnsPortrait': columnsPortrait,
      'columnsLandscape': columnsLandscape,
      'useVolumeKeys': useVolumeKeys,
      'readingDirection': readingDirection.name,
      'keepScreenOn': keepScreenOn,
      'showSystemUI': showSystemUI,
      'downloadPath': downloadPath,
      'maxConcurrentDownloads': maxConcurrentDownloads,
      'autoBackup': autoBackup,
      'showNsfwContent': showNsfwContent,
      'blacklistedTags': blacklistedTags,
      'favoriteCategories': favoriteCategories,
    };
  }

  /// Create from JSON map
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] ?? 'dark',
      defaultLanguage: json['defaultLanguage'] ?? 'english',
      imageQuality: json['imageQuality'] ?? 'high',
      autoDownload: json['autoDownload'] ?? false,
      showTitles: json['showTitles'] ?? true,
      blurThumbnails: json['blurThumbnails'] ?? false,
      infiniteScroll: json['infiniteScroll'] ?? true,
      columnsPortrait: json['columnsPortrait'] ?? 2,
      columnsLandscape: json['columnsLandscape'] ?? 3,
      useVolumeKeys: json['useVolumeKeys'] ?? false,
      readingDirection: ReadingDirection.values.firstWhere(
        (e) => e.name == json['readingDirection'],
        orElse: () => ReadingDirection.leftToRight,
      ),
      keepScreenOn: json['keepScreenOn'] ?? false,
      showSystemUI: json['showSystemUI'] ?? true,
      downloadPath: json['downloadPath'],
      maxConcurrentDownloads: json['maxConcurrentDownloads'] ?? 3,
      autoBackup: json['autoBackup'] ?? false,
      showNsfwContent: json['showNsfwContent'] ?? true,
      blacklistedTags: List<String>.from(json['blacklistedTags'] ?? []),
      favoriteCategories: List<String>.from(json['favoriteCategories'] ?? []),
    );
  }
}

/// Reading direction options
enum ReadingDirection {
  leftToRight,
  rightToLeft,
  vertical,
}

/// Extension for ReadingDirection display names
extension ReadingDirectionExtension on ReadingDirection {
  String get displayName {
    switch (this) {
      case ReadingDirection.leftToRight:
        return 'Left to Right';
      case ReadingDirection.rightToLeft:
        return 'Right to Left';
      case ReadingDirection.vertical:
        return 'Vertical';
    }
  }

  String get description {
    switch (this) {
      case ReadingDirection.leftToRight:
        return 'Western style reading';
      case ReadingDirection.rightToLeft:
        return 'Manga style reading';
      case ReadingDirection.vertical:
        return 'Continuous vertical scroll';
    }
  }
}

/// Theme options
class ThemeOption {
  static const String light = 'light';
  static const String dark = 'dark';
  static const String amoled = 'amoled';

  static const List<String> all = [light, dark, amoled];

  static String getDisplayName(String theme) {
    switch (theme.toLowerCase()) {
      case light:
        return 'Light';
      case dark:
        return 'Dark';
      case amoled:
        return 'AMOLED';
      default:
        return theme;
    }
  }
}

/// Image quality options
class ImageQuality {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String original = 'original';

  static const List<String> all = [low, medium, high, original];

  static String getDisplayName(String quality) {
    switch (quality.toLowerCase()) {
      case low:
        return 'Low (50%)';
      case medium:
        return 'Medium (75%)';
      case high:
        return 'High (90%)';
      case original:
        return 'Original (100%)';
      default:
        return quality;
    }
  }
}
