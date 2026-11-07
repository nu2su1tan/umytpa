import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Factory responsible for building platform-specific notification details and channels
/// for alarm-level reminders.
class NotificationDetailsFactory {
  const NotificationDetailsFactory();

  /// Notification channel identifier. Contains a version suffix (`_v1`) because
  /// Android notification channels are immutable once created.
  static const String androidChannelId = 'task_alarm_v1';

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

  /// Builds [NotificationDetails] for scheduling high-priority alarm reminders.
  NotificationDetails createNotificationDetails() {
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
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        sound: iosSoundFile,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }
}
