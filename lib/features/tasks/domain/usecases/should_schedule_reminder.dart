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

/// Whether the scheduler has anything to ring for [task]: the reminder before
/// the deadline, or the alarm at the deadline itself. The scheduler decides
/// which of the two applies, so every caller shares this one rule.
bool shouldScheduleNotifications(Task task, {required DateTime now}) {
  if (task.isDone) {
    return false;
  }
  return shouldScheduleReminder(task, now: now) || task.dueAt.isAfter(now);
}
