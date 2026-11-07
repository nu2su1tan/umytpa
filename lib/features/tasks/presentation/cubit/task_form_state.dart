import 'package:equatable/equatable.dart';

import '../../../reminders/domain/reminder_permission_status.dart';
import '../../domain/entities/reminder_preset.dart';
import '../../domain/entities/task.dart';
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
  final Task? existingTask;
  final String? submitError;
  final ReminderPermissionRationale? pendingRationale;

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
        validation,
        isEdit,
        isDirty,
        isSubmitting,
        showPermissionHelp,
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
