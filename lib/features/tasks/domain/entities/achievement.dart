/// Badges earned for finishing tasks, keeping streaks and focusing.
enum Achievement {
  firstDone(done: 1),
  tenDone(done: 10),
  fiftyDone(done: 50),
  hundredDone(done: 100),
  streak3(streak: 3),
  streak7(streak: 7),
  streak30(streak: 30),
  focusHour(focusMinutes: 60),
  focusTenHours(focusMinutes: 600);

  const Achievement({this.done = 0, this.streak = 0, this.focusMinutes = 0});

  final int done;
  final int streak;
  final int focusMinutes;

  bool isUnlocked({
    required int totalDone,
    required int bestStreak,
    required int totalFocusMinutes,
  }) {
    if (done > 0) {
      return totalDone >= done;
    }
    if (streak > 0) {
      return bestStreak >= streak;
    }
    return totalFocusMinutes >= focusMinutes;
  }
}
