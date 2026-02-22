import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // İşBankası Tasarım Konsepti Renkleri
  static const Color primaryColor = Color(0xFF0057B8);     // Orta Mavi (Aksiyon Butonları, İkonlar)
  static const Color secondaryColor = Color(0xFF00BFA5);   // Kâr Yeşili (Teal)
  static const Color errorColor = Color(0xFFE53935);       // Zarar Kırmızısı
  
  // Arka Plan Renkleri (Koyu Tema)
  static const Color backgroundDark = Color(0xFFF0F4FA);   // Genel Arka Plan (Login ekranıyla uyumlu hafif gri-mavi)
  static const Color surfaceDark = Color(0xFFFFFFFF);      // Kartların Arka Planı (Beyaz)
  
  // Metin Renkleri (Light mod temalı renkleri app temaya uyarlıyoruz)
  static const Color textDark = Color(0xFF1A1A2E);         // Ana Metin 
  static const Color textDim = Color(0xFF6B7280);          // İkincil Metin

  // Gelişmiş Tema Ayarı
  static ThemeData get darkTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceDark,
        error: errorColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        shadowColor: const Color(0xFF002F6C).withOpacity(0.08),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF002F6C), // Koyu Lacivert (Header / AppBar için)
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: textDim,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textDim, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: textDim.withOpacity(0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
    );
  }

  // NOTE: Diğer component'lerin uyumlu çalışması için light versiyon referansları ekliyoruz
  static const Color textLight = textDark; 
}
