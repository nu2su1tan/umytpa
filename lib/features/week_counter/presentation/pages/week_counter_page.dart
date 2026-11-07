// lib/features/week_counter/presentation/pages/week_counter_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../core/ui/glass/glass.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_controller.dart';
import '../../services/holiday_api.dart';
import '../../services/holiday_repository.dart';
import '../../services/local_store.dart';
import '../../services/prefs_repository.dart';
import '../../services/settings_repository.dart';
import '../../services/widget_sync.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/root_shell.dart';
import '../../ui/theme/tokens.dart';

/// A page that embeds the Week Counter UI into the main Umbytpa app.
class WeekCounterPage extends StatefulWidget {
  const WeekCounterPage({Key? key}) : super(key: key);

  @override
  State<WeekCounterPage> createState() => _WeekCounterPageState();
}

class _WeekCounterPageState extends State<WeekCounterPage> {
  late final AppController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    WidgetsFlutterBinding.ensureInitialized();
    LicenseRegistry.addLicense(_fontLicenses);
    await initializeDateFormatting();
    if (HomeWidgetSync.isSupported) await HomeWidgetSync.init();

    final store = SharedPrefsLocalStore();
    _controller = AppController(
      settingsRepository: SettingsRepository(store),
      holidayRepository: HolidayRepository(store, NagerDateApi()),
      prefsRepository: PrefsRepository(store),
      widgetSync: HomeWidgetSync.isSupported ? HomeWidgetSync() : NoopWidgetSync(),
    );
    await _controller.init();

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    // If AppController ever gains a dispose method, call it here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return AuroraBackground(
      child: HomeScreen(controller: _controller, onOpenTab: (_) {}),
    );
  }
}

// ---------- Font licenses (copied from the original week_counter main.dart) ----------
Stream<LicenseEntry> _fontLicenses() async* {
  for (final (family, file) in [
    ('Inter', 'OFL-Inter.txt'),
    ('Inter Tight', 'OFL-InterTight.txt'),
    ('JetBrains Mono', 'OFL-JetBrainsMono.txt'),
  ]) {
    final text = await rootBundle.loadString('assets/fonts/$file');
    yield LicenseEntryWithLineBreaks([family], text);
  }
}

