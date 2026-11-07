import 'package:intl/intl.dart';

import '../../tasks/domain/entities/task.dart';

/// Pure notification copy (no BuildContext). Matches the design mockup:
/// title = relative time left, body = "Task title · due HH:mm".
abstract final class ReminderNotificationText {
  static String titleFor(Duration remindBefore) {
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

  static String bodyFor(Task task) {
    final String due = DateFormat.Hm().format(task.dueAt.toLocal());
    return '${task.title} · due $due';
  }

  static ({String title, String body}) forTask(Task task) {
    final Duration remindBefore = task.remindBefore ?? Duration.zero;
    return (title: titleFor(remindBefore), body: bodyFor(task));
  }
}
