/// Represents granular permission states across local notifications, exact alarms,
/// and full-screen intents.
sealed class ReminderPermissionStatus {
  const ReminderPermissionStatus();

  static const ReminderPermissionStatus granted = ReminderPermissionGranted();
  static const ReminderPermissionStatus notificationsDenied =
      ReminderNotificationsDenied();
  static const ReminderPermissionStatus exactAlarmsMissing =
      ReminderExactAlarmsMissing();
  static const ReminderPermissionStatus fullScreenMissing =
      ReminderFullScreenMissing();

  bool get isGranted => this is ReminderPermissionGranted;
}

final class ReminderPermissionGranted extends ReminderPermissionStatus {
  const ReminderPermissionGranted();
}

final class ReminderNotificationsDenied extends ReminderPermissionStatus {
  const ReminderNotificationsDenied();
}

final class ReminderExactAlarmsMissing extends ReminderPermissionStatus {
  const ReminderExactAlarmsMissing();
}

final class ReminderFullScreenMissing extends ReminderPermissionStatus {
  const ReminderFullScreenMissing();
}

/// Identifies which special permission needs an explanatory rationale dialog
/// in the presentation layer before navigating the user to system settings.
enum ReminderPermissionRationale {
  exactAlarms,
  fullScreenIntent,
}
