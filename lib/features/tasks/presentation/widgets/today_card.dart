import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/copy/copy_pack.dart';
import '../../../../core/copy/profile_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../week_counter/ui/kit/pressable.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../domain/usecases/task_stats.dart';
import '../../domain/usecases/today_progress.dart';
import 'confetti_burst.dart';

/// "Today" summary: a progress ring, what's next, the streak, and shortcuts to
/// focus mode and statistics.
class TodayCard extends StatefulWidget {
  const TodayCard({
    required this.progress,
    required this.stats,
    required this.onOpenStats,
    required this.onStartFocus,
    super.key,
  });

  final TodayProgress progress;
  final TaskStats stats;
  final VoidCallback onOpenStats;
  final VoidCallback onStartFocus;

  @override
  State<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<TodayCard> {
  final GlobalKey<ConfettiBurstState> _confetti =
      GlobalKey<ConfettiBurstState>();

  @override
  void didUpdateWidget(TodayCard old) {
    super.didUpdateWidget(old);
    if (widget.progress.allDone && !old.progress.allDone) {
      unawaited(HapticFeedback.heavyImpact());
      _confetti.currentState?.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final TodayProgress p = widget.progress;
    final double fraction = p.fraction ?? 0;

    final CopyPack copy = context.copy;
    final String headline = p.total == 0
        ? copy.todayNothing
        : p.allDone
        ? copy.todayAllDone
        : copy.leftLine(p.left);
    final TaskStats stats = widget.stats;
    final String? mood = stats.currentStreak > 0
        ? copy.streakNote(stats.currentStreak)
        : (stats.bestStreak >= 3 && stats.doneToday == 0)
        ? copy.streakLost
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.line, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: fraction),
                    duration: Motion.slow,
                    curve: Motion.out,
                    builder: (BuildContext context, double value, _) {
                      return SizedBox.square(
                        dimension: 76,
                        child: CustomPaint(
                          painter: _RingPainter(
                            fraction: value,
                            track: t.surface3,
                            color: p.allDone ? Tokens.lime : t.violetInk,
                          ),
                          child: Center(
                            child: Text(
                              p.total == 0 ? '–' : '${(value * 100).round()}%',
                              style: t.body.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: Fonts.tabular,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          headline,
                          style: t.sectionTitle.copyWith(
                            fontSize: 20,
                            height: 26 / 20,
                          ),
                        ),
                        if (p.total == 0) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            copy.emptyLine(
                              DateTime.now(),
                              name: context.profile.name,
                            ),
                            style: t.footnote.copyWith(color: t.ink2),
                          ),
                        ],
                        if (p.total > 0) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            l10n.todayDoneOf(p.done, p.total),
                            style: t.footnote.copyWith(color: t.ink2),
                          ),
                        ],
                        if (p.next != null && !p.allDone) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            l10n.todayNext(p.next!.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.footnote.copyWith(color: t.ink2),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (mood != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(mood, style: t.footnote.copyWith(color: t.ink2)),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (widget.stats.currentStreak > 0)
                    _Chip(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF8A3D),
                      label: copy.streakChip(widget.stats.currentStreak),
                      onTap: widget.onOpenStats,
                    ),
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: l10n.focusTitle,
                    onTap: widget.onStartFocus,
                  ),
                  _Chip(
                    icon: Icons.bar_chart_rounded,
                    label: l10n.statsOpen,
                    onTap: widget.onOpenStats,
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned.fill(child: ConfettiBurst(key: _confetti)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: t.surface2,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: iconColor ?? t.violetInk),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.footnote.copyWith(
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.color,
  });

  final double fraction;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 8;
    final Rect arc = (Offset.zero & size).deflate(stroke / 2);
    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(arc, 0, math.pi * 2, false, base);
    if (fraction > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * fraction.clamp(0.0, 1.0),
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
