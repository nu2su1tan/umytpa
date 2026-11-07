import 'dart:math' as math;

/// How the app talks: close friend, calm assistant, or strict coach.
enum CopyTone { friendly, calm, coach }

/// All the "voice" lines of the Tracker for one language and tone.
///
/// Phrases may contain `{n}` (replaced by ", Name" or nothing), `{N}`
/// ("Name, " or nothing) and the placeholders each field documents.
class CopyPack {
  const CopyPack({
    required this.lang,
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.night,
    required this.comeback,
    required this.monday,
    required this.friday,
    required this.cheers,
    required this.finalCheers,
    required this.empty,
    required this.overdueTitle,
    required this.overdueNudge,
    required this.rescueBanner,
    required this.rescueAction,
    required this.emptyTitle,
    required this.emptyBody,
    required this.todayNothing,
    required this.todayAllDone,
    required this.streakLost,
    required this.streakNotes,
    required this.recapMore,
    required this.recapSame,
    required this.recapLess,
    required this.recapFirst,
    required this.reminderTitles,
    required this.reminderBody,
    required this.alarmTitles,
    required this.focusDone,
  });

  final String lang;
  final List<String> morning;
  final List<String> afternoon;
  final List<String> evening;
  final List<String> night;
  final List<String> comeback;
  final List<String> monday;
  final List<String> friday;

  /// Toast after ticking a task.
  final List<String> cheers;

  /// Toast after ticking the last task of the day.
  final List<String> finalCheers;

  /// Lines for an empty day.
  final List<String> empty;
  final String overdueTitle;
  final String overdueNudge;

  /// Contains `{count}`.
  final String rescueBanner;
  final String rescueAction;
  final String emptyTitle;
  final String emptyBody;
  final String todayNothing;
  final String todayAllDone;
  final String streakLost;

  /// Streak length threshold -> line (`{count}` allowed).
  final Map<int, String> streakNotes;

  /// Weekly recap lines: `{count}` finished, `{diff}` difference.
  final List<String> recapMore;
  final List<String> recapSame;
  final List<String> recapLess;
  final List<String> recapFirst;

  /// Notification titles; `{when}` is "in 5 minutes" etc.
  final List<String> reminderTitles;

  /// `{title}` and `{time}`.
  final String reminderBody;
  final List<String> alarmTitles;
  final String focusDone;

  static final math.Random _random = math.Random();
  static final Map<int, int> _last = <int, int>{};

  static String _who(String s, String? name) {
    final String? n = (name == null || name.trim().isEmpty) ? null : name.trim();
    return s
        .replaceAll('{n}', n == null ? '' : ', $n')
        .replaceAll('{N}', n == null ? '' : '$n, ')
        .replaceFirstMapped(
          RegExp(r'^[a-zа-яё]'),
          (Match m) => m.group(0)!.toUpperCase(),
        );
  }

  /// Same pick for the same [seed]; used where the text should be stable.
  static String _stable(List<String> list, int seed) =>
      list[seed.abs() % list.length];

  /// A random pick that avoids repeating the previous one for this [key].
  static String _fresh(List<String> list, int key) {
    if (list.length == 1) {
      return list.first;
    }
    int i = _random.nextInt(list.length);
    if (i == _last[key]) {
      i = (i + 1) % list.length;
    }
    _last[key] = i;
    return list[i];
  }

  static int _daySeed(DateTime d) =>
      d.year * 400 + d.difference(DateTime(d.year)).inDays;

  /// The greeting for [now]. [comeback] wins, then night, Monday/Friday, and
  /// finally the time of day.
  String greeting({
    required DateTime now,
    String? name,
    bool comeback = false,
  }) {
    final List<String> pool;
    if (comeback) {
      pool = this.comeback;
    } else if (now.hour < 5) {
      pool = night;
    } else if (now.weekday == DateTime.monday && now.hour < 17) {
      pool = monday;
    } else if (now.weekday == DateTime.friday && now.hour >= 17) {
      pool = friday;
    } else if (now.hour < 12) {
      pool = morning;
    } else if (now.hour < 17) {
      pool = afternoon;
    } else {
      pool = evening;
    }
    return _who(_stable(pool, _daySeed(now) + now.hour ~/ 6), name);
  }

