import 'package:equatable/equatable.dart';

import '../entities/repeat_rule.dart';
import '../entities/task_category.dart';

/// What was recognised in a free-text task title ("Lab tomorrow 18:00 #study").
class SmartInput extends Equatable {
  const SmartInput({
    required this.title,
    this.date,
    this.hour,
    this.minute,
    this.category,
    this.repeat,
    this.remindBefore,
  });

  /// The title with the recognised words removed.
  final String title;

  /// Calendar day (time of day ignored).
  final DateTime? date;
  final int? hour;
  final int? minute;
  final TaskCategory? category;
  final RepeatRule? repeat;

  /// "remind 15 min before" / "за 15 минут".
  final Duration? remindBefore;

  bool get hasTime => hour != null;

  bool get found =>
      date != null ||
      hasTime ||
      category != null ||
      repeat != null ||
      remindBefore != null;

  @override
  List<Object?> get props =>
      <Object?>[title, date, hour, minute, category, repeat, remindBefore];
}

/// Understands dates, times, `#categories` and repeats in Russian and English.
abstract final class SmartInputParser {
  static const String _l = r'(?<![\p{L}\p{N}])';
  static const String _r = r'(?![\p{L}\p{N}])';

  static RegExp _re(String body) => RegExp(
        '$_l(?:$body)$_r',
        caseSensitive: false,
        unicode: true,
      );

  static final Map<TaskCategory, RegExp> _categories = <TaskCategory, RegExp>{
    TaskCategory.study: RegExp(
      r'#(?:учёба|учеба|учёбе|study|учеб\p{L}*)(?![\p{L}\p{N}])',
      caseSensitive: false,
      unicode: true,
    ),
    TaskCategory.work: RegExp(
      r'#(?:работа|работе|work)(?![\p{L}\p{N}])',
      caseSensitive: false,
      unicode: true,
    ),
    TaskCategory.personal: RegExp(
      r'#(?:личное|личный|personal|home|дом)(?![\p{L}\p{N}])',
      caseSensitive: false,
      unicode: true,
    ),
    TaskCategory.other: RegExp(
      r'#(?:другое|прочее|other)(?![\p{L}\p{N}])',
      caseSensitive: false,
      unicode: true,
    ),
  };

  static final RegExp _weekdaysRepeat =
      _re(r'по\s+будням|каждый\s+будний\s+день|every\s+weekday|weekdays');
  static final RegExp _dailyRepeat =
      _re(r'каждый\s+день|ежедневно|every\s*day|daily');
  static final RegExp _weeklyRepeat =
      _re(r'каждую\s+неделю|еженедельно|every\s+week|weekly');

  static final RegExp _afterTomorrow =
      _re(r'послезавтра|day\s+after\s+tomorrow');
  static final RegExp _tomorrow = _re('завтра|tomorrow');
  static final RegExp _today = _re('сегодня|today');
  static final RegExp _inDays = _re(r'через\s+(\d{1,2})\s+(?:дн\p{L}*|день)|in\s+(\d{1,2})\s+days?');

  static final List<(RegExp, int)> _weekdays = <(RegExp, int)>[
    (_re(r'(?:в\s+|on\s+)?(?:понедельник|пн|monday|mon)'), DateTime.monday),
    (_re(r'(?:во?\s+)?(?:вторник|вт|tuesday|tue)'), DateTime.tuesday),
    (_re(r'(?:в\s+)?(?:среду|среда|ср|wednesday|wed)'), DateTime.wednesday),
    (_re(r'(?:в\s+)?(?:четверг|чт|thursday|thu)'), DateTime.thursday),
    (_re(r'(?:в\s+)?(?:пятницу|пятница|пт|friday|fri)'), DateTime.friday),
    (_re(r'(?:в\s+)?(?:субботу|суббота|сб|saturday|sat)'), DateTime.saturday),
    (_re(r'(?:в\s+)?(?:воскресенье|вс|sunday|sun)'), DateTime.sunday),
  ];

  // "за 15 минут", "за час", "за полчаса", "15 min before".
  static final RegExp _remindBeforeRu = _re(
    r'за\s+(?:(\d{1,3})\s*(мин\p{L}*|м|час\p{L}*|ч|дн\p{L}*|день)|(полчаса|час))',
  );
  static final RegExp _remindBeforeEn = _re(
    r'(?:remind\s+me\s+)?(\d{1,3})\s*(min\p{L}*|hours?|hrs?|days?)\s+before',
  );

