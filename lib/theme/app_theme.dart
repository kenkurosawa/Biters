import 'package:flutter/material.dart';
import 'colors.dart';

/// Tema claro/oscuro de Biters. Titulares en Space Grotesk (bold), texto y
/// montos en Inter — ver docs/Biters_Diseno_App.pdf, página 2.
class AppTheme {
  AppTheme._();

  static const _radius = 20.0;

  static TextTheme _textTheme(Color textColor) {
    final base = TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 34,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: textColor.withValues(alpha: 0.65),
      ),
    );
    return base;
  }

  static ThemeData light() {
    const surface = Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: BitersColors.coral,
      brightness: Brightness.light,
      primary: BitersColors.coral,
      secondary: BitersColors.teal,
      tertiary: BitersColors.gold,
      surface: surface,
      error: BitersColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: BitersColors.cream,
      textTheme: _textTheme(BitersColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: BitersColors.cream,
        foregroundColor: BitersColors.ink,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: BitersColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BitersColors.coral, width: 1.5),
        ),
        labelStyle: const TextStyle(fontFamily: 'Inter', color: BitersColors.ink, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BitersColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: BitersColors.coral,
        unselectedItemColor: Color(0xFFB8AA9E),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEFE2D3)),
    );
  }

  static ThemeData dark() {
    const surface = BitersColors.charcoal800;
    const textColor = BitersColors.cream;
    final scheme = ColorScheme.fromSeed(
      seedColor: BitersColors.coral,
      brightness: Brightness.dark,
      primary: BitersColors.coral,
      secondary: BitersColors.teal,
      tertiary: BitersColors.gold,
      surface: surface,
      error: const Color(0xFFFF7A5C),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: BitersColors.charcoal900,
      textTheme: _textTheme(textColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: BitersColors.charcoal900,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BitersColors.coral, width: 1.5),
        ),
        labelStyle: const TextStyle(fontFamily: 'Inter', color: textColor, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BitersColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BitersColors.charcoal800,
        selectedItemColor: BitersColors.coral,
        unselectedItemColor: Color(0xFF8A7A6C),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF3A2F26)),
    );
  }
}
