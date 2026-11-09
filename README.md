# Umytpa

Task tracker and weekend timer for iOS and Android. Tasks, reminders, alarms and a live countdown to your days off. Offline-first: all data stays on your device, no account needed.

<p align="center">
  <img src="docs/screenshots/01.png" width="30%" alt="Weekend countdown">
  <img src="docs/screenshots/02.png" width="30%" alt="Tasks">
  <img src="docs/screenshots/03.png" width="30%" alt="Daily progress and streak">
</p>
<p align="center">
  <img src="docs/screenshots/04.png" width="30%" alt="Focus timer">
  <img src="docs/screenshots/05.png" width="30%" alt="Statistics">
  <img src="docs/screenshots/06.png" width="30%" alt="Personalization">
</p>

## Features

- **Weekend countdown** with a live timer to your next day off, a week strip and country holidays.
- **Tasks** with categories, due dates, repeats and reminders ("45 min before", "1h before").
- **Real alarms** on iOS 26 (AlarmKit) and a custom alarm sound (MP3, M4A, WAV, AIFF, CAF).
- **Focus timer** for deep work sessions.
- **Streaks, statistics and badges.**
- **Personal tone**: friendly, calm or strict coach.
- **Localization**: English and Russian.
- Home screen widget.

## Tech stack

Flutter, `flutter_bloc`, `go_router`, `get_it`, Drift (SQLite), `flutter_local_notifications`, `home_widget`.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run
```

Requires Dart SDK ^3.12.2. Run tests with `flutter test`.

## Links

- [Support](https://nu2su1tan.github.io/umytpa/)
- [Privacy Policy](https://nu2su1tan.github.io/umytpa/privacy.html)
