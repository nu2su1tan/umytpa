import 'package:drift/drift.dart';

import '../../domain/entities/task.dart';
import '../datasources/app_database.dart';

abstract final class TaskMapper {
  static Task toDomain(TaskRecord record) {
    return Task(
      id: record.id,
      title: record.title,
      dueAt: record.dueAt.toLocal(),
      category: record.category,
      remindBefore: record.remindBeforeMinutes == null
          ? null
          : Duration(minutes: record.remindBeforeMinutes!),
      isDone: record.isDone,
      createdAt: record.createdAt.toLocal(),
    );
  }

  static TasksCompanion toInsertCompanion(NewTask task, {required DateTime now}) {
    return TasksCompanion.insert(
      title: task.title,
      dueAt: task.dueAt.toUtc(),
      category: task.category,
      remindBeforeMinutes: Value<int?>(task.remindBefore?.inMinutes),
      createdAt: now.toUtc(),
    );
  }

  static TaskRecord toRecord(Task task) {
    return TaskRecord(
      id: task.id,
      title: task.title,
      dueAt: task.dueAt.toUtc(),
      category: task.category,
      remindBeforeMinutes: task.remindBefore?.inMinutes,
      isDone: task.isDone,
      createdAt: task.createdAt.toUtc(),
    );
  }
}
