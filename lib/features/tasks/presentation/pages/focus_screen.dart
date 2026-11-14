import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/copy/profile_controller.dart';
import '../../../../core/di/injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../../../week_counter/ui/kit/glass.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/entities/task.dart';
import '../cubit/stats_cubit.dart';
import '../cubit/tasks_cubit.dart';

/// A Pomodoro-style timer, optionally tied to one task.
class FocusScreen extends StatefulWidget {
  const FocusScreen({this.task, super.key});

  final Task? task;

  static Future<void> open(BuildContext context, {Task? task}) {
    final StatsCubit stats = context.read<StatsCubit>();
    final TasksCubit tasks = context.read<TasksCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<StatsCubit>.value(value: stats),
            BlocProvider<TasksCubit>.value(value: tasks),
          ],
          child: FocusScreen(task: task),
        ),
      ),
    );
  }

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

enum _Phase { choosing, running, finished }

class _FocusScreenState extends State<FocusScreen> {
  static const List<int> _options = <int>[15, 25, 45, 60];

  final ReminderScheduler _scheduler = getIt<ReminderScheduler>();
  _Phase _phase = _Phase.choosing;
  int _minutes = 25;
  DateTime? _startedAt;
  DateTime? _endsAt;
  Timer? _ticker;
  Duration _left = Duration.zero;
  int _savedMinutes = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final DateTime now = DateTime.now();
    final AppLocalizations l10n = context.l10n;
    setState(() {
      _phase = _Phase.running;
      _startedAt = now;
      _endsAt = now.add(Duration(minutes: _minutes));
      _left = Duration(minutes: _minutes);
    });
    unawaited(HapticFeedback.mediumImpact());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    await _scheduler.scheduleFocusEnd(
      at: _endsAt!,
      title: l10n.focusNotifTitle,
      body: l10n.focusNotifBody,
    );
  }

  void _tick() {
    final Duration left = _endsAt!.difference(DateTime.now());
    if (left <= Duration.zero) {
      unawaited(_finish(_minutes));
    } else {
      setState(() => _left = left);
    }
  }

  Future<void> _finish(int minutes) async {
    _ticker?.cancel();
    final StatsCubit stats = context.read<StatsCubit>();
    await _scheduler.cancelFocusEnd();
    if (minutes >= 1) {
      await stats.addFocusSession(
        FocusSession(
          startedAt: _startedAt!,
          minutes: minutes,
          taskId: widget.task?.id,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _phase = _Phase.finished;
      _savedMinutes = minutes;
    });
  }

  /// Stopping early keeps the minutes actually spent.
  Future<void> _stop() {
    final int spent = DateTime.now().difference(_startedAt!).inMinutes;
    return _finish(math.min(spent, _minutes));
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final Task? task = widget.task;

    return PopScope(
      canPop: _phase != _Phase.running,
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassButton(
                    icon: Icons.close_rounded,
                    label: l10n.focusClose,
                    onTap: () {
                      if (_phase == _Phase.running) {
                        unawaited(_stop());
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  task == null
                      ? l10n.focusNoTask
                      : l10n.focusWithTask(task.title),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.callout.copyWith(color: t.ink2),
                ),
                const SizedBox(height: 24),
                _Dial(
                  phase: _phase,
                  total: Duration(minutes: _minutes),
                  left: _left,
                ),
                const SizedBox(height: 24),
                if (_phase == _Phase.choosing)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      for (final int m in _options)
                        ChoiceChip(
                          label: Text(l10n.focusMinutesOption(m)),
                          selected: _minutes == m,
                          onSelected: (_) => setState(() => _minutes = m),
                        ),
                    ],
                  ),
                if (_phase == _Phase.running)
                  Text(
                    l10n.focusRunning,
                    style: t.callout.copyWith(color: t.ink3),
                  ),
                if (_phase == _Phase.finished) ...<Widget>[
                  Text(
                    context.copy.focusDone,
                    style: t.sectionTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.focusDoneBody(_savedMinutes),
                    style: t.callout.copyWith(color: t.ink2),
                  ),
                ],
                const Spacer(),
                _buildAction(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, AppLocalizations l10n) {
    switch (_phase) {
      case _Phase.choosing:
        return FilledButton(onPressed: _start, child: Text(l10n.focusStart));
      case _Phase.running:
        return OutlinedButton(
          onPressed: _stop,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: const StadiumBorder(),
          ),
          child: Text(l10n.focusStop),
        );
      case _Phase.finished:
        final Task? task = widget.task;
        return Column(
          children: <Widget>[
            if (task != null && !task.isDone)
              FilledButton(
                onPressed: () {
                  unawaited(context.read<TasksCubit>().toggleDone(task));
                  Navigator.of(context).pop();
                },
                child: Text(l10n.focusMarkTaskDone),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.focusClose),
            ),
          ],
        );
    }
  }
}

class _Dial extends StatelessWidget {
  const _Dial({required this.phase, required this.total, required this.left});

  final _Phase phase;
  final Duration total;
  final Duration left;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final Duration shown = phase == _Phase.choosing ? total : left;
    final double fraction = phase == _Phase.running
        ? 1 - left.inMilliseconds / total.inMilliseconds
        : phase == _Phase.finished
        ? 1
        : 0;
    final String text = phase == _Phase.finished
        ? '✓'
        : '${shown.inMinutes.toString().padLeft(2, '0')}:'
              '${(shown.inSeconds % 60).toString().padLeft(2, '0')}';
    return SizedBox.square(
      dimension: 260,
      child: CustomPaint(
        painter: _DialPainter(
          fraction: fraction.clamp(0.0, 1.0),
          track: t.surface3,
          color: phase == _Phase.finished ? Tokens.lime : t.violetInk,
        ),
        child: Center(
          child: Text(
            text,
            style: t.largeTitle.copyWith(
              fontSize: 54,
              fontFeatures: Fonts.tabular,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.fraction,
    required this.track,
    required this.color,
  });

  final double fraction;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 14;
    final Rect arc = (Offset.zero & size).deflate(stroke / 2);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint);
    if (fraction > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
