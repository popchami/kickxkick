import 'package:flutter/material.dart';

class AppTheme {
  static const String appName = 'SoleMuseum';
  static const String tagline = 'Collect. Preserve. Showcase.';

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF000000),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFFFAFAFA),
        foregroundColor: Color(0xFF000000),
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFAFAFA),
        indicatorColor: const Color(0xFF000000).withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF000000),
        foregroundColor: Color(0xFFFFFFFF),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: Color(0xFFFFFFFF),
        margin: EdgeInsets.zero,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFFFFF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF121212),
        foregroundColor: Color(0xFFFFFFFF),
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF000000),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: Color(0xFF1E1E1E),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
