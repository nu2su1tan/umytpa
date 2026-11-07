import 'package:flutter/material.dart';

import '../../../../core/theme/category_colors.dart';
import '../../../../core/ui/glass/glass.dart';
import '../../domain/entities/task_category.dart';

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
        children: <Widget>[
          _FilterChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final TaskCategory category in TaskCategory.values) ...<Widget>[
            _FilterChip(
              label: category.label,
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
    final ThemeData theme = Theme.of(context);
    final Color accentColor = color ?? theme.colorScheme.primary;
    final Color borderColor = selected ? accentColor : theme.dividerColor;

    final Widget chipContent = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: selected
                ? AppGlass(
                    radius: 20,
                    tint: accentColor.withValues(alpha: 0.16),
                    interactive: true,
                    child: chipContent,
                  )
                : chipContent,
          ),
        ),
      ),
    );
  }
}
