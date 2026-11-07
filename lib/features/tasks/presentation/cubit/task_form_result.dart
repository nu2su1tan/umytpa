import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';

/// Result returned when the form sheet is closed.
sealed class TaskFormResult extends Equatable {
  const TaskFormResult();

  @override
  List<Object?> get props => const <Object?>[];
}

final class TaskFormSaved extends TaskFormResult {
  const TaskFormSaved();
}

final class TaskFormDeleted extends TaskFormResult {
  const TaskFormDeleted(this.task);

  final Task task;

  @override
  List<Object?> get props => <Object?>[task];
}
