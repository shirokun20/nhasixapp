// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NhentaiApp';

  @override
  String get appSubtitle => 'Enhanced Reading Experience';

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
  String get checkInternetConnection => 'Check your internet connection';

  @override
  String get trySwitchingNetwork =>
      'Try switching between WiFi and mobile data';

  @override
  String get restartRouter => 'Restart your router if using WiFi';

  @override
  String get checkWebsiteStatus => 'Check if the website is down';

  @override
  String get cloudflareBypassMessage =>
      'The website is protected by Cloudflare. We\'re trying to bypass the protection.';

  @override
  String get forceBypass => 'Force Bypass';

  @override
  String get unableToProcessData =>
      'Unable to process the received data. The website structure might have changed.';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String serverReturnedError(int statusCode) {
    return 'Server returned error $statusCode. The service might be temporarily unavailable.';
  }

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
  String get lastUpdatedLabel => 'Updated:';

  @override
  String get rangeLabel => 'Range:';

  @override
  String get ofWord => 'of';

  @override
  String waitAndTry(int minutes) {
    return 'Wait $minutes minutes and try again';
  }

  @override
  String get serviceUnderMaintenance =>
      'The service might be under maintenance';

  @override
  String get tryRefreshingPage => 'Try refreshing the page';

  @override
  String get waitForBypass => 'Wait for automatic bypass to complete';

  @override
  String get tryUsingVpn => 'Try using a VPN if available';

  @override
  String get checkBackLater => 'Check back in a few minutes';

  @override
  String get tryRefreshingContent => 'Try refreshing the content';

  @override
  String get checkForAppUpdate => 'Check if the app needs an update';

  @override
  String get reportIfPersists => 'Report the issue if it persists';

  @override
  String get maintenanceTakesHours => 'Maintenance usually takes a few hours';

  @override
  String get checkSocialMedia => 'Check social media for updates';

  @override
  String get tryAgainLater => 'Try again later';

  @override
  String get tryDifferentKeywords => 'Try different keywords';

  @override
  String get serverUnavailable =>
      'The server is currently unavailable. Please try again later.';

  @override
  String get removeSomeFilters => 'Remove some filters';

  @override
  String get checkSpelling => 'Check spelling';

  @override
  String get useBroaderSearchTerms => 'Use broader search terms';

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
  String get nextCleanup => 'Next cleanup';

  @override
  String get historyStatistics => 'History Statistics';

  @override
  String get totalItems => 'Total items';

  @override
  String get lastCleanup => 'Last cleanup';

  @override
  String get lastAppAccess => 'Last app access';

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

  @override
  String get keepScreenOn => 'Keep Screen On';

  @override
  String get keepScreenOnDescription =>
      'Prevent screen from turning off while reading';

  @override
  String get platformNotSupported => 'Platform Not Supported';

  @override
  String get platformNotSupportedBody =>
      'NhasixApp is designed exclusively for Android devices.';

  @override
  String get platformNotSupportedInstall =>
      'Please install and run this app on an Android device.';

  @override
  String get storagePermissionRequired => 'Storage Permission Required';

  @override
  String get storagePermissionExplanation =>
      'This app needs storage permission to download files to your device. Files will be saved to the Downloads/nhasix folder.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get storagePermissionSettingsPrompt =>
      'Storage permission is required to download files. Please grant storage permission in app settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get readingHistoryMessage =>
      'Your reading history will appear here as you read content.';

  @override
  String get startReading => 'Start Reading';

  @override
  String get browsePopularContent => 'Browse popular content';

  @override
  String get searchSomethingInteresting => 'Search for something interesting';

  @override
  String get checkOutFeaturedItems => 'Check out featured items';

  @override
  String get appSubtitleDescription => 'Nhentai unofficial client';

  @override
  String get downloadedGalleries => 'Downloaded galleries';

  @override
  String get favoriteGalleries => 'Favorite galleries';

  @override
  String get viewHistory => 'View history';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get downloadAllGalleries => 'Download all galleries in this page';

  @override
  String enterPageNumber(int totalPages) {
    return 'Enter page number (1 - $totalPages)';
  }

  @override
  String get pageNumber => 'Page number';

  @override
  String get go => 'Go';

  @override
  String validPageNumberError(int totalPages) {
    return 'Please enter a valid page number between 1 and $totalPages';
  }

  @override
  String get tapToJump => 'Tap to jump';

  @override
  String get goToPage => 'Go to Page';

  @override
  String get previousPageTooltip => 'Previous page';

  @override
  String get nextPageTooltip => 'Next page';

  @override
  String get tapToJumpToPage => 'Tap to jump to page';

  @override
  String get loadingContentTitle => 'Loading Content';

  @override
  String get loadingContentDetails => 'Loading Content Details';

  @override
  String get fetchingMetadata => 'Fetching metadata and images...';

  @override
  String get thisMayTakeMoments => 'This may take a few moments';

  @override
  String get youAreOffline => 'You are offline. Some features may be limited.';

  @override
  String get goOnline => 'Go Online';

  @override
  String get youAreOfflineTapToGoOnline => 'You are offline. Tap to go online.';

  @override
  String get contentInformation => 'Content Information';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get moreOptions => 'More Options';

  @override
  String get moreLikeThis => 'More Like This';

  @override
  String get statistics => 'Statistics';

  @override
  String get failedToLoadContent => 'Failed to load content';

  @override
  String get shareContent => 'Share Content';

  @override
  String get sharePanelOpened => 'Share panel opened successfully!';

  @override
  String get shareFailed => 'Share failed, but link copied to clipboard';

  @override
  String downloadStartedFor(String title) {
    return 'Download started for \"$title\"';
  }

  @override
  String get viewDownloadsAction => 'View';

  @override
  String get failedToStartDownload =>
      'Failed to start download. Please try again.';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get failedToCopyLink => 'Failed to copy link. Please try again.';

  @override
  String get copiedLink => 'Copied Link';

  @override
  String get linkCopiedToClipboardDescription =>
      'The following link has been copied to your clipboard:';

  @override
  String get closeDialog => 'Close';

  @override
  String get goOnlineDialogTitle => 'Go Online';

  @override
  String get goOnlineDialogContent =>
      'You are currently in offline mode. Would you like to go online to access the latest content?';

  @override
  String get goingOnline => 'Going online...';

  @override
  String get idLabel => 'ID';

  @override
  String get pagesLabel => 'Pages';

  @override
  String get languageLabel => 'Language';

  @override
  String get artistLabel => 'Artist';

  @override
  String get charactersLabel => 'Characters';

  @override
  String get parodiesLabel => 'Parodies';

  @override
  String get groupsLabel => 'Groups (comma separated)';

  @override
  String get uploadedLabel => 'Uploaded';

  @override
  String get favoritesLabel => 'Favorites';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get artistsLabel => 'Artists (comma separated)';

  @override
  String get relatedLabel => 'Related';

  @override
  String yearAgo(int count, String plural) {
    return '$count year$plural ago';
  }

  @override
  String monthAgo(int count, String plural) {
    return '$count month$plural ago';
  }

  @override
  String dayAgo(int count, String plural) {
    return '$count day$plural ago';
  }

  @override
  String hourAgo(int count, String plural) {
    return '$count hour$plural ago';
  }

  @override
  String get selectFavoritesTooltip => 'Select favorites';

  @override
  String get deleteSelectedTooltip => 'Delete selected';

  @override
  String get selectAllAction => 'Select All';

  @override
  String get clearAction => 'Clear';

  @override
  String selectedCountFormat(int selected, int total) {
    return '$selected / $total';
  }

  @override
  String get loadingFavoritesMessage => 'Loading favorites...';

  @override
  String get deletingFavoritesMessage => 'Deleting favorites...';

  @override
  String get removingFromFavoritesMessage => 'Removing from favorites...';

  @override
  String get favoritesDeletedMessage => 'Favorites deleted successfully';

  @override
  String get failedToDeleteFavoritesMessage => 'Failed to delete favorites';

  @override
  String get confirmDeleteFavoritesTitle => 'Delete Favorites';

  @override
  String confirmDeleteFavoritesMessage(int count, String plural) {
    return 'Are you sure you want to delete $count favorite$plural?';
  }

  @override
  String get exportFavoritesTitle => 'Export Favorites';

  @override
  String get exportingFavoritesMessage => 'Exporting favorites...';

  @override
  String get favoritesExportedMessage => 'Favorites exported successfully';

  @override
  String get failedToExportFavoritesMessage => 'Failed to export favorites';

  @override
  String get searchFavoritesHint => 'Search favorites...';

  @override
  String get searchOfflineContentHint => 'Search offline content...';

  @override
  String failedToLoadPage(int pageNumber) {
    return 'Failed to load page $pageNumber';
  }

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get offlineContentTitle => 'Offline Content';

  @override
  String get favorited => 'Favorited';

  @override
  String get favorite => 'Favorite';

  @override
  String get errorLoadingFavoritesTitle => 'Error Loading Favorites';

  @override
  String get filterDataTitle => 'Filter Data';

  @override
  String get clearAllAction => 'Clear All';

  @override
  String searchFilterHint(String filterType) {
    return 'Search $filterType...';
  }

  @override
  String selectedCountFormat2(int count) {
    return 'Selected ($count)';
  }

  @override
  String get errorLoadingFilterDataTitle => 'Error loading filter data';

  @override
  String noFilterTypeAvailable(String filterType) {
    return 'No $filterType available';
  }

  @override
  String noResultsFoundForQuery(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get contentNotFoundTitle => 'Content Not Found';

  @override
  String contentNotFoundMessage(String contentId) {
    return 'Content with ID \"$contentId\" was not found.';
  }

  @override
  String get filterCategoriesTitle => 'Filter Categories';

  @override
  String get searchTitle => 'Search';

  @override
  String get advancedSearchTitle => 'Advanced Search';

  @override
  String get enterSearchQueryHint =>
      'Enter search query (e.g. \"big breasts english\")';

  @override
  String get popularSearchesTitle => 'Popular Searches';

  @override
  String get recentSearchesTitle => 'Recent Searches';

  @override
  String get pressSearchButtonMessage =>
      'Press the Search button to find content with your current filters';

  @override
  String get searchingMessage => 'Searching...';

  @override
  String resultsCountFormat(String count) {
    return '$count results';
  }

  @override
  String get viewInMainAction => 'View in Main';

  @override
  String get searchErrorTitle => 'Search Error';

  @override
  String get noResultsFoundTitle => 'No results found';

  @override
  String pageText(int pageNumber) {
    return 'page $pageNumber';
  }

  @override
  String pagesText(int startPage, int endPage) {
    return 'pages $startPage-$endPage';
  }

  @override
  String get offlineStatus => 'OFFLINE';

  @override
  String get onlineStatus => 'ONLINE';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpNoResults => 'No results found for your search';

  @override
  String get helpTryDifferent =>
      'Try using different keywords or check your spelling';

  @override
  String get helpUseFilters => 'Use filters to narrow down your search';

  @override
  String get helpCheckConnection => 'Check your internet connection';

  @override
  String get sendReportText => 'Send Report';

  @override
  String get technicalDetailsTitle => 'Technical Details';

  @override
  String get reportSentText => 'Report sent!';

  @override
  String get suggestionCheckConnection => 'Check your internet connection';

  @override
  String get suggestionTryWifiMobile =>
      'Try switching between WiFi and mobile data';

  @override
  String get suggestionRestartRouter => 'Restart your router if using WiFi';

  @override
  String get suggestionCheckWebsite => 'Check if the website is down';

  @override
  String noContentFoundWithQuery(String query) {
    return 'No content found for \"$query\". Try adjusting your search terms or filters.';
  }

  @override
  String get noContentFound =>
      'No content found. Try adjusting your search terms or filters.';

  @override
  String get suggestionTryDifferentKeywords => 'Try different keywords';

  @override
  String get suggestionRemoveFilters => 'Remove some filters';

  @override
  String get suggestionCheckSpelling => 'Check spelling';

  @override
  String get suggestionUseBroaderTerms => 'Use broader search terms';

  @override
  String get underMaintenanceTitle => 'Under Maintenance';

  @override
  String get underMaintenanceMessage =>
      'The service is currently under maintenance. Please check back later.';

  @override
  String get suggestionMaintenanceHours =>
      'Maintenance usually takes a few hours';

  @override
  String get suggestionCheckSocial => 'Check social media for updates';

  @override
  String get suggestionTryLater => 'Try again later';

  @override
  String get includeFilter => 'Include';

  @override
  String get excludeFilter => 'Exclude';

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get total => 'Total';

  @override
  String get done => 'Done';

  @override
  String downloadsFailed(int count, String plural) {
    return '$count download$plural failed';
  }

  @override
  String get processing => 'Processing...';

  @override
  String get readingCompleted => 'Completed';

  @override
  String get readAgain => 'Read Again';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get lessThanOneMinute => 'Less than 1 minute';

  @override
  String get readingTime => 'reading time';

  @override
  String get downloadActions => 'Download Actions';

  @override
  String get pause => 'Pause';

  @override
  String get convertToPdf => 'Convert to PDF';

  @override
  String get details => 'Details';

  @override
  String get downloadActionPause => 'Pause';

  @override
  String get downloadActionResume => 'Resume';

  @override
  String get downloadActionCancel => 'Cancel';

  @override
  String get downloadActionRetry => 'Retry';

  @override
  String get downloadActionConvertToPdf => 'Convert to PDF';

  @override
  String get downloadActionDetails => 'Details';

  @override
  String get downloadActionRemove => 'Remove';

  @override
  String downloadPagesRangeFormat(
      int downloaded, int total, int start, int end, int totalPages) {
    return '$downloaded/$total (Pages $start-$end of $totalPages)';
  }

  @override
  String downloadPagesFormat(int downloaded, int total) {
    return '$downloaded/$total';
  }

  @override
  String downloadContentTitle(String contentId) {
    return 'Content $contentId';
  }

  @override
  String downloadEtaLabel(String duration) {
    return 'ETA: $duration';
  }

  @override
  String get downloadSettingsTitle => 'Download Settings';

  @override
  String get performanceSection => 'Performance';

  @override
  String get maxConcurrentDownloads => 'Max Concurrent Downloads';

  @override
  String get concurrentDownloadsWarning =>
      'Higher values may consume more bandwidth and device resources';

  @override
  String get imageQualityLabel => 'Image Quality';

  @override
  String get autoRetrySection => 'Auto Retry';

  @override
  String get autoRetryFailedDownloads => 'Auto Retry Failed Downloads';

  @override
  String get autoRetryDescription => 'Automatically retry failed downloads';

  @override
  String get maxRetryAttempts => 'Max Retry Attempts';

  @override
  String get networkSection => 'Network';

  @override
  String get wifiOnlyLabel => 'WiFi Only';

  @override
  String get wifiOnlyDescription => 'Only download when connected to WiFi';

  @override
  String get downloadTimeoutLabel => 'Download Timeout';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get enableNotificationsLabel => 'Enable Notifications';

  @override
  String get enableNotificationsDescription =>
      'Show notifications for download progress';

  @override
  String get minutesUnit => 'min';

  @override
  String get searchContentHint => 'Search content...';

  @override
  String get hideFiltersTooltip => 'Hide filters';

  @override
  String get showMoreFiltersTooltip => 'Show more filters';

  @override
  String get advancedFiltersTitle => 'Advanced Filters';

  @override
  String get sortByLabel => 'Sort by';

  @override
  String get categoryLabel => 'Category';

  @override
  String get includeTagsLabel => 'Include tags (comma separated)';

  @override
  String get includeTagsHint => 'e.g., romance, comedy, school';

  @override
  String get excludeTagsLabel => 'Exclude tags (comma separated)';

  @override
  String get excludeTagsHint => 'e.g., horror, violence';

  @override
  String get artistsHint => 'e.g., artist1, artist2';

  @override
  String get pageCountRangeTitle => 'Page Count Range';

  @override
  String get minPagesLabel => 'Min pages';

  @override
  String get maxPagesLabel => 'Max pages';

  @override
  String get rangeToSeparator => 'to';

  @override
  String get popularTagsTitle => 'Popular Tags';

  @override
  String get filtersActiveLabel => 'active';

  @override
  String get clearAllFilters => 'Clear All';

  @override
  String get initializingApp => 'Initializing Application...';

  @override
  String get settingUpComponents =>
      'Setting up components and checking connection...';

  @override
  String get bypassingProtection =>
      'Bypassing protection and establishing connection...';

  @override
  String get connectionFailed => 'Connection Failed';

  @override
  String get readyToGo => 'Ready to Go!';

  @override
  String get launchingApp => 'Launching main application...';
}