  String cheer({String? name, bool last = false}) => _who(
        _fresh(last ? finalCheers : cheers, last ? 2 : 1),
        name,
      );

  String emptyLine(DateTime now, {String? name}) =>
      _who(_stable(empty, _daySeed(now)), name);

  String rescueText(int count) =>
      rescueBanner.replaceAll('{count}', '$count');

  /// The line for a streak of [days], or `null` for no streak.
  String? streakNote(int days) {
    if (days <= 0) {
      return null;
    }
    final List<int> keys = streakNotes.keys.toList()..sort();
    int? best;
    for (final int k in keys) {
      if (days >= k) {
        best = k;
      }
    }
    return best == null
        ? null
        : streakNotes[best]!.replaceAll('{count}', '$days');
  }

  String recap({required int count, required int previous}) {
    final int diff = (count - previous).abs();
    final List<String> pool = previous == 0
        ? recapFirst
        : count > previous
            ? recapMore
            : count == previous
                ? recapSame
                : recapLess;
    return _stable(pool, count + previous)
        .replaceAll('{count}', '$count')
        .replaceAll('{diff}', '$diff');
  }

  /// "in 5 minutes" / "через 5 минут".
  String when(Duration d) {
    final int minutes = d.inMinutes;
    if (lang == 'ru') {
      if (minutes <= 0) {
        return 'прямо сейчас';
      }
      if (minutes % 1440 == 0) {
        final int n = minutes ~/ 1440;
        return 'через $n ${_ru(n, 'день', 'дня', 'дней')}';
      }
      if (minutes % 60 == 0) {
        final int n = minutes ~/ 60;
        return 'через $n ${_ru(n, 'час', 'часа', 'часов')}';
      }
      return 'через $minutes ${_ru(minutes, 'минуту', 'минуты', 'минут')}';
    }
    if (minutes <= 0) {
      return 'right now';
    }
    if (minutes % 1440 == 0) {
      final int n = minutes ~/ 1440;
      return 'in $n ${n == 1 ? 'day' : 'days'}';
    }
    if (minutes % 60 == 0) {
      final int n = minutes ~/ 60;
      return 'in $n ${n == 1 ? 'hour' : 'hours'}';
    }
    return 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }

  static String _ru(int n, String one, String few, String many) {
    final int m100 = n % 100;
    final int m10 = n % 10;
    if (m100 >= 11 && m100 <= 14) {
      return many;
    }
    if (m10 == 1) {
      return one;
    }
    return m10 >= 2 && m10 <= 4 ? few : many;
  }

  /// Notification copy for the "before the deadline" reminder. [seed] keeps a
  /// task's wording stable between reschedules.
  ({String title, String body}) reminder({
    required String taskTitle,
    required String time,
    required Duration before,
    required int seed,
    String? name,
  }) {
    return (
      title: _who(
        _stable(reminderTitles, seed).replaceAll('{when}', when(before)),
        name,
      ),
      body: reminderBody
          .replaceAll('{title}', taskTitle)
          .replaceAll('{time}', time),
    );
  }

  ({String title, String body}) alarm({
    required String taskTitle,
    required int seed,
    String? name,
  }) {
    return (title: _who(_stable(alarmTitles, seed), name), body: taskTitle);
  }

  static CopyPack of(String languageCode, CopyTone tone) {
    final bool ru = languageCode == 'ru';
    return switch (tone) {
      CopyTone.friendly => ru ? _ruFriendly : _enFriendly,
      CopyTone.calm => ru ? _ruCalm : _enCalm,
      CopyTone.coach => ru ? _ruCoach : _enCoach,
    };
  }
}

