import '../../../../core/error/result.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../reminder_scheduler.dart';

/// Reloads unfinished tasks and restores future notifications after app start.
class RescheduleAllReminders {
  const RescheduleAllReminders({
    required this.repository,
    required this.reminderScheduler,
  });

  final TaskRepository repository;
  final ReminderScheduler reminderScheduler;

  Future<Result<void>> call() async {
    final List<Task> tasks = await repository.watchAll().first;
    return reminderScheduler.rescheduleAll(tasks);
  }
}
