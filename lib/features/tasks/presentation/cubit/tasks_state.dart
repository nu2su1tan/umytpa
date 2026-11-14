import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_section.dart';

sealed class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class TasksInitial extends TasksState {
  const TasksInitial();
}

final class TasksLoading extends TasksState {
  const TasksLoading();
}

final class TasksLoaded extends TasksState {
  const TasksLoaded({
    required this.allTasks,
    required this.sections,
    required this.selectedCategory,
    required this.collapsedSections,
  });

  final List<Task> allTasks;
  final List<TaskSection> sections;
  final TaskCategory? selectedCategory;
  final Set<TaskSectionKind> collapsedSections;

  bool get isGloballyEmpty => allTasks.isEmpty;

  bool get isFilterEmpty => allTasks.isNotEmpty && sections.isEmpty;

  TasksLoaded copyWith({
    List<Task>? allTasks,
    List<TaskSection>? sections,
    TaskCategory? Function()? selectedCategory,
    Set<TaskSectionKind>? collapsedSections,
  }) {
    return TasksLoaded(
      allTasks: allTasks ?? this.allTasks,
      sections: sections ?? this.sections,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      collapsedSections: collapsedSections ?? this.collapsedSections,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    allTasks,
    sections,
    selectedCategory,
    collapsedSections,
  ];
}

final class TasksFailure extends TasksState {
  const TasksFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
