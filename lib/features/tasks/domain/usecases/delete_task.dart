import '../../../../core/error/result.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../repositories/task_repository.dart';

class DeleteTask {
  const DeleteTask({
    required this.repository,
    required this.reminderScheduler,
  });

  final TaskRepository repository;
  final ReminderScheduler reminderScheduler;

  Future<Result<void>> call(int id) async {
    await reminderScheduler.cancel(id);
    return repository.delete(id);
  }
}