const CopyPack _ruFriendly = CopyPack(
  lang: 'ru',
  morning: <String>[
    'Утречко{n} ☀️',
    'Доброе утро{n}, погнали',
    'Вставай{n}, дела не ждут',
  ],
  afternoon: <String>[
    'Как день{n}, огонь?',
    'Привет{n}, как настрой?',
    'Держим темп{n}',
  ],
  evening: <String>[
    'Добрый вечерок{n} 🌙',
    'Вечер{n}, закрываем хвосты',
    'Как прошёл день{n}?',
  ],
  night: <String>[
    'Чего не спишь{n}? 🌙',
    'Ночной режим{n} 🌙',
    'Ночь на дворе{n}',
  ],
  comeback: <String>[
    'Ну наконец-то{n}, я скучал 👀',
    '{N}ты вернулся! 🔥',
    'С возвращением{n}!',
  ],
  monday: <String>[
    'Понедельник{n}, погнали 🚀',
    'Новая неделя{n} 🚀',
  ],
  friday: <String>[
    'Пятница{n}! Добиваем 🎉',
    'Пятница{n}, финальный рывок',
  ],
  cheers: <String>[
    'Красава 🔥',
    'Ещё одна в копилку ✅',
    'Ну ты даёшь!',
    'Чистая работа 👌',
    'Так держать{n}!',
    'Минус одна, ты в потоке',
  ],
  finalCheers: <String>[
    'Всё на сегодня закрыл{n} — ты огонь! 🔥',
    'Ноль хвостов! Можно и чилл 😎',
    'Вот это день{n}! Всё сделано 🎉',
  ],
  empty: <String>[
    'Чилль-режим включён 😎',
    'Идеальный момент записать мечту на завтра',
    'Ни одного дедлайна — красота',
    'Свободен как ветер{n}',
  ],
  overdueTitle: 'Горит 🔥',
  overdueNudge: 'Эти задачки заждались тебя',
  rescueBanner: 'Накопилось просроченных: {count}. Не парься, бывает.',
  rescueAction: 'Перенести всё на завтра',
  emptyTitle: 'Тут пока пусто',
  emptyBody: 'Накидай первую задачку',
  todayNothing: 'На сегодня тишина — чилль 😎',
  todayAllDone: 'Всё закрыл — ты огонь! 🔥',
  streakLost: 'Серия сорвалась — бывает. Начнём заново, я с тобой 💪',
  streakNotes: <int, String>{
    1: 'Первый день — поехали',
    3: '{count} дня подряд — разгоняемся 🚀',
    7: 'Неделя огня — не сломай 🔥',
    14: 'Две недели! Это уже привычка',
    30: '{count} дней — ты машина',
  },
  recapMore: <String>[
    'За неделю закрыл {count} — это на {diff} больше, чем в прошлую 🔥',
  ],
  recapSame: <String>['За неделю закрыл {count} — ровно как в прошлую, стабильно'],
  recapLess: <String>[
    'За неделю закрыл {count} — на {diff} меньше, зато впереди новая неделя',
  ],
  recapFirst: <String>['За неделю закрыл {count}. Для старта огонь!'],
  reminderTitles: <String>[
    'Эй{n}, дедлайн {when} ⏰',
    'Напоминаю по-братски: дедлайн {when}',
    'Не забыл? Дедлайн {when}',
  ],
  reminderBody: '«{title}» · до {time}',
  alarmTitles: <String>[
    'Время вышло, погнали! ⏰',
    'Дедлайн настал!',
    'Тик-так — время пришло',
  ],
  focusDone: 'Красава, сессия закрыта!',
);

