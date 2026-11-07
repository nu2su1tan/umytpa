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
  await initializeDateFormatting();
  await configureDependencies();

  final Result<void> reschedule =
      await getIt<RescheduleAllReminders>()();
  if (reschedule case Err(:final failure)) {
    developer.log(
      'Failed to reschedule reminders on startup',
      name: 'main',
      error: failure,
    );
  }

  runApp(const TaskTrackerApp());
}
