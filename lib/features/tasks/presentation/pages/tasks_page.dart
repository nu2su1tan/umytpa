import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/copy/profile_controller.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/glass/glass.dart';
import '../../../../core/ui/language_sheet.dart';
import '../../../../core/ui/profile_sheet.dart';
import '../../../week_counter/ui/kit/app_page.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_section.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/group_tasks_by_date.dart';
import '../../domain/usecases/quick_times.dart';
import '../../domain/usecases/toggle_task_done.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/watch_tasks.dart';
import '../../../reminders/data/local_reminder_scheduler.dart';
import '../../../reminders/domain/usecases/reschedule_all_reminders.dart';
import '../../data/external_entry.dart';
import '../../data/task_widget_sync.dart';
import '../widgets/quick_add_bar.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/task_stats.dart';
import '../../domain/usecases/today_progress.dart';
import '../cubit/stats_cubit.dart';
import '../cubit/task_form_result.dart';
import '../utils/task_l10n.dart';
import '../widgets/today_card.dart';
import 'focus_screen.dart';
import 'stats_screen.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_section_view.dart';
import '../widgets/tasks_error_view.dart';
import '../widgets/tasks_header.dart';
import '../widgets/tasks_empty_view.dart';
import '../../../../l10n/app_localizations.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with WidgetsBindingObserver {
  late final TasksCubit _cubit = TasksCubit(
    watchTasks: getIt<WatchTasks>(),
    toggleTaskDone: getIt<ToggleTaskDone>(),
    deleteTaskUseCase: getIt<DeleteTask>(),
    createTask: getIt<CreateTask>(),
    groupTasksByDate: getIt<GroupTasksByDate>(),
    updateTask: getIt<UpdateTask>(),
  )..start();
  late final StatsCubit _stats = StatsCubit(
    repository: getIt<TaskRepository>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ExternalEntries.pending.addListener(_onExternalEntry);
    // Meet the user once: ask what to call them and how to talk.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ExternalEntries.start(
          newTaskLabel: context.l10n.addTask,
        ).then((_) => _onExternalEntry()),
      );
      final ProfileController profile = getIt<ProfileController>();
      if (mounted && !profile.asked) {
        unawaited(profile.markAsked());
        unawaited(showProfileSheet(context, welcome: true));
      }
    });
  }

  @override
  void dispose() {
    ExternalEntries.pending.removeListener(_onExternalEntry);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cubit.close());
    unawaited(_stats.close());
    super.dispose();
  }

  /// A shortcut, the share sheet, Siri or the widget asked to add a task.
  Future<void> _onExternalEntry() async {
    if (!mounted || ExternalEntries.pending.value == null) {
      return;
    }
    final ExternalEntry entry = ExternalEntries.consume()!;
    switch (entry.kind) {
      case EntryKind.newTask:
        await TaskFormSheet.show(context);
      case EntryKind.share:
        await TaskFormSheet.show(context, initialTitle: entry.text);
      case EntryKind.add:
        final ({int created, String? error}) r = await _cubit.quickAdd(
          entry.text!,
        );
        if (!mounted || r.created == 0) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(entry.text!)));
    }
  }

  /// Back in the app: the repeating iOS alarm has done its job.
  Future<void> _stopRinging() async {
    if (await getIt<LocalReminderScheduler>().stopRinging()) {
      await getIt<RescheduleAllReminders>()();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A notification button ("Done") may have changed tasks from a background
    // isolate, which this database connection can't see on its own.
    if (state == AppLifecycleState.resumed) {
      unawaited(ExternalEntries.pull());
      unawaited(_stopRinging());
      _cubit.start();
      _stats.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<TasksCubit>.value(value: _cubit),
        BlocProvider<StatsCubit>.value(value: _stats),
      ],
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
            content: Text(context.l10n.taskDeleted(result.task.title)),
            action: SnackBarAction(
              label: context.l10n.undo,
              onPressed: () => cubit.undoDelete(result.task),
            ),
          ),
        );
    }
  }

  /// Mirrors today's summary onto the home-screen widget.
  void _syncWidget(BuildContext context, TasksLoaded state) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final TodayProgress p = TodayProgress.of(state.allTasks, now: now);
    unawaited(
      TaskWidgetSync.push(
        title: l10n.widgetToday,
        count: '${p.done}/${p.total}',
        next:
            p.next?.title ??
            (p.allDone ? l10n.widgetAllDone : l10n.widgetNothingNext),
        nextTime: p.next == null ? '' : l10n.dueLabel(p.next!.dueAt, now: now),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TasksCubit, TasksState>(
      listenWhen: (TasksState a, TasksState b) =>
          b is TasksLoaded && (a is! TasksLoaded || a.allTasks != b.allTasks),
      listener: (BuildContext context, TasksState state) {
        if (state is TasksLoaded) {
          _syncWidget(context, state);
        }
      },
      child: TasksView(
        onAddTask: () => _openCreate(context),
        onEditTask: (Task task) => _openEdit(context, task),
      ),
    );
  }
}

class TasksView extends StatelessWidget {
  const TasksView({this.onAddTask, this.onEditTask, this.now, super.key});

  final VoidCallback? onAddTask;
  final ValueChanged<Task>? onEditTask;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final DateTime current = now ?? DateTime.now();

