import 'package:flutter_test/flutter_test.dart';
import 'package:umytpa/core/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils.nextRoundedHour', () {
    test('from mid-hour', () {
      expect(
        DateTimeUtils.nextRoundedHour(DateTime(2026, 10, 30, 14, 30)),
        DateTime(2026, 10, 30, 15),
      );
    });

    test('from exact hour goes to next hour', () {
      expect(
        DateTimeUtils.nextRoundedHour(DateTime(2026, 10, 30, 14)),
        DateTime(2026, 10, 30, 15),
      );
    });

    test('crosses midnight', () {
      expect(
        DateTimeUtils.nextRoundedHour(DateTime(2026, 10, 30, 23, 10)),
        DateTime(2026, 10, 31),
      );
    });
  });

  group('DateTimeUtils.startOfDay', () {
    test('strips time components', () {
      expect(
        DateTimeUtils.startOfDay(DateTime(2026, 10, 30, 15, 45, 12)),
        DateTime(2026, 10, 30),
      );
    });
  });
}
