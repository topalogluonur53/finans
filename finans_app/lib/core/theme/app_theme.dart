import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant Colors
  static const Color primaryColor = Color(0xFF6C63FF); // Purple
  static const Color secondaryColor = Color(0xFF00C853); // Green profit
  static const Color errorColor = Color(0xFFFF3D00); // Red loss
  static const Color backgroundDark = Color(0xFF1E1E2C);
  static const Color surfaceDark = Color(0xFF2D2D44);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFFAAAAAA);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceDark,
        background: backgroundDark,
        error: errorColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textLight, 
        displayColor: textLight,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        labelStyle: const TextStyle(color: textDim),
        hintStyle: const TextStyle(color: textDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
