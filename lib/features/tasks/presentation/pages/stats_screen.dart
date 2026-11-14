import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/category_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../week_counter/ui/kit/app_page.dart';
import '../../../week_counter/ui/kit/glass.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/usecases/task_stats.dart';
import '../cubit/stats_cubit.dart';
import '../utils/task_l10n.dart';

/// Streak, charts by day and category, focus time and badges.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static Future<void> open(BuildContext context) {
    final StatsCubit cubit = context.read<StatsCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<StatsCubit>.value(
          value: cubit,
          child: const StatsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      backgroundColor: t.bg,
      body: BlocBuilder<StatsCubit, TaskStats>(
        builder: (BuildContext context, TaskStats s) {
          return AppPage(
            title: l10n.statsTitle,
            largeTitle: false,
            titleOnScroll: true,
            bottomPadding: 40,
            leading: GlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: l10n.back,
              onTap: () => Navigator.of(context).pop(),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(l10n.statsTitle, style: t.largeTitle),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _Tile(
                        label: l10n.statsDoneTotal,
                        value: '${s.totalDone}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Tile(
                        label: l10n.statsCurrentStreak,
                        value: '${s.currentStreak}',
                        suffix: l10n.statsDaysShort,
                        accent: s.currentStreak > 0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Tile(
                        label: l10n.statsBestStreak,
                        value: '${s.bestStreak}',
                        suffix: l10n.statsDaysShort,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: l10n.statsLast7Done,
                child: _Bars(values: s.doneLast7, locale: l10n.localeName),
              ),
              if (s.bestWeekday != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    '${l10n.statsBestDay}: ${_weekdayName(s.bestWeekday!, l10n.localeName)}',
                    style: t.footnote.copyWith(color: t.ink2),
                  ),
                ),
              if (s.byCategory.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _Section(
                  title: l10n.statsByCategory,
                  child: _Categories(counts: s.byCategory),
                ),
              ],
              const SizedBox(height: 16),
              _Section(
                title:
                    '${l10n.statsLast7Focus} · ${_duration(l10n, s.focusThisWeek)}',
                child: _Bars(
                  values: s.focusLast7,
                  locale: l10n.localeName,
                  color: t.violetInk,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  '${l10n.statsFocusTotal}: ${_duration(l10n, s.totalFocusMinutes)}',
                  style: t.footnote.copyWith(color: t.ink2),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: l10n.statsBadges,
                child: Column(
                  children: <Widget>[
                    for (final Achievement a in Achievement.values)
                      _Badge(achievement: a, unlocked: s.unlocked.contains(a)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _weekdayName(int index, String locale) {
    // 2024-01-01 was a Monday.
    return DateFormat('EEEE', locale).format(DateTime(2024, 1, 1 + index));
  }

  static String _duration(AppLocalizations l10n, int minutes) {
    if (minutes < 60) {
      return l10n.minutesShort(minutes);
    }
    return l10n.hoursMinutesShort(minutes ~/ 60, minutes % 60);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    this.suffix,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                value,
                style: t.largeTitle.copyWith(
                  fontSize: 30,
                  height: 1.1,
                  color: accent ? t.violetInk : t.ink,
                  fontFeatures: Fonts.tabular,
                ),
              ),
              if (suffix != null) ...<Widget>[
                const SizedBox(width: 3),
                Text(suffix!, style: t.footnote.copyWith(color: t.ink2)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: t.footnote.copyWith(color: t.ink2, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: t.callout.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Seven bars, oldest first, labelled with weekday initials.
class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.locale, this.color});

  final List<int> values;
  final String locale;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final int maxValue = values.fold(1, (int a, int b) => b > a ? b : a);
    final DateTime today = DateTime.now();
    final Color bar = color ?? t.limeInk;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final (int i, int v) in values.indexed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      v == 0 ? '' : '$v',
                      style: t.footnote.copyWith(
                        fontSize: 11,
                        color: t.ink2,
                        fontFeatures: Fonts.tabular,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: v / maxValue),
                      duration: Motion.slow,
                      curve: Motion.out,
                      builder: (BuildContext context, double f, _) {
                        return Container(
                          height: 4 + 64 * f,
                          decoration: BoxDecoration(
                            color: v == 0 ? t.surface3 : bar,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.E(locale).format(
                        DateTime(today.year, today.month, today.day - (6 - i)),
                      ),
                      style: t.footnote.copyWith(fontSize: 11, color: t.ink3),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.counts});

  final Map<TaskCategory, int> counts;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final int total = counts.values.fold(0, (int a, int b) => a + b);
    return Column(
      children: <Widget>[
        for (final TaskCategory c in TaskCategory.values)
          if ((counts[c] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 92,
                    child: Text(
                      context.l10n.categoryLabel(c),
                      style: t.footnote,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: counts[c]! / total),
                        duration: Motion.slow,
                        curve: Motion.out,
                        builder: (BuildContext context, double f, _) {
                          return LinearProgressIndicator(
                            value: f,
                            minHeight: 10,
                            backgroundColor: t.surface3,
                            color: CategoryColors.of(c),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${counts[c]}',
                    style: t.footnote.copyWith(fontFeatures: Fonts.tabular),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final (String name, String desc, IconData icon) = switch (achievement) {
      Achievement.firstDone => (
        l10n.badgeFirstDone,
        l10n.badgeFirstDoneDesc,
        Icons.flag_rounded,
      ),
      Achievement.tenDone => (
        l10n.badgeTenDone,
        l10n.badgeTenDoneDesc,
        Icons.bolt_rounded,
      ),
      Achievement.fiftyDone => (
        l10n.badgeFiftyDone,
        l10n.badgeFiftyDoneDesc,
        Icons.local_fire_department_rounded,
      ),
      Achievement.hundredDone => (
        l10n.badgeHundredDone,
        l10n.badgeHundredDoneDesc,
        Icons.emoji_events_rounded,
      ),
      Achievement.streak3 => (
        l10n.badgeStreak3,
        l10n.badgeStreak3Desc,
        Icons.looks_3_rounded,
      ),
      Achievement.streak7 => (
        l10n.badgeStreak7,
        l10n.badgeStreak7Desc,
        Icons.calendar_view_week_rounded,
      ),
      Achievement.streak30 => (
        l10n.badgeStreak30,
        l10n.badgeStreak30Desc,
        Icons.workspace_premium_rounded,
      ),
      Achievement.focusHour => (
        l10n.badgeFocusHour,
        l10n.badgeFocusHourDesc,
        Icons.timer_rounded,
      ),
      Achievement.focusTenHours => (
        l10n.badgeFocusTen,
        l10n.badgeFocusTenDesc,
        Icons.self_improvement_rounded,
      ),
    };
    return Opacity(
      opacity: unlocked ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? Tokens.lime : t.surface3,
              ),
              child: Icon(
                unlocked ? icon : Icons.lock_outline_rounded,
                size: 20,
                color: unlocked ? const Color(0xFF111111) : t.ink3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: t.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(desc, style: t.footnote.copyWith(color: t.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
