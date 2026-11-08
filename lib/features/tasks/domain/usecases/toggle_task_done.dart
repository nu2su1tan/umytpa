import '../../../../core/error/result.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../entities/subtask.dart';
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
    if (!isDone) {
      await _dropSpawnedNext(id, now: now);
    }
    final Result<Task> updated = await repository.setDone(
      id: id,
      isDone: isDone,
      now: now,
    );

    return updated.flatMap((Task task) async {
      if (task.isDone) {
        await reminderScheduler.cancel(task.id);
        if (task.repeat.repeats) {
          await _spawnNext(task, now: now);
        }
      } else if (shouldScheduleNotifications(task, now: now)) {
        await reminderScheduler.schedule(task);
      }
      return Success<Task>(task);
    });
  }

  /// A repeating task comes back with the next due date and a fresh checklist.
  Future<void> _spawnNext(Task done, {required DateTime now}) async {
    final Result<Task> created = await repository.create(
      NewTask(
        title: done.title,
        dueAt: done.repeat.nextAfter(done.dueAt, now: now),
        category: done.category,
        remindBefore: done.remindBefore,
        repeat: done.repeat,
        subtasks: done.subtasks
            .map((Subtask s) => s.copyWith(isDone: false))
            .toList(growable: false),
      ),
    );
    if (created case Success<Task>(:final value)) {
      if (shouldScheduleNotifications(value, now: now)) {
        await reminderScheduler.schedule(value);
      }
    }
  }

  /// Un-ticking a repeating task (a mis-tap) must not leave the next
  /// occurrence it created behind as a duplicate.
  Future<void> _dropSpawnedNext(int id, {required DateTime now}) async {
    final Result<Task> before = await repository.getById(id);
    if (before is! Success<Task>) {
      return;
    }
    final Task task = before.value;
    if (!task.isDone || !task.repeat.repeats) {
      return;
    }
    final DateTime expected = task.repeat.nextAfter(
      task.dueAt,
      now: task.completedAt ?? now,
    );
    final List<Task> all = await repository.watchAll().first;
    for (final Task other in all) {
      if (other.id != task.id &&
          !other.isDone &&
          other.title == task.title &&
          other.category == task.category &&
          other.repeat == task.repeat &&
          other.dueAt == expected) {
        await repository.delete(other.id);
        await reminderScheduler.cancel(other.id);
        return;
      }
    }
  }
}
