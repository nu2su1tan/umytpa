import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:umytpa/core/error/result.dart';
import 'package:umytpa/features/tasks/data/task_defaults.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/domain/entities/task_section.dart';
import 'package:umytpa/features/tasks/domain/usecases/create_task.dart';
import 'package:umytpa/features/tasks/domain/usecases/delete_task.dart';
import 'package:umytpa/features/tasks/domain/usecases/group_tasks_by_date.dart';
import 'package:umytpa/features/tasks/domain/usecases/quick_times.dart';
import 'package:umytpa/features/tasks/domain/usecases/toggle_task_done.dart';
import 'package:umytpa/features/tasks/domain/usecases/watch_tasks.dart';
import 'package:umytpa/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:umytpa/features/tasks/presentation/cubit/tasks_state.dart';

class _MockWatchTasks extends Mock implements WatchTasks {}

class _MockToggleTaskDone extends Mock implements ToggleTaskDone {}

class _MockDeleteTask extends Mock implements DeleteTask {}

class _MockCreateTask extends Mock implements CreateTask {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockToggleTaskDone toggleTaskDone;
  late _MockDeleteTask deleteTask;
  late _MockCreateTask createTask;
  late StreamController<List<Task>> controller;

  final DateTime now = DateTime(2026, 10, 30, 12);

  Task buildTask({
    int id = 1,
    TaskCategory category = TaskCategory.work,
    DateTime? dueAt,
    bool isDone = false,
  }) {
    return Task(
      id: id,
      title: 'Task $id',
      dueAt: dueAt ?? DateTime(2026, 10, 30, 17),
      category: category,
      remindBefore: const Duration(hours: 1),
      isDone: isDone,
      createdAt: DateTime.parse('2026-01-01'),
    );
  }

  TasksCubit buildCubit() {
    return TasksCubit(
      watchTasks: watchTasks,
      toggleTaskDone: toggleTaskDone,
      deleteTaskUseCase: deleteTask,
      createTask: createTask,
      groupTasksByDate: const GroupTasksByDate(),
      now: () => now,
    );
  }

  setUpAll(() {
    registerFallbackValue(buildTask());
    registerFallbackValue(
      NewTask(
        title: 'x',
        dueAt: now,
        category: TaskCategory.other,
        remindBefore: null,
      ),
    );
  });

