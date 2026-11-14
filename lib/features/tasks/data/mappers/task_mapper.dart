import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/repeat_rule.dart';
import '../../domain/entities/subtask.dart';
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
      repeat: RepeatRule.values.firstWhere(
        (RepeatRule r) => r.name == record.repeat,
        orElse: () => RepeatRule.none,
      ),
      subtasks: decodeSubtasks(record.subtasksJson),
      completedAt: record.completedAt?.toLocal(),
    );
  }

  static List<Subtask> decodeSubtasks(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List<Object?>) {
        return decoded
            .whereType<Map<String, Object?>>()
            .map(Subtask.fromJson)
            .toList(growable: false);
      }
    } on FormatException {
      // Fall through to an empty checklist.
    }
    return const <Subtask>[];
  }

  static String encodeSubtasks(List<Subtask> items) =>
      jsonEncode(items.map((Subtask s) => s.toJson()).toList());

  static TasksCompanion toInsertCompanion(
    NewTask task, {
    required DateTime now,
  }) {
    return TasksCompanion.insert(
      title: task.title,
      dueAt: task.dueAt.toUtc(),
      category: task.category,
      remindBeforeMinutes: Value<int?>(task.remindBefore?.inMinutes),
      createdAt: now.toUtc(),
      repeat: Value<String>(task.repeat.name),
      subtasksJson: Value<String>(encodeSubtasks(task.subtasks)),
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
      repeat: task.repeat.name,
      subtasksJson: encodeSubtasks(task.subtasks),
      completedAt: task.completedAt?.toUtc(),
    );
  }
}
