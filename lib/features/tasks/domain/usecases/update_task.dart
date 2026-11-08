import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../validation/task_input_validator.dart';
import 'should_schedule_reminder.dart';

class UpdateTask {
  const UpdateTask({
    required this.repository,
    required this.reminderScheduler,
  });

  final TaskRepository repository;
  final ReminderScheduler reminderScheduler;

  Future<Result<Task>> call(Task task, {required DateTime now}) async {
    final TaskInputValidation validation = TaskInputValidator.validate(
      title: task.title,
      dueAt: task.dueAt,
      remindBefore: task.remindBefore,
      isNew: false,
      now: now,
    );
    if (!validation.isValid) {
      final String message =
          validation.titleError ?? validation.dueAtError ?? 'Invalid input';
      return Err<Task>(ValidationFailure(message));
    }

    final Task normalized = task.copyWith(title: task.title.trim());
    final Result<Task> updated = await repository.update(normalized);

    return updated.flatMap((Task saved) async {
      await reminderScheduler.cancel(saved.id);
      if (shouldScheduleNotifications(saved, now: now)) {
        await reminderScheduler.schedule(saved);
      }
      return Success<Task>(saved);
    });
  }
}
