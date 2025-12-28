// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kuron';

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
  String get appDisguise => 'App Disguise';

  @override
  String get disguiseMode => 'Disguise Mode';

  @override
  String get offline => 'Offline';

  @override
  String get about => 'About';

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
  String get shuffleToNextGallery => 'Shuffle to next gallery';

  @override
  String get contentHidden => 'Content Hidden';

  @override
  String get tapToViewAnyway => 'Tap to view anyway';

  @override
  String get checkOutThisGallery => 'Check out this gallery!';

  @override
  String galleriesPreloaded(int count) {
    return '$count galleries preloaded';
  }

  @override
  String get oopsSomethingWentWrong => 'Oops! Something went wrong';

  @override
  String get cleanupInfo => 'Cleanup Info';

  @override
  String get loadingHistory => 'Loading history';

  @override
  String get clearingHistory => 'Clearing history...';

  @override
  String get areYouSureClearHistory =>
      'Are you sure you want to clear all reading history? This action cannot be undone.';

  @override
  String get justNow => 'Just now';

  @override
  String get artistCg => 'artist cg';

  @override
  String get gameCg => 'game cg';

  @override
  String get manga => 'manga';

  @override
  String get doujinshi => 'doujinshi';

  @override
  String get imageSet => 'image set';

  @override
  String get cosplay => 'cosplay';

  @override
  String get artistcg => 'artistcg';

  @override
  String get gamecg => 'gamecg';

  @override
  String get bigBreasts => 'big breasts';

  @override
  String get soleFemale => 'sole female';

  @override
  String get soleMale => 'sole male';

  @override
  String get fullColor => 'full color';

  @override
  String get schoolgirlUniform => 'schoolgirl uniform';

  @override
  String get tryADifferentSearchTerm => 'Try a different search term';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get loadingOfflineContent => 'Loading offline content...';

  @override
  String get excludeTags => 'Exclude Tags';

  @override
  String get excludeGroups => 'Exclude Groups';

  @override
  String get excludeCharacters => 'Exclude Characters';

  @override
  String get excludeParodies => 'Exclude Parodies';

  @override
  String get excludeArtists => 'Exclude Artists';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryAdjustingFilters =>
      'Try adjusting your search filters or search terms.';

  @override
  String get tryDifferentKeywords => 'Try different keywords';

  @override
  String get networkError =>
      'Network error. Please check your connection and try again.';

  @override
  String get serverError => 'Server error';

  @override
  String get accessBlocked => 'Access blocked. Trying to bypass protection...';

  @override
  String get tooManyRequests =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get errorProcessingResults =>
      'Error processing search results. Please try again.';

  @override
  String get invalidSearchParameters =>
      'Invalid search parameters. Please check your input.';

  @override
  String get unexpectedError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get retryBypass => 'Retry Bypass';

  @override
  String get retryConnection => 'Retry Connection';

  @override
  String get retrySearch => 'Retry Search';

  @override
  String get networkErrorTitle => 'Network Error';

  @override
  String get serverErrorTitle => 'Server Error';

  @override
  String get unknownErrorTitle => 'Unknown Error';

  @override
  String get loadingContent => 'Loading content...';

  @override
  String get refreshingContent => 'Refreshing content...';

  @override
  String get loadingMoreContent => 'Loading more content...';

  @override
  String get latestContent => 'Latest Content';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get serverTemporarilyUnavailable =>
      'Server is temporarily unavailable. Please try again later.';

  @override
  String get failedToLoadContent => 'Failed to load content';

  @override
  String get cloudflareProtectionDetected =>
      'Cloudflare protection detected. Please wait and try again.';

  @override
  String get tooManyRequestsWait =>
      'Too many requests. Please wait a moment before trying again.';

  @override
  String get noContentFoundMatching =>
      'No content found matching your search criteria. Try adjusting your filters.';

  @override
  String noContentFoundForTag(String tagName) {
    return 'No content found for tag \"$tagName\".';
  }

  @override
  String get removeSomeFilters => 'Remove some filters';

  @override
  String get checkSpelling => 'Check spelling';

  @override
  String get useGeneralTerms => 'Use more general search terms';

  @override
  String get browsePopularContent => 'Browse popular content';

  @override
  String get tryBrowsingOtherTags => 'Try browsing other tags';

  @override
  String get checkPopularContent => 'Check popular content';

  @override
  String get useSearchFunction => 'Use the search function';

  @override
  String get checkInternetConnectionSuggestion =>
      'Check your internet connection';

  @override
  String get tryRefreshingPage => 'Try refreshing the page';

  @override
  String get browsePopularContentSuggestion => 'Browse popular content';

  @override
  String get failedToInitializeSearch => 'Failed to initialize search';

  @override
  String noResultsFoundFor(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get searchingWithFilters => 'Searching with filters...';

  @override
  String get noResultsFoundWithCurrentFilters =>
      'No results found with current filters';

  @override
  String invalidFilter(String errors) {
    return 'Invalid filter: $errors';
  }

  @override
  String invalidSearchFilter(String errors) {
    return 'Invalid search filter: $errors';
  }

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
  String get featured => 'Featured';

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
    return 'Download Started';
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
  String pdfConversionStarted(String contentId) {
    return 'PDF conversion started for $contentId';
  }

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
  String get serverUnavailable =>
      'The server is currently unavailable. Please try again later.';

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
  String get noFavoritesYet =>
      'No favorites yet. Start adding content to your favorites!';

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
    return 'Export Failed: $error';
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
  String get blurThumbnails => 'Blur Thumbnails';

  @override
  String get blurThumbnailsDescription =>
      'Apply blur effect on card images for privacy';

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
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get termsAndConditionsSubtitle => 'User agreement and disclaimers';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'How we handle your data';

  @override
  String get faq => 'FAQ';

  @override
  String get faqSubtitle => 'Frequently asked questions';

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
  String failedToResetSettings(String error) {
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
  String get connectionError => 'Connection error';

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
    return '${count}h';
  }

  @override
  String days(int count) {
    return '$count days';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String daysAgo(int count, String suffix) {
    return '$count$suffix ago';
  }

  @override
  String hoursAgo(int count, String suffix) {
    return '$count$suffix ago';
  }

  @override
  String minutesAgo(int count, String suffix) {
    return '$count$suffix ago';
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
  String get storagePermissionRequired =>
      'Storage permission is required for downloads. Please grant storage permission in app settings.';

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
  String failedToStartDownload(String error) {
    return 'Failed to start download: $error';
  }

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
  String get groupsLabel => 'Groups';

  @override
  String get uploadedLabel => 'Uploaded';

  @override
  String get favoritesLabel => 'Favorites';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get artistsLabel => 'Artists';

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
  String get excludeTagsLabel => 'Exclude Tags';

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

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String loadingPage(int pageNumber) {
    return 'Loading page $pageNumber...';
  }

  @override
  String selectedItemsCount(int count) {
    return '$count selected';
  }

  @override
  String get noImage => 'No image';

  @override
  String get youAreOfflineShort => 'You are offline';

  @override
  String get someFeaturesLimited =>
      'Some features are limited. Connect to internet for full access.';

  @override
  String get wifi => 'WIFI';

  @override
  String get ethernet => 'ETHERNET';

  @override
  String get mobile => 'MOBILE';

  @override
  String get online => 'ONLINE';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get applySearch => 'Apply Search';

  @override
  String get addFiltersToSearch => 'Add filters above to enable search';

  @override
  String get startSearching => 'Start searching';

  @override
  String get enterKeywordsAdvancedHint =>
      'Enter keywords, tags, or use advanced filters to find content';

  @override
  String get filtersReady => 'Filters Ready';

  @override
  String get clearAllFiltersTooltip => 'Clear all filters';

  @override
  String get offlineSomeFeaturesUnavailable =>
      'You are offline. Some features may not be available.';

  @override
  String get usingDownloadedContentOnly => 'Using downloaded content only';

  @override
  String get onlineModeWithNetworkAccess => 'Online mode with network access';

  @override
  String get tagsScreenPlaceholder => 'Tags Screen - To be implemented';

  @override
  String get artistsScreenPlaceholder => 'Artists Screen - To be implemented';

  @override
  String get statusScreenPlaceholder => 'Status Screen - To be implemented';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String pageNotFoundWithUri(String uri) {
    return 'Page not found: $uri';
  }

  @override
  String get goHome => 'Go Home';

  @override
  String get debugThemeInfo => 'DEBUG: Theme Info';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get amoledTheme => 'AMOLED';

  @override
  String get systemMessages => 'System Messages and Background Services';

  @override
  String get notificationMessages => 'Notification Messages';

  @override
  String get convertingToPdf => 'Converting to PDF...';

  @override
  String convertingToPdfWithTitle(String title) {
    return 'Converting $title to PDF...';
  }

  @override
  String convertingToPdfProgress(Object progress) {
    return 'Converting to PDF ($progress%)';
  }

  @override
  String convertingToPdfProgressWithTitle(String title, int progress) {
    return 'Converting $title to PDF ($progress%)';
  }

  @override
  String get pdfCreatedSuccessfully => 'PDF Created Successfully';

  @override
  String pdfCreatedWithParts(String title, int partsCount) {
    return '$title converted to $partsCount PDF files';
  }

  @override
  String pdfConversionFailed(String contentId, String error) {
    return 'PDF conversion failed for $contentId: $error';
  }

  @override
  String pdfConversionFailedWithError(String title, String error) {
    return 'PDF conversion failed for $title: $error';
  }

  @override
  String downloadingWithTitle(String title) {
    return 'Downloading: $title';
  }

  @override
  String downloadingProgress(Object progress) {
    return 'Downloading ($progress%)';
  }

  @override
  String downloadedWithTitle(String title) {
    return 'Downloaded: $title';
  }

  @override
  String downloadFailedWithTitle(String title) {
    return 'Failed: $title';
  }

  @override
  String get downloadPaused => 'Paused';

  @override
  String get downloadResumed => 'Resumed';

  @override
  String get downloadCancelled => 'Cancelled';

  @override
  String get downloadRetry => 'Retry';

  @override
  String get downloadOpen => 'Open';

  @override
  String get pdfOpen => 'Open PDF';

  @override
  String get pdfShare => 'Share';

  @override
  String get pdfRetry => 'Retry PDF';

  @override
  String get downloadServiceMessages => 'Download Service Messages';

  @override
  String downloadRangeInfo(int startPage, int endPage) {
    return ' (Pages $startPage-$endPage)';
  }

  @override
  String downloadRangeComplete(int startPage, int endPage) {
    return ' (Pages $startPage-$endPage)';
  }

  @override
  String invalidPageRange(int start, int end, int total) {
    return 'Invalid page range: $start-$end (total: $total)';
  }

  @override
  String noDataReceived(String url) {
    return 'No data received for image: $url';
  }

  @override
  String createdNoMediaFile(String path) {
    return 'Created .nomedia file for privacy: $path';
  }

  @override
  String get privacyProtectionEnsured =>
      'Privacy protection ensured for existing downloads';

  @override
  String get pdfConversionMessages => 'PDF Conversion Service Messages';

  @override
  String pdfConversionCompleted(String contentId) {
    return 'PDF conversion completed successfully for $contentId';
  }

  @override
  String pdfPartProcessing(int part) {
    return 'Processing part $part in isolate...';
  }

  @override
  String get pdfSingleProcessing => 'Processing single PDF in isolate...';

  @override
  String pdfSplitRequired(int totalParts, int totalPages) {
    return 'Splitting into $totalParts parts ($totalPages pages)';
  }

  @override
  String pdfCreatedFiles(int partsCount, int pageCount) {
    return 'Created $partsCount PDF file(s) with $pageCount total pages';
  }

  @override
  String get pdfNoImagesProvided => 'No images provided for PDF conversion';

  @override
  String pdfFailedToCreatePart(int part, String error) {
    return 'Failed to create PDF part $part: $error';
  }

  @override
  String pdfFailedToCreate(String error) {
    return 'Failed to create PDF: $error';
  }

  @override
  String pdfOutputDirectoryCreated(String path) {
    return 'Created PDF output directory: $path';
  }

  @override
  String pdfUsingFallbackDirectory(String path) {
    return 'Using fallback directory: $path';
  }

  @override
  String pdfInfoSaved(String contentId, int partsCount, int pageCount) {
    return 'PDF info saved for $contentId ($partsCount parts, $pageCount pages)';
  }

  @override
  String pdfExistsForContent(String contentId, String exists) {
    return 'PDF exists for $contentId: $exists';
  }

  @override
  String pdfFoundFiles(String contentId, int count) {
    return 'Found $count PDF file(s) for $contentId';
  }

  @override
  String pdfDeletedFiles(String contentId, int count) {
    return 'Successfully deleted $count PDF file(s) for $contentId';
  }

  @override
  String pdfTotalSize(String contentId, int sizeBytes) {
    return 'Total PDF size for $contentId: $sizeBytes bytes';
  }

  @override
  String pdfCleanupStarted(int maxAge) {
    return 'Starting PDF cleanup, deleting files older than $maxAge days';
  }

  @override
  String pdfCleanupCompleted(int deletedCount) {
    return 'Cleanup completed, deleted $deletedCount old PDF files';
  }

  @override
  String pdfStatistics(Object averageFilesPerContent, Object totalFiles,
      Object totalSizeFormatted, Object uniqueContents) {
    return 'PDF statistics - $totalFiles files, $totalSizeFormatted total size, $uniqueContents unique contents, $averageFilesPerContent avg files per content';
  }

  @override
  String get historyCleanupMessages => 'History Cleanup Service Messages';

  @override
  String get historyCleanupServiceInitialized =>
      'History Cleanup Service initialized';

  @override
  String get historyCleanupServiceDisposed =>
      'History Cleanup Service disposed';

  @override
  String get autoCleanupDisabled => 'Auto cleanup history is disabled';

  @override
  String cleanupServiceStarted(int intervalHours) {
    return 'Cleanup service started with ${intervalHours}h interval';
  }

  @override
  String performingHistoryCleanup(String reason) {
    return 'Performing history cleanup: $reason';
  }

  @override
  String historyCleanupCompleted(int clearedCount, String reason) {
    return 'History cleanup completed: cleared $clearedCount entries ($reason)';
  }

  @override
  String get manualHistoryCleanup => 'Performing manual history cleanup';

  @override
  String get updatedLastAppAccess => 'Updated last app access time';

  @override
  String get updatedLastCleanupTime => 'Updated last cleanup time';

  @override
  String intervalCleanup(int intervalHours) {
    return 'Interval cleanup (${intervalHours}h)';
  }

  @override
  String inactivityCleanup(int inactivityDays) {
    return 'Inactivity cleanup ($inactivityDays days)';
  }

  @override
  String maxAgeCleanup(int maxDays) {
    return 'Max age cleanup ($maxDays days)';
  }

  @override
  String get initialCleanupSetup => 'Initial cleanup setup';

  @override
  String shouldCleanupOldHistory(String shouldCleanup) {
    return 'Should cleanup old history: $shouldCleanup';
  }

  @override
  String get analyticsMessages => 'Analytics Service Messages';

  @override
  String analyticsServiceInitialized(String enabled) {
    return 'Analytics service initialized - tracking $enabled';
  }

  @override
  String get analyticsTrackingEnabled => 'Analytics tracking enabled by user';

  @override
  String get analyticsTrackingDisabled =>
      'Analytics tracking disabled by user - data cleared';

  @override
  String get analyticsDataCleared => 'Analytics data cleared by user request';

  @override
  String get analyticsServiceDisposed => 'Analytics service disposed';

  @override
  String analyticsEventTracked(String eventType, String eventName) {
    return '📊 Analytics: $eventType - $eventName';
  }

  @override
  String get appStartedEvent => 'App started event tracked';

  @override
  String sessionEndEvent(int minutes) {
    return 'Session end event tracked ($minutes minutes)';
  }

  @override
  String get analyticsEnabledEvent => 'Analytics enabled event tracked';

  @override
  String get analyticsDisabledEvent => 'Analytics disabled event tracked';

  @override
  String screenViewEvent(String screenName) {
    return 'Screen view tracked: $screenName';
  }

  @override
  String userActionEvent(String action) {
    return 'User action tracked: $action';
  }

  @override
  String performanceEvent(String operation, int durationMs) {
    return 'Performance tracked: $operation (${durationMs}ms)';
  }

  @override
  String errorEvent(String errorType, String errorMessage) {
    return 'Error tracked: $errorType - $errorMessage';
  }

  @override
  String featureUsageEvent(String feature) {
    return 'Feature usage tracked: $feature';
  }

  @override
  String readingSessionEvent(String contentId, int minutes, int pages) {
    return 'Reading session tracked: $contentId (${minutes}min, $pages pages)';
  }

  @override
  String get offlineManagerMessages => 'Offline Content Manager Messages';

  @override
  String offlineContentAvailable(String contentId, String available) {
    return 'Content $contentId is available offline: $available';
  }

  @override
  String offlineContentPath(String contentId, String path) {
    return 'Offline content path for $contentId: $path';
  }

  @override
  String foundExistingFiles(int count) {
    return 'Found $count existing downloaded files';
  }

  @override
  String offlineImageUrlsFound(String contentId, int count) {
    return 'Found $count offline image URLs for $contentId';
  }

  @override
  String offlineContentIdsFound(int count) {
    return 'Found $count offline content IDs';
  }

  @override
  String searchingOfflineContent(String query) {
    return 'Searching offline content for: $query';
  }

  @override
  String offlineContentMetadata(String contentId, String source) {
    return 'Offline content metadata for $contentId: $source';
  }

  @override
  String offlineContentCreated(String contentId) {
    return 'Offline content created for $contentId';
  }

  @override
  String offlineStorageUsage(int sizeBytes) {
    return 'Offline storage usage: $sizeBytes bytes';
  }

  @override
  String get cleanupOrphanedFilesStarted =>
      'Starting cleanup of orphaned offline files';

  @override
  String get cleanupOrphanedFilesCompleted =>
      'Cleanup of orphaned offline files completed';

  @override
  String removedOrphanedDirectory(String path) {
    return 'Removed orphaned directory: $path';
  }

  @override
  String get queryLabel => 'Query';

  @override
  String get excludeGroupsLabel => 'Exclude Groups';

  @override
  String get excludeCharactersLabel => 'Exclude Characters';

  @override
  String get excludeParodiesLabel => 'Exclude Parodies';

  @override
  String get excludeArtistsLabel => 'Exclude Artists';

  @override
  String minutes(int count) {
    return '${count}m';
  }

  @override
  String seconds(int count) {
    return '${count}s';
  }

  @override
  String get loadingUserPreferences => 'Loading user preferences';

  @override
  String get successfullyLoadedUserPreferences =>
      'Successfully loaded user preferences';

  @override
  String invalidColumnsPortraitValue(int value) {
    return 'Invalid columns portrait value: $value';
  }

  @override
  String invalidColumnsLandscapeValue(int value) {
    return 'Invalid columns landscape value: $value';
  }

  @override
  String get updatingSettingsViaPreferencesService =>
      'Updating settings via PreferencesService';

  @override
  String get successfullyUpdatedSettings => 'Successfully updated settings';

  @override
  String failedToUpdateSetting(String error) {
    return 'Failed to update setting: $error';
  }

  @override
  String get resettingAllSettingsToDefaults =>
      'Resetting all settings to defaults';

  @override
  String get successfullyResetAllSettingsToDefaults =>
      'Successfully reset all settings to defaults';

  @override
  String get settingsNotLoaded => 'Settings not loaded';

  @override
  String get exportingSettings => 'Exporting settings';

  @override
  String get successfullyExportedSettings => 'Successfully exported settings';

  @override
  String failedToExportSettings(String error) {
    return 'Failed to export settings: $error';
  }

  @override
  String get importingSettings => 'Importing settings';

  @override
  String get successfullyImportedSettings => 'Successfully imported settings';

  @override
  String failedToImportSettings(String error) {
    return 'Failed to import settings: $error';
  }

  @override
  String get unableToSyncSettings =>
      'Unable to sync settings. Changes will be saved locally.';

  @override
  String get unableToSaveSettings =>
      'Unable to save settings. Please check device storage.';

  @override
  String get failedToUpdateSettings =>
      'Failed to update settings. Please try again.';

  @override
  String get noHistoryFound => 'No history found';

  @override
  String loadedHistoryEntries(int count) {
    return 'Loaded $count history entries';
  }

  @override
  String failedToLoadHistory(String error) {
    return 'Failed to load history: $error';
  }

  @override
  String loadingMoreHistory(int page) {
    return 'Loading more history (page $page)';
  }

  @override
  String loadedMoreHistoryEntries(int count, int total) {
    return 'Loaded $count more entries, total: $total';
  }

  @override
  String get refreshingHistory => 'Refreshing history';

  @override
  String refreshedHistoryWithEntries(int count) {
    return 'Refreshed history with $count entries';
  }

  @override
  String failedToRefreshHistory(String error) {
    return 'Failed to refresh history: $error';
  }

  @override
  String get clearingAllHistory => 'Clearing all history';

  @override
  String get allHistoryCleared => 'All history cleared';

  @override
  String failedToClearHistory(String error) {
    return 'Failed to clear history: $error';
  }

  @override
  String removingHistoryItem(String contentId) {
    return 'Removing history item: $contentId';
  }

  @override
  String removedHistoryItem(String contentId) {
    return 'Removed history item: $contentId';
  }

  @override
  String failedToRemoveHistoryItem(String error) {
    return 'Failed to remove history item: $error';
  }

  @override
  String get performingManualHistoryCleanup =>
      'Performing manual history cleanup';

  @override
  String get manualCleanupCompleted => 'Manual cleanup completed';

  @override
  String failedToPerformCleanup(String error) {
    return 'Failed to perform cleanup: $error';
  }

  @override
  String get updatingCleanupSettings => 'Updating cleanup settings';

  @override
  String get cleanupSettingsUpdated => 'Cleanup settings updated';

  @override
  String addingContentToFavorites(String title) {
    return 'Adding content to favorites: $title';
  }

  @override
  String successfullyAddedToFavorites(String title) {
    return 'Successfully added to favorites: $title';
  }

  @override
  String contentNotInFavorites(String contentId) {
    return 'Content $contentId is not in favorites, skipping removal';
  }

  @override
  String callingRemoveFromFavoritesUseCase(String params) {
    return 'Calling removeFromFavoritesUseCase with params: $params';
  }

  @override
  String get successfullyCalledRemoveFromFavoritesUseCase =>
      'Successfully called removeFromFavoritesUseCase';

  @override
  String updatingFavoritesListInState(String contentId) {
    return 'Updating favorites list in state, removing contentId: $contentId';
  }

  @override
  String favoritesCountBeforeAfter(int before, int after) {
    return 'Favorites count: before=$before, after=$after';
  }

  @override
  String get stateUpdatedSuccessfully => 'State updated successfully';

  @override
  String successfullyRemovedFromFavorites(String contentId) {
    return 'Successfully removed from favorites: $contentId';
  }

  @override
  String errorRemovingContentFromFavorites(String contentId, String error) {
    return 'Error removing content $contentId from favorites: $error';
  }

  @override
  String removingFavoritesInBatch(int count) {
    return 'Removing $count favorites in batch';
  }

  @override
  String successfullyRemovedFavoritesInBatch(int count) {
    return 'Successfully removed $count favorites in batch';
  }

  @override
  String searchingFavoritesWithQuery(String query) {
    return 'Searching favorites with query: $query';
  }

  @override
  String foundFavoritesMatchingQuery(int count) {
    return 'Found $count favorites matching query';
  }

  @override
  String get clearingFavoritesSearch => 'Clearing favorites search';

  @override
  String get exportingFavoritesData => 'Exporting favorites data';

  @override
  String successfullyExportedFavorites(int count) {
    return 'Successfully exported $count favorites';
  }

  @override
  String get importingFavoritesData => 'Importing favorites data';

  @override
  String successfullyImportedFavorites(int count) {
    return 'Successfully imported $count favorites';
  }

  @override
  String failedToImportFavorite(String error) {
    return 'Failed to import favorite: $error';
  }

  @override
  String get retryingFavoritesLoading => 'Retrying favorites loading';

  @override
  String get refreshingFavorites => 'Refreshing favorites';

  @override
  String failedToLoadFavorites(String error) {
    return 'Failed to load favorites: $error';
  }

  @override
  String failedToInitializeDownloadManager(String error) {
    return 'Failed to initialize download manager: $error';
  }

  @override
  String get waitingForWifiConnection => 'Waiting for WiFi connection';

  @override
  String failedToQueueDownload(String error) {
    return 'Failed to queue download: $error';
  }

  @override
  String retryingDownload(int current, int total) {
    return 'Retrying... ($current/$total)';
  }

  @override
  String get downloadCancelledByUser => 'Download cancelled by user';

  @override
  String failedToPauseDownload(String error) {
    return 'Failed to pause download: $error';
  }

  @override
  String failedToCancelDownload(String error) {
    return 'Failed to cancel download: $error';
  }

  @override
  String failedToRetryDownload(String error) {
    return 'Failed to retry download: $error';
  }

  @override
  String failedToResumeDownload(String error) {
    return 'Failed to resume download: $error';
  }

  @override
  String failedToRemoveDownload(String error) {
    return 'Failed to remove download: $error';
  }

  @override
  String failedToRefreshDownloads(String error) {
    return 'Failed to refresh downloads: $error';
  }

  @override
  String failedToUpdateDownloadSettings(String error) {
    return 'Failed to update download settings: $error';
  }

  @override
  String get pausingAllDownloads => 'Pausing all downloads';

  @override
  String get resumingAllDownloads => 'Resuming all downloads';

  @override
  String get cancellingAllDownloads => 'Cancelling all downloads';

  @override
  String get clearingCompletedDownloads => 'Clearing completed downloads';

  @override
  String failedToPauseAllDownloads(String error) {
    return 'Failed to pause all downloads: $error';
  }

  @override
  String failedToResumeAllDownloads(String error) {
    return 'Failed to resume all downloads: $error';
  }

  @override
  String failedToCancelAllDownloads(String error) {
    return 'Failed to cancel all downloads: $error';
  }

  @override
  String failedToQueueRangeDownload(String error) {
    return 'Failed to queue range download: $error';
  }

  @override
  String failedToClearCompletedDownloads(String error) {
    return 'Failed to clear completed downloads: $error';
  }

  @override
  String get downloadNotCompletedYet => 'Download is not completed yet';

  @override
  String get noImagesFoundForConversion => 'No images found for conversion';

  @override
  String storageCleanupCompleted(int cleanedFiles, String freedSpace) {
    return 'Storage cleanup completed. Cleaned $cleanedFiles directories, freed $freedSpace MB';
  }

  @override
  String storageCleanupComplete(int cleanedFiles, String freedSpace) {
    return 'Storage Cleanup Complete: Cleaned $cleanedFiles items, freed $freedSpace MB';
  }

  @override
  String storageCleanupFailed(String error) {
    return 'Storage Cleanup Failed: $error';
  }

  @override
  String exportDownloadsComplete(String fileName) {
    return 'Export Complete: Downloads exported to $fileName';
  }

  @override
  String failedToDeleteDirectory(String path, String error) {
    return 'Failed to delete directory: $path, error: $error';
  }

  @override
  String failedToDeleteTempFile(String path, String error) {
    return 'Failed to delete temp file: $path, error: $error';
  }

  @override
  String downloadDirectoryNotFound(String path) {
    return 'Download directory not found: $path';
  }

  @override
  String cannotOpenIncompleteDownload(String contentId) {
    return 'Cannot open - download not completed or path missing for $contentId';
  }

  @override
  String errorOpeningDownloadedContent(String error) {
    return 'Error opening downloaded content: $error';
  }

  @override
  String allStrategiesFailedToOpenDownload(String contentId) {
    return 'All strategies failed to open downloaded content for $contentId';
  }

  @override
  String failedToSaveProgressToDatabase(String error) {
    return 'Failed to save progress to database: $error';
  }

  @override
  String failedToUpdatePauseNotification(String error) {
    return 'Failed to update pause notification: $error';
  }

  @override
  String failedToUpdateResumeNotification(String error) {
    return 'Failed to update resume notification: $error';
  }

  @override
  String failedToUpdateNotificationProgress(String error) {
    return 'Failed to update notification progress: $error';
  }

  @override
  String errorCalculatingDirectorySize(String error) {
    return 'Error calculating directory size: $error';
  }

  @override
  String errorCleaningTempFiles(String path, String error) {
    return 'Error cleaning temp files in: $path, error: $error';
  }

  @override
  String errorDetectingDownloadsDirectory(String error) {
    return 'Error detecting Downloads directory: $error';
  }

  @override
  String usingEmergencyFallbackDirectory(String path) {
    return 'Using emergency fallback directory: $path';
  }

  @override
  String get errorDuringStorageCleanup => 'Error during storage cleanup';

  @override
  String get errorDuringExport => 'Error during export';

  @override
  String errorDuringPdfConversion(String contentId) {
    return 'Error during PDF conversion for $contentId';
  }

  @override
  String errorRetryingPdfConversion(String error) {
    return 'Error retrying PDF conversion: $error';
  }

  @override
  String get importBackupFolder => 'Import Backup Folder';

  @override
  String get importBackupFolderDescription =>
      'Enter the path to your backup folder containing nhasix content folders:';

  @override
  String get scanningBackupFolder => 'Scanning backup folder...';

  @override
  String backupContentFound(int count) {
    return 'Found $count backup items';
  }

  @override
  String get noBackupContentFound => 'No valid content found in backup folder';

  @override
  String errorScanningBackup(String error) {
    return 'Error scanning backup: $error';
  }

  @override
  String get themeDescription =>
      'Choose your preferred color theme for the app interface.';

  @override
  String get imageQualityDescription =>
      'Choose image quality for downloads. Higher quality uses more storage and data.';

  @override
  String get gridColumnsDescription =>
      'Choose how many columns to display content in portrait mode. More columns show more content but smaller items.';

  @override
  String get gridPreview => 'Grid Preview';

  @override
  String get autoCleanupDescription =>
      'Manage automatic cleanup of reading history to free up storage space.';

  @override
  String get testCacheClearing => 'Test App Update Cache Clearing';

  @override
  String get testCacheClearingDescription =>
      'Simulate app update and test cache clearing behavior.';

  @override
  String get forceClearCache => 'Force Clear All Caches';

  @override
  String get forceClearCacheDescription => 'Manually clear all image caches.';

  @override
  String get runTest => 'Run Test';

  @override
  String get clearCacheButton => 'Clear Cache';

  @override
  String get disguiseModeDescription =>
      'Choose how the app appears in your launcher for privacy.';

  @override
  String get applyingDisguiseMode => 'Applying disguise mode changes...';

  @override
  String get disguiseDefault => 'Default';

  @override
  String get disguiseCalculator => 'Calculator';

  @override
  String get disguiseNotes => 'Notes';

  @override
  String get disguiseWeather => 'Weather';

  @override
  String get storagePermissionScan =>
      'Storage permission required to scan backup folders';

  @override
  String syncResult(int synced, int updated) {
    return 'Synced: $synced new, $updated updated';
  }

  @override
  String get exportingLibrary => 'Exporting Library';

  @override
  String get libraryExportSuccess => 'Library exported successfully!';

  @override
  String get browseDownloads => 'Browse Downloads';

  @override
  String deletingContent(String title) {
    return 'Deleting $title...';
  }

  @override
  String contentDeletedFreed(String title, String size) {
    return '$title deleted. Freed $size MB';
  }

  @override
  String failedToDeleteContent(String title) {
    return 'Failed to delete $title';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get contentDeleted => 'Content deleted';

  @override
  String get cacheManagementDebug => '🚀 Cache Management (Debug)';
}
