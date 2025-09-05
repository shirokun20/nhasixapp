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
  String get offline => 'Offline';

  @override
  String get searchHint => 'Search content...';

  @override
  String get searchPlaceholder => 'Enter search keywords';

  @override
  String get noResults => 'No results found';

  @override
  String get searchSuggestions => 'Search Suggestions';

  @override
  String get suggestions => 'Suggestions:';

  @override
  String get tapToLoadContent => 'Tap to load content';

  @override
  String get searchResults => 'Search Results';

  @override
  String get failedToOpenBrowser => 'Failed to open browser';

  @override
  String get viewDownloads => 'View Downloads';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get anyLanguage => 'Any language';

  @override
  String get anyCategory => 'Any category';

  @override
  String get errorOpeningFilter => 'Error opening filter selection';

  @override
  String get errorBrowsingTag => 'Error browsing tag';

  @override
  String get pages => 'Pages';

  @override
  String get tags => 'Tags';

  @override
  String get language => 'Language';

  @override
  String get uploadedOn => 'Uploaded on';

  @override
  String get readNow => 'Read Now';

  @override
  String get confirmDownload => 'Confirm Download';

  @override
  String get downloadConfirmation => 'Are you sure you want to download?';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Downloading';

  @override
  String get downloadCompleted => 'Download Completed';

  @override
  String get downloadFailed => 'Download Failed';

  @override
  String get initializing => 'Initializing...';

  @override
  String get noContentToBrowse => 'No content loaded to open in browser';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get content => 'Content';

  @override
  String get view => 'View';

  @override
  String get clearAll => 'Clear All';

  @override
  String get exportList => 'Export List';

  @override
  String get unableToCheck => 'Unable to check connection.';

  @override
  String get noContentAvailable => 'No content available';

  @override
  String get noContentToDownload => 'No content available to download';

  @override
  String get noGalleriesFound => 'No galleries found on this page';

  @override
  String get noContentLoadedToBrowse => 'No content loaded to open in browser';

  @override
  String get showCachedContent => 'Show Cached Content';

  @override
  String get openedInBrowser => 'Opened in browser';

  @override
  String get foundGalleries => 'Found Galleries';

  @override
  String get checkingDownloadStatus => 'Checking Download Status...';

  @override
  String get allGalleriesDownloaded => 'All Galleries Downloaded';

  @override
  String downloadStarted(String title) {
    return 'Download started for \"$title\"';
  }

  @override
  String get downloadNewGalleries => 'Download New Galleries';

  @override
  String get downloadProgress => 'Download Progress';

  @override
  String get downloadComplete => 'Download Complete';

  @override
  String get downloadError => 'Download Error';

  @override
  String get initializingDownloads => 'Initializing downloads...';

  @override
  String get loadingDownloads => 'Loading downloads...';

  @override
  String get pauseAll => 'Pause All';

  @override
  String get resumeAll => 'Resume All';

  @override
  String get cancelAll => 'Cancel All';

  @override
  String get clearCompleted => 'Clear Completed';

  @override
  String get cleanupStorage => 'Cleanup Storage';

  @override
  String get all => 'All';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get noActiveDownloads => 'No active downloads';

  @override
  String get noQueuedDownloads => 'No queued downloads';

  @override
  String get noCompletedDownloads => 'No completed downloads';

  @override
  String get noFailedDownloads => 'No failed downloads';

  @override
  String get pdfConversionStarted => 'PDF conversion started';

  @override
  String get cancelAllDownloads => 'Cancel All Downloads';

  @override
  String get cancelAllConfirmation =>
      'Are you sure you want to cancel all active downloads? This action cannot be undone.';

  @override
  String get cancelDownload => 'Cancel Download';

  @override
  String get cancelDownloadConfirmation =>
      'Are you sure you want to cancel this download? Progress will be lost.';

  @override
  String get removeDownload => 'Remove Download';

  @override
  String get removeDownloadConfirmation =>
      'Are you sure you want to remove this download from the list? Downloaded files will be deleted.';

  @override
  String get cleanupConfirmation =>
      'This will remove orphaned files and clean up failed downloads. Continue?';

  @override
  String get downloadDetails => 'Download Details';

  @override
  String get status => 'Status';

  @override
  String get progress => 'Progress';

  @override
  String get progressPercent => 'Progress %';

  @override
  String get speed => 'Speed';

  @override
  String get size => 'Size';

  @override
  String get started => 'Started';

  @override
  String get ended => 'Ended';

  @override
  String get duration => 'Duration';

  @override
  String get eta => 'ETA';

  @override
  String get queued => 'Queued';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get resume => 'Resume';

  @override
  String get failed => 'Failed';

  @override
  String get downloadListExported => 'Download list exported';

  @override
  String get downloadAll => 'Download All';

  @override
  String get downloadRange => 'Download Range';

  @override
  String get selectDownloadRange => 'Select Download Range';

  @override
  String get totalPages => 'Total Pages';

  @override
  String get useSliderToSelectRange => 'Use slider to select range:';

  @override
  String get orEnterManually => 'Or enter manually:';

  @override
  String get startPage => 'Start Page';

  @override
  String get endPage => 'End Page';

  @override
  String get quickSelections => 'Quick selections:';

  @override
  String get allPages => 'All Pages';

  @override
  String get firstHalf => 'First Half';

  @override
  String get secondHalf => 'Second Half';

  @override
  String get first10 => 'First 10';

  @override
  String get last10 => 'Last 10';

  @override
  String countAlreadyDownloaded(int count) {
    return 'Skipped $count already downloaded';
  }

  @override
  String newGalleriesToDownload(int count) {
    return '• $count new galleries to download';
  }

  @override
  String alreadyDownloaded(int count) {
    return '• $count already downloaded (will be skipped)';
  }

  @override
  String downloadNew(int count) {
    return 'Download $count New';
  }

  @override
  String queuedDownloads(int count) {
    return 'Queued $count new downloads';
  }

  @override
  String downloadInfo(int count) {
    return 'Download $count new galleries?\\n\\nThis may take significant time and storage space.';
  }

  @override
  String get failedToDownload => 'Failed to download galleries';

  @override
  String selectedPagesTo(int start, int end) {
    return 'Selected: Pages $start to $end';
  }

  @override
  String pagesPercentage(int count, String percentage) {
    return '$count pages ($percentage%)';
  }

  @override
  String rangeDownloadStarted(String title, String pageText) {
    return 'Range download started: $title ($pageText)';
  }

  @override
  String opening(String title) {
    return 'Opening: $title';
  }

  @override
  String get loadingFavorites => 'Loading favorites...';

  @override
  String get errorLoadingFavorites => 'Error Loading Favorites';

  @override
  String get removeFavorite => 'Remove Favorite';

  @override
  String get removeFavoriteConfirmation =>
      'Are you sure you want to remove this content from favorites?';

  @override
  String get removeAction => 'Remove';

  @override
  String get deleteFavorites => 'Delete Favorites';

  @override
  String deleteFavoritesConfirmation(int count, String s) {
    return 'Are you sure you want to remove $count favorite$s?';
  }

  @override
  String get exportFavorites => 'Export Favorites';

  @override
  String get exportingFavorites => 'Exporting favorites...';

  @override
  String get exportComplete => 'Export Complete';

  @override
  String exportedFavoritesCount(int count) {
    return 'Exported $count favorites successfully.';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectFavorites => 'Select favorites';

  @override
  String get exportAction => 'Export';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get searchFavorites => 'Search favorites...';

  @override
  String get selectAll => 'Select All';

  @override
  String get clearSelection => 'Clear';

  @override
  String get removingFromFavorites => 'Removing from favorites...';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String failedToRemoveFavorite(String error) {
    return 'Failed to remove favorite: $error';
  }

  @override
  String removedFavoritesCount(int count) {
    return 'Removed $count favorites';
  }

  @override
  String failedToRemoveFavorites(String error) {
    return 'Failed to remove favorites: $error';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

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
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get displaySettings => 'Display';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'Follow System';

  @override
  String get appLanguage => 'App Language';

  @override
  String get allowAnalytics => 'Allow Analytics';

  @override
  String get privacyAnalytics => 'Privacy Analytics';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetReaderSettings => 'Reset Reader Settings';

  @override
  String get resetReaderSettingsConfirmation =>
      'This will reset all reader settings to their default values:\n\n';

  @override
  String get readingModeLabel => 'Reading Mode: Horizontal Pages';

  @override
  String get keepScreenOnLabel => 'Keep Screen On: Off';

  @override
  String get showUILabel => 'Show UI: On';

  @override
  String get areYouSure => 'Are you sure you want to proceed?';

  @override
  String get readerSettingsResetSuccess =>
      'Reader settings have been reset to defaults.';

  @override
  String failedToResetSettings(Object error) {
    return 'Failed to reset settings: $error';
  }

  @override
  String get readingHistory => 'Reading History';

  @override
  String get clearAllHistory => 'Clear All History';

  @override
  String get manualCleanup => 'Manual Cleanup';

  @override
  String get cleanupSettings => 'Cleanup Settings';

  @override
  String get removeFromHistory => 'Remove from History';

  @override
  String get removeFromHistoryQuestion =>
      'Remove this item from reading history?';

  @override
  String get cleanup => 'Cleanup';

  @override
  String get failedToLoadCleanupStatus => 'Failed to load cleanup status';

  @override
  String get manualCleanupConfirmation =>
      'This will perform cleanup based on your current settings. Continue?';

  @override
  String get noReadingHistory => 'No Reading History';

  @override
  String get errorLoadingHistory => 'Error Loading History';

  @override
  String get nextPage => 'Next Page';

  @override
  String get previousPage => 'Previous Page';

  @override
  String get pageOf => 'of';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get exitFullscreen => 'Exit Fullscreen';

  @override
  String get checkingConnection => 'Checking connection...';

  @override
  String get backOnline => 'Back online! All features available.';

  @override
  String get stillNoInternet => 'Still no internet connection.';

  @override
  String get unableToCheckConnection => 'Unable to check connection.';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get connectionError => 'Connection error';

  @override
  String get serverError => 'Server error';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get original => 'Original';

  @override
  String get lowFaster => 'Low (Faster)';

  @override
  String get highBetterQuality => 'High (Better Quality)';

  @override
  String get originalLargest => 'Original (Largest)';

  @override
  String get lowQuality => 'Low (Faster)';

  @override
  String get mediumQuality => 'Medium';

  @override
  String get highQuality => 'High (Better Quality)';

  @override
  String get originalQuality => 'Original (Largest)';

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
  String get sortBy => 'Sort by';

  @override
  String get filterBy => 'Filter by';

  @override
  String get recent => 'Recent';

  @override
  String get popular => 'Popular';

  @override
  String get oldest => 'Oldest';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get clear => 'Clear';

  @override
  String get remove => 'Remove';

  @override
  String get share => 'Share';

  @override
  String get goBack => 'Go Back';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get goToDownloads => 'Go to Downloads';

  @override
  String get retryAction => 'Retry';

  @override
  String hours(int count) {
    return '$count hours';
  }

  @override
  String days(int count) {
    return '$count days';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get justNow => 'Just now';

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get noData => 'No Data';

  @override
  String get unknownTitle => 'Unknown Title';

  @override
  String get offlineContentError => 'Offline Content Error';

  @override
  String get other => 'Other';

  @override
  String get confirmResetSettings =>
      'Are you sure you want to restore all settings to default?';

  @override
  String get reset => 'Reset';

  @override
  String get manageAutoCleanupDescription =>
      'Manage automatic cleanup of reading history to free up storage space.';

  @override
  String get oneDay => '1 day';

  @override
  String get twoDays => '2 days';

  @override
  String get oneWeek => '1 week';

  @override
  String get privacyInfoText =>
      '• Data is stored on your device\n• Not sent to external servers\n• Only to improve app performance\n• Can be disabled anytime';

  @override
  String get unlimited => 'Unlimited';

  @override
  String daysValue(int days) {
    return '$days days';
  }

  @override
  String get analyticsSubtitle =>
      'Helps app development with local data (not shared)';

  @override
  String get loadingContent => 'Loading content...';

  @override
  String get loadingError => 'Loading Error';

  @override
  String get jumpToPage => 'Jump to Page';

  @override
  String pageInputLabel(int maxPages) {
    return 'Page (1-$maxPages)';
  }

  @override
  String pageOfPages(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get jump => 'Jump';

  @override
  String get readerSettings => 'Reader Settings';

  @override
  String get readingMode => 'Reading Mode';

  @override
  String get horizontalPages => 'Horizontal Pages';

  @override
  String get verticalPages => 'Vertical Pages';

  @override
  String get continuousScroll => 'Continuous Scroll';
}
