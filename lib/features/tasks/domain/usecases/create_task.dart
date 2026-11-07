import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../validation/task_input_validator.dart';
import 'should_schedule_reminder.dart';

class CreateTask {
  const CreateTask({
    required this.repository,
    required this.reminderScheduler,
  });

  final TaskRepository repository;
  final ReminderScheduler reminderScheduler;

  Future<Result<Task>> call(NewTask input, {required DateTime now}) async {
    final TaskInputValidation validation = TaskInputValidator.validate(
      title: input.title,
      dueAt: input.dueAt,
      remindBefore: input.remindBefore,
      isNew: true,
      now: now,
    );
    if (!validation.isValid) {
      final String message =
          validation.titleError ?? validation.dueAtError ?? 'Invalid input';
      return Err<Task>(ValidationFailure(message));
    }

    final NewTask normalized = NewTask(
      title: input.title.trim(),
      dueAt: input.dueAt,
      category: input.category,
      remindBefore: input.remindBefore,
    );

    final Result<Task> created = await repository.create(normalized);
    return created.flatMap((Task task) async {
      if (shouldScheduleReminder(task, now: now)) {
        await reminderScheduler.schedule(task);
      }
      return Success<Task>(task);
    });
  }
}
