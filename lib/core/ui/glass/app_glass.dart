import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'glass_tokens.dart';

/// Adapter widget wrapping [LiquidGlass].
///
/// If glass shaders are unsupported or [MediaQuery.highContrastOf] is true,
/// this renders an iOS-style frosted fallback (BackdropFilter blur 18 +
/// white 0.6 fill + thin white border) wrapped in a [RepaintBoundary].
class AppGlass extends StatelessWidget {
  const AppGlass({
    super.key,
    required this.child,
    this.radius,
    this.shape,
    this.tint,
    this.interactive = false,
  });

  final Widget child;
  final double? radius;
  final LiquidShape? shape;
  final Color? tint;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final bool isHighContrast = MediaQuery.highContrastOf(context);
    final bool isUnsupported = !ImageFilter.isShaderFilterSupported;
    final double effectiveRadius = radius ?? 16.0;

    if (isHighContrast || isUnsupported) {
      return _buildFrostedFallback(context, effectiveRadius);
    }

    final LiquidShape effectiveShape =
        shape ?? LiquidRoundedSuperellipse(borderRadius: effectiveRadius);

    final Widget content = interactive ? GlassGlow(child: child) : child;

    final brightness = Theme.of(context).brightness;

    // Use own layer if tint is specified or if rendered standalone
    return LiquidGlass.withOwnLayer(
      settings: GlassTokens.createSettings(tint: tint, brightness: brightness),
      shape: effectiveShape,
      child: content,
    );
  }

  Widget _buildFrostedFallback(BuildContext context, double effectiveRadius) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fill =
        tint ??
        (isDark ? GlassTokens.fallbackDarkFill : GlassTokens.fallbackFill);
    final BorderRadius borderRadius = BorderRadius.circular(effectiveRadius);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.fallbackBlur,
            sigmaY: GlassTokens.fallbackBlur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: borderRadius,
              border: Border.all(color: GlassTokens.fallbackBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
