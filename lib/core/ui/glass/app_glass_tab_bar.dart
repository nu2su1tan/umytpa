import 'package:flutter/material.dart';
import 'package:liquid_glass_tab_bar/liquid_glass_tab_bar.dart';
import 'package:umytpa/features/week_counter/ui/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Wraps [LiquidGlassTabBar] with the main tabs: Tracker and Week.
/// Accent is the shared violet from the design tokens.
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
    final Color accent = context.tokens.violetInk;

    return LiquidGlassTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedColor: accent,
      style: const LiquidGlassTabBarStyle(),
      items: <LiquidGlassTabItem>[
        LiquidGlassTabItem(
          icon: const Icon(Icons.checklist_rounded),
          label: context.l10n.tabTracker,
        ),
        LiquidGlassTabItem(
          icon: const Icon(Icons.timer_rounded),
          label: context.l10n.navCountdown,
        ),
      ],
    );
  }
}
