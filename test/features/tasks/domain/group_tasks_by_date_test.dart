import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/domain/entities/task_section.dart';
import 'package:umytpa/features/tasks/domain/usecases/group_tasks_by_date.dart';

Task _task({
  required int id,
  required DateTime dueAt,
  bool isDone = false,
  String title = 'Task',
}) {
  return Task(
    id: id,
    title: title,
    dueAt: dueAt,
    category: TaskCategory.study,
    remindBefore: null,
    isDone: isDone,
    createdAt: DateTime.parse('2026-01-01'),
  );
}

void main() {
  const GroupTasksByDate groupTasks = GroupTasksByDate();

  group('GroupTasksByDate', () {
    test('places incomplete past-due into Overdue', () {
      final DateTime now = DateTime(2026, 10, 30, 12);
      final List<TaskSection> sections = groupTasks(
        <Task>[
          _task(id: 1, dueAt: DateTime(2026, 10, 29, 18)),
          _task(id: 2, dueAt: DateTime(2026, 10, 30, 11, 59)),
        ],
        now: now,
      );

      expect(sections, hasLength(1));
      expect(sections.single.kind, TaskSectionKind.overdue);
      expect(sections.single.tasks.map((Task t) => t.id), <int>[1, 2]);
    });

    test('exactly now is not overdue (boundary)', () {
      final DateTime now = DateTime(2026, 10, 30, 12);
      final List<TaskSection> sections = groupTasks(
        <Task>[_task(id: 1, dueAt: now)],
        now: now,
      );

      expect(sections.single.kind, TaskSectionKind.today);
      expect(sections.single.tasks.single.id, 1);
    });

    test('groups today, tomorrow, and later by calendar day', () {
      final DateTime now = DateTime(2026, 10, 30, 9);
      final List<TaskSection> sections = groupTasks(
        <Task>[
          _task(id: 1, dueAt: DateTime(2026, 10, 30, 17)),
          _task(id: 2, dueAt: DateTime(2026, 10, 31, 10)),
          _task(id: 3, dueAt: DateTime(2026, 11, 2, 10)),
        ],
        now: now,
      );

      expect(
        sections.map((TaskSection s) => s.kind),
        <TaskSectionKind>[
          TaskSectionKind.today,
          TaskSectionKind.tomorrow,
          TaskSectionKind.later,
        ],
      );
      expect(sections[0].tasks.single.id, 1);
      expect(sections[1].tasks.single.id, 2);
      expect(sections[2].tasks.single.id, 3);
    });

    test('midnight: 00:00 today is Today, not Overdue when now is 00:00', () {
      final DateTime now = DateTime(2026, 10, 30);
      final List<TaskSection> sections = groupTasks(
        <Task>[_task(id: 1, dueAt: DateTime(2026, 10, 30))],
        now: now,
      );
      expect(sections.single.kind, TaskSectionKind.today);
    });

    test('midnight: 23:59 yesterday is Overdue at 00:00', () {
      final DateTime now = DateTime(2026, 10, 30);
      final List<TaskSection> sections = groupTasks(
        <Task>[_task(id: 1, dueAt: DateTime(2026, 10, 29, 23, 59))],
        now: now,
      );
      expect(sections.single.kind, TaskSectionKind.overdue);
    });

    test('completed yesterday goes to Completed section', () {
      final DateTime now = DateTime(2026, 10, 30, 12);
      final List<TaskSection> sections = groupTasks(
        <Task>[
          _task(
            id: 1,
            dueAt: DateTime(2026, 10, 29, 18),
            isDone: true,
          ),
        ],
        now: now,
      );
      expect(sections.single.kind, TaskSectionKind.completed);
      expect(sections.single.kind.initiallyCollapsed, isTrue);
    });

    test('completed today stays in Today, after incomplete', () {
      final DateTime now = DateTime(2026, 10, 30, 12);
      final List<TaskSection> sections = groupTasks(
        <Task>[
          _task(
            id: 1,
            dueAt: DateTime(2026, 10, 30, 9),
            isDone: true,
            title: 'Done morning',
          ),
          _task(
            id: 2,
            dueAt: DateTime(2026, 10, 30, 17),
            title: 'Later today',
          ),
        ],
        now: now,
      );

      expect(sections.single.kind, TaskSectionKind.today);
      expect(
        sections.single.tasks.map((Task t) => t.id),
        <int>[2, 1],
      );
    });

    test('completed with past due time today stays in Today, not Overdue', () {
      final DateTime now = DateTime(2026, 10, 30, 18);
      final List<TaskSection> sections = groupTasks(
        <Task>[
          _task(
            id: 1,
            dueAt: DateTime(2026, 10, 30, 9),
            isDone: true,
          ),
        ],
        now: now,
      );
      expect(sections.single.kind, TaskSectionKind.today);
    });

    test('omits empty sections', () {
      final DateTime now = DateTime(2026, 10, 30, 12);
      final List<TaskSection> sections = groupTasks(
        <Task>[_task(id: 1, dueAt: DateTime(2026, 11, 5, 10))],
        now: now,
      );
      expect(sections, hasLength(1));
      expect(sections.single.kind, TaskSectionKind.later);
    });

    test('Overdue never contains completed tasks', () {
      final DateTime now = DateTime(2026, 10, 30, 12);
      final List<TaskSection> sections = groupTasks(
        <Task>[
          _task(id: 1, dueAt: DateTime(2026, 10, 28, 10), isDone: true),
          _task(id: 2, dueAt: DateTime(2026, 10, 28, 11)),
        ],
        now: now,
      );
      final TaskSection overdue = sections.firstWhere(
        (TaskSection s) => s.kind == TaskSectionKind.overdue,
      );
      expect(overdue.tasks.every((Task t) => !t.isDone), isTrue);
      expect(
        sections.any((TaskSection s) => s.kind == TaskSectionKind.completed),
        isTrue,
      );
    });
  });
}
