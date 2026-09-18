import 'package:flutter/material.dart';

/// PuzzleWake Theme Definition: Morning-inspired sunrise palette with Material 3.
class AppTheme {
  // Morning Palette Colors
  static const Color primaryAmber = Color(0xFFFF7A00);
  static const Color primarySun = Color(0xFFF59E0B);
  static const Color coralSunrise = Color(0xFFFF5722);
  static const Color morningSky = Color(0xFF4F46E5);
  static const Color successGreen = Color(0xFF10B981);
  static const Color alertRed = Color(0xFFEF4444);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAF7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3EEE6);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightCardBorder = Color(0xFFE5DDD0);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D131F);
  static const Color darkSurface = Color(0xFF161F32);
  static const Color darkSurfaceVariant = Color(0xFF1E2B45);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkCardBorder = Color(0xFF2B3A5A);

  /// Light Material 3 Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryAmber,
        onPrimary: Colors.white,
        secondary: morningSky,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        surfaceContainerHighest: lightSurfaceVariant,
        outline: lightCardBorder,
        error: alertRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightCardBorder, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightCardBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAmber;
          }
          return lightTextSecondary.withValues(alpha: 0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAmber.withValues(alpha: 0.3);
          }
          return lightSurfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAmber;
          }
          return lightCardBorder;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryAmber,
        inactiveTrackColor: lightSurfaceVariant,
        thumbColor: primaryAmber,
        overlayColor: Color(0x29FF7A00),
        trackHeight: 6,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        hourMinuteColor: lightSurfaceVariant,
        hourMinuteTextColor: primaryAmber,
        dayPeriodColor: lightSurfaceVariant,
        dayPeriodTextColor: lightTextPrimary,
        dialHandColor: primaryAmber,
        dialBackgroundColor: lightSurfaceVariant,
        dialTextColor: lightTextPrimary,
        entryModeIconColor: primaryAmber,
      ),
    );
  }

  /// Dark Material 3 Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryAmber,
        onPrimary: Colors.white,
        secondary: morningSky,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkSurfaceVariant,
        outline: darkCardBorder,
        error: alertRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkCardBorder, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkCardBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAmber;
          }
          return darkTextSecondary.withValues(alpha: 0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAmber.withValues(alpha: 0.35);
          }
          return darkSurfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAmber;
          }
          return darkCardBorder;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryAmber,
        inactiveTrackColor: darkSurfaceVariant,
        thumbColor: primaryAmber,
        overlayColor: Color(0x33FF7A00),
        trackHeight: 6,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        hourMinuteColor: darkSurfaceVariant,
        hourMinuteTextColor: primaryAmber,
        dayPeriodColor: darkSurfaceVariant,
        dayPeriodTextColor: darkTextPrimary,
        dialHandColor: primaryAmber,
        dialBackgroundColor: darkSurfaceVariant,
        dialTextColor: darkTextPrimary,
        entryModeIconColor: primaryAmber,
      ),
    );
  }
}
