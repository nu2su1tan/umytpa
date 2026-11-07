import 'package:intl/intl.dart';

import '../../../../core/utils/date_time_utils.dart';

abstract final class TaskDateFormat {
  static String dueLabel(DateTime dueAt, {required DateTime now}) {
    final DateTime local = dueAt.toLocal();
    final String time = DateFormat.Hm().format(local);

    if (DateTimeUtils.isSameCalendarDay(local, now)) {
      return time;
    }

    final DateTime yesterday = DateTimeUtils.startOfDay(now)
        .subtract(const Duration(days: 1));
    if (DateTimeUtils.isSameCalendarDay(local, yesterday)) {
      return 'Yesterday, $time';
    }

    if (DateTimeUtils.isSameCalendarDay(
      local,
      DateTimeUtils.startOfTomorrow(now),
    )) {
      return 'Tomorrow, $time';
    }

    return '${DateFormat('d MMM').format(local)}, $time';
  }
}
