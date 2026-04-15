import 'package:flutter/material.dart';

// ─── FlocksSync Brand Colors ───────────────────────────────────────────────────

class FlockColors {
  static const darkGreen = Color(0xFF0A400C);
  static const midGreen = Color(0xFF819067);
  static const tan = Color(0xFFB1AB86);
  static const cream = Color(0xFFFEFAE0);

  // Derived
  static const cardBackground = Color(
    0xFFEEEACC,
  ); // slightly darker cream for cards
  static const buttonBackground = Color(
    0xFFB1AB86,
  ); // tan buttons like the mockup
  static const divider = Color(0xFFCCC9A8);
  static const textPrimary = Color(0xFF0A400C);
  static const textSecondary = Color(0xFF819067);
  static const textMuted = Color(0xFFADAA88);
  static const errorRed = Color(0xFF8B2E00);

  // Aliases to match AppColors naming from login-demo branch
  static const background = cream;
  static const middleground = tan;
  static const green2 = midGreen;
}

// ─── ThemeData ────────────────────────────────────────────────────────────────

ThemeData flockTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: FlockColors.cream,
    colorScheme: ColorScheme.light(
      primary: FlockColors.darkGreen,
      onPrimary: FlockColors.cream,
      secondary: FlockColors.midGreen,
      onSecondary: FlockColors.cream,
      surface: FlockColors.cream,
      onSurface: FlockColors.darkGreen,
      surfaceContainerHighest: FlockColors.cardBackground,
      outline: FlockColors.tan,
      outlineVariant: FlockColors.divider,
      error: FlockColors.errorRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FlockColors.cream,
      foregroundColor: FlockColors.darkGreen,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: FlockColors.darkGreen,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: FlockColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: FlockColors.tan.withValues(alpha: 0.25),
      selectedColor: FlockColors.darkGreen.withValues(alpha: 0.12),
      labelStyle: const TextStyle(
        color: FlockColors.darkGreen,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FlockColors.cardBackground,
      labelStyle: const TextStyle(color: FlockColors.midGreen),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return FlockColors.errorRed;
        return FlockColors.darkGreen;
      }),
      suffixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return FlockColors.errorRed;
        return FlockColors.darkGreen;
      }),
      hintStyle: TextStyle(
        color: FlockColors.textMuted,
        fontStyle: FontStyle.italic,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlockColors.tan),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlockColors.tan),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlockColors.darkGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlockColors.errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlockColors.errorRed, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FlockColors.darkGreen,
        foregroundColor: FlockColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: FlockColors.darkGreen,
      foregroundColor: FlockColors.cream,
      shape: StadiumBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: FlockColors.divider,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: FlockColors.darkGreen,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: FlockColors.darkGreen,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
      titleLarge: TextStyle(
        color: FlockColors.darkGreen,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: FlockColors.darkGreen,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        color: FlockColors.darkGreen,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: FlockColors.darkGreen,
        fontSize: 14,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: FlockColors.darkGreen,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}
// Alias for backwards compatibility with login-demo branch
// Teammates can use AppColors.darkGreen or FlockColors.darkGreen — both work
typedef AppColors = FlockColors;