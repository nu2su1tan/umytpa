abstract final class ReminderLabel {
  static String? forDuration(Duration? remindBefore) {
    if (remindBefore == null) {
      return null;
    }
    if (remindBefore == const Duration(minutes: 5)) {
      return '5 min before';
    }
    if (remindBefore == const Duration(minutes: 30)) {
      return '30 min before';
    }
    if (remindBefore == const Duration(hours: 1)) {
      return '1h before';
    }
    if (remindBefore == const Duration(days: 1)) {
      return '1 day before';
    }
    final int minutes = remindBefore.inMinutes;
    if (minutes % 1440 == 0) {
      return '${minutes ~/ 1440} day before';
    }
    if (minutes % 60 == 0) {
      return '${minutes ~/ 60}h before';
    }
    return '$minutes min before';
  }
}
