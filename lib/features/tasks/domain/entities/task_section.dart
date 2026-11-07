import 'package:equatable/equatable.dart';

import 'task.dart';

enum TaskSectionKind {
  overdue,
  today,
  tomorrow,
  later,
  completed;

  String get title => switch (this) {
        TaskSectionKind.overdue => 'Overdue',
        TaskSectionKind.today => 'Today',
        TaskSectionKind.tomorrow => 'Tomorrow',
        TaskSectionKind.later => 'Later',
        TaskSectionKind.completed => 'Completed',
      };

  bool get initiallyCollapsed => this == TaskSectionKind.completed;

  bool get isOverdue => this == TaskSectionKind.overdue;
}

final class TaskSection extends Equatable {
  const TaskSection({
    required this.kind,
    required this.tasks,
  });

  final TaskSectionKind kind;
  final List<Task> tasks;

  bool get isEmpty => tasks.isEmpty;

  @override
  List<Object?> get props => <Object?>[kind, tasks];
}
