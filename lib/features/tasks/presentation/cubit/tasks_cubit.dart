import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/task_defaults.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_section.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/group_tasks_by_date.dart';
import '../../domain/usecases/parse_smart_input.dart';
import '../../domain/usecases/quick_times.dart';
import '../../domain/usecases/toggle_task_done.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/watch_tasks.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit({
    required this.watchTasks,
    required this.toggleTaskDone,
    required this.deleteTaskUseCase,
    required this.createTask,
    required this.groupTasksByDate,
    this.updateTask,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const TasksInitial());

  final WatchTasks watchTasks;
  final ToggleTaskDone toggleTaskDone;
  final DeleteTask deleteTaskUseCase;
  final CreateTask createTask;
  final GroupTasksByDate groupTasksByDate;
  final UpdateTask? updateTask;
  final DateTime Function() _now;

  StreamSubscription<List<Task>>? _subscription;
  TaskCategory? _selectedCategory;
  Set<TaskSectionKind> _collapsedSections = <TaskSectionKind>{
    TaskSectionKind.completed,
  };
  List<Task> _allTasks = const <Task>[];
  Timer? _clock;

  void start() {
    if (state is! TasksLoaded) {
      emit(const TasksLoading());
    }
    unawaited(_subscription?.cancel());
    // Tasks turn overdue and "tomorrow" becomes "today" as time passes, even
    // when the data itself doesn't change.
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (state is TasksLoaded) {
        _emitLoaded();
      }
    });
    _subscription = watchTasks().listen(
      _onTasks,
      onError: (Object error, StackTrace stackTrace) {
        emit(TasksFailure(error.toString()));
      },
    );
  }

  void retry() => start();

  void selectCategory(TaskCategory? category) {
    _selectedCategory = category;
    _emitLoaded();
  }

  void toggleSection(TaskSectionKind kind) {
    final Set<TaskSectionKind> next = Set<TaskSectionKind>.of(
      _collapsedSections,
    );
    if (next.contains(kind)) {
      next.remove(kind);
    } else {
      next.add(kind);
    }
    _collapsedSections = next;
    _emitLoaded();
  }

  Future<void> toggleDone(Task task) async {
    final Result<Task> result = await toggleTaskDone(
      id: task.id,
      isDone: !task.isDone,
      now: _now(),
    );
    if (result case Err<Task>(:final failure)) {
      emit(TasksFailure(failure.message));
      _emitLoaded();
    }
  }

  /// Deletes the task. Returns the removed task so the UI can offer Undo.
  Future<Task?> deleteTask(Task task) async {
    final Result<void> result = await deleteTaskUseCase(task.id);
    return result.fold(
      onErr: (failure) {
        emit(TasksFailure(failure.message));
        _emitLoaded();
        return null;
      },
      onSuccess: (_) => task,
    );
  }

  /// Moves every overdue open task to tomorrow, keeping its time of day.
  Future<void> moveOverdueToTomorrow() async {
    final UpdateTask? update = updateTask;
    if (update == null) {
      return;
    }
    final DateTime now = _now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    for (final Task task in _allTasks) {
      final bool today =
          task.dueAt.year == now.year &&
          task.dueAt.month == now.month &&
          task.dueAt.day == now.day;
      if (task.isDone || today || !task.dueAt.isBefore(now)) {
        continue;
      }
      final Result<Task> result = await update(
        task.copyWith(
          dueAt: DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            task.dueAt.hour,
            task.dueAt.minute,
          ),
        ),
        now: now,
      );
      if (result case Err<Task>(:final failure)) {
        emit(TasksFailure(failure.message));
        _emitLoaded();
        return;
      }
    }
  }

  /// Creates tasks from the quick-add line. Every non-empty line is a task,
  /// so a pasted list becomes several. What the text does not say comes from
  /// the chosen [time] chip, then from the last-used defaults.
  /// Returns how many tasks were created and the first error, if any.
  Future<({int created, String? error})> quickAdd(
    String text, {
    QuickTimeKind? time,
    TaskDefaults? defaults,
  }) async {
    final DateTime now = _now();
    final TaskDefaults d = defaults ?? await TaskDefaults.load();
    int created = 0;
    String? error;
    for (final String line in text.split(RegExp(r'[\r\n]+'))) {
      final String raw = line
          .replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+'), '')
          .trim();
      if (raw.isEmpty) {
        continue;
      }
      final SmartInput smart = SmartInputParser.parse(raw, now: now);
      final String title = smart.title.isEmpty ? raw : smart.title;
      final Result<Task> result = await createTask(
        NewTask(
          title: title,
          dueAt: _quickDueAt(smart, time, now),
          category: smart.category ?? d.category,
          remindBefore: smart.remindBefore ?? d.remindBefore,
          repeat: smart.repeat ?? RepeatRule.none,
        ),
        now: now,
      );
      switch (result) {
        case Success<Task>():
          created++;
        case Err<Task>(:final failure):
          error ??= failure.message;
      }
    }
    return (created: created, error: error);
  }

  DateTime _quickDueAt(SmartInput smart, QuickTimeKind? chip, DateTime now) {
    if (smart.hasTime) {
      final DateTime day = smart.date ?? DateTime(now.year, now.month, now.day);
      return DateTime(
        day.year,
        day.month,
        day.day,
        smart.hour!,
        smart.minute ?? 0,
      );
    }
    if (chip != null && smart.date == null) {
      return QuickTimes.resolve(chip, now: now);
    }
    final DateTime? day = smart.date;
    if (day == null || DateTimeUtils.isSameCalendarDay(day, now)) {
      return DateTimeUtils.nextRoundedHour(now);
    }
    // A day with no time: morning.
    return DateTime(day.year, day.month, day.day, 9);
  }

  /// A fresh copy of [task] for tomorrow, same time of day, nothing ticked.
  Future<bool> duplicate(Task task) async {
    final DateTime now = _now();
    final DateTime base = task.dueAt.isAfter(now) ? task.dueAt : now;
    final DateTime day = DateTime(base.year, base.month, base.day + 1);
    final Result<Task> result = await createTask(
      NewTask(
        title: task.title,
        dueAt: DateTime(
          day.year,
          day.month,
          day.day,
          task.dueAt.hour,
          task.dueAt.minute,
        ),
        category: task.category,
        remindBefore: task.remindBefore,
        repeat: task.repeat,
        subtasks: <Subtask>[
          for (final Subtask s in task.subtasks) s.copyWith(isDone: false),
        ],
      ),
      now: now,
    );
    return result is Success<Task>;
  }

  Future<void> undoDelete(Task task) async {
    final Result<Task> result = await createTask(
      NewTask(
        title: task.title,
        dueAt: task.dueAt,
        category: task.category,
        remindBefore: task.remindBefore,
        repeat: task.repeat,
        subtasks: task.subtasks,
      ),
      now: _now(),
      restoring: true,
    );
    switch (result) {
      case Err<Task>(:final failure):
        emit(TasksFailure(failure.message));
        _emitLoaded();
      case Success<Task>(:final value):
        // Keep a finished task finished.
        if (task.isDone) {
          await toggleTaskDone(id: value.id, isDone: true, now: _now());
        }
    }
  }

  void _onTasks(List<Task> tasks) {
    _allTasks = tasks;
    _emitLoaded();
  }

  void _emitLoaded() {
    final List<Task> filtered = _selectedCategory == null
        ? _allTasks
        : _allTasks
              .where((Task t) => t.category == _selectedCategory)
              .toList(growable: false);

    emit(
      TasksLoaded(
        allTasks: _allTasks,
        sections: groupTasksByDate(filtered, now: _now()),
        selectedCategory: _selectedCategory,
        collapsedSections: Set<TaskSectionKind>.of(_collapsedSections),
      ),
    );
  }

  @override
  Future<void> close() async {
    _clock?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}
