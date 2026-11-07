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
  });

  /// The title with the recognised words removed.
  final String title;

  /// Calendar day (time of day ignored).
  final DateTime? date;
  final int? hour;
  final int? minute;
  final TaskCategory? category;
  final RepeatRule? repeat;

  bool get hasTime => hour != null;

  bool get found =>
      date != null || hasTime || category != null || repeat != null;

  @override
  List<Object?> get props =>
      <Object?>[title, date, hour, minute, category, repeat];
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

    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime plus(int days) =>
        DateTime(today.year, today.month, today.day + days);

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

    // A time with no day means the next time it happens.
    if (date == null && hour != null) {
      final DateTime candidate =
          DateTime(today.year, today.month, today.day, hour, minute ?? 0);
      date = candidate.isAfter(now) ? today : plus(1);
    }

    final String title = text
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

    return SmartInput(
      title: title,
      date: date,
      hour: hour,
      minute: minute,
      category: category,
      repeat: repeat,
    );
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
