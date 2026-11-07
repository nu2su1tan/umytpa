import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../tasks/domain/entities/task.dart';
import '../../tasks/domain/usecases/should_schedule_reminder.dart';
import '../domain/reminder_permission_status.dart';
import '../domain/reminder_scheduler.dart';
import 'notification_details_factory.dart';
import 'reminder_notification_text.dart';

/// Local-notifications implementation of [ReminderScheduler].
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({
    required this.detailsFactory,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final NotificationDetailsFactory detailsFactory;
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _fullScreenRequested = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      detailsFactory.createAndroidChannel(),
    );

    _initialized = true;
  }

  @override
  Future<Result<void>> schedule(Task task) async {
    try {
      await initialize();

      if (!shouldScheduleReminder(task, now: DateTime.now())) {
        await cancel(task.id);
        return const Success<void>(null);
      }

      final ReminderPermissionStatus notifPermission =
          await checkNotificationsPermission();
      if (!notifPermission.isGranted) {
        return const Err<void>(PermissionFailure());
      }

      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? canSchedule = await android?.canScheduleExactNotifications();
        if (canSchedule == false) {
          await android?.requestExactAlarmsPermission();
        }
      }

      final DateTime remindAt = task.remindAt!;
      final tz.TZDateTime scheduled = tz.TZDateTime.from(remindAt, tz.local);
      final (:String title, :String body) =
          ReminderNotificationText.forTask(task);

      await _plugin.zonedSchedule(
        id: task.id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: detailsFactory.createNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id.toString(),
      );
      return const Success<void>(null);
    } on Object catch (error, stackTrace) {
      return _err(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> cancel(int taskId) async {
    try {
      await initialize();
      await _plugin.cancel(id: taskId);
      return const Success<void>(null);
    } on Object catch (error, stackTrace) {
      return _err(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> rescheduleAll(List<Task> tasks) async {
    try {
      await initialize();
      final DateTime now = DateTime.now();
      for (final Task task in tasks) {
        if (shouldScheduleReminder(task, now: now)) {
          final Result<void> result = await schedule(task);
          if (result is Err<void>) {
            developer.log(
              'Failed to reschedule task ${task.id}',
              name: 'LocalReminderScheduler',
              error: result.failure,
            );
          }
        } else {
          await cancel(task.id);
        }
      }
      return const Success<void>(null);
    } on Object catch (error, stackTrace) {
      return _err(error, stackTrace);
    }
  }

  @override
  Future<ReminderPermissionStatus> checkPermission() async {
    final ReminderPermissionStatus notif = await checkNotificationsPermission();
    if (!notif.isGranted) {
      return notif;
    }

    final ReminderPermissionStatus exact = await checkExactAlarmsPermission();
    if (!exact.isGranted) {
      return exact;
    }

    final ReminderPermissionStatus fullScreen =
        await checkFullScreenIntentPermission();
    if (!fullScreen.isGranted) {
      return fullScreen;
    }

    return ReminderPermissionStatus.granted;
  }

  @override
  Future<ReminderPermissionStatus> checkNotificationsPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool enabled = await android?.areNotificationsEnabled() ?? false;
      return enabled
          ? ReminderPermissionStatus.granted
          : ReminderPermissionStatus.notificationsDenied;
    }

    if (Platform.isIOS) {
      return _mapDarwinOptions(await _ios?.checkPermissions());
    }
    if (Platform.isMacOS) {
      return _mapDarwinOptions(await _macos?.checkPermissions());
    }

    return ReminderPermissionStatus.notificationsDenied;
  }

  @override
  Future<ReminderPermissionStatus> requestNotificationsPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool granted =
          await android?.requestNotificationsPermission() ?? false;
      return granted
          ? ReminderPermissionStatus.granted
          : ReminderPermissionStatus.notificationsDenied;
    }

    if (Platform.isIOS) {
      final bool? granted = await _ios?.requestPermissions(
        alert: true,
        sound: true,
      );
      return granted == true
          ? ReminderPermissionStatus.granted
          : ReminderPermissionStatus.notificationsDenied;
    }

    if (Platform.isMacOS) {
      final bool? granted = await _macos?.requestPermissions(
        alert: true,
        sound: true,
      );
      return granted == true
          ? ReminderPermissionStatus.granted
          : ReminderPermissionStatus.notificationsDenied;
    }

    return ReminderPermissionStatus.notificationsDenied;
  }

  @override
  Future<ReminderPermissionStatus> checkExactAlarmsPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? canSchedule = await android?.canScheduleExactNotifications();
      if (canSchedule == false) {
        return ReminderPermissionStatus.exactAlarmsMissing;
      }
      return ReminderPermissionStatus.granted;
    }

    return ReminderPermissionStatus.granted;
  }

  @override
  Future<ReminderPermissionStatus> requestExactAlarmsPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestExactAlarmsPermission();
      return checkExactAlarmsPermission();
    }

    return ReminderPermissionStatus.granted;
  }

  @override
  Future<ReminderPermissionStatus> checkFullScreenIntentPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      if (_fullScreenRequested) {
        return ReminderPermissionStatus.granted;
      }
      return ReminderPermissionStatus.fullScreenMissing;
    }

    return ReminderPermissionStatus.granted;
  }

  @override
  Future<ReminderPermissionStatus> requestFullScreenIntentPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      _fullScreenRequested = true;
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted =
          await android?.requestFullScreenIntentPermission();
      if (granted == false) {
        return ReminderPermissionStatus.fullScreenMissing;
      }
      return ReminderPermissionStatus.granted;
    }

    return ReminderPermissionStatus.granted;
  }

  @override
  Future<void> openSystemSettings() async {
    await initialize();
    await _plugin.openAppNotificationSettings();
  }

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  MacOSFlutterLocalNotificationsPlugin? get _macos =>
      _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();

  ReminderPermissionStatus _mapDarwinOptions(
    NotificationsEnabledOptions? options,
  ) {
    if (options == null) {
      return ReminderPermissionStatus.notificationsDenied;
    }
    final bool granted =
        options.isEnabled || options.isAlertEnabled || options.isSoundEnabled;
    return granted
        ? ReminderPermissionStatus.granted
        : ReminderPermissionStatus.notificationsDenied;
  }

  Err<void> _err(Object error, StackTrace stackTrace) {
    developer.log(
      'ReminderScheduler error',
      name: 'LocalReminderScheduler',
      error: error,
      stackTrace: stackTrace,
    );
    return Err<void>(UnexpectedFailure(error.toString()));
  }
}
