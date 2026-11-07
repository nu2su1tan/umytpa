import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/glass/glass.dart';
import '../../../tasks/presentation/pages/tasks_page.dart';
import '../../../week_counter/services/holiday_api.dart';
import '../../../week_counter/services/holiday_repository.dart';
import '../../../week_counter/services/local_store.dart';
import '../../../week_counter/services/prefs_repository.dart';
import '../../../week_counter/services/settings_repository.dart';
import '../../../week_counter/services/widget_sync.dart';
import '../../../week_counter/state/app_controller.dart';
import '../../../week_counter/ui/screens/celebrate_screen.dart';
import '../../../week_counter/ui/screens/home_screen.dart';
import '../../../week_counter/ui/screens/onboarding_screen.dart';
import '../../../week_counter/ui/theme/tokens.dart';

/// The main application shell hosting the primary tabs:
/// 0. Tracker (tasks)
/// 1. Week (countdown)
///
/// The Week tabs share one [AppController]. The shell also runs first-launch
/// onboarding and the "time off has started" celebration, and tells the
/// controller when the app comes back to the foreground.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static const int _weekTab = 1;

  int _currentIndex = 0;
  AppController? _controller;
  bool _celebrating = false;
  bool _onboarded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    if (HomeWidgetSync.isSupported) {
      await HomeWidgetSync.init();
    }

    final SharedPrefsLocalStore store = SharedPrefsLocalStore();
    final AppController controller = AppController(
      settingsRepository: SettingsRepository(store),
      holidayRepository: HolidayRepository(store, NagerDateApi()),
      prefsRepository: PrefsRepository(store),
      widgetSync:
          HomeWidgetSync.isSupported ? HomeWidgetSync() : NoopWidgetSync(),
    );
    await controller.init();
    if (!mounted) {
      controller.dispose();
      return;
    }
    controller.addListener(_onChange);
    setState(() {
      _controller = controller;
      _onboarded = controller.prefs.onboarded;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ?..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller?.onResume();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) =>
      _controller?.onLocaleChanged();

  void _onChange() {
    final AppController? controller = _controller;
    if (controller == null || !mounted) {
      return;
    }
    // Onboarding ends by changing prefs, which swaps in the tabs.
    if (_onboarded != controller.prefs.onboarded) {
      setState(() => _onboarded = controller.prefs.onboarded);
    }
    _maybeCelebrate();
  }

  /// Throws the party once each time off starts, whichever tab is open.
  Future<void> _maybeCelebrate() async {
    final AppController? controller = _controller;
    if (controller == null) {
      return;
    }
    final block = controller.celebrationDue;
    if (block == null ||
        _celebrating ||
        !mounted ||
        !controller.prefs.onboarded) {
      return;
    }
    _celebrating = true;
    await controller.markCelebrated(block);
    if (!mounted) {
      return;
    }
    await CelebrateScreen.open(
      context,
      controller,
      block,
      award: controller.takeFreshAward(),
    );
    _celebrating = false;
    if (mounted) {
      setState(() => _currentIndex = _weekTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppController? controller = _controller;
    if (controller == null) {
      return Scaffold(
        backgroundColor: t.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_onboarded) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: t.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: OnboardingFlow(controller: controller),
      );
    }

    final List<Widget> screens = <Widget>[
      const TasksPage(),
      HomeScreen(controller: controller),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: t.bg,
        extendBody: true,
        // The back button returns to the first tab before closing the app.
        body: PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) {
              setState(() => _currentIndex = 0);
            }
          },
          child: IndexedStack(
            index: _currentIndex,
            children: <Widget>[
              for (final (int i, Widget screen) in screens.indexed)
                TickerMode(enabled: i == _currentIndex, child: screen),
            ],
          ),
        ),
        bottomNavigationBar: AppGlassTabBar(
          currentIndex: _currentIndex,
          onTap: (int index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