  // "через 20 минут", "через час", "in 2 hours", "in an hour".
  static final RegExp _inMinutesRu = _re(
    r'через\s+(?:(\d{1,3})\s*(мин\p{L}*|м|час\p{L}*|ч)|(полчаса|час|неделю))',
  );
  static final RegExp _inMinutesEn = _re(
    r'in\s+(?:(\d{1,3})\s*(min\p{L}*|hours?|hrs?|h)|(an\s+hour|half\s+an\s+hour|a\s+week))',
  );

  // Parts of the day, used only when no clock time was written.
  static final List<(RegExp, int)> _dayParts = <(RegExp, int)>[
    (_re(r'утром|in\s+the\s+morning|this\s+morning'), 9),
    (_re(r'днём|днем|in\s+the\s+afternoon'), 14),
    (_re(r'вечером|in\s+the\s+evening|this\s+evening'), 19),
    (_re(r'ночью|tonight'), 22),
  ];

  // "18:00", "at 6:15pm" and, only after a preposition, "в 18.30". A bare
  // "2.50" is a price or a version, not a time.
  static final RegExp _clock = RegExp(
    '$_l(?:(?:в|во|at|by|до|к)\\s+(\\d{1,2})[:.](\\d{2})|(\\d{1,2}):(\\d{2}))'
    '\\s*(am|pm)?$_r',
    caseSensitive: false,
    unicode: true,
  );
  // "в 9", "at 6 pm", "6pm"
  static final RegExp _hourOnly = RegExp(
    '$_l(?:(?:(?:в|во|at|by|к)\\s+(\\d{1,2})(?:\\s*(am|pm))?)|(?:(\\d{1,2})\\s*(am|pm)))$_r',
    caseSensitive: false,
    unicode: true,
  );

