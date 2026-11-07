import '../../../../core/error/result.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import 'should_schedule_reminder.dart';

class ToggleTaskDone {
  const ToggleTaskDone({
    required this.repository,
    required this.reminderScheduler,
  });

  final TaskRepository repository;
  final ReminderScheduler reminderScheduler;

  Future<Result<Task>> call({
    required int id,
    required bool isDone,
    required DateTime now,
  }) async {
    final Result<Task> updated = await repository.setDone(
      id: id,
      isDone: isDone,
    );

    return updated.flatMap((Task task) async {
      if (task.isDone) {
        await reminderScheduler.cancel(task.id);
      } else if (shouldScheduleReminder(task, now: now)) {
        await reminderScheduler.schedule(task);
      }
      return Success<Task>(task);
    });
  }
}
