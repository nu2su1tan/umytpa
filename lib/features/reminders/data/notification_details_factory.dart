import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'reminder_actions.dart';

/// Factory responsible for building platform-specific notification details and channels
/// for alarm-level reminders.
class NotificationDetailsFactory {
  const NotificationDetailsFactory();

  /// Notification channel identifier. Contains a version suffix (`_v2`) because
  /// Android notification channels are immutable once created.
  static const String androidChannelId = 'task_alarm_v2';

  /// User-visible notification channel name in Android system settings.
  static const String androidChannelName = 'Task Alarms';

  /// User-visible notification channel description in Android system settings.
  static const String androidChannelDescription =
      'Alarm reminders for task deadlines';

  /// Android raw audio resource name (without file extension) in `res/raw`.
  static const String androidSoundResource = 'alarm_sound';

  /// iOS audio file name (with extension) bundled with the application.
  static const String iosSoundFile = 'alarm_sound.wav';

  /// Android native `Notification.FLAG_INSISTENT` value (`0x00000004`).
  /// Loops the notification sound and vibration continuously until dismissed.
  static const int insistentFlag = 4;

  /// Timeout in milliseconds (60 seconds) after which the Android notification
  /// automatically dismisses so the insistent sound does not ring indefinitely.
  static const int timeoutAfterMs = 60000;

  /// Regular (non-alarm) channel for "N minutes left" heads-up reminders.
  static const String reminderChannelId = 'task_reminder_v1';
  static const String reminderChannelName = 'Task Reminders';
  static const String reminderChannelDescription =
      'Heads-up reminders before a task deadline';

  AndroidNotificationChannel createReminderChannel() {
    return const AndroidNotificationChannel(
      reminderChannelId,
      reminderChannelName,
      description: reminderChannelDescription,
      importance: Importance.high,
    );
  }

  /// Plain heads-up notification for the "before deadline" reminder.
  NotificationDetails createReminderDetails({
    String doneLabel = 'Done',
    String snoozeLabel = '+10 min',
    bool withActions = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        reminderChannelId,
        reminderChannelName,
        channelDescription: reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        actions: withActions ? _androidActions(doneLabel, snoozeLabel) : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        categoryIdentifier: ReminderActions.iosCategory,
      ),
    );
  }

  /// Builds the [AndroidNotificationChannel] configured with alarm importance and sound.
  AndroidNotificationChannel createAndroidChannel() {
    return const AndroidNotificationChannel(
      androidChannelId,
      androidChannelName,
      description: androidChannelDescription,
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound(androidSoundResource),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  /// Localised captions for the notification buttons.
  static List<AndroidNotificationAction> _androidActions(
    String doneLabel,
    String snoozeLabel,
  ) =>
      <AndroidNotificationAction>[
        AndroidNotificationAction(ReminderActions.doneId, doneLabel),
        AndroidNotificationAction(ReminderActions.snoozeId, snoozeLabel),
      ];

  /// Builds [NotificationDetails] for scheduling high-priority alarm reminders.
  NotificationDetails createNotificationDetails({
    String doneLabel = 'Done',
    String snoozeLabel = '+10 min',
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        channelDescription: androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const RawResourceAndroidNotificationSound(androidSoundResource),
        fullScreenIntent: true,
        additionalFlags: Int32List.fromList(<int>[insistentFlag]),
        timeoutAfter: timeoutAfterMs,
        actions: _androidActions(doneLabel, snoozeLabel),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        sound: iosSoundFile,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: ReminderActions.iosCategory,
      ),
    );
  }
}
