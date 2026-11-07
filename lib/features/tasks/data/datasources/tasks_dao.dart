import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tasks_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: <Type>[Tasks, FocusSessions])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  Stream<List<TaskRecord>> watchAll() {
    return (select(tasks)..orderBy(<OrderClauseGenerator<Tasks>>[
          (Tasks t) => OrderingTerm.asc(t.dueAt),
        ]))
        .watch();
  }

  Future<TaskRecord?> getById(int id) {
    return (select(tasks)..where((Tasks t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertTask(TasksCompanion companion) {
    return into(tasks).insert(companion);
  }

  Future<bool> replaceTask(TaskRecord record) {
    return update(tasks).replace(record);
  }

  Future<int> deleteById(int id) {
    return (delete(tasks)..where((Tasks t) => t.id.equals(id))).go();
  }

  Future<int> setDone({
    required int id,
    required bool isDone,
    required DateTime now,
  }) {
    return (update(tasks)..where((Tasks t) => t.id.equals(id))).write(
      TasksCompanion(
        isDone: Value<bool>(isDone),
        completedAt: Value<DateTime?>(isDone ? now.toUtc() : null),
      ),
    );
  }

  Future<int> insertFocusSession(FocusSessionsCompanion companion) {
    return into(focusSessions).insert(companion);
  }

  Stream<List<FocusSessionRecord>> watchFocusSessions() {
    return select(focusSessions).watch();
  }
}
