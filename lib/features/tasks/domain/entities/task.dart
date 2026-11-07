import 'package:equatable/equatable.dart';

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
  });

  final int id;
  final String title;
  final DateTime dueAt;
  final TaskCategory category;

  /// Offset before [dueAt]. `null` = no reminder. Do not store [remindAt].
  final Duration? remindBefore;
  final bool isDone;
  final DateTime createdAt;

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
      ];
}

/// Input for creating a task (id and createdAt assigned by the data layer).
class NewTask extends Equatable {
  const NewTask({
    required this.title,
    required this.dueAt,
    required this.category,
    required this.remindBefore,
  });

  final String title;
  final DateTime dueAt;
  final TaskCategory category;
  final Duration? remindBefore;

  @override
  List<Object?> get props =>
      <Object?>[title, dueAt, category, remindBefore];
}
