import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/error/result.dart';
import 'features/reminders/domain/usecases/reschedule_all_reminders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  // Only the three languages the app ships, not all ~400 locales.
  await Future.wait(<Future<void>>[
    initializeDateFormatting('en'),
    initializeDateFormatting('ru'),
    initializeDateFormatting('kk'),
  ]);
  await configureDependencies();

  runApp(const TaskTrackerApp());

  // Restoring notifications can take a while with many tasks; do it after the
  // first frame is on its way instead of holding up startup.
  unawaited(_restoreReminders());
}

Future<void> _restoreReminders() async {
  final Result<void> reschedule = await getIt<RescheduleAllReminders>()();
  if (reschedule case Err(:final failure)) {
    developer.log(
      'Failed to reschedule reminders on startup',
      name: 'main',
      error: failure,
    );
  }
}
