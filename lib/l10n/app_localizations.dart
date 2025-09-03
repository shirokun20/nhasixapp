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

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

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

  /// No description provided for @removeFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove from History'**
  String get removeFromHistory;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

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

  /// No description provided for @noReadingHistory.
  ///
  /// In en, this message translates to:
  /// **'No Reading History'**
  String get noReadingHistory;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error Loading History'**
  String get errorLoadingHistory;

  /// No description provided for @offlineContentError.
  ///
  /// In en, this message translates to:
  /// **'Offline Content Error'**
  String get offlineContentError;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Download Error'**
  String get downloadError;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

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
