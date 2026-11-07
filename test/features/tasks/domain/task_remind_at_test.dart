import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/tasks/domain/entities/reminder_preset.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';

Task _task({
  required DateTime dueAt,
  Duration? remindBefore,
}) {
  return Task(
    id: 1,
    title: 'Test',
    dueAt: dueAt,
    category: TaskCategory.work,
    remindBefore: remindBefore,
    isDone: false,
    createdAt: DateTime.parse('2026-01-01T00:00:00Z').toUtc(),
  );
}

void main() {
  group('Task.remindAt', () {
    test('is null when remindBefore is null', () {
      final Task task = _task(
        dueAt: DateTime(2026, 10, 30, 17),
      );
      expect(task.remindAt, isNull);
    });

    test('subtracts one hour', () {
      final Task task = _task(
        dueAt: DateTime(2026, 10, 30, 17),
        remindBefore: ReminderPreset.oneHour.duration,
      );
      expect(task.remindAt, DateTime(2026, 10, 30, 16));
    });

    test('subtracts five minutes', () {
      final Task task = _task(
        dueAt: DateTime(2026, 10, 30, 17),
        remindBefore: ReminderPreset.fiveMinutes.duration,
      );
      expect(task.remindAt, DateTime(2026, 10, 30, 16, 55));
    });

    test('subtracts one day across midnight', () {
      final Task task = _task(
        dueAt: DateTime(2026, 10, 30, 10),
        remindBefore: ReminderPreset.oneDay.duration,
      );
      expect(task.remindAt, DateTime(2026, 10, 29, 10));
    });

    test('ReminderPreset.fromDuration round-trips', () {
      for (final ReminderPreset preset in ReminderPreset.values
          .where((ReminderPreset p) => p != ReminderPreset.custom)) {
        expect(ReminderPreset.fromDuration(preset.duration), preset);
      }
    });
  });
}
