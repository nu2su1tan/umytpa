import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alarm_sound.dart';
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

  /// Timeout in milliseconds (10 minutes) after which the Android notification
  /// automatically dismisses so the insistent sound does not ring indefinitely.
  static const int timeoutAfterMs = 600000;

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
  AndroidNotificationChannel createAndroidChannel([
    AlarmSound sound = AlarmSound.builtIn,
    String? customPath,
  ]) {
    return AndroidNotificationChannel(
      _channelId(sound),
      androidChannelName,
      description: androidChannelDescription,
      importance: Importance.max,
      sound: _androidSound(customPath),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  static String _channelId(AlarmSound sound) =>
      sound.isCustom ? sound.androidChannelId : androidChannelId;

  static AndroidNotificationSound _androidSound(String? customPath) =>
      customPath == null
          ? const RawResourceAndroidNotificationSound(androidSoundResource)
          : UriAndroidNotificationSound(Uri.file(customPath).toString());

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
    AlarmSound sound = AlarmSound.builtIn,
    String? customPath,
    bool iosActions = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(sound),
        androidChannelName,
        channelDescription: androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: _androidSound(customPath),
        fullScreenIntent: true,
        additionalFlags: Int32List.fromList(<int>[insistentFlag]),
        timeoutAfter: timeoutAfterMs,
        actions: _androidActions(doneLabel, snoozeLabel),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        sound: sound.fileName ?? iosSoundFile,
        interruptionLevel: InterruptionLevel.timeSensitive,
        // Without the buttons when a real alarm will ring at the deadline: a
        // button tapped in the background could not cancel that alarm.
        categoryIdentifier: iosActions ? ReminderActions.iosCategory : null,
      ),
    );
  }
}
