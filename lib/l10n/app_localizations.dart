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
  /// **'NhentaiApp'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enhanced Reading Experience'**
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

  /// No description provided for @appDisguise.
  ///
  /// In en, this message translates to:
  /// **'App Disguise'**
  String get appDisguise;

  /// No description provided for @disguiseMode.
  ///
  /// In en, this message translates to:
  /// **'Disguise Mode'**
  String get disguiseMode;

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

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get checkInternetConnection;

  /// No description provided for @trySwitchingNetwork.
  ///
  /// In en, this message translates to:
  /// **'Try switching between WiFi and mobile data'**
  String get trySwitchingNetwork;

  /// No description provided for @restartRouter.
  ///
  /// In en, this message translates to:
  /// **'Restart your router if using WiFi'**
  String get restartRouter;

  /// No description provided for @checkWebsiteStatus.
  ///
  /// In en, this message translates to:
  /// **'Check if the website is down'**
  String get checkWebsiteStatus;

  /// No description provided for @cloudflareBypassMessage.
  ///
  /// In en, this message translates to:
  /// **'The website is protected by Cloudflare. We\'re trying to bypass the protection.'**
  String get cloudflareBypassMessage;

  /// No description provided for @forceBypass.
  ///
  /// In en, this message translates to:
  /// **'Force Bypass'**
  String get forceBypass;

  /// No description provided for @unableToProcessData.
  ///
  /// In en, this message translates to:
  /// **'Unable to process the received data. The website structure might have changed.'**
  String get unableToProcessData;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @serverReturnedError.
  ///
  /// In en, this message translates to:
  /// **'Server returned error {statusCode}. The service might be temporarily unavailable.'**
  String serverReturnedError(int statusCode);

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

  /// No description provided for @shuffleToNextGallery.
  ///
  /// In en, this message translates to:
  /// **'Shuffle to next gallery'**
  String get shuffleToNextGallery;

  /// No description provided for @contentHidden.
  ///
  /// In en, this message translates to:
  /// **'Content Hidden'**
  String get contentHidden;

  /// No description provided for @tapToViewAnyway.
  ///
  /// In en, this message translates to:
  /// **'Tap to view anyway'**
  String get tapToViewAnyway;

  /// No description provided for @checkOutThisGallery.
  ///
  /// In en, this message translates to:
  /// **'Check out this gallery!'**
  String get checkOutThisGallery;

  /// No description provided for @galleriesPreloaded.
  ///
  /// In en, this message translates to:
  /// **'{count} galleries preloaded'**
  String galleriesPreloaded(int count);

  /// No description provided for @oopsSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get oopsSomethingWentWrong;

  /// No description provided for @cleanupInfo.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Info'**
  String get cleanupInfo;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history'**
  String get loadingHistory;

  /// No description provided for @clearingHistory.
  ///
  /// In en, this message translates to:
  /// **'Clearing history...'**
  String get clearingHistory;

  /// No description provided for @areYouSureClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all reading history? This action cannot be undone.'**
  String get areYouSureClearHistory;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @artistCg.
  ///
  /// In en, this message translates to:
  /// **'artist cg'**
  String get artistCg;

  /// No description provided for @gameCg.
  ///
  /// In en, this message translates to:
  /// **'game cg'**
  String get gameCg;

  /// No description provided for @manga.
  ///
  /// In en, this message translates to:
  /// **'manga'**
  String get manga;

  /// No description provided for @doujinshi.
  ///
  /// In en, this message translates to:
  /// **'doujinshi'**
  String get doujinshi;

  /// No description provided for @imageSet.
  ///
  /// In en, this message translates to:
  /// **'image set'**
  String get imageSet;

  /// No description provided for @cosplay.
  ///
  /// In en, this message translates to:
  /// **'cosplay'**
  String get cosplay;

  /// No description provided for @artistcg.
  ///
  /// In en, this message translates to:
  /// **'artistcg'**
  String get artistcg;

  /// No description provided for @gamecg.
  ///
  /// In en, this message translates to:
  /// **'gamecg'**
  String get gamecg;

  /// No description provided for @bigBreasts.
  ///
  /// In en, this message translates to:
  /// **'big breasts'**
  String get bigBreasts;

  /// No description provided for @soleFemale.
  ///
  /// In en, this message translates to:
  /// **'sole female'**
  String get soleFemale;

  /// No description provided for @soleMale.
  ///
  /// In en, this message translates to:
  /// **'sole male'**
  String get soleMale;

  /// No description provided for @fullColor.
  ///
  /// In en, this message translates to:
  /// **'full color'**
  String get fullColor;

  /// No description provided for @schoolgirlUniform.
  ///
  /// In en, this message translates to:
  /// **'schoolgirl uniform'**
  String get schoolgirlUniform;

  /// No description provided for @tryADifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryADifferentSearchTerm;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @loadingOfflineContent.
  ///
  /// In en, this message translates to:
  /// **'Loading offline content...'**
  String get loadingOfflineContent;

  /// No description provided for @excludeTags.
  ///
  /// In en, this message translates to:
  /// **'Exclude Tags'**
  String get excludeTags;

  /// No description provided for @excludeGroups.
  ///
  /// In en, this message translates to:
  /// **'Exclude Groups'**
  String get excludeGroups;

  /// No description provided for @excludeCharacters.
  ///
  /// In en, this message translates to:
  /// **'Exclude Characters'**
  String get excludeCharacters;

  /// No description provided for @excludeParodies.
  ///
  /// In en, this message translates to:
  /// **'Exclude Parodies'**
  String get excludeParodies;

  /// No description provided for @excludeArtists.
  ///
  /// In en, this message translates to:
  /// **'Exclude Artists'**
  String get excludeArtists;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search filters or search terms.'**
  String get tryAdjustingFilters;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get tryDifferentKeywords;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @accessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Access blocked. Trying to bypass protection...'**
  String get accessBlocked;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get tooManyRequests;

  /// No description provided for @errorProcessingResults.
  ///
  /// In en, this message translates to:
  /// **'Error processing search results. Please try again.'**
  String get errorProcessingResults;

  /// No description provided for @invalidSearchParameters.
  ///
  /// In en, this message translates to:
  /// **'Invalid search parameters. Please check your input.'**
  String get invalidSearchParameters;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// No description provided for @retryBypass.
  ///
  /// In en, this message translates to:
  /// **'Retry Bypass'**
  String get retryBypass;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// No description provided for @retrySearch.
  ///
  /// In en, this message translates to:
  /// **'Retry Search'**
  String get retrySearch;

  /// No description provided for @networkErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkErrorTitle;

  /// No description provided for @serverErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverErrorTitle;

  /// No description provided for @unknownErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Error'**
  String get unknownErrorTitle;

  /// No description provided for @loadingContent.
  ///
  /// In en, this message translates to:
  /// **'Loading content...'**
  String get loadingContent;

  /// No description provided for @refreshingContent.
  ///
  /// In en, this message translates to:
  /// **'Refreshing content...'**
  String get refreshingContent;

  /// No description provided for @loadingMoreContent.
  ///
  /// In en, this message translates to:
  /// **'Loading more content...'**
  String get loadingMoreContent;

  /// No description provided for @latestContent.
  ///
  /// In en, this message translates to:
  /// **'Latest Content'**
  String get latestContent;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @serverTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server is temporarily unavailable. Please try again later.'**
  String get serverTemporarilyUnavailable;

  /// No description provided for @failedToLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content'**
  String get failedToLoadContent;

  /// No description provided for @cloudflareProtectionDetected.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare protection detected. Please wait and try again.'**
  String get cloudflareProtectionDetected;

  /// No description provided for @tooManyRequestsWait.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment before trying again.'**
  String get tooManyRequestsWait;

  /// No description provided for @noContentFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No content found matching your search criteria. Try adjusting your filters.'**
  String get noContentFoundMatching;

  /// No description provided for @noContentFoundForTag.
  ///
  /// In en, this message translates to:
  /// **'No content found for tag \"{tagName}\".'**
  String noContentFoundForTag(String tagName);

  /// No description provided for @removeSomeFilters.
  ///
  /// In en, this message translates to:
  /// **'Remove some filters'**
  String get removeSomeFilters;

  /// No description provided for @checkSpelling.
  ///
  /// In en, this message translates to:
  /// **'Check spelling'**
  String get checkSpelling;

  /// No description provided for @useGeneralTerms.
  ///
  /// In en, this message translates to:
  /// **'Use more general search terms'**
  String get useGeneralTerms;

  /// No description provided for @browsePopularContent.
  ///
  /// In en, this message translates to:
  /// **'Browse popular content'**
  String get browsePopularContent;

  /// No description provided for @tryBrowsingOtherTags.
  ///
  /// In en, this message translates to:
  /// **'Try browsing other tags'**
  String get tryBrowsingOtherTags;

  /// No description provided for @checkPopularContent.
  ///
  /// In en, this message translates to:
  /// **'Check popular content'**
  String get checkPopularContent;

  /// No description provided for @useSearchFunction.
  ///
  /// In en, this message translates to:
  /// **'Use the search function'**
  String get useSearchFunction;

  /// No description provided for @checkInternetConnectionSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get checkInternetConnectionSuggestion;

  /// No description provided for @tryRefreshingPage.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing the page'**
  String get tryRefreshingPage;

  /// No description provided for @browsePopularContentSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Browse popular content'**
  String get browsePopularContentSuggestion;

  /// No description provided for @failedToInitializeSearch.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize search'**
  String get failedToInitializeSearch;

  /// No description provided for @noResultsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noResultsFoundFor(String query);

  /// No description provided for @searchingWithFilters.
  ///
  /// In en, this message translates to:
  /// **'Searching with filters...'**
  String get searchingWithFilters;

  /// No description provided for @noResultsFoundWithCurrentFilters.
  ///
  /// In en, this message translates to:
  /// **'No results found with current filters'**
  String get noResultsFoundWithCurrentFilters;

  /// No description provided for @invalidFilter.
  ///
  /// In en, this message translates to:
  /// **'Invalid filter: {errors}'**
  String invalidFilter(String errors);

  /// No description provided for @invalidSearchFilter.
  ///
  /// In en, this message translates to:
  /// **'Invalid search filter: {errors}'**
  String invalidSearchFilter(String errors);

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
  /// **'Download Started'**
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
  /// **'PDF conversion started for {contentId}'**
  String pdfConversionStarted(String contentId);

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

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated:'**
  String get lastUpdatedLabel;

  /// No description provided for @rangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Range:'**
  String get rangeLabel;

  /// No description provided for @ofWord.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofWord;

  /// No description provided for @waitAndTry.
  ///
  /// In en, this message translates to:
  /// **'Wait {minutes} minutes and try again'**
  String waitAndTry(int minutes);

  /// No description provided for @serviceUnderMaintenance.
  ///
  /// In en, this message translates to:
  /// **'The service might be under maintenance'**
  String get serviceUnderMaintenance;

  /// No description provided for @waitForBypass.
  ///
  /// In en, this message translates to:
  /// **'Wait for automatic bypass to complete'**
  String get waitForBypass;

  /// No description provided for @tryUsingVpn.
  ///
  /// In en, this message translates to:
  /// **'Try using a VPN if available'**
  String get tryUsingVpn;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back in a few minutes'**
  String get checkBackLater;

  /// No description provided for @tryRefreshingContent.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing the content'**
  String get tryRefreshingContent;

  /// No description provided for @checkForAppUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check if the app needs an update'**
  String get checkForAppUpdate;

  /// No description provided for @reportIfPersists.
  ///
  /// In en, this message translates to:
  /// **'Report the issue if it persists'**
  String get reportIfPersists;

  /// No description provided for @maintenanceTakesHours.
  ///
  /// In en, this message translates to:
  /// **'Maintenance usually takes a few hours'**
  String get maintenanceTakesHours;

  /// No description provided for @checkSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Check social media for updates'**
  String get checkSocialMedia;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get tryAgainLater;

  /// No description provided for @serverUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The server is currently unavailable. Please try again later.'**
  String get serverUnavailable;

  /// No description provided for @useBroaderSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Use broader search terms'**
  String get useBroaderSearchTerms;

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

  /// Message shown when user has no favorites
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Start adding content to your favorites!'**
  String get noFavoritesYet;

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
  /// **'Export Failed: {error}'**
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
  String failedToResetSettings(String error);

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

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

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
  /// **'{count}h'**
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

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}{suffix} ago'**
  String daysAgo(int count, String suffix);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}{suffix} ago'**
  String hoursAgo(int count, String suffix);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}{suffix} ago'**
  String minutesAgo(int count, String suffix);

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

  /// No description provided for @nextCleanup.
  ///
  /// In en, this message translates to:
  /// **'Next cleanup'**
  String get nextCleanup;

  /// No description provided for @historyStatistics.
  ///
  /// In en, this message translates to:
  /// **'History Statistics'**
  String get historyStatistics;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get totalItems;

  /// No description provided for @lastCleanup.
  ///
  /// In en, this message translates to:
  /// **'Last cleanup'**
  String get lastCleanup;

  /// No description provided for @lastAppAccess.
  ///
  /// In en, this message translates to:
  /// **'Last app access'**
  String get lastAppAccess;

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

  /// No description provided for @platformNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Platform Not Supported'**
  String get platformNotSupported;

  /// No description provided for @platformNotSupportedBody.
  ///
  /// In en, this message translates to:
  /// **'NhasixApp is designed exclusively for Android devices.'**
  String get platformNotSupportedBody;

  /// No description provided for @platformNotSupportedInstall.
  ///
  /// In en, this message translates to:
  /// **'Please install and run this app on an Android device.'**
  String get platformNotSupportedInstall;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required for downloads. Please grant storage permission in app settings.'**
  String get storagePermissionRequired;

  /// No description provided for @storagePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'This app needs storage permission to download files to your device. Files will be saved to the Downloads/nhasix folder.'**
  String get storagePermissionExplanation;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @storagePermissionSettingsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to download files. Please grant storage permission in app settings.'**
  String get storagePermissionSettingsPrompt;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @readingHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reading history will appear here as you read content.'**
  String get readingHistoryMessage;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get startReading;

  /// No description provided for @searchSomethingInteresting.
  ///
  /// In en, this message translates to:
  /// **'Search for something interesting'**
  String get searchSomethingInteresting;

  /// No description provided for @checkOutFeaturedItems.
  ///
  /// In en, this message translates to:
  /// **'Check out featured items'**
  String get checkOutFeaturedItems;

  /// No description provided for @appSubtitleDescription.
  ///
  /// In en, this message translates to:
  /// **'Nhentai unofficial client'**
  String get appSubtitleDescription;

  /// No description provided for @downloadedGalleries.
  ///
  /// In en, this message translates to:
  /// **'Downloaded galleries'**
  String get downloadedGalleries;

  /// No description provided for @favoriteGalleries.
  ///
  /// In en, this message translates to:
  /// **'Favorite galleries'**
  String get favoriteGalleries;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get viewHistory;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @downloadAllGalleries.
  ///
  /// In en, this message translates to:
  /// **'Download all galleries in this page'**
  String get downloadAllGalleries;

  /// No description provided for @enterPageNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter page number (1 - {totalPages})'**
  String enterPageNumber(int totalPages);

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page number'**
  String get pageNumber;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @validPageNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid page number between 1 and {totalPages}'**
  String validPageNumberError(int totalPages);

  /// No description provided for @tapToJump.
  ///
  /// In en, this message translates to:
  /// **'Tap to jump'**
  String get tapToJump;

  /// No description provided for @goToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to Page'**
  String get goToPage;

  /// No description provided for @previousPageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPageTooltip;

  /// No description provided for @nextPageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPageTooltip;

  /// No description provided for @tapToJumpToPage.
  ///
  /// In en, this message translates to:
  /// **'Tap to jump to page'**
  String get tapToJumpToPage;

  /// No description provided for @loadingContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading Content'**
  String get loadingContentTitle;

  /// No description provided for @loadingContentDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading Content Details'**
  String get loadingContentDetails;

  /// No description provided for @fetchingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Fetching metadata and images...'**
  String get fetchingMetadata;

  /// No description provided for @thisMayTakeMoments.
  ///
  /// In en, this message translates to:
  /// **'This may take a few moments'**
  String get thisMayTakeMoments;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Some features may be limited.'**
  String get youAreOffline;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnline;

  /// No description provided for @youAreOfflineTapToGoOnline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Tap to go online.'**
  String get youAreOfflineTapToGoOnline;

  /// No description provided for @contentInformation.
  ///
  /// In en, this message translates to:
  /// **'Content Information'**
  String get contentInformation;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreOptions;

  /// No description provided for @moreLikeThis.
  ///
  /// In en, this message translates to:
  /// **'More Like This'**
  String get moreLikeThis;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @shareContent.
  ///
  /// In en, this message translates to:
  /// **'Share Content'**
  String get shareContent;

  /// No description provided for @sharePanelOpened.
  ///
  /// In en, this message translates to:
  /// **'Share panel opened successfully!'**
  String get sharePanelOpened;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed, but link copied to clipboard'**
  String get shareFailed;

  /// No description provided for @downloadStartedFor.
  ///
  /// In en, this message translates to:
  /// **'Download started for \"{title}\"'**
  String downloadStartedFor(String title);

  /// No description provided for @viewDownloadsAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewDownloadsAction;

  /// No description provided for @failedToStartDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to start download: {error}'**
  String failedToStartDownload(String error);

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @failedToCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy link. Please try again.'**
  String get failedToCopyLink;

  /// No description provided for @copiedLink.
  ///
  /// In en, this message translates to:
  /// **'Copied Link'**
  String get copiedLink;

  /// No description provided for @linkCopiedToClipboardDescription.
  ///
  /// In en, this message translates to:
  /// **'The following link has been copied to your clipboard:'**
  String get linkCopiedToClipboardDescription;

  /// No description provided for @closeDialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeDialog;

  /// No description provided for @goOnlineDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnlineDialogTitle;

  /// No description provided for @goOnlineDialogContent.
  ///
  /// In en, this message translates to:
  /// **'You are currently in offline mode. Would you like to go online to access the latest content?'**
  String get goOnlineDialogContent;

  /// No description provided for @goingOnline.
  ///
  /// In en, this message translates to:
  /// **'Going online...'**
  String get goingOnline;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @pagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagesLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @artistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistLabel;

  /// No description provided for @charactersLabel.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get charactersLabel;

  /// No description provided for @parodiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Parodies'**
  String get parodiesLabel;

  /// No description provided for @groupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsLabel;

  /// No description provided for @uploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadedLabel;

  /// No description provided for @favoritesLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @artistsLabel.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artistsLabel;

  /// No description provided for @relatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get relatedLabel;

  /// No description provided for @yearAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} year{plural} ago'**
  String yearAgo(int count, String plural);

  /// No description provided for @monthAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} month{plural} ago'**
  String monthAgo(int count, String plural);

  /// No description provided for @dayAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} day{plural} ago'**
  String dayAgo(int count, String plural);

  /// No description provided for @hourAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hour{plural} ago'**
  String hourAgo(int count, String plural);

  /// No description provided for @selectFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select favorites'**
  String get selectFavoritesTooltip;

  /// No description provided for @deleteSelectedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelectedTooltip;

  /// No description provided for @selectAllAction.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllAction;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @selectedCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{selected} / {total}'**
  String selectedCountFormat(int selected, int total);

  /// No description provided for @loadingFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading favorites...'**
  String get loadingFavoritesMessage;

  /// No description provided for @deletingFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting favorites...'**
  String get deletingFavoritesMessage;

  /// No description provided for @removingFromFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Removing from favorites...'**
  String get removingFromFavoritesMessage;

  /// No description provided for @favoritesDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Favorites deleted successfully'**
  String get favoritesDeletedMessage;

  /// No description provided for @failedToDeleteFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete favorites'**
  String get failedToDeleteFavoritesMessage;

  /// No description provided for @confirmDeleteFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Favorites'**
  String get confirmDeleteFavoritesTitle;

  /// No description provided for @confirmDeleteFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} favorite{plural}?'**
  String confirmDeleteFavoritesMessage(int count, String plural);

  /// No description provided for @exportFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Favorites'**
  String get exportFavoritesTitle;

  /// No description provided for @exportingFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Exporting favorites...'**
  String get exportingFavoritesMessage;

  /// No description provided for @favoritesExportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Favorites exported successfully'**
  String get favoritesExportedMessage;

  /// No description provided for @failedToExportFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to export favorites'**
  String get failedToExportFavoritesMessage;

  /// No description provided for @searchFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Search favorites...'**
  String get searchFavoritesHint;

  /// No description provided for @searchOfflineContentHint.
  ///
  /// In en, this message translates to:
  /// **'Search offline content...'**
  String get searchOfflineContentHint;

  /// No description provided for @failedToLoadPage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load page {pageNumber}'**
  String failedToLoadPage(int pageNumber);

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @offlineContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Content'**
  String get offlineContentTitle;

  /// No description provided for @favorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get favorited;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @errorLoadingFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Favorites'**
  String get errorLoadingFavoritesTitle;

  /// No description provided for @filterDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Data'**
  String get filterDataTitle;

  /// No description provided for @clearAllAction.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllAction;

  /// No description provided for @searchFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Search {filterType}...'**
  String searchFilterHint(String filterType);

  /// No description provided for @selectedCountFormat2.
  ///
  /// In en, this message translates to:
  /// **'Selected ({count})'**
  String selectedCountFormat2(int count);

  /// No description provided for @errorLoadingFilterDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Error loading filter data'**
  String get errorLoadingFilterDataTitle;

  /// No description provided for @noFilterTypeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No {filterType} available'**
  String noFilterTypeAvailable(String filterType);

  /// No description provided for @noResultsFoundForQuery.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noResultsFoundForQuery(String query);

  /// No description provided for @contentNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Content Not Found'**
  String get contentNotFoundTitle;

  /// No description provided for @contentNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Content with ID \"{contentId}\" was not found.'**
  String contentNotFoundMessage(String contentId);

  /// No description provided for @filterCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Categories'**
  String get filterCategoriesTitle;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @advancedSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search'**
  String get advancedSearchTitle;

  /// No description provided for @enterSearchQueryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter search query (e.g. \"big breasts english\")'**
  String get enterSearchQueryHint;

  /// No description provided for @popularSearchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Searches'**
  String get popularSearchesTitle;

  /// No description provided for @recentSearchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearchesTitle;

  /// No description provided for @pressSearchButtonMessage.
  ///
  /// In en, this message translates to:
  /// **'Press the Search button to find content with your current filters'**
  String get pressSearchButtonMessage;

  /// No description provided for @searchingMessage.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingMessage;

  /// No description provided for @resultsCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCountFormat(String count);

  /// No description provided for @viewInMainAction.
  ///
  /// In en, this message translates to:
  /// **'View in Main'**
  String get viewInMainAction;

  /// No description provided for @searchErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Error'**
  String get searchErrorTitle;

  /// No description provided for @noResultsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFoundTitle;

  /// No description provided for @pageText.
  ///
  /// In en, this message translates to:
  /// **'page {pageNumber}'**
  String pageText(int pageNumber);

  /// No description provided for @pagesText.
  ///
  /// In en, this message translates to:
  /// **'pages {startPage}-{endPage}'**
  String pagesText(int startPage, int endPage);

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get offlineStatus;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get onlineStatus;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @tapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found for your search'**
  String get helpNoResults;

  /// No description provided for @helpTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try using different keywords or check your spelling'**
  String get helpTryDifferent;

  /// No description provided for @helpUseFilters.
  ///
  /// In en, this message translates to:
  /// **'Use filters to narrow down your search'**
  String get helpUseFilters;

  /// No description provided for @helpCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get helpCheckConnection;

  /// No description provided for @sendReportText.
  ///
  /// In en, this message translates to:
  /// **'Send Report'**
  String get sendReportText;

  /// No description provided for @technicalDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Details'**
  String get technicalDetailsTitle;

  /// No description provided for @reportSentText.
  ///
  /// In en, this message translates to:
  /// **'Report sent!'**
  String get reportSentText;

  /// No description provided for @suggestionCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get suggestionCheckConnection;

  /// No description provided for @suggestionTryWifiMobile.
  ///
  /// In en, this message translates to:
  /// **'Try switching between WiFi and mobile data'**
  String get suggestionTryWifiMobile;

  /// No description provided for @suggestionRestartRouter.
  ///
  /// In en, this message translates to:
  /// **'Restart your router if using WiFi'**
  String get suggestionRestartRouter;

  /// No description provided for @suggestionCheckWebsite.
  ///
  /// In en, this message translates to:
  /// **'Check if the website is down'**
  String get suggestionCheckWebsite;

  /// No description provided for @noContentFoundWithQuery.
  ///
  /// In en, this message translates to:
  /// **'No content found for \"{query}\". Try adjusting your search terms or filters.'**
  String noContentFoundWithQuery(String query);

  /// No description provided for @noContentFound.
  ///
  /// In en, this message translates to:
  /// **'No content found. Try adjusting your search terms or filters.'**
  String get noContentFound;

  /// No description provided for @suggestionTryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get suggestionTryDifferentKeywords;

  /// No description provided for @suggestionRemoveFilters.
  ///
  /// In en, this message translates to:
  /// **'Remove some filters'**
  String get suggestionRemoveFilters;

  /// No description provided for @suggestionCheckSpelling.
  ///
  /// In en, this message translates to:
  /// **'Check spelling'**
  String get suggestionCheckSpelling;

  /// No description provided for @suggestionUseBroaderTerms.
  ///
  /// In en, this message translates to:
  /// **'Use broader search terms'**
  String get suggestionUseBroaderTerms;

  /// No description provided for @underMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under Maintenance'**
  String get underMaintenanceTitle;

  /// No description provided for @underMaintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'The service is currently under maintenance. Please check back later.'**
  String get underMaintenanceMessage;

  /// No description provided for @suggestionMaintenanceHours.
  ///
  /// In en, this message translates to:
  /// **'Maintenance usually takes a few hours'**
  String get suggestionMaintenanceHours;

  /// No description provided for @suggestionCheckSocial.
  ///
  /// In en, this message translates to:
  /// **'Check social media for updates'**
  String get suggestionCheckSocial;

  /// No description provided for @suggestionTryLater.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get suggestionTryLater;

  /// No description provided for @includeFilter.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get includeFilter;

  /// No description provided for @excludeFilter.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get excludeFilter;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @downloadsFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} download{plural} failed'**
  String downloadsFailed(int count, String plural);

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @readingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get readingCompleted;

  /// No description provided for @readAgain.
  ///
  /// In en, this message translates to:
  /// **'Read Again'**
  String get readAgain;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @lessThanOneMinute.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 minute'**
  String get lessThanOneMinute;

  /// No description provided for @readingTime.
  ///
  /// In en, this message translates to:
  /// **'reading time'**
  String get readingTime;

  /// No description provided for @downloadActions.
  ///
  /// In en, this message translates to:
  /// **'Download Actions'**
  String get downloadActions;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @convertToPdf.
  ///
  /// In en, this message translates to:
  /// **'Convert to PDF'**
  String get convertToPdf;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @downloadActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get downloadActionPause;

  /// No description provided for @downloadActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get downloadActionResume;

  /// No description provided for @downloadActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloadActionCancel;

  /// No description provided for @downloadActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get downloadActionRetry;

  /// No description provided for @downloadActionConvertToPdf.
  ///
  /// In en, this message translates to:
  /// **'Convert to PDF'**
  String get downloadActionConvertToPdf;

  /// No description provided for @downloadActionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get downloadActionDetails;

  /// No description provided for @downloadActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get downloadActionRemove;

  /// No description provided for @downloadPagesRangeFormat.
  ///
  /// In en, this message translates to:
  /// **'{downloaded}/{total} (Pages {start}-{end} of {totalPages})'**
  String downloadPagesRangeFormat(
      int downloaded, int total, int start, int end, int totalPages);

  /// No description provided for @downloadPagesFormat.
  ///
  /// In en, this message translates to:
  /// **'{downloaded}/{total}'**
  String downloadPagesFormat(int downloaded, int total);

  /// No description provided for @downloadContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Content {contentId}'**
  String downloadContentTitle(String contentId);

  /// No description provided for @downloadEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA: {duration}'**
  String downloadEtaLabel(String duration);

  /// No description provided for @downloadSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Settings'**
  String get downloadSettingsTitle;

  /// No description provided for @performanceSection.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performanceSection;

  /// No description provided for @maxConcurrentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Max Concurrent Downloads'**
  String get maxConcurrentDownloads;

  /// No description provided for @concurrentDownloadsWarning.
  ///
  /// In en, this message translates to:
  /// **'Higher values may consume more bandwidth and device resources'**
  String get concurrentDownloadsWarning;

  /// No description provided for @imageQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Image Quality'**
  String get imageQualityLabel;

  /// No description provided for @autoRetrySection.
  ///
  /// In en, this message translates to:
  /// **'Auto Retry'**
  String get autoRetrySection;

  /// No description provided for @autoRetryFailedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Auto Retry Failed Downloads'**
  String get autoRetryFailedDownloads;

  /// No description provided for @autoRetryDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically retry failed downloads'**
  String get autoRetryDescription;

  /// No description provided for @maxRetryAttempts.
  ///
  /// In en, this message translates to:
  /// **'Max Retry Attempts'**
  String get maxRetryAttempts;

  /// No description provided for @networkSection.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkSection;

  /// No description provided for @wifiOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'WiFi Only'**
  String get wifiOnlyLabel;

  /// No description provided for @wifiOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Only download when connected to WiFi'**
  String get wifiOnlyDescription;

  /// No description provided for @downloadTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Download Timeout'**
  String get downloadTimeoutLabel;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @enableNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotificationsLabel;

  /// No description provided for @enableNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show notifications for download progress'**
  String get enableNotificationsDescription;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesUnit;

  /// No description provided for @searchContentHint.
  ///
  /// In en, this message translates to:
  /// **'Search content...'**
  String get searchContentHint;

  /// No description provided for @hideFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide filters'**
  String get hideFiltersTooltip;

  /// No description provided for @showMoreFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show more filters'**
  String get showMoreFiltersTooltip;

  /// No description provided for @advancedFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFiltersTitle;

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortByLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @includeTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Include tags (comma separated)'**
  String get includeTagsLabel;

  /// No description provided for @includeTagsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., romance, comedy, school'**
  String get includeTagsHint;

  /// No description provided for @excludeTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Exclude Tags'**
  String get excludeTagsLabel;

  /// No description provided for @excludeTagsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., horror, violence'**
  String get excludeTagsHint;

  /// No description provided for @artistsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., artist1, artist2'**
  String get artistsHint;

  /// No description provided for @pageCountRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Count Range'**
  String get pageCountRangeTitle;

  /// No description provided for @minPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Min pages'**
  String get minPagesLabel;

  /// No description provided for @maxPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Max pages'**
  String get maxPagesLabel;

  /// No description provided for @rangeToSeparator.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get rangeToSeparator;

  /// No description provided for @popularTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Tags'**
  String get popularTagsTitle;

  /// No description provided for @filtersActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get filtersActiveLabel;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllFilters;

  /// No description provided for @initializingApp.
  ///
  /// In en, this message translates to:
  /// **'Initializing Application...'**
  String get initializingApp;

  /// No description provided for @settingUpComponents.
  ///
  /// In en, this message translates to:
  /// **'Setting up components and checking connection...'**
  String get settingUpComponents;

  /// No description provided for @bypassingProtection.
  ///
  /// In en, this message translates to:
  /// **'Bypassing protection and establishing connection...'**
  String get bypassingProtection;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @readyToGo.
  ///
  /// In en, this message translates to:
  /// **'Ready to Go!'**
  String get readyToGo;

  /// No description provided for @launchingApp.
  ///
  /// In en, this message translates to:
  /// **'Launching main application...'**
  String get launchingApp;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imageNotAvailable;

  /// No description provided for @loadingPage.
  ///
  /// In en, this message translates to:
  /// **'Loading page {pageNumber}...'**
  String loadingPage(int pageNumber);

  /// No description provided for @selectedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedItemsCount(int count);

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get noImage;

  /// No description provided for @youAreOfflineShort.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get youAreOfflineShort;

  /// No description provided for @someFeaturesLimited.
  ///
  /// In en, this message translates to:
  /// **'Some features are limited. Connect to internet for full access.'**
  String get someFeaturesLimited;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'WIFI'**
  String get wifi;

  /// No description provided for @ethernet.
  ///
  /// In en, this message translates to:
  /// **'ETHERNET'**
  String get ethernet;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'MOBILE'**
  String get mobile;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get online;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @applySearch.
  ///
  /// In en, this message translates to:
  /// **'Apply Search'**
  String get applySearch;

  /// No description provided for @addFiltersToSearch.
  ///
  /// In en, this message translates to:
  /// **'Add filters above to enable search'**
  String get addFiltersToSearch;

  /// No description provided for @startSearching.
  ///
  /// In en, this message translates to:
  /// **'Start searching'**
  String get startSearching;

  /// No description provided for @enterKeywordsAdvancedHint.
  ///
  /// In en, this message translates to:
  /// **'Enter keywords, tags, or use advanced filters to find content'**
  String get enterKeywordsAdvancedHint;

  /// No description provided for @filtersReady.
  ///
  /// In en, this message translates to:
  /// **'Filters Ready'**
  String get filtersReady;

  /// No description provided for @clearAllFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get clearAllFiltersTooltip;

  /// No description provided for @offlineSomeFeaturesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Some features may not be available.'**
  String get offlineSomeFeaturesUnavailable;

  /// No description provided for @usingDownloadedContentOnly.
  ///
  /// In en, this message translates to:
  /// **'Using downloaded content only'**
  String get usingDownloadedContentOnly;

  /// No description provided for @onlineModeWithNetworkAccess.
  ///
  /// In en, this message translates to:
  /// **'Online mode with network access'**
  String get onlineModeWithNetworkAccess;

  /// No description provided for @tagsScreenPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tags Screen - To be implemented'**
  String get tagsScreenPlaceholder;

  /// No description provided for @artistsScreenPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Artists Screen - To be implemented'**
  String get artistsScreenPlaceholder;

  /// No description provided for @statusScreenPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Status Screen - To be implemented'**
  String get statusScreenPlaceholder;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundWithUri.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {uri}'**
  String pageNotFoundWithUri(String uri);

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @debugThemeInfo.
  ///
  /// In en, this message translates to:
  /// **'DEBUG: Theme Info'**
  String get debugThemeInfo;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @amoledTheme.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get amoledTheme;

  /// No description provided for @systemMessages.
  ///
  /// In en, this message translates to:
  /// **'System Messages and Background Services'**
  String get systemMessages;

  /// No description provided for @notificationMessages.
  ///
  /// In en, this message translates to:
  /// **'Notification Messages'**
  String get notificationMessages;

  /// No description provided for @convertingToPdf.
  ///
  /// In en, this message translates to:
  /// **'Converting to PDF...'**
  String get convertingToPdf;

  /// No description provided for @convertingToPdfWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Converting {title} to PDF...'**
  String convertingToPdfWithTitle(String title);

  /// No description provided for @convertingToPdfProgress.
  ///
  /// In en, this message translates to:
  /// **'Converting to PDF ({progress}%)'**
  String convertingToPdfProgress(Object progress);

  /// No description provided for @convertingToPdfProgressWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Converting {title} to PDF ({progress}%)'**
  String convertingToPdfProgressWithTitle(String title, int progress);

  /// No description provided for @pdfCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PDF Created Successfully'**
  String get pdfCreatedSuccessfully;

  /// No description provided for @pdfCreatedWithParts.
  ///
  /// In en, this message translates to:
  /// **'{title} converted to {partsCount} PDF files'**
  String pdfCreatedWithParts(String title, int partsCount);

  /// No description provided for @pdfConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF conversion failed for {contentId}: {error}'**
  String pdfConversionFailed(String contentId, String error);

  /// No description provided for @pdfConversionFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'PDF conversion failed for {title}: {error}'**
  String pdfConversionFailedWithError(String title, String error);

  /// No description provided for @downloadingWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading: {title}'**
  String downloadingWithTitle(String title);

  /// No description provided for @downloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading ({progress}%)'**
  String downloadingProgress(Object progress);

  /// No description provided for @downloadedWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded: {title}'**
  String downloadedWithTitle(String title);

  /// No description provided for @downloadFailedWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed: {title}'**
  String downloadFailedWithTitle(String title);

  /// No description provided for @downloadPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get downloadPaused;

  /// No description provided for @downloadResumed.
  ///
  /// In en, this message translates to:
  /// **'Resumed'**
  String get downloadResumed;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get downloadCancelled;

  /// No description provided for @downloadRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get downloadRetry;

  /// No description provided for @downloadOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get downloadOpen;

  /// No description provided for @pdfOpen.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get pdfOpen;

  /// No description provided for @pdfShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get pdfShare;

  /// No description provided for @pdfRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry PDF'**
  String get pdfRetry;

  /// No description provided for @downloadServiceMessages.
  ///
  /// In en, this message translates to:
  /// **'Download Service Messages'**
  String get downloadServiceMessages;

  /// No description provided for @downloadRangeInfo.
  ///
  /// In en, this message translates to:
  /// **' (Pages {startPage}-{endPage})'**
  String downloadRangeInfo(int startPage, int endPage);

  /// No description provided for @downloadRangeComplete.
  ///
  /// In en, this message translates to:
  /// **' (Pages {startPage}-{endPage})'**
  String downloadRangeComplete(int startPage, int endPage);

  /// No description provided for @invalidPageRange.
  ///
  /// In en, this message translates to:
  /// **'Invalid page range: {start}-{end} (total: {total})'**
  String invalidPageRange(int start, int end, int total);

  /// No description provided for @noDataReceived.
  ///
  /// In en, this message translates to:
  /// **'No data received for image: {url}'**
  String noDataReceived(String url);

  /// No description provided for @createdNoMediaFile.
  ///
  /// In en, this message translates to:
  /// **'Created .nomedia file for privacy: {path}'**
  String createdNoMediaFile(String path);

  /// No description provided for @privacyProtectionEnsured.
  ///
  /// In en, this message translates to:
  /// **'Privacy protection ensured for existing downloads'**
  String get privacyProtectionEnsured;

  /// No description provided for @pdfConversionMessages.
  ///
  /// In en, this message translates to:
  /// **'PDF Conversion Service Messages'**
  String get pdfConversionMessages;

  /// No description provided for @pdfConversionCompleted.
  ///
  /// In en, this message translates to:
  /// **'PDF conversion completed successfully for {contentId}'**
  String pdfConversionCompleted(String contentId);

  /// No description provided for @pdfPartProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing part {part} in isolate...'**
  String pdfPartProcessing(int part);

  /// No description provided for @pdfSingleProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing single PDF in isolate...'**
  String get pdfSingleProcessing;

  /// No description provided for @pdfSplitRequired.
  ///
  /// In en, this message translates to:
  /// **'Splitting into {totalParts} parts ({totalPages} pages)'**
  String pdfSplitRequired(int totalParts, int totalPages);

  /// No description provided for @pdfCreatedFiles.
  ///
  /// In en, this message translates to:
  /// **'Created {partsCount} PDF file(s) with {pageCount} total pages'**
  String pdfCreatedFiles(int partsCount, int pageCount);

  /// No description provided for @pdfNoImagesProvided.
  ///
  /// In en, this message translates to:
  /// **'No images provided for PDF conversion'**
  String get pdfNoImagesProvided;

  /// No description provided for @pdfFailedToCreatePart.
  ///
  /// In en, this message translates to:
  /// **'Failed to create PDF part {part}: {error}'**
  String pdfFailedToCreatePart(int part, String error);

  /// No description provided for @pdfFailedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create PDF: {error}'**
  String pdfFailedToCreate(String error);

  /// No description provided for @pdfOutputDirectoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Created PDF output directory: {path}'**
  String pdfOutputDirectoryCreated(String path);

  /// No description provided for @pdfUsingFallbackDirectory.
  ///
  /// In en, this message translates to:
  /// **'Using fallback directory: {path}'**
  String pdfUsingFallbackDirectory(String path);

  /// No description provided for @pdfInfoSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF info saved for {contentId} ({partsCount} parts, {pageCount} pages)'**
  String pdfInfoSaved(String contentId, int partsCount, int pageCount);

  /// No description provided for @pdfExistsForContent.
  ///
  /// In en, this message translates to:
  /// **'PDF exists for {contentId}: {exists}'**
  String pdfExistsForContent(String contentId, String exists);

  /// No description provided for @pdfFoundFiles.
  ///
  /// In en, this message translates to:
  /// **'Found {count} PDF file(s) for {contentId}'**
  String pdfFoundFiles(String contentId, int count);

  /// No description provided for @pdfDeletedFiles.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted {count} PDF file(s) for {contentId}'**
  String pdfDeletedFiles(String contentId, int count);

  /// No description provided for @pdfTotalSize.
  ///
  /// In en, this message translates to:
  /// **'Total PDF size for {contentId}: {sizeBytes} bytes'**
  String pdfTotalSize(String contentId, int sizeBytes);

  /// No description provided for @pdfCleanupStarted.
  ///
  /// In en, this message translates to:
  /// **'Starting PDF cleanup, deleting files older than {maxAge} days'**
  String pdfCleanupStarted(int maxAge);

  /// No description provided for @pdfCleanupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cleanup completed, deleted {deletedCount} old PDF files'**
  String pdfCleanupCompleted(int deletedCount);

  /// No description provided for @pdfStatistics.
  ///
  /// In en, this message translates to:
  /// **'PDF statistics - {totalFiles} files, {totalSizeFormatted} total size, {uniqueContents} unique contents, {averageFilesPerContent} avg files per content'**
  String pdfStatistics(Object averageFilesPerContent, Object totalFiles,
      Object totalSizeFormatted, Object uniqueContents);

  /// No description provided for @historyCleanupMessages.
  ///
  /// In en, this message translates to:
  /// **'History Cleanup Service Messages'**
  String get historyCleanupMessages;

  /// No description provided for @historyCleanupServiceInitialized.
  ///
  /// In en, this message translates to:
  /// **'History Cleanup Service initialized'**
  String get historyCleanupServiceInitialized;

  /// No description provided for @historyCleanupServiceDisposed.
  ///
  /// In en, this message translates to:
  /// **'History Cleanup Service disposed'**
  String get historyCleanupServiceDisposed;

  /// No description provided for @autoCleanupDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto cleanup history is disabled'**
  String get autoCleanupDisabled;

  /// No description provided for @cleanupServiceStarted.
  ///
  /// In en, this message translates to:
  /// **'Cleanup service started with {intervalHours}h interval'**
  String cleanupServiceStarted(int intervalHours);

  /// No description provided for @performingHistoryCleanup.
  ///
  /// In en, this message translates to:
  /// **'Performing history cleanup: {reason}'**
  String performingHistoryCleanup(String reason);

  /// No description provided for @historyCleanupCompleted.
  ///
  /// In en, this message translates to:
  /// **'History cleanup completed: cleared {clearedCount} entries ({reason})'**
  String historyCleanupCompleted(int clearedCount, String reason);

  /// No description provided for @manualHistoryCleanup.
  ///
  /// In en, this message translates to:
  /// **'Performing manual history cleanup'**
  String get manualHistoryCleanup;

  /// No description provided for @updatedLastAppAccess.
  ///
  /// In en, this message translates to:
  /// **'Updated last app access time'**
  String get updatedLastAppAccess;

  /// No description provided for @updatedLastCleanupTime.
  ///
  /// In en, this message translates to:
  /// **'Updated last cleanup time'**
  String get updatedLastCleanupTime;

  /// No description provided for @intervalCleanup.
  ///
  /// In en, this message translates to:
  /// **'Interval cleanup ({intervalHours}h)'**
  String intervalCleanup(int intervalHours);

  /// No description provided for @inactivityCleanup.
  ///
  /// In en, this message translates to:
  /// **'Inactivity cleanup ({inactivityDays} days)'**
  String inactivityCleanup(int inactivityDays);

  /// No description provided for @maxAgeCleanup.
  ///
  /// In en, this message translates to:
  /// **'Max age cleanup ({maxDays} days)'**
  String maxAgeCleanup(int maxDays);

  /// No description provided for @initialCleanupSetup.
  ///
  /// In en, this message translates to:
  /// **'Initial cleanup setup'**
  String get initialCleanupSetup;

  /// No description provided for @shouldCleanupOldHistory.
  ///
  /// In en, this message translates to:
  /// **'Should cleanup old history: {shouldCleanup}'**
  String shouldCleanupOldHistory(String shouldCleanup);

  /// No description provided for @analyticsMessages.
  ///
  /// In en, this message translates to:
  /// **'Analytics Service Messages'**
  String get analyticsMessages;

  /// No description provided for @analyticsServiceInitialized.
  ///
  /// In en, this message translates to:
  /// **'Analytics service initialized - tracking {enabled}'**
  String analyticsServiceInitialized(String enabled);

  /// No description provided for @analyticsTrackingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Analytics tracking enabled by user'**
  String get analyticsTrackingEnabled;

  /// No description provided for @analyticsTrackingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Analytics tracking disabled by user - data cleared'**
  String get analyticsTrackingDisabled;

  /// No description provided for @analyticsDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Analytics data cleared by user request'**
  String get analyticsDataCleared;

  /// No description provided for @analyticsServiceDisposed.
  ///
  /// In en, this message translates to:
  /// **'Analytics service disposed'**
  String get analyticsServiceDisposed;

  /// No description provided for @analyticsEventTracked.
  ///
  /// In en, this message translates to:
  /// **'📊 Analytics: {eventType} - {eventName}'**
  String analyticsEventTracked(String eventType, String eventName);

  /// No description provided for @appStartedEvent.
  ///
  /// In en, this message translates to:
  /// **'App started event tracked'**
  String get appStartedEvent;

  /// No description provided for @sessionEndEvent.
  ///
  /// In en, this message translates to:
  /// **'Session end event tracked ({minutes} minutes)'**
  String sessionEndEvent(int minutes);

  /// No description provided for @analyticsEnabledEvent.
  ///
  /// In en, this message translates to:
  /// **'Analytics enabled event tracked'**
  String get analyticsEnabledEvent;

  /// No description provided for @analyticsDisabledEvent.
  ///
  /// In en, this message translates to:
  /// **'Analytics disabled event tracked'**
  String get analyticsDisabledEvent;

  /// No description provided for @screenViewEvent.
  ///
  /// In en, this message translates to:
  /// **'Screen view tracked: {screenName}'**
  String screenViewEvent(String screenName);

  /// No description provided for @userActionEvent.
  ///
  /// In en, this message translates to:
  /// **'User action tracked: {action}'**
  String userActionEvent(String action);

  /// No description provided for @performanceEvent.
  ///
  /// In en, this message translates to:
  /// **'Performance tracked: {operation} ({durationMs}ms)'**
  String performanceEvent(String operation, int durationMs);

  /// No description provided for @errorEvent.
  ///
  /// In en, this message translates to:
  /// **'Error tracked: {errorType} - {errorMessage}'**
  String errorEvent(String errorType, String errorMessage);

  /// No description provided for @featureUsageEvent.
  ///
  /// In en, this message translates to:
  /// **'Feature usage tracked: {feature}'**
  String featureUsageEvent(String feature);

  /// No description provided for @readingSessionEvent.
  ///
  /// In en, this message translates to:
  /// **'Reading session tracked: {contentId} ({minutes}min, {pages} pages)'**
  String readingSessionEvent(String contentId, int minutes, int pages);

  /// No description provided for @offlineManagerMessages.
  ///
  /// In en, this message translates to:
  /// **'Offline Content Manager Messages'**
  String get offlineManagerMessages;

  /// No description provided for @offlineContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'Content {contentId} is available offline: {available}'**
  String offlineContentAvailable(String contentId, String available);

  /// No description provided for @offlineContentPath.
  ///
  /// In en, this message translates to:
  /// **'Offline content path for {contentId}: {path}'**
  String offlineContentPath(String contentId, String path);

  /// No description provided for @foundExistingFiles.
  ///
  /// In en, this message translates to:
  /// **'Found {count} existing downloaded files'**
  String foundExistingFiles(int count);

  /// No description provided for @offlineImageUrlsFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} offline image URLs for {contentId}'**
  String offlineImageUrlsFound(String contentId, int count);

  /// No description provided for @offlineContentIdsFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} offline content IDs'**
  String offlineContentIdsFound(int count);

  /// No description provided for @searchingOfflineContent.
  ///
  /// In en, this message translates to:
  /// **'Searching offline content for: {query}'**
  String searchingOfflineContent(String query);

  /// No description provided for @offlineContentMetadata.
  ///
  /// In en, this message translates to:
  /// **'Offline content metadata for {contentId}: {source}'**
  String offlineContentMetadata(String contentId, String source);

  /// No description provided for @offlineContentCreated.
  ///
  /// In en, this message translates to:
  /// **'Offline content created for {contentId}'**
  String offlineContentCreated(String contentId);

  /// No description provided for @offlineStorageUsage.
  ///
  /// In en, this message translates to:
  /// **'Offline storage usage: {sizeBytes} bytes'**
  String offlineStorageUsage(int sizeBytes);

  /// No description provided for @cleanupOrphanedFilesStarted.
  ///
  /// In en, this message translates to:
  /// **'Starting cleanup of orphaned offline files'**
  String get cleanupOrphanedFilesStarted;

  /// No description provided for @cleanupOrphanedFilesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cleanup of orphaned offline files completed'**
  String get cleanupOrphanedFilesCompleted;

  /// No description provided for @removedOrphanedDirectory.
  ///
  /// In en, this message translates to:
  /// **'Removed orphaned directory: {path}'**
  String removedOrphanedDirectory(String path);

  /// No description provided for @queryLabel.
  ///
  /// In en, this message translates to:
  /// **'Query'**
  String get queryLabel;

  /// No description provided for @excludeGroupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Exclude Groups'**
  String get excludeGroupsLabel;

  /// No description provided for @excludeCharactersLabel.
  ///
  /// In en, this message translates to:
  /// **'Exclude Characters'**
  String get excludeCharactersLabel;

  /// No description provided for @excludeParodiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Exclude Parodies'**
  String get excludeParodiesLabel;

  /// No description provided for @excludeArtistsLabel.
  ///
  /// In en, this message translates to:
  /// **'Exclude Artists'**
  String get excludeArtistsLabel;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String minutes(int count);

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String seconds(int count);

  /// No description provided for @loadingUserPreferences.
  ///
  /// In en, this message translates to:
  /// **'Loading user preferences'**
  String get loadingUserPreferences;

  /// No description provided for @successfullyLoadedUserPreferences.
  ///
  /// In en, this message translates to:
  /// **'Successfully loaded user preferences'**
  String get successfullyLoadedUserPreferences;

  /// No description provided for @invalidColumnsPortraitValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid columns portrait value: {value}'**
  String invalidColumnsPortraitValue(int value);

  /// No description provided for @invalidColumnsLandscapeValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid columns landscape value: {value}'**
  String invalidColumnsLandscapeValue(int value);

  /// No description provided for @updatingSettingsViaPreferencesService.
  ///
  /// In en, this message translates to:
  /// **'Updating settings via PreferencesService'**
  String get updatingSettingsViaPreferencesService;

  /// No description provided for @successfullyUpdatedSettings.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated settings'**
  String get successfullyUpdatedSettings;

  /// No description provided for @failedToUpdateSetting.
  ///
  /// In en, this message translates to:
  /// **'Failed to update setting: {error}'**
  String failedToUpdateSetting(String error);

  /// No description provided for @resettingAllSettingsToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Resetting all settings to defaults'**
  String get resettingAllSettingsToDefaults;

  /// No description provided for @successfullyResetAllSettingsToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Successfully reset all settings to defaults'**
  String get successfullyResetAllSettingsToDefaults;

  /// No description provided for @settingsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Settings not loaded'**
  String get settingsNotLoaded;

  /// No description provided for @exportingSettings.
  ///
  /// In en, this message translates to:
  /// **'Exporting settings'**
  String get exportingSettings;

  /// No description provided for @successfullyExportedSettings.
  ///
  /// In en, this message translates to:
  /// **'Successfully exported settings'**
  String get successfullyExportedSettings;

  /// No description provided for @failedToExportSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to export settings: {error}'**
  String failedToExportSettings(String error);

  /// No description provided for @importingSettings.
  ///
  /// In en, this message translates to:
  /// **'Importing settings'**
  String get importingSettings;

  /// No description provided for @successfullyImportedSettings.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported settings'**
  String get successfullyImportedSettings;

  /// No description provided for @failedToImportSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to import settings: {error}'**
  String failedToImportSettings(String error);

  /// Error message when settings cannot be synced
  ///
  /// In en, this message translates to:
  /// **'Unable to sync settings. Changes will be saved locally.'**
  String get unableToSyncSettings;

  /// Error message when settings cannot be saved due to storage issues
  ///
  /// In en, this message translates to:
  /// **'Unable to save settings. Please check device storage.'**
  String get unableToSaveSettings;

  /// Generic error message when settings update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update settings. Please try again.'**
  String get failedToUpdateSettings;

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get noHistoryFound;

  /// No description provided for @loadedHistoryEntries.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} history entries'**
  String loadedHistoryEntries(int count);

  /// No description provided for @failedToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history: {error}'**
  String failedToLoadHistory(String error);

  /// No description provided for @loadingMoreHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading more history (page {page})'**
  String loadingMoreHistory(int page);

  /// No description provided for @loadedMoreHistoryEntries.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} more entries, total: {total}'**
  String loadedMoreHistoryEntries(int count, int total);

  /// No description provided for @refreshingHistory.
  ///
  /// In en, this message translates to:
  /// **'Refreshing history'**
  String get refreshingHistory;

  /// No description provided for @refreshedHistoryWithEntries.
  ///
  /// In en, this message translates to:
  /// **'Refreshed history with {count} entries'**
  String refreshedHistoryWithEntries(int count);

  /// No description provided for @failedToRefreshHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh history: {error}'**
  String failedToRefreshHistory(String error);

  /// No description provided for @clearingAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clearing all history'**
  String get clearingAllHistory;

  /// No description provided for @allHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'All history cleared'**
  String get allHistoryCleared;

  /// No description provided for @failedToClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear history: {error}'**
  String failedToClearHistory(String error);

  /// No description provided for @removingHistoryItem.
  ///
  /// In en, this message translates to:
  /// **'Removing history item: {contentId}'**
  String removingHistoryItem(String contentId);

  /// No description provided for @removedHistoryItem.
  ///
  /// In en, this message translates to:
  /// **'Removed history item: {contentId}'**
  String removedHistoryItem(String contentId);

  /// No description provided for @failedToRemoveHistoryItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove history item: {error}'**
  String failedToRemoveHistoryItem(String error);

  /// No description provided for @performingManualHistoryCleanup.
  ///
  /// In en, this message translates to:
  /// **'Performing manual history cleanup'**
  String get performingManualHistoryCleanup;

  /// No description provided for @manualCleanupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Manual cleanup completed'**
  String get manualCleanupCompleted;

  /// No description provided for @failedToPerformCleanup.
  ///
  /// In en, this message translates to:
  /// **'Failed to perform cleanup: {error}'**
  String failedToPerformCleanup(String error);

  /// No description provided for @updatingCleanupSettings.
  ///
  /// In en, this message translates to:
  /// **'Updating cleanup settings'**
  String get updatingCleanupSettings;

  /// No description provided for @cleanupSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cleanup settings updated'**
  String get cleanupSettingsUpdated;

  /// No description provided for @addingContentToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Adding content to favorites: {title}'**
  String addingContentToFavorites(String title);

  /// No description provided for @successfullyAddedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Successfully added to favorites: {title}'**
  String successfullyAddedToFavorites(String title);

  /// No description provided for @contentNotInFavorites.
  ///
  /// In en, this message translates to:
  /// **'Content {contentId} is not in favorites, skipping removal'**
  String contentNotInFavorites(String contentId);

  /// No description provided for @callingRemoveFromFavoritesUseCase.
  ///
  /// In en, this message translates to:
  /// **'Calling removeFromFavoritesUseCase with params: {params}'**
  String callingRemoveFromFavoritesUseCase(String params);

  /// No description provided for @successfullyCalledRemoveFromFavoritesUseCase.
  ///
  /// In en, this message translates to:
  /// **'Successfully called removeFromFavoritesUseCase'**
  String get successfullyCalledRemoveFromFavoritesUseCase;

  /// No description provided for @updatingFavoritesListInState.
  ///
  /// In en, this message translates to:
  /// **'Updating favorites list in state, removing contentId: {contentId}'**
  String updatingFavoritesListInState(String contentId);

  /// No description provided for @favoritesCountBeforeAfter.
  ///
  /// In en, this message translates to:
  /// **'Favorites count: before={before}, after={after}'**
  String favoritesCountBeforeAfter(int before, int after);

  /// No description provided for @stateUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'State updated successfully'**
  String get stateUpdatedSuccessfully;

  /// No description provided for @successfullyRemovedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Successfully removed from favorites: {contentId}'**
  String successfullyRemovedFromFavorites(String contentId);

  /// No description provided for @errorRemovingContentFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error removing content {contentId} from favorites: {error}'**
  String errorRemovingContentFromFavorites(String contentId, String error);

  /// No description provided for @removingFavoritesInBatch.
  ///
  /// In en, this message translates to:
  /// **'Removing {count} favorites in batch'**
  String removingFavoritesInBatch(int count);

  /// No description provided for @successfullyRemovedFavoritesInBatch.
  ///
  /// In en, this message translates to:
  /// **'Successfully removed {count} favorites in batch'**
  String successfullyRemovedFavoritesInBatch(int count);

  /// No description provided for @searchingFavoritesWithQuery.
  ///
  /// In en, this message translates to:
  /// **'Searching favorites with query: {query}'**
  String searchingFavoritesWithQuery(String query);

  /// No description provided for @foundFavoritesMatchingQuery.
  ///
  /// In en, this message translates to:
  /// **'Found {count} favorites matching query'**
  String foundFavoritesMatchingQuery(int count);

  /// No description provided for @clearingFavoritesSearch.
  ///
  /// In en, this message translates to:
  /// **'Clearing favorites search'**
  String get clearingFavoritesSearch;

  /// No description provided for @exportingFavoritesData.
  ///
  /// In en, this message translates to:
  /// **'Exporting favorites data'**
  String get exportingFavoritesData;

  /// No description provided for @successfullyExportedFavorites.
  ///
  /// In en, this message translates to:
  /// **'Successfully exported {count} favorites'**
  String successfullyExportedFavorites(int count);

  /// No description provided for @importingFavoritesData.
  ///
  /// In en, this message translates to:
  /// **'Importing favorites data'**
  String get importingFavoritesData;

  /// No description provided for @successfullyImportedFavorites.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} favorites'**
  String successfullyImportedFavorites(int count);

  /// No description provided for @failedToImportFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to import favorite: {error}'**
  String failedToImportFavorite(String error);

  /// No description provided for @retryingFavoritesLoading.
  ///
  /// In en, this message translates to:
  /// **'Retrying favorites loading'**
  String get retryingFavoritesLoading;

  /// No description provided for @refreshingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Refreshing favorites'**
  String get refreshingFavorites;

  /// No description provided for @failedToLoadFavorites.
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites: {error}'**
  String failedToLoadFavorites(String error);

  /// No description provided for @failedToInitializeDownloadManager.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize download manager: {error}'**
  String failedToInitializeDownloadManager(String error);

  /// No description provided for @waitingForWifiConnection.
  ///
  /// In en, this message translates to:
  /// **'Waiting for WiFi connection'**
  String get waitingForWifiConnection;

  /// No description provided for @failedToQueueDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to queue download: {error}'**
  String failedToQueueDownload(String error);

  /// No description provided for @retryingDownload.
  ///
  /// In en, this message translates to:
  /// **'Retrying... ({current}/{total})'**
  String retryingDownload(int current, int total);

  /// No description provided for @downloadCancelledByUser.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled by user'**
  String get downloadCancelledByUser;

  /// No description provided for @failedToPauseDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to pause download: {error}'**
  String failedToPauseDownload(String error);

  /// No description provided for @failedToCancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel download: {error}'**
  String failedToCancelDownload(String error);

  /// No description provided for @failedToRetryDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to retry download: {error}'**
  String failedToRetryDownload(String error);

  /// No description provided for @failedToResumeDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to resume download: {error}'**
  String failedToResumeDownload(String error);

  /// No description provided for @failedToRemoveDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove download: {error}'**
  String failedToRemoveDownload(String error);

  /// No description provided for @failedToRefreshDownloads.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh downloads: {error}'**
  String failedToRefreshDownloads(String error);

  /// No description provided for @failedToUpdateDownloadSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to update download settings: {error}'**
  String failedToUpdateDownloadSettings(String error);

  /// No description provided for @pausingAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Pausing all downloads'**
  String get pausingAllDownloads;

  /// No description provided for @resumingAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Resuming all downloads'**
  String get resumingAllDownloads;

  /// No description provided for @cancellingAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Cancelling all downloads'**
  String get cancellingAllDownloads;

  /// No description provided for @clearingCompletedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Clearing completed downloads'**
  String get clearingCompletedDownloads;

  /// No description provided for @failedToPauseAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Failed to pause all downloads: {error}'**
  String failedToPauseAllDownloads(String error);

  /// No description provided for @failedToResumeAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Failed to resume all downloads: {error}'**
  String failedToResumeAllDownloads(String error);

  /// No description provided for @failedToCancelAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel all downloads: {error}'**
  String failedToCancelAllDownloads(String error);

  /// No description provided for @failedToQueueRangeDownload.
  ///
  /// In en, this message translates to:
  /// **'Failed to queue range download: {error}'**
  String failedToQueueRangeDownload(String error);

  /// No description provided for @failedToClearCompletedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear completed downloads: {error}'**
  String failedToClearCompletedDownloads(String error);

  /// No description provided for @downloadNotCompletedYet.
  ///
  /// In en, this message translates to:
  /// **'Download is not completed yet'**
  String get downloadNotCompletedYet;

  /// No description provided for @noImagesFoundForConversion.
  ///
  /// In en, this message translates to:
  /// **'No images found for conversion'**
  String get noImagesFoundForConversion;

  /// No description provided for @storageCleanupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Storage cleanup completed. Cleaned {cleanedFiles} directories, freed {freedSpace} MB'**
  String storageCleanupCompleted(int cleanedFiles, String freedSpace);

  /// No description provided for @storageCleanupComplete.
  ///
  /// In en, this message translates to:
  /// **'Storage Cleanup Complete: Cleaned {cleanedFiles} items, freed {freedSpace} MB'**
  String storageCleanupComplete(int cleanedFiles, String freedSpace);

  /// No description provided for @storageCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Storage Cleanup Failed: {error}'**
  String storageCleanupFailed(String error);

  /// No description provided for @exportDownloadsComplete.
  ///
  /// In en, this message translates to:
  /// **'Export Complete: Downloads exported to {fileName}'**
  String exportDownloadsComplete(String fileName);

  /// No description provided for @failedToDeleteDirectory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete directory: {path}, error: {error}'**
  String failedToDeleteDirectory(String path, String error);

  /// No description provided for @failedToDeleteTempFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete temp file: {path}, error: {error}'**
  String failedToDeleteTempFile(String path, String error);

  /// No description provided for @downloadDirectoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Download directory not found: {path}'**
  String downloadDirectoryNotFound(String path);

  /// No description provided for @cannotOpenIncompleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Cannot open - download not completed or path missing for {contentId}'**
  String cannotOpenIncompleteDownload(String contentId);

  /// No description provided for @errorOpeningDownloadedContent.
  ///
  /// In en, this message translates to:
  /// **'Error opening downloaded content: {error}'**
  String errorOpeningDownloadedContent(String error);

  /// No description provided for @allStrategiesFailedToOpenDownload.
  ///
  /// In en, this message translates to:
  /// **'All strategies failed to open downloaded content for {contentId}'**
  String allStrategiesFailedToOpenDownload(String contentId);

  /// No description provided for @failedToSaveProgressToDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to save progress to database: {error}'**
  String failedToSaveProgressToDatabase(String error);

  /// No description provided for @failedToUpdatePauseNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to update pause notification: {error}'**
  String failedToUpdatePauseNotification(String error);

  /// No description provided for @failedToUpdateResumeNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to update resume notification: {error}'**
  String failedToUpdateResumeNotification(String error);

  /// No description provided for @failedToUpdateNotificationProgress.
  ///
  /// In en, this message translates to:
  /// **'Failed to update notification progress: {error}'**
  String failedToUpdateNotificationProgress(String error);

  /// No description provided for @errorCalculatingDirectorySize.
  ///
  /// In en, this message translates to:
  /// **'Error calculating directory size: {error}'**
  String errorCalculatingDirectorySize(String error);

  /// No description provided for @errorCleaningTempFiles.
  ///
  /// In en, this message translates to:
  /// **'Error cleaning temp files in: {path}, error: {error}'**
  String errorCleaningTempFiles(String path, String error);

  /// No description provided for @errorDetectingDownloadsDirectory.
  ///
  /// In en, this message translates to:
  /// **'Error detecting Downloads directory: {error}'**
  String errorDetectingDownloadsDirectory(String error);

  /// No description provided for @usingEmergencyFallbackDirectory.
  ///
  /// In en, this message translates to:
  /// **'Using emergency fallback directory: {path}'**
  String usingEmergencyFallbackDirectory(String path);

  /// No description provided for @errorDuringStorageCleanup.
  ///
  /// In en, this message translates to:
  /// **'Error during storage cleanup'**
  String get errorDuringStorageCleanup;

  /// No description provided for @errorDuringExport.
  ///
  /// In en, this message translates to:
  /// **'Error during export'**
  String get errorDuringExport;

  /// No description provided for @errorDuringPdfConversion.
  ///
  /// In en, this message translates to:
  /// **'Error during PDF conversion for {contentId}'**
  String errorDuringPdfConversion(String contentId);

  /// No description provided for @errorRetryingPdfConversion.
  ///
  /// In en, this message translates to:
  /// **'Error retrying PDF conversion: {error}'**
  String errorRetryingPdfConversion(String error);

  /// No description provided for @importBackupFolder.
  ///
  /// In en, this message translates to:
  /// **'Import Backup Folder'**
  String get importBackupFolder;

  /// No description provided for @importBackupFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the path to your backup folder containing nhasix content folders:'**
  String get importBackupFolderDescription;

  /// No description provided for @scanningBackupFolder.
  ///
  /// In en, this message translates to:
  /// **'Scanning backup folder...'**
  String get scanningBackupFolder;

  /// No description provided for @backupContentFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} backup items'**
  String backupContentFound(int count);

  /// No description provided for @noBackupContentFound.
  ///
  /// In en, this message translates to:
  /// **'No valid content found in backup folder'**
  String get noBackupContentFound;

  /// No description provided for @errorScanningBackup.
  ///
  /// In en, this message translates to:
  /// **'Error scanning backup: {error}'**
  String errorScanningBackup(String error);

  /// No description provided for @themeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred color theme for the app interface.'**
  String get themeDescription;

  /// No description provided for @imageQualityDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose image quality for downloads. Higher quality uses more storage and data.'**
  String get imageQualityDescription;

  /// No description provided for @gridColumnsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how many columns to display content in portrait mode. More columns show more content but smaller items.'**
  String get gridColumnsDescription;

  /// No description provided for @gridPreview.
  ///
  /// In en, this message translates to:
  /// **'Grid Preview'**
  String get gridPreview;

  /// No description provided for @autoCleanupDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage automatic cleanup of reading history to free up storage space.'**
  String get autoCleanupDescription;

  /// No description provided for @testCacheClearing.
  ///
  /// In en, this message translates to:
  /// **'Test App Update Cache Clearing'**
  String get testCacheClearing;

  /// No description provided for @testCacheClearingDescription.
  ///
  /// In en, this message translates to:
  /// **'Simulate app update and test cache clearing behavior.'**
  String get testCacheClearingDescription;

  /// No description provided for @forceClearCache.
  ///
  /// In en, this message translates to:
  /// **'Force Clear All Caches'**
  String get forceClearCache;

  /// No description provided for @forceClearCacheDescription.
  ///
  /// In en, this message translates to:
  /// **'Manually clear all image caches.'**
  String get forceClearCacheDescription;

  /// No description provided for @runTest.
  ///
  /// In en, this message translates to:
  /// **'Run Test'**
  String get runTest;

  /// No description provided for @clearCacheButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheButton;

  /// No description provided for @disguiseModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app appears in your launcher for privacy.'**
  String get disguiseModeDescription;

  /// No description provided for @applyingDisguiseMode.
  ///
  /// In en, this message translates to:
  /// **'Applying disguise mode changes...'**
  String get applyingDisguiseMode;

  /// No description provided for @disguiseDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get disguiseDefault;

  /// No description provided for @disguiseCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get disguiseCalculator;

  /// No description provided for @disguiseNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get disguiseNotes;

  /// No description provided for @disguiseWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get disguiseWeather;

  /// No description provided for @storagePermissionScan.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required to scan backup folders'**
  String get storagePermissionScan;

  /// No description provided for @syncResult.
  ///
  /// In en, this message translates to:
  /// **'Synced: {synced} new, {updated} updated'**
  String syncResult(int synced, int updated);

  /// No description provided for @exportingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exporting Library'**
  String get exportingLibrary;

  /// No description provided for @libraryExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Library exported successfully!'**
  String get libraryExportSuccess;

  /// No description provided for @browseDownloads.
  ///
  /// In en, this message translates to:
  /// **'Browse Downloads'**
  String get browseDownloads;

  /// No description provided for @deletingContent.
  ///
  /// In en, this message translates to:
  /// **'Deleting {title}...'**
  String deletingContent(String title);

  /// No description provided for @contentDeletedFreed.
  ///
  /// In en, this message translates to:
  /// **'{title} deleted. Freed {size} MB'**
  String contentDeletedFreed(String title, String size);

  /// No description provided for @failedToDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete {title}'**
  String failedToDeleteContent(String title);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @contentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Content deleted'**
  String get contentDeleted;

  /// No description provided for @cacheManagementDebug.
  ///
  /// In en, this message translates to:
  /// **'🚀 Cache Management (Debug)'**
  String get cacheManagementDebug;
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
