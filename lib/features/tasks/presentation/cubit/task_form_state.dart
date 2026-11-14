import 'package:equatable/equatable.dart';

import '../../../reminders/domain/reminder_permission_status.dart';
import '../../domain/entities/reminder_preset.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/parse_smart_input.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/validation/task_input_validator.dart';

sealed class TaskFormState extends Equatable {
  const TaskFormState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class TaskFormLoading extends TaskFormState {
  const TaskFormLoading();
}

final class TaskFormReady extends TaskFormState {
  const TaskFormReady({
    required this.title,
    required this.dueAt,
    required this.category,
    required this.reminder,
    required this.validation,
    required this.isEdit,
    required this.isDirty,
    required this.isSubmitting,
    required this.showPermissionHelp,
    this.customBefore,
    this.repeat = RepeatRule.none,
    this.subtasks = const <Subtask>[],
    this.smart,
    this.existingTask,
    this.submitError,
    this.pendingRationale,
  });

  final String title;
  final DateTime dueAt;
  final TaskCategory category;
  final ReminderPreset reminder;
  final TaskInputValidation validation;
  final bool isEdit;
  final bool isDirty;
  final bool isSubmitting;
  final bool showPermissionHelp;

  /// The offset when [reminder] is [ReminderPreset.custom].
  final Duration? customBefore;
  final RepeatRule repeat;
  final List<Subtask> subtasks;

  /// Dates/categories recognised in the title, offered as a one-tap apply.
  final SmartInput? smart;
  final Task? existingTask;
  final String? submitError;
  final ReminderPermissionRationale? pendingRationale;

  /// The reminder offset actually chosen, whichever way.
  Duration? get remindBefore =>
      reminder == ReminderPreset.custom ? customBefore : reminder.duration;

  bool get canSave => validation.isValid && !isSubmitting;

  TaskFormReady copyWith({
    String? title,
    DateTime? dueAt,
    TaskCategory? category,
    ReminderPreset? reminder,
    TaskInputValidation? validation,
    bool? isDirty,
    bool? isSubmitting,
    bool? showPermissionHelp,
    Duration? Function()? customBefore,
    RepeatRule? repeat,
    List<Subtask>? subtasks,
    SmartInput? Function()? smart,
    String? Function()? submitError,
    ReminderPermissionRationale? Function()? pendingRationale,
  }) {
    return TaskFormReady(
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      category: category ?? this.category,
      reminder: reminder ?? this.reminder,
      validation: validation ?? this.validation,
      isEdit: isEdit,
      isDirty: isDirty ?? this.isDirty,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showPermissionHelp: showPermissionHelp ?? this.showPermissionHelp,
      customBefore: customBefore != null ? customBefore() : this.customBefore,
      repeat: repeat ?? this.repeat,
      subtasks: subtasks ?? this.subtasks,
      smart: smart != null ? smart() : this.smart,
      existingTask: existingTask,
      submitError: submitError != null ? submitError() : this.submitError,
      pendingRationale: pendingRationale != null
          ? pendingRationale()
          : this.pendingRationale,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    title,
    dueAt,
    category,
    reminder,
    customBefore,
    validation,
    isEdit,
    isDirty,
    isSubmitting,
    showPermissionHelp,
    repeat,
    subtasks,
    smart,
    existingTask,
    submitError,
    pendingRationale,
  ];
}

final class TaskFormLoadFailure extends TaskFormState {
  const TaskFormLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Terminal states consumed by the sheet to pop with a [TaskFormResult].
sealed class TaskFormEffect extends TaskFormState {
  const TaskFormEffect();
}

final class TaskFormSaveSuccess extends TaskFormEffect {
  const TaskFormSaveSuccess();
}

final class TaskFormDeleteSuccess extends TaskFormEffect {
  const TaskFormDeleteSuccess(this.task);

  final Task task;

  @override
  List<Object?> get props => <Object?>[task];
}
