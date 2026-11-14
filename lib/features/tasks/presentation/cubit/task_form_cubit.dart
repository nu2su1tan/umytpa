import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../reminders/domain/reminder_permission_status.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../../data/task_defaults.dart';
import '../../domain/entities/reminder_preset.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/parse_smart_input.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/validation/task_input_validator.dart';
import 'task_form_state.dart';

class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit({
    required this.createTask,
    required this.updateTask,
    required this.deleteTask,
    required this.reminderScheduler,
    this.initialTask,
    this.defaultReminder = ReminderPreset.defaultPreset,
    this.defaultCustomBefore,
    this.defaultCategory = TaskCategory.study,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const TaskFormLoading()) {
    _bootstrap();
  }

  final CreateTask createTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;
  final ReminderScheduler reminderScheduler;
  final Task? initialTask;
  final ReminderPreset defaultReminder;
  final Duration? defaultCustomBefore;
  final TaskCategory defaultCategory;
  final DateTime Function() _now;

  late String _baselineTitle;
  late DateTime _baselineDueAt;
  late TaskCategory _baselineCategory;
  late ReminderPreset _baselineReminder;
  Duration? _baselineCustom;
  RepeatRule _baselineRepeat = RepeatRule.none;
  List<Subtask> _baselineSubtasks = const <Subtask>[];
  bool _permissionPrompted = false;

  bool get isEdit => initialTask != null;

  void _bootstrap() {
    final DateTime now = _now();
    if (initialTask case final Task task) {
      _baselineTitle = task.title;
      _baselineDueAt = task.dueAt;
      _baselineCategory = task.category;
      _baselineReminder = ReminderPreset.fromDuration(task.remindBefore);
      _baselineCustom = _baselineReminder == ReminderPreset.custom
          ? task.remindBefore
          : null;
      _baselineRepeat = task.repeat;
      _baselineSubtasks = task.subtasks;
      emit(
        TaskFormReady(
          title: task.title,
          dueAt: task.dueAt,
          category: task.category,
          reminder: _baselineReminder,
          customBefore: _baselineCustom,
          validation: _validate(
            title: task.title,
            dueAt: task.dueAt,
            reminder: _baselineReminder,
            customOverride: _baselineCustom,
          ),
          repeat: task.repeat,
          subtasks: task.subtasks,
          isEdit: true,
          isDirty: false,
          isSubmitting: false,
          showPermissionHelp: false,
          existingTask: task,
        ),
      );
      return;
    }

    final DateTime dueAt = DateTimeUtils.nextRoundedHour(now);
    _baselineTitle = '';
    _baselineDueAt = dueAt;
    _baselineCategory = defaultCategory;
    _baselineReminder = defaultReminder;
    _baselineCustom = defaultCustomBefore;
    emit(
      TaskFormReady(
        title: '',
        dueAt: dueAt,
        category: defaultCategory,
        reminder: defaultReminder,
        customBefore: defaultCustomBefore,
        validation: _validate(
          title: '',
          dueAt: dueAt,
          reminder: defaultReminder,
          customOverride: defaultCustomBefore,
        ),
        isEdit: false,
        isDirty: false,
        isSubmitting: false,
        showPermissionHelp: false,
      ),
    );
  }

  /// Starts a new task with [title] already typed (text shared from another
  /// app). The recognised date and time are offered right away.
  void prefill(String? title) {
    if (title == null || title.trim().isEmpty || isEdit) {
      return;
    }
    titleChanged(title.trim());
  }

  void titleChanged(String title) {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    emit(
      current.copyWith(
        title: title,
        validation: _validate(
          title: title,
          dueAt: current.dueAt,
          reminder: current.reminder,
        ),
        isDirty: _computeDirty(
          title: title,
          dueAt: current.dueAt,
          category: current.category,
          reminder: current.reminder,
        ),
        smart: () => _smartFor(title),
        submitError: () => null,
      ),
    );
  }

  SmartInput? _smartFor(String title) {
    if (isEdit) {
      return null;
    }
    final SmartInput parsed = SmartInputParser.parse(title, now: _now());
    return parsed.found && parsed.title.isNotEmpty ? parsed : null;
  }

  /// Fills the form from what was recognised in the title.
  void applySmartInput() {
    final TaskFormReady? current = _ready;
    final SmartInput? smart = current?.smart;
    if (current == null || smart == null) {
      return;
    }
    final DateTime base = smart.date ?? current.dueAt;
    final DateTime dueAt = DateTime(
      base.year,
      base.month,
      base.day,
      smart.hour ?? current.dueAt.hour,
      smart.minute ?? current.dueAt.minute,
    );
    final TaskCategory category = smart.category ?? current.category;
    final RepeatRule repeat = smart.repeat ?? current.repeat;
    emit(
      current.copyWith(
        title: smart.title,
        dueAt: dueAt,
        category: category,
        repeat: repeat,
        validation: _validate(
          title: smart.title,
          dueAt: dueAt,
          reminder: current.reminder,
        ),
        isDirty: _computeDirty(
          title: smart.title,
          dueAt: dueAt,
          category: category,
          reminder: current.reminder,
          repeatOverride: repeat,
        ),
        smart: () => null,
        submitError: () => null,
      ),
    );
    final Duration? before = smart.remindBefore;
    if (before != null) {
      unawaited(
        reminderChanged(ReminderPreset.fromDuration(before), custom: before),
      );
    }
  }

  /// A quick-time chip: sets the deadline to [dueAt] in one tap.
  void quickDueAt(DateTime dueAt) {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    _emitDueAt(current, dueAt);
  }

  void categoryChanged(TaskCategory category) {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    emit(
      current.copyWith(
        category: category,
        isDirty: _computeDirty(
          title: current.title,
          dueAt: current.dueAt,
          category: category,
          reminder: current.reminder,
        ),
        submitError: () => null,
      ),
    );
  }

  void dueDateChanged(DateTime date) {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    final DateTime dueAt = DateTime(
      date.year,
      date.month,
      date.day,
      current.dueAt.hour,
      current.dueAt.minute,
    );
    _emitDueAt(current, dueAt);
  }

  void dueTimeChanged(TimeOfDayLike time) {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    final DateTime dueAt = DateTime(
      current.dueAt.year,
      current.dueAt.month,
      current.dueAt.day,
      time.hour,
      time.minute,
    );
    _emitDueAt(current, dueAt);
  }

  void _emitDueAt(TaskFormReady current, DateTime dueAt) {
    emit(
      current.copyWith(
        dueAt: dueAt,
        validation: _validate(
          title: current.title,
          dueAt: dueAt,
          reminder: current.reminder,
        ),
        isDirty: _computeDirty(
          title: current.title,
          dueAt: dueAt,
          category: current.category,
          reminder: current.reminder,
        ),
        submitError: () => null,
      ),
    );
  }

  Future<void> reminderChanged(
    ReminderPreset reminder, {
    Duration? custom,
  }) async {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }

    bool showHelp = current.showPermissionHelp;
    ReminderPermissionRationale? nextRationale;

    if (reminder != ReminderPreset.none && !_permissionPrompted) {
      _permissionPrompted = true;
      final ReminderPermissionStatus notifStatus = await reminderScheduler
          .requestNotificationsPermission();

      if (!notifStatus.isGranted) {
        showHelp = true;
      } else {
        showHelp = false;
        final ReminderPermissionStatus exactStatus = await reminderScheduler
            .checkExactAlarmsPermission();
        if (!exactStatus.isGranted) {
          nextRationale = ReminderPermissionRationale.exactAlarms;
        } else {
          final ReminderPermissionStatus fullStatus = await reminderScheduler
              .checkFullScreenIntentPermission();
          if (!fullStatus.isGranted) {
            nextRationale = ReminderPermissionRationale.fullScreenIntent;
          }
        }
      }
    }

    // The user may have kept typing while permission dialogs were open;
    // build on the latest state so those edits aren't thrown away.
    final TaskFormReady latest = _ready ?? current;
    final Duration? nextCustom = reminder == ReminderPreset.custom
        ? (custom ?? latest.customBefore)
        : null;
    emit(
      latest.copyWith(
        reminder: reminder,
        customBefore: () => nextCustom,
        validation: _validate(
          title: latest.title,
          dueAt: latest.dueAt,
          reminder: reminder,
          customOverride: nextCustom,
        ),
        isDirty: _computeDirty(
          title: latest.title,
          dueAt: latest.dueAt,
          category: latest.category,
          reminder: reminder,
          customOverride: nextCustom,
        ),
        showPermissionHelp: showHelp,
        pendingRationale: () => nextRationale,
        submitError: () => null,
      ),
    );
  }

  Future<void> confirmPermissionRationale(
    ReminderPermissionRationale rationale,
  ) async {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }

    switch (rationale) {
      case ReminderPermissionRationale.exactAlarms:
        await reminderScheduler.requestExactAlarmsPermission();
        final ReminderPermissionStatus fullStatus = await reminderScheduler
            .checkFullScreenIntentPermission();
        final ReminderPermissionRationale? next = !fullStatus.isGranted
            ? ReminderPermissionRationale.fullScreenIntent
            : null;
        emit((_ready ?? current).copyWith(pendingRationale: () => next));
      case ReminderPermissionRationale.fullScreenIntent:
        await reminderScheduler.requestFullScreenIntentPermission();
        emit((_ready ?? current).copyWith(pendingRationale: () => null));
    }
  }

  void dismissPermissionRationale() {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(pendingRationale: () => null));
  }

  Future<void> openSystemSettings() => reminderScheduler.openSystemSettings();

  Future<void> save() async {
    final TaskFormReady? current = _ready;
    if (current == null || !current.canSave) {
      return;
    }

    emit(current.copyWith(isSubmitting: true, submitError: () => null));
    final DateTime now = _now();

    if (current.isEdit) {
      final Task updated = current.existingTask!.copyWith(
        title: current.title.trim(),
        dueAt: current.dueAt,
        category: current.category,
        remindBefore: () => current.remindBefore,
        repeat: current.repeat,
        subtasks: current.subtasks,
      );
      final Result<Task> result = await updateTask(updated, now: now);
      _handleSaveResult(current, result);
      return;
    }

    final Result<Task> result = await createTask(
      NewTask(
        title: current.title.trim(),
        dueAt: current.dueAt,
        category: current.category,
        remindBefore: current.remindBefore,
        repeat: current.repeat,
        subtasks: current.subtasks,
      ),
      now: now,
    );
    _handleSaveResult(current, result);
  }

  void _handleSaveResult(TaskFormReady current, Result<Task> result) {
    switch (result) {
      case Success<Task>():
        if (!current.isEdit) {
          unawaited(
            TaskDefaults.save(
              category: current.category,
              remindBefore: current.remindBefore,
            ),
          );
        }
        emit(const TaskFormSaveSuccess());
      case Err<Task>(:final failure):
        emit(
          current.copyWith(
            isSubmitting: false,
            submitError: () => failure.message,
          ),
        );
    }
  }

  Future<void> delete() async {
    final TaskFormReady? current = _ready;
    final Task? task = current?.existingTask;
    if (current == null || task == null) {
      return;
    }
    emit(current.copyWith(isSubmitting: true, submitError: () => null));
    final Result<void> result = await deleteTask(task.id);
    switch (result) {
      case Success<void>():
        emit(TaskFormDeleteSuccess(task));
      case Err<void>(:final failure):
        emit(
          current.copyWith(
            isSubmitting: false,
            submitError: () => failure.message,
          ),
        );
    }
  }

  TaskInputValidation _validate({
    required String title,
    required DateTime dueAt,
    required ReminderPreset reminder,
    Duration? customOverride,
  }) {
    final Duration? custom = customOverride ?? _ready?.customBefore;
    return TaskInputValidator.validate(
      title: title,
      dueAt: dueAt,
      remindBefore: reminder == ReminderPreset.custom
          ? custom
          : reminder.duration,
      isNew: !isEdit,
      now: _now(),
    );
  }

  bool _computeDirty({
    required String title,
    required DateTime dueAt,
    required TaskCategory category,
    required ReminderPreset reminder,
    RepeatRule? repeatOverride,
    List<Subtask>? subtasksOverride,
    Duration? customOverride,
  }) {
    final TaskFormReady? cur = _ready;
    final Duration? custom = customOverride ?? cur?.customBefore;
    final RepeatRule repeat = repeatOverride ?? cur?.repeat ?? RepeatRule.none;
    final List<Subtask> subtasks =
        subtasksOverride ?? cur?.subtasks ?? const <Subtask>[];
    return title.trim() != _baselineTitle.trim() ||
        dueAt != _baselineDueAt ||
        category != _baselineCategory ||
        reminder != _baselineReminder ||
        (reminder == ReminderPreset.custom && custom != _baselineCustom) ||
        repeat != _baselineRepeat ||
        !_sameSubtasks(subtasks, _baselineSubtasks);
  }

  bool _sameSubtasks(List<Subtask> a, List<Subtask> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  void repeatChanged(RepeatRule repeat) {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    emit(
      current.copyWith(
        repeat: repeat,
        isDirty: _computeDirty(
          title: current.title,
          dueAt: current.dueAt,
          category: current.category,
          reminder: current.reminder,
          repeatOverride: repeat,
        ),
      ),
    );
  }

  void _setSubtasks(List<Subtask> items) {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }
    emit(
      current.copyWith(
        subtasks: items,
        isDirty: _computeDirty(
          title: current.title,
          dueAt: current.dueAt,
          category: current.category,
          reminder: current.reminder,
          subtasksOverride: items,
        ),
      ),
    );
  }

  void subtaskAdded(String title) {
    final String trimmed = title.trim();
    final TaskFormReady? current = _ready;
    if (trimmed.isEmpty || current == null) {
      return;
    }
    _setSubtasks(<Subtask>[...current.subtasks, Subtask(title: trimmed)]);
  }

  void subtaskToggled(int index) {
    final TaskFormReady? current = _ready;
    if (current == null || index < 0 || index >= current.subtasks.length) {
      return;
    }
    final List<Subtask> next = List<Subtask>.of(current.subtasks);
    next[index] = next[index].copyWith(isDone: !next[index].isDone);
    _setSubtasks(next);
  }

  void subtaskRemoved(int index) {
    final TaskFormReady? current = _ready;
    if (current == null || index < 0 || index >= current.subtasks.length) {
      return;
    }
    _setSubtasks(List<Subtask>.of(current.subtasks)..removeAt(index));
  }

  TaskFormReady? get _ready =>
      state is TaskFormReady ? state as TaskFormReady : null;
}

/// Tiny time carrier so Domain/Cubit stay free of Flutter's [TimeOfDay].
final class TimeOfDayLike {
  const TimeOfDayLike({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
