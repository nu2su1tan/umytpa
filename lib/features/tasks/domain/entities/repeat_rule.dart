/// How often a task comes back after it is completed.
enum RepeatRule {
  none,
  daily,
  weekdays,
  weekly;

  bool get repeats => this != RepeatRule.none;

  /// The first occurrence after [from] that is also after [now], keeping the
  /// time of day. Completing a long-overdue task therefore yields a future
  /// date, not another overdue one.
  DateTime nextAfter(DateTime from, {required DateTime now}) {
    if (this == RepeatRule.none) {
      return from;
    }
    DateTime next = from;
    do {
      next = _step(next);
    } while (!next.isAfter(now));
    return next;
  }

  DateTime _step(DateTime d) {
    DateTime plus(int days) =>
        DateTime(d.year, d.month, d.day + days, d.hour, d.minute);
    switch (this) {
      case RepeatRule.none:
        return d;
      case RepeatRule.daily:
        return plus(1);
      case RepeatRule.weekly:
        return plus(7);
      case RepeatRule.weekdays:
        DateTime n = plus(1);
        while (n.weekday == DateTime.saturday || n.weekday == DateTime.sunday) {
          n = DateTime(n.year, n.month, n.day + 1, n.hour, n.minute);
        }
        return n;
    }
  }
}
