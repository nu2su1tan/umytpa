import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'app_glass.dart';
import 'glass_tokens.dart';

/// Floating Action Button with an iOS 26 liquid glass aesthetic.
/// Features orange-tinted glass, a vibrant glow shadow, interactive touch glow,
/// and a 0.92 press scale animation.
class AppGlassFab extends StatefulWidget {
  const AppGlassFab({
    super.key,
    required this.onPressed,
    this.tooltip = 'Add task',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  State<AppGlassFab> createState() => _AppGlassFabState();
}

class _AppGlassFabState extends State<AppGlassFab> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: widget.onPressed != null ? _onTapDown : null,
          onTapUp: widget.onPressed != null ? _onTapUp : null,
          onTapCancel: widget.onPressed != null ? _onTapCancel : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accent.withValues(alpha: 0.40),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AppGlass(
                radius: 18,
                tint: GlassTokens.accentOrangeTint,
                interactive: true,
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: accent,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

