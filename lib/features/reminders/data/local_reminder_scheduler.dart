import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:intl/intl.dart';

import '../../../core/copy/copy_pack.dart';
import '../../../core/copy/profile_controller.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../tasks/domain/entities/task.dart';
import '../../tasks/domain/usecases/should_schedule_reminder.dart';
import '../domain/reminder_permission_status.dart';
import '../domain/reminder_scheduler.dart';
import 'notification_details_factory.dart';
import 'reminder_actions.dart';
import 'reminder_notification_text.dart';

/// Local-notifications implementation of [ReminderScheduler].
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({
    required this.detailsFactory,
    this.languageCode,
    this.profile,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final NotificationDetailsFactory detailsFactory;

  /// Language for notification text; `null` means the system language.
  final String? Function()? languageCode;
  /// Supplies the user's name and tone for the notification wording.
  final ProfileController? profile;
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
    final String lang = _lang;
    final DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          ReminderActions.iosCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              ReminderActions.doneId,
              ReminderNotificationText.doneLabel(languageCode: lang),
            ),
            DarwinNotificationAction.plain(
              ReminderActions.snoozeId,
              ReminderNotificationText.snoozeLabel(languageCode: lang),
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveBackgroundNotificationResponse: reminderBackgroundHandler,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        // Buttons that don't open the UI arrive in the background handler;
        // anything that reaches us here with an action is handled the same.
        if (r.actionId != null) {
          reminderBackgroundHandler(r);
        }
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      detailsFactory.createAndroidChannel(),
    );
    await android?.createNotificationChannel(
      detailsFactory.createReminderChannel(),
    );

    _initialized = true;
  }

  @override
  Future<Result<void>> schedule(Task task) async {
    try {
      await initialize();

      final DateTime now = DateTime.now();
      final bool wantsReminder = shouldScheduleReminder(task, now: now);
      final bool wantsAlarm = !task.isDone && task.dueAt.isAfter(now);
      await cancel(task.id);
      if (!wantsReminder && !wantsAlarm) {
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

      final String lang = _lang;

      if (wantsReminder) {
        final (:String title, :String body) = _reminderText(task, lang);
        await _plugin.zonedSchedule(
          id: task.id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(task.remindAt!, tz.local),
          notificationDetails: detailsFactory.createReminderDetails(
            doneLabel: ReminderNotificationText.doneLabel(languageCode: lang),
            snoozeLabel:
                ReminderNotificationText.snoozeLabel(languageCode: lang),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: ReminderActions.encodePayload(
            taskId: task.id,
            title: title,
            body: body,
          ),
        );
      }

      if (wantsAlarm) {
        final (:String title, :String body) = _alarmText(task, lang);
        await _plugin.zonedSchedule(
          id: _alarmId(task.id),
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(task.dueAt, tz.local),
          notificationDetails: detailsFactory.createNotificationDetails(
            doneLabel: ReminderNotificationText.doneLabel(languageCode: lang),
            snoozeLabel:
                ReminderNotificationText.snoozeLabel(languageCode: lang),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: ReminderActions.encodePayload(
            taskId: task.id,
            title: title,
            body: body,
          ),
        );
      }
      return const Success<void>(null);
    } on Object catch (error, stackTrace) {
      return _err(error, stackTrace);
    }
  }

  ({String title, String body}) _reminderText(Task task, String lang) {
    final ProfileController? p = profile;
    if (p == null) {
      return ReminderNotificationText.forTask(task, languageCode: lang);
    }
    return CopyPack.of(lang, p.tone).reminder(
      taskTitle: task.title,
      time: DateFormat.Hm().format(task.dueAt.toLocal()),
      before: task.remindBefore ?? Duration.zero,
      seed: task.id,
      name: p.name,
    );
  }

  ({String title, String body}) _alarmText(Task task, String lang) {
    final ProfileController? p = profile;
    if (p == null) {
      return ReminderNotificationText.forDeadline(task, languageCode: lang);
    }
    return CopyPack.of(lang, p.tone).alarm(
      taskTitle: task.title,
      seed: task.id,
      name: p.name,
    );
  }

  String get _lang =>
      languageCode?.call() ?? PlatformDispatcher.instance.locale.languageCode;

  /// Rings the deadline alarm again after [delay] (the "+10 min" button).
  Future<void> snooze({
    required int taskId,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    try {
      await initialize();
      final String lang = _lang;
      await _plugin.cancel(id: _alarmId(taskId));
      await _plugin.zonedSchedule(
        id: _alarmId(taskId),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: detailsFactory.createNotificationDetails(
          doneLabel: ReminderNotificationText.doneLabel(languageCode: lang),
          snoozeLabel: ReminderNotificationText.snoozeLabel(languageCode: lang),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: ReminderActions.encodePayload(
          taskId: taskId,
          title: title,
          body: body,
        ),
      );
    } on Object catch (error, stackTrace) {
      _err(error, stackTrace);
    }
  }

  @override
  Future<Result<void>> cancel(int taskId) async {
    try {
      await initialize();
      await _plugin.cancel(id: taskId);
      await _plugin.cancel(id: _alarmId(taskId));
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
        if (!task.isDone &&
            (shouldScheduleReminder(task, now: now) ||
                task.dueAt.isAfter(now))) {
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

  static const int _focusEndId = 2000000000;

  @override
  Future<void> scheduleFocusEnd({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    try {
      await initialize();
      await _plugin.zonedSchedule(
        id: _focusEndId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails:
            detailsFactory.createReminderDetails(withActions: false),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Object catch (error, stackTrace) {
      _err(error, stackTrace);
    }
  }

  @override
  Future<void> cancelFocusEnd() async {
    try {
      await initialize();
      await _plugin.cancel(id: _focusEndId);
    } on Object catch (error, stackTrace) {
      _err(error, stackTrace);
    }
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

  /// The deadline alarm uses its own id so it can coexist with the reminder.
  static int _alarmId(int taskId) => taskId + 1000000000;

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
