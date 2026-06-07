import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color brandPrimary = Color(0xFF2F855A);
  static const Color brandAccent = Color(0xFF2B6CB0);
  static const Color brandTeal = Color(0xFF00D4A8);
  
  // Dark Theme
  static const Color darkSurface = Color(0xFF102235);
  static const Color darkSurface2 = Color(0xFF142B40);
  static const Color darkSurface3 = Color(0xFF1B354D);
  static const Color darkBorder = Color(0x2DB3CDE0);
  static const Color darkText = Color(0xFFEDF4F8);
  static const Color darkTextSoft = Color(0xFFB9CADA);
  static const Color darkTextMuted = Color(0xFF88A0B8);
  
  // Light Theme
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightSurface2 = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSoft = Color(0xFF334155);
  static const Color lightTextMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B1827),
      primaryColor: brandPrimary,
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandAccent,
        surface: darkSurface,
        background: Color(0xFF0B1827),
        onBackground: darkText,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(color: darkText, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.spaceGrotesk(color: darkText, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: darkTextSoft),
        bodyMedium: GoogleFonts.inter(color: darkTextMuted),
        labelLarge: GoogleFonts.jetBrainsMono(color: darkTextSoft, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface.withOpacity(0.94),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          color: const Color(0xFF93C5AA),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A1826),
        selectedItemColor: brandTeal,
        unselectedItemColor: darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        color: darkSurface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightSurface,
      primaryColor: brandPrimary,
      colorScheme: const ColorScheme.light(
        primary: brandPrimary,
        secondary: brandAccent,
        surface: Colors.white,
        background: lightSurface,
        onBackground: lightText,
        onSurface: lightText,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(color: lightText, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.spaceGrotesk(color: lightText, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: lightTextSoft),
        bodyMedium: GoogleFonts.inter(color: lightTextMuted),
        labelLarge: GoogleFonts.jetBrainsMono(color: lightTextSoft, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.94),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          color: brandPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: brandPrimary,
        unselectedItemColor: lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(color: lightBorder),
    );
  }
}