import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/reminders/data/reminder_notification_text.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';

void main() {
  group('ReminderNotificationText', () {
    test('formats known presets', () {
      expect(
        ReminderNotificationText.titleFor(const Duration(minutes: 5)),
        '5 minutes left',
      );
      expect(
        ReminderNotificationText.titleFor(const Duration(minutes: 30)),
        '30 minutes left',
      );
      expect(
        ReminderNotificationText.titleFor(const Duration(hours: 1)),
        '1 hour left',
      );
      expect(
        ReminderNotificationText.titleFor(const Duration(days: 1)),
        '1 day left',
      );
      expect(
        ReminderNotificationText.titleFor(Duration.zero),
        'Due now',
      );
    });

    test('builds body with title and due time', () {
      final Task task = Task(
        id: 1,
        title: 'Review pitch deck',
        dueAt: DateTime(2026, 10, 30, 17),
        category: TaskCategory.work,
        remindBefore: const Duration(hours: 1),
        isDone: false,
        createdAt: DateTime.parse('2026-01-01'),
      );

      expect(
        ReminderNotificationText.bodyFor(task),
        'Review pitch deck · due 17:00',
      );

      final (:String title, :String body) =
          ReminderNotificationText.forTask(task);
      expect(title, '1 hour left');
      expect(body, 'Review pitch deck · due 17:00');
    });
  });
}
