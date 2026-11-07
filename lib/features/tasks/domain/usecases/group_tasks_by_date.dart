import '../../../../core/utils/date_time_utils.dart';
import '../entities/task.dart';
import '../entities/task_section.dart';

/// Groups tasks into date-based sections.
///
/// Rules:
/// - Overdue: incomplete tasks with [Task.dueAt] strictly before [now]
/// - Today / Tomorrow / Later: by calendar day of [Task.dueAt]
/// - Completed incomplete-past: completed tasks whose due day is before today
/// - Completed tasks due today/tomorrow/later stay in those sections (at end)
/// - Empty sections are omitted
class GroupTasksByDate {
  const GroupTasksByDate();

  List<TaskSection> call(List<Task> tasks, {required DateTime now}) {
    final DateTime todayStart = DateTimeUtils.startOfDay(now);
    final DateTime tomorrowStart = DateTimeUtils.startOfTomorrow(now);
    final DateTime laterStart = DateTimeUtils.startOfDayAfterTomorrow(now);

    final List<Task> overdue = <Task>[];
    final List<Task> today = <Task>[];
    final List<Task> tomorrow = <Task>[];
    final List<Task> later = <Task>[];
    final List<Task> completedPast = <Task>[];

    for (final Task task in tasks) {
      if (task.isDone && task.dueAt.isBefore(todayStart)) {
        completedPast.add(task);
        continue;
      }

      if (!task.isDone && task.dueAt.isBefore(now)) {
        overdue.add(task);
        continue;
      }

      if (task.dueAt.isBefore(tomorrowStart)) {
        today.add(task);
      } else if (task.dueAt.isBefore(laterStart)) {
        tomorrow.add(task);
      } else {
        later.add(task);
      }
    }

    return <TaskSection>[
      if (overdue.isNotEmpty)
        TaskSection(kind: TaskSectionKind.overdue, tasks: _sortSection(overdue)),
      if (today.isNotEmpty)
        TaskSection(kind: TaskSectionKind.today, tasks: _sortSection(today)),
      if (tomorrow.isNotEmpty)
        TaskSection(
          kind: TaskSectionKind.tomorrow,
          tasks: _sortSection(tomorrow),
        ),
      if (later.isNotEmpty)
        TaskSection(kind: TaskSectionKind.later, tasks: _sortSection(later)),
      if (completedPast.isNotEmpty)
        TaskSection(
          kind: TaskSectionKind.completed,
          tasks: _sortCompleted(completedPast),
        ),
    ];
  }

  /// Incomplete first (by dueAt), then completed (by dueAt).
  static List<Task> _sortSection(List<Task> tasks) {
    final List<Task> incomplete =
        tasks.where((Task t) => !t.isDone).toList()
          ..sort((Task a, Task b) => a.dueAt.compareTo(b.dueAt));
    final List<Task> completed =
        tasks.where((Task t) => t.isDone).toList()
          ..sort((Task a, Task b) => a.dueAt.compareTo(b.dueAt));
    return <Task>[...incomplete, ...completed];
  }

  static List<Task> _sortCompleted(List<Task> tasks) {
    return List<Task>.of(tasks)
      ..sort((Task a, Task b) => b.dueAt.compareTo(a.dueAt));
  }
}