  static SmartInput parse(String input, {required DateTime now}) {
    String text = input;
    TaskCategory? category;
    RepeatRule? repeat;
    DateTime? date;
    int? hour;
    int? minute;

    String strip(RegExpMatch m) {
      return text.replaceRange(m.start, m.end, ' ');
    }

    for (final MapEntry<TaskCategory, RegExp> e in _categories.entries) {
      final RegExpMatch? m = e.value.firstMatch(text);
      if (m != null) {
        category = e.key;
        text = strip(m);
        break;
      }
    }

    for (final (RegExp re, RepeatRule rule) in <(RegExp, RepeatRule)>[
      (_weekdaysRepeat, RepeatRule.weekdays),
      (_dailyRepeat, RepeatRule.daily),
      (_weeklyRepeat, RepeatRule.weekly),
    ]) {
      final RegExpMatch? m = re.firstMatch(text);
      if (m != null) {
        repeat = rule;
        text = strip(m);
        break;
      }
    }

    Duration? remindBefore;
    for (final RegExp re in <RegExp>[_remindBeforeRu, _remindBeforeEn]) {
      final RegExpMatch? rm = re.firstMatch(text);
      if (rm == null) {
        continue;
      }
      final Duration? d = re == _remindBeforeRu
          ? _ruBefore(rm)
          : _unit(int.parse(rm.group(1)!), rm.group(2)!);
      if (d != null) {
        remindBefore = d;
        text = strip(rm);
        break;
      }
    }

    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime plus(int days) =>
        DateTime(today.year, today.month, today.day + days);

    // "in 20 minutes" fixes the exact moment, so no other date or time is
    // looked for.
    for (final RegExp re in <RegExp>[_inMinutesRu, _inMinutesEn]) {
      final RegExpMatch? rel = re.firstMatch(text);
      if (rel == null) {
        continue;
      }
      final String? word = rel.group(3)?.toLowerCase().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
      final Duration? d = word != null
          ? switch (word) {
              'полчаса' || 'half an hour' => const Duration(minutes: 30),
              'час' || 'an hour' => const Duration(hours: 1),
              _ => const Duration(days: 7),
            }
          : _unit(int.parse(rel.group(1)!), rel.group(2)!);
      if (d == null) {
        continue;
      }
      final DateTime at = now.add(d);
      final bool days = d.inDays >= 1;
      text = strip(rel);
      return SmartInput(
        title: _clean(text),
        date: DateTime(at.year, at.month, at.day),
        hour: days ? null : at.hour,
        minute: days ? null : at.minute,
        category: category,
        repeat: repeat,
        remindBefore: remindBefore,
      );
    }

    RegExpMatch? m = _afterTomorrow.firstMatch(text);
    if (m != null) {
      date = plus(2);
      text = strip(m);
    } else if ((m = _tomorrow.firstMatch(text)) != null) {
      date = plus(1);
      text = strip(m!);
    } else if ((m = _today.firstMatch(text)) != null) {
      date = today;
      text = strip(m!);
    } else if ((m = _inDays.firstMatch(text)) != null) {
      date = plus(int.parse(m!.group(1) ?? m.group(2)!));
      text = strip(m);
    } else {
      for (final (RegExp re, int weekday) in _weekdays) {
        final RegExpMatch? wm = re.firstMatch(text);
        if (wm != null) {
          int delta = (weekday - today.weekday) % 7;
          if (delta == 0) {
            delta = 7;
          }
          date = plus(delta);
          text = strip(wm);
          break;
        }
      }
    }

    final RegExpMatch? clock = _clock.firstMatch(text);
    if (clock != null) {
      final int? h = _to24(
        int.parse(clock.group(1) ?? clock.group(3)!),
        clock.group(5),
      );
      final int mi = int.parse(clock.group(2) ?? clock.group(4)!);
      if (h != null && mi < 60) {
        hour = h;
        minute = mi;
        text = strip(clock);
      }
    }
    if (hour == null) {
      final RegExpMatch? ho = _hourOnly.firstMatch(text);
      if (ho != null) {
        final int raw = int.parse(ho.group(1) ?? ho.group(3)!);
        final String? ap = ho.group(2) ?? ho.group(4);
        final int? h = _to24(raw, ap);
        if (h != null) {
          hour = h;
          minute = 0;
          text = strip(ho);
        }
      }
    }

    if (hour == null) {
      for (final (RegExp re, int h) in _dayParts) {
        final RegExpMatch? dp = re.firstMatch(text);
        if (dp != null) {
          hour = h;
          minute = 0;
          text = strip(dp);
          break;
        }
      }
    }

    // A time with no day means the next time it happens.
    if (date == null && hour != null) {
      final DateTime candidate =
          DateTime(today.year, today.month, today.day, hour, minute ?? 0);
      date = candidate.isAfter(now) ? today : plus(1);
    }

    return SmartInput(
      title: _clean(text),
      date: date,
      hour: hour,
      minute: minute,
      category: category,
      repeat: repeat,
      remindBefore: remindBefore,
    );
  }

  static String _clean(String text) => text
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(
        RegExp(
          r'(?:^|\s)(?:в|во|на|к|до|at|on|by|to)\s*$',
          caseSensitive: false,
          unicode: true,
        ),
        '',
      )
      .trim();

  static Duration? _ruBefore(RegExpMatch m) {
    final String? word = m.group(3)?.toLowerCase();
    if (word != null) {
      return word == 'час' ? const Duration(hours: 1) : const Duration(minutes: 30);
    }
    return _unit(int.parse(m.group(1)!), m.group(2)!);
  }

  static Duration? _unit(int n, String unit) {
    final String u = unit.toLowerCase();
    if (n <= 0) {
      return null;
    }
    if (u.startsWith('мин') || u == 'м' || u.startsWith('min')) {
      return Duration(minutes: n);
    }
    if (u.startsWith('час') || u == 'ч' || u.startsWith('hour') ||
        u.startsWith('hr') || u == 'h') {
      return Duration(hours: n);
    }
    if (u.startsWith('дн') || u == 'день' || u.startsWith('day')) {
      return Duration(days: n);
    }
    return null;
  }

  static int? _to24(int h, String? ampm) {
    if (ampm == null) {
      return h <= 23 ? h : null;
    }
    if (h < 1 || h > 12) {
      return null;
    }
    final bool pm = ampm.toLowerCase() == 'pm';
    return pm ? (h % 12) + 12 : h % 12;
  }
}
