import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
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
import 'alarm_sound.dart';
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
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.customDismissAction,
          },
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

      final ({bool granted, AndroidScheduleMode mode}) env =
          await _environment();
      if (!env.granted) {
        return const Err<void>(PermissionFailure());
      }
      final AndroidScheduleMode mode = env.mode;

      final String lang = _lang;

      if (wantsReminder) {
        final (:String title, :String body) = _reminderText(task, lang);
        await _ring(
          id: task.id,
          at: task.remindAt!,
          title: title,
          body: body,
          mode: mode,
          taskId: task.id,
          kind: kindReminder,
          lang: lang,
        );
      }

      if (wantsAlarm) {
        final (:String title, :String body) = _alarmText(task, lang);
        await _ring(
          id: _alarmId(task.id),
          at: task.dueAt,
          title: title,
          body: body,
          mode: mode,
          taskId: task.id,
          kind: kindAlarm,
          lang: lang,
        );
      }
      return const Success<void>(null);
    } on Object catch (error, stackTrace) {
      return _err(error, stackTrace);
    }
  }

  ({bool granted, AndroidScheduleMode mode})? _envCache;
  DateTime? _envAt;

  /// Whether we may post notifications, and whether alarms can be exact.
  /// Cached briefly: restoring many tasks would otherwise ask the platform
  /// the same two questions for each one. Never opens a settings screen.
  Future<({bool granted, AndroidScheduleMode mode})> _environment() async {
    final DateTime now = DateTime.now();
    final ({bool granted, AndroidScheduleMode mode})? cached = _envCache;
    if (cached != null &&
        _envAt != null &&
        now.difference(_envAt!) < const Duration(seconds: 20)) {
      return cached;
    }
    final bool granted = (await checkNotificationsPermission()).isGranted;
    AndroidScheduleMode mode = AndroidScheduleMode.exactAllowWhileIdle;
    if (Platform.isAndroid) {
      final bool? canExact = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      if (canExact == false) {
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }
    final ({bool granted, AndroidScheduleMode mode}) env =
        (granted: granted, mode: mode);
    _envCache = env;
    _envAt = now;
    return env;
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


  /// iOS plays a notification sound once and for at most 30 seconds, so the
  /// alarm is repeated every [_repeatEvery] until the user reacts.
  static const int _repeatCount = 15;
  static const Duration _repeatEvery = Duration(seconds: 30);

  /// iOS keeps at most 64 pending notifications; stay clear of the limit.
  static const int _pendingBudget = 60;

  /// The reminder and the alarm each get their own block of ids (`r` / `a`).
  static int _repeatId(int taskId, String kind, int n) =>
      1100000000 + taskId * 32 + (kind == kindAlarm ? 16 : 0) + n;

  static const String kindReminder = 'r';
  static const String kindAlarm = 'a';

  /// Cancels the waiting repeats of one task; [kind] limits it to the
  /// reminder's or the alarm's chain.
  Future<void> cancelRepeats(int taskId, {String? kind}) async {
    if (!Platform.isIOS) {
      return;
    }
    await initialize();
    for (final String k in <String>[kindReminder, kindAlarm]) {
      if (kind != null && kind != k) {
        continue;
      }
      for (int n = 1; n <= _repeatCount; n++) {
        await _plugin.cancel(id: _repeatId(taskId, k, n));
      }
    }
  }

  /// Posts one alarm-style notification at [at]: the chosen sound, and on
  /// Android a looping sound that lasts until the notification is dismissed.
  Future<void> _ring({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required AndroidScheduleMode mode,
    required int taskId,
    required String kind,
    required String lang,
  }) async {
    final AlarmSound sound = await AlarmSound.load();
    final String? customPath = await sound.path();
    if (sound.isCustom && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            detailsFactory.createAndroidChannel(sound, customPath),
          );
    }
    final NotificationDetails details = detailsFactory.createNotificationDetails(
      doneLabel: ReminderNotificationText.doneLabel(languageCode: lang),
      snoozeLabel: ReminderNotificationText.snoozeLabel(languageCode: lang),
      sound: sound,
      customPath: customPath,
    );
    final String payload = ReminderActions.encodePayload(
      taskId: taskId,
      title: title,
      body: body,
      kind: kind,
    );
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: details,
      androidScheduleMode: mode,
      payload: payload,
    );
    if (!Platform.isIOS) {
      return;
    }
    final int pending = (await _plugin.pendingNotificationRequests()).length;
    final int repeats = (_pendingBudget - pending).clamp(0, _repeatCount);
    for (int n = 1; n <= repeats; n++) {
      await _plugin.zonedSchedule(
        id: _repeatId(taskId, kind, n),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at.add(_repeatEvery * n), tz.local),
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: payload,
      );
    }
  }

  /// Stops the repeating iOS alarm once the user is back in the app: clears
  /// the repeats still waiting and the ones already shown. Returns whether
  /// anything was cleared, so the caller can re-plan the future ones.
  Future<bool> stopRinging() async {
    if (!Platform.isIOS) {
      return false;
    }
    await initialize();
    bool cleared = false;
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    for (final PendingNotificationRequest r in pending) {
      if (r.id >= 1100000000 && r.id < 2000000000) {
        await _plugin.cancel(id: r.id);
        cleared = true;
      }
    }
    final List<ActiveNotification> shown =
        await _plugin.getActiveNotifications();
    for (final ActiveNotification n in shown) {
      final int? id = n.id;
      if (id != null && id >= 1100000000 && id < 2000000000) {
        await _plugin.cancel(id: id);
      }
    }
    return cleared;
  }

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
      await cancelRepeats(taskId);
      await _plugin.cancel(id: _alarmId(taskId));
      await _plugin.cancel(id: taskId);
      await _ring(
        id: _alarmId(taskId),
        at: DateTime.now().add(delay),
        title: title,
        body: body,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
        taskId: taskId,
        kind: kindAlarm,
        lang: lang,
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
      await cancelRepeats(taskId);
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
      // Soonest first, so the repeats that fit under the iOS limit go to the
      // alarms that ring next.
      final List<Task> ordered = <Task>[...tasks]
        ..sort((Task a, Task b) => a.dueAt.compareTo(b.dueAt));
      for (final Task task in ordered) {
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
    _envCache = null;

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
    _envCache = null;

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
