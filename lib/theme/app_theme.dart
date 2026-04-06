import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryColor = Color(0xFF3B82F6); // Blue
  static const Color _surfaceColor = Color(0xFFF8FAFC); // Light Slate Background
  static const Color _cardColor = Color(0xFFFFFFFF);    // White Cards
  static const Color subTileColor = Color(0xFFF1F5F9);  // Slate 100 Sub-tiles

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      surface: _surfaceColor,
      primary: _primaryColor,
      secondary: const Color(0xFF10B981), // Emerald Green
      error: const Color(0xFFEF4444),     // Red
    );

    final baseTextTheme = GoogleFonts.soraTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surfaceColor,
      cardColor: _cardColor,

      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceColor,
        foregroundColor: const Color(0xFF0F172A), // Slate 900
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(
          color: const Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),

      cardTheme: CardThemeData(
        color: _cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200 border
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _primaryColor,
        tileColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A), // Slate 900
        ),
        titleMedium: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        bodyLarge: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        bodyMedium: GoogleFonts.sora(
          fontSize: 15,
          color: const Color(0xFF64748B), // Slate 500
        ),
        bodySmall: GoogleFonts.sora(
          fontSize: 13,
          color: const Color(0xFF94A3B8), // Slate 400
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1F2937),
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}


