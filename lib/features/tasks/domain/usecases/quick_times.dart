/// One-tap deadlines offered next to the title field.
enum QuickTimeKind { inOneHour, tonight, tomorrowMorning }

abstract final class QuickTimes {
  /// The chips worth showing at [now]: "this evening" disappears once it is
  /// nearly evening already.
  static List<QuickTimeKind> available(DateTime now) => <QuickTimeKind>[
    QuickTimeKind.inOneHour,
    if (now.hour < 18) QuickTimeKind.tonight,
    QuickTimeKind.tomorrowMorning,
  ];

  static DateTime resolve(QuickTimeKind kind, {required DateTime now}) {
    return switch (kind) {
      QuickTimeKind.inOneHour => DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      ).add(const Duration(hours: 1)),
      QuickTimeKind.tonight => DateTime(now.year, now.month, now.day, 19),
      QuickTimeKind.tomorrowMorning => DateTime(
        now.year,
        now.month,
        now.day + 1,
        9,
      ),
    };
  }
}
