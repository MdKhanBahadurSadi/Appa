import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryAccent = Color(0xFF6366F1);
  static const secondaryAccent = Color(0xFF10B981);
  static const surfaceDark = Color(0xFF0F172A);
  static const surfaceLight = Color(0xFFF8FAFC);

  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: brightness,
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: isDark ? surfaceDark : surfaceLight,
        onSurface: isDark ? Colors.white : const Color(0xFF1E293B),
        surfaceContainerLow: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      scaffoldBackgroundColor: isDark ? surfaceDark : surfaceLight,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
    );
  }
}
