import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Week Counter'**
  String get appTitle;

  /// No description provided for @navCountdown.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get navCountdown;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @untilWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend in'**
  String get untilWeekend;

  /// No description provided for @untilLongWeekend.
  ///
  /// In en, this message translates to:
  /// **'Long weekend in'**
  String get untilLongWeekend;

  /// No description provided for @untilHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday in'**
  String get untilHoliday;

  /// No description provided for @untilDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Days off in'**
  String get untilDaysOff;

  /// No description provided for @youreOff.
  ///
  /// In en, this message translates to:
  /// **'You\'re off!'**
  String get youreOff;

  /// No description provided for @backToWorkIn.
  ///
  /// In en, this message translates to:
  /// **'Back to work in'**
  String get backToWorkIn;

  /// No description provided for @backToWorkAt.
  ///
  /// In en, this message translates to:
  /// **'Back to work {when}'**
  String backToWorkAt(String when);

  /// No description provided for @noWorkAhead.
  ///
  /// In en, this message translates to:
  /// **'No workdays ahead'**
  String get noWorkAhead;

  /// No description provided for @inShiftUntil.
  ///
  /// In en, this message translates to:
  /// **'In shift until {time}'**
  String inShiftUntil(String time);

  /// No description provided for @daysOffCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day off} other{{count} days off}}'**
  String daysOffCount(int count);

  /// No description provided for @dayShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get dayShort;

  /// No description provided for @hourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// No description provided for @minuteShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteShort;

  /// No description provided for @kindWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get kindWeekend;

  /// No description provided for @kindLongWeekend.
  ///
  /// In en, this message translates to:
  /// **'Long weekend'**
  String get kindLongWeekend;

  /// No description provided for @kindHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get kindHoliday;

  /// No description provided for @kindDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Days off'**
  String get kindDaysOff;

  /// No description provided for @noneComing.
  ///
  /// In en, this message translates to:
  /// **'None in the next year'**
  String get noneComing;

  /// No description provided for @noWorkdaysTitle.
  ///
  /// In en, this message translates to:
  /// **'No workdays set'**
  String get noWorkdaysTitle;

  /// No description provided for @noWorkdaysBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your workdays in Schedule to start the countdown.'**
  String get noWorkdaysBody;

  /// No description provided for @noDaysOffTitle.
  ///
  /// In en, this message translates to:
  /// **'No days off ahead'**
  String get noDaysOffTitle;

  /// No description provided for @noDaysOffBody.
  ///
  /// In en, this message translates to:
  /// **'Every day in the next year is a workday. Mark days off in the calendar.'**
  String get noDaysOffBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open schedule'**
  String get openSettings;

  /// No description provided for @openCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get openCalendar;

  /// No description provided for @holidaysNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load public holidays for {years}. Weekends are still counted.'**
  String holidaysNotLoaded(String years);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @legendWeekend.
  ///
  /// In en, this message translates to:
  /// **'weekends'**
  String get legendWeekend;

  /// No description provided for @legendHoliday.
  ///
  /// In en, this message translates to:
  /// **'holiday'**
  String get legendHoliday;

  /// No description provided for @legendDayOff.
  ///
  /// In en, this message translates to:
  /// **'vacation'**
  String get legendDayOff;

  /// No description provided for @calendarHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to change it. Long-press to select several days.'**
  String get calendarHint;

  /// No description provided for @overrideAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get overrideAuto;

  /// No description provided for @overrideDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get overrideDayOff;

  /// No description provided for @overrideWorkday.
  ///
  /// In en, this message translates to:
  /// **'Workday'**
  String get overrideWorkday;

  /// No description provided for @statusWorkday.
  ///
  /// In en, this message translates to:
  /// **'Workday'**
  String get statusWorkday;

  /// No description provided for @statusDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get statusDayOff;

  /// No description provided for @statusExtraWorkday.
  ///
  /// In en, this message translates to:
  /// **'Workday (moved)'**
  String get statusExtraWorkday;

  /// No description provided for @holidayIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored: marked as a workday'**
  String get holidayIgnored;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Note, e.g. vacation (optional)'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @daysSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day selected} other{{count} days selected}}'**
  String daysSelected(int count);

  /// No description provided for @markDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Mark as days off'**
  String get markDaysOff;

  /// No description provided for @resetToAuto.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetToAuto;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @noCountry.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get noCountry;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @noCountryOption.
  ///
  /// In en, this message translates to:
  /// **'No public holidays'**
  String get noCountryOption;

  /// No description provided for @holidaysUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String holidaysUpdated(String date);

  /// No description provided for @holidaysNotLoadedYet.
  ///
  /// In en, this message translates to:
  /// **'Not loaded yet'**
  String get holidaysNotLoadedYet;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load. Check your internet connection.'**
  String get loadFailed;

  /// No description provided for @workdays.
  ///
  /// In en, this message translates to:
  /// **'Workdays'**
  String get workdays;

  /// No description provided for @endsNextDay.
  ///
  /// In en, this message translates to:
  /// **'Ends the next day'**
  String get endsNextDay;

  /// No description provided for @perDayHours.
  ///
  /// In en, this message translates to:
  /// **'Different hours per day'**
  String get perDayHours;

  /// No description provided for @addWidget.
  ///
  /// In en, this message translates to:
  /// **'Add widget to home screen'**
  String get addWidget;

  /// No description provided for @preciseWidget.
  ///
  /// In en, this message translates to:
  /// **'Precise widget countdown'**
  String get preciseWidget;

  /// No description provided for @preciseWidgetHint.
  ///
  /// In en, this message translates to:
  /// **'Allow alarms & reminders so the widget ticks every second. Otherwise it updates about every 30 minutes.'**
  String get preciseWidgetHint;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'Public holidays from Nager.Date (date.nager.at)'**
  String get dataSource;

  /// No description provided for @weekdayName.
  ///
  /// In en, this message translates to:
  /// **'{day, select, 1{Monday} 2{Tuesday} 3{Wednesday} 4{Thursday} 5{Friday} 6{Saturday} 7{Sunday} other{Friday}}'**
  String weekdayName(String day);

  /// No description provided for @monthIn.
  ///
  /// In en, this message translates to:
  /// **'{month, select, 1{in January} 2{in February} 3{in March} 4{in April} 5{in May} 6{in June} 7{in July} 8{in August} 9{in September} 10{in October} 11{in November} 12{in December} other{this month}}'**
  String monthIn(String month);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String durationDays(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String durationHours(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String durationMinutes(int count);

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String durationSeconds(int count);

  /// No description provided for @timerDay.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get timerDay;

  /// No description provided for @timerHour.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get timerHour;

  /// No description provided for @timerMinute.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get timerMinute;

  /// No description provided for @whenToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get whenToday;

  /// No description provided for @whenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get whenTomorrow;

  /// No description provided for @whenAt.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String whenAt(String day, String time);

  /// No description provided for @eyebrowUntil.
  ///
  /// In en, this message translates to:
  /// **'until'**
  String get eyebrowUntil;

  /// No description provided for @eyebrowFreedom.
  ///
  /// In en, this message translates to:
  /// **'freedom'**
  String get eyebrowFreedom;

  /// No description provided for @eyebrowLastHourPrefix.
  ///
  /// In en, this message translates to:
  /// **'freedom in'**
  String get eyebrowLastHourPrefix;

  /// No description provided for @eyebrowLastHourStrike.
  ///
  /// In en, this message translates to:
  /// **'forever'**
  String get eyebrowLastHourStrike;

  /// No description provided for @eyebrowLastHourSuffix.
  ///
  /// In en, this message translates to:
  /// **'under an hour'**
  String get eyebrowLastHourSuffix;

  /// No description provided for @eyebrowOffStrike.
  ///
  /// In en, this message translates to:
  /// **'until work'**
  String get eyebrowOffStrike;

  /// No description provided for @eyebrowWeekendLeft.
  ///
  /// In en, this message translates to:
  /// **'weekend left'**
  String get eyebrowWeekendLeft;

  /// No description provided for @eyebrowLongWeekendLeft.
  ///
  /// In en, this message translates to:
  /// **'long weekend left'**
  String get eyebrowLongWeekendLeft;

  /// No description provided for @eyebrowHolidayStrike.
  ///
  /// In en, this message translates to:
  /// **'workday'**
  String get eyebrowHolidayStrike;

  /// No description provided for @eyebrowHolidayLeft.
  ///
  /// In en, this message translates to:
  /// **'holiday'**
  String get eyebrowHolidayLeft;

  /// No description provided for @weekDone.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the week done'**
  String weekDone(int percent);

  /// No description provided for @backToWorkLower.
  ///
  /// In en, this message translates to:
  /// **'back to work'**
  String get backToWorkLower;

  /// No description provided for @orbTip.
  ///
  /// In en, this message translates to:
  /// **'tap the orb for a new line'**
  String get orbTip;

  /// No description provided for @orbLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% done. Tap for a new line'**
  String orbLabel(int percent);

  /// No description provided for @jokesLabel.
  ///
  /// In en, this message translates to:
  /// **'Lines of the week'**
  String get jokesLabel;

  /// No description provided for @jokesMore.
  ///
  /// In en, this message translates to:
  /// **'Other lines'**
  String get jokesMore;

  /// No description provided for @hintCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'Count public holidays'**
  String get hintCountryTitle;

  /// No description provided for @hintCountryBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your country so holidays shorten the week'**
  String get hintCountryBody;

  /// No description provided for @hintHolidaysFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Holidays not loaded'**
  String get hintHolidaysFailedTitle;

  /// No description provided for @weekendLonger.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The weekend is 1 day longer} other{The weekend is {count} days longer}}'**
  String weekendLonger(int count);

  /// No description provided for @widgetTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Countdown on your home screen'**
  String get widgetTipTitle;

  /// No description provided for @widgetTipBody.
  ///
  /// In en, this message translates to:
  /// **'Add the widget in half a minute'**
  String get widgetTipBody;

  /// No description provided for @widgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgetsTitle;

  /// No description provided for @widgetStepIos1.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on the home screen'**
  String get widgetStepIos1;

  /// No description provided for @widgetStepIos2.
  ///
  /// In en, this message translates to:
  /// **'Tap Edit, then Add Widget'**
  String get widgetStepIos2;

  /// No description provided for @widgetStepIos3.
  ///
  /// In en, this message translates to:
  /// **'Find Week Counter and pick a size'**
  String get widgetStepIos3;

  /// No description provided for @widgetStepAndroid1.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on the home screen'**
  String get widgetStepAndroid1;

  /// No description provided for @widgetStepAndroid2.
  ///
  /// In en, this message translates to:
  /// **'Open Widgets'**
  String get widgetStepAndroid2;

  /// No description provided for @widgetStepAndroid3.
  ///
  /// In en, this message translates to:
  /// **'Find Week Counter and drag it onto the screen'**
  String get widgetStepAndroid3;

  /// No description provided for @widgetUpdatesNote.
  ///
  /// In en, this message translates to:
  /// **'The numbers update on their own, even when the app is closed.'**
  String get widgetUpdatesNote;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @daysOffIn.
  ///
  /// In en, this message translates to:
  /// **'Days off {monthIn}'**
  String daysOffIn(String monthIn);

  /// No description provided for @holidayOn.
  ///
  /// In en, this message translates to:
  /// **'holiday {date}'**
  String holidayOn(String date);

  /// No description provided for @noHolidaysShort.
  ///
  /// In en, this message translates to:
  /// **'no holidays'**
  String get noHolidaysShort;

  /// No description provided for @upcomingHolidays.
  ///
  /// In en, this message translates to:
  /// **'Upcoming holidays'**
  String get upcomingHolidays;

  /// No description provided for @noUpcomingHolidays.
  ///
  /// In en, this message translates to:
  /// **'Choose a country to see public holidays'**
  String get noUpcomingHolidays;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changes save right away. The countdown and widget update on their own.'**
  String get settingsSubtitle;

  /// No description provided for @workdaysHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to pick your own'**
  String get workdaysHint;

  /// No description provided for @shiftStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get shiftStartsAt;

  /// No description provided for @shiftEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get shiftEndsAt;

  /// No description provided for @celebrateWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend!'**
  String get celebrateWeekend;

  /// No description provided for @celebrateLongWeekend.
  ///
  /// In en, this message translates to:
  /// **'Long weekend!'**
  String get celebrateLongWeekend;

  /// No description provided for @celebrateHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday!'**
  String get celebrateHoliday;

  /// No description provided for @celebrateDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Time off!'**
  String get celebrateDaysOff;

  /// No description provided for @celebrateEyebrow.
  ///
  /// In en, this message translates to:
  /// **'the week is done'**
  String get celebrateEyebrow;

  /// No description provided for @celebrateLateEyebrow.
  ///
  /// In en, this message translates to:
  /// **'late, but from the heart'**
  String get celebrateLateEyebrow;

  /// No description provided for @celebrateWas.
  ///
  /// In en, this message translates to:
  /// **'work'**
  String get celebrateWas;

  /// No description provided for @celebrateBody.
  ///
  /// In en, this message translates to:
  /// **'Work\'s over. The next {duration} are yours.'**
  String celebrateBody(String duration);

  /// No description provided for @celebrateBodyOpen.
  ///
  /// In en, this message translates to:
  /// **'Work\'s over. Enjoy it.'**
  String get celebrateBodyOpen;

  /// No description provided for @celebrateLateBody.
  ///
  /// In en, this message translates to:
  /// **'The week ended {when}. Celebrating anyway.'**
  String celebrateLateBody(String when);

  /// No description provided for @celebrateCta.
  ///
  /// In en, this message translates to:
  /// **'Yay, time to rest'**
  String get celebrateCta;

  /// No description provided for @navAwards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get navAwards;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @weekHeader.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekHeader;

  /// No description provided for @weekStarts.
  ///
  /// In en, this message translates to:
  /// **'Week starts'**
  String get weekStarts;

  /// No description provided for @weekEnds.
  ///
  /// In en, this message translates to:
  /// **'Week ends'**
  String get weekEnds;

  /// No description provided for @holidaysShort.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysShort;

  /// No description provided for @holidaysShortHint.
  ///
  /// In en, this message translates to:
  /// **'Short weeks and transfers'**
  String get holidaysShortHint;

  /// No description provided for @sectionExtras.
  ///
  /// In en, this message translates to:
  /// **'Widgets and effects'**
  String get sectionExtras;

  /// No description provided for @confetti.
  ///
  /// In en, this message translates to:
  /// **'Confetti'**
  String get confetti;

  /// No description provided for @confettiHint.
  ///
  /// In en, this message translates to:
  /// **'With Reduce Motion on, you get a still card instead'**
  String get confettiHint;

  /// No description provided for @confettiHintAndroid.
  ///
  /// In en, this message translates to:
  /// **'With animations off in Settings, you get a still card instead'**
  String get confettiHintAndroid;

  /// No description provided for @weeksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String weeksCount(int count);

  /// No description provided for @vacationTitle.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get vacationTitle;

  /// No description provided for @vacationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get vacationNone;

  /// No description provided for @vacationIntro.
  ///
  /// In en, this message translates to:
  /// **'On vacation we count the days until you\'re back. Weeks for awards are kept.'**
  String get vacationIntro;

  /// No description provided for @vacationHowLong.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get vacationHowLong;

  /// No description provided for @vacationFrom.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get vacationFrom;

  /// No description provided for @vacationWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} wk'**
  String vacationWeeks(int count);

  /// No description provided for @vacationFromTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get vacationFromTomorrow;

  /// No description provided for @vacationFromMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get vacationFromMonday;

  /// No description provided for @vacationGo.
  ///
  /// In en, this message translates to:
  /// **'Go on vacation for {days}'**
  String vacationGo(String days);

  /// No description provided for @vacationActive.
  ///
  /// In en, this message translates to:
  /// **'You\'re on vacation'**
  String get vacationActive;

  /// No description provided for @vacationPlanned.
  ///
  /// In en, this message translates to:
  /// **'Vacation planned'**
  String get vacationPlanned;

  /// No description provided for @vacationActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Until {date} inclusive. We count the days until you\'re back; weeks for awards are kept.'**
  String vacationActiveBody(String date);

  /// No description provided for @vacationPlannedBody.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to} inclusive. We count the days until you\'re back; weeks for awards are kept.'**
  String vacationPlannedBody(String from, String to);

  /// No description provided for @vacationEndEarly.
  ///
  /// In en, this message translates to:
  /// **'Come back early'**
  String get vacationEndEarly;

  /// No description provided for @vacationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel vacation'**
  String get vacationCancel;

  /// No description provided for @vacationNote.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get vacationNote;

  /// No description provided for @untilInclusive.
  ///
  /// In en, this message translates to:
  /// **'Until {date} inclusive'**
  String untilInclusive(String date);

  /// No description provided for @holidayMidweek.
  ///
  /// In en, this message translates to:
  /// **'A holiday mid-week. Back to work {when}'**
  String holidayMidweek(String when);

  /// No description provided for @eyebrowVacationPrefix.
  ///
  /// In en, this message translates to:
  /// **'vacation · until'**
  String get eyebrowVacationPrefix;

  /// No description provided for @eyebrowVacationStrike.
  ///
  /// In en, this message translates to:
  /// **'work'**
  String get eyebrowVacationStrike;

  /// No description provided for @eyebrowVacationSuffix.
  ///
  /// In en, this message translates to:
  /// **'you\'re back'**
  String get eyebrowVacationSuffix;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbStart;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbStep.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {m}'**
  String onbStep(int n, int m);

  /// No description provided for @onbWelcomePrefix.
  ///
  /// In en, this message translates to:
  /// **'Counting down to'**
  String get onbWelcomePrefix;

  /// No description provided for @onbWelcomeStrike.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get onbWelcomeStrike;

  /// No description provided for @onbWelcomeSuffix.
  ///
  /// In en, this message translates to:
  /// **'freedom'**
  String get onbWelcomeSuffix;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us when your work week ends. The orb fills up toward the weekend, and there\'s a small party when it arrives.'**
  String get onbWelcomeBody;

  /// No description provided for @onbTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you work?'**
  String get onbTypeTitle;

  /// No description provided for @onbFiveDay.
  ///
  /// In en, this message translates to:
  /// **'Five-day week'**
  String get onbFiveDay;

  /// No description provided for @onbFiveDayHint.
  ///
  /// In en, this message translates to:
  /// **'Mon–Fri, weekends on Saturday and Sunday'**
  String get onbFiveDayHint;

  /// No description provided for @onbCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own schedule'**
  String get onbCustom;

  /// No description provided for @onbCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Your own days, for example Tue–Sat'**
  String get onbCustomHint;

  /// No description provided for @onbTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'When is your work week?'**
  String get onbTimeTitle;

  /// No description provided for @onbWidgetBody.
  ///
  /// In en, this message translates to:
  /// **'The widget shows how much is left, even when the app is closed.'**
  String get onbWidgetBody;

  /// No description provided for @onbHowToWidget.
  ///
  /// In en, this message translates to:
  /// **'How to add the widget'**
  String get onbHowToWidget;

  /// No description provided for @onbNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onbNotNow;

  /// No description provided for @awardsHero.
  ///
  /// In en, this message translates to:
  /// **'times you made it\nto the weekend'**
  String get awardsHero;

  /// No description provided for @awardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no awards yet} =1{1 award} other{{count} awards}}'**
  String awardsCount(int count);

  /// No description provided for @awardsMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String awardsMore(int count);

  /// No description provided for @awardsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get awardsWeekly;

  /// No description provided for @awardsSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get awardsSpecial;

  /// No description provided for @awardsProgress.
  ///
  /// In en, this message translates to:
  /// **'{got} of {total} earned'**
  String awardsProgress(int got, int total);

  /// No description provided for @awardLocked.
  ///
  /// In en, this message translates to:
  /// **'not earned yet'**
  String get awardLocked;

  /// No description provided for @awardEarnedOn.
  ///
  /// In en, this message translates to:
  /// **'earned {date}'**
  String awardEarnedOn(String date);

  /// No description provided for @awardWeeksLeft.
  ///
  /// In en, this message translates to:
  /// **'{weeks} to go'**
  String awardWeeksLeft(String weeks);

  /// No description provided for @awardNew.
  ///
  /// In en, this message translates to:
  /// **'New award: {name}'**
  String awardNew(String name);

  /// No description provided for @celebrateWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks} behind you'**
  String celebrateWeeks(String weeks);

  /// No description provided for @celebrateNext.
  ///
  /// In en, this message translates to:
  /// **'{weeks} to “{name}”'**
  String celebrateNext(String weeks, String name);

  /// No description provided for @celebrateAllDone.
  ///
  /// In en, this message translates to:
  /// **'Every weekly award is yours'**
  String get celebrateAllDone;

  /// No description provided for @atNight.
  ///
  /// In en, this message translates to:
  /// **'{day}, at night'**
  String atNight(String day);

  /// No description provided for @widgetSetUp.
  ///
  /// In en, this message translates to:
  /// **'Open the app to set up'**
  String get widgetSetUp;

  /// No description provided for @tabTracker.
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get tabTracker;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @sectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get sectionOverdue;

  /// No description provided for @sectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sectionToday;

  /// No description provided for @sectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get sectionTomorrow;

  /// No description provided for @sectionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get sectionLater;

  /// No description provided for @sectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sectionCompleted;

  /// No description provided for @categoryStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get categoryStudy;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @reminderPresetNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get reminderPresetNone;

  /// No description provided for @reminderPreset5m.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get reminderPreset5m;

  /// No description provided for @reminderPreset30m.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get reminderPreset30m;

  /// No description provided for @reminderPreset1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get reminderPreset1h;

  /// No description provided for @reminderPreset1d.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get reminderPreset1d;

  /// No description provided for @reminderBeforeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min before'**
  String reminderBeforeMinutes(int count);

  /// No description provided for @reminderBeforeHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h before'**
  String reminderBeforeHours(int count);

  /// No description provided for @reminderBeforeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day before} other{{count} days before}}'**
  String reminderBeforeDays(int count);

  /// No description provided for @dueYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String dueYesterday(String time);

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {time}'**
  String dueTomorrow(String time);

  /// No description provided for @dueOnDate.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String dueOnDate(String date, String time);

  /// No description provided for @tasksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmptyTitle;

  /// No description provided for @tasksEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first one'**
  String get tasksEmptyBody;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @tasksFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this category'**
  String get tasksFilterEmptyTitle;

  /// No description provided for @tasksFilterEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another filter or add a new task'**
  String get tasksFilterEmptyBody;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String taskDeleted(String title);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markDone;

  /// No description provided for @markNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get markNotDone;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes.'**
  String get discardBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @taskHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskHint;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dateTomorrow;

  /// No description provided for @permExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms permission'**
  String get permExactTitle;

  /// No description provided for @permExactBody.
  ///
  /// In en, this message translates to:
  /// **'Umytpa needs permission to schedule exact alarms so your reminders ring right on time. Tap Continue to open settings.'**
  String get permExactBody;

  /// No description provided for @permFullScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Full-screen reminder permission'**
  String get permFullScreenTitle;

  /// No description provided for @permFullScreenBody.
  ///
  /// In en, this message translates to:
  /// **'Umytpa can display reminders over locked screens like an alarm clock. Tap Continue to enable full-screen alerts in settings.'**
  String get permFullScreenBody;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @notificationsOffBanner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. The task can still be saved, but reminders will not fire.'**
  String get notificationsOffBanner;

  /// No description provided for @openSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettingsAction;

  /// No description provided for @errTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get errTitleRequired;

  /// No description provided for @errTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title must be at most {max} characters'**
  String errTitleTooLong(int max);

  /// No description provided for @errDeadlinePast.
  ///
  /// In en, this message translates to:
  /// **'Deadline must be in the future'**
  String get errDeadlinePast;

  /// No description provided for @warnReminderPassed.
  ///
  /// In en, this message translates to:
  /// **'Reminder time has already passed. The task will be saved without a notification.'**
  String get warnReminderPassed;

  /// No description provided for @errInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get errInvalidInput;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageButton.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageButton;

  /// No description provided for @repeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatLabel;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @subtasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get subtasksLabel;

  /// No description provided for @subtaskHint.
  ///
  /// In en, this message translates to:
  /// **'Add a step'**
  String get subtaskHint;

  /// No description provided for @subtaskProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String subtaskProgress(int done, int total);

  /// No description provided for @widgetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get widgetToday;

  /// No description provided for @widgetNothingNext.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get widgetNothingNext;

  /// No description provided for @widgetAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done 🎉'**
  String get widgetAllDone;

  /// No description provided for @todayLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing left} =1{1 task left} other{{count} tasks left}}'**
  String todayLeft(int count);

  /// No description provided for @todayDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String todayDoneOf(int done, int total);

  /// No description provided for @todayNothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for today'**
  String get todayNothingPlanned;

  /// No description provided for @todayAllDone.
  ///
  /// In en, this message translates to:
  /// **'Everything done — nice work!'**
  String get todayAllDone;

  /// No description provided for @todayNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String todayNext(String title);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String streakDays(int count);

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsOpen.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsOpen;

  /// No description provided for @statsDoneTotal.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statsDoneTotal;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get statsCurrentStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get statsBestStreak;

  /// No description provided for @statsFocusTotal.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get statsFocusTotal;

  /// No description provided for @statsLast7Done.
  ///
  /// In en, this message translates to:
  /// **'Completed, last 7 days'**
  String get statsLast7Done;

  /// No description provided for @statsLast7Focus.
  ///
  /// In en, this message translates to:
  /// **'Focus minutes, last 7 days'**
  String get statsLast7Focus;

  /// No description provided for @statsByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get statsByCategory;

  /// No description provided for @statsBestDay.
  ///
  /// In en, this message translates to:
  /// **'Most productive day'**
  String get statsBestDay;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'Finish a task to see your stats'**
  String get statsNoData;

  /// No description provided for @statsBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get statsBadges;

  /// No description provided for @statsDaysShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get statsDaysShort;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @hoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String hoursMinutesShort(int hours, int minutes);

  /// No description provided for @badgeFirstDone.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get badgeFirstDone;

  /// No description provided for @badgeFirstDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a task'**
  String get badgeFirstDoneDesc;

  /// No description provided for @badgeTenDone.
  ///
  /// In en, this message translates to:
  /// **'Getting going'**
  String get badgeTenDone;

  /// No description provided for @badgeTenDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 tasks'**
  String get badgeTenDoneDesc;

  /// No description provided for @badgeFiftyDone.
  ///
  /// In en, this message translates to:
  /// **'On a roll'**
  String get badgeFiftyDone;

  /// No description provided for @badgeFiftyDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 tasks'**
  String get badgeFiftyDoneDesc;

  /// No description provided for @badgeHundredDone.
  ///
  /// In en, this message translates to:
  /// **'Centurion'**
  String get badgeHundredDone;

  /// No description provided for @badgeHundredDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 tasks'**
  String get badgeHundredDoneDesc;

  /// No description provided for @badgeStreak3.
  ///
  /// In en, this message translates to:
  /// **'Three in a row'**
  String get badgeStreak3;

  /// No description provided for @badgeStreak3Desc.
  ///
  /// In en, this message translates to:
  /// **'3-day streak'**
  String get badgeStreak3Desc;

  /// No description provided for @badgeStreak7.
  ///
  /// In en, this message translates to:
  /// **'Perfect week'**
  String get badgeStreak7;

  /// No description provided for @badgeStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'7-day streak'**
  String get badgeStreak7Desc;

  /// No description provided for @badgeStreak30.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get badgeStreak30;

  /// No description provided for @badgeStreak30Desc.
  ///
  /// In en, this message translates to:
  /// **'30-day streak'**
  String get badgeStreak30Desc;

  /// No description provided for @badgeFocusHour.
  ///
  /// In en, this message translates to:
  /// **'In the zone'**
  String get badgeFocusHour;

  /// No description provided for @badgeFocusHourDesc.
  ///
  /// In en, this message translates to:
  /// **'Focus for 1 hour in total'**
  String get badgeFocusHourDesc;

  /// No description provided for @badgeFocusTen.
  ///
  /// In en, this message translates to:
  /// **'Deep work'**
  String get badgeFocusTen;

  /// No description provided for @badgeFocusTenDesc.
  ///
  /// In en, this message translates to:
  /// **'Focus for 10 hours in total'**
  String get badgeFocusTenDesc;

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// No description provided for @focusStart.
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get focusStart;

  /// No description provided for @focusStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get focusStop;

  /// No description provided for @focusWithTask.
  ///
  /// In en, this message translates to:
  /// **'Working on: {title}'**
  String focusWithTask(String title);

  /// No description provided for @focusNoTask.
  ///
  /// In en, this message translates to:
  /// **'Free focus session'**
  String get focusNoTask;

  /// No description provided for @focusMinutesOption.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String focusMinutesOption(int count);

  /// No description provided for @focusDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Session complete!'**
  String get focusDoneTitle;

  /// No description provided for @focusDoneBody.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes of focus saved.'**
  String focusDoneBody(int count);

  /// No description provided for @focusMarkTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Mark task done'**
  String get focusMarkTaskDone;

  /// No description provided for @focusClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get focusClose;

  /// No description provided for @focusRunning.
  ///
  /// In en, this message translates to:
  /// **'Stay with it'**
  String get focusRunning;

  /// No description provided for @focusNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus session finished'**
  String get focusNotifTitle;

  /// No description provided for @focusNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Time for a break.'**
  String get focusNotifBody;

  /// No description provided for @focusTask.
  ///
  /// In en, this message translates to:
  /// **'Focus on this task'**
  String get focusTask;

  /// No description provided for @smartApply.
  ///
  /// In en, this message translates to:
  /// **'Apply: {summary}'**
  String smartApply(String summary);

  /// No description provided for @smartHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: “Lab report tomorrow 18:00 #study”'**
  String get smartHint;

  /// No description provided for @allDoneCelebrate.
  ///
  /// In en, this message translates to:
  /// **'All done for today!'**
  String get allDoneCelebrate;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
