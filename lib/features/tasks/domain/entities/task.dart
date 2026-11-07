import 'package:equatable/equatable.dart';

import 'repeat_rule.dart';
import 'subtask.dart';
import 'task_category.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.category,
    required this.remindBefore,
    required this.isDone,
    required this.createdAt,
    this.repeat = RepeatRule.none,
    this.subtasks = const <Subtask>[],
    this.completedAt,
  });

  final int id;
  final String title;
  final DateTime dueAt;
  final TaskCategory category;

  /// Offset before [dueAt]. `null` = no reminder. Do not store [remindAt].
  final Duration? remindBefore;
  final bool isDone;
  final DateTime createdAt;
  final RepeatRule repeat;
  final List<Subtask> subtasks;

  /// When the task was last marked done; `null` while open.
  final DateTime? completedAt;

  int get subtasksDone => subtasks.where((Subtask s) => s.isDone).length;

  DateTime? get remindAt =>
      remindBefore == null ? null : dueAt.subtract(remindBefore!);

  Task copyWith({
    int? id,
    String? title,
    DateTime? dueAt,
    TaskCategory? category,
    Duration? Function()? remindBefore,
    bool? isDone,
    DateTime? createdAt,
    RepeatRule? repeat,
    List<Subtask>? subtasks,
    DateTime? Function()? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      category: category ?? this.category,
      remindBefore:
          remindBefore != null ? remindBefore() : this.remindBefore,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      repeat: repeat ?? this.repeat,
      subtasks: subtasks ?? this.subtasks,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        dueAt,
        category,
        remindBefore,
        isDone,
        createdAt,
        repeat,
        subtasks,
        completedAt,
      ];
}

/// Input for creating a task (id and createdAt assigned by the data layer).
class NewTask extends Equatable {
  const NewTask({
    required this.title,
    required this.dueAt,
    required this.category,
    required this.remindBefore,
    this.repeat = RepeatRule.none,
    this.subtasks = const <Subtask>[],
  });

  final String title;
  final DateTime dueAt;
  final TaskCategory category;
  final Duration? remindBefore;
  final RepeatRule repeat;
  final List<Subtask> subtasks;

  @override
  List<Object?> get props =>
      <Object?>[title, dueAt, category, remindBefore, repeat, subtasks];
}
