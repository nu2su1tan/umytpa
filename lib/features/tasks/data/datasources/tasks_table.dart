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
}