    return Scaffold(
      backgroundColor: context.tokens.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: BlocBuilder<TasksCubit, TasksState>(
              builder: (BuildContext context, TasksState state) {
                return switch (state) {
                  TasksInitial() || TasksLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  TasksFailure(:final message) => SafeArea(
                    child: TasksErrorView(
                      message: message,
                      onRetry: () => context.read<TasksCubit>().retry(),
                    ),
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
          Positioned.fill(child: _FabLayer(onAddTask: onAddTask)),
        ],
      ),
    );
  }
}

/// The add button, floating just above the tab bar at the bottom right.
class _FabLayer extends StatelessWidget {
  const _FabLayer({required this.onAddTask});

  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    // The enclosing Scaffold already pads for the tab bar; measure from the
    // raw safe area so the bar's height isn't counted twice.
    final MediaQueryData media = MediaQuery.of(context);
    final MediaQueryData raw = media.copyWith(
      padding: media.padding.copyWith(bottom: media.viewPadding.bottom),
    );

    return MediaQuery(
      data: raw,
      child: Builder(
        builder: (BuildContext context) {
          return Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: AppTheme.screenPadding + 4,
                bottom: AppGlassTabBar.bottomPaddingOf(context) + 12,
              ),
              child: BlocBuilder<TasksCubit, TasksState>(
                builder: (BuildContext context, TasksState state) {
                  return AppGlassFab(
                    onPressed: onAddTask,
                    tooltip: context.l10n.addTask,
                  );
                },
              ),
            ),
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
    return AppPage(
      largeTitle: false,
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ProfileButton(),
          SizedBox(width: 8),
          LanguageButton(),
        ],
      ),
      bottomPadding: AppGlassTabBar.bottomPaddingOf(context),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            8,
            AppTheme.screenPadding,
            0,
          ),
          child: TasksHeader(now: now),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.screenPadding,
          ),
          child: QuickAddBar(
            onSubmit: (String text, QuickTimeKind? time) =>
                context.read<TasksCubit>().quickAdd(text, time: time),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.screenPadding,
          ),
          child: BlocBuilder<StatsCubit, TaskStats>(
            builder: (BuildContext context, TaskStats stats) {
              return TodayCard(
                progress: TodayProgress.of(state.allTasks, now: now),
                stats: stats,
                onOpenStats: () => StatsScreen.open(context),
                onStartFocus: () => FocusScreen.open(context),
              );
            },
          ),
        ),
        if (now.weekday == DateTime.sunday)
          BlocBuilder<StatsCubit, TaskStats>(
            builder: (BuildContext context, TaskStats stats) {
              if (stats.doneThisWeek == 0 && stats.donePrevWeek == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPadding,
                  0,
                  AppTheme.screenPadding,
                  16,
                ),
                child: _NoteCard(
                  icon: Icons.insights_rounded,
                  title: context.l10n.recapTitle,
                  body: context.copy.recap(
                    count: stats.doneThisWeek,
                    previous: stats.donePrevWeek,
                  ),
                ),
              );
            },
          ),
        if (TodayProgress.of(state.allTasks, now: now).overdue >= 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPadding,
              0,
              AppTheme.screenPadding,
              16,
            ),
            child: _NoteCard(
              icon: Icons.local_fire_department_rounded,
              body: context.copy.rescueText(
                TodayProgress.of(state.allTasks, now: now).overdue,
              ),
              actionLabel: context.copy.rescueAction,
              onAction: () =>
                  unawaited(context.read<TasksCubit>().moveOverdueToTomorrow()),
            ),
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
        if (state.isGloballyEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: TasksEmptyView(),
          )
        else if (state.isFilterEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: TasksFilterEmptyView(),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPadding,
              0,
              AppTheme.screenPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final TaskSection section in state.sections)
                  TaskSectionView(
                    section: section,
                    collapsed: state.collapsedSections.contains(section.kind),
                    now: now,
                    onToggleCollapsed: () {
                      context.read<TasksCubit>().toggleSection(section.kind);
                    },
                    onToggleDone: (Task task) {
                      if (!task.isDone) {
                        _cheer(context, task);
                      }
                      context.read<TasksCubit>().toggleDone(task);
                    },
                    onTapTask: (Task task) => onEditTask?.call(task),
                    onDeleteTask: (Task task) => _onDelete(context, task),
                    onFocusTask: (Task task) =>
                        FocusScreen.open(context, task: task),
                    onDuplicateTask: (Task task) => _onDuplicate(context, task),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// A short pat on the back; a bigger one for the last task of the day.
  void _cheer(BuildContext context, Task done) {
    final TodayProgress p = TodayProgress.of(state.allTasks, now: now);
    final bool counted =
        DateTimeUtils.isSameCalendarDay(done.dueAt, now) ||
        done.dueAt.isBefore(now);
    final bool last = counted && p.left == 1;
    final String text = context.copy.cheer(
      name: context.profile.name,
      last: last,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  Future<void> _onDuplicate(BuildContext context, Task task) async {
    final bool ok = await context.read<TasksCubit>().duplicate(task);
    if (!ok || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.taskDuplicated)));
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
          content: Text(context.l10n.taskDeleted(deleted.title)),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => cubit.undoDelete(deleted),
          ),
        ),
      );
  }
}

/// A soft card for a recap or a nudge, with an optional action.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.icon,
    required this.body,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String? title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.violetSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: t.violetInk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null)
                  Text(
                    title!,
                    style: t.callout.copyWith(
                      fontWeight: FontWeight.w700,
                      color: t.violetInk,
                    ),
                  ),
                Text(body, style: t.callout.copyWith(color: t.ink)),
                if (actionLabel != null) ...<Widget>[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: t.callout.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.violetInk,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
