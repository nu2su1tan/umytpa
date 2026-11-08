import 'package:intl/intl.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/reminder_preset.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_section.dart';
import '../../domain/validation/task_input_validator.dart';

/// Translations of the tracker's domain values. The domain keeps its English
/// labels; the UI shows these.
// Building a DateFormat parses its pattern; the list asks for the same two
// formats once per row on every rebuild, so keep them.
final Map<String, DateFormat> _hmCache = <String, DateFormat>{};
final Map<String, DateFormat> _dayMonthCache = <String, DateFormat>{};

DateFormat _hm(String locale) =>
    _hmCache.putIfAbsent(locale, () => DateFormat.Hm(locale));

DateFormat _dayMonth(String locale) =>
    _dayMonthCache.putIfAbsent(locale, () => DateFormat('d MMM', locale));

extension TaskL10n on AppLocalizations {
  String categoryLabel(TaskCategory category) => switch (category) {
        TaskCategory.study => categoryStudy,
        TaskCategory.work => categoryWork,
        TaskCategory.personal => categoryPersonal,
        TaskCategory.other => categoryOther,
      };

  String sectionTitle(TaskSectionKind kind) => switch (kind) {
        TaskSectionKind.overdue => sectionOverdue,
        TaskSectionKind.today => sectionToday,
        TaskSectionKind.tomorrow => sectionTomorrow,
        TaskSectionKind.later => sectionLater,
        TaskSectionKind.completed => sectionCompleted,
      };

  String presetLabel(ReminderPreset preset) => switch (preset) {
        ReminderPreset.none => reminderPresetNone,
        ReminderPreset.fiveMinutes => reminderPreset5m,
        ReminderPreset.thirtyMinutes => reminderPreset30m,
        ReminderPreset.oneHour => reminderPreset1h,
        ReminderPreset.oneDay => reminderPreset1d,
        ReminderPreset.custom => reminderCustom,
      };

  String repeatName(RepeatRule rule) => switch (rule) {
        RepeatRule.none => repeatNone,
        RepeatRule.daily => repeatDaily,
        RepeatRule.weekdays => repeatWeekdays,
        RepeatRule.weekly => repeatWeekly,
      };

  String greeting(DateTime now) {
    if (now.hour < 12) {
      return greetingMorning;
    }
    if (now.hour < 17) {
      return greetingAfternoon;
    }
    return greetingEvening;
  }

  /// "1h before", "за 30 мин"…; `null` when there is no reminder.
  String? reminderBefore(Duration? remindBefore) {
    if (remindBefore == null) {
      return null;
    }
    final int minutes = remindBefore.inMinutes;
    if (minutes > 0 && minutes % 1440 == 0) {
      return reminderBeforeDays(minutes ~/ 1440);
    }
    if (minutes > 0 && minutes % 60 == 0) {
      return reminderBeforeHours(minutes ~/ 60);
    }
    return reminderBeforeMinutes(minutes);
  }

  String dueLabel(DateTime dueAt, {required DateTime now}) {
    final DateTime local = dueAt.toLocal();
    final String time = _hm(localeName).format(local);

    if (DateTimeUtils.isSameCalendarDay(local, now)) {
      return time;
    }
    final DateTime yesterday =
        DateTimeUtils.startOfDay(now).subtract(const Duration(days: 1));
    if (DateTimeUtils.isSameCalendarDay(local, yesterday)) {
      return dueYesterday(time);
    }
    if (DateTimeUtils.isSameCalendarDay(
      local,
      DateTimeUtils.startOfTomorrow(now),
    )) {
      return dueTomorrow(time);
    }
    return dueOnDate(_dayMonth(localeName).format(local), time);
  }

  /// Translates a message produced by the domain (validation, use cases).
  /// Anything else is technical (database, missing row, a raw exception), so
  /// the user gets the generic localized error instead of English internals.
  String domainMessage(String message) {
    if (message == TaskInputValidator.titleRequiredMessage) {
      return errTitleRequired;
    }
    if (message ==
        TaskInputValidator.titleTooLongMessage(
          TaskInputValidator.maxTitleLength,
        )) {
      return errTitleTooLong(TaskInputValidator.maxTitleLength);
    }
    if (message == TaskInputValidator.deadlinePastMessage) {
      return errDeadlinePast;
    }
    if (message == TaskInputValidator.reminderPassedMessage) {
      return warnReminderPassed;
    }
    if (message == 'Invalid input') {
      return errInvalidInput;
    }
    return errorTitle;
  }
}
