import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Pushes the Tracker summary to the Android home-screen widget.
abstract final class TaskWidgetSync {
  static const String androidName = 'kz.nu2su1tan.umytpa.TaskWidgetProvider';

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static String? _last;

  static Future<void> push({
    required String title,
    required String count,
    required String next,
    required String nextTime,
  }) async {
    if (!isSupported) {
      return;
    }
    final String signature = '$title|$count|$next|$nextTime';
    if (signature == _last) {
      return;
    }
    _last = signature;
    try {
      await HomeWidget.saveWidgetData<String>('task_widget_title', title);
      await HomeWidget.saveWidgetData<String>('task_widget_count', count);
      await HomeWidget.saveWidgetData<String>('task_widget_next', next);
      await HomeWidget.saveWidgetData<String>('task_widget_next_time', nextTime);
      await HomeWidget.updateWidget(qualifiedAndroidName: androidName);
    } on PlatformException catch (error) {
      debugPrint('Task widget update failed: $error');
    }
  }
}
