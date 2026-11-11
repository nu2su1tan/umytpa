import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/reminder_preset.dart';
import '../domain/entities/task_category.dart';

/// What a new task starts with: the category and reminder the user chose last
/// time, so the common case needs no taps at all.
class TaskDefaults {
  const TaskDefaults({
    this.category = TaskCategory.study,
    this.reminder = ReminderPreset.defaultPreset,
    this.customBefore,
  });

  final TaskCategory category;
  final ReminderPreset reminder;
  final Duration? customBefore;

  /// The reminder offset to put on a task; `null` means no reminder.
  Duration? get remindBefore =>
      reminder == ReminderPreset.custom ? customBefore : reminder.duration;

  static const String _categoryKey = 'default_category';
  static const String _reminderKey = 'default_reminder_minutes';

  static Future<TaskDefaults> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString(_categoryKey);
      final TaskCategory category = TaskCategory.values.firstWhere(
        (TaskCategory c) => c.name == name,
        orElse: () => TaskCategory.study,
      );
      if (!prefs.containsKey(_reminderKey)) {
        return TaskDefaults(category: category);
      }
      final int minutes = prefs.getInt(_reminderKey) ?? -1;
      final Duration? before =
          minutes < 0 ? null : Duration(minutes: minutes);
      final ReminderPreset preset = ReminderPreset.fromDuration(before);
      return TaskDefaults(
        category: category,
        reminder: preset,
        customBefore: preset == ReminderPreset.custom ? before : null,
      );
    } on Object {
      return const TaskDefaults();
    }
  }

  static Future<void> save({
    required TaskCategory category,
    required Duration? remindBefore,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_categoryKey, category.name);
      await prefs.setInt(_reminderKey, remindBefore?.inMinutes ?? -1);
    } on Object {
      // Remembering is a convenience; never fail a save over it.
    }
  }
}
