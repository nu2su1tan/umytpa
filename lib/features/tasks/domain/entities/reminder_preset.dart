/// Reminder offset options shown in the form (matches the design).
enum ReminderPreset {
  none,
  fiveMinutes,
  thirtyMinutes,
  oneHour,
  oneDay,

  /// Any other offset, kept next to the choice (see the form state).
  custom;

  /// Offset before [Task.dueAt]. `null` means no reminder.
  Duration? get duration => switch (this) {
        ReminderPreset.none => null,
        ReminderPreset.fiveMinutes => const Duration(minutes: 5),
        ReminderPreset.thirtyMinutes => const Duration(minutes: 30),
        ReminderPreset.oneHour => const Duration(hours: 1),
        ReminderPreset.oneDay => const Duration(days: 1),
        ReminderPreset.custom => null,
      };

  String get label => switch (this) {
        ReminderPreset.none => 'None',
        ReminderPreset.fiveMinutes => '5 min',
        ReminderPreset.thirtyMinutes => '30 min',
        ReminderPreset.oneHour => '1 hour',
        ReminderPreset.oneDay => '1 day',
        ReminderPreset.custom => 'Custom',
      };

  /// Default for a new task when settings are unavailable.
  static const ReminderPreset defaultPreset = ReminderPreset.oneHour;

  /// Resolves a stored duration back to a preset. Other values → [custom].
  static ReminderPreset fromDuration(Duration? duration) {
    if (duration == null) {
      return ReminderPreset.none;
    }
    for (final ReminderPreset preset in ReminderPreset.values) {
      if (preset.duration == duration) {
        return preset;
      }
    }
    return ReminderPreset.custom;
  }
}
