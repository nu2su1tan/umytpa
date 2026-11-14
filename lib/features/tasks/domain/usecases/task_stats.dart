import 'package:equatable/equatable.dart';

import '../entities/achievement.dart';
import '../entities/focus_session.dart';
import '../entities/task.dart';
import '../entities/task_category.dart';

/// Numbers behind the stats screen, streaks and badges.
class TaskStats extends Equatable {
  const TaskStats({
    required this.totalDone,
    required this.currentStreak,
    required this.bestStreak,
    required this.doneLast7,
    required this.focusLast7,
    required this.byCategory,
    required this.totalFocusMinutes,
    required this.focusSessions,
    required this.doneToday,
    required this.weekdayHistogram,
    this.donePrevWeek = 0,
  });

  final int totalDone;
  final int currentStreak;
  final int bestStreak;

  /// Completed tasks per day, oldest first, ending today.
  final List<int> doneLast7;

  /// Focus minutes per day, oldest first, ending today.
  final List<int> focusLast7;
  final Map<TaskCategory, int> byCategory;
  final int totalFocusMinutes;
  final int focusSessions;
  final int doneToday;

  /// Completed tasks by weekday (index 0 = Monday).
  final List<int> weekdayHistogram;

  /// Completed tasks in the 7 days before [doneLast7].
  final int donePrevWeek;

  int get doneThisWeek => doneLast7.fold(0, (int a, int b) => a + b);

  int get focusThisWeek => focusLast7.fold(0, (int a, int b) => a + b);

  /// Index of the weekday with the most finished tasks, or `null`.
  int? get bestWeekday {
    int best = 0;
    int? index;
    for (int i = 0; i < weekdayHistogram.length; i++) {
      if (weekdayHistogram[i] > best) {
        best = weekdayHistogram[i];
        index = i;
      }
    }
    return index;
  }

  List<Achievement> get unlocked => Achievement.values
      .where(
        (Achievement a) => a.isUnlocked(
          totalDone: totalDone,
          bestStreak: bestStreak,
          totalFocusMinutes: totalFocusMinutes,
        ),
      )
      .toList(growable: false);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static TaskStats compute(
    List<Task> tasks,
    List<FocusSession> sessions, {
    required DateTime now,
  }) {
    final DateTime today = _day(now);
    final Map<DateTime, int> doneByDay = <DateTime, int>{};
    final Map<TaskCategory, int> byCategory = <TaskCategory, int>{};
    final List<int> weekdays = List<int>.filled(7, 0);
    int totalDone = 0;

    for (final Task task in tasks) {
      final DateTime? at = task.isDone
          ? (task.completedAt ?? task.dueAt)
          : null;
      if (at == null) {
        continue;
      }
      totalDone++;
      final DateTime day = _day(at);
      doneByDay[day] = (doneByDay[day] ?? 0) + 1;
      byCategory[task.category] = (byCategory[task.category] ?? 0) + 1;
      weekdays[at.weekday - 1]++;
    }

    final Map<DateTime, int> focusByDay = <DateTime, int>{};
    int totalFocus = 0;
    for (final FocusSession s in sessions) {
      final DateTime day = _day(s.startedAt);
      focusByDay[day] = (focusByDay[day] ?? 0) + s.minutes;
      totalFocus += s.minutes;
    }

    DateTime back(int days) =>
        DateTime(today.year, today.month, today.day - days);

    // Current streak: consecutive days with a finished task, counted back from
    // today (or from yesterday while today is still empty).
    int current = 0;
    DateTime cursor = (doneByDay[today] ?? 0) > 0 ? today : back(1);
    while ((doneByDay[cursor] ?? 0) > 0) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    final List<DateTime> days = doneByDay.keys.toList()..sort();
    int best = 0;
    int run = 0;
    DateTime? prev;
    for (final DateTime day in days) {
      if (prev != null &&
          DateTime(prev.year, prev.month, prev.day + 1) == day) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) {
        best = run;
      }
      prev = day;
    }

    return TaskStats(
      totalDone: totalDone,
      currentStreak: current,
      bestStreak: best,
      doneLast7: <int>[for (int i = 6; i >= 0; i--) doneByDay[back(i)] ?? 0],
      focusLast7: <int>[for (int i = 6; i >= 0; i--) focusByDay[back(i)] ?? 0],
      byCategory: byCategory,
      totalFocusMinutes: totalFocus,
      focusSessions: sessions.length,
      doneToday: doneByDay[today] ?? 0,
      weekdayHistogram: weekdays,
      donePrevWeek: <int>[
        for (int i = 13; i >= 7; i--) doneByDay[back(i)] ?? 0,
      ].fold(0, (int a, int b) => a + b),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    totalDone,
    currentStreak,
    bestStreak,
    doneLast7,
    focusLast7,
    byCategory,
    totalFocusMinutes,
    focusSessions,
    doneToday,
    weekdayHistogram,
    donePrevWeek,
  ];
}
