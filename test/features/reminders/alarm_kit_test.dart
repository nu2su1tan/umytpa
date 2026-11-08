import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/reminders/data/alarm_kit.dart';
import 'package:umytpa/features/reminders/data/reminder_notification_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('umytpa/alarmkit');
  final List<MethodCall> calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('alarmId', () {
    test('is a valid UUID that carries the task id', () {
      expect(
        AlarmKitService.alarmId(1),
        '00000000-0000-4000-8000-000000000001',
      );
      expect(
        AlarmKitService.alarmId(255),
        '00000000-0000-4000-8000-0000000000ff',
      );
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ).hasMatch(AlarmKitService.alarmId(123456789)),
        isTrue,
      );
    });

    test('differs for different tasks', () {
      expect(AlarmKitService.alarmId(7), isNot(AlarmKitService.alarmId(8)));
    });
  });

  group('not on iOS', () {
    test('everything says no and never calls the platform', () async {
      answer((_) => 'authorized');
      final AlarmKitService service = AlarmKitService(isIOS: false);
      expect(await service.status(), AlarmKitStatus.unsupported);
      expect(await service.request(), AlarmKitStatus.unsupported);
      expect(await service.isReady, isFalse);
      expect(
        await service.schedule(
          taskId: 1,
          at: DateTime(2030),
          title: 't',
          stopLabel: 'Stop',
        ),
        isFalse,
      );
      await service.cancel(1);
      expect(calls, isEmpty);
    });
  });

  group('on iOS', () {
    test('maps the system status', () async {
      for (final (String raw, AlarmKitStatus expected)
          in <(String, AlarmKitStatus)>[
            ('unsupported', AlarmKitStatus.unsupported),
            ('notDetermined', AlarmKitStatus.notDetermined),
            ('denied', AlarmKitStatus.denied),
            ('authorized', AlarmKitStatus.authorized),
            ('something new', AlarmKitStatus.unsupported),
          ]) {
        answer((_) => raw);
        final AlarmKitService service = AlarmKitService(
          channel: channel,
          isIOS: true,
        );
        expect(await service.status(), expected, reason: raw);
      }
    });

    test('status is cached briefly', () async {
      answer((_) => 'authorized');
      final AlarmKitService service = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      await service.status();
      await service.status();
      await service.isReady;
      expect(calls.where((MethodCall c) => c.method == 'status'), hasLength(1));
    });

    test('request asks only when the answer is still open', () async {
      answer(
        (MethodCall c) => c.method == 'status' ? 'notDetermined' : 'authorized',
      );
      final AlarmKitService open = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      expect(await open.request(), AlarmKitStatus.authorized);
      expect(calls.map((MethodCall c) => c.method), <String>[
        'status',
        'request',
      ]);
      // The answer is remembered.
      expect(await open.isReady, isTrue);

      calls.clear();
      answer((_) => 'denied');
      final AlarmKitService refused = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      expect(await refused.request(), AlarmKitStatus.denied);
      expect(calls.map((MethodCall c) => c.method), <String>['status']);
    });

    test('schedule sends everything the native side needs', () async {
      answer((_) => true);
      final AlarmKitService service = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      final DateTime at = DateTime.utc(2030, 5, 17, 9, 30);
      final bool ok = await service.schedule(
        taskId: 42,
        at: at,
        title: 'Report',
        stopLabel: 'Stop',
        sound: 'alarm_1.caf',
      );
      expect(ok, isTrue);
      final MethodCall call = calls.single;
      expect(call.method, 'schedule');
      expect(call.arguments, <String, Object?>{
        'id': AlarmKitService.alarmId(42),
        'at': at.millisecondsSinceEpoch,
        'title': 'Report',
        'stop': 'Stop',
        'sound': 'alarm_1.caf',
      });
    });

    test('schedule leaves the sound out when there is none', () async {
      answer((_) => true);
      final AlarmKitService service = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      await service.schedule(
        taskId: 1,
        at: DateTime(2030),
        title: 't',
        stopLabel: 'Stop',
      );
      expect(
        (calls.single.arguments as Map<Object?, Object?>).containsKey('sound'),
        isFalse,
      );
    });

    test('a refused or failed schedule is just "false"', () async {
      final AlarmKitService service = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      for (final Object? Function(MethodCall) handler
          in <Object? Function(MethodCall)>[
            (_) => false,
            (_) => null,
            (_) => throw PlatformException(code: 'schedule', message: 'limit'),
          ]) {
        answer(handler);
        expect(
          await service.schedule(
            taskId: 1,
            at: DateTime(2030),
            title: 't',
            stopLabel: 'Stop',
          ),
          isFalse,
        );
      }
    });

    test('a missing channel (background isolate) is survivable', () async {
      // No handler registered: the call throws MissingPluginException.
      final AlarmKitService service = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      expect(await service.status(), AlarmKitStatus.unsupported);
      expect(await service.isReady, isFalse);
      expect(
        await service.schedule(
          taskId: 1,
          at: DateTime(2030),
          title: 't',
          stopLabel: 'Stop',
        ),
        isFalse,
      );
      await service.cancel(1);
      expect(await service.count(), 0);
    });

    test('an answer of the wrong type is survivable', () async {
      answer((_) => false);
      final AlarmKitService service = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      expect(await service.count(), 0);
      expect(await service.status(), AlarmKitStatus.unsupported);
    });

    test('cancel sends the task alarm id', () async {
      answer((_) => true);
      final AlarmKitService service = AlarmKitService(
        channel: channel,
        isIOS: true,
      );
      await service.cancel(9);
      expect(calls.single.method, 'cancel');
      expect(calls.single.arguments, <String, Object?>{
        'id': AlarmKitService.alarmId(9),
      });
    });
  });

  test('stop button is translated', () {
    expect(ReminderNotificationText.stopLabel(languageCode: 'ru'), 'Стоп');
    expect(ReminderNotificationText.stopLabel(languageCode: 'kk'), 'Тоқтату');
    expect(ReminderNotificationText.stopLabel(languageCode: 'en'), 'Stop');
    expect(ReminderNotificationText.stopLabel(), 'Stop');
  });
}
