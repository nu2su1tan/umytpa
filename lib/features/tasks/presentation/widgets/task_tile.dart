import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_colors.dart';
import '../../domain/entities/task.dart';
import '../utils/reminder_label.dart';
import '../utils/task_date_format.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.now,
    required this.isOverdueSection,
    required this.onToggleDone,
    required this.onTap,
    super.key,
  });

  final Task task;
  final DateTime now;
  final bool isOverdueSection;
  final VoidCallback onToggleDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color categoryColor = CategoryColors.of(task.category);
    final bool overdue = isOverdueSection ||
        (!task.isDone && task.dueAt.isBefore(now));
    final String? reminder = ReminderLabel.forDuration(task.remindBefore);
    final Color secondary = task.isDone
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant;
    final Color dueColor = overdue && !task.isDone
        ? theme.colorScheme.error
        : secondary;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                label: task.isDone ? 'Mark as not done' : 'Mark as done',
                button: true,
                child: IconButton(
                  onPressed: onToggleDone,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(
                    task.isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.isDone
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isDone
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            task.category.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: secondary,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            '·',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: secondary,
                            ),
                          ),
                          Text(
                            TaskDateFormat.dueLabel(task.dueAt, now: now),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: dueColor,
                              fontWeight: overdue && !task.isDone
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (reminder != null && !task.isDone) ...<Widget>[
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            Text(
                              reminder,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
