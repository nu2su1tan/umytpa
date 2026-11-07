import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../reminders/domain/reminder_permission_status.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../../domain/entities/reminder_preset.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/usecases/create_task.dart';
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
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const TaskFormLoading()) {
    _bootstrap();
  }

  final CreateTask createTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;
  final ReminderScheduler reminderScheduler;
  final Task? initialTask;
  final ReminderPreset defaultReminder;
  final DateTime Function() _now;

  late String _baselineTitle;
  late DateTime _baselineDueAt;
  late TaskCategory _baselineCategory;
  late ReminderPreset _baselineReminder;
  bool _permissionPrompted = false;

  bool get isEdit => initialTask != null;

  void _bootstrap() {
    final DateTime now = _now();
    if (initialTask case final Task task) {
      _baselineTitle = task.title;
      _baselineDueAt = task.dueAt;
      _baselineCategory = task.category;
      _baselineReminder = ReminderPreset.fromDuration(task.remindBefore);
      emit(
        TaskFormReady(
          title: task.title,
          dueAt: task.dueAt,
          category: task.category,
          reminder: _baselineReminder,
          validation: _validate(
            title: task.title,
            dueAt: task.dueAt,
            reminder: _baselineReminder,
          ),
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
    _baselineCategory = TaskCategory.study;
    _baselineReminder = defaultReminder;
    emit(
      TaskFormReady(
        title: '',
        dueAt: dueAt,
        category: TaskCategory.study,
        reminder: defaultReminder,
        validation: _validate(
          title: '',
          dueAt: dueAt,
          reminder: defaultReminder,
        ),
        isEdit: false,
        isDirty: false,
        isSubmitting: false,
        showPermissionHelp: false,
      ),
    );
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
        submitError: () => null,
      ),
    );
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

  Future<void> reminderChanged(ReminderPreset reminder) async {
    final TaskFormReady? current = _ready;
    if (current == null) {
      return;
    }

    bool showHelp = current.showPermissionHelp;
    ReminderPermissionRationale? nextRationale;

    if (reminder != ReminderPreset.none && !_permissionPrompted) {
      _permissionPrompted = true;
      final ReminderPermissionStatus notifStatus =
          await reminderScheduler.requestNotificationsPermission();

      if (!notifStatus.isGranted) {
        showHelp = true;
      } else {
        showHelp = false;
        final ReminderPermissionStatus exactStatus =
            await reminderScheduler.checkExactAlarmsPermission();
        if (!exactStatus.isGranted) {
          nextRationale = ReminderPermissionRationale.exactAlarms;
        } else {
          final ReminderPermissionStatus fullStatus =
              await reminderScheduler.checkFullScreenIntentPermission();
          if (!fullStatus.isGranted) {
            nextRationale = ReminderPermissionRationale.fullScreenIntent;
          }
        }
      }
    }

    emit(
      current.copyWith(
        reminder: reminder,
        validation: _validate(
          title: current.title,
          dueAt: current.dueAt,
          reminder: reminder,
        ),
        isDirty: _computeDirty(
          title: current.title,
          dueAt: current.dueAt,
          category: current.category,
          reminder: reminder,
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
        final ReminderPermissionStatus fullStatus =
            await reminderScheduler.checkFullScreenIntentPermission();
        final ReminderPermissionRationale? next = !fullStatus.isGranted
            ? ReminderPermissionRationale.fullScreenIntent
            : null;
        emit(current.copyWith(pendingRationale: () => next));
      case ReminderPermissionRationale.fullScreenIntent:
        await reminderScheduler.requestFullScreenIntentPermission();
        emit(current.copyWith(pendingRationale: () => null));
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
        remindBefore: () => current.reminder.duration,
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
        remindBefore: current.reminder.duration,
      ),
      now: now,
    );
    _handleSaveResult(current, result);
  }

  void _handleSaveResult(TaskFormReady current, Result<Task> result) {
    switch (result) {
      case Success<Task>():
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
  }) {
    return TaskInputValidator.validate(
      title: title,
      dueAt: dueAt,
      remindBefore: reminder.duration,
      isNew: !isEdit,
      now: _now(),
    );
  }

  bool _computeDirty({
    required String title,
    required DateTime dueAt,
    required TaskCategory category,
    required ReminderPreset reminder,
  }) {
    return title.trim() != _baselineTitle.trim() ||
        dueAt != _baselineDueAt ||
        category != _baselineCategory ||
        reminder != _baselineReminder;
  }

  TaskFormReady? get _ready => state is TaskFormReady ? state as TaskFormReady : null;
}

/// Tiny time carrier so Domain/Cubit stay free of Flutter's [TimeOfDay].
final class TimeOfDayLike {
  const TimeOfDayLike({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
