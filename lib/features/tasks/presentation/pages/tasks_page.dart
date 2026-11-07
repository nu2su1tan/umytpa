import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/glass/glass.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_section.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/group_tasks_by_date.dart';
import '../../domain/usecases/toggle_task_done.dart';
import '../../domain/usecases/watch_tasks.dart';
import '../cubit/task_form_result.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_section_view.dart';
import '../widgets/tasks_empty_view.dart';
import '../widgets/tasks_error_view.dart';
import '../widgets/tasks_header.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TasksCubit>(
      create: (_) => TasksCubit(
        watchTasks: getIt<WatchTasks>(),
        toggleTaskDone: getIt<ToggleTaskDone>(),
        deleteTaskUseCase: getIt<DeleteTask>(),
        createTask: getIt<CreateTask>(),
        groupTasksByDate: getIt<GroupTasksByDate>(),
      )..start(),
      child: const _TasksPageBody(),
    );
  }
}

class _TasksPageBody extends StatelessWidget {
  const _TasksPageBody();

  Future<void> _openCreate(BuildContext context) async {
    final TaskFormResult? result = await TaskFormSheet.show(context);
    if (!context.mounted) {
      return;
    }
    await _handleFormResult(context, result);
  }

  Future<void> _openEdit(BuildContext context, Task task) async {
    final TaskFormResult? result = await TaskFormSheet.show(
      context,
      task: task,
    );
    if (!context.mounted) {
      return;
    }
    await _handleFormResult(context, result);
  }

  Future<void> _handleFormResult(
    BuildContext context,
    TaskFormResult? result,
  ) async {
    if (result is TaskFormDeleted) {
      final TasksCubit cubit = context.read<TasksCubit>();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Deleted "${result.task.title}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => cubit.undoDelete(result.task),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TasksView(
      onAddTask: () => _openCreate(context),
      onEditTask: (Task task) => _openEdit(context, task),
    );
  }
}

class TasksView extends StatelessWidget {
  const TasksView({
    this.onAddTask,
    this.onEditTask,
    this.now,
    super.key,
  });

  final VoidCallback? onAddTask;
  final ValueChanged<Task>? onEditTask;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final DateTime current = now ?? DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<TasksCubit, TasksState>(
            builder: (BuildContext context, TasksState state) {
              return switch (state) {
                TasksInitial() || TasksLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                TasksFailure(:final message) => TasksErrorView(
                    message: message,
                    onRetry: () => context.read<TasksCubit>().retry(),
                  ),
                TasksLoaded() => _LoadedBody(
                    state: state,
                    now: current,
                    onAddTask: onAddTask,
                    onEditTask: onEditTask,
                  ),
              };
            },
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<TasksCubit, TasksState>(
        builder: (BuildContext context, TasksState state) {
          final bool hideFab = state is TasksLoaded && state.isGloballyEmpty;
          if (hideFab) {
            return const SizedBox.shrink();
          }
          return AppGlassFab(
            onPressed: onAddTask,
          );
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.now,
    required this.onAddTask,
    required this.onEditTask,
  });

  final TasksLoaded state;
  final DateTime now;
  final VoidCallback? onAddTask;
  final ValueChanged<Task>? onEditTask;

  @override
  Widget build(BuildContext context) {
    if (state.isGloballyEmpty) {
      return TasksEmptyView(onAddTask: onAddTask ?? () {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            16,
            AppTheme.screenPadding,
            0,
          ),
          child: TasksHeader(now: now),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.screenPadding,
          ),
          child: CategoryFilterBar(
            selected: state.selectedCategory,
            onSelected: (TaskCategory? category) {
              context.read<TasksCubit>().selectCategory(category);
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.isFilterEmpty
              ? const TasksFilterEmptyView()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.screenPadding,
                    8,
                    AppTheme.screenPadding,
                    AppGlassTabBar.bottomPaddingOf(context),
                  ),
                  itemCount: state.sections.length,
                  itemBuilder: (BuildContext context, int index) {
                    final TaskSection section = state.sections[index];
                    final bool collapsed =
                        state.collapsedSections.contains(section.kind);
                    return TaskSectionView(
                      section: section,
                      collapsed: collapsed,
                      now: now,
                      onToggleCollapsed: () {
                        context.read<TasksCubit>().toggleSection(section.kind);
                      },
                      onToggleDone: (Task task) {
                        context.read<TasksCubit>().toggleDone(task);
                      },
                      onTapTask: (Task task) => onEditTask?.call(task),
                      onDeleteTask: (Task task) => _onDelete(context, task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _onDelete(BuildContext context, Task task) async {
    final TasksCubit cubit = context.read<TasksCubit>();
    final Task? deleted = await cubit.deleteTask(task);
    if (deleted == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${deleted.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.undoDelete(deleted),
          ),
        ),
      );
  }
}
