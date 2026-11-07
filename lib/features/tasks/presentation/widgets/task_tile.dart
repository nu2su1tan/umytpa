import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/category_colors.dart';
import '../../../week_counter/ui/kit/pressable.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../domain/entities/task.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/task_l10n.dart';

/// One task as a rounded card with a round check, matching the Week cards.
class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.now,
    required this.isOverdueSection,
    required this.onToggleDone,
    required this.onTap,
    this.onFocus,
    super.key,
  });

  final Task task;
  final DateTime now;
  final bool isOverdueSection;
  final VoidCallback onToggleDone;
  final VoidCallback onTap;

  /// Starts a focus session for this task; hidden when null.
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final Color categoryColor = CategoryColors.of(task.category);
    final bool overdue =
        isOverdueSection || (!task.isDone && task.dueAt.isBefore(now));
    final String? reminder = context.l10n.reminderBefore(task.remindBefore);
    final Color secondary = task.isDone ? t.ink3 : t.ink2;
    final Color dueColor = overdue && !task.isDone ? t.danger : secondary;
    final TextDecoration? strike =
        task.isDone ? TextDecoration.lineThrough : null;

    return Pressable(
      onTap: onTap,
      scale: 0.985,
      haptic: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.line, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              label: task.isDone ? context.l10n.markNotDone : context.l10n.markDone,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  unawaited(
                    task.isDone
                        ? HapticFeedback.selectionClick()
                        : HapticFeedback.mediumImpact(),
                  );
                  onToggleDone();
                },
                child: SizedBox(
                  width: 56,
                  height: 64,
                  child: Center(child: _CheckCircle(done: task.isDone)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      task.title,
                      style: t.body.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: strike,
                        decorationColor: t.ink3,
                        color: task.isDone ? t.ink3 : t.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                          context.l10n.categoryLabel(task.category),
                          style: t.footnote.copyWith(
                            color: secondary,
                            decoration: strike,
                          ),
                        ),
                        Text('·', style: t.footnote.copyWith(color: t.ink3)),
                        Text(
                          context.l10n.dueLabel(task.dueAt, now: now),
                          style: t.footnote.copyWith(
                            color: dueColor,
                            fontWeight: overdue && !task.isDone
                                ? FontWeight.w600
                                : FontWeight.w400,
                            decoration: strike,
                          ),
                        ),
                        if (reminder != null && !task.isDone)
                          _ReminderBadge(label: reminder),
                        if (task.repeat.repeats)
                          Icon(Icons.repeat_rounded, size: 14, color: t.ink3),
                        if (task.subtasks.isNotEmpty)
                          _SubtaskBadge(
                            done: task.subtasksDone,
                            total: task.subtasks.length,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (onFocus != null && !task.isDone)
              Semantics(
                button: true,
                label: context.l10n.focusTask,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onFocus,
                  child: SizedBox(
                    width: 48,
                    height: 64,
                    child: Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: t.ink3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubtaskBadge extends StatelessWidget {
  const _SubtaskBadge({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.checklist_rounded, size: 14, color: t.ink3),
        const SizedBox(width: 3),
        Text(
          context.l10n.subtaskProgress(done, total),
          style: t.footnote.copyWith(
            color: done == total ? t.limeInk : t.ink2,
            fontFeatures: Fonts.tabular,
          ),
        ),
      ],
    );
  }
}

class _ReminderBadge extends StatelessWidget {
  const _ReminderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: t.violetSoft,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.notifications_none_rounded, size: 13, color: t.violetInk),
          const SizedBox(width: 3),
          Text(
            label,
            style: t.footnote.copyWith(
              fontSize: 12,
              height: 16 / 12,
              color: t.violetInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round check: empty ring while open, lime disc with a dark tick when done.
/// The disc pops with a spring when it gets ticked.
class _CheckCircle extends StatefulWidget {
  const _CheckCircle({required this.done});

  final bool done;

  @override
  State<_CheckCircle> createState() => _CheckCircleState();
}

class _CheckCircleState extends State<_CheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void didUpdateWidget(_CheckCircle old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) {
      unawaited(_pop.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final bool done = widget.done;
    return AnimatedBuilder(
      animation: _pop,
      builder: (BuildContext context, Widget? child) {
        final double scale = _pop.isAnimating
            ? 0.55 + 0.45 * Curves.elasticOut.transform(_pop.value)
            : 1;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.out,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? Tokens.lime : Colors.transparent,
          border: Border.all(
            color: done ? Tokens.lime : t.ink3,
            width: 1.5,
          ),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF111111))
            : null,
      ),
    );
  }
}
