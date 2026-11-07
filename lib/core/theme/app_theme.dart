import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'package:umytpa/features/week_counter/ui/theme/tokens.dart';

/// Material 3 themes matching the Minimalist Task Tracker style guide.
abstract final class AppTheme {
  static const double screenPadding = 20;
  static const double cardRadius = 16;
  static const double buttonRadius = 14;
  static const double fabRadius = 18;

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        primary: AppColors.lightPrimary,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimary: Colors.white,
        text: AppColors.lightText,
        textSecondary: AppColors.lightTextSecondary,
        divider: AppColors.lightDivider,
        error: AppColors.lightError,
        orangeText: AppColors.lightOrangeText,
      ).copyWith(
        extensions: const <ThemeExtension<dynamic>>[Tokens.light],
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        primary: AppColors.darkPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimary: AppColors.darkText,
        text: AppColors.darkText,
        textSecondary: AppColors.darkTextSecondary,
        divider: AppColors.darkDivider,
        error: AppColors.darkError,
        orangeText: AppColors.darkPrimary,
      ).copyWith(
        extensions: const <ThemeExtension<dynamic>>[Tokens.dark],
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color primaryContainer,
    required Color onPrimary,
    required Color text,
    required Color textSecondary,
    required Color divider,
    required Color error,
    required Color orangeText,
  }) {
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: orangeText,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: primaryContainer,
      onSecondaryContainer: orangeText,
      tertiary: primary,
      onTertiary: onPrimary,
      error: error,
      onError: brightness == Brightness.light ? Colors.white : AppColors.darkText,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textSecondary,
      outline: divider,
      outlineVariant: divider,
      surfaceContainerHighest: background,
      surfaceContainerHigh: surface,
      surfaceContainer: surface,
      surfaceContainerLow: background,
      surfaceContainerLowest: background,
    );

    final TextTheme textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: text,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: text,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: onPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: divider,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.headlineLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: divider),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryContainer,
        disabledColor: surface,
        side: BorderSide(color: divider),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fabRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: error,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: divider,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: background,
        ),
        actionTextColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brightness == Brightness.light
                ? AppColors.lightText
                : AppColors.darkText;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return divider;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
