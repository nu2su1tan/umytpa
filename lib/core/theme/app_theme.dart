import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:umytpa/features/week_counter/ui/theme/tokens.dart';

/// Material themes for the whole app. Built from the same [Tokens] as the
/// Week screens (Wabi neutrals, violet accent, Inter), so the Tracker and the
/// Week counter look like one product.
abstract final class AppTheme {
  static const double screenPadding = 16;
  static const double cardRadius = 20;
  static const double buttonRadius = 25;
  static const double fabRadius = 28;

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final Tokens t = brightness == Brightness.dark ? Tokens.dark : Tokens.light;
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: Tokens.violet,
          brightness: brightness,
        ).copyWith(
          primary: t.violetInk,
          onPrimary: isDark ? Colors.black : Colors.white,
          primaryContainer: t.violetSoft,
          onPrimaryContainer: t.violetInk,
          secondary: t.violetInk,
          onSecondary: isDark ? Colors.black : Colors.white,
          secondaryContainer: t.violetSoft,
          onSecondaryContainer: t.violetInk,
          tertiary: t.limeInk,
          surface: t.bg,
          onSurface: t.ink,
          onSurfaceVariant: t.ink2,
          error: t.danger,
          outline: t.ink3,
          outlineVariant: t.line,
        );

    final TextTheme textTheme = TextTheme(
      headlineLarge: t.largeTitle.copyWith(fontSize: 30, height: 36 / 30),
      headlineMedium: t.sectionTitle,
      titleLarge: t.navTitle,
      titleMedium: t.navTitle.copyWith(fontSize: 16, letterSpacing: -0.3),
      bodyLarge: t.body,
      bodyMedium: t.callout,
      bodySmall: t.footnote,
      labelLarge: t.navTitle.copyWith(fontSize: 16),
    );

    const PageTransitionsTheme transitions = PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      canvasColor: t.bg,
      dividerColor: t.line,
      fontFamily: Fonts.text,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[t],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: transitions,
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: t.navTitle,
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: t.violetSoft,
        disabledColor: t.surface,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: t.callout.copyWith(color: t.ink),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.inverse,
        foregroundColor: t.onInverse,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.inverse,
          foregroundColor: t.onInverse,
          disabledBackgroundColor: t.inverse.withValues(alpha: 0.35),
          disabledForegroundColor: t.onInverse,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: Fonts.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.17,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.violetInk,
          minimumSize: const Size(44, 44),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: Fonts.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintStyle: t.body.copyWith(color: t.ink3),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Tokens.violet,
        selectionColor: Tokens.violet.withValues(alpha: 0.3),
        selectionHandleColor: Tokens.violet,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.sheet,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: t.navTitle.copyWith(fontSize: 20),
        contentTextStyle: t.callout,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: t.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: t.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.inverse,
        contentTextStyle: t.callout.copyWith(
          color: t.onInverse,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: isDark ? Tokens.violet : Tokens.lime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? t.violetInk
              : t.surface3;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
      dividerTheme: DividerThemeData(color: t.line, thickness: 0.5, space: 0.5),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.violetInk),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.inverse,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(color: t.onInverse, fontSize: 13),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: Tokens.violet,
      ),
    );
  }
}
