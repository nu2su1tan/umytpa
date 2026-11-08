import 'dart:io';

import 'package:flutter/services.dart';

/// Whether the system lets the app ring real alarms (iOS 26+, AlarmKit).
enum AlarmKitStatus { unsupported, notDetermined, denied, authorized }

/// Real alarms on iOS 26 and later: they ring until stopped, through silent
/// mode and Focus, like the Clock app. Everything here is best effort: on
/// other systems, in a background isolate (where the channel does not
/// exist) or on any error it reports "no" and the caller keeps using
/// notifications.
class AlarmKitService {
  AlarmKitService({MethodChannel? channel, bool? isIOS})
    : _channel = channel ?? const MethodChannel('umytpa/alarmkit'),
      _isIOS = isIOS ?? Platform.isIOS;

  final MethodChannel _channel;
  final bool _isIOS;

  /// The alarm of a task has a fixed id, so it can be cancelled by task id.
  /// The system wants a UUID; the task id fills its last 12 hex digits.
  static String alarmId(int taskId) =>
      '00000000-0000-4000-8000-${taskId.toRadixString(16).padLeft(12, '0')}';

  AlarmKitStatus? _cached;
  DateTime? _cachedAt;

  Future<AlarmKitStatus> status() async {
    if (!_isIOS) {
      return AlarmKitStatus.unsupported;
    }
    final DateTime now = DateTime.now();
    final AlarmKitStatus? cached = _cached;
    if (cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < const Duration(seconds: 20)) {
      return cached;
    }
    final AlarmKitStatus fresh = _parse(await _call<String>('status'));
    _cached = fresh;
    _cachedAt = now;
    return fresh;
  }

  /// Shows the system permission dialog when it has not been answered yet.
  Future<AlarmKitStatus> request() async {
    if (!_isIOS) {
      return AlarmKitStatus.unsupported;
    }
    final AlarmKitStatus current = await status();
    if (current != AlarmKitStatus.notDetermined) {
      return current;
    }
    final AlarmKitStatus result = _parse(await _call<String>('request'));
    _cached = result;
    _cachedAt = DateTime.now();
    return result;
  }

  Future<bool> get isReady async => await status() == AlarmKitStatus.authorized;

  /// Rings [title] at [at] until the user stops it. Returns whether the
  /// system accepted the alarm.
  Future<bool> schedule({
    required int taskId,
    required DateTime at,
    required String title,
    required String stopLabel,
    String? sound,
  }) async {
    if (!_isIOS) {
      return false;
    }
    final bool? ok = await _call<bool>('schedule', <String, Object?>{
      'id': alarmId(taskId),
      'at': at.millisecondsSinceEpoch,
      'title': title,
      'stop': stopLabel,
      if (sound != null) 'sound': sound,
    });
    return ok == true;
  }

  Future<void> cancel(int taskId) async {
    if (!_isIOS) {
      return;
    }
    await _call<bool>('cancel', <String, Object?>{'id': alarmId(taskId)});
  }

  /// How many alarms the system holds for the app (for diagnostics).
  Future<int> count() async => await _call<int>('count') ?? 0;

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on Object {
      // No channel (background isolate), a platform error or an answer of an
      // unexpected type: all mean "the system alarm is not available".
      return null;
    }
  }

  static AlarmKitStatus _parse(String? value) => switch (value) {
    'notDetermined' => AlarmKitStatus.notDetermined,
    'denied' => AlarmKitStatus.denied,
    'authorized' => AlarmKitStatus.authorized,
    _ => AlarmKitStatus.unsupported,
  };
}
