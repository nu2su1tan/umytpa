import '../../../core/error/result.dart';
import '../../tasks/domain/entities/task.dart';
import 'reminder_permission_status.dart';

/// Schedules and cancels local notifications for tasks.
///
/// Domain interface — implementation lives in `features/reminders/data`.
abstract interface class ReminderScheduler {
  Future<Result<void>> schedule(Task task);

  Future<Result<void>> cancel(int taskId);

  Future<Result<void>> rescheduleAll(List<Task> tasks);

  /// Checks the overall reminder permission status across all required levels.
  Future<ReminderPermissionStatus> checkPermission();

  /// Checks if basic notifications permission is enabled.
  Future<ReminderPermissionStatus> checkNotificationsPermission();

  /// Requests basic notifications permission.
  Future<ReminderPermissionStatus> requestNotificationsPermission();

  /// Checks if exact alarms permission is granted (Android 12+).
  Future<ReminderPermissionStatus> checkExactAlarmsPermission();

  /// Requests exact alarms permission by opening system settings (Android 12+).
  Future<ReminderPermissionStatus> requestExactAlarmsPermission();

  /// Checks if full-screen intent permission is granted (Android 14+).
  Future<ReminderPermissionStatus> checkFullScreenIntentPermission();

  /// Requests full-screen intent permission (Android 14+).
  Future<ReminderPermissionStatus> requestFullScreenIntentPermission();

  Future<void> openSystemSettings();
}
