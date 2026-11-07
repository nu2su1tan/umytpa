import 'package:equatable/equatable.dart';

/// Pure validation for the create/edit form. UI only displays the messages.
abstract final class TaskInputValidator {
  static const int maxTitleLength = 120;

  // Messages are public so the UI can map them to the current language.
  static const String titleRequiredMessage = 'Title is required';
  static const String deadlinePastMessage = 'Deadline must be in the future';
  static const String reminderPassedMessage =
      'Reminder time has already passed. The task will be saved without a notification.';

  static String titleTooLongMessage(int max) =>
      'Title must be at most $max characters';

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
      titleError = titleRequiredMessage;
    } else if (trimmed.length > maxTitleLength) {
      titleError = titleTooLongMessage(maxTitleLength);
    }

    String? dueAtError;
    // Minute precision: the picker has no seconds, so the current minute
    // (e.g. 21:47 at 21:47:30) is still a valid deadline.
    final DateTime currentMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    if (isNew && dueAt.isBefore(currentMinute)) {
      dueAtError = deadlinePastMessage;
    }

    String? reminderWarning;
    if (remindBefore != null) {
      final DateTime remindAt = dueAt.subtract(remindBefore);
      if (!remindAt.isAfter(now)) {
        reminderWarning = reminderPassedMessage;
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
