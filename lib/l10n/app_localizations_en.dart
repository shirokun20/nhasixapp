// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NhasixApp';

  @override
  String get appSubtitle => 'NHentai';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get favorites => 'Favorites';

  @override
  String get downloads => 'Downloads';

  @override
  String get history => 'Reading History';

  @override
  String get randomGallery => 'Random Gallery';

  @override
  String get offlineContent => 'Offline Content';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get imageQuality => 'Image Quality';

  @override
  String get gridColumns => 'Grid Columns (Portrait)';

  @override
  String get reader => 'Reader';

  @override
  String get showSystemUIInReader => 'Show System UI in Reader';

  @override
  String get historyCleanup => 'History Cleanup';

  @override
  String get autoCleanupHistory => 'Auto Cleanup History';

  @override
  String get automaticallyCleanOldReadingHistory =>
      'Automatically clean old reading history';

  @override
  String get cleanupInterval => 'Cleanup Interval';

  @override
  String get howOftenToCleanupHistory => 'How often to cleanup history';

  @override
  String get maxHistoryDays => 'Max History Days';

  @override
  String get maximumDaysToKeepHistory =>
      'Maximum days to keep history (0 = unlimited)';

  @override
  String get cleanupOnInactivity => 'Cleanup on Inactivity';

  @override
  String get cleanHistoryWhenAppUnused =>
      'Clean history when app is unused for several days';

  @override
  String get inactivityThreshold => 'Inactivity Threshold';

  @override
  String get daysOfInactivityBeforeCleanup =>
      'Days of inactivity before cleanup';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get amoled => 'AMOLED';

  @override
  String get english => 'English';

  @override
  String get japanese => 'Japanese';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get original => 'Original';

  @override
  String hours(int count) {
    return '$count hours';
  }

  @override
  String days(int count) {
    return '$count days';
  }

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Downloading';

  @override
  String get downloadCompleted => 'Download Completed';

  @override
  String get downloadFailed => 'Download Failed';

  @override
  String downloadStarted(String title) {
    return 'Download started for \"$title\"';
  }

  @override
  String get downloadNewGalleries => 'Download New Galleries';

  @override
  String get clearAllHistory => 'Clear All History';

  @override
  String get manualCleanup => 'Manual Cleanup';

  @override
  String get removeFromHistory => 'Remove from History';

  @override
  String get loading => 'Loading';

  @override
  String get error => 'Error';

  @override
  String get noData => 'No Data';

  @override
  String get unknownTitle => 'Unknown Title';

  @override
  String get noReadingHistory => 'No Reading History';

  @override
  String get errorLoadingFavorites => 'Error Loading Favorites';

  @override
  String get errorLoadingHistory => 'Error Loading History';

  @override
  String get offlineContentError => 'Offline Content Error';

  @override
  String get downloadError => 'Download Error';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';
}
