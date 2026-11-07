/// Pure date/time helpers used by Domain and Presentation.
abstract final class DateTimeUtils {
  /// Start of the calendar day in the same timezone as [dateTime].
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  static DateTime startOfTomorrow(DateTime now) {
    return startOfDay(now).add(const Duration(days: 1));
  }

  static DateTime startOfDayAfterTomorrow(DateTime now) {
    return startOfDay(now).add(const Duration(days: 2));
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Nearest whole hour strictly in the future relative to [now].
  ///
  /// Examples (local time):
  /// - 14:00:00 → 15:00:00
  /// - 14:00:01 → 15:00:00
  /// - 14:30:00 → 15:00:00
  static DateTime nextRoundedHour(DateTime now) {
    final DateTime floored = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    );
    return floored.add(const Duration(hours: 1));
  }
}