const CopyPack _ruCalm = CopyPack(
  lang: 'ru',
  morning: <String>['Доброе утро{n}', 'Начнём спокойно{n}'],
  afternoon: <String>[
    'Добрый день{n}',
    'Спокойного дня{n}',
  ],
  evening: <String>[
    'Добрый вечер{n}',
    'Время подвести итоги{n}',
  ],
  night: <String>[
    'Уже поздно{n}',
    'Пора отдохнуть{n}',
  ],
  comeback: <String>[
    'Рады видеть{n}',
    'С возвращением{n}',
  ],
  monday: <String>['Понедельник{n}. Шаг за шагом'],
  friday: <String>['Завершим неделю{n}'],
  cheers: <String>['Готово', 'Отлично', 'Хорошая работа', 'Шаг сделан'],
  finalCheers: <String>[
    'Все дела на сегодня выполнены. Хорошая работа{n}',
    'На сегодня всё. Можно отдохнуть',
  ],
  empty: <String>[
    'Сегодня без срочных дел',
    'Спокойный день — можно спланировать завтра',
  ],
  overdueTitle: 'Просрочено',
  overdueNudge: 'Эти задачи ждут внимания',
  rescueBanner: 'Просроченных задач: {count}. Их можно спокойно перенести.',
  rescueAction: 'Перенести на завтра',
  emptyTitle: 'Пока нет задач',
  emptyBody: 'Добавьте первую',
  todayNothing: 'На сегодня ничего не запланировано',
  todayAllDone: 'Всё выполнено. Хорошая работа!',
  streakLost: 'Серия прервалась. Это нормально — начните заново',
  streakNotes: <int, String>{
    1: 'Первый день',
    3: '{count} дня подряд',
    7: 'Неделя подряд',
    14: 'Две недели подряд',
    30: '{count} дней подряд',
  },
  recapMore: <String>[
    'За неделю выполнено задач: {count}. Это на {diff} больше, чем раньше',
  ],
  recapSame: <String>['За неделю выполнено задач: {count}, как и на прошлой'],
  recapLess: <String>[
    'За неделю выполнено задач: {count}, на {diff} меньше. Это нормально',
  ],
  recapFirst: <String>['За неделю выполнено задач: {count}. Хорошее начало'],
  reminderTitles: <String>['Напоминание: срок {when}'],
  reminderBody: '{title} · до {time}',
  alarmTitles: <String>['Срок наступил'],
  focusDone: 'Сессия завершена',
);

const CopyPack _ruCoach = CopyPack(
  lang: 'ru',
  morning: <String>[
    'Подъём{n}!',
    'Начинай с главного{n}',
  ],
  afternoon: <String>[
    'Не сбавляй темп{n}',
    'Что уже сделано{n}?',
  ],
  evening: <String>[
    'Закрывай остатки{n}',
    'Подведи итоги{n}',
  ],
  night: <String>[
    'Пора спать{n}',
    'Хватит на сегодня{n}',
  ],
  comeback: <String>[
    'Возвращайся в ритм{n}',
    'Начинаем сейчас{n}',
  ],
  monday: <String>['Задай темп{n}'],
  friday: <String>['Закрой неделю сильно{n}'],
  cheers: <String>['Сделано. Дальше.', 'Так и надо.', 'Следующая.', 'Результат есть.'],
  finalCheers: <String>[
    'План на день выполнен{n}. Так держать',
    'Всё закрыто. Это результат дисциплины',
  ],
  empty: <String>[
    'Задач нет — запланируй завтра заранее',
    'Свободное время — используй его с умом',
  ],
  overdueTitle: 'Просрочено — разберись',
  overdueNudge: 'Это надо сделать, а не откладывать',
  rescueBanner: 'Просрочено: {count}. Пора навести порядок.',
  rescueAction: 'Перенести на завтра и закрыть',
  emptyTitle: 'План пуст',
  emptyBody: 'Добавь первую задачу',
  todayNothing: 'План на сегодня пуст — исправь это',
  todayAllDone: 'План выполнен. Отличная дисциплина',
  streakLost: 'Серия прервана. Возвращайся — без оправданий',
  streakNotes: <int, String>{
    1: 'День первый. Начало положено',
    3: '{count} дня подряд. Держи ритм',
    7: 'Неделя дисциплины',
    14: 'Две недели. Это система',
    30: '{count} дней. Железная дисциплина',
  },
  recapMore: <String>['За неделю закрыто {count}, на {diff} больше. Растёшь'],
  recapSame: <String>['За неделю закрыто {count}, столько же. Пора поднять планку'],
  recapLess: <String>['За неделю закрыто {count}, на {diff} меньше. Подтянись'],
  recapFirst: <String>['За неделю закрыто {count}. Теперь только лучше'],
  reminderTitles: <String>['Срок {when}. Приступай'],
  reminderBody: '{title} · до {time}',
  alarmTitles: <String>['Время вышло. Что сделано?'],
  focusDone: 'Сессия закрыта. Результат засчитан',
);