  setUp(() {
    watchTasks = _MockWatchTasks();
    toggleTaskDone = _MockToggleTaskDone();
    deleteTask = _MockDeleteTask();
    createTask = _MockCreateTask();
    controller = StreamController<List<Task>>.broadcast();
    when(() => watchTasks()).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  group('TasksCubit', () {
    blocTest<TasksCubit, TasksState>(
      'emits loading then loaded sections from watch stream',
      build: buildCubit,
      act: (TasksCubit cubit) async {
        cubit.start();
        controller.add(<Task>[
          buildTask(),
          buildTask(
            id: 2,
            dueAt: DateTime(2026, 10, 29, 18),
            category: TaskCategory.study,
          ),
        ]);
        await pumpEventQueue();
      },
      expect: () => <Matcher>[
        isA<TasksLoading>(),
        isA<TasksLoaded>()
            .having(
              (TasksLoaded s) => s.allTasks,
              'allTasks',
              hasLength(2),
            )
            .having(
              (TasksLoaded s) => s.sections.map((TaskSection e) => e.kind),
              'kinds',
              containsAll(<TaskSectionKind>[
                TaskSectionKind.overdue,
                TaskSectionKind.today,
              ]),
            ),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'filters by category',
      build: buildCubit,
      act: (TasksCubit cubit) async {
        cubit.start();
        controller.add(<Task>[
          buildTask(),
          buildTask(id: 2, category: TaskCategory.study),
        ]);
        await pumpEventQueue();
        cubit.selectCategory(TaskCategory.study);
      },
      expect: () => <Matcher>[
        isA<TasksLoading>(),
        isA<TasksLoaded>().having(
          (TasksLoaded s) => s.sections.expand((TaskSection e) => e.tasks),
          'tasks',
          hasLength(2),
        ),
        isA<TasksLoaded>()
            .having(
              (TasksLoaded s) => s.selectedCategory,
              'filter',
              TaskCategory.study,
            )
            .having(
              (TasksLoaded s) =>
                  s.sections.expand((TaskSection e) => e.tasks).single.category,
              'only study',
              TaskCategory.study,
            ),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'keeps Completed section collapsed by default and can expand',
      build: buildCubit,
      act: (TasksCubit cubit) async {
        cubit.start();
        controller.add(<Task>[
          buildTask(
            dueAt: DateTime(2026, 10, 28, 10),
            isDone: true,
          ),
        ]);
        await pumpEventQueue();
        cubit.toggleSection(TaskSectionKind.completed);
      },
      expect: () => <Matcher>[
        isA<TasksLoading>(),
        isA<TasksLoaded>().having(
          (TasksLoaded s) =>
              s.collapsedSections.contains(TaskSectionKind.completed),
          'collapsed',
          isTrue,
        ),
        isA<TasksLoaded>().having(
          (TasksLoaded s) =>
              s.collapsedSections.contains(TaskSectionKind.completed),
          'expanded',
          isFalse,
        ),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'toggleDone delegates to use case',
      build: buildCubit,
      setUp: () {
        when(
          () => toggleTaskDone(
            id: any(named: 'id'),
            isDone: any(named: 'isDone'),
            now: any(named: 'now'),
          ),
        ).thenAnswer((_) async => Success<Task>(buildTask(isDone: true)));
      },
      act: (TasksCubit cubit) async {
        cubit.start();
        final Task task = buildTask();
        controller.add(<Task>[task]);
        await pumpEventQueue();
        await cubit.toggleDone(task);
      },
      verify: (_) {
        verify(
          () => toggleTaskDone(
            id: 1,
            isDone: true,
            now: now,
          ),
        ).called(1);
      },
    );

    blocTest<TasksCubit, TasksState>(
      'deleteTask returns removed task for undo',
      build: buildCubit,
      setUp: () {
        when(() => deleteTask(1)).thenAnswer(
          (_) async => const Success<void>(null),
        );
      },
      act: (TasksCubit cubit) async {
        cubit.start();
        final Task task = buildTask();
        controller.add(<Task>[task]);
        await pumpEventQueue();
        final Task? deleted = await cubit.deleteTask(task);
        expect(deleted, task);
      },
      verify: (_) {
        verify(() => deleteTask(1)).called(1);
      },
    );

    group('quickAdd', () {
      List<NewTask> captured() => verify(
            () => createTask(captureAny(), now: any(named: 'now')),
          ).captured.cast<NewTask>();

      setUp(() {
        when(() => createTask(any(), now: any(named: 'now'))).thenAnswer(
          (_) async => Success<Task>(buildTask()),
        );
      });

      test('reads date, time, category and reminder from the text', () async {
        final TasksCubit cubit = buildCubit();
        final ({int created, String? error}) r = await cubit.quickAdd(
          'Lab report tomorrow 18:00 #work 15 min before',
          defaults: const TaskDefaults(),
        );
        expect(r.created, 1);
        final NewTask task = captured().single;
        expect(task.title, 'Lab report');
        expect(task.dueAt, DateTime(2026, 10, 31, 18));
        expect(task.category, TaskCategory.work);
        expect(task.remindBefore, const Duration(minutes: 15));
        await cubit.close();
      });

      test('every line is its own task, bullets removed', () async {
        final TasksCubit cubit = buildCubit();
        final ({int created, String? error}) r = await cubit.quickAdd(
          '- Milk\n2) Bread today 20:00\n\n',
          defaults: const TaskDefaults(),
        );
        expect(r.created, 2);
        final List<NewTask> tasks = captured();
        expect(tasks.map((NewTask t) => t.title), <String>['Milk', 'Bread']);
        await cubit.close();
      });

      test('uses the chip and the remembered defaults when text is silent',
          () async {
        final TasksCubit cubit = buildCubit();
        await cubit.quickAdd(
          'Stretch',
          time: QuickTimeKind.tomorrowMorning,
          defaults: const TaskDefaults(category: TaskCategory.personal),
        );
        final NewTask task = captured().single;
        expect(task.dueAt, DateTime(2026, 10, 31, 9));
        expect(task.category, TaskCategory.personal);
        expect(task.remindBefore, const Duration(hours: 1));
        await cubit.close();
      });
    });
  });
}
