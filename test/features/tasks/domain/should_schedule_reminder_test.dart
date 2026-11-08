import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/domain/usecases/should_schedule_reminder.dart';

Task _task({
  required DateTime dueAt,
  Duration? remindBefore,
  bool isDone = false,
}) {
  return Task(
    id: 1,
    title: 'Test',
    dueAt: dueAt,
    category: TaskCategory.personal,
    remindBefore: remindBefore,
    isDone: isDone,
    createdAt: DateTime.parse('2026-01-01'),
  );
}

void main() {
  final DateTime now = DateTime(2026, 10, 30, 16);

  group('shouldScheduleReminder', () {
    test('true when remindAt is in the future', () {
      final Task task = _task(
        dueAt: DateTime(2026, 10, 30, 17),
        remindBefore: const Duration(hours: 1),
      );
      // remindAt == 16:00, now == 16:00 → not after
      expect(shouldScheduleReminder(task, now: now), isFalse);
      expect(
        shouldScheduleReminder(
          task,
          now: now.subtract(const Duration(minutes: 1)),
        ),
        isTrue,
      );
    });

    test('false when done', () {
      final Task task = _task(
        dueAt: DateTime(2026, 10, 30, 18),
        remindBefore: const Duration(hours: 1),
        isDone: true,
      );
      expect(shouldScheduleReminder(task, now: now), isFalse);
    });

    test('false when no reminder', () {
      final Task task = _task(dueAt: DateTime(2026, 10, 30, 18));
      expect(shouldScheduleReminder(task, now: now), isFalse);
    });
  });

  group('shouldScheduleNotifications', () {
    test('true when the deadline is closer than the reminder lead time', () {
      // remindAt is already past, but the deadline alarm is still ahead.
      final Task task = _task(
        dueAt: DateTime(2026, 10, 30, 16, 40),
        remindBefore: const Duration(hours: 1),
      );
      expect(shouldScheduleReminder(task, now: now), isFalse);
      expect(shouldScheduleNotifications(task, now: now), isTrue);
    });

    test('true with no reminder while the deadline is ahead', () {
      final Task task = _task(dueAt: DateTime(2026, 10, 30, 18));
      expect(shouldScheduleNotifications(task, now: now), isTrue);
    });

    test('false when done or the deadline has passed', () {
      expect(
        shouldScheduleNotifications(
          _task(dueAt: DateTime(2026, 10, 30, 18), isDone: true),
          now: now,
        ),
        isFalse,
      );
      expect(
        shouldScheduleNotifications(
          _task(dueAt: DateTime(2026, 10, 30, 15)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
