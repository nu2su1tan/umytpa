import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../entities/task.dart';

/// How the current day is going: what is done, what is left, what is next.
class TodayProgress extends Equatable {
  const TodayProgress({
    required this.done,
    required this.total,
    required this.next,
    required this.overdue,
  });

  /// Tasks due today that are finished.
  final int done;

  /// Tasks due today plus open overdue ones.
  final int total;

  /// The most urgent open task: the oldest overdue one, else the soonest.
  final Task? next;

  final int overdue;

  int get left => total - done;

  /// 0..1, or `null` when nothing is planned.
  double? get fraction => total == 0 ? null : done / total;

  bool get allDone => total > 0 && done == total;

  static TodayProgress of(List<Task> tasks, {required DateTime now}) {
    int done = 0;
    int total = 0;
    int overdue = 0;
    Task? next;
    for (final Task task in tasks) {
      final bool dueToday = DateTimeUtils.isSameCalendarDay(task.dueAt, now);
      if (task.isDone) {
        if (dueToday) {
          done++;
          total++;
        }
        continue;
      }
      final bool late = task.dueAt.isBefore(now) && !dueToday;
      if (dueToday || late) {
        total++;
      }
      if (late) {
        overdue++;
      }
      if (next == null || task.dueAt.isBefore(next.dueAt)) {
        next = task;
      }
    }
    return TodayProgress(
      done: done,
      total: total,
      next: next,
      overdue: overdue,
    );
  }

  @override
  List<Object?> get props => <Object?>[done, total, next, overdue];
}
