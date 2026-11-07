import 'package:equatable/equatable.dart';

/// Pure validation for the create/edit form. UI only displays the messages.
abstract final class TaskInputValidator {
  static const int maxTitleLength = 120;

  static TaskInputValidation validate({
    required String title,
    required DateTime dueAt,
    required Duration? remindBefore,
    required bool isNew,
    required DateTime now,
  }) {
    final String trimmed = title.trim();

    String? titleError;
    if (trimmed.isEmpty) {
      titleError = 'Title is required';
    } else if (trimmed.length > maxTitleLength) {
      titleError = 'Title must be at most $maxTitleLength characters';
    }

    String? dueAtError;
    if (isNew && !dueAt.isAfter(now)) {
      dueAtError = 'Deadline must be in the future';
    }

    String? reminderWarning;
    if (remindBefore != null) {
      final DateTime remindAt = dueAt.subtract(remindBefore);
      if (!remindAt.isAfter(now)) {
        reminderWarning =
            'Reminder time has already passed. The task will be saved without a notification.';
      }
    }

    return TaskInputValidation(
      titleError: titleError,
      dueAtError: dueAtError,
      reminderWarning: reminderWarning,
    );
  }
}

final class TaskInputValidation extends Equatable {
  const TaskInputValidation({
    this.titleError,
    this.dueAtError,
    this.reminderWarning,
  });

  final String? titleError;
  final String? dueAtError;
  final String? reminderWarning;

  bool get isValid => titleError == null && dueAtError == null;

  bool get hasReminderWarning => reminderWarning != null;

  @override
  List<Object?> get props =>
      <Object?>[titleError, dueAtError, reminderWarning];
}
