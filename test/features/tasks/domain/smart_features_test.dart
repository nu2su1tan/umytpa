import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/tasks/domain/entities/focus_session.dart';
import 'package:umytpa/features/tasks/domain/entities/repeat_rule.dart';
import 'package:umytpa/features/tasks/domain/entities/task.dart';
import 'package:umytpa/features/tasks/domain/entities/task_category.dart';
import 'package:umytpa/features/tasks/domain/usecases/parse_smart_input.dart';
import 'package:umytpa/features/tasks/domain/usecases/task_stats.dart';
import 'package:umytpa/features/tasks/domain/usecases/today_progress.dart';

void main() {
  // Wednesday 2026-11-04 12:00.
  final DateTime now = DateTime(2026, 11, 4, 12);

  group('RepeatRule.nextAfter', () {
    test('daily moves one day', () {
      expect(
        RepeatRule.daily.nextAfter(DateTime(2026, 11, 4, 18), now: now),
        DateTime(2026, 11, 5, 18),
      );
    });

    test('overdue task jumps to the future, keeping the time', () {
      expect(
        RepeatRule.daily.nextAfter(DateTime(2026, 11, 1, 9), now: now),
        DateTime(2026, 11, 5, 9),
      );
    });

    test('weekdays skips the weekend', () {
      // Friday 2026-11-06 -> Monday 2026-11-09.
      expect(
        RepeatRule.weekdays.nextAfter(
          DateTime(2026, 11, 6, 9),
          now: DateTime(2026, 11, 6, 8),
        ),
        DateTime(2026, 11, 9, 9),
      );
    });

    test('weekly moves seven days', () {
      expect(
        RepeatRule.weekly.nextAfter(DateTime(2026, 11, 5, 9), now: now),
        DateTime(2026, 11, 12, 9),
      );
    });
  });

  group('SmartInputParser', () {
    test('russian: tomorrow, time and category', () {
      final SmartInput r = SmartInputParser.parse(
        'Сдать лабу завтра в 18:00 #учёба',
        now: now,
      );
      expect(r.title, 'Сдать лабу');
      expect(r.date, DateTime(2026, 11, 5));
      expect(r.hour, 18);
      expect(r.minute, 0);
      expect(r.category, TaskCategory.study);
    });

    test('english: tomorrow at 6pm #work', () {
      final SmartInput r = SmartInputParser.parse(
        'Send report tomorrow at 6pm #work',
        now: now,
      );
      expect(r.title, 'Send report');
      expect(r.date, DateTime(2026, 11, 5));
      expect(r.hour, 18);
      expect(r.category, TaskCategory.work);
    });

    test('time only picks the next occurrence', () {
      final SmartInput later = SmartInputParser.parse('Call 15:30', now: now);
      expect(later.date, DateTime(2026, 11, 4));
      final SmartInput earlier = SmartInputParser.parse('Call 09:30', now: now);
      expect(earlier.date, DateTime(2026, 11, 5));
    });

    test('weekday and repeat', () {
      final SmartInput r = SmartInputParser.parse(
        'Спортзал в пятницу каждую неделю',
        now: now,
      );
      expect(r.title, 'Спортзал');
      expect(r.date, DateTime(2026, 11, 6));
      expect(r.repeat, RepeatRule.weekly);
    });

    test('daily repeat in english', () {
      final SmartInput r = SmartInputParser.parse('Stretch every day', now: now);
      expect(r.repeat, RepeatRule.daily);
      expect(r.title, 'Stretch');
    });

    test('plain text finds nothing', () {
      final SmartInput r = SmartInputParser.parse('Buy milk', now: now);
      expect(r.found, isFalse);
      expect(r.title, 'Buy milk');
    });
  });

  group('TaskStats', () {
    Task done(DateTime at, {TaskCategory c = TaskCategory.study}) => Task(
          id: at.millisecondsSinceEpoch,
          title: 't',
          dueAt: at,
          category: c,
          remindBefore: null,
          isDone: true,
          createdAt: at,
          completedAt: at,
        );

    test('streak counts consecutive days ending today', () {
      final TaskStats s = TaskStats.compute(
        <Task>[
          done(DateTime(2026, 11, 4, 9)),
          done(DateTime(2026, 11, 3, 9)),
          done(DateTime(2026, 11, 2, 9)),
          done(DateTime(2026, 10, 28, 9)),
        ],
        const <FocusSession>[],
        now: now,
      );
      expect(s.currentStreak, 3);
      expect(s.bestStreak, 3);
      expect(s.totalDone, 4);
      expect(s.doneToday, 1);
      expect(s.doneLast7.last, 1);
    });

    test('streak survives an empty today', () {
      final TaskStats s = TaskStats.compute(
        <Task>[done(DateTime(2026, 11, 3, 9)), done(DateTime(2026, 11, 2, 9))],
        const <FocusSession>[],
        now: now,
      );
      expect(s.currentStreak, 2);
    });

    test('streak breaks after a gap', () {
      final TaskStats s = TaskStats.compute(
        <Task>[done(DateTime(2026, 11, 1, 9))],
        const <FocusSession>[],
        now: now,
      );
      expect(s.currentStreak, 0);
      expect(s.bestStreak, 1);
    });

    test('focus minutes and badges', () {
      final TaskStats s = TaskStats.compute(
        <Task>[done(DateTime(2026, 11, 4, 9))],
        <FocusSession>[
          FocusSession(startedAt: DateTime(2026, 11, 4, 10), minutes: 25),
          FocusSession(startedAt: DateTime(2026, 11, 3, 10), minutes: 45),
        ],
        now: now,
      );
      expect(s.totalFocusMinutes, 70);
      expect(s.focusLast7.last, 25);
      expect(s.unlocked.map((a) => a.name), contains('focusHour'));
      expect(s.unlocked.map((a) => a.name), contains('firstDone'));
    });
  });

  group('TodayProgress', () {
    Task open(DateTime due) => Task(
          id: due.millisecondsSinceEpoch,
          title: 't',
          dueAt: due,
          category: TaskCategory.work,
          remindBefore: null,
          isDone: false,
          createdAt: now,
        );

    test('counts today and overdue, picks the most urgent', () {
      final TodayProgress p = TodayProgress.of(
        <Task>[
          open(DateTime(2026, 11, 4, 18)),
          open(DateTime(2026, 11, 2, 9)),
          open(DateTime(2026, 11, 9, 9)),
        ],
        now: now,
      );
      expect(p.total, 2);
      expect(p.overdue, 1);
      expect(p.next!.dueAt, DateTime(2026, 11, 2, 9));
    });
  });
}
