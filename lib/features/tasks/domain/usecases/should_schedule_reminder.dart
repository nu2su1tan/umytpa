import '../entities/task.dart';

/// Whether a local notification should be scheduled for [task] at [now].
bool shouldScheduleReminder(Task task, {required DateTime now}) {
  if (task.isDone) {
    return false;
  }
  final DateTime? remindAt = task.remindAt;
  if (remindAt == null) {
    return false;
  }
  return remindAt.isAfter(now);
}
