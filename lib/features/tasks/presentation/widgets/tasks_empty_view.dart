import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../week_counter/ui/kit/buttons.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';

class TasksEmptyView extends StatelessWidget {
  const TasksEmptyView({required this.onAddTask, super.key});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding * 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const _EmptyIllustration(),
            const SizedBox(height: 28),
            Text(
              context.l10n.tasksEmptyTitle,
              style: t.largeTitle.copyWith(fontSize: 28, height: 34 / 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tasksEmptyBody,
              style: t.body.copyWith(color: t.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            AppButton(label: context.l10n.addTask, onTap: onAddTask, expand: false),
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
    final Tokens t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding * 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: t.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off_rounded,
                size: 30,
                color: t.ink2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.tasksFilterEmptyTitle,
              style: t.navTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.tasksFilterEmptyBody,
              style: t.callout,
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
    final Tokens t = context.tokens;

    return SizedBox(
      width: 88,
      height: 96,
      child: CustomPaint(
        painter: _EmptyPainter(line: t.ink, accent: t.violetInk),
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
      const Radius.circular(14),
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

    canvas.drawCircle(
      Offset(size.width - 10, 18),
      5,
      Paint()
        ..color = Tokens.lime
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyPainter oldDelegate) {
    return oldDelegate.line != line || oldDelegate.accent != accent;
  }
}
