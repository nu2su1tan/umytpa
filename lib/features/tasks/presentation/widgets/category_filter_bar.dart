import 'package:flutter/material.dart';

import '../../../../core/theme/category_colors.dart';
import '../../../week_counter/ui/kit/pressable.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../domain/entities/task_category.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/task_l10n.dart';

/// Horizontal pill filter. Selected pill is violet, the rest are plain cards.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final TaskCategory? selected;
  final ValueChanged<TaskCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: <Widget>[
          _FilterChip(
            label: context.l10n.filterAll,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final TaskCategory category in TaskCategory.values) ...<Widget>[
            _FilterChip(
              label: context.l10n.categoryLabel(category),
              selected: selected == category,
              color: CategoryColors.of(category),
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final Color background = selected ? t.violetSoft : t.surface;
    final Color foreground = selected ? t.violetInk : t.ink;

    return Semantics(
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.out,
          constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: background,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? t.violetInk.withValues(alpha: 0.35)
                    : t.line,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (color != null) ...<Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: t.callout.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
