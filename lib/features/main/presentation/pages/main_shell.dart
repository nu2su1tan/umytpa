import 'package:flutter/material.dart';
import '../../../../core/ui/glass/glass.dart';
import '../../../tasks/presentation/pages/tasks_page.dart';
import '../../../week_counter/presentation/pages/week_counter_page.dart';

/// The main application shell hosting the 2 primary tabs:
/// 1. Tracker (TasksPage)
/// 2. Calendar (WeekCounterPage)
///
/// Configured with [Scaffold.extendBody: true] and [AppGlassTabBar] floating
/// above the content.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          TasksPage(),
          WeekCounterPage(),
        ],
      ),
      bottomNavigationBar: AppGlassTabBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

