import 'package:drift/drift.dart';

import '../../domain/entities/task_category.dart';

@DataClassName('TaskRecord')
@TableIndex(name: 'idx_tasks_due_at', columns: {#dueAt})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 120)();

  /// Stored in UTC.
  DateTimeColumn get dueAt => dateTime()();

  /// Enum name (e.g. `study`), not index.
  TextColumn get category => textEnum<TaskCategory>()();

  IntColumn get remindBeforeMinutes => integer().nullable()();

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// Stored in UTC.
  DateTimeColumn get createdAt => dateTime()();

  /// [RepeatRule] enum name.
  TextColumn get repeat => text().withDefault(const Constant('none'))();

  /// JSON list of `{t, d}` checklist items.
  TextColumn get subtasksJson => text().withDefault(const Constant('[]'))();

  /// Stored in UTC; `null` while the task is open.
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// One finished focus (Pomodoro) session.
@DataClassName('FocusSessionRecord')
class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The task worked on, if any (kept after the task is deleted).
  IntColumn get taskId => integer().nullable()();

  /// Stored in UTC.
  DateTimeColumn get startedAt => dateTime()();

  IntColumn get minutes => integer()();
}
