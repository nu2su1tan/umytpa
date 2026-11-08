import 'package:intl/intl.dart';

import '../../tasks/domain/entities/task.dart';

/// Pure notification copy (no BuildContext). Matches the design mockup:
/// title = relative time left, body = "Task title · due HH:mm".
abstract final class ReminderNotificationText {
  static String titleFor(Duration remindBefore, {String? languageCode}) {
    if (languageCode == 'ru') {
      return _titleRu(remindBefore);
    }
    if (languageCode == 'kk') {
      return _titleKk(remindBefore);
    }
    if (remindBefore == Duration.zero) {
      return 'Due now';
    }
    if (remindBefore == const Duration(minutes: 5)) {
      return '5 minutes left';
    }
    if (remindBefore == const Duration(minutes: 30)) {
      return '30 minutes left';
    }
    if (remindBefore == const Duration(hours: 1)) {
      return '1 hour left';
    }
    if (remindBefore == const Duration(days: 1)) {
      return '1 day left';
    }
    final int minutes = remindBefore.inMinutes;
    if (minutes % 1440 == 0) {
      final int days = minutes ~/ 1440;
      return '$days ${days == 1 ? 'day' : 'days'} left';
    }
    if (minutes % 60 == 0) {
      final int hours = minutes ~/ 60;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} left';
    }
    return '$minutes minutes left';
  }

  static String doneLabel({String? languageCode}) =>
      switch (languageCode) {
        'ru' => 'Сделал',
        'kk' => 'Дайын',
        _ => 'Done',
      };

  static String snoozeLabel({String? languageCode}) =>
      switch (languageCode) {
        'ru' || 'kk' => '+10 мин',
        _ => '+10 min',
      };

  static String bodyFor(Task task, {String? languageCode}) {
    final String due = DateFormat.Hm().format(task.dueAt.toLocal());
    if (languageCode == 'ru') {
      return '${task.title} · до $due';
    }
    if (languageCode == 'kk') {
      return '${task.title} · $due дейін';
    }
    return '${task.title} · due $due';
  }

  /// Copy for the alarm that rings exactly at the deadline.
  static ({String title, String body}) forDeadline(
    Task task, {
    String? languageCode,
  }) {
    return (
      title: titleFor(Duration.zero, languageCode: languageCode),
      body: task.title,
    );
  }

  static ({String title, String body}) forTask(
    Task task, {
    String? languageCode,
  }) {
    final Duration remindBefore = task.remindBefore ?? Duration.zero;
    return (
      title: titleFor(remindBefore, languageCode: languageCode),
      body: bodyFor(task, languageCode: languageCode),
    );
  }

  static String _plural(int n, String one, String few, String many) {
    final int mod100 = n % 100;
    final int mod10 = n % 10;
    if (mod100 >= 11 && mod100 <= 14) {
      return many;
    }
    if (mod10 == 1) {
      return one;
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return few;
    }
    return many;
  }

  static String _titleRu(Duration remindBefore) {
    if (remindBefore == Duration.zero) {
      return 'Дедлайн настал! ⏰';
    }
    final int minutes = remindBefore.inMinutes;
    if (minutes % 1440 == 0) {
      final int d = minutes ~/ 1440;
      return 'Дедлайн через $d ${_plural(d, 'день', 'дня', 'дней')} ⏰';
    }
    if (minutes % 60 == 0) {
      final int h = minutes ~/ 60;
      return 'Дедлайн через $h ${_plural(h, 'час', 'часа', 'часов')} ⏰';
    }
    return 'Дедлайн через $minutes ${_plural(minutes, 'минуту', 'минуты', 'минут')} ⏰';
  }

  static String _titleKk(Duration remindBefore) {
    if (remindBefore == Duration.zero) {
      return 'Дедлайн келді! ⏰';
    }
    final int minutes = remindBefore.inMinutes;
    if (minutes % 1440 == 0) {
      return 'Дедлайнға ${minutes ~/ 1440} күн қалды ⏰';
    }
    if (minutes % 60 == 0) {
      return 'Дедлайнға ${minutes ~/ 60} сағат қалды ⏰';
    }
    return 'Дедлайнға $minutes минут қалды ⏰';
  }
}
