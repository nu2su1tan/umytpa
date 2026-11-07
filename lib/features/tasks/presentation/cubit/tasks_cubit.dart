import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_section.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/group_tasks_by_date.dart';
import '../../domain/usecases/toggle_task_done.dart';
import '../../domain/usecases/watch_tasks.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit({
    required this.watchTasks,
    required this.toggleTaskDone,
    required this.deleteTaskUseCase,
    required this.createTask,
    required this.groupTasksByDate,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const TasksInitial());

  final WatchTasks watchTasks;
  final ToggleTaskDone toggleTaskDone;
  final DeleteTask deleteTaskUseCase;
  final CreateTask createTask;
  final GroupTasksByDate groupTasksByDate;
  final DateTime Function() _now;

  StreamSubscription<List<Task>>? _subscription;
  TaskCategory? _selectedCategory;
  Set<TaskSectionKind> _collapsedSections = <TaskSectionKind>{
    TaskSectionKind.completed,
  };
  List<Task> _allTasks = const <Task>[];

  void start() {
    emit(const TasksLoading());
    unawaited(_subscription?.cancel());
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
    final Set<TaskSectionKind> next =
        Set<TaskSectionKind>.of(_collapsedSections);
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

  Future<void> undoDelete(Task task) async {
    final Result<Task> result = await createTask(
      NewTask(
        title: task.title,
        dueAt: task.dueAt,
        category: task.category,
        remindBefore: task.remindBefore,
      ),
      now: _now(),
    );
    if (result case Err<Task>(:final failure)) {
      emit(TasksFailure(failure.message));
      _emitLoaded();
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
    await _subscription?.cancel();
    return super.close();
  }
}
