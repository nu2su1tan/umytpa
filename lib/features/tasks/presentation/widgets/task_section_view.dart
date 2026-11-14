import 'package:flutter/material.dart';

import '../../../../core/copy/profile_controller.dart';
import '../../../week_counter/ui/kit/pressable.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_section.dart';
import 'task_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/task_l10n.dart';

class TaskSectionView extends StatelessWidget {
  const TaskSectionView({
    required this.section,
    required this.collapsed,
    required this.now,
    required this.onToggleCollapsed,
    required this.onToggleDone,
    required this.onTapTask,
    required this.onDeleteTask,
    this.onFocusTask,
    this.onDuplicateTask,
    super.key,
  });

  final TaskSection section;
  final bool collapsed;
  final DateTime now;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<Task> onToggleDone;
  final ValueChanged<Task> onTapTask;
  final ValueChanged<Task> onDeleteTask;
  final ValueChanged<Task>? onFocusTask;

  /// Swipe right: make a copy of the task.
  final ValueChanged<Task>? onDuplicateTask;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final Color headerColor = section.kind.isOverdue ? t.danger : t.ink2;
    final bool canCollapse =
        section.kind.initiallyCollapsed ||
        section.kind == TaskSectionKind.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Pressable(
          onTap: canCollapse ? onToggleCollapsed : null,
          scale: 0.98,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 28),
              child: Row(
                children: <Widget>[
                  Text(
                    section.kind.isOverdue
                        ? context.copy.overdueTitle
                        : context.l10n.sectionTitle(section.kind),
                    style: t.sectionTitle.copyWith(
                      fontSize: 20,
                      height: 26 / 20,
                      color: section.kind.isOverdue ? t.danger : t.ink,
                    ),
                  ),
                  if (section.kind == TaskSectionKind.completed) ...<Widget>[
                    const SizedBox(width: 6),
                    Icon(
                      collapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 22,
                      color: headerColor,
                    ),
                    const SizedBox(width: 2),
                    Text('${section.tasks.length}', style: t.mono),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (section.kind.isOverdue && !collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              context.copy.overdueNudge,
              style: t.footnote.copyWith(color: t.ink2),
            ),
          ),
        if (!collapsed)
          ...section.tasks.map(
            (Task task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey<int>(task.id),
                direction: onDuplicateTask == null
                    ? DismissDirection.endToStart
                    : DismissDirection.horizontal,
                background: onDuplicateTask == null
                    ? const _DeleteBackground()
                    : const _DuplicateBackground(),
                secondaryBackground: onDuplicateTask == null
                    ? null
                    : const _DeleteBackground(),
                confirmDismiss: (DismissDirection direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    onDuplicateTask?.call(task);
                    return false;
                  }
                  return true;
                },
                onDismissed: (_) => onDeleteTask(task),
                child: TaskTile(
                  task: task,
                  now: now,
                  isOverdueSection: section.kind.isOverdue,
                  onToggleDone: () => onToggleDone(task),
                  onTap: () => onTapTask(task),
                  onFocus: onFocusTask == null
                      ? null
                      : () => onFocusTask!(task),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DuplicateBackground extends StatelessWidget {
  const _DuplicateBackground();

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: t.violetSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.copy_rounded, color: t.violetInk),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.delete_outline_rounded, color: t.danger),
    );
  }
}
