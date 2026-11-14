// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'Демалыс санағышы';

  @override
  String get navCountdown => 'Апта';

  @override
  String get navCalendar => 'Күнтізбе';

  @override
  String get untilWeekend => 'Демалысқа дейін';

  @override
  String get untilLongWeekend => 'Ұзақ демалысқа дейін';

  @override
  String get untilHoliday => 'Мерекеге дейін';

  @override
  String get untilDaysOff => 'Демалысқа дейін';

  @override
  String get youreOff => 'Сіз демалыстасыз!';

  @override
  String get backToWorkIn => 'Жұмысқа дейін';

  @override
  String backToWorkAt(String when) {
    return 'Жұмысқа: $when';
  }

  @override
  String get noWorkAhead => 'Жұмыс күндері жоспарланбаған';

  @override
  String inShiftUntil(String time) {
    return 'Ауысым $time дейін';
  }

  @override
  String daysOffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count демалыс күні',
    );
    return '$_temp0';
  }

  @override
  String get dayShort => 'к';

  @override
  String get hourShort => 'сағ';

  @override
  String get minuteShort => 'мин';

  @override
  String get kindWeekend => 'Демалыс';

  @override
  String get kindLongWeekend => 'Ұзақ демалыс';

  @override
  String get kindHoliday => 'Мереке';

  @override
  String get kindDaysOff => 'Демалыс';

  @override
  String get noneComing => 'Алдағы жылда болмайды';

  @override
  String get noWorkdaysTitle => 'Жұмыс күндері таңдалмаған';

  @override
  String get noWorkdaysBody =>
      'Санақты бастау үшін «Кесте» бөлімінде жұмыс күндерін таңдаңыз.';

  @override
  String get noDaysOffTitle => 'Демалыс күндері жоқ';

  @override
  String get noDaysOffBody =>
      'Келесі жылдың бәрі жұмыс күндері. Күнтізбеде демалыс күндерін белгілеңіз.';

  @override
  String get openSettings => 'Кестені ашу';

  @override
  String get openCalendar => 'Күнтізбені ашу';

  @override
  String holidaysNotLoaded(String years) {
    return '$years жылдардың мерекелерін жүктеу мүмкін болмады. Демалыс күндері бәрібір есепке алынады.';
  }

  @override
  String get retry => 'Қайталау';

  @override
  String get legendWeekend => 'демалыс';

  @override
  String get legendHoliday => 'мереке';

  @override
  String get legendDayOff => 'демалыс күні';

  @override
  String get calendarHint =>
      'Күнді өзгерту үшін басыңыз. Бірнеше күнді таңдау үшін басып тұрыңыз.';

  @override
  String get overrideAuto => 'Авто';

  @override
  String get overrideDayOff => 'Демалыс';

  @override
  String get overrideWorkday => 'Жұмыс күні';

  @override
  String get statusWorkday => 'Жұмыс күні';

  @override
  String get statusDayOff => 'Демалыс күні';

  @override
  String get statusExtraWorkday => 'Жұмыс күні (ауыстырылған)';

  @override
  String get holidayIgnored => 'Есепке алынбайды: жұмыс күні деп белгіленген';

  @override
  String get noteHint => 'Жазба, мысалы «демалыс» (міндетті емес)';

  @override
  String get save => 'Сақтау';

  @override
  String get cancel => 'Бас тарту';

  @override
  String daysSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн таңдалды',
    );
    return '$_temp0';
  }

  @override
  String get markDaysOff => 'Демалыс күні ету';

  @override
  String get resetToAuto => 'Қалпына келтіру';

  @override
  String get country => 'Ел';

  @override
  String get noCountry => 'Таңдалмаған';

  @override
  String get searchCountry => 'Елді іздеу';

  @override
  String get noCountryOption => 'Мерекесіз';

  @override
  String holidaysUpdated(String date) {
    return 'Жаңартылды: $date';
  }

  @override
  String get holidaysNotLoadedYet => 'Әлі жүктелмеген';

  @override
  String get refresh => 'Жаңарту';

  @override
  String get loadFailed =>
      'Жүктеу мүмкін болмады. Интернет байланысын тексеріңіз.';

  @override
  String get workdays => 'Жұмыс күндері';

  @override
  String get endsNextDay => 'Келесі күні аяқталады';

  @override
  String get perDayHours => 'Күндер бойынша әртүрлі уақыт';

  @override
  String get addWidget => 'Виджетті экранға қосу';

  @override
  String get preciseWidget => 'Виджеттегі нақты санақ';

  @override
  String get preciseWidgetHint =>
      'Виджет әр секунд сайын жаңарып тұруы үшін «Оятқыштар мен еске салғыштарға» рұқсат беріңіз. Әйтпесе ол шамамен 30 минутта бір рет жаңарады.';

  @override
  String get allow => 'Рұқсат беру';

  @override
  String get sectionAbout => 'Қолданба туралы';

  @override
  String get dataSource => 'Мерекелер: Nager.Date (date.nager.at)';

  @override
  String weekdayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'дүйсенбі',
      '2': 'сейсенбі',
      '3': 'сәрсенбі',
      '4': 'бейсенбі',
      '5': 'жұма',
      '6': 'сенбі',
      '7': 'жексенбі',
      'other': 'жұма',
    });
    return '$_temp0';
  }

  @override
  String monthIn(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'қаңтарда',
      '2': 'ақпанда',
      '3': 'наурызда',
      '4': 'сәуірде',
      '5': 'мамырда',
      '6': 'маусымда',
      '7': 'шілдеде',
      '8': 'тамызда',
      '9': 'қыркүйекте',
      '10': 'қазанда',
      '11': 'қарашада',
      '12': 'желтоқсанда',
      'other': 'осы айда',
    });
    return '$_temp0';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сағат',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    return '$count мин';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунд',
    );
    return '$_temp0';
  }

  @override
  String get timerDay => 'к';

  @override
  String get timerHour => 'с';

  @override
  String get timerMinute => 'м';

  @override
  String get whenToday => 'бүгін';

  @override
  String get whenTomorrow => 'ертең';

  @override
  String whenAt(String day, String time) {
    return '$day, $time';
  }

  @override
  String get eyebrowUntil => 'дейін';

  @override
  String get eyebrowFreedom => 'бостандыққа';

  @override
  String get eyebrowLastHourPrefix => 'бостандыққа дейін';

  @override
  String get eyebrowLastHourStrike => 'мәңгілік';

  @override
  String get eyebrowLastHourSuffix => 'бір сағаттан аз';

  @override
  String get eyebrowOffStrike => 'жұмысқа дейін';

  @override
  String get eyebrowWeekendLeft => 'демалысқа дейін';

  @override
  String get eyebrowLongWeekendLeft => 'ұзақ демалысқа дейін';

  @override
  String get eyebrowHolidayStrike => 'жұмыс күні';

  @override
  String get eyebrowHolidayLeft => 'мереке';

  @override
  String weekDone(int percent) {
    return 'Аптаның $percent% өтті';
  }

  @override
  String get backToWorkLower => 'қайта жұмысқа';

  @override
  String get orbTip => 'сөйлемді ауыстыру үшін шарды басыңыз';

  @override
  String orbLabel(int percent) {
    return '$percent% өтті. Сөйлемді ауыстыру үшін басыңыз';
  }

  @override
  String get jokesLabel => 'Аптаның сөйлемдері';

  @override
  String get jokesMore => 'Басқа сөйлемдер';

  @override
  String get hintCountryTitle => 'Мерекелерді ескеру';

  @override
  String get hintCountryBody => 'Елді таңдаңыз, мерекелер аптаны қысқартады';

  @override
  String get hintHolidaysFailedTitle => 'Мерекелер жүктелмеді';

  @override
  String weekendLonger(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Демалыс $count күнге ұзарады',
    );
    return '$_temp0';
  }

  @override
  String get widgetTipTitle => 'Басты экрандағы таймер';

  @override
  String get widgetTipBody => 'Виджетті жарты минутта қосыңыз';

  @override
  String get widgetsTitle => 'Виджеттер';

  @override
  String get widgetStepIos1 => '«Басты» экранның бос жерін басып тұрыңыз';

  @override
  String get widgetStepIos2 =>
      '«Өңдеу» түймесін, содан кейін «Виджет қосу» түймесін басыңыз';

  @override
  String get widgetStepIos3 => '«Демалыс санағышын» тауып, өлшемін таңдаңыз';

  @override
  String get widgetStepAndroid1 => 'Басты экранның бос жерін басып тұрыңыз';

  @override
  String get widgetStepAndroid2 => '«Виджеттер» бөлімін ашыңыз';

  @override
  String get widgetStepAndroid3 =>
      '«Демалыс санағышын» тауып, экранға сүйреңіз';

  @override
  String get widgetUpdatesNote =>
      'Сандар қолданба жабық болса да өзі жаңарады.';

  @override
  String get gotIt => 'Түсінікті';

  @override
  String get done => 'Дайын';

  @override
  String get close => 'Жабу';

  @override
  String get back => 'Артқа';

  @override
  String get today => 'Бүгін';

  @override
  String daysOffIn(String monthIn) {
    return '$monthIn бос күндер';
  }

  @override
  String holidayOn(String date) {
    return 'мереке $date';
  }

  @override
  String get noHolidaysShort => 'мерекесіз';

  @override
  String get upcomingHolidays => 'Таяудағы мерекелер';

  @override
  String get noUpcomingHolidays => 'Мерекелерді көру үшін елді таңдаңыз';

  @override
  String get settingsSubtitle =>
      'Бірден сақталады. Таймер мен виджет өздігінен қайта есептеледі.';

  @override
  String get workdaysHint => 'Өз күндеріңізді таңдау үшін күнді басыңыз';

  @override
  String get shiftStartsAt => 'Басталуы';

  @override
  String get shiftEndsAt => 'Аяқталуы';

  @override
  String get celebrateWeekend => 'Демалыс!';

  @override
  String get celebrateLongWeekend => 'Ұзақ демалыс!';

  @override
  String get celebrateHoliday => 'Мереке!';

  @override
  String get celebrateDaysOff => 'Демалыс!';

  @override
  String get celebrateEyebrow => 'апта артта қалды';

  @override
  String get celebrateLateEyebrow => 'кеш болса да, шын жүректен';

  @override
  String get celebrateWas => 'жұмыс';

  @override
  String celebrateBody(String duration) {
    return 'Жұмыс бітті. Алда $duration жұмыссыз.';
  }

  @override
  String get celebrateBodyOpen => 'Жұмыс бітті. Демалыңыз.';

  @override
  String celebrateLateBody(String when) {
    return 'Апта $when аяқталды. Бәрібір тойлаймыз.';
  }

  @override
  String get celebrateCta => 'Ура, демаламын';

  @override
  String get navAwards => 'Марапаттар';

  @override
  String get scheduleTitle => 'Кесте';

  @override
  String get weekHeader => 'Апта';

  @override
  String get weekStarts => 'Аптаның басы';

  @override
  String get weekEnds => 'Аптаның соңы';

  @override
  String get holidaysShort => 'Мерекелер';

  @override
  String get holidaysShortHint => 'Қысқа апталар мен ауыстырулар';

  @override
  String get sectionExtras => 'Виджеттер мен эффектілер';

  @override
  String get confetti => 'Конфетти';

  @override
  String get confettiHint =>
      'iPhone-да «Қозғалысты азайту» қосылған болса, ашықхатты анимациясыз көрсетеміз';

  @override
  String get confettiHintAndroid =>
      'Телефон баптауларында анимация өшірілген болса, ашықхатты анимациясыз көрсетеміз';

  @override
  String weeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count апта',
    );
    return '$_temp0';
  }

  @override
  String get vacationTitle => 'Демалыс';

  @override
  String get vacationNone => 'Жоқ';

  @override
  String get vacationIntro =>
      'Демалыста оралуға дейінгі күндерді санаймыз. Марапаттарға арналған апталар сақталады.';

  @override
  String get vacationHowLong => 'Қанша уақыт';

  @override
  String get vacationFrom => 'Қай күннен бастап';

  @override
  String vacationWeeks(int count) {
    return '$count апта';
  }

  @override
  String get vacationFromTomorrow => 'Ертеңнен';

  @override
  String get vacationFromMonday => 'Дүйсенбіден';

  @override
  String vacationGo(String days) {
    return '$days демалысқа шығу';
  }

  @override
  String get vacationActive => 'Сіз демалыстасыз';

  @override
  String get vacationPlanned => 'Демалыс жоспарланған';

  @override
  String vacationActiveBody(String date) {
    return '$date қоса алғанға дейін. Оралуға дейінгі күндерді санаймыз, марапаттарға арналған апталар сақталады.';
  }

  @override
  String vacationPlannedBody(String from, String to) {
    return '$from бастап $to қоса алғанға дейін. Оралуға дейінгі күндерді санаймыз, марапаттарға арналған апталар сақталады.';
  }

  @override
  String get vacationEndEarly => 'Ертерек оралу';

  @override
  String get vacationCancel => 'Демалысты болдырмау';

  @override
  String get vacationNote => 'Демалыс';

  @override
  String untilInclusive(String date) {
    return '$date қоса алғанға дейін';
  }

  @override
  String holidayMidweek(String when) {
    return 'Апта ортасындағы мереке. Жұмыс $when';
  }

  @override
  String get eyebrowVacationPrefix => 'демалыс · дейін';

  @override
  String get eyebrowVacationStrike => 'жұмысқа';

  @override
  String get eyebrowVacationSuffix => 'оралуға';

  @override
  String get onbSkip => 'Өткізіп жіберу';

  @override
  String get onbStart => 'Бастау';

  @override
  String get onbNext => 'Әрі қарай';

  @override
  String onbStep(int n, int m) {
    return '$n-қадам, барлығы $m';
  }

  @override
  String get onbWelcomeTasks =>
      'Және еске салғыштары мен нақты оятқыштары бар тапсырмалар трекері.';

  @override
  String get onbTasksTitle => 'Қоңырау соғатын тапсырмалар';

  @override
  String get onbTasksSmart =>
      'Еркін жазыңыз: «Зертханалық жұмыс ертең 18:00 #оқу».';

  @override
  String get onbTasksVoice => 'Немесе дауыспен айтып жіберіңіз.';

  @override
  String get onbTasksAlarm =>
      'Еске салғыштар қолданба жабық болса да нақты оятқыш болып келеді.';

  @override
  String get onbEnableReminders => 'Еске салғыштарды қосу';

  @override
  String get onbWelcomePrefix => 'Санаймыз';

  @override
  String get onbWelcomeStrike => 'жұмаға';

  @override
  String get onbWelcomeSuffix => 'бостандыққа дейін';

  @override
  String get onbWelcomeBody =>
      'Жұмыс аптаңыз қашан аяқталатынын айтыңыз. Шар демалысқа қарай толып отырады, ал демалыс басталғанда шағын мереке болады.';

  @override
  String get onbTypeTitle => 'Қалай жұмыс істейсіз?';

  @override
  String get onbFiveDay => 'Бес күндік апта';

  @override
  String get onbFiveDayHint => 'Дс–Жм, сенбі мен жексенбі демалыс';

  @override
  String get onbCustom => 'Өз кестем';

  @override
  String get onbCustomHint => 'Өз күндеріңіз, мысалы сс–сб';

  @override
  String get onbTimeTitle => 'Жұмыс аптаңыз қашан?';

  @override
  String get onbWidgetBody =>
      'Виджет қолданба жабық болса да, қанша қалғанын көрсетеді.';

  @override
  String get onbHowToWidget => 'Виджетті қалай қосу керек';

  @override
  String get onbNotNow => 'Қазір емес';

  @override
  String get awardsHero => 'рет демалысты\nкүттіңіз';

  @override
  String awardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count марапат',
      zero: 'марапат әзірге жоқ',
    );
    return '$_temp0';
  }

  @override
  String awardsMore(int count) {
    return 'және тағы $count';
  }

  @override
  String get awardsWeekly => 'Апталар';

  @override
  String get awardsSpecial => 'Ерекше';

  @override
  String awardsProgress(int got, int total) {
    return '$total ішінен $got алынды';
  }

  @override
  String get awardLocked => 'әлі алынбаған';

  @override
  String awardEarnedOn(String date) {
    return 'алынған күні: $date';
  }

  @override
  String awardWeeksLeft(String weeks) {
    return 'тағы $weeks';
  }

  @override
  String awardNew(String name) {
    return 'Жаңа марапат: $name';
  }

  @override
  String celebrateWeeks(String weeks) {
    return '$weeks артта қалды';
  }

  @override
  String celebrateNext(String weeks, String name) {
    return '«$name» марапатына дейін тағы $weeks';
  }

  @override
  String get celebrateAllDone => 'Апталар бойынша барлық марапат жиналды';

  @override
  String atNight(String day) {
    return '$day, түнде';
  }

  @override
  String get widgetSetUp => 'Баптау үшін қолданбаны ашыңыз';

  @override
  String get tabTracker => 'Трекер';

  @override
  String get greetingMorning => 'Қайырлы таң ☀️';

  @override
  String get greetingAfternoon => 'Күн қалай, жақсы ма?';

  @override
  String get greetingEvening => 'Қайырлы кеш 🌙';

  @override
  String get sectionOverdue => 'Шұғыл 🔥';

  @override
  String get sectionToday => 'Бүгінге';

  @override
  String get sectionTomorrow => 'Ертең';

  @override
  String get sectionLater => 'Кейін';

  @override
  String get sectionCompleted => 'Орындалды';

  @override
  String get categoryStudy => 'Оқу';

  @override
  String get categoryWork => 'Жұмыс';

  @override
  String get categoryPersonal => 'Жеке';

  @override
  String get categoryOther => 'Басқа';

  @override
  String get filterAll => 'Барлығы';

  @override
  String get reminderPresetNone => 'Керек емес';

  @override
  String get reminderPreset5m => '5 мин';

  @override
  String get reminderPreset30m => '30 мин';

  @override
  String get reminderPreset1h => '1 сағат';

  @override
  String get reminderPreset1d => '1 күн';

  @override
  String reminderBeforeMinutes(int count) {
    return '$count мин бұрын';
  }

  @override
  String reminderBeforeHours(int count) {
    return '$count сағ бұрын';
  }

  @override
  String reminderBeforeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн бұрын',
    );
    return '$_temp0';
  }

  @override
  String dueYesterday(String time) {
    return 'Кеше, $time';
  }

  @override
  String dueTomorrow(String time) {
    return 'Ертең, $time';
  }

  @override
  String dueOnDate(String date, String time) {
    return '$date, $time';
  }

  @override
  String get tasksEmptyTitle => 'Мұнда әзірге бос';

  @override
  String get tasksEmptyBody => 'Алғашқы тапсырмаңды қос';

  @override
  String get addTask => 'Тапсырма қосу';

  @override
  String get tasksFilterEmptyTitle => 'Мұнда ештеңе жоқ';

  @override
  String get tasksFilterEmptyBody =>
      'Басқа санатты қарап көр немесе жаңа тапсырма қос';

  @override
  String get errorTitle => 'Ой, бірдеңе бұзылды';

  @override
  String taskDeleted(String title) {
    return '«$title» жойылды';
  }

  @override
  String get undo => 'Қайтару';

  @override
  String get markDone => 'Орындалды деп белгілеу';

  @override
  String get markNotDone => 'Белгіні алып тастау';

  @override
  String get discardTitle => 'Сақтамай шығасың ба?';

  @override
  String get discardBody => 'Жазғанның бәрі жоғалады.';

  @override
  String get keepEditing => 'Қалу';

  @override
  String get discard => 'Шығу';

  @override
  String get taskHint => 'Не істеу керек?';

  @override
  String get remindMe => 'Еске салу';

  @override
  String get saveChanges => 'Өзгерістерді сақтау';

  @override
  String get delete => 'Жою';

  @override
  String get dateToday => 'Бүгін';

  @override
  String get dateTomorrow => 'Ертең';

  @override
  String get permExactTitle => 'Нақты оятқыштар керек';

  @override
  String get permExactBody =>
      'Еске салғыш дәл уақытында шалынуы үшін Umytpa-ға нақты оятқыштарға рұқсат керек. «Әрі қарай» түймесін бас, баптауларды ашамыз.';

  @override
  String get permFullScreenTitle => 'Еске салғыштар экранның үстінде';

  @override
  String get permFullScreenBody =>
      'Umytpa бұғатталған экранның үстінде оятқыштай шыға алады, сондықтан дедлайнды ұмытпайсың. «Әрі қарай» түймесін басып, баптауларда қос.';

  @override
  String get continueLabel => 'Әрі қарай';

  @override
  String get notificationsOffBanner =>
      'Хабарландырулар өшірулі. Тапсырманы сақтауға болады, бірақ еске салғыштар үнсіз болады.';

  @override
  String get openSettingsAction => 'Баптауларды ашу';

  @override
  String get errTitleRequired => 'Не істеу керегін жаз';

  @override
  String errTitleTooLong(int max) {
    return 'Тым ұзақ, $max таңбаға дейін қысқарт';
  }

  @override
  String get errDeadlinePast => 'Бұл уақыт өтіп кетті, кейінірек уақыт таңда';

  @override
  String get warnReminderPassed =>
      'Еске салғыштың уақыты өтіп кетті, тапсырманы онсыз сақтаймын.';

  @override
  String get errInvalidInput => 'Дұрыс емес деректер';

  @override
  String get languageTitle => 'Тіл';

  @override
  String get languageSystem => 'Жүйедегідей';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageKazakh => 'Қазақша';

  @override
  String get languageButton => 'Тілді ауыстыру';

  @override
  String get repeatLabel => 'Қайталау';

  @override
  String get repeatNone => 'Керек емес';

  @override
  String get repeatDaily => 'Күн сайын';

  @override
  String get repeatWeekdays => 'Жұмыс күндері';

  @override
  String get repeatWeekly => 'Аптасына бір рет';

  @override
  String get subtasksLabel => 'Қадамдар';

  @override
  String get subtaskHint => 'Қадам қосу';

  @override
  String subtaskProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get widgetToday => 'Бүгін';

  @override
  String get widgetNothingNext => 'Бос, демал 😎';

  @override
  String get widgetAllDone => 'Бәрі орындалды 🎉';

  @override
  String todayLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тапсырма қалды',
      zero: 'Бәрі орындалды, сен керемет екенсің',
    );
    return '$_temp0';
  }

  @override
  String todayDoneOf(int done, int total) {
    return '$total ішінен $done қалтада';
  }

  @override
  String get todayNothingPlanned => 'Бүгінге тыныштық — демал 😎';

  @override
  String get todayAllDone => 'Бәрін жаптың — сен отсың! 🔥';

  @override
  String todayNext(String title) {
    return 'Келесі: $title';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн қатарынан',
    );
    return '$_temp0';
  }

  @override
  String get statsTitle => 'Сенің статистикаң';

  @override
  String get statsOpen => 'Статистика';

  @override
  String get statsDoneTotal => 'Орындалды';

  @override
  String get statsCurrentStreak => 'Қазіргі серия';

  @override
  String get statsBestStreak => 'Серия рекорды';

  @override
  String get statsFocusTotal => 'Фокустағы уақыт';

  @override
  String get statsLast7Done => '7 күнде орындалды';

  @override
  String get statsLast7Focus => '7 күндегі фокус';

  @override
  String get statsByCategory => 'Санаттар бойынша';

  @override
  String get statsBestDay => 'Ең өнімді күн';

  @override
  String get statsNoData =>
      'Бірнеше тапсырма орында — мұнда сиқыр пайда болады';

  @override
  String get statsBadges => 'Жетістіктер';

  @override
  String get statsDaysShort => 'к';

  @override
  String minutesShort(int count) {
    return '$count мин';
  }

  @override
  String hoursMinutesShort(int hours, int minutes) {
    return '$hours сағ $minutes мин';
  }

  @override
  String get badgeFirstDone => 'Алғашқы қадам';

  @override
  String get badgeFirstDoneDesc => 'Кез келген тапсырманы орында';

  @override
  String get badgeTenDone => 'Қарқын алу';

  @override
  String get badgeTenDoneDesc => '10 тапсырма орында';

  @override
  String get badgeFiftyDone => 'Күшті';

  @override
  String get badgeFiftyDoneDesc => '50 тапсырма орында';

  @override
  String get badgeHundredDone => 'Аңыз';

  @override
  String get badgeHundredDoneDesc => '100 тапсырма орында';

  @override
  String get badgeStreak3 => 'Үш күн қатарынан';

  @override
  String get badgeStreak3Desc => '3 күндік серия';

  @override
  String get badgeStreak7 => 'Отты апта';

  @override
  String get badgeStreak7Desc => '7 күндік серия';

  @override
  String get badgeStreak30 => 'Машина';

  @override
  String get badgeStreak30Desc => '30 күндік серия — бұл күш';

  @override
  String get badgeFocusHour => 'Ағында';

  @override
  String get badgeFocusHourDesc => '1 сағат фокус жина';

  @override
  String get badgeFocusTen => 'Монах режимі';

  @override
  String get badgeFocusTenDesc => '10 сағат фокус жина';

  @override
  String get focusTitle => 'Фокус';

  @override
  String get focusStart => 'Кеттік';

  @override
  String get focusStop => 'Тоқтату';

  @override
  String focusWithTask(String title) {
    return 'Істеп жатырмыз: $title';
  }

  @override
  String get focusNoTask => 'Жай фокус';

  @override
  String focusMinutesOption(int count) {
    return '$count мин';
  }

  @override
  String get focusDoneTitle => 'Жарайсың, сессия аяқталды!';

  @override
  String focusDoneBody(int count) {
    return '$count минут таза фокус жиналды.';
  }

  @override
  String get focusMarkTaskDone => 'Тапсырма дайын ✅';

  @override
  String get focusClose => 'Жабу';

  @override
  String get focusRunning => 'Алаңдама, сен ағындасың';

  @override
  String get focusNotifTitle => 'Уақыт бітті!';

  @override
  String get focusNotifBody => 'Дем алып, денеңді жазуға болады.';

  @override
  String get focusTask => 'Фокусқа кіру';

  @override
  String smartApply(String summary) {
    return 'Қосу: $summary';
  }

  @override
  String get smartHint =>
      'Қалай болса солай жаз: «Зертханалық жұмыс ертең 18:00 #оқу»';

  @override
  String get allDoneCelebrate => 'Бүгінге бәрі орындалды!';

  @override
  String get profileTitle => 'Өзіңе бапта';

  @override
  String get profileButton => 'Жекелендіру';

  @override
  String get profileWelcomeTitle => 'Танысайық';

  @override
  String get profileWelcomeBody =>
      'Саған қалай жүгінейін? Өткізіп жіберіп, кейін өзгертуге болады.';

  @override
  String get profileNameLabel => 'Сенің атың';

  @override
  String get profileNameHint => 'Аты немесе лақап аты';

  @override
  String get profileToneTitle => 'Менімен қалай сөйлесесің?';

  @override
  String get toneFriendly => 'Достық үнде';

  @override
  String get toneFriendlyDesc => 'Еркін, сленгпен және эмодзимен';

  @override
  String get toneCalm => 'Сабырлы';

  @override
  String get toneCalmDesc => 'Сыпайы әрі жұмсақ';

  @override
  String get toneCoach => 'Қатал жаттықтырушы';

  @override
  String get toneCoachDesc => 'Қысқа әрі талапшыл';

  @override
  String get profileDone => 'Дайын';

  @override
  String get profileSkip => 'Өткізіп жіберу';

  @override
  String get recapTitle => 'Апта қорытындысы';

  @override
  String get reminderCustom => 'Өз уақытым';

  @override
  String get customReminderTitle => 'Дедлайнға дейін еске салу';

  @override
  String get unitMinutes => 'минут';

  @override
  String get unitHours => 'сағат';

  @override
  String get unitDays => 'күн';

  @override
  String get customReminderApply => 'Дайын';

  @override
  String get customReminderHint => 'Қанша';

  @override
  String get alarmSoundTitle => 'Оятқыш дыбысы';

  @override
  String get alarmSoundBuiltIn => 'Стандартты';

  @override
  String get alarmSoundPick => 'Құрылғыдан дыбыс таңдау';

  @override
  String get alarmSoundReset => 'Стандартты дыбысты қайтару';

  @override
  String get alarmSoundHintIos =>
      'Кез келген кең таралған аудио пішім: MP3, M4A, AAC, WAV, AIFF, CAF, FLAC, AMR, MP4, 3GP және басқалар. Алғашқы 30 секунд ойнайды. Қолданбаны ашқанша немесе «Дайын» түймесін баспайынша дыбыс қайталанады.';

  @override
  String get alarmSoundHintAndroid =>
      'Кез келген кең таралған аудио пішім: MP3, M4A, AAC, WAV, FLAC, OGG, OPUS, AMR, MIDI, 3GP, MKA, WEBM және басқалар. Хабарландыруды баспайынша немесе сырғытып тастамайынша дыбыс шығады.';

  @override
  String get alarmSoundFailed => 'Бұл файлды алу мүмкін болмады';

  @override
  String get quickAddHint => 'Жылдам: «Анаға 20 минуттан кейін қоңырау шал»';

  @override
  String get quickInHour => '1 сағаттан кейін';

  @override
  String get quickTonight => 'Кешке';

  @override
  String get quickTomorrowMorning => 'Ертең таңертең';

  @override
  String get quickVoice => 'Дауыспен енгізу';

  @override
  String get quickVoiceUnavailable =>
      'Дауыспен енгізу қолжетімсіз. Микрофон мен сөйлеуді тану рұқсатын тексеріңіз.';

  @override
  String quickAddedCount(int count) {
    return 'Қосылған тапсырма: $count';
  }

  @override
  String get taskDuplicate => 'Көшірме жасау';

  @override
  String get taskDuplicated => 'Көшірме жасалды';
}
