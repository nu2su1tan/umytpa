import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_section.dart';
import 'task_tile.dart';

class TaskSectionView extends StatelessWidget {
  const TaskSectionView({
    required this.section,
    required this.collapsed,
    required this.now,
    required this.onToggleCollapsed,
    required this.onToggleDone,
    required this.onTapTask,
    required this.onDeleteTask,
    super.key,
  });

  final TaskSection section;
  final bool collapsed;
  final DateTime now;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<Task> onToggleDone;
  final ValueChanged<Task> onTapTask;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color headerColor = section.kind.isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: section.kind.initiallyCollapsed ||
                  section.kind == TaskSectionKind.completed
              ? onToggleCollapsed
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: <Widget>[
                Text(
                  section.kind.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: headerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (section.kind == TaskSectionKind.completed) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 18,
                    color: headerColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${section.tasks.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: headerColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!collapsed)
          ...section.tasks.map(
            (Task task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey<int>(task.id),
                direction: DismissDirection.endToStart,
                background: const _DeleteBackground(),
                onDismissed: (_) => onDeleteTask(task),
                child: TaskTile(
                  task: task,
                  now: now,
                  isOverdueSection: section.kind.isOverdue,
                  onToggleDone: () => onToggleDone(task),
                  onTap: () => onTapTask(task),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
    );
  }
}
