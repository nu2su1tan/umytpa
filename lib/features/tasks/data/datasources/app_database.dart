import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/task_category.dart';
import 'tasks_dao.dart';
import 'tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: <Type>[Tasks, FocusSessions], daos: <Type>[TasksDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.repeat);
        await m.addColumn(tasks, tasks.subtasksJson);
        await m.addColumn(tasks, tasks.completedAt);
        await m.createTable(focusSessions);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'task_tracker',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
