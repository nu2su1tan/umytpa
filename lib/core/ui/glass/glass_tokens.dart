import 'dart:math';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Single source of truth for iOS 26 Liquid Glass appearance and tokens.
abstract final class GlassTokens {
  // Optical & shader settings
  static const double thickness = 20.0;
  static const double blur = 10.0;
  static const double lightIntensity = 0.6;
  static const double ambientStrength = 0.15;
  static const double refractiveIndex = 1.25;
  static const double saturation = 1.35;
  static const double lightAngle = 0.5 * pi;

  // Tints
  static const Color defaultLightTint = Color(0x26FFFFFF);
  static const Color defaultDarkTint = Color(0x33000000);
  static const Color accentOrange = Color(0xFFED760E);
  static const Color accentOrangeTint = Color(0x38ED760E);

  // Fallback (frosted) tokens
  static const double fallbackBlur = 18.0;
  static const Color fallbackFill = Color(0x99FFFFFF); // white 0.6 fill
  static const Color fallbackDarkFill = Color(0x991E1B17);
  static const Color fallbackBorder = Color(0x66FFFFFF); // thin white border
  static const double fallbackBorderWidth = 1.0;

  /// Creates [LiquidGlassSettings] using the central tokens.
  static LiquidGlassSettings createSettings({
    Color? tint,
    Brightness brightness = Brightness.light,
  }) {
    final Color defaultColor =
        brightness == Brightness.dark ? defaultDarkTint : defaultLightTint;

    return LiquidGlassSettings(
      thickness: thickness,
      blur: blur,
      lightIntensity: lightIntensity,
      ambientStrength: ambientStrength,
      refractiveIndex: refractiveIndex,
      saturation: saturation,
      lightAngle: lightAngle,
      glassColor: tint ?? defaultColor,
    );
  }
}

