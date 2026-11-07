import 'package:flutter/material.dart';

/// Design-token colors from the Minimalist Task Tracker style guide.
abstract final class AppColors {
  // Light
  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFFED760E);
  static const Color lightPrimaryContainer = Color(0xFFFFEBD9);
  static const Color lightOrangeText = Color(0xFFB4540A);
  static const Color lightText = Color(0xFF1F1B16);
  static const Color lightTextSecondary = Color(0xFF6B645C);
  static const Color lightDivider = Color(0xFFECE8E2);
  static const Color lightError = Color(0xFFD93025);

  // Dark
  static const Color darkBackground = Color(0xFF14120F);
  static const Color darkSurface = Color(0xFF1E1B17);
  static const Color darkPrimary = Color(0xFFF28A2E);
  static const Color darkPrimaryContainer = Color(0xFF3A2208);
  static const Color darkText = Color(0xFFF5F1EB);
  static const Color darkTextSecondary = Color(0xFFA39B91);
  static const Color darkDivider = Color(0xFF2E2A25);
  static const Color darkError = Color(0xFFF2837B);

  // Categories (shared across themes)
  static const Color study = Color(0xFF3B82F6);
  static const Color work = Color(0xFF8B5CF6);
  static const Color personal = Color(0xFF10B981);
  static const Color other = Color(0xFF9CA3AF);
}
