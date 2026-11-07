import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/core/copy/copy_pack.dart';

void main() {
  // Thursday morning.
  final DateTime thursday = DateTime(2026, 11, 5, 10);

  test('every language and tone has all the lines', () {
    for (final String lang in <String>['ru', 'en']) {
      for (final CopyTone tone in CopyTone.values) {
        final CopyPack p = CopyPack.of(lang, tone);
        for (final List<String> list in <List<String>>[
          p.morning,
          p.afternoon,
          p.evening,
          p.night,
          p.comeback,
          p.monday,
          p.friday,
          p.cheers,
          p.finalCheers,
          p.empty,
          p.recapMore,
          p.recapSame,
          p.recapLess,
          p.recapFirst,
          p.reminderTitles,
          p.alarmTitles,
        ]) {
          expect(list, isNotEmpty, reason: '$lang/$tone');
        }
      }
    }
  });

  test('greetings stay short enough for the big title', () {
    final List<String> tooLong = <String>[];
    for (final String lang in <String>['ru', 'en']) {
      for (final CopyTone tone in CopyTone.values) {
        final CopyPack p = CopyPack.of(lang, tone);
        for (final String line in <String>[
          ...p.morning,
          ...p.afternoon,
          ...p.evening,
          ...p.night,
          ...p.comeback,
          ...p.monday,
          ...p.friday,
        ]) {
          final String shown = line
              .replaceAll('{n}', ', Вовлер')
              .replaceAll('{N}', 'Вовлер, ');
          if (shown.length > 34) {
            tooLong.add(shown);
          }
        }
      }
    }
    expect(tooLong, isEmpty);
  });

  test('greeting uses the name, or drops it cleanly', () {
    final CopyPack p = CopyPack.of('en', CopyTone.calm);
    final String withName = p.greeting(now: thursday, name: 'Miras');
    final String without = p.greeting(now: thursday);
    expect(withName, contains('Miras'));
    expect(without, isNot(contains('{n}')));
    expect(without, isNot(contains(', .')));
  });

  test('greeting picks the night slot after midnight', () {
    final CopyPack p = CopyPack.of('en', CopyTone.coach);
    final String g = p.greeting(now: DateTime(2026, 11, 5, 2));
    expect(
      g.contains('Sleep') || g.contains('Enough for today'),
      isTrue,
      reason: g,
    );
  });

  test('comeback wins over the time of day', () {
    final CopyPack p = CopyPack.of('en', CopyTone.friendly);
    final String g = p.greeting(now: thursday, comeback: true);
    expect(g.contains('missed') || g.contains('back'), isTrue, reason: g);
  });

  test('cheers never repeat twice in a row', () {
    final CopyPack p = CopyPack.of('en', CopyTone.friendly);
    String? prev;
    for (int i = 0; i < 40; i++) {
      final String c = p.cheer();
      expect(c, isNot(prev));
      prev = c;
    }
  });

  test('streak notes pick the closest threshold', () {
    final CopyPack p = CopyPack.of('en', CopyTone.friendly);
    expect(p.streakNote(0), isNull);
    expect(p.streakNote(1), 'Day one — let’s go');
    expect(p.streakNote(5), contains('5 days'));
    expect(p.streakNote(8), contains('week'));
  });

  test('weekly recap compares with the previous week', () {
    final CopyPack p = CopyPack.of('en', CopyTone.friendly);
    expect(p.recap(count: 8, previous: 5), contains('3 more'));
    expect(p.recap(count: 3, previous: 5), contains('2 fewer'));
    expect(p.recap(count: 5, previous: 5), contains('same'));
    expect(p.recap(count: 4, previous: 0), contains('4'));
  });

  test('notification wording mentions when, and the task', () {
    final CopyPack ru = CopyPack.of('ru', CopyTone.friendly);
    final ({String title, String body}) r = ru.reminder(
      taskTitle: 'Лаба',
      time: '18:00',
      before: const Duration(minutes: 5),
      seed: 1,
    );
    expect(r.title, contains('через 5 минут'));
    expect(r.body, contains('Лаба'));
    expect(r.body, contains('18:00'));
    expect(ru.when(const Duration(hours: 2)), 'через 2 часа');
    expect(ru.when(const Duration(days: 1)), 'через 1 день');
  });
}