const CopyPack _enFriendly = CopyPack(
  lang: 'en',
  morning: <String>['Morning{n} ☀️', 'Rise and shine{n}', 'Good morning{n}, let’s go'],
  afternoon: <String>[
    'Hey{n}, how’s the day going?',
    'Afternoon{n} — keep the pace',
  ],
  evening: <String>[
    'Evening{n} 🌙',
    'Evening{n}, wrap it up',
  ],
  night: <String>[
    'Still up{n}? 🌙',
    'It’s late{n} 🌙',
  ],
  comeback: <String>[
    'Finally{n}, I missed you 👀',
    'You’re back{n}! 🔥',
  ],
  monday: <String>['Monday{n}, let’s go 🚀'],
  friday: <String>['Friday{n}! Finish strong 🎉'],
  cheers: <String>[
    'Nailed it 🔥',
    'One more in the bag ✅',
    'Look at you go!',
    'Clean work 👌',
    'Keep it up{n}!',
  ],
  finalCheers: <String>[
    'Everything’s done{n} — you’re on fire! 🔥',
    'Zero left! Time to chill 😎',
  ],
  empty: <String>[
    'Chill mode: on 😎',
    'Perfect moment to plan tomorrow',
    'No deadlines — beautiful',
  ],
  overdueTitle: 'On fire 🔥',
  overdueNudge: 'These have been waiting for you',
  rescueBanner: '{count} overdue — no stress, it happens.',
  rescueAction: 'Move everything to tomorrow',
  emptyTitle: 'Nothing here yet',
  emptyBody: 'Throw in your first task',
  todayNothing: 'Nothing planned today — chill 😎',
  todayAllDone: 'All done — you’re on fire! 🔥',
  streakLost: 'Streak broke — it happens. Let’s start over 💪',
  streakNotes: <int, String>{
    1: 'Day one — let’s go',
    3: '{count} days — warming up 🚀',
    7: 'A week on fire 🔥',
    14: 'Two weeks! That’s a habit',
    30: '{count} days — you’re a machine',
  },
  recapMore: <String>['This week you finished {count} — {diff} more than last week 🔥'],
  recapSame: <String>['This week you finished {count} — same as last week, steady'],
  recapLess: <String>[
    'This week you finished {count} — {diff} fewer, but a new week is coming',
  ],
  recapFirst: <String>['This week you finished {count}. Great start!'],
  reminderTitles: <String>[
    'Hey{n}, deadline {when} ⏰',
    'Heads up: deadline {when}',
    'Not forgetting, right? Deadline {when}',
  ],
  reminderBody: '“{title}” · due {time}',
  alarmTitles: <String>[
    'Time’s up, let’s go! ⏰',
    'Deadline’s here!',
    'Tick-tock — it’s time',
  ],
  focusDone: 'Nice, session done!',
);

