import 'package:intl/intl.dart';

/// English (US-style) uses a 12-hour clock with AM/PM; every other app
/// language (ru, kk, ...) uses 24-hour time.
bool uses12HourClock(String localeName) => localeName.startsWith('en');

/// "7:00 PM" for English, "19:00" for everything else.
DateFormat timeFormatFor(String localeName) => uses12HourClock(localeName)
    ? DateFormat.jm(localeName)
    : DateFormat.Hm(localeName);
