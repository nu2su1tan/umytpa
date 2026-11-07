import 'package:go_router/go_router.dart';

import '../../features/main/presentation/pages/main_shell.dart';
import '../../features/week_counter/presentation/pages/week_counter_page.dart';

/// Application routes. Task create/edit uses a modal bottom sheet, not a route.
abstract final class AppRoutes {
  static const String tasks = '/';
  static const String week = '/week';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.tasks,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.tasks,
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: AppRoutes.week,
      builder: (context, state) => const WeekCounterPage(),
    ),
  ],
);

