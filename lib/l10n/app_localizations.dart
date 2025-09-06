import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NhasixApp'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'NHentai'**
  String get appSubtitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get history;

  /// No description provided for @randomGallery.
  ///
  /// In en, this message translates to:
  /// **'Random Gallery'**
  String get randomGallery;

  /// No description provided for @offlineContent.
  ///
  /// In en, this message translates to:
  /// **'Offline Content'**
  String get offlineContent;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search content...'**
  String get searchHint;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter search keywords'**
  String get searchPlaceholder;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @searchSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Search Suggestions'**
  String get searchSuggestions;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions:'**
  String get suggestions;

  /// No description provided for @tapToLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Tap to load content'**
  String get tapToLoadContent;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @failedToOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Failed to open browser'**
  String get failedToOpenBrowser;

  /// No description provided for @viewDownloads.
  ///
  /// In en, this message translates to:
  /// **'View Downloads'**
  String get viewDownloads;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @anyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Any language'**
  String get anyLanguage;

  /// No description provided for @anyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get anyCategory;

  /// No description provided for @errorOpeningFilter.
  ///
  /// In en, this message translates to:
  /// **'Error opening filter selection'**
  String get errorOpeningFilter;

  /// No description provided for @errorBrowsingTag.
  ///
  /// In en, this message translates to:
  /// **'Error browsing tag'**
  String get errorBrowsingTag;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @uploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded on'**
  String get uploadedOn;

  /// No description provided for @readNow.
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get readNow;

  /// No description provided for @confirmDownload.
  ///
  /// In en, this message translates to:
  /// **'Confirm Download'**
  String get confirmDownload;

  /// No description provided for @downloadConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to download?'**
  String get downloadConfirmation;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @downloadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Download Completed'**
  String get downloadCompleted;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadFailed;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @noContentToBrowse.
  ///
  /// In en, this message translates to:
  /// **'No content loaded to open in browser'**
  String get noContentToBrowse;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @exportList.
  ///
  /// In en, this message translates to:
  /// **'Export List'**
  String get exportList;

  /// No description provided for @unableToCheck.
  ///
  /// In en, this message translates to:
  /// **'Unable to check connection.'**
  String get unableToCheck;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// No description provided for @noContentToDownload.
  ///
  /// In en, this message translates to:
  /// **'No content available to download'**
  String get noContentToDownload;

  /// No description provided for @noGalleriesFound.
  ///
  /// In en, this message translates to:
  /// **'No galleries found on this page'**
  String get noGalleriesFound;

  /// No description provided for @noContentLoadedToBrowse.
  ///
  /// In en, this message translates to:
  /// **'No content loaded to open in browser'**
  String get noContentLoadedToBrowse;

  /// No description provided for @showCachedContent.
  ///
  /// In en, this message translates to:
  /// **'Show Cached Content'**
  String get showCachedContent;

  /// No description provided for @openedInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opened in browser'**
  String get openedInBrowser;

  /// No description provided for @foundGalleries.
  ///
  /// In en, this message translates to:
  /// **'Found Galleries'**
  String get foundGalleries;

  /// No description provided for @checkingDownloadStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking Download Status...'**
  String get checkingDownloadStatus;

  /// No description provided for @allGalleriesDownloaded.
  ///
  /// In en, this message translates to:
  /// **'All Galleries Downloaded'**
  String get allGalleriesDownloaded;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started for \"{title}\"'**
  String downloadStarted(String title);

  /// No description provided for @downloadNewGalleries.
  ///
  /// In en, this message translates to:
  /// **'Download New Galleries'**
  String get downloadNewGalleries;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Download Progress'**
  String get downloadProgress;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download Complete'**
  String get downloadComplete;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Download Error'**
  String get downloadError;

  /// No description provided for @initializingDownloads.
  ///
  /// In en, this message translates to:
  /// **'Initializing downloads...'**
  String get initializingDownloads;

  /// No description provided for @loadingDownloads.
  ///
  /// In en, this message translates to:
  /// **'Loading downloads...'**
  String get loadingDownloads;

  /// No description provided for @pauseAll.
  ///
  /// In en, this message translates to:
  /// **'Pause All'**
  String get pauseAll;

  /// No description provided for @resumeAll.
  ///
  /// In en, this message translates to:
  /// **'Resume All'**
  String get resumeAll;

  /// No description provided for @cancelAll.
  ///
  /// In en, this message translates to:
  /// **'Cancel All'**
  String get cancelAll;

  /// No description provided for @clearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed'**
  String get clearCompleted;

  /// No description provided for @cleanupStorage.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Storage'**
  String get cleanupStorage;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @noDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloadsYet;

  /// No description provided for @noActiveDownloads.
  ///
  /// In en, this message translates to:
  /// **'No active downloads'**
  String get noActiveDownloads;

  /// No description provided for @noQueuedDownloads.
  ///
  /// In en, this message translates to:
  /// **'No queued downloads'**
  String get noQueuedDownloads;

  /// No description provided for @noCompletedDownloads.
  ///
  /// In en, this message translates to:
  /// **'No completed downloads'**
  String get noCompletedDownloads;

  /// No description provided for @noFailedDownloads.
  ///
  /// In en, this message translates to:
  /// **'No failed downloads'**
  String get noFailedDownloads;

  /// No description provided for @pdfConversionStarted.
  ///
  /// In en, this message translates to:
  /// **'PDF conversion started'**
  String get pdfConversionStarted;

  /// No description provided for @cancelAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Cancel All Downloads'**
  String get cancelAllDownloads;

  /// No description provided for @cancelAllConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel all active downloads? This action cannot be undone.'**
  String get cancelAllConfirmation;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get cancelDownload;

  /// No description provided for @cancelDownloadConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this download? Progress will be lost.'**
  String get cancelDownloadConfirmation;

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove Download'**
  String get removeDownload;

  /// No description provided for @removeDownloadConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this download from the list? Downloaded files will be deleted.'**
  String get removeDownloadConfirmation;

  /// No description provided for @cleanupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will remove orphaned files and clean up failed downloads. Continue?'**
  String get cleanupConfirmation;

  /// No description provided for @downloadDetails.
  ///
  /// In en, this message translates to:
  /// **'Download Details'**
  String get downloadDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @progressPercent.
  ///
  /// In en, this message translates to:
  /// **'Progress %'**
  String get progressPercent;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get eta;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @downloadListExported.
  ///
  /// In en, this message translates to:
  /// **'Download list exported'**
  String get downloadListExported;

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// No description provided for @downloadRange.
  ///
  /// In en, this message translates to:
  /// **'Download Range'**
  String get downloadRange;

  /// No description provided for @selectDownloadRange.
  ///
  /// In en, this message translates to:
  /// **'Select Download Range'**
  String get selectDownloadRange;

  /// No description provided for @totalPages.
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get totalPages;

  /// No description provided for @useSliderToSelectRange.
  ///
  /// In en, this message translates to:
  /// **'Use slider to select range:'**
  String get useSliderToSelectRange;

  /// No description provided for @orEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter manually:'**
  String get orEnterManually;

  /// No description provided for @startPage.
  ///
  /// In en, this message translates to:
  /// **'Start Page'**
  String get startPage;

  /// No description provided for @endPage.
  ///
  /// In en, this message translates to:
  /// **'End Page'**
  String get endPage;

  /// No description provided for @quickSelections.
  ///
  /// In en, this message translates to:
  /// **'Quick selections:'**
  String get quickSelections;

  /// No description provided for @allPages.
  ///
  /// In en, this message translates to:
  /// **'All Pages'**
  String get allPages;

  /// No description provided for @firstHalf.
  ///
  /// In en, this message translates to:
  /// **'First Half'**
  String get firstHalf;

  /// No description provided for @secondHalf.
  ///
  /// In en, this message translates to:
  /// **'Second Half'**
  String get secondHalf;

  /// No description provided for @first10.
  ///
  /// In en, this message translates to:
  /// **'First 10'**
  String get first10;

  /// No description provided for @last10.
  ///
  /// In en, this message translates to:
  /// **'Last 10'**
  String get last10;

  /// No description provided for @countAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Skipped {count} already downloaded'**
  String countAlreadyDownloaded(int count);

  /// No description provided for @newGalleriesToDownload.
  ///
  /// In en, this message translates to:
  /// **'• {count} new galleries to download'**
  String newGalleriesToDownload(int count);

  /// No description provided for @alreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'• {count} already downloaded (will be skipped)'**
  String alreadyDownloaded(int count);

  /// No description provided for @downloadNew.
  ///
  /// In en, this message translates to:
  /// **'Download {count} New'**
  String downloadNew(int count);

  /// No description provided for @queuedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Queued {count} new downloads'**
  String queuedDownloads(int count);

  /// No description provided for @downloadInfo.
  ///
  /// In en, this message translates to:
  /// **'Download {count} new galleries?\\n\\nThis may take significant time and storage space.'**
  String downloadInfo(int count);

  /// No description provided for @failedToDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to download galleries'**
  String get failedToDownload;

  /// No description provided for @selectedPagesTo.
  ///
  /// In en, this message translates to:
  /// **'Selected: Pages {start} to {end}'**
  String selectedPagesTo(int start, int end);

  /// No description provided for @pagesPercentage.
  ///
  /// In en, this message translates to:
  /// **'{count} pages ({percentage}%)'**
  String pagesPercentage(int count, String percentage);

  /// No description provided for @rangeDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Range download started: {title} ({pageText})'**
  String rangeDownloadStarted(String title, String pageText);

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening: {title}'**
  String opening(String title);

  /// No description provided for @loadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Loading favorites...'**
  String get loadingFavorites;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get removeFavorite;

  /// No description provided for @removeFavoriteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this content from favorites?'**
  String get removeFavoriteConfirmation;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @deleteFavorites.
  ///
  /// In en, this message translates to:
  /// **'Delete Favorites'**
  String get deleteFavorites;

  /// No description provided for @deleteFavoritesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {count} favorite{s}?'**
  String deleteFavoritesConfirmation(int count, String s);

  /// No description provided for @exportFavorites.
  ///
  /// In en, this message translates to:
  /// **'Export Favorites'**
  String get exportFavorites;

  /// No description provided for @exportingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Exporting favorites...'**
  String get exportingFavorites;

  /// No description provided for @exportComplete.
  ///
  /// In en, this message translates to:
  /// **'Export Complete'**
  String get exportComplete;

  /// No description provided for @exportedFavoritesCount.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} favorites successfully.'**
  String exportedFavoritesCount(int count);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectFavorites.
  ///
  /// In en, this message translates to:
  /// **'Select favorites'**
  String get selectFavorites;

  /// No description provided for @exportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @searchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Search favorites...'**
  String get searchFavorites;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @removingFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removing from favorites...'**
  String get removingFromFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @failedToRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove favorite: {error}'**
  String failedToRemoveFavorite(String error);

  /// No description provided for @removedFavoritesCount.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} favorites'**
  String removedFavoritesCount(int count);

  /// No description provided for @failedToRemoveFavorites.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove favorites: {error}'**
  String failedToRemoveFavorites(String error);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @imageQuality.
  ///
  /// In en, this message translates to:
  /// **'Image Quality'**
  String get imageQuality;

  /// No description provided for @gridColumns.
  ///
  /// In en, this message translates to:
  /// **'Grid Columns (Portrait)'**
  String get gridColumns;

  /// No description provided for @reader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get reader;

  /// No description provided for @showSystemUIInReader.
  ///
  /// In en, this message translates to:
  /// **'Show System UI in Reader'**
  String get showSystemUIInReader;

  /// No description provided for @historyCleanup.
  ///
  /// In en, this message translates to:
  /// **'History Cleanup'**
  String get historyCleanup;

  /// No description provided for @autoCleanupHistory.
  ///
  /// In en, this message translates to:
  /// **'Auto Cleanup History'**
  String get autoCleanupHistory;

  /// No description provided for @automaticallyCleanOldReadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Automatically clean old reading history'**
  String get automaticallyCleanOldReadingHistory;

  /// No description provided for @cleanupInterval.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Interval'**
  String get cleanupInterval;

  /// No description provided for @howOftenToCleanupHistory.
  ///
  /// In en, this message translates to:
  /// **'How often to cleanup history'**
  String get howOftenToCleanupHistory;

  /// No description provided for @maxHistoryDays.
  ///
  /// In en, this message translates to:
  /// **'Max History Days'**
  String get maxHistoryDays;

  /// No description provided for @maximumDaysToKeepHistory.
  ///
  /// In en, this message translates to:
  /// **'Maximum days to keep history (0 = unlimited)'**
  String get maximumDaysToKeepHistory;

  /// No description provided for @cleanupOnInactivity.
  ///
  /// In en, this message translates to:
  /// **'Cleanup on Inactivity'**
  String get cleanupOnInactivity;

  /// No description provided for @cleanHistoryWhenAppUnused.
  ///
  /// In en, this message translates to:
  /// **'Clean history when app is unused for several days'**
  String get cleanHistoryWhenAppUnused;

  /// No description provided for @inactivityThreshold.
  ///
  /// In en, this message translates to:
  /// **'Inactivity Threshold'**
  String get inactivityThreshold;

  /// No description provided for @daysOfInactivityBeforeCleanup.
  ///
  /// In en, this message translates to:
  /// **'Days of inactivity before cleanup'**
  String get daysOfInactivityBeforeCleanup;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get systemMode;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @allowAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Allow Analytics'**
  String get allowAnalytics;

  /// No description provided for @privacyAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Privacy Analytics'**
  String get privacyAnalytics;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @resetReaderSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Reader Settings'**
  String get resetReaderSettings;

  /// No description provided for @resetReaderSettingsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will reset all reader settings to their default values:\n\n'**
  String get resetReaderSettingsConfirmation;

  /// No description provided for @readingModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading Mode: Horizontal Pages'**
  String get readingModeLabel;

  /// No description provided for @keepScreenOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On: Off'**
  String get keepScreenOnLabel;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On'**
  String get keepScreenOn;

  /// No description provided for @keepScreenOnDescription.
  ///
  /// In en, this message translates to:
  /// **'Prevent screen from turning off while reading'**
  String get keepScreenOnDescription;

  /// No description provided for @showUILabel.
  ///
  /// In en, this message translates to:
  /// **'Show UI: On'**
  String get showUILabel;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to proceed?'**
  String get areYouSure;

  /// No description provided for @readerSettingsResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reader settings have been reset to defaults.'**
  String get readerSettingsResetSuccess;

  /// No description provided for @failedToResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset settings: {error}'**
  String failedToResetSettings(Object error);

  /// No description provided for @readingHistory.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get readingHistory;

  /// No description provided for @clearAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear All History'**
  String get clearAllHistory;

  /// No description provided for @manualCleanup.
  ///
  /// In en, this message translates to:
  /// **'Manual Cleanup'**
  String get manualCleanup;

  /// No description provided for @cleanupSettings.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Settings'**
  String get cleanupSettings;

  /// No description provided for @removeFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove from History'**
  String get removeFromHistory;

  /// No description provided for @removeFromHistoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this item from reading history?'**
  String get removeFromHistoryQuestion;

  /// No description provided for @cleanup.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get cleanup;

  /// No description provided for @failedToLoadCleanupStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cleanup status'**
  String get failedToLoadCleanupStatus;

  /// No description provided for @manualCleanupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will perform cleanup based on your current settings. Continue?'**
  String get manualCleanupConfirmation;

  /// No description provided for @noReadingHistory.
  ///
  /// In en, this message translates to:
  /// **'No Reading History'**
  String get noReadingHistory;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error Loading History'**
  String get errorLoadingHistory;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get nextPage;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get previousPage;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get pageOf;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @exitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen'**
  String get exitFullscreen;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking connection...'**
  String get checkingConnection;

  /// No description provided for @backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online! All features available.'**
  String get backOnline;

  /// No description provided for @stillNoInternet.
  ///
  /// In en, this message translates to:
  /// **'Still no internet connection.'**
  String get stillNoInternet;

  /// No description provided for @unableToCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Unable to check connection.'**
  String get unableToCheckConnection;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @lowFaster.
  ///
  /// In en, this message translates to:
  /// **'Low (Faster)'**
  String get lowFaster;

  /// No description provided for @highBetterQuality.
  ///
  /// In en, this message translates to:
  /// **'High (Better Quality)'**
  String get highBetterQuality;

  /// No description provided for @originalLargest.
  ///
  /// In en, this message translates to:
  /// **'Original (Largest)'**
  String get originalLargest;

  /// No description provided for @lowQuality.
  ///
  /// In en, this message translates to:
  /// **'Low (Faster)'**
  String get lowQuality;

  /// No description provided for @mediumQuality.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumQuality;

  /// No description provided for @highQuality.
  ///
  /// In en, this message translates to:
  /// **'High (Better Quality)'**
  String get highQuality;

  /// No description provided for @originalQuality.
  ///
  /// In en, this message translates to:
  /// **'Original (Largest)'**
  String get originalQuality;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @amoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get amoled;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @goToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Go to Downloads'**
  String get goToDownloads;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hours(int count);

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String days(int count);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @unknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Title'**
  String get unknownTitle;

  /// No description provided for @offlineContentError.
  ///
  /// In en, this message translates to:
  /// **'Offline Content Error'**
  String get offlineContentError;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @confirmResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore all settings to default?'**
  String get confirmResetSettings;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @manageAutoCleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage automatic cleanup of reading history to free up storage space.'**
  String get manageAutoCleanupDescription;

  /// No description provided for @oneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// No description provided for @twoDays.
  ///
  /// In en, this message translates to:
  /// **'2 days'**
  String get twoDays;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get oneWeek;

  /// No description provided for @privacyInfoText.
  ///
  /// In en, this message translates to:
  /// **'• Data is stored on your device\n• Not sent to external servers\n• Only to improve app performance\n• Can be disabled anytime'**
  String get privacyInfoText;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @daysValue.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysValue(int days);

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps app development with local data (not shared)'**
  String get analyticsSubtitle;

  /// No description provided for @loadingContent.
  ///
  /// In en, this message translates to:
  /// **'Loading content...'**
  String get loadingContent;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading Error'**
  String get loadingError;

  /// No description provided for @jumpToPage.
  ///
  /// In en, this message translates to:
  /// **'Jump to Page'**
  String get jumpToPage;

  /// No description provided for @pageInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Page (1-{maxPages})'**
  String pageInputLabel(int maxPages);

  /// No description provided for @pageOfPages.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOfPages(int current, int total);

  /// No description provided for @jump.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get jump;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettings;

  /// No description provided for @readingMode.
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get readingMode;

  /// No description provided for @horizontalPages.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Pages'**
  String get horizontalPages;

  /// No description provided for @verticalPages.
  ///
  /// In en, this message translates to:
  /// **'Vertical Pages'**
  String get verticalPages;

  /// No description provided for @continuousScroll.
  ///
  /// In en, this message translates to:
  /// **'Continuous Scroll'**
  String get continuousScroll;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
