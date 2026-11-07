import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TasksEmptyView extends StatelessWidget {
  const TasksEmptyView({required this.onAddTask, super.key});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const _EmptyIllustration(),
            const SizedBox(height: 24),
            Text(
              'No tasks yet',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first one',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160, minHeight: 48),
              child: FilledButton(
                onPressed: onAddTask,
                child: const Text('Add task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasksFilterEmptyView extends StatelessWidget {
  const TasksFilterEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.filter_list_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks in this category',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try another filter or add a new task',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    final Color line = Theme.of(context).colorScheme.onSurface;
    final Color accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 88,
      height: 96,
      child: CustomPaint(
        painter: _EmptyPainter(line: line, accent: accent),
      ),
    );
  }
}

class _EmptyPainter extends CustomPainter {
  _EmptyPainter({required this.line, required this.accent});

  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final RRect card = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 12, size.width - 20, size.height - 20),
      const Radius.circular(12),
    );
    canvas.drawRRect(card, stroke);

    final Paint dash = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Paint bar = Paint()
      ..color = line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final double y = 32.0 + i * 16;
      canvas
        ..drawLine(Offset(22, y), Offset(30, y), dash)
        ..drawLine(Offset(38, y), Offset(size.width - 28, y), bar);
    }

    canvas.drawCircle(Offset(size.width - 10, 18), 5, stroke);
  }

  @override
  bool shouldRepaint(covariant _EmptyPainter oldDelegate) {
    return oldDelegate.line != line || oldDelegate.accent != accent;
  }
}
