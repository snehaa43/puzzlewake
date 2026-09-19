import 'package:flutter/material.dart';

/// PuzzleWake Theme Definition: Dreamy Twilight and Celestial Night & Dawn Palettes.
class AppTheme {
  // Brand Colors
  static const Color primaryLilac = Color(0xFFC084FC);
  static const Color primaryLilacLight = Color(0xFFD8B4FE);
  static const Color primaryLilacDark = Color(0xFFA855F7);
  static const Color primaryAmber = Color(0xFFD8B4FE);
  static const Color moonGold = Color(0xFFFFD54F);
  static const Color moonPeach = Color(0xFFFF8A65);
  static const Color successGreen = Color(0xFF10B981);
  static const Color alertRed = Color(0xFFEF4444);

  // Dark Celestial Theme Colors
  static const Color nightBgTop = Color(0xFF2B1C42);
  static const Color nightBgMid = Color(0xFF1F1433);
  static const Color nightBgBottom = Color(0xFF120B1E);
  static const Color darkBackground = Color(0xFF130C20);
  static const Color darkSurface = Color(0xFF241938);
  static const Color darkSurfaceVariant = Color(0xFF2D1E45);
  static const Color darkCardBorder = Color(0xFF3D2A5C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA092B3);

  // Light Celestial Dawn Colors
  static const Color lightBgTop = Color(0xFFF6F0FD);
  static const Color lightBgMid = Color(0xFFEDE3F8);
  static const Color lightBgBottom = Color(0xFFDFD0F3);
  static const Color lightBackground = Color(0xFFF7F3FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1E9FA);
  static const Color lightCardBorder = Color(0xFFDACBED);
  static const Color lightTextPrimary = Color(0xFF1E1033);
  static const Color lightTextSecondary = Color(0xFF6B5880);

  /// Dynamic Background Gradient for full screen containers
  static LinearGradient getBackgroundGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [nightBgTop, nightBgMid, nightBgBottom],
        stops: [0.0, 0.45, 1.0],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lightBgTop, lightBgMid, lightBgBottom],
        stops: [0.0, 0.5, 1.0],
      );
    }
  }

  /// Dark Theme Gradient constant for backward compatibility
  static const LinearGradient nightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [nightBgTop, nightBgMid, nightBgBottom],
    stops: [0.0, 0.45, 1.0],
  );

  /// Helper theme getters
  static Color getCardColor(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getCardBorderColor(bool isDark) => isDark ? const Color(0xFF432F62) : lightCardBorder;
  static Color getTextPrimary(bool isDark) => isDark ? Colors.white : lightTextPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;

  /// Dark Material 3 Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryLilac,
        onPrimary: Color(0xFF1E1035),
        secondary: moonGold,
        onSecondary: Colors.black,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkSurfaceVariant,
        outline: darkCardBorder,
        error: alertRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((_) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFBE8DF1);
          }
          return const Color(0xFF3B2956);
        }),
      ),
    );
  }

  /// Light Material 3 Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLilacDark,
        onPrimary: Colors.white,
        secondary: Color(0xFFF59E0B),
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
        backgroundColor: Colors.transparent,
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((_) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF9333EA);
          }
          return const Color(0xFFDACBED);
        }),
      ),
    );
  }
}
