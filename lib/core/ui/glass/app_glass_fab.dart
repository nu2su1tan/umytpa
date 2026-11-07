import 'package:flutter/material.dart';
import 'package:umytpa/features/week_counter/ui/kit/orb.dart';

/// "Add" button drawn as the small lime glass sphere from the Week screen,
/// with a plus in the middle.
class AppGlassFab extends StatelessWidget {
  const AppGlassFab({
    super.key,
    required this.onPressed,
    this.tooltip = 'Add task',
  });

  static const double size = 64;

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Orb(
              size: size,
              fill: 0.58,
              mode: OrbMode.weekend,
              onTap: onPressed,
              semanticLabel: tooltip,
            ),
            // The plus must not swallow the orb's taps.
            const IgnorePointer(
              child: ExcludeSemantics(
                child: Icon(
                  Icons.add,
                  size: 30,
                  color: Color(0xFF1B2A00),
                  shadows: <Shadow>[
                    Shadow(color: Color(0x66FFFFFF), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
