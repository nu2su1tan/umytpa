import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../tasks/data/datasources/app_database.dart';
import '../../tasks/data/repositories/task_repository_impl.dart';
import '../../tasks/domain/usecases/toggle_task_done.dart';
import 'local_reminder_scheduler.dart';
import 'notification_details_factory.dart';

/// Buttons shown on task notifications and the code that handles them.
abstract final class ReminderActions {
  static const String doneId = 'task_done';
  static const String snoozeId = 'task_snooze';
  static const String iosDismissId =
      'com.apple.UNNotificationDismissActionIdentifier';
  static const String iosCategory = 'task_actions';
  static const Duration snoozeFor = Duration(minutes: 10);

  /// Payload carries what a background isolate needs without opening the app.
  static String encodePayload({
    required int taskId,
    required String title,
    required String body,
    String? kind,
  }) => jsonEncode(<String, Object>{
    'id': taskId,
    't': title,
    'b': body,
    if (kind != null) 'k': kind,
  });

  static ({int id, String title, String body, String? kind})? decodePayload(
    String? raw,
  ) {
    if (raw == null) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?> && decoded['id'] is int) {
        return (
          id: decoded['id']! as int,
          title: (decoded['t'] as String?) ?? '',
          body: (decoded['b'] as String?) ?? '',
          kind: decoded['k'] as String?,
        );
      }
    } on FormatException {
      // Older notifications carried just the task id.
      final int? id = int.tryParse(raw);
      if (id != null) {
        return (id: id, title: '', body: '', kind: null);
      }
    }
    return null;
  }
}

/// Runs in a background isolate when a notification button is tapped.
@pragma('vm:entry-point')
Future<void> reminderBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final ({int id, String title, String body, String? kind})? payload =
      ReminderActions.decodePayload(response.payload);
  if (payload == null) {
    return;
  }
  final LocalReminderScheduler scheduler = LocalReminderScheduler(
    detailsFactory: const NotificationDetailsFactory(),
  );
  switch (response.actionId) {
    case ReminderActions.iosDismissId:
      // Swiping the notification away silences the repeating alarm.
      await scheduler.cancelRepeats(payload.id, kind: payload.kind);
    case ReminderActions.snoozeId:
      await scheduler.snooze(
        taskId: payload.id,
        title: payload.title,
        body: payload.body,
        delay: ReminderActions.snoozeFor,
      );
    case ReminderActions.doneId:
      final AppDatabase database = AppDatabase();
      try {
        await ToggleTaskDone(
          repository: TaskRepositoryImpl(database.tasksDao),
          reminderScheduler: scheduler,
        )(id: payload.id, isDone: true, now: DateTime.now());
      } finally {
        await database.close();
      }
  }
}
