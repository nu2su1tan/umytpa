import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/features/tasks/domain/usecases/parse_smart_input.dart';

void main() {
  // Wednesday 2026-11-04 12:00.
  final DateTime now = DateTime(2026, 11, 4, 12);

  test('relative minutes', () {
    final SmartInput s = SmartInputParser.parse('Позвонить маме через 20 минут', now: now);
    expect(s.title, 'Позвонить маме');
    expect(s.date, DateTime(2026, 11, 4));
    expect(s.hour, 12);
    expect(s.minute, 20);
  });

  test('relative hours in English', () {
    final SmartInput s = SmartInputParser.parse('Call mom in 2 hours', now: now);
    expect(s.title, 'Call mom');
    expect(s.hour, 14);
    expect(s.minute, 0);
  });

  test('"через час" and "через неделю"', () {
    expect(SmartInputParser.parse('Чай через час', now: now).hour, 13);
    final SmartInput w = SmartInputParser.parse('Отчёт через неделю', now: now);
    expect(w.date, DateTime(2026, 11, 11));
    expect(w.hasTime, isFalse);
  });

  test('part of day', () {
    final SmartInput s = SmartInputParser.parse('Зарядка завтра утром', now: now);
    expect(s.title, 'Зарядка');
    expect(s.date, DateTime(2026, 11, 5));
    expect(s.hour, 9);
    expect(SmartInputParser.parse('Кино вечером', now: now).hour, 19);
  });

  test('remind before', () {
    final SmartInput s =
        SmartInputParser.parse('Встреча завтра 18:00 за 15 минут', now: now);
    expect(s.title, 'Встреча');
    expect(s.remindBefore, const Duration(minutes: 15));
    expect(s.hour, 18);
    final SmartInput e =
        SmartInputParser.parse('Meeting at 18:00 30 min before', now: now);
    expect(e.remindBefore, const Duration(minutes: 30));
    expect(SmartInputParser.parse('Дело за час', now: now).remindBefore,
        const Duration(hours: 1));
  });
}
