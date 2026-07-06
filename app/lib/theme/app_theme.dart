import 'package:flutter/material.dart';

import '../models/background_theme.dart';

class AppTheme {
  static const String appName = 'KickxKick';
  static const String tagline = 'Collect. Create. Exhibit.';

  static Color _barColorFor(BackgroundTheme backgroundTheme) {
    switch (backgroundTheme) {
      case BackgroundTheme.orange:
        return const Color(0xFFFF7A1A);
      case BackgroundTheme.street:
        return const Color(0xFF1C1C1C);
    }
  }

  static ThemeData lightTheme(BackgroundTheme backgroundTheme) {
    final barColor = _barColorFor(backgroundTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'NotoSansJP',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF7A1A),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: barColor,
        foregroundColor: const Color(0xFFFFFFFF),
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: barColor,
        indicatorColor: Colors.white.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFF7A1A),
        foregroundColor: Color(0xFFFFFFFF),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFFFFFFFF),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData darkTheme(BackgroundTheme backgroundTheme) {
    final barColor = _barColorFor(backgroundTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'NotoSansJP',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF7A1A),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: barColor,
        foregroundColor: const Color(0xFFFFFFFF),
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: barColor,
        indicatorColor: Colors.white.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFF7A1A),
        foregroundColor: Color(0xFFFFFFFF),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1E1E1E),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
