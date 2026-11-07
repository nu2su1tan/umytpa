import 'package:flutter/material.dart';
import 'package:liquid_glass_tab_bar/liquid_glass_tab_bar.dart';
import '../../theme/app_colors.dart';

/// Wraps [LiquidGlassTabBar] with the two main tabs:
/// - Checklist icon "Tracker"
/// - Calendar icon "Calendar"
/// Accent is set to the app's existing orange.
class AppGlassTabBar extends StatelessWidget {
  const AppGlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Returns the bottom padding required for scrollables so content is not
  /// obscured behind the floating tab bar.
  static double bottomPaddingOf(BuildContext context) {
    return LiquidGlassTabBar.heightOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return LiquidGlassTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedColor: accent,
      style: const LiquidGlassTabBarStyle(),
      items: const <LiquidGlassTabItem>[
        LiquidGlassTabItem(
          icon: Icon(Icons.checklist_rounded),
          label: 'Tracker',
        ),
        LiquidGlassTabItem(
          icon: Icon(Icons.timer_rounded),
          label: 'Week',
        ),
      ],
    );
  }
}
