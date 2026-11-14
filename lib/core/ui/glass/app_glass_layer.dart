import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'glass_tokens.dart';

/// Wraps a screen or region so nested glass surfaces can share a single layer
/// to minimize GPU and texture allocation cost.
class AppGlassLayer extends StatelessWidget {
  const AppGlassLayer({super.key, required this.child, this.settings});

  final Widget child;
  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) {
    final bool isHighContrast = MediaQuery.highContrastOf(context);
    final bool isUnsupported = !ImageFilter.isShaderFilterSupported;
    final Brightness brightness = Theme.of(context).brightness;

    return LiquidGlassLayer(
      fake: isHighContrast || isUnsupported,
      settings: settings ?? GlassTokens.createSettings(brightness: brightness),
      child: child,
    );
  }
}