const CopyPack _enCalm = CopyPack(
  lang: 'en',
  morning: <String>['Good morning{n}', 'Let’s begin gently{n}'],
  afternoon: <String>['Good afternoon{n}', 'Steady does it{n}'],
  evening: <String>['Good evening{n}', 'Time to review the day'],
  night: <String>[
    'It’s late{n}',
    'Time to rest{n}',
  ],
  comeback: <String>[
    'Good to see you again{n}',
    'Welcome back{n}',
  ],
  monday: <String>['A new week{n}'],
  friday: <String>['Let’s wrap up{n}'],
  cheers: <String>['Done', 'Well done', 'Good work', 'One step taken'],
  finalCheers: <String>[
    'Everything for today is done. Good work{n}',
    'That’s all for today. Time to rest',
  ],
  empty: <String>[
    'No urgent tasks today',
    'A quiet day — a good time to plan tomorrow',
  ],
  overdueTitle: 'Overdue',
  overdueNudge: 'These tasks need your attention',
  rescueBanner: '{count} overdue tasks. They can be calmly moved.',
  rescueAction: 'Move to tomorrow',
  emptyTitle: 'No tasks yet',
  emptyBody: 'Add your first one',
  todayNothing: 'Nothing planned for today',
  todayAllDone: 'All done. Good work!',
  streakLost: 'The streak ended. That’s okay — start again',
  streakNotes: <int, String>{
    1: 'First day',
    3: '{count} days in a row',
    7: 'A week in a row',
    14: 'Two weeks in a row',
    30: '{count} days in a row',
  },
  recapMore: <String>['This week you completed {count} tasks, {diff} more than before'],
  recapSame: <String>['This week you completed {count} tasks, same as last week'],
  recapLess: <String>['This week you completed {count} tasks, {diff} fewer. That’s fine'],
  recapFirst: <String>['This week you completed {count} tasks. A good start'],
  reminderTitles: <String>['Reminder: due {when}'],
  reminderBody: '{title} · due {time}',
  alarmTitles: <String>['The deadline has arrived'],
  focusDone: 'Session complete',
);

const CopyPack _enCoach = CopyPack(
  lang: 'en',
  morning: <String>['Up{n}. Plan time', 'Start with what matters{n}'],
  afternoon: <String>['Midday{n}. Don’t slow down', 'What’s done so far{n}?'],
  evening: <String>['Evening{n}. Close what’s left', 'Clear the backlog{n}'],
  night: <String>[
    'Sleep is discipline{n}',
    'Enough for today{n}',
  ],
  comeback: <String>[
    'Back in rhythm{n}',
    'Start now{n}',
  ],
  monday: <String>['Set the pace{n}'],
  friday: <String>['Close the week strong{n}'],
  cheers: <String>['Done. Next.', 'That’s how it’s done.', 'Next one.', 'Result delivered.'],
  finalCheers: <String>[
    'Today’s plan is complete{n}. Keep going',
    'Everything closed. That’s discipline.',
  ],
  empty: <String>[
    'No tasks — plan tomorrow in advance',
    'Free time — use it wisely',
  ],
  overdueTitle: 'Overdue — deal with it',
  overdueNudge: 'These need doing, not postponing',
  rescueBanner: 'Overdue: {count}. Time to restore order.',
  rescueAction: 'Move to tomorrow and finish',
  emptyTitle: 'The plan is empty',
  emptyBody: 'Add your first task',
  todayNothing: 'Nothing planned today — fix that',
  todayAllDone: 'Plan complete. Excellent discipline',
  streakLost: 'Streak broken. Come back — no excuses',
  streakNotes: <int, String>{
    1: 'Day one. A start is made',
    3: '{count} days in a row. Hold the rhythm',
    7: 'A week of discipline',
    14: 'Two weeks. That’s a system',
    30: '{count} days. Iron discipline',
  },
  recapMore: <String>['{count} closed this week, {diff} more. You’re growing'],
  recapSame: <String>['{count} closed this week, same as before. Raise the bar'],
  recapLess: <String>['{count} closed this week, {diff} fewer. Step it up'],
  recapFirst: <String>['{count} closed this week. Only up from here'],
  reminderTitles: <String>['Due {when}. Get started'],
  reminderBody: '{title} · due {time}',
  alarmTitles: <String>['Time’s up. What’s done?'],
  focusDone: 'Session closed. Result counted',
);
